# Phone Native Application Roadmap

Status: approved product architecture; implementation pending

Phone is Edemint's custom calling application. It is not a renamed upstream dialer, website wrapper or proprietary service client. The first image integration happens only after a real `edemint-phone` executable exists and passes the gates in this document.

Icons and final animation are deferred.

## 1. Product scope

Phone provides one coherent calling surface for supported cellular modems and configured internet-calling accounts.

Core capabilities:

- numeric dial pad and international-number handling;
- incoming, outgoing, active and held call states;
- call history with missed-call notifications;
- contacts and favorites;
- speaker, microphone, mute, hold and audio-route controls;
- dual-call and merge controls where the provider supports them;
- voicemail entry and provider voicemail number;
- SMS entry points when a cellular modem supports messaging;
- SIP URI and ordinary telephone-number calling;
- Bluetooth headset and hands-free audio routing;
- mobile-shaped, desktop and compact in-call layouts;
- integration with Fullcall and Messenger without merging their identities.

Phone does not make unsupported hardware appear capable. Devices without a voice-capable modem or configured VoIP account show setup and diagnostic guidance instead of a nonfunctional dial pad.

## 2. Technology decision

Build Phone as an Edemint-owned GTK4/libadwaita application written in Rust.

Proposed identity:

- display name: `Phone`;
- application ID: `org.edemint.Phone` after namespace reservation;
- executable: `edemint-phone`;
- package: `edemint-phone`;
- settings: GSettings under the application ID;
- call history and contacts cache: encrypted local database;
- account credentials: Secret Service only.

The client must not run as root.

## 3. Supported call transports

### Cellular voice

Use the system ModemManager service through its documented D-Bus API. `modemmanager` is already present in the Edemint base package list.

A modem must expose voice capability before Phone enables cellular calling. Data-only modems remain usable by NetworkManager but do not produce misleading call controls.

Cellular feature detection includes:

- modem and SIM presence;
- SIM lock and unlock state;
- registered network and roaming state;
- signal quality;
- operator identity where available;
- voice-call capability;
- SMS capability;
- modem-defined call waiting, hold, multiparty and DTMF support;
- emergency-number information when the modem and network expose it.

### Internet calling

Support standards-based SIP as the first VoIP transport. WebRTC may be added for service integrations and browser-compatible call links, but it must not replace a documented telephone account model.

An architecture decision record must select the maintained SIP/media library after verifying:

- Debian Trixie availability and license;
- `amd64` and `arm64` support;
- TLS, SRTP, ICE and TURN support;
- PipeWire integration or a bounded audio adapter;
- active security maintenance;
- IPv6, NAT traversal and network-change behavior.

Provider credentials and tokens remain in Secret Service. Server certificates are validated by default and insecure registration requires an explicit developer-only mode.

## 4. Architecture

1. **Presentation layer**
   GTK4/libadwaita dialer, contacts, history, setup, incoming-call and in-call surfaces.
2. **Call coordinator**
   One state machine that normalizes cellular and VoIP call states without erasing transport-specific capability limits.
3. **Cellular adapter**
   ModemManager D-Bus client for modem discovery, registration, voice calls, DTMF and supported messaging operations.
4. **VoIP adapter**
   SIP registration, signaling, secure media negotiation and provider diagnostics.
5. **Media router**
   PipeWire/WirePlumber device discovery, per-call streams, Bluetooth routing, mute and volume state.
6. **Data layer**
   encrypted call history, contact links, favorites, account metadata and schema migrations.
7. **Platform integration**
   Secret Service, notifications, portals, power inhibition, lock screen, Bluetooth and emergency-state surfaces.

The application UI never blocks on modem, network, DNS or media operations.

## 5. Call state model

The internal state machine distinguishes:

- unavailable;
- account or SIM setup required;
- idle;
- dialing;
- ringing outgoing;
- ringing incoming;
- connecting media;
- active;
- held;
- transferring;
- disconnecting;
- ended with a reason;
- failed with a recoverable diagnostic.

Every transition is driven by an acknowledged transport event. The interface must not display `Connected` merely because the user pressed Call.

Call failure reasons include no service, rejected, busy, no answer, invalid number, account authentication failure, certificate failure, media negotiation failure, unsupported modem operation and network loss.

## 6. Main user experience

### Dialer

- locale-aware display with canonical international storage;
- `+`, pause and DTMF digits where applicable;
- number matching against contacts without uploading the address book;
- account/line selector when more than one route is available;
- clear roaming or paid-provider indication;
- keyboard, touch and assistive-technology operation.

### Incoming call

- caller identity from local contacts and verified provider metadata;
- Answer, Decline and optional Reply by Message;
- visible transport and account;
- lock-screen notification with privacy controls;
- ringing route independent from active-call route where PipeWire permits it;
- no automatic camera or microphone activation before acceptance.

### In-call view

- duration and connection state;
- mute, speaker/audio route, keypad, hold and end;
- add/merge/transfer only when supported;
- clear capture indicators;
- live network-quality warning for VoIP;
- compact window and mobile full-screen layout;
- immediate recovery surface after audio-device removal.

### History

- incoming, outgoing, missed and blocked classifications;
- transport/account and disconnect reason;
- grouped repeated calls;
- call-back, message, contact and delete actions;
- configurable retention and clear-all action;
- no call audio recording by default.

## 7. Contacts

Phone initially uses a small local contact store or a shared Edemint Contacts service once one is defined.

Required fields:

- display name;
- multiple phone numbers and SIP addresses;
- labels;
- avatar reference;
- favorites;
- block state;
- optional organization and notes.

Import/export uses an explicit vCard flow through the file portal. Remote synchronization is a separate provider integration and must never silently upload local contacts.

## 8. Audio and Bluetooth

Use PipeWire and WirePlumber for all user-facing audio routing.

Requirements:

- microphone and speaker selection;
- per-call mute and output volume;
- Bluetooth headset and hands-free profiles through BlueZ/PipeWire;
- wired-headset insertion/removal handling;
- echo cancellation and noise suppression where supported;
- proximity-sensor behavior only on hardware that exposes a suitable sensor;
- restore the previous media route after a call;
- do not expose unsupported telephony controls for ordinary A2DP-only devices.

A device becoming unavailable during a call triggers a visible fallback route, not silent call termination.

## 9. SMS relationship

Phone may expose `Send message` and missed-call reply actions, but the long-term message timeline belongs in Messenger.

The cellular adapter can provide SMS capability to a shared Edemint messaging service. Phone itself should not create a second, incompatible SMS database. Until that shared service exists, SMS support remains a bounded optional module.

MMS and carrier-specific rich messaging require separate architecture and provider validation and are not implied by basic SMS support.

## 10. Emergency calling

Emergency calling is safety-critical and must not be overclaimed.

- The UI must clearly identify which route, SIM and network will be used.
- SIP and data-only calling must never be described as reliable emergency service unless the configured provider explicitly supports it for the user's registered location.
- A Raspberry Pi or desktop without a supported voice modem cannot provide cellular emergency calls.
- Emergency numbers vary by country and must come from authoritative locale, SIM, modem or network data where possible.
- Lock-screen emergency access requires a dedicated threat model and physical-device testing.
- Location transmission, callback behavior, network registration without a SIM and regulatory requirements require country-specific validation.
- Failure to establish an emergency call must produce an immediate audible and visible error with alternative guidance.

No Edemint release may advertise emergency-call support based solely on a successful ordinary test call.

## 11. Security and privacy

- Phone never runs as root.
- Modem operations use ModemManager's system D-Bus policy.
- VoIP secrets use Secret Service and are redacted from logs.
- SIP uses TLS and secure media where the provider supports them; downgrade state is visible.
- Call history and cached contact data are encrypted at rest when the user session supports protected key storage.
- Caller-supplied names, SIP headers and metadata are treated as untrusted text.
- Links and received files open through portals and Inspector.
- Microphone access is limited to active call setup and calls, with persistent capture indicators.
- Recording is disabled by default. If later implemented, it requires explicit consent controls and jurisdiction-aware warnings.
- Diagnostic export excludes credentials, full phone numbers and contact data unless the user explicitly includes them.
- Spam reporting is opt-in and clearly states what data is transmitted.

## 12. Blocking and spam controls

- local block list;
- silence unknown callers option;
- provider spam-label display without treating it as infallible;
- user-controlled report action;
- rate limiting for repeated incoming VoIP calls;
- no cloud address-book upload as a prerequisite for spam protection;
- blocked callers do not bypass notification privacy through alternate display metadata.

## 13. Reliability

- preserve active calls when the main window is closed;
- inhibit suspend only while required for an active or ringing call;
- recover after NetworkManager connectivity changes;
- reconnect VoIP registration with bounded backoff;
- refresh modem state after USB disconnect/reconnect;
- retain accurate ended-call reason after restart;
- prevent duplicate call-history entries during daemon reconnect;
- protect the database with atomic migrations and corruption recovery.

A small user-session call service may own active call state independently of the window. It must have a narrow D-Bus API and terminate when no account, ringing call or active call requires it.

## 14. Accessibility

- full keyboard and switch-control operation;
- spoken labels and states for all call controls;
- large touch targets in mobile-shaped layouts;
- number entry announced correctly without exposing it on a locked screen;
- vibration/haptic hooks only on supported hardware;
- visual, audible and assistive-technology incoming-call signaling;
- high contrast and scalable text;
- color is never the only indicator for mute, hold, roaming or failed state;
- reduced-motion transitions.

## 15. Integration with other Edemint apps

- **Settings:** cellular account, SIM, roaming, preferred line, VoIP accounts, microphone, speakers and privacy.
- **Messenger:** SMS and message reply handoff.
- **Fullcall:** hand off team meetings or organization calls without sharing private account storage.
- **Contacts:** common contact records and caller matching.
- **Calendar:** create or join scheduled calls.
- **Activity Monitor:** identify Phone media/network activity without exposing call content.
- **Inspector:** safely preview received files.
- **Mission Control:** compact active-call presence without leaking caller information on shared displays.

## 16. Delivery phases

### Phase 0: hardware and protocol proof

- reserve application identity;
- prove Rust/GTK4 builds on `amd64` and `arm64`;
- enumerate ModemManager voice capability on supported test modems;
- select and audit the SIP/media library;
- prove PipeWire call audio and Bluetooth routing;
- define the call state machine and D-Bus boundary;
- create emergency-call non-claims and regional test policy.

Exit: at least one documented cellular voice modem and one SIP test provider complete ordinary two-way calls on physical hardware.

### Phase 1: cellular alpha

- modem/SIM/network status;
- dial, receive, answer, decline and end;
- DTMF, mute and audio routing;
- call history and missed-call notifications;
- modem removal and network-loss recovery;
- truthful unsupported-hardware setup screen.

Exit: repeatable cellular call suite passes without root application code.

### Phase 2: VoIP alpha

- SIP account setup and secure credential storage;
- registration diagnostics;
- incoming/outgoing secure calls;
- ICE/STUN/TURN and network change handling;
- provider certificate and media-security display.

Exit: two-way VoIP suite passes over Wi-Fi, Ethernet and a constrained network.

### Phase 3: contacts and multiple calls

- contacts, favorites and vCard import/export;
- multiple accounts and line selection;
- hold, second call, merge and transfer where supported;
- spam/block controls;
- Messenger SMS service integration.

Exit: capability-dependent controls and history reconciliation tests pass.

### Phase 4: production hardening

- independent security review;
- modem and SIP malformed-event tests;
- accessibility audit;
- suspend/resume and long-duration calls;
- battery, CPU, memory and thermal measurements;
- regional emergency behavior documentation;
- translations and right-to-left layouts;
- package migrations and recovery.

Exit: all applicable Definition of Done gates in `docs/APPLICATIONS_ROADMAP.md` pass.

## 17. CI contract

Before image construction:

- Rust formatting, linting, tests and dependency audit;
- `amd64` and `arm64` builds;
- call state-machine property tests;
- mocked ModemManager D-Bus tests;
- SIP signaling and secure-media fixtures;
- database migration and corruption tests;
- GTK headless launch test;
- AppStream and desktop-entry validation;
- package, license and installed-size reports.

Hardware-in-the-loop tests are required for modem calls, Bluetooth routes, microphones, speakers and suspend/resume. CI mocks cannot establish emergency-call readiness.

Superseded workflows use concurrency cancellation. Rerun only failed jobs when source and relevant inputs remain unchanged.

## 18. Image policy

Do not add a placeholder Phone launcher to either image.

Recommended rollout:

1. development package for supported hardware;
2. optional certified App Store package;
3. inclusion in mobile/device profiles with a supported modem;
4. optional desktop profile inclusion for SIP calling;
5. Pi inclusion only after a named compatible modem, audio route and performance budget are documented.

The generic desktop image may include Phone only when it remains useful as a VoIP client and clearly reports the absence of cellular hardware.

## 19. Definition of first release

Phone 1.0 requires:

- native Edemint GTK4 application;
- supported cellular voice calls through ModemManager;
- standards-based secure VoIP;
- reliable PipeWire and Bluetooth audio routing;
- contacts, favorites and call history;
- incoming/missed-call notifications;
- accurate capability and failure reporting;
- privacy-preserving storage and logs;
- accessible desktop and mobile-shaped layouts;
- reproducible `amd64` and `arm64` packages;
- physical modem and audio-device validation;
- explicit emergency-call limitations and regional evidence;
- no dependency on final icons or animation.

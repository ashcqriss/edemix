# Fullcall Native Application Roadmap

Status: approved product architecture; implementation pending

Fullcall is Edemint's custom team communication and collaboration application. It is not Microsoft Teams, a web wrapper, a renamed upstream client, or a launcher for an external website.

Icons and final animation are deferred. Functional, security and accessibility contracts come first.

## 1. Product scope

Fullcall provides:

- organizations and teams;
- public and private channels;
- direct and group messages;
- threaded replies, reactions, mentions and message search;
- voice and video calls;
- scheduled and instant meetings;
- screen and application-window sharing;
- file and image sharing;
- presence and availability;
- notifications and quiet hours;
- moderation, roles and invitations;
- offline history and queued sending;
- desktop, mobile-shaped and multi-monitor layouts.

Fullcall is distinct from Edemint Messenger. Messenger targets ordinary personal conversations. Fullcall targets structured teams, channels, meetings, roles and organizational administration. Shared protocol libraries may be reused, but application identity, settings and local data remain separate.

## 2. Technology decision

### Native client

Build the client as an Edemint-owned GTK4/libadwaita application written in Rust.

Reasons:

- native Wayland behavior and Edemint visual integration;
- memory safety for network, media and untrusted-message processing;
- strong asynchronous networking support;
- direct integration with PipeWire, XDG Desktop Portals, Secret Service and desktop notifications;
- one codebase for `amd64` and `arm64`;
- no embedded general-purpose browser requirement.

Proposed application identity:

- display name: `Fullcall`;
- application ID: `org.edemint.Fullcall` once the namespace is formally reserved;
- executable: `fullcall`;
- package: `edemint-fullcall`;
- user data: `$XDG_DATA_HOME/fullcall`;
- cache: `$XDG_CACHE_HOME/fullcall`;
- settings: GSettings under the application ID;
- credentials and access tokens: Secret Service, never plain-text configuration files.

### Communication protocol

Use open, documented protocols. The recommended baseline is Matrix for identity, synchronization, rooms, messages and end-to-end encryption, combined with WebRTC for real-time media.

Before implementation is locked, an architecture decision record must confirm:

- the exact Matrix client API level;
- the Rust SDK and crypto-store versions;
- the group-call signaling profile;
- the selected SFU deployment for calls larger than peer-to-peer limits;
- federation policy;
- server-side retention, moderation and abuse controls;
- compatibility with self-hosted and Edemint-certified service providers.

The operating-system image contains the client only. A homeserver, identity service, TURN service and optional SFU are server infrastructure and must not silently run on the user's computer.

## 3. Architecture

Keep boundaries explicit:

1. **Presentation layer**
   GTK4/libadwaita windows, adaptive navigation, message timeline, call surfaces and accessibility metadata.
2. **Application layer**
   account state, team/channel navigation, drafts, notifications, search orchestration and permission prompts.
3. **Protocol layer**
   Matrix synchronization, room state, encryption, message sending and media-event signaling.
4. **Media layer**
   WebRTC sessions, PipeWire capture/playback, echo cancellation, device selection and screen sharing.
5. **Storage layer**
   encrypted protocol state, SQLite indexes, drafts, cache limits and migration handling.
6. **Platform layer**
   Secret Service, XDG Desktop Portals, notifications, power inhibition, keyring, file chooser and Inspector handoff.

Protocol and media work must never run on the GTK main thread.

## 4. Core data model

Fullcall's user-facing model maps protocol primitives into stable product concepts:

- Organization: administrative boundary and account context.
- Team: collection of channels and members.
- Channel: ordered conversation with membership and permissions.
- Direct conversation: one-to-one or small private room.
- Thread: replies anchored to one root event.
- Meeting: real-time session associated with a channel, conversation or scheduled event.
- Role: owner, administrator, moderator, member or guest.
- Attachment: immutable uploaded content with MIME metadata, size and safety state.

The client must tolerate unknown protocol events and newer server features without losing the rest of a conversation.

## 5. User experience

### Main window

- adaptive team and account switcher;
- channel/conversation sidebar;
- searchable message timeline;
- composer with text, attachment, emoji, mention and reply controls;
- optional information panel for members, pinned messages, files and call state;
- keyboard-first navigation and complete focus order;
- no final icons required for the first functional build.

### Calling surface

- pre-call camera, microphone and speaker test;
- explicit join control;
- mute, camera, screen share, participant list and leave controls;
- active-speaker and grid layouts;
- network-quality indicator;
- permission and unsupported-hardware explanations;
- picture-in-picture or compact call window;
- safe recovery after device removal, network change or display rotation.

### Mobile-shaped layout

Use the same application and data model with adaptive GTK breakpoints. Sidebars become navigation pages; call controls retain large touch targets; the composer remains reachable when the software keyboard is visible.

## 6. Security and privacy

- End-to-end encryption is required for direct and private conversations before Fullcall claims private messaging.
- Encryption state must be visible and understandable, not represented by color alone.
- Device verification, recovery-key export and compromised-session removal are first-class flows.
- Access and refresh tokens use Secret Service.
- Local crypto state uses an encrypted store with atomic migrations.
- Message HTML is sanitized; arbitrary scripts and remote embedded content never execute.
- Link previews are opt-in or fetched through a privacy-preserving server policy.
- Attachments download to a quarantined location and offer `Open in Inspector` before ordinary applications.
- Camera, microphone, file and screen-sharing access use portals or narrowly scoped PipeWire permissions.
- Fullcall never runs as root and has no broad filesystem access.
- Logs redact tokens, message bodies, file paths and encryption material by default.
- Crash reporting is disabled by default and must never include message content or keys.
- Organizations can publish retention and recording policies that the client displays before participation.

## 7. Calls and media

### Audio

- PipeWire input/output discovery;
- per-device selection and hot switching;
- echo cancellation, noise suppression and automatic gain controls where supported;
- mute state synchronized with the meeting state;
- clear indicators whenever capture is active.

### Video

- PipeWire or portal-mediated camera access;
- capability-based resolution and frame-rate selection;
- bandwidth adaptation;
- hardware acceleration only when stable and measurable;
- fallback to software decode without crashing the call.

### Screen sharing

- XDG ScreenCast portal selection of screen or application window;
- PipeWire stream transport;
- persistent on-screen sharing indicator;
- one-action stop control;
- no silent capture or permission reuse beyond portal policy.

### Network

- ICE with configured STUN/TURN services;
- reconnect after Wi-Fi changes and suspend/resume;
- adaptive bitrate and packet-loss handling;
- diagnostic view that reveals connection quality without exposing credentials.

## 8. Files and Inspector integration

- Files are selected through the XDG file chooser portal.
- Upload shows name, type, size and destination before sending.
- Configurable upload limits prevent accidental multi-gigabyte transfers.
- Downloads are content-sniffed and extension mismatches are flagged.
- Unknown or active content opens in Inspector's read-only sandbox by default.
- Archive extraction, executable permission and macro execution are never automatic.
- Cached media obeys a user-visible storage limit and clear-cache action.

## 9. Accounts and administration

- password and SSO/OIDC sign-in where supported by the configured service;
- multiple accounts with clear organization identity;
- guest accounts separated from member accounts;
- invite, remove, ban, role and room-permission controls for authorized users;
- session list with device name, last activity and revoke action;
- no silent contact-book upload;
- server URL visible during sign-in to prevent service impersonation.

Enterprise policy may configure trusted homeservers and certificate authorities, but cannot hide capture, recording or encryption state from the user.

## 10. Offline behavior

- previously synchronized conversations remain readable offline;
- drafts save locally and atomically;
- outgoing messages queue with visible pending/failed state;
- retries are bounded and user-controllable;
- edits, reactions and redactions reconcile after reconnect;
- local search works over the synchronized encrypted index;
- cache corruption opens a recovery flow instead of blocking application startup.

## 11. Accessibility

- every control has a semantic name, role and state;
- complete keyboard operation and documented shortcuts;
- timeline updates announced without overwhelming screen readers;
- captions/subtitles architecture reserved from the first call implementation;
- high contrast, scalable text and reduced motion;
- color never carries status alone;
- minimum touch targets for mobile-shaped layouts;
- focus returns predictably after dialogs, channel changes and calls.

## 12. Delivery phases

### Phase 0: architecture proof

- create protocol/media decision records;
- reserve application ID and package name;
- prove GTK4/Rust builds on Debian Trixie `amd64` and `arm64`;
- prove account login and encrypted sync against a disposable test server;
- prove portal-based microphone, camera and screen capture;
- establish dependency, license and installed-size reports.

Exit: no unresolved protocol, SDK, license or architecture blocker.

### Phase 1: messaging alpha

- account sign-in/sign-out;
- team/channel and direct-conversation list;
- encrypted message timeline;
- send, edit, reply, react and redact;
- drafts, unread counts and notifications;
- attachment upload/download with Inspector handoff;
- local encrypted storage and migration tests.

Exit: two users can communicate securely across restart, offline and reconnect scenarios.

### Phase 2: calls alpha

- one-to-one voice/video;
- device preview and selection;
- mute/camera controls;
- portal screen sharing;
- TURN fallback and network diagnostics;
- suspend/resume and device-removal recovery.

Exit: calls pass physical-device tests on `amd64` and Raspberry Pi-class `arm64` hardware.

### Phase 3: teams and meetings beta

- organizations, teams, channels and roles;
- group meetings using the selected SFU architecture;
- invitations, guest access and moderation;
- meeting links, calendar handoff and scheduled notifications;
- participant grid, active speaker and compact call window.

Exit: documented multi-user load and moderation tests pass.

### Phase 4: production hardening

- independent security review;
- encryption interoperability and recovery tests;
- fuzzing for event parsing, media signaling and attachment metadata;
- accessibility audit;
- storage migration and downgrade behavior;
- bandwidth, CPU, memory and battery budgets;
- translation and right-to-left layouts;
- administrator deployment documentation.

Exit: all Definition of Done gates in `docs/APPLICATIONS_ROADMAP.md` pass.

## 13. CI contract

Lightweight gates run before either image build:

- Rust formatting, linting, unit tests and dependency audit;
- `amd64` and `arm64` builds;
- license and source inventory;
- protocol fixture and crypto-store tests;
- GTK headless launch smoke test;
- portal mock tests;
- malformed-event and attachment fixtures;
- AppStream and desktop-entry validation;
- package and installed-size diff.

Only after lightweight gates pass:

- add `edemint-fullcall` to an application test image;
- run the `amd64` ISO contract;
- run physical audio/video/screen-sharing tests;
- start a Pi image build only when arm64 package contents changed and the measured size/performance budget is acceptable.

Superseded workflows use concurrency cancellation. Rerun only failed jobs when source and relevant inputs are unchanged.

## 14. Image policy

Do not add Fullcall to either image until Phase 1 has a functional, tested package. A placeholder launcher would misrepresent the product.

Recommended rollout:

1. installable development package;
2. optional certified App Store package;
3. desktop image inclusion after messaging and call stability gates;
4. Pi image inclusion only after memory, storage, camera and hardware-decode measurements.

## 15. Definition of first release

Fullcall 1.0 requires:

- native Edemint GTK application, not a browser wrapper;
- encrypted messaging and device verification;
- reliable one-to-one and group voice/video calls;
- screen sharing through the Wayland portal;
- teams, channels, direct conversations and roles;
- safe files through Inspector;
- offline history, drafts and queued sending;
- accessibility audit;
- reproducible `amd64` and `arm64` packages;
- physical-device validation;
- clear service, privacy, retention and recording disclosures;
- no dependency on final icons or animations.

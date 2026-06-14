# ADR: Phone Is an Independent Application

Status: accepted

## Decision

Phone is a complete, independently installable and independently usable Edemint application.

Its product and package identity is:

- display name: `Phone`;
- application ID: `org.edemint.Phone` after namespace reservation;
- executable: `edemint-phone`;
- package: `edemint-phone`;
- optional user-session service: `edemint-phone-service`;
- settings namespace: owned exclusively by Phone;
- call history, contacts, favorites and account metadata: owned exclusively by Phone;
- credentials: separate Phone entries in Secret Service;
- release version and migration lifecycle: independent from every other Edemint application.

## Required independence

Phone must work when Fullcall, Messenger, Contacts, Calendar and every optional communication application are absent.

A standalone Phone installation includes all functionality required for:

- cellular and SIP account setup;
- dialing and receiving calls;
- incoming-call and missed-call notifications;
- call history;
- a built-in local contact book and favorites;
- voicemail-number configuration;
- microphone, speaker and Bluetooth routing;
- blocking and spam controls;
- offline account and history access;
- diagnostics and recovery.

Phone must not import or link against another Edemint application's private database, settings schema, account store, executable or background process.

Phone must not require Fullcall or Messenger to start, place calls, receive calls, display contacts or retain call history.

## Optional interoperability

Integration with other applications is limited to documented, optional system interfaces:

- open a telephone number in Phone through a registered `tel:` handler;
- offer `Send message` through a system intent when Messenger is installed;
- export or import contacts through vCard or a future public contacts API;
- create calendar events through a portal or documented calendar API;
- hand a team-meeting link to Fullcall through a URI handler;
- preview received files through Inspector;
- expose non-sensitive process/resource information to Activity Monitor.

Every optional handoff must detect when the target application is unavailable and keep Phone operational. No integration may transfer credentials, private databases or encryption keys.

## Process boundary

The graphical process and optional call service belong only to Phone.

The optional user-session service may keep an incoming or active call alive after the window closes. Its D-Bus API must be versioned, narrowly scoped and documented. Other applications may request a call through that public API but cannot manipulate Phone's private state.

System services such as ModemManager, PipeWire, WirePlumber, BlueZ, NetworkManager and Secret Service are operating-system dependencies, not application dependencies. Using those services does not make Phone part of another app.

## Packaging boundary

`edemint-phone` must declare its own runtime dependencies and must never depend on packages named `edemint-fullcall`, `edemint-messenger`, `edemint-contacts` or `edemint-calendar`.

Optional integrations use `Recommends`, `Suggests`, portals, URI handlers or runtime feature detection only when appropriate. Removing another Edemint application must not remove Phone or damage its data.

## Data boundary

Phone owns versioned storage for:

- calls;
- local contacts;
- favorites;
- blocks;
- cellular and VoIP account metadata;
- voicemail configuration;
- application preferences.

Exports and inter-application transfers use explicit schemas. Phone never reads another application's files directly.

Uninstalling Phone must not delete another application's data. Uninstalling another application must not delete or invalidate Phone's data.

## Acceptance tests

Independence is proven by CI and package tests that:

1. install Phone into a minimal Edemint application environment without Fullcall, Messenger, Contacts or Calendar;
2. launch and complete first-run setup;
3. create, edit, search and delete a local contact;
4. place and receive mocked cellular and SIP calls;
5. preserve call history across restart;
6. route audio through mocked PipeWire devices;
7. handle unavailable optional URI handlers without crashing;
8. remove each optional communication application and repeat Phone smoke tests;
9. upgrade and migrate Phone without installing another Edemint application;
10. remove Phone without changing another application's files or settings.

A release that fails these tests is not an independent Phone application and must not be shipped under this design.

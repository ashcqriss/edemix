# Microsoft Teams Integration

Status: transitional web integration

## Decision

Edemint provides Microsoft Teams as a web-service launcher, not as a bundled native application.

Microsoft does not provide a maintained native Debian Teams package suitable for inclusion in the Edemint images. Microsoft documents Teams for Web support on Linux in Firefox, so the first implementation opens `https://teams.microsoft.com/` in the Firefox ESR recovery browser already included in Edemint.

The launcher must remain truthful:

- the application name identifies the Microsoft service;
- metadata records that delivery is web-based;
- Edemint does not claim ownership of Teams;
- no Microsoft executable, account credential, cookie or proprietary asset is redistributed;
- final icon work remains deferred and must follow Microsoft trademark rules.

## Current integration

`edemint-teams.desktop` launches Teams for Web in a new Firefox ESR window.

This provides a visible application entry without adding a new package, external APT repository, proprietary binary or image-size cost beyond the existing browser.

A Microsoft account and any license required by the user's organization remain the user's responsibility.

## Functional acceptance

Before the launcher is considered release-ready, verify on physical `amd64` and `arm64` Edemint sessions:

- sign-in and sign-out;
- organization and personal account selection where Microsoft permits it;
- chat and channel navigation;
- meeting join by URL;
- camera and microphone permission prompts;
- speaker and microphone selection through PipeWire;
- notifications through the browser and desktop portal;
- file upload through the XDG file chooser portal;
- download routing and `Open in Inspector` handoff;
- screen sharing through Wayland, PipeWire and XDG Desktop Portal;
- keyboard navigation, zoom and screen-reader behavior;
- logout and cookie removal behavior.

Unsupported or degraded web-client capabilities must be documented rather than hidden.

## Security and privacy

- Teams remains isolated by the browser security model.
- Camera, microphone, notifications, file access and screen sharing require explicit permission.
- The launcher never stores a username or password.
- Credentials and session cookies remain under the browser's storage controls.
- Untrusted downloads should be offered to Inspector before another application opens them.
- Enterprise certificate, proxy and device-management support is a separate administrator feature.
- Telemetry is governed by Microsoft and the user's organization; Edemint must link to the applicable Microsoft privacy information instead of claiming that Teams is telemetry-free.

## Future options

A more app-like Edemint web container may be considered only if it:

- uses a browser engine Microsoft actively supports for Teams for Web;
- receives timely engine security updates;
- supports portals, PipeWire and Wayland screen sharing;
- keeps site data isolated from ordinary browsing;
- exposes clear permission and data-removal controls;
- does not bypass Microsoft licensing or service terms.

Do not build an unofficial Teams protocol client by reverse engineering private APIs. If Microsoft later publishes a supported Linux client or packaging channel, evaluate its architecture support, license, update mechanism, sandboxing and redistribution terms before replacing this launcher.

## Relationship to Messenger

Teams is a service-specific optional communication entry. It does not replace the planned Edemint Messenger, whose open baseline remains subject to a separate protocol decision. Messenger and Teams must have distinct identities, storage and permission surfaces.

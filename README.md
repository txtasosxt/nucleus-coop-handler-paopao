# PAO PAO Demo: two players on one PC

A Nucleus Co-op handler and launcher for **PAO PAO Demo**, Steam app **3498580**.
Two real Steam accounts play on one Windows PC, with separate controllers and
screen regions. Sandboxie Plus separates the second Steam session. Creating or
joining a lobby stays in the game menus.

This unofficial experiment targets the **demo**, tested with Unity 6000.3.12f1
and Nucleus Co-op 2.4.2. Compatibility with the full game or another build has not
been established. A single-account attempt did not work in this setup; use two
accounts, each entitled to the demo/game being played.

## Working and unfinished

Runtime testing confirmed two real accounts in one lobby, independent Xbox
Bluetooth controllers, background input, automated Nucleus launch, a two-monitor
layout and reversing the accounts between regions. **Nucleus runs unelevated**;
the boxed helper still requests elevation, so the entire setup is not unelevated.

**Audio separation still needs testing/tweaking.** Cold Steam starts, startup
cancellation, save isolation and future/full-game builds are not established.
The tested starting point is two saved, already signed-in Steam clients.

## Install

1. Prepare normal Steam and a second Steam client in a Sandboxie box named
   `SteamPlayer2`, signed into different accounts. Disable Steam Input for the
   demo in both clients. See the [setup guide](docs/automated-launch.md).
2. [Stage the supported XInput backend patch](docs/xinput-backend.md), retain its
   original backup, then manually install the staged settings asset. An unmodified
   tested build used Windows Gaming Input, which the XInput hook did not intercept.
3. From the downloaded repository root, build the helper:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher\build.ps1
   ```

   This uses Windows PowerShell 5.1 and the installed .NET Framework compiler;
   no IDE or NuGet packages are needed. Python 3 is used only for staging the patch.
4. Copy `build\PaoPaoNucleusLauncher.exe` beside `NucleusCoop.exe`. Copy
   `handlers\Pao Pao Demo.js` into Nucleus's `handlers` folder. Keep a backup of
   the previous handler outside that folder.
5. Configure your Sandboxie path, controller indices and screen order at the top
   of the handler. The shipped `[2, 1]` indices are examples for normal/boxed Steam;
   calibrate on your PC. Optional local settings support other Steam/library paths.
6. Close both games and standalone Proto Input Hosts. Keep both Steam clients
   signed in. Open Nucleus normally, add/select the demo's `PaoPao Demo.exe`, choose
   **PAO PAO Demo (Automated Steam + Sandboxie)**, assign two regions and press Play.

Steam login, Steam Guard, updates and UAC can still need your interaction.
Nucleus supplies the x64 Proto Input libraries; no game files, platform libraries,
compiled binaries, accounts or saved profiles are distributed in this repository.

## How it works

The helper launches one game through each Steam client and starts a worker in
that context. Both workers use OpenXinput with DirectInput redirection disabled.
Normal Steam uses **Remote Load Library** injection; the boxed game uses
**EasyHook Inject**. Workers remain alive until their games close. Nucleus finds
and positions the resulting windows; its own injection methods stay disabled.

Success returns exit code **zero**, not the game PID: Sandboxie's elevated
launcher displays an error for a nonzero child exit status. Game PIDs stay in
local logs. The current handler makes no extra game copies, installs no emulators,
changes no platform DLLs, and does not set Documents/OneDrive paths.

## Guides

- [Setup, mapping and troubleshooting](docs/automated-launch.md)
- [Exact-build XInput patch and rollback](docs/xinput-backend.md)
- [Audio routing: unfinished](docs/audio.md)
- [Developer checks and runtime evidence](docs/testing.md)
- [Archived manual workflow](docs/nucleus-steam-layout.md)
- [Historical emulator crash investigation](docs/startup-crash.md)

Share only relevant, redacted errors. Do not publish account IDs, authentication
tickets, tokens, credentials, personal paths, audio endpoint IDs or saved profiles.
The optional `PaoPaoNucleusLauncher.local.ini` is ignored by Git and stays private.

References: [Nucleus handlers](https://www.splitscreen.me/docs/create-handlers/),
[Proto Input](https://www.splitscreen.me/docs/proto/),
[Nucleus source](https://github.com/SplitScreen-Me/splitscreenme-nucleus),
[Sandboxie command line](https://sandboxie-plus.github.io/sandboxie-docs/Content/StartCommandLine.html).

This project is not affiliated with the game developer, Valve, Sandboxie or the
Nucleus team. Test compatibility with another build rather than assuming it.

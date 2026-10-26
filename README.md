# PAO PAO: two players on one PC

A Nucleus Co-op handler and launcher for **PAO PAO**, with the earlier demo
handler retained separately.
Two separate Steam accounts play on one Windows PC, with separate controllers and
screen regions. Sandboxie Plus separates the second Steam session.

| Game | Steam app | Handler | Setup |
| --- | --- | --- | --- |
| Full game, supported settings build 26220223 | 3024130 | `handlers/Pao Pao.js` | [Full-game guide](docs/full-game.md) |
| Earlier demo | 3498580 | `handlers/Pao Pao Demo.js` | Demo steps below |

Both require a supported XInput settings patch and Steam Input disabled in both
clients. The full game's controller fix was confirmed during testing; see
[validation and limits](docs/testing.md) for the distinction between runtime
results and offline checks. Other builds need separate verification.

## Install the full game

Follow the [full-game guide](docs/full-game.md) to stage the patch, check for a
private Sandboxie copy, configure controllers and build the helper:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher\build-full-game.ps1
```

Copy the generated `build/handlers/Pao Pao.js` and `build/handlers/Pao Pao/`
directory into Nucleus's `handlers` directory. The full-game helper belongs
inside `handlers/Pao Pao`, resolved through `Game.Folder`. Shared Proto Input
libraries stay in Nucleus's root. Start both Steam clients, keep both games
closed, add `PaoPao.exe` to Nucleus, assign two controllers and regions, and Play.

## Install the demo

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
   calibrate on your PC. For custom Steam or game paths, create
   `PaoPaoNucleusLauncher.local.ini` beside `NucleusCoop.exe`.
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

Both instances run through their respective Steam clients using the existing
game installation.

## Guides

- [Full-game installation and troubleshooting](docs/full-game.md)
- [Setup, mapping and troubleshooting](docs/automated-launch.md)
- [Exact-build XInput patch and rollback](docs/xinput-backend.md)
- [Audio routing: unfinished](docs/audio.md)
- [Developer checks and runtime evidence](docs/testing.md)

References: [Nucleus handlers](https://www.splitscreen.me/docs/create-handlers/),
[Proto Input](https://www.splitscreen.me/docs/proto/),
[Nucleus source](https://github.com/SplitScreen-Me/splitscreenme-nucleus),
[Sandboxie command line](https://sandboxie-plus.github.io/sandboxie-docs/Content/StartCommandLine.html).

This project is not affiliated with the game developer, Valve, Sandboxie or the
Nucleus team.

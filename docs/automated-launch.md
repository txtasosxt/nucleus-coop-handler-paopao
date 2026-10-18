# Setup and troubleshooting

This guide targets the demo/build described in the [README](../README.md).

## Steam sessions and prerequisites

1. Install Sandboxie Plus and create a box named `SteamPlayer2`.
2. Sign normal Steam into one account. Through Sandboxie's UI, run Steam inside
   the box and sign into a different account. Both must have access to the demo.
   Putting a numeric Steam ID in Nucleus does not authenticate that account.
3. Check that each client launches the demo to its menu, then close the games.
   Keep both Steam clients signed in for the first automated test.
4. In **both** clients: demo Properties -> Controller -> **Disable Steam Input**.
5. Apply the [supported XInput backend patch](xinput-backend.md) to the active
   `PaoPao Demo_Data` folder, not an older Playtest Data folder.

This tested authentication workflow needs Sandboxie; Nucleus generally does not.
Earlier emulator trials did not supply working online authentication. No account
credentials are read by the helper, and no platform DLL replacement is required.

## Build and install

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher\build.ps1
```

The execution-policy override applies only to that process. The build uses the
installed Windows .NET Framework compiler without NuGet packages or an IDE.

Close Nucleus and the games, then copy these files into your Nucleus directory:

| Source | Destination relative to Nucleus |
| --- | --- |
| `build\PaoPaoNucleusLauncher.exe` | `PaoPaoNucleusLauncher.exe` |
| `handlers\Pao Pao Demo.js` | `handlers\Pao Pao Demo.js` |

Back up a previous handler outside `handlers`. The EXE belongs beside
`NucleusCoop.exe`, not inside `handlers`. Update both files from the same revision.
The Nucleus x64 installation must provide `ProtoInputLoader64.dll`,
`ProtoInputHooks64.dll`, `ProtoInputIJ64.exe` and `ProtoInputIJP64.dll`.

## Handler settings

Edit the variables at the top of the installed handler:

```javascript
var PaoPaoControllerIndices = [2, 1];
var PaoPaoSwapScreenAssignments = true;
var PaoPaoSandboxStart = "C:\\Program Files\\Sandboxie-Plus\\Start.exe";
var PaoPaoSandboxName = "SteamPlayer2";
```

- Set `PaoPaoSandboxStart` to **your** Sandboxie executable path.
  Update this value if Sandboxie Plus is installed elsewhere.
- Use a box name containing letters, digits or underscores, without extra quotes.
- Controller indices are **normal Steam first, boxed Steam second**. They must be
  different integers from 1 to 32. Nucleus's icons allocate regions, while these values
  control actual controller routing.
- `PaoPaoSwapScreenAssignments = true` puts the boxed game in the first Nucleus
  region and normal Steam in the second. `false` reverses that. Left/right comes
  from your layout, not hard-coded monitor numbers.

`Game.RequiresAdmin = false` permits normal Nucleus startup. The boxed helper still
uses Sandboxie's `/elevate` and may require a UAC confirmation.

## Non-default Steam or game locations

Defaults are Steam under Program Files (x86), and the demo in that installation's
`steamapps\common\Pao Pao Demo`. For other paths create
`PaoPaoNucleusLauncher.local.ini` beside `NucleusCoop.exe`, for example:

```ini
SteamExe=C:\Program Files (x86)\Steam\steam.exe
GameDirectory=E:\SteamLibrary\steamapps\common\Pao Pao Demo
```

Include only overrides needed on your machine. Use absolute, unquoted paths;
`GameDirectory` contains the EXE and Data folder. Blank lines and `#`/`;` comments
are ignored. Workers read the file in their own Windows/Sandboxie context. This
override parser has offline checks; alternate-library startup is not runtime
verified.

## Start and verify

Connect controllers and monitors. Keep both clients signed in, but close both
games and standalone Proto Input Hosts. Start Nucleus outside Sandboxie, select
the handler, allocate two regions and press Play. The helper launches/injects;
Nucleus finds and positions each process. Create/join the lobby in the game menus.
Steam login, Guard, update and UAC prompts remain interactive.

Both workers use OpenXinput, raw-input/cursor/XInput/focus hooks and a 5 ms focus
message loop. DirectInput redirection, fake cursor drawing and input locking are
off. Remote Load Library is used normally; EasyHook is used inside the box.

Settings shortcuts: Right Ctrl + Right Alt + top-row **1** for normal Steam,
**2** for boxed Steam. Hide the GUI before checking controls. Keep the input worker
alive while playing; closing an injected console can terminate its game.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Awaiting compatible devices | Current handler keeps `XinputHook = true` for discovery, with Nucleus injection methods disabled. |
| Both controllers affect one game / XInput calls stay zero | Exact backend patch, Steam Input off in both clients, OpenXinput on. |
| Wrong controller or screen | Calibrate the controller array; use the screen-swap flag to change account placement. |
| Missing Sandboxie executable | Correct the configured `Start.exe` path. |
| Invalid box name | Bare `/box:SteamPlayer2`, not `/box:"SteamPlayer2"`. |
| Numeric Sandboxie error despite a launched game | Matching current helper/handler: success must return zero, not the game PID. |
| Jint constructor error | Current handler resolves the framework assembly explicitly. |
| Unknown settings hash | Stop and investigate that build; do not remove the check or force the old patch offset. |
| Game exits before input-ready | Read the launcher error; a game exit is different from an injection timeout. |
| Wrong audio | See the [unfinished audio guide](audio.md); audio numbers follow screen-slot order. |

Logs are `paopao-automation-player-1.log` (normal) and
`paopao-automation-player-2.log` (boxed), in the logical Nucleus folder. Use
Sandboxie's box-content browser to locate the boxed physical copy; the root is
configuration-dependent.

Nucleus session-start cleanup can close matching games. Its Stop command is
intended to close attached games; workers exit when their games exit. Complete
shutdown/cancellation and cold-client behavior need separate runtime checks.

## Rollback

Close games/Nucleus and restore the previous matching handler/helper pair. For
the game-settings asset, restore its original backup as explained in the patch
guide. Steam verification/update may also restore/replace it, after which the
launcher's patched-hash check stops until a supported XInput asset is installed.

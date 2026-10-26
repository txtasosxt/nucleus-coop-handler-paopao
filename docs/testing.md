# Validation and limits

## Demo runtime evidence

The tested PC/build passed: two real Steam accounts in one lobby; independent
Xbox Bluetooth controllers; background input; direct helper launches; automated
Nucleus startup and placement; swapping accounts between two monitors; and normal
unelevated Nucleus startup. The boxed helper still requests elevation. OpenXinput
is enabled in both workers, with DirectInput redirection and Steam Input off.

Both launch orders were tried. A game PID used as a nonzero exit status caused a
misleading Sandboxie error despite a successful game launch. Success now returns
zero. Earlier genuine injection failure and that exit-status issue are distinct.

Audio separation remains unresolved. A single-account attempt did not work in this
setup. Later-build compatibility, save isolation, cold Steam startup,
startup cancellation and complete shutdown are not established. Local path
overrides are covered offline but alternate-library startup is not runtime tested.

## Full-game evidence and checks

The full game's logs selected Windows.Gaming.Input. In a clean boxed Steam launch,
controllers worked in Big Picture but not gameplay with Steam Input disabled.
Enabling Steam Input restored gameplay. After Proto Input injection, both
controllers still controlled the game in the background even when all four
XInput indices were zero. That workaround did not establish isolation.

For build 26220223, the XInput patch was derived from the exact Unity version's
PlayerSettings tree. All known bytes roundtripped identically; the unparsed
four-byte tail and every other object were preserved. Exactly one byte changed
at offset 2164. The tester reported the patched setup working. Full two-account
automated launch/lobby testing was not repeated after the publication changes;
the final helper hash guard and package layout are validated offline.

Build/check commands (run from the repository root):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher\build-full-game.ps1
py -3 -m unittest discover -s tests -p test_prepare_xinput.py -v
node --check '.\handlers\Pao Pao.js'
pwsh -File .\tests\check-full-game-automation.ps1 -NucleusDirectory 'C:\NucleusCoop' -LauncherPath '.\build\handlers\Pao Pao\PaoPaoFullNucleusLauncher.exe'
powershell -NoProfile -File .\tests\check-full-game-launch-interop.ps1 -NucleusDirectory 'C:\NucleusCoop' -LaunchRoot '.\build' -LauncherPath '.\build\handlers\Pao Pao\PaoPaoFullNucleusLauncher.exe'
```

The full-game tests evaluate typed handler objects, both region/account mappings,
actual .NET Framework/Jint process construction, `Game.Folder` helper resolution,
bare Sandboxie box quoting, exit handling and offline helper self-tests. They
never launch Steam/games or inject. Patch-tool unit tests use synthetic bytes;
local supported originals were separately checked against the published hashes.
No game assets are needed for the unit tests or included in the repository.

## Launcher exit status

Success returns exit code **zero**, not the game PID: Sandboxie's elevated
launcher displays an error for a nonzero child exit status. Game PIDs stay in
local logs.

## Offline checks

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher\build.ps1
.\build\PaoPaoNucleusLauncher.exe --self-test
node --check '.\handlers\Pao Pao Demo.js'
```

The helper checks input plans, worker numbering, local path parsing and zero
success status without launching Steam/games or calling injection APIs.

With PowerShell 7, substitute your Nucleus path:

```powershell
pwsh -File .\tests\check-automation.ps1 -NucleusDirectory 'C:\NucleusCoop' -LauncherPath .\build\PaoPaoNucleusLauncher.exe
```

This evaluates typed Nucleus/Jint objects, replaces game launching before callbacks,
checks both screen orders and controller/account mapping, rejects invalid slots
and duplicate controllers, and checks installed hook IDs/API presence.

For Nucleus's .NET Framework/Jint runtime use **Windows PowerShell 5.1**:

```powershell
powershell -NoProfile -File .\tests\check-launch-interop.ps1 -NucleusDirectory 'C:\NucleusCoop' -LauncherPath .\build\PaoPaoNucleusLauncher.exe -SandboxieStart 'C:\Program Files\Sandboxie-Plus\Start.exe'
```

Copy the helper into Nucleus first for request construction. The check constructs
both real launch requests, verifies bare Sandboxie box names and zero/nonzero exit
handling. Real `Process.Start` executes **only the helper's offline self-test**;
full callbacks replace process creation with a recorder. No game is injected.

The archived restoration and manual-layout checks target `experiments/`, not the
current handler. Restoration fixtures are marker files, never executable DLLs.

## Runtime verification

Check launch, stable windows, account login, independent controllers, background
input, intended screen regions and a shared lobby separately. Check Stop/restart
separately. Verify audio audibly: a routing API log does not prove output isolation.

# Validation and limits

## Runtime evidence

The tested PC/build passed: two real Steam accounts in one lobby; independent
Xbox Bluetooth controllers; background input; direct helper launches; automated
Nucleus startup and placement; swapping accounts between two monitors; and normal
unelevated Nucleus startup. The boxed helper still requests elevation. OpenXinput
is enabled in both workers, with DirectInput redirection and Steam Input off.

Both launch orders were tried. A game PID used as a nonzero exit status caused a
misleading Sandboxie error despite a successful game launch. Success now returns
zero. Earlier genuine injection failure and that exit-status issue are distinct.

Audio separation remains unresolved. A single-account attempt did not work in this
setup. Full-game/later-build compatibility, save isolation, cold Steam startup,
startup cancellation and complete shutdown are not established. Local path
overrides are covered offline but alternate-library startup is not runtime tested.

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

Publish only relevant redacted messages. Do not include game assets, platform
DLLs, account IDs, credentials, authentication tickets, personal paths, audio
endpoint IDs, saved profiles, dumps or full runtime logs.

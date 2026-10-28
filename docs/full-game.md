# PAO PAO full-game setup

This handler targets Steam app **3024130**, executable `PaoPao.exe`, and active
data folder `PaoPao_Data`. The supported settings asset is from Steam build
**26220223**, Unity **6000.3.12f1**. The demo uses a different handler, app ID,
executable and settings patch. Updating to the full game requires adding
`PaoPao.exe` to Nucleus; the old demo entry does not identify it.

## Prerequisites

- Windows with Nucleus Co-op and its bundled x64 Proto Input libraries. Offline
  integration checks were run against Nucleus 2.4.2 and its installed Jint runtime.
- Sandboxie Plus with a box named `SteamPlayer2`.
- Two Steam accounts, each with its own entitlement to PAO PAO. Start one Steam
  client normally and the other inside `SteamPlayer2`; sign in and complete
  Steam Guard, game updates and any first-run prompts before using Nucleus.
- Two controllers. The reference setup uses official Xbox Bluetooth controllers.
- Python 3 for the local patch tool and Windows PowerShell 5.1/.NET Framework
  for compiling the launcher. No Unity editor, IDE or NuGet packages are required.

Nucleus can run without administrator rights. Sandboxie's boxed launch command
requests elevation and may show UAC. The helper does not sign accounts in.

## 1. Prepare the XInput settings patch

Close both games. From the repository root, substitute the actual library path:

```powershell
py -3 .\tools\prepare_xinput.py 'C:\Program Files (x86)\Steam\steamapps\common\PaoPao\PaoPao_Data\globalgamemanagers' --output-dir .\build\full-game-xinput
```

The tool accepts only a verified original file hash, stages a one-byte patch and
an original backup, and verifies the resulting hash. It never changes the input
or installs anything. A renamed original backup can also be passed as input.
Keep `globalgamemanagers.original-backup` somewhere safe outside the install.

Manually copy the staged `globalgamemanagers` into the game's active
`PaoPao_Data` folder. **Check Sandboxie's private copy too:** use Sandboxie Plus's
box-content browser for `SteamPlayer2` and look for the corresponding Steam
library path under its virtual drive. If a private `PaoPao_Data/globalgamemanagers`
exists, back it up separately and replace it with the same supported patched
file. A private copy shadows the host installation. Verify that it belongs to
the same supported build before replacing it; do not overwrite a different build.

In **both** Steam clients, PAO PAO -> Properties -> Controller -> select
**Disable Steam Input**. Restart games after any change to this setting or asset.

The original full-game build selected Windows.Gaming.Input. Enabling Steam Input
restored boxed gameplay input, but both controllers still affected the game even
with all Proto Input XInput indices set to zero. The XInput settings patch fixes
the backend mismatch; Steam Input should remain disabled for this workflow.
See [exact hashes, derivation and rollback](xinput-backend.md).

## 2. Build and install the handler

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher\build-full-game.ps1
```

Copy the contents of `build/handlers` into Nucleus's `handlers` directory:

```text
NucleusCoop/
  NucleusCoop.exe
  ProtoInputLoader64.dll       (already supplied by Nucleus)
  ...other bundled SDK files...
  handlers/
    Pao Pao.js
    Pao Pao/
      PaoPaoFullNucleusLauncher.exe
```

The helper is a handler asset, found through `Game.Folder`. It walks parent
directories to find Nucleus's bundled SDK; do not copy SDK or game DLLs into
the handler asset folder. The demo handler/helper can remain installed.

Edit these generic settings at the top of the installed `Pao Pao.js`:

- `PaoPaoSandboxStart`: actual Sandboxie `Start.exe` path. Its default is
  `C:\Program Files\Sandboxie-Plus\Start.exe`.
- `PaoPaoSandboxName`: `SteamPlayer2`, or your existing box name.
- `PaoPaoControllerIndices`: normal Steam's and boxed Steam's OpenXinput indices.
  `[2, 1]` is an example, not a fixed identity for controller colors. Nucleus's
  device assignments do not override this explicit mapping. Keep indices distinct.
- `PaoPaoSwapScreenAssignments`: `true` assigns boxed Steam to Nucleus's first
  region and normal Steam to the second; `false` reverses that order. Nucleus's
  region numbering does not necessarily match physical monitor position.

For a custom Steam/library location, create
`handlers/Pao Pao/PaoPaoFullNucleusLauncher.local.ini` locally:

```ini
SteamExe=C:\Program Files (x86)\Steam\steam.exe
GameDirectory=E:\SteamLibrary\steamapps\common\PaoPao
```

Use absolute, unquoted paths. This file, logs and compiled outputs are ignored
by Git. The helper verifies the supported patched hash in its own context before
launching or injecting, including inside Sandboxie, and never edits game assets.

## 3. Launch

1. Start Steam normally and inside `SteamPlayer2`, with the two accounts signed in.
2. Keep both games and standalone Proto Input Hosts closed.
3. Open Nucleus, add/select `PaoPao.exe` and the **PAO PAO** handler.
4. Choose two screen regions and assign the controllers. If Nucleus remains on
   `Awaiting handler compatible devices...`, verify both controllers are connected
   and that the handler's XInput discovery flag has not been disabled.
5. Press Play and accept any Sandboxie/UAC prompt. The helper launches and injects
   each game; do not inject again manually. Create/join a lobby from the game menus.

Normal Steam uses Remote Load Library injection. The boxed worker uses EasyHook
inside the same box. Both enable XInput and OpenXinput, disable DirectInput
redirection, and run background focus hooks. Successful launches return exit code
zero. Nucleus's own injection methods stay off to avoid a second injection.

## Troubleshooting and rollback

The full-game helper's local logs are `paopao-full-player-1.log` and
`paopao-full-player-2.log` beside the helper; find the boxed log through Sandboxie's
box-content browser. Share only relevant redacted errors, not full game/Steam
logs, account IDs, authentication tickets, local paths or saved profiles.

If both controllers control one game, check Steam Input is disabled, both active
settings files match the patched hash, and the controller mapping is distinct.
A zero XInput call counter while gameplay works suggests the active input path
still bypasses the hook. Do not keep changing indices to compensate for a backend
mismatch. GUI shortcuts may open more than one injected panel; identify the
correct game instance before editing settings. Restart a game for a clean injection
baseline; closing Proto Input Host alone does not unload its injected DLL.

For rollback, close games and restore each original backup as `globalgamemanagers`
in its corresponding normal/private folder. Steam verification can restore the
normal install but does not necessarily replace Sandboxie's private copy. Updates
can replace assets; unknown hashes must be investigated before using another patch.
Remove the full-game handler script and its asset directory to uninstall it.
Audio separation remains unverified; see [testing limits](testing.md).

References: [handler asset folders](https://www.splitscreen.me/docs/create-handlers/#copy-a-specific-file),
[path variables](https://www.splitscreen.me/docs/handler-api/#17-path-variables),
[Proto Input](https://www.splitscreen.me/docs/proto/).

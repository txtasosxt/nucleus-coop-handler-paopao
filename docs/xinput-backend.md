# Exact-build XInput backend patch

The tested demo and full-game build used Windows Gaming Input. Both controllers affected the focused
game while Proto Input's XInput call counter stayed at zero. Setting Unity's
`windowsGamepadBackendHint` to 1 in `PaoPao Demo_Data/globalgamemanagers` selected
XInput. Controller isolation/background input then worked in the demo. The same
field was separately derived and the resulting patch confirmed working during
full-game testing; the demo's offset was not reused.

## Full game

| Property | Supported value |
| --- | --- |
| Game | PAO PAO, app 3024130, Steam build 26220223 |
| Active data folder | `PaoPao_Data` |
| Unity | 6000.3.12f1 |
| Settings file size | 642212 bytes |
| Original SHA-256 | `F034DEAC724D8A4E5545BDFC3B7C46C5E872842E457515C37A76C821BBFC6D80` |
| Patched SHA-256 | `30BAA662AC2EDA2F8A392855022535D1A22B4E2386A65E78AF94E755C36DDDB0` |
| Changed byte | Offset 2164, value 0 -> 1 |

Follow the [full-game guide](full-game.md), including replacing any private
Sandboxie copy and disabling Steam Input in both clients.

## Demo

| Property | Supported value |
| --- | --- |
| Game | PAO PAO Demo, app 3498580 |
| Unity | 6000.3.12f1 |
| Settings file size | 640244 bytes |
| Original SHA-256 | `325C6E008F8DEACCF01DA083A970D3751A195E3F49C5ED9777D9480E0DFE159D` |
| Patched SHA-256 | `AA75B042730B45999DED75C3662FE7E9861E55B52B32E2C27ED964A687AD4847` |
| Changed byte | Offset 2216, value 0 -> 1 |

The offset is valid **only for that complete original hash**, not every asset
with the same filename or Unity version. The launcher refuses any other patched
hash. Do not remove the guard to force another build.

Both changes were derived with the exact-version PlayerSettings schema,
requiring all known bytes to roundtrip unchanged and preserving an unknown
four-byte tail verbatim. The published standard-library tool needs no Unity
parser because it accepts only the already-verified entire file hash.

## Stage and install

These commands are for the **demo**; full-game commands are in the linked guide.
Close both games. Find the demo through Steam Properties -> Installed Files ->
Browse. Use `PaoPao Demo_Data`, not an older Playtest folder. With Python 3, run
from the repository root, substituting your actual library path:

```powershell
py -3 .\tools\prepare_xinput.py 'C:\Program Files (x86)\Steam\steamapps\common\Pao Pao Demo\PaoPao Demo_Data\globalgamemanagers' --output-dir .\build\xinput
```

The tool verifies the original size/hash, stages `build/xinput/globalgamemanagers`
and `globalgamemanagers.original-backup`, and verifies the patched hash. It refuses
unknown builds, conflicting outputs and overwriting the input. An already-patched
input is detected without writes. **It never installs the patch automatically.**

Keep the original backup safely outside the install. Manually copy the staged
`globalgamemanagers` over the active Data-folder asset. No original or modified
game asset is distributed here, and no platform DLL is changed by the tool.

## Restore or update

With games closed, copy the original backup back as `globalgamemanagers` and verify
its original hash. Steam file verification can restore the current Steam build
too. Updates/verification can change this asset: recheck after each update.
Unknown hashes need a fresh build-specific investigation. After restoration the
XInput-dependent launcher stops until a supported patched asset is installed.

For Sandboxie, restore the private copy separately if present. The normal Steam
installation and a private boxed copy can contain different versions of this file.

References: [Unity backend setting](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/PlayerSettings-windowsGamepadBackendHint.html),
[Unity enum source](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Editor/Mono/PlayerSettings.bindings.cs),
[exact-version type schema](https://github.com/AssetRipper/TypeTreeDumps/blob/main/InfoJson/6000.3.12f1.json).

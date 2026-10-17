# Exact-build XInput backend patch

The tested demo used Windows Gaming Input. Both controllers affected the focused
game while Proto Input's XInput call counter stayed at zero. Setting Unity's
`windowsGamepadBackendHint` to 1 in `PaoPao Demo_Data/globalgamemanagers` selected
XInput. Controller isolation/background input then worked.

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

The initial change was derived with the exact-version PlayerSettings schema,
requiring all known bytes to roundtrip unchanged and preserving an unknown
four-byte tail verbatim. The published standard-library tool needs no Unity
parser because it accepts only the already-verified entire file hash.

## Stage and install

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

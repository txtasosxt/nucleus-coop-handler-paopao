# Archived manual Steam + Sandboxie workflow

For normal installation use [automated launch](automated-launch.md). This guide
records the preceding successful manual workflow. Its layout-only script is
`experiments/manual-steam-sandboxie-layout.js`; do not install archived scripts
alongside the current handler.

Prepare two real signed-in Steam accounts, disable Steam Input in both and apply
the supported [XInput backend setting](xinput-backend.md). Use one fresh bundled
Proto Input Host per game, in the same context as that game:

| Setting | Normal Windows | SteamPlayer2 box |
| --- | --- | --- |
| Injection | Remote Load Library | EasyHook Inject |
| XInput / OpenXinput | Enabled | Enabled |
| DirectInput redirection | Disabled | Disabled |
| Assigned controller | Calibrated normal index | A different calibrated index |
| Other controller slots | 0 | 0 |

Enable Register Raw Input, Get Raw Input Data, Clip Cursor and Focus, with the
5 ms focus message loop. Leave input locking and fake cursor drawing off. Hide
the settings GUI while checking input. Indices are not permanent device colors.

Example boxed Host command, after substituting your actual install paths:

```text
"C:\Program Files\Sandboxie-Plus\Start.exe" /box:SteamPlayer2 /elevate "C:\NucleusCoop\ProtoInputHost.exe"
```

With the archived layout handler, start Nucleus with games closed. At each launch
prompt, manually launch and inject that context's game, acknowledge the prompt,
then select its game PID. Nucleus positions it; the manual Host owns input.
Session-start cleanup can close already-running matching games.

Restart a game to remove its injection cleanly; do not inject twice. Closing an
injected console just to hide it can terminate its game. Two standalone Hosts
both using instance 1 can open both settings GUIs with one shortcut; the current
automated workers assign separate instance numbers.

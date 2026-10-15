# Startup crash observed on 2026-10-15

The initial handler was loaded successfully in Nucleus. It produced separate
instance folders, configured the bundled emulators, and created game processes.
Each process exited before showing a game window. The player logs contained
only early Unity input/physics initialization messages.

Windows Application Error events (ID 1000) for three attempts identified:

- Application: `PaoPao Demo.exe`, from a Nucleus instance folder.
- Faulting module: `EOSSDK-Win64-Shipping.dll`, from the instance's
  `PaoPao Demo_Data\Plugins\x86_64` folder.
- Exception: `0xc0000409`.
- Fault offset: `0x00000000005f6059`.

The instance DLL's SHA-256 matched the bundled Nemirtingas emulator exactly;
it differed from the original Steam DLL. The original Steam installation was
not replaced, and the user confirmed the demo still reaches the menu from Steam.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| Steam original EOS DLL | 19531704 | `9C498FE31C8DF1D9085DFA9C71C6D50EC6B569ACDB29F1DECB97BE105B6341DC` |
| Nucleus bundled emulator / instance DLL | 11290112 | `D2282A61385A2AB7FAE90B3431BC2F7CEF65658BC923C8EB6BB3173A9A0993FC` |

These events establish the crashing module, not the precise failing function
or the cause of the exception. A dump with matching symbols would be needed
for a reliable internal diagnosis. They do not establish that controller input
or OneDrive caused the failure.

## Next diagnostic

`Game.UseNemirtingasEpicEmu` is now false. The remaining emulation/controller
settings stay in place to isolate the Epic library replacement. Because the
initial handler retains its game copies, simply changing the flag would leave
the old emulator DLL in those copies. `Game.ForceSymlink = true` makes Nucleus
refresh the full copies before the next trial; `Game.HardcopyGame = true`
continues to select copying rather than symlinking.

Expected next evidence: the copied EOS library matches Steam's original, then
the game either reaches a menu, reports an authentication failure, or records a
new crash. None of these outcomes has yet been verified for the revised handler.
Even a successful menu launch would leave two-player EOS authentication and
joining unresolved.

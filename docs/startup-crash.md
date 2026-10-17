# Startup crash observed on 2026-10-15

**Historical investigation:** this describes an earlier restoration handler,
now archived under `experiments/`, not the current working Steam + Sandboxie
workflow. Follow the [current setup guide](automated-launch.md) for installation.

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

## First diagnostic and why it did not take effect

`Game.UseNemirtingasEpicEmu` is now false. The remaining emulation/controller
settings stay in place to isolate the Epic library replacement. Because the
initial handler retains its game copies, simply changing the flag would leave
the old emulator DLL in those copies. A first attempt also enabled
`Game.ForceSymlink = true` to request a full-copy pass. The next runtime log
showed that the pass ran, but direct inspection found that both retained
instances still had the old emulator hash. The new attempt repeated the same
module, exception and fault offset. The copy pass did not restore the originals.

## Corrected diagnostic

The handler now explicitly overwrites the x64 EOS library in each instance
from its counterpart in Steam's original installation, after Nucleus's game
setup and before launching the game. It also restores the optional older
Playtest data folder when present. It rejects a destination inside the source
installation, linked directories, and a linked destination DLL. A missing
required source library fails before launch with an explanatory handler error.

Forced full copying is disabled again. `Game.HardcopyGame = true` continues to
select full game copies for the initial setup; explicit EOS restoration handles
the stale DLLs in subsequent launches.

Four isolated regression checks passed with the actual installed Jint engine:
cached demo and Playtest DLL replacement, absent optional Playtest folder,
source-destination rejection, and linked-directory rejection. The corrected
handler was installed with a backup. Both actual retained instances were
restored, and all four x64 EOS DLLs were verified against the Steam originals
by SHA-256. The original Steam files were verified unchanged.

Expected next evidence: the game either reaches a menu, reports an
authentication failure, or records a new crash. None of these game outcomes has
yet been verified for the revised handler; file restoration itself is verified.
Even a successful menu launch would leave two-player EOS authentication and
joining unresolved.

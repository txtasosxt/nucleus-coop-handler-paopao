# PAO PAO demo handler for Nucleus Co-op

Experimental handler for trying two players on one Windows PC with two Xbox
controllers. **This is a development trial, not confirmed PAO PAO support.**
No game files, emulator DLLs, account IDs or credentials are distributed here.

## Status

The starting target is the Steam demo, app **3498580**, executable
`PaoPao Demo.exe`. It does not target the unreleased full game, app 3024130.

Read-only inspection of an installed demo build found Unity 6000.3.12f1,
IL2CPP, Unity Input System, Unity Netcode, Steamworks and an EOS networking
transport. An existing player log referenced `EOSTransport`. These findings
explain the initial configuration; they do not establish that emulation works.

The first runtime trial failed during startup. Windows Application Error
reports name the bundled Epic emulator DLL with exception `0xc0000409`.
Disabling Epic emulation and forcing a full-copy pass did not overwrite the
cached emulator DLLs. The current revision explicitly restores the original EOS
libraries in each game copy before launch. This is a **startup diagnostic**,
not a completed multiplayer fix. See [the crash findings](docs/startup-crash.md).

The current handler attempts:

- Two game windows sized to the assigned Nucleus screen regions.
- One XInput controller per instance through Proto Input.
- Steam emulation while preserving the game's original Epic library.
- Fresh Nucleus user profiles and separate player logs.

**Not yet verified:** two-instance startup, authentication, session discovery,
joining, independent controls, independent saves, or clean shutdown.

Static validation passed: Node's JavaScript syntax check, verification of the
configured settings against the installed Nucleus library, and top-level
evaluation with Nucleus's own bundled Jint engine and typed game settings.
The initial handler loaded through Nucleus and created game processes; they
crashed before reaching the menu. The revised handler's launch result and all
gameplay tests remain pending.

The corrected restoration callback was executed with the installed Jint engine
against isolated file fixtures. Four regression checks passed: replacing both
cached libraries, handling an absent old Playtest folder, rejecting the source
as a destination, and rejecting a linked destination directory. The four EOS
DLLs in the two actual retained instances were also restored and verified by
SHA-256 against their original Steam counterparts. No revised game launch has
yet been verified.

## Install and try

1. Use an official Nucleus Co-op installation with its bundled Goldberg and
   Proto Input files. The initial API reference was an installed
   Nucleus executable reporting file version 2.3.0.0; runtime compatibility has
   not yet been tested.
2. Close any normal PAO PAO session. Back up existing saves from
   `%USERPROFILE%\AppData\LocalLow\ArtDock\PaoPao Demo` before testing. Save
   separation is an intended configuration, not a verified result.
3. Download this repository's current development revision and copy
   `handlers/Pao Pao Demo.js` into your Nucleus `handlers` folder.
4. Restart Nucleus. Use **Search Game** and select the Steam installation's
   `PaoPao Demo.exe`.
5. Connect both Xbox controllers. Give the two Nucleus players different names
   and keep distinct default Steam IDs. Entering real IDs does not authenticate
   real Steam accounts.
6. Assign one controller to each of two screen regions. Start the experimental
   handler, then follow [the testing checklist](docs/testing.md).

This diagnostic deliberately uses **full game copies**, approximately 18 GiB for
two instances plus overhead, on the drive containing Nucleus's `content`
folder. Copies are retained for debugging. Before each launch, the handler
explicitly overwrites each instance's x64 EOS DLL with the original from the
Steam installation, including the optional older Playtest data folder. It
refuses to write into the source installation or linked destination paths.
The complete game no longer needs a forced copy pass on every trial.
Steam's original DLLs should not be replaced. Do not manually paste emulator
DLLs into the Steam installation.

The trial launches the game executable directly, rather than EOSBootstrapper.
Whether that works with this demo must be established by the first launch test.
If a second window fails to appear, do not treat one working window as success.

The raw-input block attempts to avoid Unity detecting both controllers in both
instances. Because the game has partial controller support, it may also prevent
keyboard/mouse interaction needed by some menus. Record the exact affected
menu; this configuration may require a refinement after the first test.

## Multiplayer accounts

Nucleus's player Steam ID fields are identifiers consumed by compatible
emulators and handlers. They are not Steam login credentials. This experiment
uses Steam emulation, and does not sign two real accounts in simultaneously.

PAO PAO may require a valid Steam authentication ticket to create an EOS
identity. The original EOS library is now retained after the bundled emulator
crashed. Different Nucleus Steam IDs do not authenticate two real accounts.
For this diagnostic, test whether the game reaches the menu first. If EOS
login or multiplayer fails after that, retain the logs: that is a separate
authentication/transport problem, not proof that startup still crashes.

## OneDrive

The handler does not set `DocumentsConfigPath` or `DocumentsSavePath`. Nucleus
may still show its general OneDrive warning if Windows Documents is redirected
to OneDrive. Do not move Documents or disable OneDrive just to troubleshoot this
initial trial. Whether LocalLow save isolation works still needs verification.

## Restoration regression check

On Windows with PowerShell 7 and an installed copy of Nucleus, run:

```powershell
pwsh -File .\tests\check-restoration.ps1 -NucleusDirectory 'C:\NucleusCo-op'
```

Use your actual Nucleus directory. The check executes the real launch callback
with temporary marker files, not game binaries. It does not start Nucleus or
PAO PAO or alter installed libraries. The small fixtures are retained in the
Windows temporary directory for inspection.

## References

- [Handler development guide](https://www.splitscreen.me/docs/create-handlers)
- [Handler API](https://www.splitscreen.me/docs/handler-api/)
- [Proto Input](https://www.splitscreen.me/docs/proto)
- [Nucleus usage](https://www.splitscreen.me/docs/usage/)
- [PAO PAO on Steam](https://store.steampowered.com/app/3024130/PAO_PAO/)

This is an unofficial community experiment. It is not an official release
from ArtDock, Dreland Enterprises, or SplitScreen.Me.

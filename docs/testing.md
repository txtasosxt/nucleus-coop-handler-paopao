# First trial checklist

The first revision loaded in Nucleus but the game processes crashed inside the
bundled Epic emulator DLL before opening a window. A forced copy pass failed to
replace that cached DLL. The current revision disables Epic emulation and
explicitly restores the original EOS DLLs. Its launch result remains pending.
A successful launch would not establish multiplayer compatibility.

## Preparation

- Back up the existing LocalLow save folder and close normal game instances.
- Keep enough disk space for two full copies of the demo.
- Enable Nucleus's debug log in its settings.
- Use two connected Xbox controllers with distinct Nucleus player names/IDs.
- Do not change OneDrive or firewall settings before identifying an actual
  problem in the trial.

## Check each stage separately

1. **Handler load:** the experimental demo appears after using Search Game.
   Record the installed Nucleus version and any handler parsing error.
2. **Launch (current focus):** let the handler restore the EOS DLLs. Confirm the
   copied EOS DLL matches Steam's original DLL, then check whether two
   `PaoPao Demo.exe` processes reach the menu in their assigned regions. If one
   exits, capture its player log and Windows Application Error event. Record
   an EOS login error separately from a process crash.
3. **Controls:** move controller 1, then controller 2. Each must control only
   its own window, including when that window is in the background. Record any
   menu that still needs keyboard/mouse input.
4. **Identity and connection:** inspect the game's available host/join options.
   Create a disposable session in player 1 and attempt to join from player 2.
   Record whether login, lobby discovery, invitation or joining fails. Do not
   assume that real Steam's friend invites are available under emulation.
5. **Gameplay:** confirm both players can move and interact independently in
   the same world. Two disconnected single-player sessions do not pass.
6. **Saves:** use disposable progress and verify that player save paths are
   separate and the backed-up normal save is unchanged. Unity PlayerPrefs may
   also share registry settings; this needs observation rather than assumption.
7. **Exit:** close through Nucleus and confirm that both game processes exit.
   Verify that Windows Documents still has its original location. If input is
   locked, press End to unlock; Ctrl+Q is Nucleus's default session exit shortcut.

## Useful evidence

- Nucleus version, demo Steam build ID, and which stage failed.
- `debug-log.txt` from the Nucleus installation, if debug logging is enabled.
- Each `pao-player-*.log` from
  `Nucleus\content\PaoPaoDemoExperimental\Instance*`.
- Observed save paths and whether each controller affected one or both windows.

If EOS login or initialization fails, this is a networking/authentication
investigation. If both players join but control both windows, investigate
controller routing. Keep these results distinct so the next change addresses
the observed failure.

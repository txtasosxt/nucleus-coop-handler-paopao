# Separate audio outputs: unfinished

Launch, controller isolation, and window placement have been tested; separate
audio outputs remain unverified. No new audio hook is implemented by this project.

First make sure each intended output is available in Windows Sound settings and
plays its test sound. Connect/turn on HDMI devices before opening Nucleus.

In the selected PAO PAO **profile settings**, choose **Audio -> Custom settings**,
select outputs for each instance and save that profile. Profile values can differ
from global Nucleus defaults.

With shipped `PaoPaoSwapScreenAssignments = true`:

| Audio instance | Game/account |
| --- | --- |
| Instance 1 | Boxed account / first region |
| Instance 2 | Normal Steam / second region |

With the flag false, reverse this account-to-audio-instance mapping. Region order
is distinct from calling the normal Steam account player 1.

Relaunch through Nucleus and test distinct menu sounds in each game. Confirm that
only its intended device plays that sound. A routing log records an attempted
assignment, not audible success. Routing the boxed game's audio from unelevated
Nucleus remains a runtime test.

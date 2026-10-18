// Experimental PAO PAO Steam demo handler. Multiplayer is not verified.
// Start with two players; see README.md and docs/testing.md before running.

Game.ExecutableName = "PaoPao Demo.exe";
Game.ExecutableContext = ["PaoPao Demo_Data", "GameAssembly.dll", "UnityPlayer.dll"];
Game.GUID = "PaoPaoDemoExperimental";
Game.GameName = "PAO PAO Demo (Experimental)";
Game.SteamID = "3498580";
Game.MaxPlayers = 2;
Game.MaxPlayersOneMonitor = 2;
Game.BinariesFolder = "";
Game.WorkingFolder = "";
Game.Description = "EXPERIMENTAL: multiplayer, save isolation and controller separation are untested. Assign two Xbox controllers to two screen sections. This trial uses Steam and Epic emulation; real Steam IDs do not sign in to accounts. See the repository testing guide before playing or creating saves.";

// Full copies keep emulator DLL replacements away from the Steam installation.
// Two instances need approximately 18 GiB plus overhead on the Nucleus drive.
Game.HardcopyGame = true;
Game.SymlinkGame = false;
Game.SymlinkFolders = false;
Game.SymlinkExe = false;
Game.KeepSymLinkOnExit = true;

// Attempt separate Steam and EOS identities through Nucleus's bundled tools.
// This cannot be assumed to satisfy PAO PAO's Steam-ticket authentication.
Game.UseGoldberg = true;
Game.GoldbergWriteSteamIDAndAccount = true;
Game.UseNemirtingasEpicEmu = true;

// Request fresh LocalLow profiles; actual Unity save routing needs testing.
Game.UseNucleusEnvironment = true;
Game.UserProfileSavePath = "AppData\\LocalLow\\ArtDock\\PaoPao Demo";
Game.UserProfileSavePathNoCopy = true;

Game.HandlerInterval = 100;
Game.PauseBetweenStarts = 20;
Game.SupportsPositioning = true;
Game.HasDynamicWindowTitle = true;
Game.Hook.ForceFocusWindowName = "PaoPao Demo";
Game.Hook.ForceFocus = false;
Game.SupportsKeyboard = false;
Game.SupportsMultipleKeyboardsAndMice = false;

// Proto Input owns controller routing; disable the legacy input hooks.
Game.Hook.CustomDllEnabled = false;
Game.Hook.XInputEnabled = false;
Game.Hook.XInputReroute = false;
Game.Hook.DInputEnabled = false;
Game.Hook.DInputForceDisable = false;
Game.HookSetCursorPos = false;
Game.HookGetCursorPos = false;
Game.HookGetKeyState = false;
Game.HookGetAsyncKeyState = false;
Game.HookGetKeyboardState = false;
Game.HookFilterRawInput = false;
Game.HookFilterMouseMessages = false;
Game.HookUseLegacyInput = false;
Game.HookDontUpdateLegacyInMouseMsg = false;
Game.HookMouseVisibility = false;
Game.SendNormalMouseInput = false;
Game.SendNormalKeyboardInput = false;
Game.SendScrollWheel = false;
Game.ForwardRawKeyboardInput = false;
Game.ForwardRawMouseInput = false;
Game.HookReRegisterRawInput = false;
Game.HookReRegisterRawInputMouse = false;
Game.HookReRegisterRawInputKeyboard = false;
Game.DrawFakeMouseCursor = false;

Game.ProtoInput.InjectStartup = true;
Game.ProtoInput.InjectRuntime_RemoteLoadMethod = false;
Game.ProtoInput.InjectRuntime_EasyHookMethod = false;
Game.ProtoInput.InjectRuntime_EasyHookStealthMethod = false;
Game.ProtoInput.XinputHook = true;
Game.ProtoInput.UseOpenXinput = false;
Game.ProtoInput.UseDinputRedirection = false;
Game.ProtoInput.FocusHooks = true;
Game.ProtoInput.FreezeExternalInputWhenInputNotLocked = false;
// Unity may enumerate the same controllers through raw HID as well as XInput.
// This trial blocks that path. Keyboard/mouse menus may need a later refinement.
Game.ProtoInput.BlockRawInputHook = true;
Game.ProtoInput.RawInputFilter = false;
Game.ProtoInput.MessageFilterHook = true;
Game.ProtoInput.BlockedMessages = [0x00FF];
Game.LockInputAtStart = false;
Game.LockInputSuspendsExplorer = false;
Game.LockInputToggleKey = 0x23;

Game.Play = function () {
    var logPath = Context.GetFolder(Nucleus.Folder.InstancedGameFolder) +
        "\\pao-player-" + (Context.PlayerID + 1) + ".log";
    Context.StartArguments = "-screen-fullscreen 0 -popupwindow" +
        " -screen-width " + Context.Width +
        " -screen-height " + Context.Height +
        ' -logFile "' + logPath + '"';
};

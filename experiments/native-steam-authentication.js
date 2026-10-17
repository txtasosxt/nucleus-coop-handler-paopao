// Experimental PAO PAO Steam demo handler. Multiplayer is not verified.
// Single-instance Steam authentication diagnostic; assign one controller only.

Game.ExecutableName = "PaoPao Demo.exe";
Game.ExecutableContext = ["PaoPao Demo_Data", "GameAssembly.dll", "UnityPlayer.dll"];
Game.GUID = "PaoPaoDemoExperimental";
Game.GameName = "PAO PAO Demo (Experimental)";
Game.SteamID = "3498580";
Game.MaxPlayers = 1;
Game.MaxPlayersOneMonitor = 1;
Game.BinariesFolder = "";
Game.WorkingFolder = "";
Game.Description = "STEAM AUTHENTICATION TEST: keep Steam open and signed in to an account with the demo. Assign ONE controller to ONE screen section. This revision restores the original Steam and Epic libraries and uses the current Steam login. Two-account multiplayer and controller isolation remain unverified.";

// Full copies keep emulator DLL replacements away from the Steam installation.
// Two instances need approximately 18 GiB plus overhead on the Nucleus drive.
Game.HardcopyGame = true;
Game.SymlinkGame = false;
Game.SymlinkFolders = false;
Game.SymlinkExe = false;
Game.KeepSymLinkOnExit = true;
// A forced full-copy pass did not overwrite cached emulator DLLs in testing.
// Restore the original Steam and EOS libraries explicitly in Game.Play instead.
Game.ForceSymlink = false;

// The emulated Steam library returned no authentication ticket in the demo.
// Test the current real Steam session through Nucleus before adding player two.
Game.UseGoldberg = false;
Game.GoldbergWriteSteamIDAndAccount = false;
Game.UseNemirtingasEpicEmu = false;
Game.CreateSteamAppIdByExe = true;

// Request fresh LocalLow profiles; actual Unity save routing needs testing.
// Deliberately omit DocumentsConfigPath and DocumentsSavePath.
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
    if (Number(Context.PlayerID) !== 0) {
        throw new Error("Assign only one player for this Steam authentication test.");
    }
    var IO = importNamespace("System.IO");
    var sourceRoot = String(IO.Path.GetFullPath(Context.RootInstallFolder));
    var instanceRoot = String(IO.Path.GetFullPath(
        Context.GetFolder(Nucleus.Folder.InstancedGameFolder)));
    var sourcePrefix = sourceRoot.toLowerCase().replace(/[\\\/]+$/, "") + "\\";
    if (instanceRoot.toLowerCase() === sourceRoot.toLowerCase() ||
        instanceRoot.toLowerCase().indexOf(sourcePrefix) === 0) {
        throw new Error("Library restoration requires a separate Nucleus game copy.");
    }

    var dataFolders = ["PaoPao Demo_Data", "PaoPao Playtest 2_Data"];
    var libraryNames = ["EOSSDK-Win64-Shipping.dll", "steam_api64.dll"];
    for (var i = 0; i < dataFolders.length; i++) {
        for (var libraryIndex = 0; libraryIndex < libraryNames.length; libraryIndex++) {
            var relativeDll = dataFolders[i] +
                "\\Plugins\\x86_64\\" + libraryNames[libraryIndex];
            var sourceDll = IO.Path.Combine(sourceRoot, relativeDll);
            if (!IO.File.Exists(sourceDll)) {
                if (i === 0) {
                    throw new Error("The original Steam demo library is missing: " + libraryNames[libraryIndex]);
                }
                continue; // Older Playtest data is not present in every install.
            }

            var dataPath = IO.Path.Combine(instanceRoot, dataFolders[i]);
            var pluginsPath = IO.Path.Combine(dataPath, "Plugins");
            var dllFolder = IO.Path.Combine(pluginsPath, "x86_64");
            var destinationDll = IO.Path.Combine(instanceRoot, relativeDll);
            var directories = [instanceRoot, dataPath, pluginsPath, dllFolder];
            for (var j = 0; j < directories.length; j++) {
                if (!IO.Directory.Exists(directories[j]) ||
                    (Number(IO.File.GetAttributes(directories[j])) & 0x400) !== 0) {
                    throw new Error("Library restoration requires ordinary full-copy directories.");
                }
            }
            if (IO.File.Exists(destinationDll) &&
                (Number(IO.File.GetAttributes(destinationDll)) & 0x400) !== 0) {
                throw new Error("Refusing to replace a linked game library.");
            }
            IO.File.Copy(sourceDll, destinationDll, true);
        }
    }

    var logPath = instanceRoot + "\\pao-player-" + (Context.PlayerID + 1) + ".log";
    Context.StartArguments = "-screen-fullscreen 0 -popupwindow" +
        " -screen-width " + Context.Width +
        " -screen-height " + Context.Height +
        ' -logFile "' + logPath + '"';
};

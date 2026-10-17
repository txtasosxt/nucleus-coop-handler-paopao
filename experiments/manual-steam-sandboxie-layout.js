// PAO PAO Demo: manually authenticated Steam + Sandboxie window-layout trial.
// Keep the proven standalone Proto Input Hosts responsible for controller routing.

Game.ExecutableName = "PaoPao Demo.exe";
Game.ExecutableContext = ["PaoPao Demo_Data", "GameAssembly.dll", "UnityPlayer.dll"];
Game.GUID = "PaoPaoDemoExperimental";
Game.GameName = "PAO PAO Demo (Steam + Sandboxie Layout)";
Game.SteamID = "3498580";
Game.MaxPlayers = 2;
Game.MaxPlayersOneMonitor = 2;
Game.BinariesFolder = "";
Game.WorkingFolder = "";
Game.Description = "MANUAL STEAM + SANDBOXIE LAYOUT TEST. Close both games and their Proto Input Hosts before pressing Play; keep both Steam clients signed in. At the first launch prompt, start the normal Steam game and prepare its outside Proto Input Host with OpenXinput and Remote Load Library. At the second prompt, start the SteamPlayer2 game and prepare its Host inside that box with OpenXinput and EasyHook Inject. Choose the corresponding game PID in each Nucleus process picker. Nucleus arranges the windows; Steam logins and input injection remain manual. Stopping Nucleus closes the games. Layout integration is not yet runtime verified.";

// Do not create copies or change the working Steam/Sandboxie environments.
Game.HardcopyGame = false;
Game.HardlinkGame = false;
Game.SymlinkGame = false;
Game.SymlinkFolders = false;
Game.SymlinkExe = false;
Game.ForceSymlink = false;
Game.KeepSymLinkOnExit = true;
Game.UseNucleusEnvironment = false;
Game.ForceEnvironmentUse = false;
Game.UseGoldberg = false;
Game.GoldbergWriteSteamIDAndAccount = false;
Game.NeedsSteamEmulation = false;
Game.UseNemirtingasEpicEmu = false;
Game.CreateSteamAppIdByExe = false;

// Start Nucleus BEFORE the games: normal session-start cleanup closes matching
// game processes even when ThirdPartyLaunch is enabled.
Game.ThirdPartyLaunch = true;
Game.IgnoreThirdPartyPrompt = false;
Game.ForceProcessPick = true;
Game.ProcessChangesAtEnd = false;
Game.PromptBetweenInstances = false;
Game.PauseBetweenStarts = 0;
Game.PauseBetweenProcessGrab = 0;
Game.RequiresAdmin = true;
Game.HandlerInterval = 100;
Game.SupportsPositioning = true;
Game.HasDynamicWindowTitle = true;
Game.Hook.ForceFocusWindowName = "PaoPao Demo";
Game.Hook.ForceFocus = false;
Game.SupportsKeyboard = false;
Game.SupportsMultipleKeyboardsAndMice = false;
Game.KeepAspectRatio = false;
Game.KeepMonitorAspectRatio = false;
Game.NotTopMost = true;
Game.DontResize = false;
Game.DontReposition = false;
Game.DontRemoveBorders = false;

// Do not inject a second time into games already configured by standalone Hosts.
Game.ProtoInput.InjectStartup = false;
Game.ProtoInput.InjectRuntime_RemoteLoadMethod = false;
Game.ProtoInput.InjectRuntime_EasyHookMethod = false;
Game.ProtoInput.InjectRuntime_EasyHookStealthMethod = false;
Game.ProtoInput.UseOpenXinput = true;
Game.ProtoInput.UseDinputRedirection = false;
// Nucleus also uses this flag to show XInput gamepads in its setup screen.
// It cannot inject the hook here because every injection method above is off.
Game.ProtoInput.XinputHook = true;
Game.ProtoInput.FocusHooks = false;
Game.ProtoInput.RegisterRawInputHook = false;
Game.ProtoInput.GetRawInputDataHook = false;
Game.ProtoInput.ClipCursorHook = false;
Game.ProtoInput.BlockRawInputHook = false;
Game.ProtoInput.MessageFilterHook = false;
Game.ProtoInput.RawInputFilter = false;
Game.ProtoInput.EnableFocusMessageLoop = false;
Game.ProtoInput.FreezeExternalInputWhenInputNotLocked = false;
Game.ProtoInput.BlockedMessages = [];
Game.LockInputAtStart = false;
Game.LockInputSuspendsExplorer = false;

// Disable legacy hooks, input simulation and file-based controller wrappers.
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
Game.HookFocus = false;
Game.FakeFocus = false;
Game.PreventWindowDeactivation = false;
Game.SetWindowHook = false;
Game.SetWindowHookStart = false;
Game.HookInit = false;
Game.BlockRawInput = false;
Game.UseX360ce = false;
Game.UseDevReorder = false;
Game.UseDInputBlocker = false;

Game.Play = function () {
    var player = Number(Context.PlayerID);
    if (player !== 0 && player !== 1) {
        throw new Error("This layout trial supports exactly two player slots.");
    }
    Context.Log(player === 0
        ? "PAO PAO layout slot 1: launch normal Steam game, prepare its outside Proto Input Host, then select that game PID."
        : "PAO PAO layout slot 2: launch SteamPlayer2 game, prepare its in-box Proto Input Host, then select that game PID.");
};

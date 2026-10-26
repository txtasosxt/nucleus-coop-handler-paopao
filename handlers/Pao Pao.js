// PAO PAO full game: automated real-Steam launch and per-context Proto Input workers.
// The x64 helper replaces manual game launch and standalone Proto Input Hosts.
var PaoPaoControllerIndices = [2, 1]; // Example normal/boxed OpenXinput indices; calibrate on your PC.
var PaoPaoSwapScreenAssignments = true; // Swap the accounts between the current two Nucleus regions.
var PaoPaoSandboxStart = "C:\\Program Files\\Sandboxie-Plus\\Start.exe";
var PaoPaoSandboxName = "SteamPlayer2";

Game.ExecutableName = "PaoPao.exe";
Game.ExecutableContext = ["PaoPao_Data", "GameAssembly.dll", "UnityPlayer.dll"];
Game.GUID = "PaoPaoFullSteamSandbox";
Game.GameName = "PAO PAO";
Game.SteamID = "3024130";
Game.MaxPlayers = 2;
Game.MaxPlayersOneMonitor = 2;
Game.BinariesFolder = "";
Game.WorkingFolder = "";
Game.Description = "1. Install the supported XInput settings patch in the game and any private Sandboxie copy.\n2. Start Steam normally and inside SteamPlayer2, signed into two accounts that own PAO PAO.\n3. Disable Steam Input for PAO PAO in both clients.\n4. Keep both games closed. Assign two controllers and screen regions, then press Play.\n5. Create or join the same lobby from the game menus.";

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
Game.IgnoreThirdPartyPrompt = true;
Game.ForceProcessPick = false;
Game.ProcessChangesAtEnd = false;
Game.PromptBetweenInstances = false;
Game.PauseBetweenStarts = 0;
Game.PauseBetweenProcessGrab = 0;
Game.RequiresAdmin = false; // Nucleus may run normally; the boxed helper requests elevation.
Game.HandlerInterval = 100;
Game.SupportsPositioning = true;
Game.HasDynamicWindowTitle = true;
Game.Hook.ForceFocusWindowName = "PaoPao";
Game.Hook.ForceFocus = false;
Game.SupportsKeyboard = false;
Game.SupportsMultipleKeyboardsAndMice = false;
Game.KeepAspectRatio = false;
Game.KeepMonitorAspectRatio = false;
Game.NotTopMost = true;
Game.DontResize = false;
Game.DontReposition = false;
Game.DontRemoveBorders = false;

// Separate context-aware helper workers own injection; Nucleus must not reinject.
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

function PaoPaoGetNucleusRoot() {
    var System = importNamespace("System");
    return String(System.AppDomain.CurrentDomain.BaseDirectory);
}

function PaoPaoSystemAssembly() {
    // Nucleus's Jint AllowClr list does not expose System.dll constructors through
    // importNamespace. Resolve the framework assembly explicitly instead.
    var System = importNamespace("System");
    return System.Reflection.Assembly.Load("System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089");
}

function PaoPaoBuildLaunchInfo(slot, controller, width, height) {
    var IO = importNamespace("System.IO");
    var System = importNamespace("System");
    var nucleusRoot = PaoPaoGetNucleusRoot();
    var helper = String(IO.Path.Combine(String(Game.Folder), "PaoPaoFullNucleusLauncher.exe"));
    if (!IO.File.Exists(helper)) {
        throw new Error("Install PaoPaoFullNucleusLauncher.exe in this handler's Pao Pao asset folder first.");
    }
    function quoted(value) {
        if (/[\"\r\n]/.test(value)) {
            throw new Error("Unsupported character in launcher path or sandbox name.");
        }
        return '"' + value + '"';
    }
    var framework = PaoPaoSystemAssembly();
    var info = System.Activator.CreateInstance(framework.GetType("System.Diagnostics.ProcessStartInfo"));
    var args = "launch " + slot + " " + controller + " " + width + " " + height;
    if (slot === 2 && !/^[A-Za-z0-9_]+$/.test(PaoPaoSandboxName)) {
        throw new Error("Use an unquoted Sandboxie box name containing letters, numbers or underscores.");
    }
    info.FileName = slot === 1 ? helper : PaoPaoSandboxStart;
    // Sandboxie's /box: parser accepts a bare name, not a quoted value.
    // Only the executable path needs quoting for its spaces.
    info.Arguments = slot === 1 ? args
        : "/box:" + PaoPaoSandboxName + " /elevate /wait " + quoted(helper) + " " + args;
    if (slot === 2 && !IO.File.Exists(PaoPaoSandboxStart)) {
        throw new Error("Sandboxie Start.exe is missing at the configured path.");
    }
    info.WorkingDirectory = nucleusRoot;
    info.UseShellExecute = false;
    info.CreateNoWindow = true;
    info.WindowStyle = System.Enum.Parse(framework.GetType("System.Diagnostics.ProcessWindowStyle"), "Hidden");
    return info;
}

function PaoPaoStartProcess(info) {
    var framework = PaoPaoSystemAssembly();
    var Process = framework.GetType("System.Diagnostics.Process");
    return Process.Start(info);
}

function PaoPaoLaunchPlayer(slot, controller, width, height) {
    var launcher = PaoPaoStartProcess(PaoPaoBuildLaunchInfo(slot, controller, width, height));
    if (!launcher.WaitForExit(120000)) {
        launcher.Kill(); // Only the launcher/wait wrapper started by this callback.
        throw new Error("PAO PAO player " + slot + " launcher timed out. Check its automation log.");
    }
    var exitCode = Number(launcher.ExitCode);
    launcher.Dispose();
    if (exitCode !== 0) {
        throw new Error("PAO PAO player " + slot + " launch/injection failed, exit code=" + exitCode + ". Check paopao-full-player-" + slot + ".log (inside SteamPlayer2 for player 2).");
    }
    return true;
}

Game.Play = function () {
    var player = Number(Context.PlayerID);
    if (player !== 0 && player !== 1) {
        throw new Error("This handler supports exactly two player slots.");
    }
    if (PaoPaoControllerIndices[0] === PaoPaoControllerIndices[1]) {
        throw new Error("Choose two different OpenXinput controller indices.");
    }
    // Nucleus's screen-slot order is separate from the Steam account/player role.
    // Keep each role's controller even when its assigned screen is swapped.
    var slot = PaoPaoSwapScreenAssignments ? 2 - player : player + 1;
    var controller = Number(PaoPaoControllerIndices[slot - 1]);
    if (controller < 1 || controller > 32 || controller % 1 !== 0) {
        throw new Error("OpenXinput controller index must be an integer from 1 to 32.");
    }
    Context.Log("PAO PAO auto launch: slot=" + slot + ", screen-slot=" + (player + 1) + ", controller=" + controller);
    PaoPaoLaunchPlayer(slot, controller, Number(Context.Width), Number(Context.Height));
    Context.Log("PAO PAO input ready: slot=" + slot + ". Nucleus can now select and position its game window.");
};

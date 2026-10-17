// Build with the Windows .NET Framework 64-bit C# compiler. No NuGet packages.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Threading;

internal static class PaoPaoNucleusLauncher
{
    private const string GameProcess = "PaoPao Demo";
    private static readonly string Root = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
    private static readonly string DefaultSteam = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Steam", "steam.exe");
    private static string Steam = DefaultSteam;
    private static int slot;

    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            if (args.Length == 1 && args[0] == "--self-test") return SelfTest();
            if (args.Length != 5 || (args[0] != "launch" && args[0] != "host"))
                throw new ArgumentException("Expected launch <slot> <controller> <width> <height>, or host <slot> <controller> <pid> <ready-event>.");
            slot = Number(args[1], 1, 2);
            int controller = Number(args[2], 1, 32);
            CheckDependencies(slot);
            if (args[0] == "launch")
            {
                int gamePid = Launch(controller, Number(args[3], 320, 16384), Number(args[4], 240, 16384));
                Log("Launcher completed successfully, game pid=" + gamePid + ", exit code=0");
                return SuccessExitCode(gamePid);
            }
            Host(controller, Number(args[3], 1, Int32.MaxValue), args[4]);
            return 0;
        }
        catch (Exception error)
        {
            Log("ERROR: " + error.GetType().Name + ": " + error.Message);
            return -1;
        }
    }

    private static int SuccessExitCode(int gamePid)
    {
        if (gamePid <= 0) throw new ArgumentOutOfRangeException("gamePid");
        // Sandboxie's elevated launcher displays an error for every nonzero
        // child exit status. Keep process IDs in logs, not in the exit status.
        return 0;
    }

    private static int Number(string text, int min, int max)
    {
        int value;
        if (!Int32.TryParse(text, NumberStyles.None, CultureInfo.InvariantCulture, out value) || value < min || value > max)
            throw new ArgumentException("Numeric argument is out of range.");
        return value;
    }

    private static string Quote(string text)
    {
        if (text.IndexOfAny(new char[] { '"', '\r', '\n' }) >= 0 || text.EndsWith("\\", StringComparison.Ordinal))
            throw new ArgumentException("Unsupported command-line path.");
        return "\"" + text + "\"";
    }

    private static void Log(string message)
    {
        // Only launcher state, PID, controller and error messages; no game/auth logs.
        try
        {
            File.AppendAllText(Path.Combine(Root, "paopao-automation-player-" + slot + ".log"),
                DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture) + " " + message + Environment.NewLine);
        }
        catch { }
    }

    private static void CheckDependencies(int playerSlot)
    {
        // Optional local paths are not distributed or committed with the project.
        Steam = LocalPath("SteamExe", DefaultSteam);
        string[] files = playerSlot == 2
            ? new string[] { "ProtoInputLoader64.dll", "ProtoInputHooks64.dll", "ProtoInputIJ64.exe", "ProtoInputIJP64.dll" }
            : new string[] { "ProtoInputLoader64.dll", "ProtoInputHooks64.dll" };
        foreach (string file in files)
            if (!File.Exists(Path.Combine(Root, file))) throw new FileNotFoundException("Missing Nucleus dependency: " + file);
        if (!File.Exists(Steam)) throw new FileNotFoundException("Steam executable was not found at the configured path.");
        string gameDirectory = LocalPath("GameDirectory", Path.Combine(Path.GetDirectoryName(Steam), "steamapps", "common", "Pao Pao Demo"));
        string settings = Path.Combine(gameDirectory, "PaoPao Demo_Data", "globalgamemanagers");
        if (!File.Exists(settings)) throw new FileNotFoundException("The tested Steam demo's game-settings file was not found.");
        using (SHA256 sha = SHA256.Create())
        using (FileStream input = File.OpenRead(settings))
        {
            string digest = BitConverter.ToString(sha.ComputeHash(input)).Replace("-", "");
            if (digest != "AA75B042730B45999DED75C3662FE7E9861E55B52B32E2C27ED964A687AD4847")
                throw new InvalidOperationException("The demo settings differ from the tested XInput build. Recheck the Unity backend patch before automatic injection.");
        }
    }

    private static string LocalPath(string key, string fallback)
    {
        string config = Path.Combine(Root, "PaoPaoNucleusLauncher.local.ini");
        if (!File.Exists(config)) return fallback;
        return ReadLocalPath(File.ReadAllLines(config), key, fallback);
    }

    private static string ReadLocalPath(string[] lines, string key, string fallback)
    {
        foreach (string raw in lines)
        {
            string line = raw.Trim();
            if (line.Length == 0 || line.StartsWith("#") || line.StartsWith(";")) continue;
            int separator = line.IndexOf('=');
            if (separator < 0 || !String.Equals(line.Substring(0, separator).Trim(), key, StringComparison.OrdinalIgnoreCase)) continue;
            string value = line.Substring(separator + 1).Trim();
            if (!Path.IsPathRooted(value) || value.IndexOfAny(new char[] { '"', '\r', '\n' }) >= 0)
                throw new ArgumentException("Local path configuration must use an absolute, unquoted path: " + key);
            return value;
        }
        return fallback;
    }

    private static Process StartHidden(string exe, string arguments)
    {
        return Process.Start(new ProcessStartInfo(exe, arguments) {
            UseShellExecute = false, CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden, WorkingDirectory = Root
        });
    }

    private static int Launch(int controller, int width, int height)
    {
        HashSet<int> existing = new HashSet<int>(Process.GetProcessesByName(GameProcess).Select(p => p.Id));
        Log("Launch requested, slot=" + slot + ", controller=" + controller + ", method=" + (slot == 1 ? "Remote Load Library" : "EasyHook"));
        // Running inside SteamPlayer2 routes this request to the boxed Steam client.
        using (Process starter = StartHidden(Steam, "-applaunch 3498580 -screen-fullscreen 0 -popupwindow -screen-width " + width + " -screen-height " + height)) { }
        Process game = null;
        DateTime deadline = DateTime.UtcNow.AddSeconds(60);
        while (DateTime.UtcNow < deadline)
        {
            Process[] candidates = Process.GetProcessesByName(GameProcess).Where(p => !existing.Contains(p.Id)).ToArray();
            if (candidates.Length > 1) throw new InvalidOperationException("Multiple new PAO PAO processes appeared; refusing ambiguous injection.");
            if (candidates.Length == 1)
            {
                Process candidate = candidates[0];
                candidate.Refresh();
                if (!candidate.HasExited && candidate.MainWindowHandle != IntPtr.Zero)
                {
                    game = candidate;
                    break;
                }
            }
            Thread.Sleep(250);
        }
        if (game == null) throw new TimeoutException("No new game window appeared within 60 seconds. Check this Steam client's login and demo availability.");
        Log("Game window found, pid=" + game.Id);
        // Give the Unity window a short settling interval before runtime injection.
        Thread.Sleep(5000);
        string eventName = "Local\\PaoPaoReady-" + Guid.NewGuid().ToString("N");
        using (EventWaitHandle ready = new EventWaitHandle(false, EventResetMode.ManualReset, eventName))
        using (Process host = StartHidden(Assembly.GetExecutingAssembly().Location,
            "host " + slot + " " + controller + " " + game.Id + " " + Quote(eventName)))
        {
            deadline = DateTime.UtcNow.AddSeconds(40);
            while (DateTime.UtcNow < deadline)
            {
                if (ready.WaitOne(200))
                {
                    if (game.HasExited) throw new InvalidOperationException("The game exited during injection.");
                    Log("Injection configured; game pid=" + game.Id);
                    // The host keeps its pipe server alive until the game closes.
                    return game.Id;
                }
                if (host.HasExited) throw new InvalidOperationException("The input host exited before reporting ready. Check this slot's automation log.");
                if (game.HasExited)
                {
                    if (!host.HasExited) host.Kill(); // Only this helper's own child.
                    throw new InvalidOperationException("The game exited before input injection reported ready.");
                }
            }
            if (!host.HasExited) host.Kill(); // Only this helper's own child.
            throw new TimeoutException("Input injection did not complete within 40 seconds.");
        }
    }

    private static void Host(int controller, int pid, string eventName)
    {
        if (!eventName.StartsWith("Local\\PaoPaoReady-", StringComparison.Ordinal)) throw new ArgumentException("Invalid ready event.");
        Process game = Process.GetProcessById(pid);
        if (!String.Equals(game.ProcessName, GameProcess, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Refusing to inject into a process other than PAO PAO Demo.");
        if (game.Modules.Cast<ProcessModule>().Any(m => String.Equals(m.ModuleName, "ProtoInputHooks64.dll", StringComparison.OrdinalIgnoreCase)))
            throw new InvalidOperationException("The game is already injected; start a fresh game process.");
        if (!Native.SetDllDirectory(Root)) throw new InvalidOperationException("Cannot set the Nucleus DLL search directory.");
        Directory.SetCurrentDirectory(Root);
        string dllRoot = Root + "\\";
        uint handle = slot == 1
            ? Native.RemoteLoadLibraryInjectRuntime((uint)pid, dllRoot)
            : Native.EasyHookInjectRuntime((uint)pid, dllRoot);
        if (handle == 0) throw new InvalidOperationException("Proto Input returned an invalid instance handle.");
        foreach (Step step in BuildPlan(slot, controller)) Execute(handle, step);
        Thread.Sleep(500);
        if (game.HasExited) throw new InvalidOperationException("The game exited while applying the input settings.");
        using (EventWaitHandle ready = EventWaitHandle.OpenExisting(eventName)) ready.Set();
        Log("Input ready, pid=" + pid + ", instance=" + slot + ", controller=" + controller + ", OpenXinput=true");
        game.WaitForExit();
        Log("Game exited; input host exiting.");
    }

    internal sealed class Step
    {
        internal string Name;
        internal int[] Values;
        internal Step(string name, params int[] values) { Name = name; Values = values; }
    }

    internal static List<Step> BuildPlan(int instance, int controller)
    {
        if (instance < 1 || instance > 2 || controller < 1 || controller > 32) throw new ArgumentOutOfRangeException();
        return new List<Step> {
            new Step("state", instance),
            new Step("show-cursor", 0),
            new Step("clip-options", 1),
            new Step("hook", 0), // RegisterRawInputHookID, checked against installed SDK.
            new Step("hook", 1), // GetRawInputDataHookID.
            new Step("hook", 9), // ClipCursorHookID.
            new Step("hook", 10), // FocusHooksHookID.
            new Step("openxinput", 1),
            new Step("dinput", 0),
            new Step("controllers", controller, 0, 0, 0),
            new Step("hook", 12), // XinputHookID.
            new Step("messages", 0, 0, 0, 0, 0),
            new Step("focus-loop", 5, 1, 0, 0, 1, 1),
            new Step("draw-cursor", 0),
            new Step("cursor-fix", 0),
            new Step("freeze", 0)
        };
    }

    private static void Execute(uint handle, Step step)
    {
        int[] v = step.Values;
        switch (step.Name)
        {
            case "state": Native.SetupState(handle, v[0]); break;
            case "hook": Native.InstallHook(handle, v[0]); break;
            case "show-cursor": Native.SetShowCursorWhenImageUpdated(handle, v[0] != 0); break;
            case "clip-options": Native.SetCursorClipOptions(handle, v[0] != 0); break;
            case "openxinput": Native.SetUseOpenXinput(handle, v[0] != 0); break;
            case "dinput": Native.SetUseDinputRedirection(handle, v[0] != 0); break;
            case "controllers": Native.SetControllerIndex(handle, (uint)v[0], (uint)v[1], (uint)v[2], (uint)v[3]); break;
            case "messages": Native.SetupMessagesToSend(handle, v[0] != 0, v[1] != 0, v[2] != 0, v[3] != 0, v[4] != 0); break;
            case "focus-loop": Native.StartFocusMessageLoop(handle, v[0], v[1] != 0, v[2] != 0, v[3] != 0, v[4] != 0, v[5] != 0); break;
            case "draw-cursor": Native.SetDrawFakeCursor(handle, v[0] != 0); break;
            case "cursor-fix": Native.SetDrawFakeCursorFix(handle, v[0] != 0); break;
            case "freeze": Native.SetExternalFreezeFakeInput(handle, v[0] != 0); break;
            default: throw new InvalidOperationException("Unknown input configuration step.");
        }
    }

    private static int SelfTest()
    {
        // No Steam launch, DLL loading, native call, or injection in self-test mode.
        string configured = Path.Combine(Path.GetPathRoot(Root), "Example Library", "Pao Pao Demo");
        if (ReadLocalPath(new string[] { "# comment", "GameDirectory=" + configured }, "GameDirectory", "fallback") != configured)
            throw new Exception("Local library path configuration mismatch.");
        if (ReadLocalPath(new string[0], "SteamExe", DefaultSteam) != DefaultSteam)
            throw new Exception("Default Steam path configuration mismatch.");
        bool relativeRejected = false;
        try { ReadLocalPath(new string[] { "GameDirectory=relative" }, "GameDirectory", "fallback"); }
        catch (ArgumentException) { relativeRejected = true; }
        if (!relativeRejected) throw new Exception("Relative local path was accepted.");
        foreach (int pid in new int[] { 1, 12345, Int32.MaxValue })
            if (SuccessExitCode(pid) != 0) throw new Exception("Success must return exit code zero, never the game PID.");
        foreach (int instance in new int[] { 1, 2 })
        {
            List<Step> plan = BuildPlan(instance, 3 - instance);
            int[] hooks = plan.Where(s => s.Name == "hook").Select(s => s.Values[0]).ToArray();
            if (!hooks.SequenceEqual(new int[] { 0, 1, 9, 10, 12 })) throw new Exception("Hook plan mismatch.");
            if (plan.Single(s => s.Name == "state").Values[0] != instance) throw new Exception("Instance numbering mismatch.");
            if (!plan.Single(s => s.Name == "controllers").Values.SequenceEqual(new int[] { 3 - instance, 0, 0, 0 })) throw new Exception("Controller plan mismatch.");
            if (plan.Single(s => s.Name == "openxinput").Values[0] != 1 || plan.Single(s => s.Name == "dinput").Values[0] != 0) throw new Exception("Backend plan mismatch.");
            if (!plan.Single(s => s.Name == "focus-loop").Values.SequenceEqual(new int[] { 5, 1, 0, 0, 1, 1 })) throw new Exception("Focus-loop mismatch.");
        }
        bool rejected = false;
        try { BuildPlan(1, 0); } catch (ArgumentOutOfRangeException) { rejected = true; }
        if (!rejected) throw new Exception("Invalid controller accepted.");
        Console.WriteLine("Offline input-plan checks passed; no processes launched or native APIs called.");
        return 0;
    }

    private static class Native
    {
        private const string Dll = "ProtoInputLoader64.dll";
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] internal static extern bool SetDllDirectory(string path);
        [DllImport(Dll, CharSet = CharSet.Unicode, CallingConvention = CallingConvention.Cdecl)] internal static extern uint RemoteLoadLibraryInjectRuntime(uint pid, string root);
        [DllImport(Dll, CharSet = CharSet.Unicode, CallingConvention = CallingConvention.Cdecl)] internal static extern uint EasyHookInjectRuntime(uint pid, string root);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetupState(uint h, int index);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void InstallHook(uint h, int hook);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetShowCursorWhenImageUpdated(uint h, bool enabled);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetCursorClipOptions(uint h, bool fake);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetUseOpenXinput(uint h, bool enabled);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetUseDinputRedirection(uint h, bool enabled);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetControllerIndex(uint h, uint a, uint b, uint c, uint d);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetupMessagesToSend(uint h, bool wheel, bool buttons, bool move, bool keys, bool dblClick);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void StartFocusMessageLoop(uint h, int ms, bool activate, bool activateApp, bool ncActivate, bool setFocus, bool mouseActivate);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetDrawFakeCursor(uint h, bool enabled);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetDrawFakeCursorFix(uint h, bool enabled);
        [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)] internal static extern void SetExternalFreezeFakeInput(uint h, bool enabled);
    }
}

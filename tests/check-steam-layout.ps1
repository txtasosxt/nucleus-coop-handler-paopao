#requires -Version 7.0
param(
    [Parameter(Mandatory=$true)]
    [string]$NucleusDirectory,
    [string]$HandlerPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\experiments\manual-steam-sandboxie-layout.js'))
)
$ErrorActionPreference = 'Stop'
$paoAssembly = [Reflection.Assembly]::LoadFrom((Join-Path $NucleusDirectory 'Nucleus.Gaming.dll'))
$null = [Reflection.Assembly]::LoadFrom((Join-Path $NucleusDirectory 'Jint.dll'))
$paoInfoType = $paoAssembly.GetType('Nucleus.Gaming.GenericGameInfo')
$paoGame = [Runtime.CompilerServices.RuntimeHelpers]::GetUninitializedObject($paoInfoType)
$paoGame.Hook = [Activator]::CreateInstance($paoInfoType.GetField('Hook').FieldType)
$paoGame.ProtoInput = [Activator]::CreateInstance($paoInfoType.GetField('ProtoInput').FieldType)
$paoConfigure = [Action[Jint.Options]] {
    param($paoOptions)
    $null = $paoOptions.AllowClr([Reflection.Assembly[]]@($paoAssembly))
}
$paoEngine = [Jint.Engine]::new($paoConfigure)
$null = $paoEngine.SetValue('Game', [object]$paoGame)
$null = $paoEngine.Execute([IO.File]::ReadAllText($HandlerPath))
# Supply only logging and a slot number; no actual game or process is launched.
$null = $paoEngine.Execute('var Context = {PlayerID:0,Log:function(message){}}; Game.Play(); Context.PlayerID=1; Game.Play();')
$paoRejected = $false
try { $null = $paoEngine.Execute('Context.PlayerID=2; Game.Play();') }
catch {
    if ($_.Exception.Message -notmatch 'supports exactly two player slots') { throw }
    $paoRejected = $true
}
$paoChecks = [ordered]@{
    InstalledJintTypedEvaluation = $true
    BothPlayerCallbacks = $true
    ThirdSlotRejected = $paoRejected
    ExternalLaunch = $paoGame.ThirdPartyLaunch
    ManualPidSelection = $paoGame.ForceProcessPick
    LaunchPrompts = -not $paoGame.IgnoreThirdPartyPrompt
    TwoPlayers = ($paoGame.MaxPlayers -eq 2 -and $paoGame.MaxPlayersOneMonitor -eq 2)
    OpenXinputControllerDiscovery = ($paoGame.ProtoInput.XinputHook -and $paoGame.ProtoInput.UseOpenXinput)
    PositioningEnabled = ($paoGame.SupportsPositioning -and -not $paoGame.DontResize -and -not $paoGame.DontReposition)
    NoProtoInjection = -not ($paoGame.ProtoInput.InjectStartup -or
        $paoGame.ProtoInput.InjectRuntime_RemoteLoadMethod -or
        $paoGame.ProtoInput.InjectRuntime_EasyHookMethod -or
        $paoGame.ProtoInput.InjectRuntime_EasyHookStealthMethod)
    NoCopies = -not ($paoGame.HardcopyGame -or $paoGame.HardlinkGame -or $paoGame.SymlinkGame)
    NoEmulators = -not ($paoGame.UseGoldberg -or $paoGame.UseNemirtingasEpicEmu -or $paoGame.NeedsSteamEmulation)
    OriginalEnvironment = -not ($paoGame.UseNucleusEnvironment -or $paoGame.ForceEnvironmentUse)
    NoAppIdRewrite = -not $paoGame.CreateSteamAppIdByExe
    LegacyControllerHooksOff = -not ($paoGame.Hook.CustomDllEnabled -or
        $paoGame.Hook.XInputEnabled -or $paoGame.Hook.XInputReroute -or
        $paoGame.Hook.DInputEnabled -or $paoGame.UseX360ce -or
        $paoGame.UseDevReorder -or $paoGame.UseDInputBlocker)
}
foreach ($paoCheck in $paoChecks.GetEnumerator()) {
    if (-not $paoCheck.Value) { throw "Layout configuration check failed: $($paoCheck.Key)" }
}
[pscustomobject]@{ConfigurationChecks=$paoChecks;RuntimeLayoutTested=$false} | ConvertTo-Json -Depth 4

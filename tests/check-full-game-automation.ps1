#requires -Version 7.0
param(
    [Parameter(Mandatory=$true)][string]$NucleusDirectory,
    [Parameter(Mandatory=$true)][string]$LauncherPath,
    [string]$HandlerPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\handlers\Pao Pao.js'))
)
$ErrorActionPreference = 'Stop'
$paoAssembly = [Reflection.Assembly]::LoadFrom((Join-Path $NucleusDirectory 'Nucleus.Gaming.dll'))
$null = [Reflection.Assembly]::LoadFrom((Join-Path $NucleusDirectory 'Jint.dll'))
$paoInfoType = $paoAssembly.GetType('Nucleus.Gaming.GenericGameInfo')
$paoGame = [Runtime.CompilerServices.RuntimeHelpers]::GetUninitializedObject($paoInfoType)
$paoGame.Hook = [Activator]::CreateInstance($paoInfoType.GetField('Hook').FieldType)
$paoGame.ProtoInput = [Activator]::CreateInstance($paoInfoType.GetField('ProtoInput').FieldType)
$paoConfigure = [Action[Jint.Options]] { param($paoOptions); $null = $paoOptions.AllowClr([Reflection.Assembly[]]@($paoAssembly)) }
$paoEngine = [Jint.Engine]::new($paoConfigure)
$null = $paoEngine.SetValue('Game',[object]$paoGame)
$null = $paoEngine.Execute([IO.File]::ReadAllText($HandlerPath))
# Replace the process-launching boundary before executing either callback.
$null = $paoEngine.Execute('var PaoTestCalls=[]; PaoPaoLaunchPlayer=function(slot,pad,w,h){PaoTestCalls.push([slot,pad,w,h]);return 10000+slot;}; var Context={PlayerID:0,Width:960,Height:1080,Log:function(message){}};Game.Play();Context.PlayerID=1;Game.Play();')
$null = $paoEngine.Execute('var PaoTestCallJson=JSON.stringify(PaoTestCalls);')
$paoRecordedJson = $paoEngine.GetValue('PaoTestCallJson').AsString()
if ($paoRecordedJson -ne '[[2,1,960,1080],[1,2,960,1080]]') { throw 'Swapped screen-slot/account/controller mapping changed.' }
$null = $paoEngine.Execute('PaoTestCalls=[];PaoPaoSwapScreenAssignments=false;Context.PlayerID=0;Game.Play();Context.PlayerID=1;Game.Play();var PaoOriginalOrderJson=JSON.stringify(PaoTestCalls);PaoPaoSwapScreenAssignments=true;')
$paoOriginalOrderJson = $paoEngine.GetValue('PaoOriginalOrderJson').AsString()
if ($paoOriginalOrderJson -ne '[[1,2,960,1080],[2,1,960,1080]]') { throw 'Original screen assignments cannot be restored.' }
$paoThirdSlotRejected = $false
try { $null = $paoEngine.Execute('Context.PlayerID=2;Game.Play();') }
catch { if ($_.Exception.Message -notmatch 'exactly two player slots') { throw }; $paoThirdSlotRejected = $true }
$paoDuplicateRejected = $false
try { $null = $paoEngine.Execute('Context.PlayerID=0;PaoPaoControllerIndices=[1,1];Game.Play();') }
catch { if ($_.Exception.Message -notmatch 'different OpenXinput') { throw }; $paoDuplicateRejected = $true }
$paoExpectedHooks = [ordered]@{RegisterRawInputHookID=0;GetRawInputDataHookID=1;ClipCursorHookID=9;FocusHooksHookID=10;XinputHookID=12}
$paoEnum = $paoAssembly.GetType('Nucleus.Gaming.Coop.ProtoInput.ProtoInput+ProtoHookIDs')
foreach ($paoHook in $paoExpectedHooks.GetEnumerator()) {
    if ([int][Enum]::Parse($paoEnum,$paoHook.Key) -ne $paoHook.Value) { throw 'Installed Proto Input hook IDs differ from the helper.' }
}
$paoInterop = $paoAssembly.GetType('Nucleus.Gaming.Coop.ProtoInput.ProtoInput+ProtoInput64')
$paoNativeApiNames = @('RemoteLoadLibraryInjectRuntime','EasyHookInjectRuntime','SetupState','InstallHook','SetShowCursorWhenImageUpdated','SetCursorClipOptions','SetUseOpenXinput','SetUseDinputRedirection','SetControllerIndex','SetupMessagesToSend','StartFocusMessageLoop','SetDrawFakeCursor','SetDrawFakeCursorFix','SetExternalFreezeFakeInput')
foreach ($paoApiName in $paoNativeApiNames) {
    if (-not $paoInterop.GetMethod($paoApiName,[Reflection.BindingFlags]'Public,Static')) { throw "Installed native API is missing: $paoApiName" }
}
$paoSelfTestInfo = [Diagnostics.ProcessStartInfo]::new([IO.Path]::GetFullPath($LauncherPath),'--self-test')
$paoSelfTestInfo.UseShellExecute = $false
$paoSelfTestInfo.CreateNoWindow = $true
$paoSelfTestInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
$paoSelfTestInfo.RedirectStandardOutput = $true
$paoSelfTestInfo.RedirectStandardError = $true
$paoSelfTest = [Diagnostics.Process]::Start($paoSelfTestInfo)
if (-not $paoSelfTest.WaitForExit(5000)) { $paoSelfTest.Kill(); throw 'Offline helper self-test timed out.' }
if ($paoSelfTest.ExitCode -ne 0) { throw 'Offline helper self-test failed.' }
$paoChecks = [ordered]@{
    TypedHandlerEvaluation=$true
    MockedLaunchMappings=($paoRecordedJson -eq '[[2,1,960,1080],[1,2,960,1080]]')
    OriginalScreenOrderAvailable=($paoOriginalOrderJson -eq '[[1,2,960,1080],[2,1,960,1080]]')
    ThirdSlotRejected=$paoThirdSlotRejected
    DuplicateControllerRejected=$paoDuplicateRejected
    InstalledHookIdsMatch=$true
    InstalledNativeApiPresent=$true
    OfflineHelperPlan=$true
    ExternalLaunch=$paoGame.ThirdPartyLaunch
    NoLaunchPrompts=$paoGame.IgnoreThirdPartyPrompt
    AutomaticProcessSelection=(-not $paoGame.ForceProcessPick)
    OpenXinputDeviceDiscovery=($paoGame.ProtoInput.UseOpenXinput -and $paoGame.ProtoInput.XinputHook)
    NucleusInjectionDisabled=(-not ($paoGame.ProtoInput.InjectStartup -or $paoGame.ProtoInput.InjectRuntime_RemoteLoadMethod -or $paoGame.ProtoInput.InjectRuntime_EasyHookMethod -or $paoGame.ProtoInput.InjectRuntime_EasyHookStealthMethod))
    NoGameCopies=(-not ($paoGame.HardcopyGame -or $paoGame.HardlinkGame -or $paoGame.SymlinkGame))
    NoEmulation=(-not ($paoGame.UseGoldberg -or $paoGame.UseNemirtingasEpicEmu -or $paoGame.NeedsSteamEmulation))
    UnelevatedNucleusAllowed=(-not $paoGame.RequiresAdmin)
    FullGameExecutable=($paoGame.ExecutableName -eq 'PaoPao.exe')
    FullGameSteamApp=($paoGame.SteamID -eq '3024130')
    SeparateFullGameIdentity=($paoGame.GUID -eq 'PaoPaoFullSteamSandbox')
}
foreach ($paoCheck in $paoChecks.GetEnumerator()) { if (-not $paoCheck.Value) { throw "Automation check failed: $($paoCheck.Key)" } }
[pscustomobject]@{Checks=$paoChecks;GameLaunchOrInjectionPerformed=$false;RuntimeAutomationTested=$false} | ConvertTo-Json -Depth 4

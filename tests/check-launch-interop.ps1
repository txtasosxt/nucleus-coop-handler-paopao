#requires -Version 5.1
param(
    [Parameter(Mandatory=$true)][string]$NucleusDirectory,
    [Parameter(Mandatory=$true)][string]$LauncherPath,
    [string]$SandboxieStart = '',
    [string]$HandlerPath = ''
)
$ErrorActionPreference = 'Stop'
if (-not $HandlerPath) { $HandlerPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\handlers\Pao Pao Demo.js')) }
if ([Environment]::Version.Major -ne 4) { throw 'Run this regression with Windows PowerShell 5.1 to match Nucleus .NET Framework.' }
$paoAssembly = [Reflection.Assembly]::LoadFrom((Join-Path $NucleusDirectory 'Nucleus.Gaming.dll'))
$null = [Reflection.Assembly]::LoadFrom((Join-Path $NucleusDirectory 'Jint.dll'))
$paoInfoType = $paoAssembly.GetType('Nucleus.Gaming.GenericGameInfo')
$paoGame = [Runtime.Serialization.FormatterServices]::GetUninitializedObject($paoInfoType)
$paoGame.Hook = [Activator]::CreateInstance($paoInfoType.GetField('Hook').FieldType)
$paoGame.ProtoInput = [Activator]::CreateInstance($paoInfoType.GetField('ProtoInput').FieldType)
$paoConfigure = [Action[Jint.Options]] { param($options); $null = $options.AllowClr([Reflection.Assembly[]]@($paoAssembly)) }
$paoEngine = New-Object Jint.Engine -ArgumentList $paoConfigure
$null = $paoEngine.SetValue('Game',[object]$paoGame)
$null = $paoEngine.SetValue('PaoTestRoot',[string]([IO.Path]::GetFullPath($NucleusDirectory)))
$null = $paoEngine.SetValue('PaoTestHelper',[string]([IO.Path]::GetFullPath($LauncherPath)))
# Reproduce the exact original constructor expression before checking the fix.
$paoOriginalRejected = $false
try { $null = $paoEngine.Execute('var PaoLegacyDiagnostics=importNamespace("System.Diagnostics"); var PaoLegacyInfo=new PaoLegacyDiagnostics.ProcessStartInfo();') }
catch { if ($_.Exception.Message -notmatch "object can't be used as constructor") { throw }; $paoOriginalRejected = $true }
if (-not $paoOriginalRejected) { throw 'The original constructor expression unexpectedly succeeded in this runtime.' }
$null = $paoEngine.Execute([IO.File]::ReadAllText($HandlerPath))
if ($SandboxieStart) {
    $null = $paoEngine.SetValue('PaoTestSandboxie',[string]([IO.Path]::GetFullPath($SandboxieStart)))
    $null = $paoEngine.Execute('PaoPaoSandboxStart=PaoTestSandboxie;')
}
$null = $paoEngine.Execute('PaoPaoGetNucleusRoot=function(){return PaoTestRoot;}; var PaoNormalInfo=PaoPaoBuildLaunchInfo(1,2,960,1080); var PaoBoxInfo=PaoPaoBuildLaunchInfo(2,1,960,1080);')
$paoNormal = $paoEngine.GetValue('PaoNormalInfo').ToObject()
$paoBox = $paoEngine.GetValue('PaoBoxInfo').ToObject()
if ($paoNormal.GetType().FullName -ne 'System.Diagnostics.ProcessStartInfo') { throw 'Actual ProcessStartInfo construction failed.' }
if ($paoNormal.Arguments -ne 'launch 1 2 960 1080') { throw 'Normal launch arguments changed.' }
if ($paoBox.Arguments -ne ('/box:SteamPlayer2 /elevate /wait "' + (Join-Path $NucleusDirectory 'PaoPaoNucleusLauncher.exe') + '" launch 2 1 960 1080')) { throw 'Boxed launch arguments changed.' }
# Match Sandboxie's parser: the /box: token allows letters/digits/underscore,
# stops at a space, and rejects a quote before consuming any box-name character.
if ($paoBox.Arguments -notmatch '^/box:([A-Za-z0-9_]+) /elevate /wait "([^"]+)" launch 2 1 960 1080$' -or $Matches[1] -ne 'SteamPlayer2') { throw 'Sandboxie cannot parse the generated box-name argument.' }
if ('/box:"SteamPlayer2" /elevate /wait "example.exe"' -match '^/box:[A-Za-z0-9_]+ ') { throw 'Regression check accepted the original invalid quoting.' }
$null = $paoEngine.Execute('var PaoBadBoxRejected=false; PaoPaoSandboxName="\"SteamPlayer2\"";try{PaoPaoBuildLaunchInfo(2,1,960,1080);}catch(error){PaoBadBoxRejected=String(error).indexOf("unquoted Sandboxie box name")>=0;}PaoPaoSandboxName="SteamPlayer2";')
if (-not $paoEngine.GetValue('PaoBadBoxRejected').AsBoolean()) { throw 'Quoted box configuration was not rejected.' }
foreach ($paoInfo in @($paoNormal,$paoBox)) {
    if ($paoInfo.UseShellExecute -or -not $paoInfo.CreateNoWindow -or $paoInfo.WindowStyle -ne [Diagnostics.ProcessWindowStyle]::Hidden) { throw 'Hidden process settings changed.' }
}
# Exercise the real assembly-resolved Process.Start path with only the helper's
# offline self-test. It cannot start Steam/a game or load any injection library.
$null = $paoEngine.Execute('PaoNormalInfo.FileName=PaoTestHelper; PaoNormalInfo.Arguments="--self-test"; var PaoSelfTestProcess=PaoPaoStartProcess(PaoNormalInfo); if(!PaoSelfTestProcess.WaitForExit(5000)){PaoSelfTestProcess.Kill();throw new Error("Self-test timed out");} var PaoSelfTestExit=PaoSelfTestProcess.ExitCode; PaoSelfTestProcess.Dispose();')
if ($paoEngine.GetValue('PaoSelfTestExit').AsNumber() -ne 0) { throw 'Process.Start interop self-test failed.' }
# Now execute both complete launch callbacks, replacing only Process.Start.
# Request construction, wait/exit-code handling, disposal and Game.Play all run.
$null = $paoEngine.Execute('var PaoRecorded=[]; var PaoDisposed=0; var PaoMockExitCode=0; PaoPaoStartProcess=function(info){PaoRecorded.push(String(info.Arguments));return {WaitForExit:function(ms){return ms===120000;},ExitCode:PaoMockExitCode,Dispose:function(){PaoDisposed++;}};}; var Context={PlayerID:0,Width:960,Height:1080,Log:function(message){}}; Game.Play(); Context.PlayerID=1; Game.Play(); var PaoCallsJson=JSON.stringify(PaoRecorded);')
$null = $paoEngine.Execute('var PaoCallbacksOk=PaoRecorded.length===2 && PaoRecorded[0]===String(PaoBoxInfo.Arguments) && PaoRecorded[1]==="launch 1 2 960 1080" && PaoDisposed===2;')
if (-not $paoEngine.GetValue('PaoCallbacksOk').AsBoolean()) { throw ('Full callback launch regression failed: ' + $paoEngine.GetValue('PaoCallsJson').AsString()) }
$null = $paoEngine.Execute('var PaoExitErrorsOk=true;for(var i=0;i<2;i++){PaoMockExitCode=i===0?-1:12345;var rejected=false;try{PaoPaoLaunchPlayer(2,1,960,1080);}catch(error){rejected=String(error).indexOf("exit code="+PaoMockExitCode)>=0;}PaoExitErrorsOk=PaoExitErrorsOk&&rejected;}PaoMockExitCode=0;')
if (-not $paoEngine.GetValue('PaoExitErrorsOk').AsBoolean()) { throw 'Nonzero launcher exits were not rejected.' }
[pscustomobject]@{
    Runtime=[Environment]::Version.ToString()
    JintFileVersion=[Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $NucleusDirectory 'Jint.dll')).FileVersion
    OriginalConstructorFailureReproduced=$paoOriginalRejected
    ActualProcessStartInfoConstruction=$true
    BothLaunchRequests=$true
    BareSandboxieBoxArgument=$true
    QuotedBoxConfigurationRejected=$true
    AssemblyResolvedProcessStartSelfTest=$true
    CompleteLaunchCallbacks=$true
    ZeroExitIsSuccess=$true
    NonzeroExitRejected=$true
    GameLaunchOrInjectionPerformed=$false
    RuntimeAutomationTested=$false
} | ConvertTo-Json

#requires -Version 7.0
param(
    [Parameter(Mandatory=$true)]
    [string]$NucleusDirectory,
    [string]$HandlerPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\handlers\Pao Pao Demo.js'))
)
$ErrorActionPreference = 'Stop'
$paoAssembly = [Reflection.Assembly]::LoadFrom((Join-Path $NucleusDirectory 'Nucleus.Gaming.dll'))
$null = [Reflection.Assembly]::LoadFrom((Join-Path $NucleusDirectory 'Jint.dll'))
$paoInfoType = $paoAssembly.GetType('Nucleus.Gaming.GenericGameInfo')
$paoHandlerText = [IO.File]::ReadAllText($HandlerPath)
$paoFixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('pao-restoration-check-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
$paoRelativeDlls = @(
    'PaoPao Demo_Data\Plugins\x86_64\EOSSDK-Win64-Shipping.dll',
    'PaoPao Playtest 2_Data\Plugins\x86_64\EOSSDK-Win64-Shipping.dll'
)

function New-PaoCheckEngine([string]$SourceRoot, [string]$InstanceRoot) {
    $paoInfo = [Runtime.CompilerServices.RuntimeHelpers]::GetUninitializedObject($paoInfoType)
    $paoInfo.Hook = [Activator]::CreateInstance($paoInfoType.GetField('Hook').FieldType)
    $paoInfo.ProtoInput = [Activator]::CreateInstance($paoInfoType.GetField('ProtoInput').FieldType)
    $paoConfigure = [Action[Jint.Options]] {
        param($paoOptions)
        $null = $paoOptions.AllowClr([Reflection.Assembly[]]@($paoAssembly))
    }
    $paoEngine = [Jint.Engine]::new($paoConfigure)
    $null = $paoEngine.SetValue('Game', [object]$paoInfo)
    $null = $paoEngine.Execute("var Nucleus = importNamespace('Nucleus.Gaming');")
    $null = $paoEngine.Execute($paoHandlerText)
    $paoSourceJson = ConvertTo-Json -InputObject $SourceRoot -Compress
    $paoInstanceJson = ConvertTo-Json -InputObject $InstanceRoot -Compress
    $paoContextJs = 'var Context = {RootInstallFolder:' + $paoSourceJson +
        ', Width:960, Height:1080, PlayerID:0, GetFolder:function(){return ' +
        $paoInstanceJson + ';}};'
    $null = $paoEngine.Execute($paoContextJs)
    return ,$paoEngine
}

function New-PaoFixture([string]$CaseName, [bool]$IncludePlaytest) {
    $paoSource = Join-Path (Join-Path $paoFixtureRoot $CaseName) 'source'
    $paoInstance = Join-Path (Join-Path $paoFixtureRoot $CaseName) 'Instance0'
    $paoIndices = if ($IncludePlaytest) { @(0, 1) } else { @(0) }
    foreach ($paoIndex in $paoIndices) {
        $paoSourceDll = Join-Path $paoSource $paoRelativeDlls[$paoIndex]
        $paoDestinationDll = Join-Path $paoInstance $paoRelativeDlls[$paoIndex]
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($paoSourceDll))
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($paoDestinationDll))
        # Markers only: these files are never loaded as libraries.
        [IO.File]::WriteAllBytes($paoSourceDll, [byte[]]@(10, 20, (30 + $paoIndex), 40))
        [IO.File]::WriteAllBytes($paoDestinationDll, [byte[]]@(90, 80))
    }
    return @{Source=$paoSource; Instance=$paoInstance; Indices=$paoIndices}
}

$paoResults = @()
foreach ($paoCase in @(
    @{Name='cached-demo-and-playtest'; Optional=$true},
    @{Name='demo-without-old-playtest'; Optional=$false}
)) {
    $paoFixture = New-PaoFixture $paoCase.Name $paoCase.Optional
    $paoOriginalHashes = @{}
    foreach ($paoIndex in $paoFixture.Indices) {
        $paoOriginalHashes[$paoIndex] = (Get-FileHash -LiteralPath (Join-Path $paoFixture.Source $paoRelativeDlls[$paoIndex])).Hash
    }
    $paoEngine = New-PaoCheckEngine $paoFixture.Source $paoFixture.Instance
    $null = $paoEngine.Execute('Game.Play();')
    foreach ($paoIndex in $paoFixture.Indices) {
        $paoSourceHash = (Get-FileHash -LiteralPath (Join-Path $paoFixture.Source $paoRelativeDlls[$paoIndex])).Hash
        $paoDestinationHash = (Get-FileHash -LiteralPath (Join-Path $paoFixture.Instance $paoRelativeDlls[$paoIndex])).Hash
        if ($paoSourceHash -ne $paoOriginalHashes[$paoIndex] -or $paoDestinationHash -ne $paoSourceHash) {
            throw "EOS restoration regression: $($paoCase.Name)"
        }
    }
    $paoResults += [pscustomobject]@{Case=$paoCase.Name;Result='passed'}
}

$paoUnsafe = New-PaoFixture 'reject-source-destination' $false
$paoEngine = New-PaoCheckEngine $paoUnsafe.Source $paoUnsafe.Source
$paoRejected = $false
try { $null = $paoEngine.Execute('Game.Play();') }
catch {
    if ($_.Exception.Message -notmatch 'requires a separate Nucleus game copy') { throw }
    $paoRejected = $true
}
if (!$paoRejected) { throw 'Source installation was accepted as a destination.' }
$paoResults += [pscustomobject]@{Case='reject-source-destination';Result='passed'}

$paoLinked = New-PaoFixture 'reject-linked-directory' $false
$paoLinkedInstance = Join-Path (Split-Path $paoLinked.Instance -Parent) 'linked-instance'
$null = [IO.Directory]::CreateDirectory($paoLinkedInstance)
$paoJunctionPath = Join-Path $paoLinkedInstance 'PaoPao Demo_Data'
$null = New-Item -ItemType Junction -Path $paoJunctionPath -Target (Join-Path $paoLinked.Source 'PaoPao Demo_Data')
$paoOriginalHash = (Get-FileHash -LiteralPath (Join-Path $paoLinked.Source $paoRelativeDlls[0])).Hash
$paoEngine = New-PaoCheckEngine $paoLinked.Source $paoLinkedInstance
$paoRejected = $false
try { $null = $paoEngine.Execute('Game.Play();') }
catch {
    if ($_.Exception.Message -notmatch 'requires ordinary full-copy directories') { throw }
    $paoRejected = $true
}
if (!$paoRejected) { throw 'A linked destination directory was accepted.' }
if ((Get-FileHash -LiteralPath (Join-Path $paoLinked.Source $paoRelativeDlls[0])).Hash -ne $paoOriginalHash) {
    throw 'The source library changed during the linked-directory rejection check.'
}
$paoResults += [pscustomobject]@{Case='reject-linked-directory';Result='passed'}
$paoResults | ConvertTo-Json

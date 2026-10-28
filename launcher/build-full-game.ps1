#requires -Version 5.1
param([string]$OutputDirectory = '')
$ErrorActionPreference = 'Stop'
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot '..\build\handlers' }
$paoCompiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $paoCompiler)) { throw 'The Windows .NET Framework 64-bit C# compiler is required.' }
$paoOutput = [IO.Path]::GetFullPath($OutputDirectory)
$paoAssets = Join-Path $paoOutput 'Pao Pao'
$null = [IO.Directory]::CreateDirectory($paoAssets)
$paoExecutable = Join-Path $paoAssets 'PaoPaoFullNucleusLauncher.exe'
& $paoCompiler /nologo /target:winexe /platform:x64 /optimize+ ('/out:' + $paoExecutable) (Join-Path $PSScriptRoot 'PaoPaoFullNucleusLauncher.cs')
if ($LASTEXITCODE -ne 0) { throw 'Full-game launcher compilation failed.' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\handlers\Pao Pao.js') -Destination (Join-Path $paoOutput 'Pao Pao.js')
Get-Item -LiteralPath $paoExecutable,(Join-Path $paoOutput 'Pao Pao.js') | Select-Object FullName,Length

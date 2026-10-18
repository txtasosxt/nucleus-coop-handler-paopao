#requires -Version 5.1
param([string]$OutputDirectory = '')
$ErrorActionPreference = 'Stop'
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot '..\build' }
$paoCompiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $paoCompiler)) { throw 'The Windows .NET Framework 64-bit C# compiler is required.' }
$paoOutput = [IO.Path]::GetFullPath($OutputDirectory)
$null = [IO.Directory]::CreateDirectory($paoOutput)
$paoExecutable = Join-Path $paoOutput 'PaoPaoNucleusLauncher.exe'
& $paoCompiler /nologo /target:winexe /platform:x64 /optimize+ ('/out:' + $paoExecutable) (Join-Path $PSScriptRoot 'PaoPaoNucleusLauncher.cs')
if ($LASTEXITCODE -ne 0) { throw 'C# launcher compilation failed.' }
Get-Item -LiteralPath $paoExecutable | Select-Object FullName,Length

param([Parameter(Mandatory=$true)][string]$Haxe)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path $PSScriptRoot -Parent
$testRoot=Join-Path ([System.IO.Path]::GetTempPath()) ("records-probe-"+[guid]::NewGuid().ToString())
$packageRoot=Join-Path $testRoot 'mods/ultimate_records'
New-Item -ItemType Directory -Force $packageRoot | Out-Null
foreach($name in @('RecLayout.hx','RecData.hx','RecStore.hx','RecRun.hx')){
 Copy-Item -LiteralPath (Join-Path $repoRoot "src/$name") -Destination $packageRoot
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'RecordsProbe.hx') -Destination $testRoot
# Test files stay in the isolated temporary directory; no player records are touched.
& $Haxe -cp $testRoot --run RecordsProbe (Join-Path $testRoot 'store')
if($LASTEXITCODE -ne 0){throw 'Records probe failed'}

if(!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$missing_checkver = "$env:SCOOP_HOME/bin/missing-checkver.ps1"
$dir = "$psscriptroot/../bucket" # checks the parent dir
if (!(Test-Path $dir)) { $dir = "$(Get-Location)/bucket" }
Invoke-Expression -command "& '$missing_checkver' -dir '$dir' $($args | ForEach-Object { "$_ " })"

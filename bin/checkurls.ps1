if(!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$checkurls = "$env:SCOOP_HOME/bin/checkurls.ps1"
$dir = "$psscriptroot/../bucket" # checks the parent dir
if (!(Test-Path $dir)) { $dir = "$(Get-Location)/bucket" }
Invoke-Expression -command "& '$checkurls' -dir '$dir' $($args | ForEach-Object { "$_ " })"

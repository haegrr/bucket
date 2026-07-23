param(
    # overwrite upstream param
    [String]$upstream = "ScoopInstaller/Main:master"
)

if(!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$autopr = "$env:SCOOP_HOME/bin/auto-pr.ps1"
$dir = "$psscriptroot/../bucket" # checks the parent dir
if (!(Test-Path $dir)) { $dir = "$(Get-Location)/bucket" }
Invoke-Expression -command "& '$autopr' -dir '$dir' -upstream $upstream $($args | ForEach-Object { "$_ " })"

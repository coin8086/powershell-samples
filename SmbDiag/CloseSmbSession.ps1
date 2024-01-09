<#
.SYNOPSIS
Close SMB sessions in which specified files are open.

.DESCRIPTION
#>

param(
    [Parameter(Mandatory)]
    [string[]]$FilePatterns,

    [switch]$UseRegex,

    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function logInfo {
    param([string] $msg)
    Write-Information "## $msg"
}

$files = Get-SmbOpenFile
$count = @($files).count
logInfo "Found $count SMB open file(s)"

$sessionIds = @()
$count = 0
foreach ($file in $files) {
    foreach ($pattern in $FilePatterns) {
        if (($UseRegex -and ($file.Path -match $pattern)) -or
            (!$UseRegex -and ($file.Path -like $pattern))) {
            logInfo "Found matched file '$($file.Path)'"
            $sessionIds += $file.SessionId
            $count += 1
            break
        }
    }
}

$sessionIds = $sessionIds | sort | Get-Unique
$count2 = @($sessionIds).count

logInfo "Found $count matched SMB open file(s) in $count2 SMB session(s):`n$sessionIds"

if (!$WhatIf -and ($count2 -gt 0)) {
    logInfo "Cleaning..."
    Close-SmbSession $sessionIds -Force
}

$sessions = Get-SmbSession
$count = @($sessions).count
logInfo "$count SMB session(s) remains after cleaning."

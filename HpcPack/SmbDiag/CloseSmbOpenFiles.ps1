<#
.SYNOPSIS
Close SMB open files that match a pattern.

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

$fileIds = @()
$count = 0
foreach ($file in $files) {
    foreach ($pattern in $FilePatterns) {
        if (($UseRegex -and ($file.Path -match $pattern)) -or
            (!$UseRegex -and ($file.Path -like $pattern))) {
            logInfo "Found matched file '$($file.Path)'"
            $fileIds += $file.FileId
            $count += 1
            break
        }
    }
}

logInfo "Found $count matched SMB open file(s)"

if (!$WhatIf -and ($count -gt 0)) {
    logInfo "Cleaning..."
    Close-SmbOpenFile $fileIds -Force
}


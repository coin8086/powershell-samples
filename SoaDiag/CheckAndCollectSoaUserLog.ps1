<#
.SYNOPSIS
Search in SOA user log files for a message and collect matched log files.

.DESCRIPTION
#>

param(
    # A list of SOA job ids.
    [Parameter(Mandatory=$true)]
    [string[]]$Jobs,

    # Patterns to search in log files.
    [Parameter(Mandatory=$true)]
    [string[]]$Patterns,

    # A directory where the files will be copied to.
    [Parameter(Mandatory=$true)]
    [string]$To,

    # Credential of HPC Pack admin, which is returned by Get-Credential.
    $Credential,

    # A list of computer names. When absent, all HPC Pack computer nodes that are 'Online' will be counted.
    [string[]]$Computers
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$CheckSoaUserLog = Join-Path $PSScriptRoot 'CheckSoaUserLog.ps1' -Resolve
$CollectSoaUserLog = Join-Path $PSScriptRoot 'CollectSoaUserLog.ps1' -Resolve

if (!$Credential) {
    $Credential = Get-Credential
}

if (!$Computers) {
    # NOTE: Get-HpcNode is from HPC Pack.
    $Computers = Get-HpcNode |?{ $_.noderole -eq 'ComputeNode' -and $_.nodestate -eq 'Online' } | %{ $_.NetBiosName }
}

$count = @($Computers).Count
Write-Information "# $count nodes to check"

foreach ($job in $Jobs) {
    Write-Information "# Checking for job $job..."

    &$CheckSoaUserLog -Computers $Computers -JobId $job -Patterns $Patterns |
        %{ &$CollectSoaUserLog -Computer $_.Computer -Files $_.Files -To $To -Credential $Credential }
}


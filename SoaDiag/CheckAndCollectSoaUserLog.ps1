<#
.SYNOPSIS
Search in SOA user log files for a message and collect matched log files.

.DESCRIPTION
Use it like this

$cred = Get-Credential # The account should be available on all $Computers. Typically it's an HPC PACK admin.
.\CheckAndCollectSoaUserLog.ps1 -Jobs 100..110 -Patterns 'pattern 1', 'pattern 2', 'pattern 3' -To 'a local dir' -Credential $cred
#>

[CmdletBinding(DefaultParameterSetName = 'Collect')]
param(
    # A list of SOA job ids.
    [Parameter(Mandatory)]
    [string[]]$Jobs,

    # Patterns to search in log files.
    [Parameter(Mandatory)]
    [string[]]$Patterns,

    # A directory where the files will be copied to.
    [Parameter(Mandatory, ParameterSetName = 'Collect')]
    [string]$To,

    # Credential of HPC Pack admin, which is returned by Get-Credential.
    [Parameter(ParameterSetName = 'Collect')]
    $Credential,

    # A list of computer names. When absent, all HPC Pack computer nodes that are 'Online' will be counted.
    [string[]]$Computers,

    # Only check log, do not copy any files.
    [Parameter(ParameterSetName = 'Check')]
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$CheckSoaUserLog = Join-Path $PSScriptRoot 'CheckSoaUserLog.ps1' -Resolve
$CollectSoaUserLog = Join-Path $PSScriptRoot 'CollectSoaUserLog.ps1' -Resolve

if (!$CheckOnly -and !$Credential) {
    $Credential = Get-Credential
}

if (!$Computers) {
    # NOTE: Get-HpcNode is from HPC Pack.
    $Computers = Get-HpcNode |?{ $_.noderole -eq 'ComputeNode' -and $_.nodestate -eq 'Online' } | %{ $_.NetBiosName }
}

$count = @($Computers).Count
Write-Information "# $count nodes to check"

$fcount = 0
foreach ($job in $Jobs) {
    Write-Information "# Checking for job $job..."

    &$CheckSoaUserLog -Computers $Computers -JobId $job -Patterns $Patterns |
        %{
            if (!$CheckOnly) {
                &$CollectSoaUserLog -Computer $_.Computer -Files $_.Files -To $To -Credential $Credential
            }
            else {
                Write-Output @{ Computer = $_.Computer; Files = $_.Files }
            }
            $fcount += @($_.Files).Count
        }
}

if ($fcount -gt 0) {
    Write-Information "# $fcount files are found."
}
else {
    Write-Information "# No file is found."
}


<#
.SYNOPSIS
Test SMB file read and write.

.DESCRIPTION
The $FilePath should be a SMB path. All the $Computers will read the file and write to the same SMB share backup files that have exact the same content but different postfixes. So make sure you have enough free space in the SMB share for the test. The required space is the file size timing the $Parallel. The backup files will be deleted at the end of test.

$Parallel determins how many processes on a computer to read the file and write a backup at the same time.

When $Readonly is specified, no file write will be performed.
#>

param(
    [Parameter(Mandatory)]
    [string]$FilePath,

    [int]$Parallel = 16,

    [switch]$Readonly,

    [string[]]$Computers,

    $Credential
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$testFileOps = {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [int]$Parallel,

        [bool]$Readonly = $false
    )

    function logInfo {
        param([string] $msg)
        Write-Information "## [$env:COMPUTERNAME] $msg"
    }

    logInfo "Opening $FilePath ..."

    $jobs = @()
    for ($i = 1; $i -le $Parallel; $i++) {
        $j = Start-Job -ScriptBlock {
            param(
                [Parameter(Mandatory)]
                [string]$FilePath,

                [bool]$Readonly = $false,

                [int]$Index
            )

            function logInfoIdx {
                param([string] $msg)
                Write-Information "## [$env:COMPUTERNAME][$Index] $msg"
            }

            logInfoIdx "Opening $FilePath in process $PID..."
            $bytes = [System.IO.File]::ReadAllBytes($FilePath)
            logInfoIdx "Read $($bytes.Count) bytes"

            if (!$Readonly) {
                $writePath = "$FilePath.SmbDiag.$env:COMPUTERNAME.$Index"
                logInfoIdx "Writing to $writePath..."
                [System.IO.File]::WriteAllBytes($writePath, $bytes)
                logInfoIdx "Done Writing"
            }

        } -ArgumentList @($FilePath, $Readonly, $i)
        $jobs += $j
    }

    logInfo "Waiting..."

    $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job

    if (!$Readonly) {
        logInfo "Cleaning..."
        dir "$FilePath.SmbDiag.$env:COMPUTERNAME.*" | rm
    }

    logInfo "Done"
}

$argList = @($FilePath, $Parallel, $($Readonly))

if (!$Computers) {
    &$testFileOps @argList
}
else {
    # NOTE: refer to the following link for how to read a file in a SMB share.
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/invoke-command#example-17-access-a-network-share-in-a-remote-session
    if (!$Credential) {
        $Credential = Get-Credential
    }
    Enable-WSManCredSSP -Role Client -DelegateComputer $Computers -Force | out-null
    Invoke-Command -ComputerName $Computers -ScriptBlock { Enable-WSManCredSSP -Role Server -Force | out-null }
    Invoke-Command -ComputerName $Computers -Authentication 'CredSSP' -Credential $Credential -ThrottleLimit $([int]::MaxValue) -ScriptBlock $testFileOps -ArgumentList $argList
}

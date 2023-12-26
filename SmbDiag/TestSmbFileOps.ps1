param(
    [Parameter(Mandatory)]
    [string]$FilePath,

    [int]$NumOfParallel = 10,

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
        [int]$NumOfParallel,

        [bool]$Readonly = $false
    )

    function logInfo {
        param([string] $msg)
        Write-Information "## [$env:COMPUTERNAME] $msg"
    }

    logInfo "Opening $FilePath ..."

    $jobs = @()
    for ($i = 1; $i -le $NumOfParallel; $i++) {
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

$argList = @($FilePath, $NumOfParallel, $($Readonly))

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

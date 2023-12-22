<#
.SYNOPSIS
Search for patterns in user log files for a given SOA job.

.DESCRIPTION
Use it like this

$nodes = Get-HpcNode |?{ $_.noderole -eq 'ComputeNode' -and $_.nodestate -eq 'Online' } | %{ $_.NetBiosName }
.\SearchSoaUserLog.ps1 -Computers $nodes -JobId 53 -Patterns 'your pattern 1', 'your pattern 2'

The $Patterns is passed to Select-String and the conditions of $Patterns are "OR"ed together, meaning any matched condition counts.
#>

param(
    # A SOA job id.
    [Parameter(Mandatory=$true)]
    [Alias("j")]
    [string]$JobId,

    # Patterns to search in log files.
    [Parameter(Mandatory=$true)]
    [Alias("p")]
    [string[]]$Patterns,

    # A list of computer names. When absent, search will be performed on local computer.
    [Alias("c")]
    [string[]]$Computers,

    [Alias("v")]
    [switch]$VerboseOut
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$checkLog = {
    param(
        [Parameter(Mandatory=$true)]
        [string]$JobId,

        [Parameter(Mandatory=$true)]
        [string[]]$Patterns,

        # NOTE: No way to pass in a switch parameter directly in -ArgumentList!
        # So here a boolean type is used.
        [bool]$VerboseOut=$false
    )

    function logInfo {
        param([string] $msg)
        Write-Information "## [$env:COMPUTERNAME] $msg"
    }

    function logWarn {
        param([string] $msg)
        Write-Warning "## [$env:COMPUTERNAME] $msg"
    }

    function hasLogFile {
        param(
            [Parameter(Mandatory=$true)]
            [string] $binPath
        )
        $logFile = [io.path]::ChangeExtension($binPath, "log")
        Test-Path -Path $logFile
    }

    function convertBinFile {
        param(
            [Parameter(Mandatory=$true)]
            [string] $binPath,

            [Parameter(Mandatory=$true)]
            $logParser
        )
        if (!(hasLogFile $binPath)) {
            # NOTE: Redirect stderr to stdout to avoid PS error by native command error output.
            # The native command exit code determines sucess or failure of the native call.
            &$logParser $binPath 2>&1
        }
    }

    # Check local log files for the job and message...
    #
    # 1. Locate the log file position by $env:CCP_LOGROOT_USR + SOA\HpcServiceHost\{jobid}, like
    #    C:\Users\hpcadmin\AppData\Local\Microsoft\Hpc\LogFiles\SOA\HpcServiceHost\{jobid}

    if (!$env:CCP_LOGROOT_USR) {
        logWarn "Environment variable CCP_LOGROOT_USR is not defined. Is it a node of an HPC Pack cluster?"
        return
    }

    $userLogDir = [System.Environment]::ExpandEnvironmentVariables($env:CCP_LOGROOT_USR)
    $jobLogDir = Join-Path -Path $userLogDir -ChildPath "SOA\HpcServiceHost\$JobId"

    if (!(Test-Path -Path $jobLogDir -PathType Container)) {
        logWarn "Directory '$jobLogDir' does not exist. Maybe SOA job '$JobId' did not run on this computer."
        return
    }

    # 2. Convert *.bin binary file to *.log text file by LogParser *if not already*

    # NOTE: logparser.exe is from HPC Pack.
    $logParser = Get-Command logparser.exe

    $binFiles = dir $jobLogDir -Include *.bin -Recurse
    $count = @($binFiles).Count
    logInfo "Converting $count .bin files..."

    $out = $binFiles | %{ convertBinFile $_.FullName $logParser }
    if ($VerboseOut) {
        logInfo $($out | out-string)
    }

    # 3. Search in the text file for the message, get a list of log files that have the message, like
    #    C:\Users\hpcadmin\AppData\Local\Microsoft\Hpc\LogFiles\SOA\HpcServiceHost\{jobid}\1\Host_000000.log
    #    C:\Users\hpcadmin\AppData\Local\Microsoft\Hpc\LogFiles\SOA\HpcServiceHost\{jobid}\2\Host_000000.log
    #    ...

    $logFiles = dir $jobLogDir -Include *.log -Recurse
    $count = @($logFiles).Count
    logInfo "Searching $count .log files..."
    if ($VerboseOut) {
        logInfo ($logFiles | out-string)
    }

    $files = $logFiles | sls $Patterns -List | %{ $_.Path }

    if ($files) {
        $count = @($files).Count
        logInfo "Found $count matched files."
        if ($VerboseOut) {
            logInfo ($files | out-string)
        }
        Write-Output @{ Computer = $env:COMPUTERNAME; Files = $files }
    }
    else {
        logInfo "No matched file."
    }
}

$argList = @($JobId, $Patterns, $($VerboseOut))

if (!$Computers) {
    # NOTE: Paramter splatting here. So "@xxx" not "$xxx".
    &$checkLog @argList
}
else {
    Invoke-Command -ComputerName $Computers -ThrottleLimit 10000 -ScriptBlock $checkLog -ArgumentList $argList
}


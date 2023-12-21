<#
.SYNOPSIS
Collect SOA user log files from a computer to a local directory.

.DESCRIPTION
A path of a SOA user log file has the following pattern:

*\SOA\HpcServiceHost\{jobid}\{taskid}\Host_*.log

like

C:\Users\hpcadmin\AppData\Local\Microsoft\Hpc\LogFiles\SOA\HpcServiceHost\1\2\Host_000000.log

This script copy the log files from a computer to local, in this way:

1. A file is put in a subdirectory of $TO. The name of the subdirectory is the $Computer.
2. The file is then renamed as {jobid}-{taskid}-Host_*.log
#>

param(
    # A list of file paths local to the $Computer.
    [Parameter(Mandatory=$true)]
    [string[]]$Files,

    # A directory where the files will be copied to.
    [Parameter(Mandatory=$true)]
    [string]$To,

    # A Computer name.
    [Parameter(Mandatory=$true)]
    [string]$Computer,

    # Credential for $Computer.
    $Credential
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function ExtractJobTaskAndFilename {
    param(
        [Parameter(Mandatory=$true)]
        [string] $userLogPath
    )

    # $userLogPath should have the following pattern:
    #
    # *\SOA\HpcServiceHost\{jobid}\{taskid}\Host_*.log
    #
    # like
    #
    # C:\Users\hpcadmin\AppData\Local\Microsoft\Hpc\LogFiles\SOA\HpcServiceHost\1\2\Host_000000.log
    #
    $pattern = '.+\\(?<job>\d+)\\(?<task>\d+)\\(?<filename>Host_\d+\.\w+)'

    if (!($userLogPath -match $pattern)) {
        throw "'$userLogPath' doesn't match a path pattern of a SOA log file!"
    }
    return $Matches.job, $Matches.task, $Matches.filename
}


if (!$Credential) {
    $Credential = Get-Credential
}
$session = New-PSSession -ComputerName $Computer -Credential $Credential

$dest = New-Item -Path $To -Name $Computer -ItemType "directory" -Force

foreach ($file in $Files) {
    $job, $task, $name = ExtractJobTaskAndFilename $file
    $toFileName = "$job-$task-$name"
    $toFilePath = Join-Path -Path $dest -ChildPath $toFileName

    Write-Information "## [$Computer] Copying file '$file' to '$toFilePath'..."
    Copy-Item $file -Destination $toFilePath -FromSession $session
}


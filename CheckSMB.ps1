param(
    [int]$Interval = 1
)

$ErrorActionPreference = 'Stop'

while ($true) {
    Get-Date -Format "yyyy-MM-dd HH:mm:ss K" | out-string

    $connections = Get-SmbConnection
    if ($connections) {
        $count = @($connections).Count
        "SMB connections($count):" | out-string
        $connections |select ServerName,ShareName,UserName,NumOpens,ContinuouslyAvailable | Format-Table | out-string
    }
    else {
        "No SMB connection." | out-string
    }

    $sessions = Get-SmbSession
    if ($sessions) {
        $count = @($sessions).Count
        "SMB sessions($count):" | out-string
        $sessions | select SessionId,SecondsIdle,SecondsExists,NumOpens,ClientComputerName,ClientUserName | Format-Table | out-string
    }
    else {
        "No SMB session." | out-string
    }

    $files = Get-SmbOpenFile
    if ($files) {
        $count = @($files).Count
        "SMB open files($count):" | out-string
        $files | out-string
    }
    else {
        "No SMB open file." | out-string
    }

    sleep $Interval
}

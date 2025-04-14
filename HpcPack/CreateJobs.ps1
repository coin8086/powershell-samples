$ErrorActionPreference = 'Stop'

$jobFile = "$HOME\Documents\job-template.xml"
$interval = 15 # seconds
$startId = 10

function CreateJob
{
    "Create job $startId"

    $result = job new /jobfile:$jobFile /jobname:test$startId
    $result
    $Script:startId++

    if ($result -match 'ID: (\d+)') {
      $jobId = $Matches[1]
      job submit /id:$jobId
    }
    else {
      Write-Error "Error when creating job!"
    }
}

while ($true) {
  Get-Date -Format o
  CreateJob
  Start-Sleep $interval
  '---------------------------------'
}

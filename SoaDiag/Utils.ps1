function ExtractNodeJobAndTask {
    param(
        [Parameter(Mandatory=$true)]
        [string] $filePath
    )

    $filename = Split-Path $filePath -Leaf
    $parent = Split-Path $filePath -Parent
    $dir = Split-Path $parent -Leaf

    $pattern = '^(?<job>\d+)-(?<task>\d+)-Host_000000\.log'

    if (!($filename -match $pattern)) {
        throw "'$filename' doesn't match pattern '$pattern'!"
    }
    return [pscustomobject]@{
        Node = $dir
        Job = [int]$Matches.job
        Task = [int]$Matches.task
    }
}

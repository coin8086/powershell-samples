<#
Refer to https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions#piping-objects-to-functions
#>

$InformationPreference = 'Continue'

function ProcessPipeline {
  param (
    [int] $Addend = 10
  )
  begin {
    Write-Information "Begin"
    $count = 0
  }
  process {
    if ($_ -eq $null) {
      Write-Information "No pipeline input!"
    }
    else {
      Write-Information "Processing pipeline input $_..."
      $_ + $Addend
      $count++ # NOTE: Here $count++ doesn't count for an output.
    }
  }
  end {
    Write-Information "End($count)"
  }
}
<#
0,1,2|ProcessPipeline

Begin
Processing pipeline input 0...
10
Processing pipeline input 1...
11
Processing pipeline input 2...
12
End(3)

ProcessPipeline

Begin
No input from pipeline!
End(0)
#>


# For simple function, it is as if the function body goes to the "end" block.
function SimpleFunction {
  param (
    [int] $Addend = 10
  )
  Write-Information "Begin"
  $count = 0
  $input |
    % {
      Write-Information "Processing pipeline input $_..."
      $_ + $Addend
      $count++ # NOTE: Here $count++ doesn't count for an output.
    }
  if ($count -eq 0) {
    Write-Information "No pipeline input!"
  }
  Write-Information "End($count)"
}
<#
0,1,2|SimpleFunction

Begin
Processing pipeline input 0...
10
Processing pipeline input 1...
11
Processing pipeline input 2...
12
End(3)

SimpleFunction

Begin
No pipeline input!
End(0)
#>


# For filter function, it is as if the function body goes to the "process" block.
filter FilterPipeline {
  param (
    [int] $Addend = 10
  )
  if ($_ -eq $null) {
    Write-Information "No pipeline input!"
  }
  else {
    Write-Information "Processing pipeline input $_..."
    $_ + $Addend
  }
}
<#
0,1,2|FilterPipeline

Processing pipeline input 0...
10
Processing pipeline input 1...
11
Processing pipeline input 2...
12

FilterPipeline

No pipeline input!
#>


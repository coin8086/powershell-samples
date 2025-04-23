$jobFunction = {
  param(
    [Parameter(Mandatory)]
    [int]
    $Number,

    [string]
    $Message
  )

  "Number = $Number" | Out-Default
  "Message = $Message" | Out-Default

  #Return value
  $Number + 1
}

# NOTE the following line is simply a direct method call using a script block, which doesn't start a job.
# &$jobFunction 1 "Hello"

# Start a job. Note how arguments are passed to the job function, which is different from the way of "closure"
# in functional programming languages.
Start-Job -ScriptBlock $jobFunction -ArgumentList 1, "Hello"

# Get return value from the job, as well as the output (those by Out-Default) from within it.
# Receive-Job also raises exception/error from the job if any. Think of it like await in C#.
$x = $job | Receive-Job -Wait
"x = $x" | Out-Default

# Do not forget to remove it finally.
Remove-Job $job

$x = 1

function Foo {
  "x in script scope:"
  Get-Variable -Scope Script -Name x
  "x in local scope:"
  Get-Variable -Scope Local -Name x
  "++++++++++++++++++++++++++++++++++++++++++++++"

  "Foo: $x"
  $x++
  "Foo: $x"

  "----------------------------------------------"
  "x in script scope:"
  Get-Variable -Scope Script -Name x
  "x in local scope:"
  Get-Variable -Scope Local -Name x
}

function Bar {
  "x in script scope:"
  Get-Variable -Scope Script -Name x
  "x in local scope:"
  Get-Variable -Scope Local -Name x
  "++++++++++++++++++++++++++++++++++++++++++++++"

  "Bar: $x"
  $Script:x++
  "Bar: $x"

  "----------------------------------------------"
  "x in script scope:"
  Get-Variable -Scope Script -Name x
  "x in local scope:"
  Get-Variable -Scope Local -Name x
}

Foo

'================================================'

$x

'================================================'

Bar

$x
[CmdletBinding()]
    [Parameter()]
    [switch]
    $full
)

function get-input(){
    $inputFile = $(if( -not $full){"test_"}) + "input.txt"
    $content = Get-Content -Path $inputFile
    return $content
}


## Set up ##
cls
$result = 0

## Magic begins here ##

## Magic is done ##
Write-Host "Result: ${result}"

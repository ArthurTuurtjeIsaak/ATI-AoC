[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $test
)

function get-input(){
    $inputFile = $(if($test){"test_"}) + "input.txt"
    $content = Get-Content -Path $inputFile
    return $content
}

#####################
# Magic begins here #
#####################
$column_one = New-Object System.Collections.ArrayList
$column_twoo = New-Object System.Collections.ArrayList
get-input | ForEach-Object {
    if($_ -match '\s*(\d+)\s+(\d+)'){
        $column_one.Add($matches[1])
        $column_twoo.Add($matches[2])
    } 
}

$column_one.Sort()
$column_twoo.Sort()

$result
for($i = 0; $i -le $column_one.Count; $i++){
    $result = $result + [Math]::Abs($column_one[$i] - $column_twoo[$i])
}
Write-Host $result
[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $full
)

function get-input(){
    $inputFile = $(if(-not $full){"test_"}) + "input.txt"
    $content = Get-Content -Path $inputFile
    return $content
}

#####################
# Magic begins here #
#####################
cls

$column_one = New-Object System.Collections.ArrayList
$column_twoo = New-Object System.Collections.ArrayList
get-input | ForEach-Object {
    if($_ -match '\s*(\d+)\s+(\d+)'){
        $column_one.Add($matches[1]) | Out-Null
        $column_twoo.Add($matches[2]) | Out-Null
    } 
}

$resultHash=@{}
$result = 0
foreach($number in $column_one){
    if(!$resultHash.Contains($number)){
        $count = ($column_twoo | Where-Object {$_ -eq $number}).Count 
        $simScore = [int]$number * [int]$count
        $resultHash[$number]=$simScore
    }
    $result = $result+$resultHash[$number]
}
Write-Host $result

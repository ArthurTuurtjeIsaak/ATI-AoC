[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Full,
    [switch]$LogToScreen
)

## Default Functions ##
function initiate(){
    Clear-Host
    Set-Content -Path "$PSScriptRoot\LOG.log" -Value ""
    $script:logLine=""
}

function add-to-logline($line){
    $script:logLine = $script:logLine + "${line} | "
}
 function clear-logline {
    $script:logLine = ""    
 }

function log($logLine){
    $logOut = $(if($logLine -eq "" -or $null -eq $logLine){$script:logLine}else{$logLine})
    if($LogToScreen){
        Write-Host $logOut
    }
    Add-Content -Path "$PSScriptRoot\LOG.log" -Value $logOut
}
function get-input(){
    $inputFile = $(if( -not $full){"test_"}) + "input.txt"
    $content = Get-Content -Path $PSScriptRoot\$inputFile
    return $content
}

#############################
## Task specific functions ##
#############################
function find-xmas-from{
    param (
        [int]$col,
        [int]$row
    )
    

    $rowVectors = @(0,1,-1)
    $colVectors = @(0,1,-1)

    foreach($rowVec in $rowVectors){
        foreach($colVec in $colVectors){
            $xmasCount = $xmasCount + (find-xmas -rowVector $rowVec -colVector $colVec -lastRow $row -lastCol $col -lastChar 'X')
        }
    }
    return $xmasCount
}
function find-xmas{
    param(
        [int]$rowVector,
        [int]$colVector,
        [int]$lastRow,
        [int]$lastCol,
        [string]$lastChar)

    $curRow = $lastRow + $rowVector
    $curCol = $lastCol + $colVector
    # moeilijk doenerij t.b.v. logging
    $gridValue = $grid["${curRow},${curCol}"]
    switch -regex($gridValue){
        "X" {$curChar = "X"}
        "M" {$curChar = "M"}
        "A" {$curChar = "A"}
        "S" {$curChar = "S"}
    }
    $bingo = 0
    switch ("${lastChar},${curChar}") {
        {$_ -eq "X,M" -or $_ -eq "M,A"} {$bingo = (find-xmas -rowVector $rowVector -colVector $colVector -lastRow $curRow -lastCol $curCol -lastChar $curChar)}
        "A,S" {$grid["${curRow},${curCol}"]="(${curChar})"; return 1}
    }
    if($bingo -eq 1){
        $grid["${curRow},${curCol}"]="(${curChar})"
    }
    return $bingo
}

#################
## Main script ##
#################
initiate
$result = 0
$puzle = get-input

$rows = $puzle.Count
$columns = $puzle[0].Length

$grid = @{}

$rowCount = 0
$puzle | ForEach-Object{
    Write-Progress -Activity "Loading wordsearch" -Status "Row $($rowCount+1) of ${rows}"
    $colCount = 0
    $_ -split "" | Where-Object {$_ -ne ''}| ForEach-Object {
        $grid.add("${rowCount},${colCount}", " $($_) ")
        $colCount++
    }
    $rowCount++
}

for($row = 0; $row -le $rows; $row++){
    for($col = 0; $col -le $columns; $col++){
    Write-Progress -Activity "Running wordsearch" -Status "Row $($row+1) of ${rows} Column $($col+1) of ${columns}"
        if($grid["${row},${col}"] -eq ' X '){
            $grid["${row},${col}"]="(X)"
            $result = $result + (find-xmas-from -row $row -col $col) 
        }
    }
}
for($row = 0; $row -lt $rows; $row++){
    for($col = 0; $col -lt $columns; $col++){
        add-to-logline $grid["${row},${col}"]
    }
    log
    clear-logline
}

Write-Host "Result: ${result}"

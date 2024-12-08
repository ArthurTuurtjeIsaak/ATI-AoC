[CmdletBinding()]
param(
    [Parameter()]
    [switch]
    $full
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

function log($logLine, $toScreen){
    if($toScreen){
        Write-Host "${line} `n"
    }
    Add-Content -Path "$PSScriptRoot\LOG.log" -Value $logLine
}
function get-input(){
    $inputFile = $(if( -not $full){"test_"}) + "input.txt"
    $content = Get-Content -Path $PSScriptRoot\$inputFile
    return $content
}

## Task specific functions ##
function check-report($report){
    [int[]]$script:reportArr = $report -split " " | ForEach-Object {[int]$_}
    $script:direction = get-direction $script:reportArr[0] $script:reportArr[1]
    add-to-logline $script:direction
    $loopBound = $script:reportArr.Count-1
    for($i = 0; $i -lt $loopBound; $i++){
        $stepStatus = check-step $i
        switch ($stepStatus){
            "unsafe" {return 0}
            "wrong direction" {return 0}
        }
    }
    return 1
}

function get-direction([int]$lvlA, [int]$lvlB){
        $direction = if($lvlA -lt $lvlB){"up"}else{"down"}
        return $direction
}

function check-step([int]$i){
    $lvlA = $script:reportArr[$i]
    $lvlB = $script:reportArr[$i+1]
    $step = $lvlA - $lvlB
    add-to-logline "${lvlA} - ${lvlB} = ${step}"

    #check dirrection
    $direction = get-direction $lvlA $lvlB
    if($direction -ne $script:direction){
        add-to-logline "wrong direction"
        return "wrong direction"
    }

    if([Math]::Abs($step) -gt 3 -or $step -eq 0){
        add-to-logline "unsafe"
        return "unsafe"
    }
    return "safe"
}

## Magic begins here ##
initiate
$result = 0
$puzle = get-input
$rows = $puzle.Count
$rowCount = 0
$puzle | ForEach-Object{
    $rowCount++
    Write-Progress -Activity "Checking Reports" -Status "Row ${rowCount} of ${rows}"
    $checkResult = check-report $_
    $result = $result + $checkResult
    if($checkResult -le 1){
        log $_
        log $script:logLine
        log $(if($checkResult -eq 1){"+SAFE+"}else{"-UNSAFE-"})
        log "Current count: ${result}"
    }
    $script:logLine = ""
}

## Magic is done ##
Write-Host "Result: ${result}"

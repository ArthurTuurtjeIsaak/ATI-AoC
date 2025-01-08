[CmdletBinding()]
param(
    [Parameter()]
    [switch]
    $full
)

## Default Functions ##
function initiate(){
    Clear-Host
    Set-Content -Path .\LOG.log -Value ""
    $script:logLine=""
}

function add-to-logline($line){
    $script:logLine = $script:logLine + $line
}

function log($logLine, $toScreen){
    if($toScreen){
        Write-Host "${line} `n"
    }
    Add-Content -Path .\LOG.log -Value $logLine
}
function get-input(){
    $inputFile = $(if( -not $full){"test_"}) + "input.txt"
    $content = Get-Content -Path $inputFile
    return $content
}

## Task specific functions ##
function check-report($report){
    [int[]]$reportArr = $report -split " " | ForEach-Object {[int]$_}
    $direction = if($reportArr[0] -lt $reportArr[1]){"up"}else{"down"}
    add-to-logline "${direction} | "
    return check-safty $reportArr $direction
}

function check-safty($arry, $direction){
    $loopBound = $arry.Count - 1
    for($i=0;$i -lt $loopBound;$i++){
        $a = $arry[$i]
        $b = $arry[$i+1]
        $step = $a-$b
        $absStep = [Math]::Abs($step)
        add-to-logline "${a} - ${b} = ${step} | "
        if(-not (right-direction $step $direction) -or $absStep -ge 4){
            # step is not safe no need fo further checking
            return 0
        }
    }
    # all steps are safe report may be counted
    return 1
}

function right-direction($step, $direction){
    if($step -lt 0 -and $direction -eq "up"){
        return $true
    }elseif($step -gt 0 -and $direction -eq "down"){
        return $true
    }
    add-to-logline "wrong way"
    return $false
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
    log $_
    $checkResult = check-report $_
    $result = $result + $checkResult
    log $script:logLine
    $script:logLine = ""
    log $(if($checkResult -eq 1){"+SAFE+"}else{"-UNSAFE-"})
    log "Current count: ${result}"
    }

## Magic is done ##
Write-Host "Result: ${result}"

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
    add-to-logline "new dir"
    $script:direction = get-direction $script:reportArr[0] $script:reportArr[1]

    $script:skiped = $null

    $loopBound = $script:reportArr.Count-1
    for($i = 0; $i -lt $loopBound; $i++){
        $lvlA = $script:reportArr[$i]
        $lvlB = $script:reportArr[$i+1]
        $stepStatus = check-step $lvlA $lvlB
        
        if ($stepStatus -ne "safe"){
            $i = skip-level $i
            if($i -eq -2){
                return 0
            }             
        }
    }
    return 1
}

function skip-level($i){
    switch ($script:skiped){
        $null {
            if($i -eq 1){
                skip-first-level
                return 0
            }
    }
        "first" {
            rerun 
            return -1
        }
        "skiped" {
            add-to-logline "no seccond skip"
            return -2
        }
    }

    if(skip-general $i){
        $lvl = $script:reportArr[$i+2]
        add-to-logline "skiped to [$lvl]"
        $script:skiped = "skiped"
        return $i+1
    }else{
        return -2
    }
}

function skip-first-level(){
    $script:skiped = "first" 
    add-to-logline "first skiped"
    add-to-logline "new dir"
    $script:direction = get-direction $script:reportArr[1] $script:reportArr[2]
}

function rerun(){
    add-to-logline "rerun"
    $script:direction = get-direction $script:reportArr[0] $script:reportArr[1]
    $script:skiped = "rerun"
}
function get-direction([int]$lvlA, [int]$lvlB){
        $direction = if($lvlA -lt $lvlB){"up"}else{"down"}
        add-to-logline  $direction
        return $direction
}

function skip-general($i){
    # skip $i
    # check back
    add-to-logline "skip i" 
    $lvlIplus = $script:reportArr[$i+1]
    if($i -gt 1){
        $lvlImin = $script:reportArr[$i-1]
        $checkBack = check-step $lvlImin $lvlIplus
    }
    #check farward
    $lvlIplusplus = $script:reportArr[$i+2]
    $checkFarward = check-step $lvlIplus $lvlIplusplus

    $skipI = ($checkBack -eq "safe" -and $checkFarward -eq "safe")
    
    #skip $i++
    add-to-logline "skip i+"
    $lvlI = $script:reportArr[$i]
    $chekIplus = check-step $lvlI $lvlIplusplus
    $skipIplus = ( $chekIplus -eq "safe")

    return ($skipI -or $skipIplus)

}
function check-step($lvlA, $lvlB){
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
    add-to-logline "safe"
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

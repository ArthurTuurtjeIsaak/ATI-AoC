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

#############################
## Task specific functions ##
#############################
function check-report($report){
    [int[]]$script:reportArr = $report -split " " | ForEach-Object {[int]$_}
    if(check-array){
        return 1
    }else{
        return 0
    }
}

function check-array {
    param (
        [int]$FromPosition = 0,
        [int]$SkipPosition = -1,
        [string]$Direction,
        [switch]$Skiped
    )
    add-to-logline "NEW RUN =>"
    if($SkipPosition -eq $script:reportArr.Count-1){
        return $true
    }
    if($Direction -eq ""){
        $nextPos = $(if(($FromPosition+1) -eq $SkipPosition){$FromPosition+2}else{$FromPosition+1})
        $Direction = get-direction $script:reportArr[$FromPosition] $script:reportArr[$nextPos]
    }

    $loopBound = $script:reportArr.Count-1
    for($i=$FromPosition; $i -lt $loopBound; $i++){
        $lvlA = $script:reportArr[$i]
        
        if($SkipPosition -eq ($i+1)){
            $lvlB = $script:reportArr[$i+2]
            $i++
        }else{
            $lvlB = $script:reportArr[$i+1]
        }

        $stepStatus = check-step $lvlA $lvlB $Direction

        if($stepStatus -ne "safe"){
            if($Skiped){
                return $false
            }
            switch ($i) {
                0 {
                    # o-x
                    # s -->
                    # --s->
                    return ((check-array -FromPosition 1 -Skiped) `
                            -or (check-array -SkipPosition 1 -Skiped))
                  }
                1 {
                    # o-o-x
                    # --s->
                    #   d-s->
                    # s -->
                    return ((check-array -SkipPosition 1 -Skiped) `
                            -or (check-array -FromPosition 1 -Direction $Direction -SkipPosition 2 -Skiped) `
                            -or (check-array -FromPosition 1 -Skiped))
                }
                Default {
                    # o-o-o-x
                    #     d-s->
                    #   d-s->
                    return ((check-array -FromPosition $i -Direction $Direction -SkipPosition ($i+1) -Skiped) `
                            -or (check-array -FromPosition ($i-1) -Direction $Direction -SkipPosition $i -Skiped))
                }
            }
        }
    }

    return $true
}

function get-direction([int]$lvlA, [int]$lvlB){
        $direction = if($lvlA -lt $lvlB){"up"}else{"down"}
        add-to-logline  $direction
        return $direction
}

function check-step($lvlA, $lvlB, $stepDiraction){
    $step = $lvlA - $lvlB
    add-to-logline "${lvlA} - ${lvlB} = ${step}"

    #check dirrection
    $direction = get-direction $lvlA $lvlB
    if($direction -ne $stepDiraction){
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

#################
## Main script ##
#################
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

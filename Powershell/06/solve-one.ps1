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
    $script:logLine = $script:logLine + "${line}"
}
 function clear-logline {
    $script:logLine = ""    
 }

function log{
    param([string]$logLine,
          [switch]$inline)
    $logOut = $(if($logLine -eq "" -or $null -eq $logLine){$script:logLine ;clear-logline}else{$logLine})
    if($LogToScreen){
        Write-Host $logOut
    }
    if($inline){
        Add-Content -Path "$PSScriptRoot\LOG.log" -Value $logOut -NoNewline
    }else{
        Add-Content -Path "$PSScriptRoot\LOG.log" -Value $logOut
    }
}
function get-input(){
    $inputFile = $(if( -not $full){"test_"}) + "input.txt"
    $content = Get-Content -Path $PSScriptRoot\$inputFile
    return $content
}

#############################
## Task specific functions ##
#############################

function guard-onroute(){
    $script:nextBlock=$null
    add-to-logline "Left at ${script:guard} "
    add-to-logline "going ${script:direction} "
    switch($script:direction){
        "up"    {$script:nextBlock = $script:grid | 
                    Where-Object {$_.col -eq $script:guard.col -and $_.row -lt $script:guard.row } |
                    Sort-Object -Descending -Property row |
                    Select-Object -First 1
                    $script:direction = "right"}
        "down"  {$script:nextBlock = $script:grid | 
                    Where-Object {$_.col -eq $script:guard.col -and $_.row -gt $script:guard.row } |
                    Sort-Object -Property row |
                    Select-Object -First 1
                    $script:direction = "left"}
        "left"  {$script:nextBlock = $script:grid | 
                    Where-Object {$_.col -lt $script:guard.col -and $_.row -eq $script:guard.row } |
                    Sort-Object -Descending -Property col |
                    Select-Object -First 1
                    $script:direction = "up"}
        "right" {$script:nextBlock = $script:grid | 
                    Where-Object {$_.col -gt $script:guard.col -and $_.row -eq $script:guard.row } |
                    Sort-Object -Property row |
                    Select-Object -First 1
                    $script:direction = "down"}
    }

    if(-not $null -eq $script:nextBlock){
        steps-taken
        add-to-logline "block at ${script:nextBlock}" ; log; log $script:result
        move-guard
        guard-onroute
    }
}

function steps-taken(){
    $verticalSteps=0
    $verticalSteps = [math]::abs($script:guard.row - $script:nextBlock.row)
    $horizontalSteps = 0
    $horizontalSteps = [math]::abs($script:guard.col - $script:nextBlock.col)

    $stepsTaken = $verticalSteps + $horizontalSteps -1

    add-to-logline "Steps taken ${stepsTaken} "

    $script:result += $stepsTaken
}

function move-guard(){
    if($script:guard.row -lt $script:nextBlock.row){
        $script:guard.row = $script:nextBlock.row-1
    }elseif($script:guard.row -gt $script:nextBlock.row){
        $script:guard.row = $script:nextBlock.row+1
    }elseif($script:guard.col -lt $script:nextBlock.col){
        $script:guard.col = $script:nextBlock.col-1
    }elseif($script:guard.col -gt $script:nextBlock.col){
        $script:guard.col = $script:nextBlock.col+1
    }
}

function guard-exit(){
    switch($script:direction){
        "up"    {$script:nextBlock=[PSCustomObject]@{row = -1; col = $script:guard.col}}
        "down"  {$script:nextBlock =[PSCustomObject]@{row = $script:rowCount+1 ; col = $script:guard.col}}
        "left"  {$script:nextBlock=[PSCustomObject]@{col = $script:colCount+1; row = $script:guard.row}}
        "right" {$script:nextBlock=[PSCustomObject]@{col = -1; row = $script:guard.row}}
    }
    steps-taken
    add-to-logline "exit ${script:nextBlock}"
}

#################
## Main script ##
#################
initiate
$script:result = 0
$script:puzle = get-input
$rows = $script:puzle.Count
$script:rowCount = 0
$script:grid= [System.Collections.Generic.List[PSCustomObject]]::New()
foreach($row in $script:puzle){
    $activity = "Loading puzle."
    Write-Progress -Activity $activity -Status "Row: ${script:rowCount} of ${rows}" -PercentComplete $(($script:rowCount/$rows)*100)
    $script:colCount = 0
    $row -split "" | Where-Object {"" -ne $_} | ForEach-Object{
        if($_ -eq "#"){
            $script:grid.Add([PSCustomObject]@{row = $script:rowCount; col = $script:colCount})
            
        }elseif($_ -eq "^"){
            $script:guard=[PSCustomObject]@{row = $script:rowCount; col = $script:colCount}
        }
        $script:colCount++
    }
    $script:rowCount++
}

$script:direction = "up"
guard-onroute
guard-exit
log
Write-Host "Result: ${script:result}"
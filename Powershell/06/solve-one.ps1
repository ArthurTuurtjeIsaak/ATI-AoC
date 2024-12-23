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
    $activity = "Tracking robot"
    Write-Progress -Activity $activity -Status "Steps counted: ${script:result} Unique positions tracked $($script:mapedSteps.Count)"
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
        add-to-logline "block at ${script:nextBlock}" ; log
        move-guard
        guard-onroute
    }else{
        # gedoe
        switch ($script:direction) {
            "up"    {$script:direction = "left"; break}
            "down"  {$script:direction = "right"; break}
            "right" {$script:direction = "up"; break}
            "left"  {$script:direction = "down"; break}
        }
    }
}

function steps-taken(){
    $verticalSteps=0
    $verticalSteps = [math]::abs($script:guard.row - $script:nextBlock.row)
    $horizontalSteps = 0
    $horizontalSteps = [math]::abs($script:guard.col - $script:nextBlock.col)

    $script:stepsTaken = $verticalSteps + $horizontalSteps -1

    map-rout 

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

# Moeilijk doenerij omdat ik de opdracht niet goed heb gelezenzen 
# maar nu ook geen zin heb om alles om te bouwen
# Beetje angstig voor deel twee dat wel 
function map-rout(){
        $moveRow = $(if($script:guard.row -ne $script:nextBlock.row){$true}else{$false})
        $from = $(if($moveRow){$script:guard.row}else{$script:guard.col})
        $to = $(if($moveRow){$script:nextBlock.row}else{$script:nextBlock.col})
        
        if($script:guard.row -lt $script:nextBlock.row -or $script:guard.col -lt $script:nextBlock.col){
            $step=1
        }else{
            $step=-1
        }

        for($i = $from; $i -ne $to; $i+=$step){
            if($moveRow){
                $row = $i
                $col = $script:guard.col
            }else{
                $row = $script:guard.row
                $col = $i
            }
            $visited = "${row}|${col}"
            if($script:mapedSteps -notcontains $visited){
            `	log $visited
                $script:mapedSteps.Add($visited)
            }
        }
}

function guard-exit(){
    switch($script:direction){
        "up"    {$script:nextBlock=[PSCustomObject]@{row = -1; col = $script:guard.col}}
        "down"  {$script:nextBlock =[PSCustomObject]@{row = $script:rowCount+1 ; col = $script:guard.col}}
        "left"  {$script:nextBlock=[PSCustomObject]@{row = $script:guard.row; col = -1}}
        "right" {$script:nextBlock=[PSCustomObject]@{row = $script:guard.row; col = $script:colCount+1}}
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
    Write-Progress -Activity $activity -Status "Row: ${script:rowCount} of ${rows}" -PercentComplete $(($script:rowCount/$rows)*100)
}
$script:mapedSteps=[System.Collections.Generic.List[string]]::new()
$script:direction = "up"
guard-onroute
guard-exit
log
Write-Host "Result: ${script:result}"
Write-Host "Actual result: $($script:mapedSteps.Count-1)"
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

function map-rout(){
    $thisGrid=@($script:guardStart[0],$script:guardStart[1])
    $stepCount = 0
    while($thisGrid[0] -ge 0 -and $thisGrid[1] -ge 0 -and $thisGrid[0] -lt $script:rowCount -and $thisGrid[1] -lt $script:colCount){
        Write-Progress -Activity "Mapping guard rout" -Status "Steps taken ${stepCount}"
        #log in vector
        $inVector = $script:direction
        #get next
        $nextGrid=get-nextGrid -Grid $thisGrid
        if(is-blocked -Grid $nextGrid){
            # if next block
            switch-direction
            $nextGrid = get-nextGrid -Grid $thisGrid
        }
        #log out vector
        $outVector = $script:direction
        # add to rout 
        $thisStep=[PSCustomObject]@{vectorIn=$inVector; vectorOut=$outVector; grid=$thisGrid; index = $stepCount}
        $script:guardPath.Add($thisStep)
        $thisGrid=$nextGrid
        $stepCount++
    }
}

function get-nextGrid(){
    param(
        [Parameter()]
        [System.Array]$Grid        
       )
       $r=$Grid[0]
       $c=$Grid[1]
       switch($script:direction){
            "up"    {$r-=1}
            "down"  {$r+=1}
            "left"  {$c-=1}
            "right" {$c+=1}
        }
    return @($r,$c)
}

function is-blocked(){
    param(
        [Parameter()]
        [System.Array]$Grid
    )
    $next = $script:bloks | Where-Object {$_.row -eq $Grid[0] -and $_.col -eq $Grid[1]}
    return ($null -ne $next)
}

function bogus-blocks(){
    $stepCount = 0 ; $stepsToCheck = $script:guardPath.Count
    foreach($gridSlot in $script:guardPath){
        Write-Progress -Activity "Searching locations for bogus bloks" -Status "At gridslot [$($gridSlot.grid)]. Possible locations maped: ${script:result}" -PercentComplete (($stepCount/$stepsToCheck)*100)
        if($gridSlot.grid[0] -ne $script:guardStart[0] -or $gridSlot.grid[1] -ne $script:guardStart[1]){
             add-to-logline "Try at [$($gridSlot.grid)]"
            $script:direction = $gridSlot.vectorIn
             add-to-logline "direction in: ${script:direction}"
            $incommig = get-incommig -Grid $gridSlot.grid
             add-to-logline "incomming [$($incommig.grid)]"         
            switch-direction
             add-to-logline "direction out: ${script:direction}"
            $nextStop = get-nextStop -Grid $incommig.grid
             add-to-logline "next stop [$($nextStop.grid)]"
            if($null -ne $nextStop -and $incommig.index -gt $nextStop.index){
                add-to-logline " bogus block at ($($gridSlot.grid))" 
                $script:result+=1
            }
        }
        $stepCount++
         log
    }
}

function get-incommig(){
    param(
        [Parameter()]
        [System.Array]$Grid,
        [switch]$directionIn
    )
       $r=$Grid[0]
       $c=$Grid[1]
       switch($script:direction){
            "up"    {$r+=1}
            "down"  {$r-=1}
            "left"  {$c+=1}
            "right" {$c-=1}
        }
        $incomming = $script:guardPath | Where-Object {$_.grid[0] -eq $r -and 
                                                       $_.grid[1] -eq $c -and 
                                                       $(if($directionIn){
                                                            $_.vectorIn -eq $script:direction
                                                       }else{$_.vectorOut -eq $script:direction})}
        return $incomming
}

function get-nextStop(){
    param(
        [Parameter()]
        [System.Array]$Grid
    )
    #get next block
    switch($script:direction){
        "up"    {$nextBlock = $script:bloks | 
                    Where-Object {$_.col -eq $Grid[1] -and $_.row -lt $Grid[0]} |
                    Sort-Object -Descending -Property row |
                    Select-Object -First 1;break}
        "down"  {$nextBlock = $script:bloks | 
                    Where-Object {$_.col -eq $Grid[1] -and $_.row -gt $Grid[0]} |
                    Sort-Object -Property row |
                    Select-Object -First 1;break}
        "left"  {$nextBlock = $script:bloks | 
                    Where-Object {$_.col -lt $Grid[1] -and $_.row -eq $Grid[0]} |
                    Sort-Object -Descending -Property col |
                    Select-Object -First 1;break}
        "right" {$nextBlock = $script:bloks | 
                    Where-Object {$_.col -gt $Grid[1] -and $_.row -eq $Grid[0]} |
                    Sort-Object -Property col |
                    Select-Object -First 1;break}
    }
    #get step from path
    $incomming = get-incommig -Grid @($nextBlock.row, $nextBlock.col) -directionIn
    return $incomming
}

function switch-direction(){
    switch($script:direction){
        "up"    {$script:direction = "right"; break}
        "down"  {$script:direction = "left" ; break}
        "left"  {$script:direction = "up"   ; break}
        "right" {$script:direction = "down" ; break}
    }
}

#################
## Main script ##
#################
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
initiate
$script:result = 0
$script:puzle = get-input
$rows = $script:puzle.Count
$script:rowCount = 0
$script:bloks= [System.Collections.Generic.List[PSCustomObject]]::New()
foreach($row in $script:puzle){
    $activity = "Loading puzle."
    $script:colCount = 0
    $row -split "" | Where-Object {"" -ne $_} | ForEach-Object{
        if($_ -eq "#"){
            $script:bloks.Add([PSCustomObject]@{row=$script:rowCount;col=$script:colCount})
            
        }elseif($_ -eq "^"){
            $script:guardStart=@($script:rowCount, $script:colCount)
        }
        $script:colCount++
    }
    $script:rowCount++
    Write-Progress -Activity $activity -Status "Row: ${script:rowCount} of ${rows}" -PercentComplete $(($script:rowCount/$rows)*100)
}
$script:direction = "up"
$script:guardPath=[System.Collections.Generic.List[PSCustomObject]]::new()
map-rout
bogus-blocks
$stopwatch.Stop()
Write-Host "Result ${script:result} `nTotal runtime: $($stopwatch.Elapsed.TotalMinutes) minutes"
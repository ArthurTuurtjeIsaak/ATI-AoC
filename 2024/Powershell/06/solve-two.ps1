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

function add-Block(){
    param(
        [System.Array]$Grid
    )

    if(-not $script:blocks.ContainsKey($Grid[0])){
        $script:blocks[$Grid[0]]=@{}
    }
    $script:blocks[$Grid[0]][$Grid[1]]=@($Grid[0],$Grid[1])
}

function remove-Block(){
    param(
        [System.Array]$Grid
    )
    $script:blocks[$Grid[0]].Remove($Grid[1])
    if($script:blocks[$Grid[0]].Count -eq 0){$script:blocks.Remove($Grid[0])}
}

function get-key(){
    param(
        [System.Array]$Grid,
        [string]$Direction
    )
    return "[$($Grid[0])|$($Grid[1])] $Direction"
}

function sim-loop(){
    param(
        [System.Array]$Grid,
        [string]$Direction
    )
    
    $thisKey = get-key -Grid $Grid -Direction $Direction
    add-to-logline "TK ${thisKey} `n"
    $script:miniloop[$thisKey]=$Grid
    $nextStop = get-nextStop -Grid $Grid -Direction $Direction
    add-to-logline "NK $($nextStop.Key) `n"
    if($null -eq $nextStop){
        add-to-logline "FAIL `n-------------------------"
        log
        return $false
    }elseif($script:miniloop.ContainsKey($nextStop.Key)){
        add-to-logline "LOOP `n++++++++++++++++++++++++++"
        log
        return $true
    }elseif(sim-loop -Grid $nextStop.Grid -Direction $nextStop.Direction){
        return $true
    }else{
        return $false
    }
}

function get-nextStop {
    param (
        [System.Array]$Grid,
        [string]$Direction
    )
    $nextR=$Grid[0]
    $nextC=$Grid[1]
    switch ($Direction) {
        "up"    {$nextR= $script:blocks.Keys|Where-Object{$_ -lt $nextR}|Sort-Object -Descending|
                 Where-Object{$script:blocks[$_].Contains($nextC)}|Select-Object -First 1;
                 if($null -eq $nextR){$nextR=-1}else{$nextR+=1};break }
        "down"  {$nextR= $script:blocks.Keys|Where-Object{$_ -gt $nextR}|Sort-Object|
                 Where-Object{$script:blocks[$_].Contains($nextC)}|Select-Object -First 1; $nextR-=1;break }
        "left"  {$nextC= $script:blocks[$nextR].Keys|Where-Object {$_ -lt $nextC}|
                 Sort-Object -Descending|Select-Object -First 1;if($null -eq $nextC){$nextC=-1}else{$nextC+=1};break }
        "right" {$nextC= $script:blocks[$nextR].Keys|Where-Object {$_ -gt $nextC}|
                 Sort-Object|Select-Object -First 1; $nextC-=1;break }
    }
    $newDirection=switch-direction -directionIn $Direction
    $newKey=get-key -Grid @($nextR,$nextC) -Direction $newDirection
    if($nextR -lt 0 -or $nextC -lt 0){
        return $null
    }else{
        return @{Key=$newKey;Grid=@($nextR,$nextC);Direction=$newDirection} 
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

function switch-direction(){
    param(
        [string]$directionIn
    )
    switch($directionIn){
        "up"    {$directionOut = "right"; break}
        "down"  {$directionOut = "left" ; break}
        "left"  {$directionOut = "up"   ; break}
        "right" {$directionOut = "down" ; break}
    }
    return $directionOut
}

#################
## Main script ##
#################
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
initiate
$script:result=@{}
$script:puzle = get-input
$rows = $script:puzle.Count
$script:rowCount = 0
$script:blocks=@{} 
foreach($row in $script:puzle){
    $activity = "Loading puzle."
    $script:colCount = 0
    $script:blocks[$script:rowCount]=@{}
    $row -split "" | Where-Object {"" -ne $_} | ForEach-Object{
        if($_ -eq "#"){
           add-Block -Grid @($script:rowCount, $script:colCount)
        }elseif($_ -eq "^"){
            $script:startGrid=@($script:rowCount,$script:colCount)
        }
        $script:colCount++
    }
    $script:rowCount++
    Write-Progress -Activity $activity -Status "Row: ${script:rowCount} of ${rows}" -PercentComplete $(($script:rowCount/$rows)*100)
}
$script:direction = "up"
$script:loopers=@{}
$r=$script:startGrid[0]; $c=$script:startGrid[1]
while($r -ge 0 -and $c -ge 0 -and $r -lt $script:rowCount -and $c -lt $script:colCount){
    $thisGrid = @($r, $c)
    $thisKey = get-key -Grid $thisGrid -Direction $script:direction
    $nextGrid = get-nextGrid -Grid $thisGrid
    $blockKey = get-key -Grid $nextGrid
    if(-not $script:result.ContainsKey[$blockKey]){
        if($script:blocks.ContainsKey($nextGrid[0]) -and $script:blocks[$nextGrid[0]].ContainsKey($nextGrid[1])) {
            $script:direction = switch-direction -DirectionIn $script:direction
        }else{
            $script:miniloop=@{}
            add-Block -Grid $nextGrid
            $status = "Bogus block at [$($nextGrid[0])|$($nextGrid[1])]"
            add-to-logline "${status}`n"
            Write-Progress -Activity "Running Sims" -Status $status
            if(sim-loop -Grid $startGrid -Direction "up"){
                $script:result[$blockKey]=$nextGrid
            }
            $r=$nextGrid[0]
            $c=$nextGrid[1]
            remove-Block -Grid $nextGrid
            clear-logline
        }
    }
}

$stopwatch.Stop()
Write-Host "Result $($script:result.Count) `nTotal runtime: $($stopwatch.Elapsed.TotalMinutes) minutes"
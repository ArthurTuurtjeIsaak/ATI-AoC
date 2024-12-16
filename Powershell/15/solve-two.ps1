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

function create-mapObjects{
    param(
        [int]$row,
        [int]$col,
        [string]$type
    )
    $objects=@()
    switch ($type){
        "O"{$objects += new-mapObject -type "[" -row $row -col $col; $objects+= new-mapObject -type "]" -row $row -col ($col+1); break }
        "#"{for([int]$i=0; $i -lt 2; $i++){$objects+= new-mapObject -type "#" -row $row -col ($col+$i)}; break}
        "@"{$objects+= new-mapObject -type $type -row $row -col $col}        
    }
    return $objects
}

function new-mapObject{
    param(
        [int]$row,
        [int]$col,
        [string]$type
    )
    $mapObject = [PSCustomObject]@{
                            type = $type
                            row = $row
                            col = $col
                    }
                if($type -ne "#"){
                    if($type -eq "["){
                        $mapObject | Add-Member -MemberType ScriptMethod -Name "getGps" -Value $getObjectGps
                    }
                    $mapObject | Add-Member -MemberType ScriptMethod -Name "move" -Value $moveOnObject
                } 
                if($mapObject.type -eq '@'){
                    $robbie = $mapObject
                }
    return $mapObject
}

function add-toMap{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [PSCustomObject]$mapObject
    )
    process{
        $key = "$($mapObject.row) $($mapObject.col)"

        if($map.ContainsKey($key)){
            $map[$key].Add($mapObject)
        }else{
            $map[$key] = [System.Collections.Generic.List[object]]::new()
            $map[$key].Add($mapObject)
        }
    }
}

function move-object {
    param (
        [int[]]$vector,
        [PSCustomObject]$mapObject
    )

    $oldKey = "$($mapObject.row) $($mapObject.col)"
    if($map.ContainsKey($oldKey)){
        $map[$oldKey].Remove($mapObject)
        if($map[$oldKey].Count -eq 0){
            $map.Remove($oldKey)
        }
    }

    $mapObject.move($vector)
    $mapObject | add-toMap 
}

function get-next {
    param (
        [PSCustomObject]$mapObject,
        [int[]]$Vectort
    )
    $key = "$($mapObject.row+$Vectort[0]) $($mapObject.col+$Vectort[1])"

    return $map[$key]
}

function move-next {
    param (
        [PSCustomObject]$FromObject,
        [int[]]$Vector
    )
        
    $nextObject = get-next -mapObject $FromObject -Vectort $Vector
    $iets = switch ($nextObject.type) {
        "#" { $moveVector = @(0,0);break}
        "O" { $moveVector = @(move-next -FromObject $nextObject -Vector $Vector);break}
        $null {$moveVector = $Vector}
    } 
    move-object -mapObject $FromObject -vector $moveVector | Out-Null
    return $moveVector
}

function log-grid{
    for($r=0; $r -lt $gridRows; $r++){
        for($c=0; $c -lt $colCount; $c++){
            add-to-logline $(if($null -eq $map["${r} ${c}"]){"."}else{$map["${r} ${c}"].type})
        }
        log
    }
}

#################
## Main script ##
#################
initiate
$result = 0
$puzle = get-input
$rows = $puzle.Count

## Task specific objects ##
[PSCustomObject]$robbie=$null

$getObjectGps={
    $gps = 100 * $this.row + $this.col
    return $gps
}

$moveOnObject={
    param(
        [int[]]$vector
    )
    $this.row += $vector[0]
    $this.col += $vector[1]
}

$vectorLib=@{
    "^" = @(-1,0)
    ">" = @(0,1)
    "<" = @(0,-1)
    "v" = @(1,0)
}

$map =@{}
$roboInstructions =@()
$gridRows = 0
# load task loop
$rowCount = 0
$puzle | ForEach-Object{
    if($_ -match '#'){
    $colCount = 0
        $activity = "Loading map"
        $_ -split '' | Where-Object{$_ -ne ''} | ForEach-Object {
            if($_ -ne "."){
                create-mapObjects -row $rowCount -col $colCount -type $_ | add-toMap
            }
            $colCount+=2
        }
        $gridRows++
    }else{
        $activity = "Loading robot instruction"
        Write-Progress -Activity $activity -Status "Row $($rowCount+1) of ${rows}"
        $roboInstructions += $_ -split '' | Where-Object {$_ -ne ''}
    }
    $rowCount++
}
log-grid
# execute task loop
foreach($instruction in $roboInstructions){
    $activity = "Running instructions"
    $instCount++
    Write-Progress -Activity $activity -Status "${instCount} of $($roboInstructions.Count)"
    # get vector
    $instructionVector = $vectorLib[$instruction]
    # get starting point
    move-next -FromObject $robbie -Vector $instructionVector | Out-Null
    # log-grid
}

log " "
log-grid
# for ach object in map get gps if type = o
$map.GetEnumerator() | Where-Object {$_.Value.type -eq "["} | ForEach-Object {$result += $_.Value.getGps()}

Write-Host "Result: ${result}"
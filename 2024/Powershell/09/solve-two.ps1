[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Full,
    [switch]$LogToScreen
)

#######################
## Default Functions ##
#######################

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
function Get-MatchingSectorKey {
    param(
        [int]$Length,
        [int]$Index
    )
   $sectorKey = $emptySectors.Keys | Where-Object {$emptySectors[$_].emptySpace -ge $Length} | Sort-Object | Select-Object -First 1
   $highKey = $emptySectors.Keys | Sort-Object -Descending| Select-Object -First 1
   if($null -eq $sectorKey){
       log "-----------------------------------" 
       log "Mapping empty sectors from ${highKey} to ${Index}."
        for([int]$key = ($highKey+2); $key -lt $Index; $key+=2){
            add-to-logLine "${key}|"
            $emptySectors.Add($key, [PSCustomObject]@{totalSpace=[int][string]$row[$key]; emptySpace=[int][string]$row[$key]})
            $emptySectors[$key] | Add-Member -MemberType ScriptMethod -Name innerIndex -Value $innerIndex
            if($emptySectors[$key].emptySpace -ge $Length){
                $sectorKey = $key
                break
            }
        }
        log
        log "----------------------------------"
   }
    return $sectorKey
}

function Get-Position{
    param(
        [int]$Index
    )
    if(-not $positions.containsKey($Index)){
        $highKey = $positions.Keys | Sort-Object -Descending | Select-Object -First 1
        log "----------------------------------"
        log "Mapping pos from ${highKey} to ${Index}"
        for($j=($highKey+1); $j -le $Index; $j++){
            $positions.Add($j, $positions[($j-1)]+[int][string]$row[($j-1)])
        }
        log "----------------------------------"
    }
    return $positions[$Index]
}

$innerIndex = {
    return ($this.totalSpace - $this.emptySpace)
}

#################
## Main script ##
#################
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
initiate
$script:puzle = get-input

#  0     1     2     3     4
#  0  2  5  8  11 12 15 18 19 21 22 26 27 31 32 35 36 40 40
#  2  3  3  3  1  3  3  1  2  1  4  1  4  1  3  1  4  0  2
#  0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18

$row = $script:puzle # omdat ik geen zin heb om steeds $script:puzle te typen
$endOfRow = $row.Length
log "Input length = ${endOfRow}"
log "======================================================================================="
$emptySectors=@{} 
# preload first empty sector
$emptySectors.Add(1, [PSCustomObject]@{totalSpace=[int][string]$row[1]; emptySpace=[int][string]$row[1]})
$emptySectors[1] | Add-Member -MemberType ScriptMethod -Name innerIndex -Value $innerIndex

$positions=@{}
# preload first position
$positions.Add(1, [int][string]$row[0])
$checkSums=0
for([int]$i=($endOfRow-1); $i -gt 0; $i--){
    Write-Progress -Activity "Defragmentation in process" -Status "Defrag at index ${i}" -PercentComplete ((($endOfRow-$i)/$endOfRow)*100)
    # if file
    if(($i % 2)-eq 0){
        $fileId = $i / 2
        $fileLength = [int][string]$row[$i]
        log "File length: $($row[$i]), at ${i}, id ${fileId}"
        
        # find empty sector that fits
        $msKey = Get-MatchingSectorKey -Length $fileLength -Index $i
        $pos = 0
        if($null -ne $msKey){
            log "Empty sector found at ${msKey}, inner index: $($emptySectors[$msKey].innerIndex()), empty space: $($emptySectors[$msKey].emptySpace), total space: $($emptySectors[$msKey].totalSpace)"
            $pos = Get-Position -Index $msKey
            log "position at ${msKey}: ${pos}"
            $pos = $pos + $emptySectors[$msKey].innerIndex()
            $emptySectors[$msKey].emptySpace = $emptySectors[$msKey].emptySpace - $fileLength
        }else{
            log "No empty sector found."
            $pos = Get-Position -Index $i
            log "position at ${i}: ${pos}"
        }
        for($ii=0; $ii -lt $fileLength; $ii++){
            $checkSum = $fileId * ($pos+$ii)
            log "Checksum: ${fileId} * $(($pos+$ii)) = ${checkSum}"
            add-to-logline "${checkSums} + ${checkSum} = "
            $checkSums = $checkSums+$checkSum
            add-to-logline "${checkSums}" ; log
        }
        log "======================================================================================="
    }
}
Write-Host "Result: ${checkSums}"
Write-Host "Runtime: $($stopwatch.Elapsed.TotalMinutes) minutes."

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


#################
## Main script ##
#################
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
initiate
$script:puzle = get-input
$row = $script:puzle -Split "" | Where-Object {$_ -ne ""}| ForEach-Object {[int]$_} 

#  0     1     2     3     4
#  F  s  F  s  F  s  F  s  F
#  2  3  3  3  1  3  3  1  2
#  0  1  2  3  4  5  6  7  8

# $esi == $emptySpaceIndex
[long]$esi = 1
[long]$position = $row[0]
[long]$lastFileIndex = ($row.Count - 1)
# preload first defrag
[int]$fileFragments = $row[$lastFileIndex]
[long]$checkSums=0
[long]$checkSum=0
$filesDone = [System.Collections.Generic.HashSet[int]]::New()
while ($esi -le $lastFileIndex){
    Write-Progress -Activity "Defrag in progress" -Status "Padding $($row[$esi]) sectors at index ${esi}"
    # checksum previos file except the first one (checksum of 0 will be 0)
    if($esi -gt 1){
        for([int]$fl = 0; $fl -lt $row[$esi-1];$fl++){
            $filesDone.Add(($esi-1)) | Out-Null
            $checkSum = (($esi-1)/2)*$position++
            log "$('{0:d6}' -f $esi) | $('{0:d4}' -f (($esi-1)/2)) x $('{0:d5}' -f ($position-1)) = $('{0:d9}' -f $checkSum) | file F[$($row[$esi-1])] at $($esi-1)"
            $checkSums+= $checkSum
        }
    }
    log "-----------------------------------------"

    #pad and checksum this empty space
    for($es = 0 ; $es -lt $row[$esi]; $es++){
        $checkSum = ($lastFileIndex/2)*$position++
        log "$('{0:d6}' -f $esi) | $('{0:d4}' -f ($lastFileIndex/2)) x $('{0:d5}' -f ($position-1)) = $('{0:d9}' -f $checkSum) | fragment from F[$($row[$lastFileIndex])] at ${lastFileIndex}" 
        $checkSums+=$checkSum
        $fileFragments-=1
        if($fileFragments -eq 0){
            if(-not $filesDone.Contains(($lastFileIndex -= 2))){
                # check if there are files left to pad with
                $fileFragments = $row[$lastFileIndex]
                $filesDone.Add($lastFileIndex) | Out-Null
            }else{
                log $lastFileIndex
                break
            }
        }
    }
    $esi+=2
    log "-----------------------------------------" 
}
while($fileFragments -gt 0){
    $checkSum = ($lastFileIndex/2)*$position++
    log "$($lastFileIndex/2) x ${position} = ${checkSum}"
    $checkSums+=$checkSum
    $fileFragments-=1
}
Write-Host "Result: ${checkSums}"
Write-Host "Runtime: $($stopwatch.Elapsed.TotalMinutes) minutes."

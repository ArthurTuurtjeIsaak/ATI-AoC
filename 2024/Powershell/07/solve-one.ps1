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

function calculate(){
    param(
        [long]$fromI,
        [System.Array]$calcArray
    )
    $thisResult=[System.Collections.Generic.HashSet[long]]::new()
    if($fromI -eq 0){
        $thisResult.Add([long]$calcArray[0]) | Out-Null
    }else{
        $inputSet = calculate -fromI ($fromI-1) -calcArray $calcArray 
        foreach($i in $inputSet){
            $thisResult.Add([long]$calcArray[$fromI]*$i) | Out-Null
            $thisResult.Add([long]$calcArray[$fromI]+$i) | Out-Null
        }
    }
    return $thisResult
}

#################
## Main script ##
#################
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
initiate
$script:puzle = get-input
$rows = $script:puzle.Count
$rowCount = 0
foreach($row in $script:puzle){
    Write-Progress -Activity "Running calculations:" -Status "calc ${rowCount} of ${rows}" -PercentComplete $(($rowCount/$rows)*100)
    $rowCount++
    $splitRow = $row -split ":"
    $testvalue = [long]$splitRow[0]
    $calcValues = $splitRow[1].split()| Where-Object {$_.Trim() -ne ''}
    $resultSet = calculate -fromI ($calcValues.Count-1) -calcArray $calcValues
    if($resultSet.Contains($testvalue)){
        $result+=$testvalue
    }
}
Write-Host "Result: ${result}"
Write-Host "Runtime: $($stopwatch.Elapsed.TotalMinutes) minutes."

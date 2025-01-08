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
$rows = $script:puzle.Count
$rowCount = 0
foreach($row in $script:puzle){
    Write-Progress -Activity "Running calculations:" -Status "calc ${rowCount} of ${rows}" -PercentComplete $(($rowCount/$rows)*100)
    $rowCount++
}
Write-Host "Runtime: $($stopwatch.Elapsed.TotalMinutes) minutes."

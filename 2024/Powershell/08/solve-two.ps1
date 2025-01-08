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
$antenas=New-Object System.Collections.Hashtable([System.StringComparer]::Ordinal)
foreach($row in $script:puzle){
    Write-Progress -Activity "Loading antena grid:" -Status "Row ${rowCount} of ${rows}" -PercentComplete $(($rowCount/$rows)*100)
    $colCount = 0
    $row -split "" | Where-Object {$_ -ne ""}| ForEach-Object{
       if($_ -ne ".") {
            if(-not $antenas.ContainsKey($_)){
               $antenas[$_]=@{}
            }          
            $antenas[$_].Add("${rowCount},${colCount}", @($rowCount, $colCount))
       }
       $colCount++
    }
    $rowCount++
}
$antinodes=[System.Collections.Generic.HashSet[string]]::new()
[int]$totalCount=0
$antenas.Values| ForEach-Object{
    foreach($m in $_.Keys){
        foreach($o in $_.Keys){
            if($m -ne $o){
                $rc = $_[$m][0]-$_[$o][0]
                $cc = $_[$m][1]-$_[$o][1]
                $r = $_[$m][0]
                $c = $_[$m][1]
                while($r -ge 0 -and $c -ge 0 -and $r -lt $rowCount -and $c -lt $colCount){
                    $totalCount++
                    $antinodes.Add("${r},${c}")|Out-Null
                    $r+=$rc
                    $c+=$cc
                }
            }
        }
    }
}
for($i=0; $i -lt $rows; $i++){
    for($ii=0; $ii -lt $colCount; $ii++){
        $grid="${i},${ii}"
        if($antinodes.Contains($grid)){add-to-logline "#"}else{add-to-logline "."}
    }
    log
}

Write-Host "Result: $($antinodes.Count). Total count: ${totalCount}"
Write-Host "Runtime: $($stopwatch.Elapsed.TotalMinutes) minutes."

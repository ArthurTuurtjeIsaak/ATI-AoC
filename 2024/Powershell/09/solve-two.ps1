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
$innerIndex = {
    return ($this.totalSpace - $this.emptySpace)
}

#################
## Main script ##
#################
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
initiate
$script:puzle = get-input
$files=@{}
$emptySectors=@{} 
$positions=@{}
$index=0
$rowPos=0
$script:puzle -Split "" | Where-Object {$_ -ne ""}| ForEach-Object {
    Write-Progress -Activity "Mapping the puzzle"  -PercentComplete (($index/$script:puzle.Length)*100)
    if(($index % 2) -eq 0){
        $files.Add($index, [PSCustomObject]@{length=$_; optimized=$false; id=($index / 2)})
    }else{
        $emptySectors.Add($index, [PSCustomObject]@{totalSpace=[int]$_; emptySpace=[int]$_})
        $emptySectors[$index] | Add-Member -MemberType ScriptMethod -Name innerIndex -Value $innerIndex
    }
    $rowPos+=[int]$_
    $positions.Add(++$index, $rowPos)
} 

#  0     1     2     3     4
#  F  s  F  s  F  s  F  s  F
#  2  3  3  3  1  3  3  1  2
#  0  1  2  3  4  5  6  7  8

[int]$fi= $files.Keys | Sort-Object -Descending | Select-Object -First 1
# defrag and cheksum from back to front
for($fi; $fi -gt 0; $fi-=2){
    Write-Progress -Activity "Optimizing files" -Status "Checking file $($files[$fi].id) at ${fi}"
    if(-not $files[$fi].optimized){
        # find empty space
        $esi = $emptySectors.Keys | Where-Object {$emptySectors[$_].emptySpace -ge $files[$fi].length} | Sort-Object | Select-Object -First 1
        if($null -ne $esi){
            # get pos 
            $pos = ($positions[$esi] + $emptySectors[$esi].innerIndex())
            # fill empty space
            $emptySectors[$esi].emptySpace = $emptySectors[$esi].emptySpace - $files[$fi].length
            # checksum
            for([int]$i=0; $i -lt $files[$fi].length; $i++){
                $checkSum = $files[$fi].id * ($pos+$i)
                $checkSums+=$checkSum
            }
            Remove-Variable i
            $files[$fi].optimized = $true
        }
    }
}
# checksum others
$files.Keys | Where-Object {-not $files[$_].optimized} | ForEach-Object {
    Write-Progress -Activity "Checksum whats left" -Status "file $($files[$_].id) at $($_)."
    $pos = $positions[$_]
    for([int]$i=0; $i -lt $files[$_].length; $i++){
        $checkSum = $files[$_].id * ($pos+$i)
        $checkSums+=$checkSum
    }
}
Write-Host "Result: ${checkSums}"
Write-Host "Runtime: $($stopwatch.Elapsed.TotalMinutes) minutes."

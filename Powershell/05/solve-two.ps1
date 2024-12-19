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
function get-abs-diff{
    param(
        [int]$indexA,
        [int]$indexB
    )
    $diff = $indexA - $indexB
    return $(if($diff -lt 0){"negative"}else{"positive"})
}
#################
## Main script ##
#################
initiate
$result = 0
$puzle = get-input
$rows = $puzle.Count

# task specific script variables
$rules =@{}
$pages =@()

# load task loop
$rowCount = 0
$puzle | ForEach-Object{
    if($_ -match '\|'){
        $activity = "Loading rules"
        $rules.Add(
                    $_,
                    ($_ -split '\|') -as [int[]] 
        )
    }else{
        $activity = "Loading pages"
        if(-not $_ -eq ""){
            $pages += ,$([System.Collections.Generic.List[int]]($_ -split ',') -as [int[]])
        }
    }
    Write-Progress -Activity $activity -Status "Row $($rowCount+1) of ${rows}"
    $rowCount++
}

# execute task loop
$rowCount = 0
$rows = $pages.Count
:row foreach($row in $pages){
    $activity = "Processing pages"
    Write-Progress -Activity $activity -Status "Row ${rowCount} of ${rows}" -PercentComplete (($rowCount/$rows)*100)
    $rowCount++
    add-to-logline $row
    foreach($page in $row){
        # get rules for page
        $pageRules = $rules.GetEnumerator() | Where-Object {$_.Key -match "${page}"}
        foreach($rule in $pageRules){
            # check index diff rule
            $pageRuleIndex = $rule.Value.indexOf($page)
            $otherRuleIndex = $(if($pageRuleIndex -eq 0){1}else{0})
            $other = $rule.Value[$otherRuleIndex] 
            $ruleDiff = get-abs-diff -indexA $pageRuleIndex -indexB $otherRuleIndex
            # check index diff row
            $pageRowIndex = $row.indexOf($page)
            $otherRowIndex = $row.indexOf($other)
            # check if other is present in row
            if($otherRowIndex -eq -1){
                continue
            }
            $rowDiff = get-abs-diff -indexA $pageRowIndex -indexB $otherRowIndex
            if($ruleDiff -ne $rowDiff){
                # waar heen
                #
            }
        }
    }
    log
    $middleIndex = [Math]::Floor($($row.Count /2))
    log "middle page $($row[$middleIndex])"
    $result += $row[$middleIndex]
}

Write-Host "Result: ${result}"

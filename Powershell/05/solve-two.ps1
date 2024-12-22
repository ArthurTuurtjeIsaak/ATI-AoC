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

function add-to-logline(){
    param(
        [Parameter(ValueFromPipeline)]
        [object]$line
    )
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

function getRowRules(){
    param(
        [int[]]$row
    )
    $rowRules=@{}
        foreach($page in $row){
        # Filter matching rules for the current page
        foreach ($rule in $rules.GetEnumerator()) {
            if ($row -contains $rule.Value[0] -and $row -contains $rule.Value[1]) {
                $rowRules[$rule.Key] = $rule.Value
            }
        }
    }
    return $rowRules
}

function check-row(){
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.Collections.Generic.List[int]]$row,
        [hashtable]$rowRules
    )
    $clean = $true
    $ruleKeys = $rowRules.Keys
    for($i=0; $i -lt $row.Count; $i++){
        $page = $row[$i]
        foreach($key in $ruleKeys){
            if($key -match "^${page}\|"){
                $other = $rowRules[$key][1]
                if($row.IndexOf($other) -lt $row.IndexOf($page)){
                    $row.Remove($other) | Out-Null
                    $row.Insert(($row.IndexOf($page)+1),$other)
                    $i=-1
                    $clean = $false
                }
            }elseIf($key -match "\|${page}"){
                 $other = $rowRules[$key][1]
                 if($row.IndexOf($other) -gt $row.IndexOf($page)){
                    $row.Remove($page) | Out-Null
                    $row.Insert(($row.IndexOf($other)+1),$page)
                    $i=-1
                    $clean = $false
                }
            }
        }
    }
    
    Write-Output $(if($clean){0}else{$row})
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
    
    $rowRules = getRowRules $row
    $row = check-row -row $row -rowRules $rowRules
    $middleIndex = [Math]::Floor($($row.Count /2))
    log "middle page $($row[$middleIndex])"
    $result += $row[$middleIndex]
}
   
Write-Host "Result: ${result}"

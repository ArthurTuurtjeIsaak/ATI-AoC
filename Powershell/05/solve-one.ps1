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
    $logOut = $(if($logLine -eq "" -or $null -eq $logLine){$script:logLine}else{$logLine})
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
initiate
$result = 0
$puzle = get-input

$rows = $puzle.Count
$columns = $puzle[0].Length

$grid = @{}

$rowCount = 0
$puzle | ForEach-Object{
    Write-Progress -Activity "Loading wordsearch" -Status "Row $($rowCount+1) of ${rows}"
    $colCount = 0
    $_ -split "" | Where-Object {$_ -ne ''}| ForEach-Object {
        $grid.add("${rowCount},${colCount}", " $($_) ")
        $colCount++
    }
    $rowCount++
}

for($row = 0; $row -le $rows; $row++){
    for($col = 0; $col -le $columns; $col++){
    Write-Progress -Activity "Running wordsearch" -Status "Row $($row+1) of ${rows} | Column $($col+1) of ${columns}"
        if($grid["${row},${col}"] -eq ' A '){
            $blub =  (find-xmas-from -row $row -col $col) 
            $result = $result + $blub
            if($blub -gt 0){$grid["${row},${col}"]="(A)"}
        }
    }
}
for($row = 0; $row -lt $rows; $row++){
    for($col = 0; $col -lt $columns; $col++){
        add-to-logline $grid["${row},${col}"]
    }
    log
    clear-logline
}

Write-Host "Result: ${result}"

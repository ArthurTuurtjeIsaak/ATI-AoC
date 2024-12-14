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
function find-xmas-from{
    param (
        [int]$col,
        [int]$row
    )
    $exVectorSet = @(@(@(-1,-1),@(1,1)),@(@(1,-1),@(-1,1)))

    $xmasCount = $xmasCount + (find-x-mas -vectorSet $exVectorSet -centerGrid $row,$col -lineCount 0)

    return $xmasCount
}

function find-x-mas{
    param(
        [object[]]$vectorSet,
        [int[]]$centerGrid,
        [int]$lineCount)

        $masArr=@('A')
        #go one
        $gridOne=@(($centerGrid[0]+$vectorSet[$lineCount][0][0]), ($centerGrid[1]+$vectorSet[$lineCount][0][1]))
        $masArr+= get-gridValue -gridSlot $gridOne
        #go two
        $gridTwo=@(($centerGrid[0]+$vectorSet[$lineCount][1][0]), ($centerGrid[1]+$vectorSet[$lineCount][1][1]))
        $masArr+= get-gridValue -gridSlot $gridTwo
        #if mas
        if(('M' -in $masArr) -and ('A' -in $masArr) -and ('S' -in $masArr)){
            # if 1 find-mas 2
            if($lineCount -eq 0){
                $bingo = find-x-mas -vectorSet $vectorSet -centerGrid $centerGrid -lineCount 1
            }else{
            # else return 1
                $bingo = 1
            }
        }else{
            #else return 0
            return 0
        }
       if($bingo -eq 1){
            mark-grid $gridOne  
            mark-grid $gridTwo
       }  
            
       return $bingo    
}

# moeilijk doenerij t.b.v. logging
function get-gridValue{
    param(
        [int[]]$gridSlot)
    $gridValue = $grid["$($gridSlot[0]),$($gridSlot[1])"]
    switch -regex($gridValue){
        "X" {$curChar = 'X'}
        "M" {$curChar = 'M'}
        "A" {$curChar = 'A'}
        "S" {$curChar = 'S'}
    }
    return $curChar
}


function  mark-grid{
    param(
        [int[]]$gridSlot)
    $gridValue = $grid["$($gridSlot[0]),$($gridSlot[1])"].Trim()
    if(-not ($gridValue -match "\(.\)")){
        $grid["$($gridSlot[0]),$($gridSlot[1])"]= "(${gridValue})"
    }
}

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

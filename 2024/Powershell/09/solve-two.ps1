
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Full,
    [switch]$LogToScreen
)

#######################
## Default Functions ##
#######################

function Initiate {
    Clear-Host
    Set-Content -Path "$PSScriptRoot\LOG.log" -Value ""
    $script:logLine = ""
}

function Add-ToLogline {
    param([string]$Line)
    $script:logLine += "${Line}"
}

function Clear-Logline {
    $script:logLine = ""
}

function Log {
    param(
        [string]$LogLine,
        [switch]$Inline
    )
    $logOut = if ($LogLine -eq "" -or $null -eq $LogLine) {
        $script:logLine
        Clear-Logline
    } else {
        $LogLine
    }

    if ($LogToScreen) {
        Write-Host $logOut
    }

    if ($Inline) {
        Add-Content -Path "$PSScriptRoot\LOG.log" -Value $logOut -NoNewline
    } else {
        Add-Content -Path "$PSScriptRoot\LOG.log" -Value $logOut
    }
}

function Get-Input {
    $inputFile = $(if(-not $Full) { "test_" } else { "" }) + "input.txt"
    $content = Get-Content -Path "$PSScriptRoot\$inputFile"
    return $content
}

#############################
## Task-Specific Functions ##
#############################

function Get-MatchingSectorKey {
    param(
        [int]$Length,
        [int]$Index
    )
    $sectorKey = $emptySectors.Keys | Where-Object { $emptySectors[$_].emptySpace -ge $Length } | Sort-Object | Select-Object -First 1

    if ($null -eq $sectorKey) {
        Log "-----------------------------------"
        Log "Mapping empty sectors from ${script:lastMapedSector} to ${Index}."
        for ([int]$key = ($script:lastMapedSector + 2); $key -lt $Index; $key += 2) {
            Add-ToLogline "${key}|"
            $emptySectors.Add($key, [PSCustomObject]@{
                totalSpace = [int][string]$row[$key]
                emptySpace = [int][string]$row[$key]
            })
            $emptySectors[$key] | Add-Member -MemberType ScriptMethod -Name innerIndex -Value $innerIndex
            if ($emptySectors[$key].emptySpace -ge $Length) {
                $sectorKey = $key
                break
            }
        }
        $script:lastMapedSector = $key
        Log
        Log "----------------------------------"
    }
    return $sectorKey
}

function Get-Position {
    param(
        [int]$Index
    )
    if (-not $positions.ContainsKey($Index)) {
        Log "----------------------------------"
        Log "Mapping pos from ${lastMappedKey} to ${Index}"
        for ($j = ($script:lastMappedKey + 1); $j -le $Index; $j++) {
            $positions[$j] = $positions[($j - 1)] + [int][string]$row[($j - 1)]
        }
        Log "----------------------------------"
        $script:lastMappedKey = $Index 
    }
    return $positions[$Index]
}

$innerIndex = {
    return ($this.totalSpace - $this.emptySpace)
}

#################
## Main Script ##
#################

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Initiate
$script:puzle = Get-Input

# id    # 0     1     2     3     4     5     6     7     8     9
# pos   # 0  2  5  8  11 12 15 18 19 21 22 26 27 31 32 35 36 40 40
# input # 2  3  3  3  1  3  3  1  2  1  4  1  4  1  3  1  4  0  2
# index # 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18

$row = $script:puzle # Shortcut for easy referencing
$endOfRow = $row.Length
Log "Input length = ${endOfRow}"
Log "======================================================================================="
$emptySectors = @{} 

# Preload first empty sector
$emptySectors.Add(1, [PSCustomObject]@{
    totalSpace = [int][string]$row[1]
    emptySpace = [int][string]$row[1]
})
$emptySectors[1] | Add-Member -MemberType ScriptMethod -Name innerIndex -Value $innerIndex
$script:lastMapedSector = 1 

$positions = @{}

# Preload first position
$positions.Add(1, [int][string]$row[0])
$script:lastMappedKey = 1 

$checkSums = 0

for ([int]$i = ($endOfRow - 1); $i -gt 0; $i--) {
    Write-Progress -Activity "Defragmentation in process" -Status "Defrag at index ${i}" -PercentComplete ((($endOfRow - $i) / $endOfRow) * 100)

    # If file
    if (($i % 2) -eq 0) {
        $fileId = $i / 2
        $fileLength = [int][string]$row[$i]
        Log "File length: $($row[$i]), at ${i}, id ${fileId}"

        # Find empty sector that fits
        $msKey = Get-MatchingSectorKey -Length $fileLength -Index $i
        $pos = 0

        if ($null -ne $msKey) {
            Log "Empty sector found at ${msKey}, inner index: $($emptySectors[$msKey].innerIndex()), empty space: $($emptySectors[$msKey].emptySpace), total space: $($emptySectors[$msKey].totalSpace)"
            $pos = Get-Position -Index $msKey
            Log "Position at ${msKey}: ${pos}"
            $pos = $pos + $emptySectors[$msKey].innerIndex()
            if($emptySectors[$msKey].emptySpace -eq $fileLength){
                $emptySectors.Remove($msKey)
            }else{
                $emptySectors[$msKey].emptySpace -= $fileLength
            }
        } else {
            Log "No empty sector found."
            $pos = Get-Position -Index $i
            Log "Position at ${i}: ${pos}"
        }

        for ($ii = 0; $ii -lt $fileLength; $ii++) {
            $checkSum = $fileId * ($pos + $ii)
            Log "Checksum: ${fileId} * $(($pos + $ii)) = ${checkSum}"
            Add-ToLogline "${checkSums} + ${checkSum} = "
            $checkSums += $checkSum
            Add-ToLogline "${checkSums}" 
            Log
        }
        Log "======================================================================================="
    }
}

Write-Host "Result: ${checkSums}"
Write-Host "Runtime: $($stopwatch.Elapsed.TotalMinutes) minutes."

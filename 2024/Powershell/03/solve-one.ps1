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
    $script:logLine = $script:logLine + "${line} | "
}

function log($logLine){
    if($LogToScreen){
        Write-Host "${logLine} `n"
    }
    Add-Content -Path "$PSScriptRoot\LOG.log" -Value $logLine
}
function get-input(){
    $inputFile = $(if( -not $full){"test_"}) + "input.txt"
    $content = Get-Content -Path $PSScriptRoot\$inputFile
    return $content
}

#############################
## Task specific functions ##
#############################
function run-row($row){
    log $row
    # Start measuring time
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Define the regex pattern
    $regex = "mul\((\d{1,3}),(\d{1,3})\)"

    # Initialize a hashtable to store calculations, results, and occurrences
    $script:resultsTable = @{}

    # Initialize a variable to sum up the results
    $totalSum = 0

    # Find all matches
    $matches = [regex]::Matches($row, $regex)

    # Loop through each match and process it
    foreach ($match in $matches) {
        # Extract the two digit groups
        $calcKey = $match.Value
        $num1 = [int]$match.Groups[1].Value
        $num2 = [int]$match.Groups[2].Value
        
        # Check if the calculation already exists in the hashtable
        if ($script:resultsTable.ContainsKey($calcKey)) {
            # If it exists, increment the occurrence count
            $script:resultsTable[$calcKey].Occurrences += 1
            $product = $script:resultsTable[$calcKey].Result
        } else {
            # If it doesn't exist, calculate the result, store it, and set occurrences to 1
            $product = $num1 * $num2
            $script:resultsTable[$calcKey] = [PSCustomObject]@{
                Result = $product
                Occurrences = 1
            }
        }
        log "${calcKey} = ${product}"
        # Add the result to the total sum
            $totalSum = $totalSum + $product
    }

    # Stop the timer
    $stopwatch.Stop()

    log "Total Sum of Unique Results: $totalSum"
    log "Script Execution Time: $($stopwatch.Elapsed.TotalMilliseconds) ms"
    return $totalSum

}

#################
## Main script ##
#################
initiate
$result = 0
$puzle = get-input
$rows = $puzle.Count
$rowCount = 0
$puzle | ForEach-Object{
    $rowCount++
    Write-Progress -Activity "Currupted Memmory" -Status "Row ${rowCount} of ${rows}"
    $rowResult = run-row $_
    $result = $result + $rowResult
    $script:logLine = ""
}
foreach ($key in $script:resultsTable.Keys) {
    $entry = $resultsTable[$key]
    log "${key}: Result = $($entry.Result), Occurrences = $($entry.Occurrences)"
}
## Magic is done ##
Write-Host "Result: ${result}"


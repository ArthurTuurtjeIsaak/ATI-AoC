﻿$puzzleInput = @'
.............4....O..........w....R...............
.................................f................
..............4...j......NW0......................
....................R..W..........................
...............R..................................
..................................................
v.......................f.......0W................
.....9L............l...N.........w................
....L....9.......ON........8......................
.1.........49L........f..0..N.....................
..........................V...l...................
..........4.......................................
.....................j...................3.....U..
....O.....U.......................................
........J......................l..................
.O....s.Q.......j.....l.....w..........F...q......
..................................................
.U.......................j..8.....................
................U...............................3.
2.............................J............3......
..............................F...................
.....s...R...........J..................F.........
.s......................x..........F.....q........
.......2.....Q........3........x..................
...........v......................u...............
..............v...........n......8............q...
.......f..................8........i..............
.5..................1n..............P.....i.......
............7............Q..................X.....
......5...p....................V..................
.................J..........nx............q.......
.......p............W...........................0.
......2.............p.5.....1....P................
......I.................7.X....i...P..............
............s.....r...w................V..........
...............or...6.................V...........
............................PS.7..................
..........o...........................S...........
...........5..............o..1.......n............
...........I.........r.......7.......6............
.................o.r...........X..................
................................x.........u.......
.........p..Q....2................................
.........v.................S.....................u
I...........................S.....6...............
..................................................
.......I..........................................
..................................................
.......................................6..........
.................................X................
'@

$lines = $puzzleInput.Split("`n").Trim()

$map = [System.Collections.ArrayList]@()
$symbols = @()
$antiNodes = @()
$occupied = @()

for ($h=0;$h-lt$lines.Count;$h++) {
    for ($i=0;$i-lt$lines[$h].Length;$i++) {
        # check for any symbol that's not a period marker
        if ($lines[$h][$i] -notmatch '\.') {
            # check if the symbol found is new
            if ($lines[$h][$i] -cin $symbols) {
                # Powershell has no case-sensitive version of notin, so we need to use the else here
            }
            else {
                # add symbol to array of used symbols
                $symbols += $lines[$h][$i]
            }
            # add symbol and coords to arraylist which we use to map coords to the symbols
            # null to avoid unnecessary output
            $null = $map.Add(@{"$($lines[$h][$i])" = "$($i),$($h)"})
        }
    }
}

# loop through symbols
foreach ($symbol in $symbols) {
    # loop through coordinates and handle them separately
    foreach ($coord in ($map | Where-Object {$_.Keys -cmatch $symbol})) {
        [int]$sourceX,[int]$sourceY = $coord.Values.Split(",")
        # loop through coords again to compare one coord with the rest
        foreach ($comparecoord in ($map | Where-Object {$_.Keys -cmatch $symbol})) {
            if ($coord.Values -eq $comparecoord.Values) {
                # skip the coord we're comparing
                Continue
            }
            else {
                [int]$compareX,[int]$compareY = $comparecoord.Values.Split(",")
                $xDiff = $sourceX - $compareX
                $yDiff = $sourceY - $compareY

                # all node pairs are assessed twice, which is very convenient as this allows us to check in both directions easily
                $antiX = $sourceX + $xDiff
                $antiY = $sourceY + $yDiff

                # only include antinodes that fall on the map and are unique
                while ($antiX -ge 0 -and $antiY -ge 0 -and $antiX -lt $lines[0].Length -and $antiY -lt $lines.Count) {
                    $antiNode = "$antiX,$antiY"
                    if ($antiNode -notin $antiNodes) {
                        $antiNodes += $antiNode
                    }
                    $antiX = $antiX + $xDiff
                    $antiY = $antiY + $yDiff
                }
            }
        }
    }
}

# draw map
$newmap = @()
for ($h=0;$h-lt$lines.Count;$h++) {
    $line = ""
    for ($i=0;$i-lt$lines[$h].Length;$i++) {
        if ("$i,$h" -in $antiNodes) {
            $line += "#"
        }
        elseif ("$i,$h" -in $map.Values) {
            $line += ($map | Where-Object {$_.Values -eq "$i,$h"}).Keys
        }
        else {
            $line += "."
        }
    }
    $newmap += $line
}

$antiNodes.Count

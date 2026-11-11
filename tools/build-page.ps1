<#
  Builds the whole profile page (assets/*.svg) from one layout, one theme and one pixel font.

  Run:  powershell -ExecutionPolicy Bypass -File tools/build-page.ps1

  Output
    assets/page-top.svg        typing banner (with top margin under the GIF)
    assets/btn-linkedin.svg    clickable button (wrapped in <a> in README.md)
    assets/btn-github.svg      clickable button (wrapped in <a> in README.md)
    assets/page-body.svg       about / tech stack / currently / random thought
    assets/icons/*.svg         standalone skill icons

  GitHub renders SVGs as plain images, so links inside an SVG are not clickable.
  The page is therefore cut at the button row: top -> buttons -> body.
#>
param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$ci = [Globalization.CultureInfo]::InvariantCulture
function N($v) { ([double]$v).ToString('0.####', $ci) }
$assets = Join-Path $Root 'assets'
New-Item -ItemType Directory -Force (Join-Path $assets 'icons') | Out-Null

function Save($rel, $content) {
  $path = Join-Path $assets $rel
  [IO.File]::WriteAllText($path, $content, (New-Object Text.UTF8Encoding $false))
  [xml](Get-Content $path -Raw -Encoding UTF8) | Out-Null
  '{0,-26} {1,8:N0} bytes' -f $rel, (Get-Item $path).Length
}

# ============================== THEME (sampled from the hero GIF) ==============================
$T = @{
  bg = '#190A48'; deep = '#0F0932'; night = '#000529'
  line = '#7B07FF'; line2 = '#2F07D1'
  pink = '#FF3AA4'; pinkDark = '#A81775'; magenta = '#D126FF'
  cyan = '#7CF8FF'; blue = '#0AD5FF'; ink = '#EAF0FF'
}
$W = 800          # page width in px (images are shown at this width)
$M = 16           # page margin: the page surface shows around the cards
$PAD = 28         # inner padding of cards (text starts at $M + $PAD)
$GAP = 24         # vertical gap between cards
$scan = '<pattern id="scan" width="4" height="4" patternUnits="userSpaceOnUse"><rect width="4" height="2" fill="#000529" opacity="0.45"/></pattern>'

# ============================== PIXEL FONT (5 wide, 9 tall cell) ==============================
# spec = 'firstRow|row,row,...'  ('1' or '#' = pixel on). Rows 0-6 are cap height, 7-8 descenders.
$F = [System.Collections.Hashtable]::new()   # case-sensitive: 'a' and 'A' are different glyphs
$up = [ordered]@{
  A = '01110,10001,10001,11111,10001,10001,10001'; B = '11110,10001,10001,11110,10001,10001,11110'
  C = '01110,10001,10000,10000,10000,10001,01110'; D = '11110,10001,10001,10001,10001,10001,11110'
  E = '11111,10000,10000,11110,10000,10000,11111'; F = '11111,10000,10000,11110,10000,10000,10000'
  G = '01110,10001,10000,10111,10001,10001,01111'; H = '10001,10001,10001,11111,10001,10001,10001'
  I = '01110,00100,00100,00100,00100,00100,01110'; J = '00111,00010,00010,00010,00010,10010,01100'
  K = '10001,10010,10100,11000,10100,10010,10001'; L = '10000,10000,10000,10000,10000,10000,11111'
  M = '10001,11011,10101,10101,10001,10001,10001'; N = '10001,11001,10101,10011,10001,10001,10001'
  O = '01110,10001,10001,10001,10001,10001,01110'; P = '11110,10001,10001,11110,10000,10000,10000'
  Q = '01110,10001,10001,10001,10101,10010,01101'; R = '11110,10001,10001,11110,10100,10010,10001'
  S = '01111,10000,10000,01110,00001,00001,11110'; T = '11111,00100,00100,00100,00100,00100,00100'
  U = '10001,10001,10001,10001,10001,10001,01110'; V = '10001,10001,10001,10001,10001,01010,00100'
  W = '10001,10001,10001,10101,10101,11011,10001'; X = '10001,10001,01010,00100,01010,10001,10001'
  Y = '10001,10001,01010,00100,00100,00100,00100'; Z = '11111,00001,00010,00100,01000,10000,11111'
}
foreach ($k in $up.Keys) { $F[$k] = '0|' + $up[$k] }
$low = [ordered]@{
  a = '2|.###.,....#,.####,#...#,.####'
  b = '0|#....,#....,####.,#...#,#...#,#...#,####.'
  c = '2|.###.,#...#,#....,#...#,.###.'
  d = '0|....#,....#,.####,#...#,#...#,#...#,.####'
  e = '2|.###.,#...#,#####,#....,.###.'
  f = '0|..##.,.#...,####.,.#...,.#...,.#...,.#...'
  g = '2|.####,#...#,#...#,.####,....#,#...#,.###.'
  h = '0|#....,#....,####.,#...#,#...#,#...#,#...#'
  i = '0|..#..,.....,.##..,..#..,..#..,..#..,.###.'
  j = '0|...#.,.....,..##.,...#.,...#.,...#.,...#.,#..#.,.##..'
  k = '0|#....,#....,#..#.,#.#..,##...,#.#..,#..#.'
  l = '0|.##..,..#..,..#..,..#..,..#..,..#..,.###.'
  m = '2|##.#.,#.#.#,#.#.#,#.#.#,#.#.#'
  n = '2|####.,#...#,#...#,#...#,#...#'
  o = '2|.###.,#...#,#...#,#...#,.###.'
  p = '2|####.,#...#,#...#,####.,#....,#....,#....'
  q = '2|.####,#...#,#...#,.####,....#,....#,....#'
  r = '2|#.##.,##..#,#....,#....,#....'
  s = '2|.####,#....,.###.,....#,####.'
  t = '1|.#...,####.,.#...,.#...,.#...,..##.'
  u = '2|#...#,#...#,#...#,#..##,.##.#'
  v = '2|#...#,#...#,#...#,.#.#.,..#..'
  w = '2|#...#,#...#,#.#.#,#.#.#,.#.#.'
  x = '2|#...#,.#.#.,..#..,.#.#.,#...#'
  y = '2|#...#,#...#,.#.#.,..#..,..#..,.#...,#....'
  z = '2|#####,...#.,..#..,.#...,#####'
}
foreach ($k in $low.Keys) { $F[$k] = $low[$k] }
$F[' '] = '0|.....'
$F[','] = '5|..##.,..#..,.#...'
$F['.'] = '5|.##..,.##..'
$F["'"] = '0|..#..,..#..,.#...'
$F['('] = '0|...#.,..#..,.#...,.#...,.#...,..#..,...#.'
$F[')'] = '0|.#...,..#..,...#.,...#.,...#.,..#..,.#...'
$F['-'] = '4|.###.'
$F['/'] = '0|....#,....#,...#.,..#..,.#...,#....,#....'
$F['\'] = '0|#....,#....,.#...,..#..,...#.,....#,....#'
$F['_'] = '8|#####'
$F['>'] = '0|.#...,..#..,...#.,....#,...#.,..#..,.#...'
$F['@'] = '0|.###.,#...#,#.###,#.#.#,#.###,#....,.####'

function Seg($t, $c) { @{ t = $t; c = $c } }
function TW($segs, $s) { $n = 0; foreach ($g in $segs) { $n += $g.t.Length }; $n * 6 * $s - $s }

# draws colored text; returns <path> markup
function Txt($x, $y, $s, $segs, $shadow) {
  $by = [ordered]@{}
  $sh = New-Object Text.StringBuilder
  $so = [Math]::Max(2, [int][Math]::Round($s * 0.7))
  $cx = $x
  foreach ($seg in $segs) {
    $col = $seg.c
    if (-not $by.Contains($col)) { $by[$col] = New-Object Text.StringBuilder }
    foreach ($chr in $seg.t.ToCharArray()) {
      $spec = $F[[string]$chr]
      if (-not $spec) { throw "No glyph for '$chr'" }
      $p = $spec.Split('|'); $start = [int]$p[0]; $rows = $p[1].Split(',')
      for ($r = 0; $r -lt $rows.Count; $r++) {
        $row = $rows[$r]; $yy = $y + ($start + $r) * $s; $c = 0
        while ($c -lt 5) {
          if ($row[$c] -eq '1' -or $row[$c] -eq '#') {
            $st = $c
            while ($c -lt 5 -and ($row[$c] -eq '1' -or $row[$c] -eq '#')) { $c++ }
            $w = ($c - $st) * $s
            [void]$by[$col].Append("M$(N ($cx + $st * $s)) $(N $yy)h$(N $w)v$(N $s)h-$(N $w)z")
            if ($shadow) { [void]$sh.Append("M$(N ($cx + $st * $s + $so)) $(N ($yy + $so))h$(N $w)v$(N $s)h-$(N $w)z") }
          } else { $c++ }
        }
      }
      $cx += 6 * $s
    }
  }
  $out = New-Object Text.StringBuilder
  if ($shadow -and $sh.Length) { [void]$out.AppendLine("  <path d=""$($sh.ToString())"" fill=""$($T.pinkDark)""/>") }
  foreach ($k in $by.Keys) { [void]$out.AppendLine("  <path d=""$($by[$k].ToString())"" fill=""$k""/>") }
  $out.ToString()
}

# rectangle with stepped (pixel) corners
function Poly($x0, $y0, $x1, $y1, $n) {
  $pts = @(
    @(($x0 + $n), $y0), @(($x1 - $n), $y0), @(($x1 - $n), ($y0 + $n)), @($x1, ($y0 + $n)),
    @($x1, ($y1 - $n)), @(($x1 - $n), ($y1 - $n)), @(($x1 - $n), $y1), @(($x0 + $n), $y1),
    @(($x0 + $n), ($y1 - $n)), @($x0, ($y1 - $n)), @($x0, ($y0 + $n)), @(($x0 + $n), ($y0 + $n))
  )
  ($pts | ForEach-Object { "$(N ($_[0])),$(N ($_[1]))" }) -join ' '
}

# ============================== PIXEL ICONS (16x16 grids) ==============================
$pal = @{ C = '#7CF8FF'; P = '#FF3AA4'; B = '#0AD5FF'; M = '#D126FF'; V = '#7B07FF'; D = '#000529'; W = '#FFFFFF' }

function NewGrid { 1..16 | ForEach-Object { , (('.' * 16).ToCharArray()) } }
function Put($g, $x, $y, $ch) { if ($x -ge 0 -and $x -lt 16 -and $y -ge 0 -and $y -lt 16) { $g[$y][$x] = [char]$ch } }
function FillRect($g, $x, $y, $w, $h, $ch) { for ($yy = $y; $yy -lt $y + $h; $yy++) { for ($xx = $x; $xx -lt $x + $w; $xx++) { Put $g $xx $yy $ch } } }
function DrawLine($g, $x0, $y0, $x1, $y1, $ch) {
  $dx = [Math]::Abs($x1 - $x0); $dy = -[Math]::Abs($y1 - $y0)
  $sx = if ($x0 -lt $x1) { 1 } else { -1 }; $sy = if ($y0 -lt $y1) { 1 } else { -1 }
  $err = $dx + $dy
  while ($true) {
    Put $g $x0 $y0 $ch
    if ($x0 -eq $x1 -and $y0 -eq $y1) { break }
    $e2 = 2 * $err
    if ($e2 -ge $dy) { $err += $dy; $x0 += $sx }
    if ($e2 -le $dx) { $err += $dx; $y0 += $sy }
  }
}
function Glyph($g, $chr, $x, $y, $ch) {
  $rows = $F[[string]$chr].Split('|')[1].Split(',')
  for ($r = 0; $r -lt 7; $r++) { for ($c = 0; $c -lt 5; $c++) { if ($rows[$r][$c] -eq '1') { Put $g ($x + $c) ($y + $r) $ch } } }
}
function Sparse($map) {
  $g = NewGrid
  foreach ($k in $map.Keys) {
    $s = $map[$k]
    if ($s.Length -ne 16) { throw "icon row $k has length $($s.Length): '$s'" }
    $g[[int]$k] = $s.ToCharArray()
  }
  , $g
}
function GridPaths($g, $ox, $oy, $s) {
  $sb = New-Object Text.StringBuilder
  $d = New-Object Text.StringBuilder
  for ($y = 0; $y -lt 16; $y++) {
    $x = 0
    while ($x -lt 16) {
      $ch = $g[$y][$x]
      if ($ch -ne '.' -and $ch -ne 'D') {
        $st = $x
        while ($x -lt 16 -and $g[$y][$x] -ne '.' -and $g[$y][$x] -ne 'D') { $x++ }
        [void]$d.Append("M$(N ($ox + ($st + 1) * $s)) $(N ($oy + ($y + 1) * $s))h$(N (($x - $st) * $s))v$(N $s)h-$(N (($x - $st) * $s))z")
      } else { $x++ }
    }
  }
  [void]$sb.AppendLine("    <path d=""$($d.ToString())"" fill=""$($T.pinkDark)""/>")
  $by = @{}
  for ($y = 0; $y -lt 16; $y++) {
    $x = 0
    while ($x -lt 16) {
      $ch = [string]$g[$y][$x]
      if ($ch -ne '.') {
        $st = $x
        while ($x -lt 16 -and [string]$g[$y][$x] -eq $ch) { $x++ }
        if (-not $by.ContainsKey($ch)) { $by[$ch] = New-Object Text.StringBuilder }
        [void]$by[$ch].Append("M$(N ($ox + $st * $s)) $(N ($oy + $y * $s))h$(N (($x - $st) * $s))v$(N $s)h-$(N (($x - $st) * $s))z")
      } else { $x++ }
    }
  }
  foreach ($ch in 'V', 'M', 'B', 'C', 'P', 'W', 'D') {
    if ($by.ContainsKey($ch)) { [void]$sb.AppendLine("    <path d=""$($by[$ch].ToString())"" fill=""$($pal[$ch])""/>") }
  }
  $sb.ToString()
}

$icons = [ordered]@{}
$icons['html'] = @{ label = 'HTML'; grid = (Sparse @{
  3 = '.........PP.....'; 4 = '....CC...PPCC...'; 5 = '...CC...PP..CC..'; 6 = '..CC....PP...CC.'
  7 = '.CC....PP.....CC'; 8 = '.CC....PP.....CC'; 9 = '..CC..PP.....CC.'; 10 = '...CC.PP....CC..'
  11 = '....CPP....CC...'; 12 = '.....PP.........' }) }
$icons['css'] = @{ label = 'CSS'; grid = (Sparse @{
  2 = '.....CC..CC.....'; 3 = '.....C....C.....'; 4 = '.....C....C.....'; 5 = '.....C....C.....'
  6 = '....C......C....'; 7 = '...CC..PP..CC...'; 8 = '...CC..PP..CC...'; 9 = '....C......C....'
  10 = '.....C....C.....'; 11 = '.....C....C.....'; 12 = '.....C....C.....'; 13 = '.....CC..CC.....' }) }
$g = NewGrid; FillRect $g 1 1 14 14 'P'
foreach ($c in @(@(1, 1), @(14, 1), @(1, 14), @(14, 14))) { Put $g $c[0] $c[1] '.' }
Glyph $g 'J' 2 4 'D'; Glyph $g 'S' 8 4 'D'
$icons['javascript'] = @{ label = 'JAVASCRIPT'; grid = $g }
$g = NewGrid; FillRect $g 1 1 14 14 'B'
foreach ($c in @(@(1, 1), @(14, 1), @(1, 14), @(14, 14))) { Put $g $c[0] $c[1] '.' }
Glyph $g 'T' 2 4 'D'; Glyph $g 'S' 8 4 'D'
$icons['typescript'] = @{ label = 'TYPESCRIPT'; grid = $g }
$g = NewGrid
foreach ($deg in 0, 60, 120) {
  $a = $deg * [Math]::PI / 180
  for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) {
    $dx = $x - 7.5; $dy = $y - 7.5
    $xr = $dx * [Math]::Cos($a) + $dy * [Math]::Sin($a)
    $yr = -$dx * [Math]::Sin($a) + $dy * [Math]::Cos($a)
    $v = [Math]::Pow($xr / 7.4, 2) + [Math]::Pow($yr / 2.9, 2)
    if ([Math]::Abs($v - 1) -lt 0.42) { Put $g $x $y 'C' }
  } }
}
FillRect $g 7 7 2 2 'P'
$icons['react'] = @{ label = 'REACT'; grid = $g }
$g = NewGrid
$hex = @(@(7, 0, 8, 0), @(8, 0, 14, 4), @(14, 4, 14, 11), @(14, 11, 8, 15), @(8, 15, 7, 15), @(7, 15, 1, 11), @(1, 11, 1, 4), @(1, 4, 7, 0))
foreach ($l in $hex) { DrawLine $g $l[0] $l[1] $l[2] $l[3] 'M' }
foreach ($l in $hex) { DrawLine $g ($l[0] + $(if ($l[0] -gt 7) { -1 } else { 1 })) $l[1] ($l[2] + $(if ($l[2] -gt 7) { -1 } else { 1 })) $l[3] 'M' }
Glyph $g 'N' 5 4 'C'
$icons['nodejs'] = @{ label = 'NODE.JS'; grid = $g }
$icons['express'] = @{ label = 'EXPRESS'; grid = (Sparse @{
  2 = '.CCCCCCCCCCCCCC.'; 3 = '.C............C.'; 4 = '.C.PP...BBBBB.C.'; 5 = '.C............C.'; 6 = '.CCCCCCCCCCCCCC.'
  7 = '.......PP.......'; 8 = '.......PP.......'
  9 = '.CCCCCCCCCCCCCC.'; 10 = '.C............C.'; 11 = '.C.MM...BBBBB.C.'; 12 = '.C............C.'; 13 = '.CCCCCCCCCCCCCC.' }) }
$g = NewGrid
foreach ($wave in @(@(4, 0.0, 'C'), @(10, 0.0, 'B'))) {
  for ($x = 0; $x -lt 16; $x++) {
    $yy = [int][Math]::Round($wave[0] + 1.7 * [Math]::Sin($x * 2 * [Math]::PI / 10 + $wave[1]))
    Put $g $x $yy $wave[2]; Put $g $x ($yy + 1) $wave[2]
  }
}
$icons['tailwind'] = @{ label = 'TAILWIND'; grid = $g }
$icons['python'] = @{ label = 'PYTHON'; grid = (Sparse @{
  1 = '...CCCCCC.......'; 2 = '..CCDCCCCC......'; 3 = '..CCCCCCCC......'; 4 = '..CCCCCCCC.PPPP.'
  5 = '..CCCCCCCC.PPPP.'; 6 = '..CCCCCCCC.PPPP.'; 7 = '..CCCC.PPPPPPPP.'; 8 = '..CCCC.PPPPPPPP.'
  9 = '..CCCC.PPPPPPPP.'; 10 = '..CCCC.PPPPPPPP.'; 11 = '..CCCC.PPPPPDPP.'; 12 = '...CCCCPPPPPPP..'
  13 = '.....CCCPPPPPP..' }) }
$g = NewGrid
FillRect $g 3 5 2 6 'C'
DrawLine $g 5 9 10 7 'C'; DrawLine $g 5 10 10 8 'C'
foreach ($n in @(@(2, 1, 'P'), @(2, 11, 'P'), @(10, 5, 'M'))) {
  FillRect $g $n[0] $n[1] 4 4 $n[2]
  foreach ($c in @(@(0, 0), @(3, 0), @(0, 3), @(3, 3))) { Put $g ($n[0] + $c[0]) ($n[1] + $c[1]) '.' }
}
$icons['git'] = @{ label = 'GIT'; grid = $g }
$icons['github'] = @{ label = 'GITHUB'; grid = (Sparse @{
  1 = '...CC......CC...'; 2 = '..CCCC....CCCC..'; 3 = '..CCCCCCCCCCCC..'; 4 = '.CCCCCCCCCCCCCC.'
  5 = '.CCCCCCCCCCCCCC.'; 6 = '.CCCDDCCCCDDCCC.'; 7 = '.CCCDDCCCCDDCCC.'; 8 = '.CCCCCCCCCCCCCC.'
  9 = '..CCCCCPPCCCCC..'; 10 = '..CCCCCCCCCCCC..'; 11 = '...CCCCCCCCCC...'
  12 = '...CC.CC.CC.CC..'; 13 = '...C..C...C..C..' }) }
# the GitHub cat is magenta so it reads differently from the cyan Git graph
$githubGrid = $icons['github'].grid
for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) { if ($githubGrid[$y][$x] -eq 'C') { $githubGrid[$y][$x] = 'M' } } }

foreach ($k in $icons.Keys) {
  $ic = $icons[$k]
  $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" viewBox="0 0 160 160" shape-rendering="crispEdges" role="img" aria-label="$($ic.label)">
  <title>$($ic.label)</title>
  <g>
$(GridPaths $ic.grid 16 16 8)  </g>
</svg>
"@
  Save "icons/$k.svg" $svg | Out-Null
}

# ============================== PAGE SURFACE ==============================
# Every image is full-bleed on this colour, so stacked images read as one continuous page.
function Surface($h) { "  <rect width=""$W"" height=""$h"" fill=""$($T.deep)""/>`n" }

# ============================== TOP: typing banner ==============================
$lines = @("hey, i'm udit", 'i build for the web', 'ship fast, fix later', 'touch grass (soon)')
$S = 5; $cell = 6 * $S; $dur = 16
$topPad = 24; $bannerH = 104; $botPad = 16
$H1 = $topPad + $bannerH + $botPad
$textY = $topPad + [int](($bannerH - 7 * $S) / 2)
$clips = New-Object Text.StringBuilder
$body = New-Object Text.StringBuilder
for ($k = 0; $k -lt $lines.Count; $k++) {
  $text = $lines[$k]; $n = $text.Length
  $x0 = [int](($W - (TW @((Seg $text $T.cyan)) $S)) / 2)
  $s0 = $k / $lines.Count; $e0 = ($k + 1) / $lines.Count; $step = 0.15 / $n
  $times = New-Object Collections.Generic.List[string]
  $wid = New-Object Collections.Generic.List[string]
  $cxs = New-Object Collections.Generic.List[string]
  $times.Add('0'); $wid.Add('0'); $cxs.Add((N $x0))
  if ($s0 -gt 0) { $times.Add((N $s0)); $wid.Add('0'); $cxs.Add((N $x0)) }
  for ($j = 1; $j -le $n; $j++) {
    $times.Add((N ($s0 + $j * $step))); $wid.Add((N ($j * $cell))); $cxs.Add((N ($x0 + $j * $cell)))
  }
  if ($e0 -lt 1) {
    $times.Add((N $e0)); $wid.Add('0'); $cxs.Add((N $x0))
    $times.Add('1'); $wid.Add('0'); $cxs.Add((N $x0))
  } else {
    $times.Add('1'); $wid.Add((N ($n * $cell))); $cxs.Add((N ($x0 + $n * $cell)))
  }
  $kt = $times -join ';'
  [void]$clips.AppendLine("    <clipPath id=""clip$k""><rect x=""$x0"" y=""0"" width=""0"" height=""$H1""><animate attributeName=""width"" calcMode=""discrete"" values=""$($wid -join ';')"" keyTimes=""$kt"" dur=""${dur}s"" repeatCount=""indefinite""/></rect></clipPath>")
  if ($k -eq 0) { $ov = '1;0;0'; $ok = "0;$(N $e0);1" }
  elseif ($e0 -lt 1) { $ov = '0;1;0;0'; $ok = "0;$(N $s0);$(N $e0);1" }
  else { $ov = '0;1;1'; $ok = "0;$(N $s0);1" }
  [void]$body.AppendLine('  <g opacity="0">')
  [void]$body.AppendLine("    <animate attributeName=""opacity"" calcMode=""discrete"" values=""$ov"" keyTimes=""$ok"" dur=""${dur}s"" repeatCount=""indefinite""/>")
  [void]$body.AppendLine("    <g clip-path=""url(#clip$k)"">")
  [void]$body.Append((Txt $x0 $textY $S @((Seg $text $T.cyan)) $true))
  [void]$body.AppendLine('    </g>')
  [void]$body.AppendLine("    <rect x=""$x0"" y=""$textY"" width=""$(3 * $S)"" height=""$(7 * $S)"" fill=""$($T.pink)""><animate attributeName=""x"" calcMode=""discrete"" values=""$($cxs -join ';')"" keyTimes=""$kt"" dur=""${dur}s"" repeatCount=""indefinite""/><animate attributeName=""opacity"" calcMode=""discrete"" values=""1;0;1"" keyTimes=""0;0.5;1"" dur=""0.6s"" repeatCount=""indefinite""/></rect>")
  [void]$body.AppendLine('  </g>')
}
$pts = Poly ($M + 2) ($topPad + 2) ($W - $M - 2) ($topPad + $bannerH - 2) 8
$svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="$W" height="$H1" viewBox="0 0 $W $H1" shape-rendering="crispEdges" role="img" aria-label="Typing animation: hey, i'm udit. i build for the web. ship fast, fix later. touch grass (soon).">
  <title>hey, i'm udit</title>
  <defs>$scan
$($clips.ToString())  </defs>
$(Surface $H1)  <polygon points="$pts" fill="$($T.bg)" stroke="$($T.line2)" stroke-width="4"/>
  <polygon points="$pts" fill="url(#scan)"/>
$($body.ToString())</svg>
"@
Save 'page-top.svg' $svg

# ============================== LINK BARS (each is one clickable image) ==============================
# LinkedIn "in" badge, 16x16
$liGrid = Sparse @{
  1 = '.CCCCCCCCCCCCCC.'; 2 = '.CCCCCCCCCCCCCC.'; 3 = '.CCDDCCCCCCCCCC.'; 4 = '.CCDDCCCCCCCCCC.'; 5 = '.CCCCCCCCCCCCCC.'
  6 = '.CCDDCCDDDDDDCC.'; 7 = '.CCDDCCDDDDDDCC.'; 8 = '.CCDDCCDDCCDDCC.'; 9 = '.CCDDCCDDCCDDCC.'
  10 = '.CCDDCCDDCCDDCC.'; 11 = '.CCDDCCDDCCDDCC.'; 12 = '.CCDDCCDDCCDDCC.'; 13 = '.CCCCCCCCCCCCCC.'; 14 = '.CCCCCCCCCCCCCC.' }

function LinkBar($file, $label, $handle, $accent, $grid) {
  $ch = 44; $h = 52
  $pts = Poly ($M + 2) 2 ($W - $M - 2) ($ch - 2) 6
  $hs = @((Seg $handle $T.ink))
  $labelX = $M + 16 + 32 + 14
  $arrowX = $W - $M - 16 - 15
  $handleX = $arrowX - 12 - (TW $hs 3)
  $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="$W" height="$h" viewBox="0 0 $W $h" shape-rendering="crispEdges" role="img" aria-label="${label}: $handle">
  <title>${label}: $handle</title>
  <defs>$scan</defs>
$(Surface $h)  <polygon points="$pts" fill="$($T.bg)" stroke="$accent" stroke-width="4"/>
  <polygon points="$pts" fill="url(#scan)"/>
  <g>
$(GridPaths $grid ($M + 16) 6 2)  </g>
$(Txt $labelX 12 3 @((Seg $label $T.cyan)) $true)$(Txt $handleX 12 3 $hs $false)$(Txt $arrowX 12 3 @((Seg '>' $accent)) $false)</svg>
"@
  Save $file $svg
}
LinkBar 'link-linkedin.svg' 'LINKEDIN' 'udit-agrawal' $T.cyan $liGrid
LinkBar 'link-github.svg' 'GITHUB' '@LighTnos' $T.pink $icons['github'].grid

# ============================== BODY: cards ==============================
$titleS = 4; $bodyS = 3
$pitch = 9 * $bodyS + 14
$headH = 92           # card top -> first body line
$footH = 28
function BodyH($n) { ($n - 1) * $pitch + 9 * $bodyS }

function CardFrame($y, $h, $accent, $title) {
  $pts = Poly ($M + 2) ($y + 2) ($W - $M - 2) ($y + $h - 2) 8
  $sb = New-Object Text.StringBuilder
  [void]$sb.AppendLine("  <polygon points=""$pts"" fill=""$($T.bg)"" stroke=""$($T.line)"" stroke-width=""4""/>")
  [void]$sb.AppendLine("  <polygon points=""$pts"" fill=""url(#scan)""/>")
  [void]$sb.Append((Txt ($M + $PAD) ($y + 24) $titleS @((Seg '// ' $accent), (Seg $title $T.cyan)) $true))
  $dx = $W - $M - $PAD - 46
  [void]$sb.AppendLine("  <rect x=""$dx"" y=""$($y + 33)"" width=""10"" height=""10"" fill=""$($T.pink)""/><rect x=""$($dx + 18)"" y=""$($y + 33)"" width=""10"" height=""10"" fill=""$($T.magenta)""/><rect x=""$($dx + 36)"" y=""$($y + 33)"" width=""10"" height=""10"" fill=""$($T.cyan)""/>")
  [void]$sb.AppendLine("  <path d=""M$($M + $PAD) $($y + 68)H$($W - $M - $PAD)"" stroke=""$accent"" stroke-width=""4"" stroke-dasharray=""12 8"" opacity=""0.7"" fill=""none""/>")
  $sb.ToString()
}
function TextBlock($y0, $rows) {
  $sb = New-Object Text.StringBuilder
  for ($i = 0; $i -lt $rows.Count; $i++) { [void]$sb.Append((Txt ($M + $PAD) ($y0 + $i * $pitch) $bodyS $rows[$i] $false)) }
  $sb.ToString()
}

$about = @(
  @((Seg "hey, i'm " $T.ink), (Seg 'udit' $T.pink), (Seg '.' $T.ink)),
  @((Seg 'web dev who learns by building' $T.ink)),
  @((Seg 'and breaking things a little.' $T.ink)),
  @((Seg 'if it compiles, it ' $T.ink), (Seg 'ships' $T.cyan), (Seg '.' $T.ink))
)
$now = @(
  @((Seg '> ' $T.pink), (Seg 'leveling up in ' $T.ink), (Seg 'typescript' $T.cyan)),
  @((Seg '> ' $T.magenta), (Seg 'messing around with ' $T.ink), (Seg 'python' $T.cyan)),
  @((Seg '> ' $T.cyan), (Seg 'always building ' $T.ink), (Seg 'new stuff' $T.pink))
)
$thought = @(
  @((Seg 'it works on ' $T.ink), (Seg 'my machine' $T.pink)),
  @((Seg '\_(._.)_/' $T.cyan))
)
foreach ($grp in $about, $now, $thought) {
  foreach ($row in $grp) { if ((TW $row $bodyS) -gt ($W - 2 * $M - 2 * $PAD)) { throw "line too wide: $(($row | ForEach-Object { $_.t }) -join '')" } }
}

# tech stack grid: 6 + 5 icons, borderless, 122px cells
$order = 'html', 'javascript', 'css', 'typescript', 'react', 'tailwind', 'nodejs', 'express', 'python', 'git', 'github'
$cellW = 122; $iconScale = 4; $iconSize = 16 * $iconScale; $rowH = 90; $rowGap = 24
$stackH = 2 * $rowH + $rowGap

$y = 16
$bodySvg = New-Object Text.StringBuilder

# about
$h = $headH + (BodyH $about.Count) + $footH
[void]$bodySvg.Append((CardFrame $y $h $T.pink 'ABOUT ME'))
[void]$bodySvg.Append((TextBlock ($y + $headH) $about))
$y += $h + $GAP

# stack
$h = $headH + $stackH + $footH
[void]$bodySvg.Append((CardFrame $y $h $T.cyan 'TECH STACK'))
$rows = @(@($order[0..5]), @($order[6..10]))
for ($r = 0; $r -lt 2; $r++) {
  $items = $rows[$r]; $startX = [int](($W - $items.Count * $cellW) / 2)
  $ry = $y + $headH + $r * ($rowH + $rowGap)
  for ($i = 0; $i -lt $items.Count; $i++) {
    $ic = $icons[[string]$items[$i]]; $cx0 = $startX + $i * $cellW
    $lab = @((Seg $ic.label $T.cyan)); $lw = TW $lab 2
    [void]$bodySvg.AppendLine("  <g>")
    [void]$bodySvg.AppendLine("    <animateTransform attributeName=""transform"" type=""translate"" calcMode=""discrete"" values=""0 0;0 -4;0 0"" keyTimes=""0;0.5;1"" dur=""2.4s"" begin=""-$(N (($r * 6 + $i) * 0.22))s"" repeatCount=""indefinite""/>")
    [void]$bodySvg.Append((GridPaths $ic.grid ($cx0 + [int](($cellW - $iconSize) / 2)) $ry $iconScale))
    [void]$bodySvg.AppendLine("  </g>")
    [void]$bodySvg.Append((Txt ([int]($cx0 + ($cellW - $lw) / 2)) ($ry + $iconSize + 12) 2 $lab $true))
  }
}
$y += $h + $GAP

# currently
$h = $headH + (BodyH $now.Count) + $footH
[void]$bodySvg.Append((CardFrame $y $h $T.magenta 'CURRENTLY'))
[void]$bodySvg.Append((TextBlock ($y + $headH) $now))
$y += $h + $GAP

# random thought
$h = $headH + (BodyH $thought.Count) + $footH
[void]$bodySvg.Append((CardFrame $y $h $T.pink 'RANDOM THOUGHT'))
[void]$bodySvg.Append((TextBlock ($y + $headH) $thought))
$y += $h

$H2 = $y + 16
$svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="$W" height="$H2" viewBox="0 0 $W $H2" shape-rendering="crispEdges" role="img" aria-label="About me: hey, i'm udit, a web dev who learns by building and breaking things a little. Tech stack: HTML, JavaScript, CSS, TypeScript, React, Tailwind, Node.js, Express, Python, Git, GitHub. Currently: leveling up in typescript, messing around with python, always building new stuff. Random thought: it works on my machine.">
  <title>About, tech stack, currently, random thought</title>
  <defs>$scan</defs>
$(Surface $H2)$($bodySvg.ToString())</svg>
"@
Save 'page-body.svg' $svg

# ============================== END CAP (closes the page under the snake graph) ==============================
$he = 16
$endPts = "0,0 $W,0 $W,$($he - 8) $($W - 8),$($he - 8) $($W - 8),$he 8,$he 8,$($he - 8) 0,$($he - 8)"
$svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="$W" height="$he" viewBox="0 0 $W $he" shape-rendering="crispEdges" aria-hidden="true">
  <polygon points="$endPts" fill="$($T.deep)"/>
</svg>
"@
Save 'page-end.svg' $svg

"page-top: $H1 px   page-body: $H2 px"

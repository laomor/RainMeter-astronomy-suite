<#
  把 Event Time Case 下的两个时间戳文件，写进四个演示页里固化的数据块。

  页面里每块数据都夹在
      /* === DATA SUN BEGIN === */  ...  /* === DATA SUN END === */
  之间，脚本只认这两行标记之间的内容，别处一个字节都不碰。

  数据不干净（行数不够、事件名不对、文件缺失）时整块跳过：
  页面保持上一版能用的数据，宁可慢一天，也不写进去半截数组。
#>
param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$Pages = @(
  'EffectPreviewImage_Position\index.html',
  'EffectPreviewImage_Trajectory\index.html',
  'EffectPreviewImage_Event\index.html',
  'EffectPreviewImage_Clock\index.html'
)

function Read-EventLines {
  param(
    [string]$Path,
    [string]$Kind,
    [string]$Allowed
  )
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $raw = [System.IO.File]::ReadAllText($Path)
  $raw = $raw -replace "`r`n", "`n" -replace "`r", "`n"
  $lines = @($raw.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
  $expect = '^\d{10}(' + $Allowed + ')$'
  $keep = @($lines | Where-Object { $_ -match $expect })
  # 有空行、null 行或事件名不对，就当数据不可靠，整块不更新
  if ($keep.Count -ne $lines.Count) { return $null }
  if ($keep.Count -lt 4) { return $null }
  return $keep
}

function New-Block {
  param([string]$Kind, [string[]]$Lines)
  $inner = $Lines -join "`n"
  $decl  = 'const {0}_RAW = `{1}`;' -f $Kind, $inner
  $begin = "/* === DATA $Kind BEGIN === */"
  $end   = "/* === DATA $Kind END === */"
  return $begin + "`n" + $decl + "`n" + $end
}

function Set-Block {
  param([string]$Text, [string]$Kind, [string]$Block)
  $begin = "/* === DATA $Kind BEGIN === */"
  $end   = "/* === DATA $Kind END === */"
  $i = $Text.IndexOf($begin)
  if ($i -lt 0) { return $null }
  $j = $Text.IndexOf($end, $i)
  if ($j -lt 0) { return $null }
  return $Text.Substring(0, $i) + $Block + $Text.Substring($j + $end.Length)
}

$sun  = Read-EventLines -Path (Join-Path $Root 'Event Time Case\SunTimeStampEvent.txt') -Kind SUN  -Allowed 'Sunrise|Sunset'
$moon = Read-EventLines -Path (Join-Path $Root 'Event Time Case\MoonTimeStampEvent.txt') -Kind MOON -Allowed 'Moonrise|Moonset'

if (-not $sun -or -not $moon) {
  Write-Host '::warning::事件数据不可用，本次不更新演示页，页面保持上一版数据'
  exit 0
}

$sunBlock  = New-Block -Kind 'SUN'  -Lines $sun
$moonBlock = New-Block -Kind 'MOON' -Lines $moon

foreach ($page in $Pages) {
  $path = Join-Path $Root $page
  if (-not (Test-Path -LiteralPath $path)) {
    Write-Host "::warning::缺页面 $page，跳过"
    continue
  }
  $text = [System.IO.File]::ReadAllText($path)
  $next = Set-Block -Text $text -Kind 'SUN'  -Block $sunBlock
  if ($null -eq $next) { Write-Host "::warning::$page 找不到 SUN 标记，跳过"; continue }
  $next = Set-Block -Text $next -Kind 'MOON' -Block $moonBlock
  if ($null -eq $next) { Write-Host "::warning::$page 找不到 MOON 标记，跳过"; continue }
  if ($next -ne $text) {
    [System.IO.File]::WriteAllText($path, $next, $Utf8NoBom)
    Write-Host "updated: $page"
  } else {
    Write-Host "unchanged: $page"
  }
}

Write-Host ("sun  {0} 条  {1} -> {2}" -f $sun.Count, $sun[0].Substring(10), $sun[$sun.Count-1].Substring(10))
Write-Host ("moon {0} 条  {1} -> {2}" -f $moon.Count, $moon[0].Substring(10), $moon[$moon.Count-1].Substring(10))

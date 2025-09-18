$root  = (Get-Location).Path
$src   = Join-Path $root "src"
$outJ  = Join-Path $root "scripts.manifest.json"
$outMD = Join-Path $root "docs\scripts.inventory.md"

# Ensure folders exist
New-Item -ItemType Directory -Force -Path (Join-Path $root "docs") | Out-Null

# Collect all .lua files
$files = Get-ChildItem -Path $src -Recurse -File -Include *.lua

# Build file entries with SHA1 + optional @Version header
$items = foreach ($f in $files) {
  $rel = $f.FullName.Substring($root.Length + 1).Replace("\","/")
  $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA1).Hash.ToLower()
  $ver  = ($null)
  $hdr  = Select-String -Path $f.FullName -Pattern '^\s*--\s*@Version:\s*(.+)$' -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($hdr) { $ver = $hdr.Matches[0].Groups[1].Value }

  [PSCustomObject]@{
    path    = $rel
    name    = $f.Name
    bytes   = $f.Length
    sha1    = $hash
    version = $ver
  }
}

# Manifest JSON
$manifest = [PSCustomObject]@{
  project      = Split-Path $root -Leaf
  generated_at = (Get-Date).ToUniversalTime().ToString("s") + "Z"
  count        = $items.Count
  files        = $items | Sort-Object path
}

$manifest | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $outJ

# Markdown table (fixed hash column)
$lines = @(
  "# Script Inventory",
  "",
  "_Generated: $($manifest.generated_at)_",
  "",
  "Path | Bytes | SHA1 | Version",
  "---|---:|---|---"
)

foreach ($it in $manifest.files) {
  $short = $it.sha1.Substring(0,10)
  $ver   = if ($it.version) { $it.version } else { "-" }
  $lines += "$($it.path) | $($it.bytes) | `$short...` | $ver"
}

$lines -join "`n" | Out-File -Encoding utf8 $outMD

Write-Host "Wrote $outJ and $outMD (files: $($manifest.count))"

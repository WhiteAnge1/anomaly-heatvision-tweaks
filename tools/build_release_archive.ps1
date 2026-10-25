param(
    [string]$ModRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'dist'),
    [string]$FileName = 'HeatVision-Green-Channel-Fix-1.2.0-rc4.zip'
)

$ErrorActionPreference = 'Stop'
$ModRoot = (Resolve-Path -LiteralPath $ModRoot).Path
if (-not (Test-Path -LiteralPath $OutputDirectory)) { [void](New-Item -ItemType Directory -Path $OutputDirectory) }
$OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
$archivePath = Join-Path $OutputDirectory $FileName
$checksumPath = $archivePath + '.sha256'
if (Test-Path -LiteralPath $archivePath) { Remove-Item -LiteralPath $archivePath -Force }
if (Test-Path -LiteralPath $checksumPath) { Remove-Item -LiteralPath $checksumPath -Force }

$relativeFiles = New-Object System.Collections.Generic.List[string]
foreach ($relativeRoot in @('gamedata','fomod')) {
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $ModRoot $relativeRoot) -Recurse -File) {
        $relativeFiles.Add(($file.FullName.Substring($ModRoot.Length).TrimStart('\','/') -replace '\\','/'))
    }
}
foreach ($relative in @('README.md','CHANGELOG.md','THIRD_PARTY_NOTICES.md')) { $relativeFiles.Add($relative) }
$relativeFiles = @($relativeFiles | Sort-Object -Unique)

Add-Type -AssemblyName System.IO.Compression
$stream = [IO.File]::Open($archivePath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
try {
    $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create, $false)
    try {
        $fixedTime = [DateTimeOffset]::new(2026, 10, 25, 0, 0, 0, [TimeSpan]::Zero)
        foreach ($relative in $relativeFiles) {
            $source = Join-Path $ModRoot ($relative -replace '/','\')
            $entry = $zip.CreateEntry($relative, [IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $fixedTime
            $input = [IO.File]::OpenRead($source)
            $output = $entry.Open()
            try { $input.CopyTo($output) } finally { $output.Dispose(); $input.Dispose() }
        }
    } finally { $zip.Dispose() }
} finally { $stream.Dispose() }

$hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToUpperInvariant()
[IO.File]::WriteAllText($checksumPath, "$hash  $FileName`n", (New-Object Text.UTF8Encoding($false)))
Write-Output "Archive: $archivePath"
Write-Output "Files: $($relativeFiles.Count)"
Write-Output "Bytes: $((Get-Item -LiteralPath $archivePath).Length)"
Write-Output "SHA256: $hash"
Write-Output "Checksum: $checksumPath"

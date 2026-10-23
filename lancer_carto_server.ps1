param(
    [Parameter(Mandatory=$true)] [string]$Root,
    [Parameter(Mandatory=$true)] [string]$ReadyFile
)

$ErrorActionPreference = "Stop"
$rootPath = [System.IO.Path]::GetFullPath($Root)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8000/")

$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".htm" = "text/html; charset=utf-8"
    ".css" = "text/css; charset=utf-8"
    ".js" = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".geojson" = "application/geo+json; charset=utf-8"
    ".csv" = "text/csv; charset=utf-8"
    ".txt" = "text/plain; charset=utf-8"
    ".png" = "image/png"
    ".jpg" = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg" = "image/svg+xml; charset=utf-8"
    ".ico" = "image/x-icon"
}

function Get-SafePath([string]$urlPath) {
    $relative = [System.Uri]::UnescapeDataString($urlPath).TrimStart('/')
    $relative = $relative.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $candidate = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootPath, $relative))
    $rootWithSlash = $rootPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (($candidate -ne $rootPath) -and (-not $candidate.StartsWith($rootWithSlash, [System.StringComparison]::OrdinalIgnoreCase))) {
        return $null
    }
    return $candidate
}

try {
    $listener.Start()
    [System.IO.File]::WriteAllText($ReadyFile, "ready", [System.Text.Encoding]::ASCII)
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $path = Get-SafePath $context.Request.Url.AbsolutePath
            if ($null -eq $path) {
                $context.Response.StatusCode = 404
            } else {
                if ([System.IO.Directory]::Exists($path)) {
                    $path = [System.IO.Path]::Combine($path, "index.html")
                }
                if (-not [System.IO.File]::Exists($path)) {
                    $context.Response.StatusCode = 404
                } else {
                    $ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
                    $textExt = @(".html", ".htm", ".css", ".js", ".json", ".geojson", ".csv", ".svg", ".txt")
                    if ($textExt -contains $ext) {
                        $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
                    } else {
                        $bytes = [System.IO.File]::ReadAllBytes($path)
                    }
                    if ($mime.ContainsKey($ext)) { $context.Response.ContentType = $mime[$ext] } else { $context.Response.ContentType = "application/octet-stream" }
                    $context.Response.ContentLength64 = $bytes.Length
                    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            }
        } catch {
            $context.Response.StatusCode = 500
        } finally {
            $context.Response.Close()
        }
    }
} catch {
    if (Test-Path $ReadyFile) { Remove-Item $ReadyFile -Force -ErrorAction SilentlyContinue }
    exit 1
} finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()
}

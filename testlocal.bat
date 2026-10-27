@echo off
setlocal
cd /d "%~dp0"
set PORT=8000

echo Demarrage du serveur local sur http://localhost:%PORT%
echo Pour arreter, fermez cette fenetre.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$p=%PORT%; $root=(Get-Location).Path; $l=New-Object System.Net.HttpListener; $l.Prefixes.Add('http://localhost:'+$p+'/'); $l.Start(); Start-Process ('http://localhost:'+$p+'/index.html'); while($l.IsListening){ $c=$l.GetContext(); $r=$c.Request; $path=$r.Url.LocalPath.TrimStart('/'); if($path -eq ''){$path='index.html'}; $f=Join-Path $root $path; if(Test-Path $f -PathType Leaf){ $b=[IO.File]::ReadAllBytes($f); $ext=[IO.Path]::GetExtension($f).ToLower(); $ct=@{'.html'='text/html; charset=utf-8';'.js'='application/javascript';'.css'='text/css';'.csv'='text/csv; charset=utf-8';'.png'='image/png';'.jpg'='image/jpeg';'.json'='application/json'}[$ext]; if(-not $ct){$ct='application/octet-stream'}; $c.Response.ContentType=$ct; $c.Response.ContentLength64=$b.Length; $c.Response.OutputStream.Write($b,0,$b.Length) } else { $c.Response.StatusCode=404 }; $c.Response.Close() }"

endlocal
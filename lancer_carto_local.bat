@echo off
setlocal
cd /d "%~dp0"

if not exist "index.html" if exist "index.txt" copy /Y "index.txt" "index.html" >nul
if not exist "index.html" (
  echo ERREUR: index.html ou index.txt est introuvable dans ce dossier.
  echo Placez le fichier HTML dans le meme dossier que ce .bat.
  pause
  exit /b 1
)

where py >nul 2>&1
if not errorlevel 1 goto use_py
where python >nul 2>&1
if not errorlevel 1 goto use_python
where npx >nul 2>&1
if not errorlevel 1 goto use_npx

echo ERREUR: Python et npx sont introuvables.
echo Installez Python depuis https://www.python.org/downloads/ ou Node.js depuis https://nodejs.org/.
pause
exit /b 1

:use_py
echo Demarrage du serveur avec Python (py)...
start "Carto HTTP server" /b py -m http.server 8000
goto open_browser

:use_python
echo Demarrage du serveur avec Python (python)...
start "Carto HTTP server" /b python -m http.server 8000
goto open_browser

:use_npx
echo Demarrage du serveur avec npx http-server...
start "Carto HTTP server" /b npx --yes http-server -p 8000
goto open_browser

:open_browser
 timeout /t 2 /nobreak >nul
start "" "http://localhost:8000/index.html"
echo Application ouverte sur http://localhost:8000/index.html
echo Le serveur reste actif dans cette fenetre.
pause
endlocal

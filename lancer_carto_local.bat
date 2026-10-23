@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist "index.html" if exist "index.txt" copy /Y "index.txt" "index.html" >nul
if not exist "index.html" (
  echo ERREUR: index.html ou index.txt est introuvable dans ce dossier.
  echo Placez le fichier HTML dans le meme dossier que ce .bat.
  pause
  exit /b 1
)

set "PYTHON_CMD="
py -3 -c "import sys" >nul 2>&1
if not errorlevel 1 set "PYTHON_CMD=py -3"
if not defined PYTHON_CMD (
  python -c "import sys" >nul 2>&1
  if not errorlevel 1 set "PYTHON_CMD=python"
)

set "READY_FILE=%TEMP%\carto_server_ready_%RANDOM%_%RANDOM%.tmp"
set "NEEDS_READY=0"
if exist "%READY_FILE%" del /q "%READY_FILE%" >nul 2>&1

if defined PYTHON_CMD (
  echo Demarrage du serveur avec Python...
  start "Carto HTTP server" /b cmd /c %PYTHON_CMD% -m http.server 8000
) else (
  set "NEEDS_READY=1"
  echo Python valide introuvable. Utilisation du serveur PowerShell natif...
  if not exist "%~dp0lancer_carto_server.ps1" (
    echo ERREUR: lancer_carto_server.ps1 est introuvable.
    echo Les deux fichiers doivent rester dans le meme dossier.
    pause
    exit /b 1
  )
  start "Carto HTTP server" /b powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lancer_carto_server.ps1" -Root "%CD%" -ReadyFile "%READY_FILE%"
)

timeout /t 2 /nobreak >nul
powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient; try {$c.Connect('127.0.0.1',8000); exit 0} catch {exit 1} finally {$c.Close()}" >nul 2>&1
if errorlevel 1 (
  echo ERREUR: le serveur n'a pas demarre.
  echo Aucun navigateur ne sera ouvert.
  echo Verifiez qu'un autre programme n'utilise pas le port 8000.
  pause
  exit /b 1
)
if "%NEEDS_READY%"=="1" if not exist "%READY_FILE%" (
  echo ERREUR: le serveur PowerShell n'a pas confirme son demarrage.
  echo Aucun navigateur ne sera ouvert.
  pause
  exit /b 1
)
del /q "%READY_FILE%" >nul 2>&1
start "" "http://localhost:8000/index.html"
echo Application ouverte sur http://localhost:8000/index.html
echo Le serveur reste actif dans cette fenetre.
pause
endlocal

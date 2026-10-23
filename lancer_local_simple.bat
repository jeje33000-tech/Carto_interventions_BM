@echo off
title Lanceur local simple - port 8000
cd /d "%~dp0"

echo.
echo ============================================================
echo   Lanceur local SIMPLE
echo   Sert le dossier courant sur http://localhost:8000/
echo ============================================================
echo.

set "PYTHON_CMD="
where py >nul 2>&1 && set "PYTHON_CMD=py -3"
if not defined PYTHON_CMD (
    where python >nul 2>&1 && set "PYTHON_CMD=python"
)
if not defined PYTHON_CMD (
    where python3 >nul 2>&1 && set "PYTHON_CMD=python3"
)

if not defined PYTHON_CMD goto :no_python

echo Python : %PYTHON_CMD%
echo Demarrage du serveur sur le port 8000...
echo Ouvrez http://localhost:8000/ dans votre navigateur.
echo Pour arreter : Ctrl+C puis fermez, ou fermez cette fenetre.
echo.

start "" "http://localhost:8000/"
%PYTHON_CMD% -m http.server 8000 --bind 127.0.0.1

echo.
echo Le serveur s'est arrete.
pause
exit /b 0

:no_python
echo.
echo ERREUR : Python introuvable.
echo Installez Python 3 ou ajoutez-le au PATH.
echo.
pause
exit /b 1

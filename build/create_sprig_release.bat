@echo off
setlocal

REM This bat file will create both a 7z and zip archive of the sprig folder named sprigV<version>.7z/.zip
REM It excludes all git-related files and this script itself
REM You need 7zip installed to use this script

REM Navigate to repository root
cd /d "%~dp0\.."

REM Define variables
set "archiveName=sprig"
set "destinationDir=dist"
set "version="

REM Check for the sprig version file
if not exist "sprig\version" (
    echo Error: Could not find the file "sprig\version".
    pause
    exit /b 1
)

REM Read the content of "sprig/version" file
set /p version=<sprig\version

REM Validate that we have the version
if "%version%"=="" (
    echo Error: Failed to retrieve the version from "sprig\version".
    pause
    exit /b 1
)

REM Create destination directory
if not exist "%destinationDir%" mkdir "%destinationDir%"

REM Create archive file names
set "output7z=%destinationDir%\%archiveName%V%version%.7z"
set "outputZip=%destinationDir%\%archiveName%V%version%.zip"

REM Remove existing archives if present
for %%A in ("%output7z%" "%outputZip%") do (
    if exist "%%~A" (
        echo Removing existing "%%~A"
        del "%%~A"
    )
)

REM Create the 7z file excluding this script and all git-related files
echo Creating 7z archive "%output7z%"...
7z a -t7z -mx=9 -xr!.git* -xr!build -x!.gitignore -x!.gitattributes -x!justfile -x!main -x!TODO.txt "%output7z%" *
if %errorlevel% neq 0 (
    echo Error: Failed to create the 7z archive.
    pause
    exit /b 1
)

REM Create the zip file with the same exclusions
echo Creating zip archive "%outputZip%"...
7z a -tzip -mx=9 -xr!.git* -xr!build -x!.gitignore -x!.gitattributes -x!justfile -x!main -x!TODO.txt "%outputZip%" *
if %errorlevel% neq 0 (
    echo Error: Failed to create the zip archive.
    pause
    exit /b 1
)

echo.
echo Both archives created successfully:
echo   "%output7z%"
echo   "%outputZip%"
pause
exit /b 0

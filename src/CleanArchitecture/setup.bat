@echo off
REM Clean Architecture .NET Solution Generator
REM Compatible with standard Windows Command Prompt
REM Simply redirects to PowerShell version for consistency

echo Clean Architecture .NET Solution Generator
echo ----------------------------------------

if "%~1"=="" (
  echo ERROR: You must provide a solution name!
  echo Usage: setup.bat SolutionName [/WithTest]
  exit /b 1
)

set SOLUTION_NAME=%~1
set WITH_TEST=

if /i "%~2"=="/WithTest" (
  set WITH_TEST=-WithTest
)

echo Running PowerShell script setup.ps1...

powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -SolutionName "%SOLUTION_NAME%" %WITH_TEST%

if %ERRORLEVEL% NEQ 0 (
  echo ERROR: Failed to execute setup.ps1
  exit /b %ERRORLEVEL%
)

echo.
echo Setup complete! Solution '%SOLUTION_NAME%' is ready.

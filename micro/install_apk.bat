@echo off
echo Installing Micro app on Android device...

REM Check if ADB is available
adb version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ADB not found. Please make sure Android SDK Platform-Tools is installed and in your PATH.
    pause
    exit /b 1
)

REM Check if device is connected
adb devices | findstr "device$" >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: No Android device connected. Please connect your device and enable USB debugging.
    pause
    exit /b 1
)

REM Install the APK
echo Installing app-debug.apk...
adb install -r "build\app\outputs\flutter-apk\app-debug.apk"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS! Micro app has been installed on your device.
    echo You can now find it in your app drawer.
) else (
    echo.
    echo FAILED to install the APK. Please check the error messages above.
)

pause
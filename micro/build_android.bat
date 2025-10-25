@echo off
echo Building Micro for Android...

cd android
call gradlew assembleDebug --no-daemon

if %ERRORLEVEL% EQU 0 (
    echo Build successful!
    echo Installing APK on device...
    adb install -r app/build/outputs/apk/debug/app-debug.apk
    echo Launching app...
    adb shell am start -n com.psitrix.micro/com.psitrix.micro.MainActivity
) else (
    echo Build failed with error code %ERRORLEVEL%
    echo Please check the error messages above.
)

pause
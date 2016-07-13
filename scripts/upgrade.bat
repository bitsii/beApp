
mkdir App\IUHub.bak
del /s /q App\IUHub.bak\*.*
copy /y App\IUHub\*.* App\IUHub.bak
cd App\IUHub
unzip -o ..\IUHub.zip

cd ..\..
call App\IUHub\postupgrade.bat

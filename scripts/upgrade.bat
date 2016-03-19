
mkdir App\Dz.bak
del /s /q App\Dz.bak\*.*
copy /y App\Dz\*.* App\Dz.bak
cd App\Dz
unzip -o ..\Dz.zip
cd ..\..
call App\Dz\postupgrade.bat

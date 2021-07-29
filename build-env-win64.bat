
@echo on
SETLOCAL
set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
set "MSYS2=C:\msys64\msys2_shell.cmd"
call "%VCVARS%" amd64
echo **********************************************************************
echo ** Loading MSYS2 MINGW64 Shell Environment 
echo **********************************************************************
@echo on
call "%MSYS2%" -mingw64 -use-full-path -here -defterm -no-start -c %*
exit /b %ERRORLEVEL%
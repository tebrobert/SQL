@echo off
cls

msbuild
if exist "lab12/bin/App.config/lab12.exe" (
    cd "lab12/bin/App.config/"
    cls
    lab12.exe
    del "lab12.exe"
    cd ../../..
    cls
)

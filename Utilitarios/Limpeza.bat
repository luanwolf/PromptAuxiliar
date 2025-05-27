@echo off 
chcp 65001 
setlocal enabledelayedexpansion 
echo  [ 🧹 ] Limpando arquivos temporários... 
del /q /f "C:\Users\Luan\AppData\Local\Temp\*" 
del /q /f "C:\Windows\Temp\*" 

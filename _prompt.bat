::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCqDJGqL8lYnKQlRXziyLmS3FqEgwev04dW3sEIQRPYAWZrD07iHIfJd40brFQ==
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSDk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+IeA==
::cxY6rQJ7JhzQF1fEqQJhZkkaHErSXA==
::ZQ05rAF9IBncCkqN+0xwdVsFAlbMbCXqZg==
::ZQ05rAF9IAHYFVzEqQIAOhRZXBDCHX6iD7kV6fqb
::eg0/rx1wNQPfEVWB+kM9LVsJDDSQM2aqEvU9/fDy4+OGsA0LBaxtGA==
::fBEirQZwNQPfEVWB+kM9LVsJDDSQM2aqEvU9/fDy4+OGsA0LBaxtGA==
::cRolqwZ3JBvQF1fEqQIWLQlGTQmHMn+7RqUd+um77v+fq0EUVfB/doCb7b2AJO8E+SU=
::dhA7uBVwLU+EWHGB7UMjIHs=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATEVotwAB5NTReKfDnqVOB8
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCqDJGqL8lYnKQlRXziyLmS3FqEg2Pr04vqT4mwITOszcY7JmqLfbrJd713hFQ==
::YB416Ek+ZW8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Prompt Auxiliar v1.2 © Heyash
mode con cols=130 lines=40

:: Para funcionar as cores do batchfile
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

:: Forçar administrador
fsutil dirty query C: >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ ⚠️ ] O script precisa ser executado como Administrador!
    echo  [ 🔄 ] Reiniciando com permissões elevadas...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit
)

:: Aviso de inicialização da estrutura
echo.
echo  [ 📁 ] Verificando e criando arquivos/pastas necessários...
timeout /t 2 >nul

:: Criar estrutura de pastas e arquivos necessários
set "ROOT=%~dp0"
set "popup_needed=0"

:: Criar pastas e arquivos placeholder se necessário
for %%A in ("Log" "Registros" "Software" "Utilitarios") do (
    if not exist "%ROOT%%%~A" (
        mkdir "%ROOT%%%~A"
        set "popup_needed=1"
    )

    if not exist "%ROOT%%%~A\instruções.txt" (
        if /I "%%~A"=="Log" (
            echo AQUI FICAM OS LOGS>"%ROOT%%%~A\instruções.txt"
        ) else if /I "%%~A"=="Registros" (
            echo AQUI FICAM OS .REG PARA APLICAR NO SEU COMPUTADOR>"%ROOT%%%~A\instruções.txt"
        ) else if /I "%%~A"=="Software" (
            echo AQUI FICAM OS INSTALADORES .EXE, .MSI E .LNK OU ATALHOS COMO SÃO CONHECIDOS, ASSIM VOCÊ CONSEGUE INSTALAR QUALQUER PROGRAMA>"%ROOT%%%~A\instruções.txt"
        )
    )
)

:: Criar o script Limpeza.bat dentro da pasta Utilitarios, se não existir
set "LIMPEZA_FILE=%ROOT%Utilitarios\Limpeza.bat"
if not exist "%LIMPEZA_FILE%" (
    echo @echo off > "%LIMPEZA_FILE%"
    echo chcp 65001 >nul >> "%LIMPEZA_FILE%"
    echo setlocal enabledelayedexpansion >> "%LIMPEZA_FILE%"
    echo echo  [ 🧹 ] Limpando arquivos temporários... >> "%LIMPEZA_FILE%"
    echo del /q /f "%temp%\*" >> "%LIMPEZA_FILE%"
    echo del /q /f "%systemroot%\Temp\*" >> "%LIMPEZA_FILE%"
    set "popup_needed=1"
)

:: Criar arquivos com conteúdo padrão se não existirem
if not exist "%ROOT%Winget.txt" (
    (
        echo #ATENÇÃO PARA QUE O PROMPT IGNORE A LINHA VOCÊ DEVE COLOCAR UM # NA FRENTE DA LINHA QUE DESEJA QUE FOSSE IGNORADA
        echo #INSIRA O CÓDIGO DO APLICATIVO DESEJADO PARA INSTALAÇÃO.
        echo.
        echo #EXEMPLO 
        echo #CPU-Z
        echo CPUID.CPU-Z
    ) > "%ROOT%Winget.txt"
    set "popup_needed=1"
)

if not exist "%ROOT%Bloatware.txt" (
    (
        echo #ATENÇÃO PARA QUE O PROMPT IGNORE A LINHA VOCÊ DEVE COLOCAR UM # NA FRENTE DA LINHA QUE DESEJA QUE FOSSE IGNORADA
        echo.
        echo #INSIRA O CÓDIGO DO APLICATIVO DESEJADO PARA INSTALAÇÃO.
        echo.
        echo #EXEMPLO 
        echo #Assistência Rápida 
        echo MicrosoftCorporationII.QuickAssist_8wekyb3d8bbwe
    ) > "%ROOT%Bloatware.txt"
    set "popup_needed=1"
)

if "%popup_needed%"=="1" (
    echo  [ ✅ ] Estrutura criada com sucesso!
) else (
    echo  [ ℹ️ ] Estrutura já estava pronta. Nenhuma alteração necessária.
)
timeout /t 2 >nul

:: Obter a data no formato yyyy-MM-dd
for /f "tokens=1-3 delims=/ " %%a in ("%date%") do set DATA=%%a-%%b-%%c

:: Obter o nome do usuário
set "USUARIO=%USERNAME%"

:: Criar diretório de log, caso não exista
set "LOGDIR=%~dp0Log"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:: Criar o arquivo de log com a nomenclatura desejada
set "LOGFILE=%LOGDIR%\Log - %DATA% - %USUARIO%.txt"

:: Formatação do título
echo =================================================== >> "%LOGFILE%"
echo    LOG DE UTILIZAÇÃO - %DATE% %TIME%                >> "%LOGFILE%"
echo =================================================== >> "%LOGFILE%"

:: Caminho do arquivo de controle
set "FLAG_FILE=%~dp0Utilitarios\flag"

:: Verifica se é a primeira execução
if not exist "%FLAG_FILE%" (
    cls
    echo.
    echo    ———————————————————————————————————————————————
    echo         %ESC%[7m%ESC%[1mBem-vindo ao Prompt Auxiliar v1.2! 👋%ESC%[0m   
    echo    ———————————————————————————————————————————————
    echo.
    echo    Esta é a sua primeira vez usando este prompt
    echo    e algumas configurações iniciais foram feitas.
    echo.
    echo    Confira as pastas e os arquivos de instruções criados!
    echo. 
    echo    %ESC%[7m%ESC%[1mEstrutura de pastas criada:%ESC%[0m
    echo    📁 %SYSTEMDRIVE%\PromptAuxiliar\
    echo    ├── 📂 Log\
    echo    ├── 📂 Registros\
    echo    ├── 📂 Software\
    echo    ├── 📂 Utilitarios\
    echo    ├── 📄 bloatware.txt
    echo    └── 📄 winget.txt
    echo.
    echo    Você pode abrir a pasta através do Menu na opção %ESC%[7m%ESC%[1mP%ESC%[0m.
    echo.
    echo    %ESC%[7m%ESC%[1m%ESC%[5mPressione qualquer tecla para continuar...%ESC%[0m
    pause >nul

    :: Cria o arquivo de controle para evitar novo aviso
    echo primeira_execucao > "%FLAG_FILE%"
)

:: Menu inicial
:MENU
cls
echo.
echo  Informações do usuário/sistema:
echo  %ESC%[7m%ESC%[1mUsuario:%ESC%[0m %username%  -  %ESC%[7m%ESC%[1mComputador:%ESC%[0m %computername%  -  %ESC%[7m%ESC%[1mDia:%ESC%[0m %date%
echo.
echo  ——————————————————————————————————————————————————————
echo.
echo.  ███╗   ███╗███████╗███╗   ██╗██╗   ██╗
echo.  ████╗ ████║██╔════╝████╗  ██║██║   ██║
echo.  ██╔████╔██║█████╗  ██╔██╗ ██║██║   ██║
echo.  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║   ██║
echo.  ██║ ╚═╝ ██║███████╗██║ ╚████║╚██████╔╝
echo.  ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝  v1.2 by %ESC%[7m%ESC%[1mHeyash%ESC%[0m   
echo.
echo  ——————————————————————————————————————————————————————
echo.
echo    📂   Abrir pasta do prompt (P)
echo    🔃   Atualizar menu (R)
echo    ❌   Sair (X)
echo.
echo    %ESC%[7m%ESC%[1m01%ESC%[0m   Atualizar softwares
echo    %ESC%[7m%ESC%[1m02%ESC%[0m   Instalar softwares via Winget (winget.txt)
echo    %ESC%[7m%ESC%[1m03%ESC%[0m   Instalar softwares da pasta "Software"
echo    %ESC%[7m%ESC%[1m04%ESC%[0m   Remover softwares (bloatware.txt)
echo    %ESC%[7m%ESC%[1m05%ESC%[0m   Aplicar ajustes via registros (.reg)
echo    %ESC%[7m%ESC%[1m06%ESC%[0m   Ativar o Windows (slmgr)
echo    %ESC%[7m%ESC%[1m07%ESC%[0m   Criar atalhos no Desktop (GodMode e BIOS) %ESC%[7m%ESC%[1m%ESC%[5m*Corrigido%ESC%[0m
echo    %ESC%[7m%ESC%[1m08%ESC%[0m   Reparar conexão de rede
echo    %ESC%[7m%ESC%[1m09%ESC%[0m   Limpeza de malware via MRT
echo    %ESC%[7m%ESC%[1m10%ESC%[0m   Limpeza de arquivos temporários
echo    %ESC%[7m%ESC%[1m11%ESC%[0m   Limpeza profunda do Windows
echo    %ESC%[7m%ESC%[1m12%ESC%[0m   Windows Utility %ESC%[7m%ESC%[1m%ESC%[5m*Nova função%ESC%[0m
echo    %ESC%[7m%ESC%[1m13%ESC%[0m   Alternar o menu de contexto
echo    %ESC%[7m%ESC%[1m14%ESC%[0m   Gerenciar apps de inicialização
echo    %ESC%[7m%ESC%[1m15%ESC%[0m   Reiniciar o computador (5s)
echo.
echo  ——————————————————————————————————————————————————————
echo.
set /p opcao="%ESC%[7m%ESC%[1m%ESC%[5m৹ Digite a opção desejada (1-15):%ESC%[0m "

if "%opcao%"=="1" goto ATUALIZAR
if "%opcao%"=="2" goto INSTALAR_WINGET
if "%opcao%"=="3" goto INSTALAR_SOFTWARE
if "%opcao%"=="4" goto REMOVER_BLOATWARE
if "%opcao%"=="5" goto INSTALAR_REG
if "%opcao%"=="6" goto ATIVAR_WINDOWS
if "%opcao%"=="7" goto FOLDER_GODMODE
if "%opcao%"=="8" goto REPARAR_REDE
if "%opcao%"=="9" goto MRT
if "%opcao%"=="10" goto LIMPAR_TEMP
if "%opcao%"=="11" goto CLEANUP
if "%opcao%"=="12" goto CHRIS_TITUS
if "%opcao%"=="13" goto CONTEXT_MENU
if "%opcao%"=="14" goto STARTUP_APPS
if "%opcao%"=="15" goto REINICIAR

if /I "%opcao%"=="P" goto ABRIR_PASTA_SCRIPT
if /I "%opcao%"=="p" goto ABRIR_PASTA_SCRIPT

if /I "%opcao%"=="X" exit
if /I "%opcao%"=="x" exit

if /I "%opcao%"=="R" goto :MENU
if /I "%opcao%"=="r" goto :MENU

goto :MENU

:: ======================== RESTANTE DAS FUNÇÕES ========================

:ATUALIZAR
cls
echo  [ 📋 ] Listando programas disponíveis para atualização...
winget upgrade

echo.
echo  [ 🔄 ] Opções de atualização:
echo.
echo    %ESC%[7m%ESC%[1m01%ESC%[0m   Atualizar todos os programas
echo    %ESC%[7m%ESC%[1m02%ESC%[0m   Atualizar individualmente
echo    %ESC%[7m%ESC%[1m03%ESC%[0m   Voltar para o menu principal
echo.
set /p update_option="%ESC%[7m%ESC%[1m%ESC%[5m৹ Digite a opção desejada: (1-3)%ESC%[0m "

if "%update_option%"=="1" (
    cls
    echo  [ 🚀 ] Atualizando todos os programas via Winget...
    winget upgrade --all --silent
    if %errorlevel% neq 0 (
        echo  [ ❌ ] Erro ao atualizar os programas. Verifique o log para mais detalhes.
        echo  [ ❌ ] Atualização de todos os programas falhou em %DATE% %TIME% >> "%LOGFILE%"
    ) else (
        echo  [ ✅ ] Atualização concluída com sucesso!
        echo  [ ✅ ] Atualização de programas realizada em %DATE% %TIME% >> "%LOGFILE%"
    )
    timeout /t 5 >nul
    goto :MENU
)

if "%update_option%"=="2" (
    cls
    echo  [ 📋 ] Listando programas disponíveis para atualização...
    winget upgrade
    echo.
    set /p app_id="৹ Digite a opção desejada (ID.ID): "
    winget upgrade --id "%app_id%" --silent
    if %errorlevel% neq 0 (
        echo  [ ❌ ] Erro ao atualizar o programa %app_id%. Verifique o log para mais detalhes.
        echo  [ ❌ ] Atualização do programa %app_id% falhou em %DATE% %TIME% >> "%LOGFILE%"
    ) else (
        echo  [ ✅ ] Atualização do programa %app_id% concluída com sucesso!
        echo  [ ✅ ] Atualização individual realizada para %app_id% em %DATE% %TIME% >> "%LOGFILE%"
    )
    timeout /t 5 >nul
    goto :MENU
)

if "%update_option%"=="3" (
    goto :MENU
)
goto :MENU

:INSTALAR_WINGET
cls
echo  [ 🚀 ] Instalando programas via Winget...
set "WINGET_FILE=%~dp0Winget.txt"
if not exist "%WINGET_FILE%" (
    echo  [ ❌ ] O arquivo Winget.txt não foi encontrado!
    echo  [ ❌ ] Instalação via Winget falhou. Arquivo Winget.txt ausente em %DATE% %TIME% >> "%LOGFILE%"
    timeout /t 5 >nul
    goto :MENU
)

:: Ativar o delayed expansion para trabalhar com variáveis dentro do loop
setlocal enabledelayedexpansion

:: Loop para ler o arquivo Winget.txt e instalar os programas
for /f "tokens=* delims=" %%A in ('findstr /V "^#" "%WINGET_FILE%"') do (
    set "PROGRAM=%%A"
    
    :: Ignorar linhas com "#"
    echo %%A | findstr /r "^#" >nul
    if not errorlevel 1 (
        echo  [ 🔒 ] Ignorando linha comentada: %%A
        echo  [ 🔒 ] Linha comentada ignorada: %%A em %DATE% %TIME% >> "%LOGFILE%"
    ) else (
        echo  [ 🚀 ] Instalando !PROGRAM!...
        
        :: Executar a instalação via Winget
        winget install "!PROGRAM!" --silent --accept-package-agreements --accept-source-agreements

        :: Verificar se houve erro na instalação
        if !errorlevel! neq 0 (
            echo  [ ❌ ] Erro ao instalar !PROGRAM! >> "%LOGFILE%"
        ) else (
            echo  [ ✅ ] Instalado: !PROGRAM! >> "%LOGFILE%"
        )
    )
)

:: Finalizar o uso do delayed expansion
endlocal

echo  [ ✅ ] Instalação concluída!
timeout /t 5 >nul
goto :MENU

:INSTALAR_SOFTWARE
cls
echo  [ 🛠 ] Instalando programas do sistema...

set "PASTA_SOFTWARE=%~dp0Software"

if not exist "%PASTA_SOFTWARE%" (
    echo  [ ❌ ] A pasta "Software" não existe!
    echo  [ ❌ ] Pasta "Software" não encontrada em %DATE% %TIME% >> "%LOGFILE%"
    timeout /t 5 >nul
    goto :MENU
)

:: Instalar programas .exe, .msi e .lnk
for %%I in ("%PASTA_SOFTWARE%\*.exe" "%PASTA_SOFTWARE%\*.msi" "%PASTA_SOFTWARE%\*.lnk") do (
    echo  [ 🚀 ] Instalando %%~nxI...
    start /wait "" "%%I"
    if %ERRORLEVEL% neq 0 (
        echo  [ ❌ ] Erro ao instalar %%~nxI. >> "%LOGFILE%"
    ) else (
        echo  [ ✅ ] Instalado: %%~nxI >> "%LOGFILE%"
    )
)

echo  [ ✅ ] Instalação concluída!
timeout /t 5 >nul
goto :MENU

:INSTALAR_REG
cls
echo  [ 🛠 ] Aplicando ajustes do sistema...

setlocal enabledelayedexpansion
set "PASTA_REG=%~dp0Registros"

if not exist "%PASTA_REG%" (
    echo  [ ❌ ] A pasta "Registros" não existe!
    echo  [ ❌ ] Pasta "Registros" não encontrada em %DATE% %TIME% >> "%LOGFILE%"
    timeout /t 5 >nul
    goto :MENU
)

:: Instalar arquivos .reg
for %%I in ("%PASTA_REG%\*.reg") do (
    echo  [ 🚀 ] Aplicando ajuste %%~nxI...
    reg import "%%I"

    if !ERRORLEVEL! neq 0 (
        echo  [ ❌ ] Erro ao aplicar %%~nxI. >> "%LOGFILE%"
    ) else (
        echo  [ ✅ ] Ajuste aplicado: %%~nxI >> "%LOGFILE%"
    )
)

echo  [ ✅ ] Aplicação de ajustes concluída!
timeout /t 5 >nul
endlocal
goto :MENU

:REMOVER_BLOATWARE
cls
echo  [ 🗑 ] Removendo bloatwares...

set "BLOATED=%~dp0bloatware.txt"
if not exist "%BLOATED%" (
    echo  [ ❌ ] Arquivo bloatware.txt não encontrado!
    echo  [ ❌ ] Arquivo bloatware.txt ausente em %DATE% %TIME% >> "%LOGFILE%"
    timeout /t 5 >nul
    goto :MENU
)

:: Ignorar linhas comentadas e remover softwares
for /f "tokens=* delims=" %%A in ('findstr /V "^#" "%BLOATED%"') do (
    echo  [ 🔄 ] Removendo %%A com Winget...
    winget uninstall "%%A" --silent

    if %errorlevel% neq 0 (
        echo  [ ❌ ] Falha ao remover %%A. >> "%LOGFILE%"
    ) else (
        echo  [ ✅ ] Removido: %%A >> "%LOGFILE%"
    )
)

echo  [ ✅ ] Remoção concluída!
timeout /t 5 >nul
goto :MENU

:LIMPAR_TEMP
cls
echo  [ 🧹 ] Limpando arquivos temporários...
call "%ROOT%Utilitarios\Limpeza.bat"
echo  [ ✅ ] Limpeza de arquivos temporários concluída!
echo  [ ✅ ] LIMPEZA TEMPORÁRIA FINALIZADA EM %DATE% %TIME% >> "%LOGFILE%"
timeout /t 5 >nul
goto :MENU
 
:ATIVAR_WINDOWS
cls
echo  [ 🔑 ] Ativando o Windows...
echo  [ 🔑 ] Iniciando ativação do Windows em %DATE% %TIME% >> "%LOGFILE%"

:: Tentar ativar o Windows
slmgr /ato >> "%LOGFILE%" 2>&1

:: Verificar se o comando foi bem-sucedido
if %errorlevel% neq 0 (
    echo  [ ❌ ] Falha ao ativar o Windows. Verifique se a chave de produto está correta.
    echo  [ ❌ ] Erro ao ativar o Windows em %DATE% %TIME% >> "%LOGFILE%"
    echo Código de erro: %errorlevel% >> "%LOGFILE%"
) else (
    echo  [ ✅ ] Windows ativado com sucesso!
    echo  [ ✅ ] Ativação do Windows realizada em %DATE% %TIME% >> "%LOGFILE%"
)

timeout /t 5 >nul
goto :MENU

:REPARAR_REDE
cls
echo  [ 🛡️ ] Reparando conexão de rede...
echo  [ 🛡️ ] Iniciando reparo de rede em %DATE% %TIME% >> "%LOGFILE%"

:: Resetar configurações de IP e Winsock
netsh int ip reset >> "%LOGFILE%" 2>&1
netsh winsock reset >> "%LOGFILE%" 2>&1

:: Renovar IP
ipconfig /release >> "%LOGFILE%" 2>&1
ipconfig /renew >> "%LOGFILE%" 2>&1
ipconfig /flushdns >> "%LOGFILE%" 2>&1

:: Reiniciar adaptador de rede (substitua "Ethernet" conforme necessário)
netsh interface set interface "Ethernet" admin=disable >> "%LOGFILE%" 2>&1
netsh interface set interface "Ethernet" admin=enable >> "%LOGFILE%" 2>&1

:: Verificar último comando executado
if %errorlevel% neq 0 (
    echo  [ ❌ ] Falha ao reparar a conexão de rede.
    echo  [ ❌ ] Reparação da rede falhou em %DATE% %TIME% >> "%LOGFILE%"
) else (
    echo  [ ✅ ] Conexão de rede reparada com sucesso!
    echo  [ ✅ ] Reparação da rede realizada em %DATE% %TIME% >> "%LOGFILE%"
)
timeout /t 5 >nul
goto :MENU

:CONTEXT_MENU
cls
echo  [ 🟦 ] Selecione o estilo do menu contextual:
echo.
echo    %ESC%[7m%ESC%[1m01%ESC%[0m   Clássico (Windows 10)
echo    %ESC%[7m%ESC%[1m02%ESC%[0m   Moderno (Windows 11)
echo    %ESC%[7m%ESC%[1m03%ESC%[0m   Voltar para o menu principal
echo.
set /p context_op="%ESC%[7m%ESC%[1m%ESC%[5m৹ Digite a opção desejada (1-3):%ESC%[0m "

if "%context_op%"=="1" (
    echo.
    echo  [ ⚙️ ] Aplicando menu contextual Clássico...
    echo  [ ⚙️ ] Aplicando menu contextual Clássico... >> "%LOGFILE%"
    reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
    echo  [ 🔁 ] Reiniciando explorer.exe...
    echo  [ 🔁 ] Reiniciando explorer.exe... >> "%LOGFILE%"
    taskkill /f /im explorer.exe >nul
    start explorer.exe
    echo  [ ✅ ] Menu contextual definido como Clássico. >> "%LOGFILE%"
	echo  [ ✅ ] Menu contextual definido como Clássico.
) else if "%context_op%"=="2" (
    echo.
    echo  [ ⚙️ ] Aplicando menu contextual Moderno...
    echo  [ ⚙️ ] Aplicando menu contextual Moderno... >> "%LOGFILE%"
    reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
    echo  [ 🔁 ] Reiniciando explorer.exe...
    echo  [ 🔁 ] Reiniciando explorer.exe... >> "%LOGFILE%"
    taskkill /f /im explorer.exe >nul
    start explorer.exe
    echo  [ ✅ ] Menu contextual definido como Moderno. >> "%LOGFILE%"
	echo  [ ✅ ] Menu contextual definido como Moderno.
) else if "%context_op%"=="3" (
    timeout /t 5 >nul
    goto :MENU
) else (
    echo  [ ❌ ] Opção inválida. >> "%LOGFILE%"
    echo  [ ❌ ] Opção inválida.
    timeout /t 5 >nul
)

goto :MENU

:MRT
cls 
echo  [ 🛡️ ] Verificando e executando MRT...
echo  [ 🛡️ ] Verificando e executando MRT... >> "%LOGFILE%"

where MRT >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ 🔽️ ] Baixando Microsoft MRT...
    echo  [ 🔽️ ] Baixando Microsoft MRT... >> "%LOGFILE%"
    powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/mrt.exe', '%ROOT%Software\MRT.exe')"
    start "" "%ROOT%Software\MRT.exe"
    echo  [ ✅ ] MRT baixado e iniciado. >> "%LOGFILE%"
	echo  [ ✅ ] MRT baixado e iniciado.
) else (
    echo  [ ▶️ ] Executando MRT local... >> "%LOGFILE%"
    MRT.exe
    echo  [ ✅ ] MRT executado localmente. >> "%LOGFILE%"
	echo  [ ✅ ] MRT executado localmente.
)
timeout /t 5 >nul
goto :MENU

:CLEANUP
cls
echo.
echo  [ 🧹 ] Realizando limpeza profunda...
echo  [ 🧹 ] Realizando limpeza profunda... >> "%LOGFILE%"
echo.

:: Executar limpeza de disco
echo  [ 📂 ] Executando Cleanmgr (Disco)... >> "%LOGFILE%"
cleanmgr /sagerun:1
echo  [ ✅ ] Cleanmgr finalizado. >> "%LOGFILE%"

:: Restaurar imagem do sistema
echo  [ 🛠️ ] Executando DISM /RestoreHealth... >> "%LOGFILE%"
dism /online /cleanup-image /restorehealth >> "%LOGFILE%" 2>&1
echo  [ ✅ ] DISM finalizado. >> "%LOGFILE%"

:: Verificar integridade do sistema
echo  [ 🔍 ] Executando SFC /Scannow... >> "%LOGFILE%"
sfc /scannow >> "%LOGFILE%" 2>&1
echo  [ ✅ ] SFC finalizado. >> "%LOGFILE%"

echo.
echo  [ ✅ ] Limpeza completada.
echo  [ ✅ ] Limpeza completada. >> "%LOGFILE%"
timeout /t 5 >nul
goto :MENU

:STARTUP_APPS
cls
echo  [ ⚙️ ] Abrindo o Gerenciador de Tarefas na aba de Inicialização...
echo  [ ⚙️ ] Abrindo o Gerenciador de Tarefas na aba de Inicialização... >> "%LOGFILE%"
taskmgr /0 /startup
echo  [ ✅ ] Gerenciador de Tarefas aberto com sucesso!
echo  [ ✅ ] Gerenciador de Tarefas aberto com sucesso! >> "%LOGFILE%"
echo.
timeout /t 5 >nul
goto :MENU

:FOLDER_GODMODE
cls
echo  [ ⚙️ ] Criando a pasta "GodMode" e atalhos na área de trabalho...
echo  [ ⚙️ ] Criando a pasta "GodMode" e atalhos na área de trabalho... >> "%LOGFILE%"

:: Caminho da área de trabalho
set "DESKTOP=%USERPROFILE%\Desktop"

:: Criar a pasta "GodMode"
mkdir "%DESKTOP%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" >nul 2>&1

if exist "%DESKTOP%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" (
    echo  [ ✅ ] Pasta "GodMode" criada com sucesso!
    echo  [ ✅ ] Pasta "GodMode" criada com sucesso! >> "%LOGFILE%"
) else (
    echo  [ ❌ ] Falha ao criar a pasta "GodMode". Verifique as permissões.
    echo  [ ❌ ] Falha ao criar a pasta "GodMode". Verifique as permissões. >> "%LOGFILE%"
    timeout /t 5 >nul
    goto :MENU
)

:: Criar atalhos (BIOS)
echo  [ ⚙️ ] Criando atalhos...
echo  [ ⚙️ ] Criando atalhos... >> "%LOGFILE%"

:: Atalho para BIOS
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$desktop = '%DESKTOP%'; $log = '%LOGFILE%'; try { $s = (New-Object -ComObject WScript.Shell).CreateShortcut(\"$desktop\\Reiniciar BIOS.lnk\"); $s.TargetPath = 'shutdown.exe'; $s.Arguments = '/r /fw /t 0'; $s.IconLocation = \"$env:SystemRoot\\System32\\setupapi.dll,57\"; $s.Save(); Write-Output '[ ✅ ] Atalho BIOS criado com sucesso!'; Add-Content -Path $log -Value '[ ✅ ] Atalho BIOS criado com sucesso!'; } catch { Write-Output '[ ❌ ] Falha ao criar o atalho BIOS.'; Add-Content -Path $log -Value '[ ❌ ] Falha ao criar o atalho BIOS.'; }"

echo  [ ✅ ] Atalhos criados com sucesso!
echo  [ ✅ ] Atalhos criados com sucesso! >> "%LOGFILE%"
timeout /t 5 >nul
goto :MENU

:CHRIS_TITUS
cls
echo  [ 🧠 ] Executando script de otimização do Chris Titus Tech...
echo  [ 🌐 ] Isso pode levar alguns minutos e requer conexão com a internet.

powershell -NoProfile -ExecutionPolicy Bypass -Command "irm -useb christitus.com/win | iex"

if %errorlevel% neq 0 (
    echo  [ ❌ ] Erro ao executar o script de otimização.
    echo  [ ❌ ] Falha ao aplicar script de Chris Titus em %DATE% %TIME% >> "%LOGFILE%"
) else (
    echo  [ ✅ ] Script aplicado com sucesso!
    echo  [ ✅ ] Script Chris Titus executado em %DATE% %TIME% >> "%LOGFILE%"
)

timeout /t 5 >nul
goto :MENU

:ABRIR_PASTA_SCRIPT
echo.
echo 🗂️  Abrindo a pasta onde o script está localizado...
start "" explorer "%~dp0"
timeout /t 2 >nul
goto MENU

:REINICIAR
cls
set /p confirm="%ESC%[7m%ESC%[1m%ESC%[5m৹ Tem certeza que deseja reiniciar? (S/N):%ESC%[0m "
if /I "%confirm%"=="S" (
    echo  [ 🔁 ] Reinicialização agendada para 5 segundos...
    echo  [ 🔁 ] Reinício solicitado em %DATE% %TIME% >> "%LOGFILE%"
    shutdown /r /t 5
) else (
    echo  [ ❎ ] Reinicialização cancelada.
    echo  [ ❎ ] Reinício cancelado em %DATE% %TIME% >> "%LOGFILE%"
    timeout /t 5 >nul
)
goto :MENU
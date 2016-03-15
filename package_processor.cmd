rem @echo off

rem eleva els permisos del script per a ajudar a que l'uac no bote
set __COMPAT_LAYER=RunAsInvoker

rem habilita l'us correcte de variables en els for, if, etc
Setlocal EnableDelayedExpansion

rem estableix alguns path que necessita el sistema per funcionar
rem set path_7z_extra=F:\Programas\packetizer\fitxers_auxiliars\7z920_extra
rem set 7zCommand=7zr.exe
set path_7z_extra=F:\Programas\packetizer\fitxers_auxiliars\7z1514-extra\x64
set 7zCommand=7za.exe

set path=%path_7z_extra%;%path%;

rem estableix rutes als components
set build_files=%~dp0\fitxers_auxiliars\build_files
set config_template=%build_files%\packetizer_config_template.cfg
set software_folder_preprod=F:\DeploymentSharePreProd\Applications
set software_folder_prod=F:\DeploymentShare\Applications
set software_folder_referencia=F:\DeploymentSharePreProd\Applications
set software_folder_funcadd_proves=F:\Programas\packetizer\funcionalitats_addicionals\proves
set software_folder_funcadd_prod=F:\Programas\packetizer\funcionalitats_addicionals\prod

rem contruim els paquets de preprod
set build_dir=builds_preprod
set software_base_folder=%software_folder_preprod%

for /f "tokens=*" %%F in ('DIR /b "%build_dir%\*.flg" 2^>NUL') do (
set nom_software=%%F
set nom_software=!nom_software:~0,-4!
call :package_builder
)

rem contruim els paquets de prod
set build_dir=builds_prod
set software_base_folder=%software_folder_prod%

for /f "tokens=*" %%F in ('DIR /b "%build_dir%\*.flg" 2^>NUL') do (
set nom_software=%%F
set nom_software=!nom_software:~0,-4!
call :package_builder
)

rem contruim els paquets de referencia
set build_dir=builds_referencia
set software_base_folder=%software_folder_referencia%

for /f "tokens=*" %%F in ('DIR /b "%build_dir%\*.flg" 2^>NUL') do (
set nom_software=%%F
set nom_software=!nom_software:~0,-4!
call :package_builder
)

rem contruim els paquets de funcionalitats addicionals de proves
set build_dir=builds_funcadd_proves
set software_base_folder=%software_folder_funcadd_proves%

for /f "tokens=*" %%F in ('DIR /b "%build_dir%\*.flg" 2^>NUL') do (
set nom_software=%%F
set nom_software=!nom_software:~0,-4!
call :package_builder
)

rem contruim els paquets de funcionalitats addicionals de prod
set build_dir=builds_funcadd_prod
set software_base_folder=%software_folder_funcadd_prod%

for /f "tokens=*" %%F in ('DIR /b "%build_dir%\*.flg" 2^>NUL') do (
set nom_software=%%F
set nom_software=!nom_software:~0,-4!
call :package_builder
)

rem sortim de l'script
exit /b

:package_builder 
rem construim la ruta completa al lloc on estan els fitxers orige de l'instalador
set software_folder=%software_base_folder%\%nom_software%
if "%nom_software%" == "" (
echo Problema agafant el nom del software, abortant
exit /b -1
)
if "%software_folder%" == "" (
echo Problema construint la ruta del software, abortant
exit /b -1
)

echo.
echo Inicia construccio de !nom_software! a les !time!

rem estableix la carpeta on deixar l'instalador construit
set build_dest=%build_dir%\%nom_software%

rem crem el directori per a l'instalador automatic si es que no existeix
if not exist "%nom_software%" mkdir "%build_dest%"

rem anem al directori on deixar l'instalador 
pushd "%build_dest%"

rem esborrem el fitxers antiquats que puga haver ahi
del /q "*-v*.exe" "%nom_software%*.7z"

rem construeix el fitxer de configuracio de l'instalador automatic
set cmd_name=
for /f "tokens=*" %%F in ('DIR /b "%software_folder%" ^| find "_install.cmd"') do set cmd_name=%%F
rem nomes volem instaladors del tipus _install.cmd perque sino despres el invisible_run.vbs pot cascar
rem if "%cmd_name%" == "" for /f "tokens=*" %%F in ('DIR /b "%software_folder%" ^| find ".cmd"') do set cmd_name=%%F
if "%cmd_name%" == "" (
echo No s'ha trobat la comanda d'instalacio per a %nom_software%
popd
Goto:eof
)
type "%config_template%" >config_packet.cfg
echo RunProgram="wscript.exe invisible_run.vbs %cmd_name%" >>config_packet.cfg
echo ;^^!@InstallEnd@^^! >>config_packet.cfg

rem llegeig del corresponent fitxer package_data.txt les dades del paquet per construir el nom final de l'instalable
set pkg_arch=x86_64-
FOR /F "tokens=2 delims==" %%F IN ('type "%software_folder%\package_data.txt"^|findstr /b architecture 2^>NUL') DO set pkg_arch=%%F-
set pkg_osversion=
FOR /F "tokens=2 delims==" %%F IN ('type "%software_folder%\package_data.txt"^|findstr /b osversion 2^>NUL') DO set pkg_osversion=%%F-
set pkg_version=
FOR /F "tokens=2 delims==" %%F IN ('type "%software_folder%\package_data.txt"^|findstr /b version 2^>NUL') DO set pkg_version=-%%F

Rem Creamos el comprimido con todo el contenido de la carpeta correspondiente
cmd /c !7zCommand! a "%nom_software%.7z" "%software_folder%\*" "%build_files%\invisible_run.vbs" "%build_files%\Wbusy.exe" -m0=BCJ2 -m1=LZMA2:d25:fb255 -m2=LZMA2:d19 -m3=LZMA2:d19 -mb0:1 -mb0s1:2 -mb0s2:3 -mx 

rem crea el nom del paquet final llevant _install.cmd del cmd
if "%cmd_name:~-12%" =="_install.cmd" (
set nom_paquet=%cmd_name:~0,-12%
) else (
set nom_paquet=%nom_software%
)

rem fiquem un sfx que es corresponga amb l'arquitectura del paquet 
if "%pkg_arch%" == "x64-" (
set sfxfile=7zsd_LZMA2_x64.withUAC.sfx
) else (
set sfxfile=7zsd_LZMA2.withUAC.sfx
)

Rem Copiamos la configuracion, junto con el SFX y el comprimido
copy /b "%path_7z_extra%\%sfxfile%" + "config_packet.cfg" + "%nom_software%.7z" "%pkg_osversion%%pkg_arch%%nom_paquet%%pkg_version%-v%date:~-4%%date:~3,2%%date:~0,2%.exe"

rem signa el paquet
"F:\Programas\Windows Kits\8.1\bin\x86\signtool.exe" sign /tr http://tss.pki.gva.es:8318/tsa "%pkg_osversion%%pkg_arch%%nom_paquet%%pkg_version%-v%date:~-4%%date:~3,2%%date:~0,2%.exe"

rem esborrem el fitxer de configuracio i el 7z per a deixar nomes l'instalador automatic
del "%nom_software%.7z" "config_packet.cfg"

rem tornem al directori inicial
popd

rem esborrem el flag de control al acabar de contruir el paquet
del /q "%build_dest%.flg"

echo Finalitzada construccio de %nom_software% a les !time!

rem torna a la funcio principal
Goto:eof

:: Fix ability to reference com interlop
@echo off
:: CSC CommandLine Helper
:: Created: 03-06-2025
:: Author:  Devin Grinstead
:: Description: An interactive, but basic, CLI that allows users to complie c# classes
::              as long as a .NET Framework runtime has been installed
:: Setting Variables
:: BEGIN USER EDIT HERE
set csc_path=C:\Windows\Microsoft.NET\Framework64\v4.0.30319
set csc_lib="%csc_path%","C:\Windows\Microsoft.NET\assembly\GAC_MSIL"
set csc_lang_version=5
:: END USER EDIT HERE
setlocal
setlocal EnableDelayedExpansion
:: Adds important paths to the path variable
set PATH=%PATH%;%csc_path%
:: Prints Welcome Message
echo Welcome to CSC CommandLine Helper
echo The required dir structure is 
echo    ..^\                 - Project base directory
echo       src^\
echo          ^*.cs          - Any cs source file, can be in child directories
echo          references.txt - A newline delimited list of assembly references
echo                           System.IO
echo                           "C:\custom dll\customdll.dll"
echo                           mydll="C:\custom dll\customdll2.dll"
echo       assembly^\
echo          ^*.dll         - Assemblies to copy into output directory
echo Once your project matches the above dir structure
echo:
pause
echo:
:: Fetches the lastest version of csc.exe
if not exist "%csc_path%" ( 
	echo Unable to locate .NET Framework install
	echo Change the variable csc_path to your current install of csc.exe or
	echo make sure a 64bit version of .NET is installed
	echo Exiting Command
	goto end
) 



:: Get's the project name
set /p project_name=Enter Project name ^(outfile with extension^): 
echo:

:: Sets the project directory to the current working directory
set project_dir=%CD%
echo Current Directory is %project_dir%
set /p yesno=Do you wish to change the current directory^? ^[yes^|no^]: 
:: Tests input for yes case-insensitive
set is_y=
set is_e=
set is_s=
set is_3=
set is_yes=

if "%yesno:~0,1%"=="y" set is_y=1
if "%yesno:~0,1%"=="Y" set is_y=1
if "%yesno:~1,1%"=="e" set is_e=1
if "%yesno:~1,1%"=="E" set is_e=1
if "%yesno:~2,1%"=="s" set is_s=1
if "%yesno:~2,1%"=="S" set is_s=1
if "%yesno:~3,1%"=="" set is_3=1

set /a is_yes=%is_y%+%is_e%+%is_s%+%is_3%
:: On yes requests user for new directory
if %is_yes%==4 ( 
	echo Enter your project's base directory ^(relative paths are based on %project_dir%^)
	set /p project_dir=Directroy: 
) 
:: Exits script if project_dir does not exist
if not exist "%project_dir%" ( 
	echo Project Directory ^[%project_dir%^] NOT Found
	echo Exiting Command
	goto end
) 
echo:

:: Gets the csc.exe target type
set tar_list=exe winexe library module appcontainerexe winmdobj
set tar_found=
echo Enter your target type ^[exe^|winexe^|library^|module^|appcontainerexe^|winmdobj^]
set /p tar=Target: 
:: Validates the input against the tar_list var
for %%i in (%tar_list%) do ( 
	if "%tar%"=="%%i" ( 
		set tar_found=y
	) 
) 
:: Eixts script if not a valid target type
if not defined tar_found ( 
	echo Target Type is invalid
	echo Exiting Command
	goto end 
) 
echo:

echo Building %project_name% in %project_dir% as %tar%
:: Creates the bin directory if not found
if not exist "%project_dir%\bin" ( 
	echo Creating %project_dir%\bin
	mkdir "%project_dir%\bin"
) 
:: Copies the reference dlls into the bin directory
if exist "%project_dir%\assembly" ( 
	echo Copying assembly files
	xcopy "%project_dir%\assembly" "%project_dir%\bin" /y 
) 
:: Fetches the references list
set project_refs="mscorlib.dll","netstandard.dll"
if exist "%project_dir%\src\references.txt" ( 
	echo Fetching Project References
	
	for /f "usebackq tokens=* delims=" %%i in ("%project_dir%\src\references.txt") do ( 
		set temp_ref = %%i
		:: Checks if the reference end in .dll and adds it if it does not
		if not "%temp_ref:~-4%"==".dll" ( 
			set temp_ref=%temp_ref%.dll
		)  
		set project_refs=!project_refs!,"%temp_ref%"
	) 
) 
:: Calls the csc.exe command with the requested paramaters
csc.exe ^
	/out:"%project_dir%\bin\%project_name%" ^
	/t:%tar% ^
	/recurse:"%project_dir%\src\*.cs" ^
	/r:%project_refs% ^
	/lib:%csc_lib%,"%project_dir%\bin" ^
	/langversion:%csc_lang_version%

echo:
echo Build Sript Complete

:end
endlocal
echo Press any key to exit . . . 
pause >nul

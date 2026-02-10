!include "MUI2.nsh"

Name "WineBot Validation App"
OutFile "dist/ValidationSetup.exe"
InstallDir "$PROGRAMFILES64\WineBotValidation"
RequestExecutionLevel admin

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  
  # Install Core DLL
  File "out/ValidationCore.dll"
  
  # Install Executables
  File "out/ValidationCLI.exe"
  File "out/ValidationGUI.exe"
  
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  # Create shortcuts
  CreateShortcut "$DESKTOP\Validation GUI.lnk" "$INSTDIR\ValidationGUI.exe"
  CreateShortcut "$DESKTOP\Validation CLI.lnk" "$INSTDIR\ValidationCLI.exe"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\ValidationCore.dll"
  Delete "$INSTDIR\ValidationCLI.exe"
  Delete "$INSTDIR\ValidationGUI.exe"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$DESKTOP\Validation GUI.lnk"
  Delete "$DESKTOP\Validation CLI.lnk"
SectionEnd
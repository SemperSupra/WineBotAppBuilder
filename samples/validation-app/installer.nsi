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

  # Project binaries.
  File "out/ValidationCore.dll"
  File "out/ValidationCLI.exe"
  File "out/ValidationGUI.exe"

  # Runtime dependencies resolved from the exact MinGW toolchain by
  # tools/winbuild/build-real.sh. Keep them beside the application binaries so
  # the installed payload matches the successfully tested out/ payload.
  File "out/libgcc_s_seh-1.dll"
  File "out/libstdc++-6.dll"
  File "out/libwinpthread-1.dll"

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateShortcut "$DESKTOP\Validation GUI.lnk" "$INSTDIR\ValidationGUI.exe"
  CreateShortcut "$DESKTOP\Validation CLI.lnk" "$INSTDIR\ValidationCLI.exe"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\ValidationCore.dll"
  Delete "$INSTDIR\ValidationCLI.exe"
  Delete "$INSTDIR\ValidationGUI.exe"
  Delete "$INSTDIR\libgcc_s_seh-1.dll"
  Delete "$INSTDIR\libstdc++-6.dll"
  Delete "$INSTDIR\libwinpthread-1.dll"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$DESKTOP\Validation GUI.lnk"
  Delete "$DESKTOP\Validation CLI.lnk"
SectionEnd

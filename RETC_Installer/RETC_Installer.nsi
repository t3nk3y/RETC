
!define FILES ".\files"

!include "MUI2.nsh"
!include LogicLib.nsh
!include x64.nsh

;--------------------------------
;General

; The name of the installer
Name "RETC"

Icon "${NSISDIR}\Contrib\Graphics\Icons\nsis1-install.ico"

; The file to write
OutFile "RETC_Setup.exe"

; The default installation directory
InstallDir $PROGRAMFILES\RETC

Function .onInit
	${If} ${RunningX64} 
	   ; disable registry redirection (enable access to 64-bit portion of registry)
	   SetRegView 64
	   ; change install dir 
	   StrCpy $INSTDIR "$PROGRAMFILES64\RETC"
	${EndIf}
FunctionEnd
	
; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\RETC" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

;--------------------------------
;Variables
Var OW64Path
Var OWT64Path
Var OW32Path
Var OWT32Path

;--------------------------------
;Interface Settings
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TEXT "RETC is a piece of software that allows Corsair RGB devices to take advantage of software that supports Razr Chroma RGB devices."
!define MUI_FINISHPAGE_TEXT "Installation is complete.  Remember, RETC will only work with supported software when the RazrChroma DLL files have been placed in the software directory.  If you wish to use it with any other software, you will need to copy RzChromaSDK.dll and RzChromaSDK64.dll to that software directory as well."

;--------------------------------

; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_COMPONENTS
!insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------

; The stuff to install
Section "RETC (required)" Sec_RETC
	SectionIn RO

	; Set output path to the installation directory.
	SetOutPath $INSTDIR

	IfFileExists "$SYSDIR\RzChromaSDK.dll" rzchroma_ask
	IfFileExists "$SYSDIR\RzChromaSDK64.dll" rzchroma_ask
	${DisableX64FSRedirection}
	IfFileExists "$SYSDIR\RzChromaSDK.dll" rzchroma_ask
	IfFileExists "$SYSDIR\RzChromaSDK64.dll" rzchroma_ask
	${EnableX64FSRedirection}

	Goto nodelete_rzchroma

	rzchroma_ask:
		MessageBox MB_YESNO "Found RazrChroma DLL's in the Windows system directory.$\r$\nThese should never be put here!$\r$\n$\r$\nWould you like to remove these?" IDYES delete_rzchroma IDNO nodelete_rzchroma
	delete_rzchroma:
		Delete "$SYSDIR\RzChromaSDK.dll"
		Delete "$SYSDIR\RzChromaSDK64.dll"
		${DisableX64FSRedirection}
		Delete "$SYSDIR\RzChromaSDK.dll"
		Delete "$SYSDIR\RzChromaSDK64.dll"
		${EnableX64FSRedirection}
	nodelete_rzchroma:

	;If nssm is already installed, attempt to stop before installing
	${If} ${FileExists} "$INSTDIR\nssm.exe"
		nsExec::ExecToLog '"$INSTDIR\nssm.exe" stop RETC'
	${EndIf}
	
	${If} ${RunningX64}
		File "${FILES}\win64\retc-rpc-server-64.exe"
		File "${FILES}\win64\CUESDK.x64_2015.dll"
	${Else}
		File "${FILES}\win32\retc-rpc-server-32.exe"
		File "${FILES}\win32\CUESDK_2015.dll"
	${EndIf}
	
	File "${FILES}\win32\nssm.exe"
	File "${FILES}\win64\nssm.exe"
	File "${FILES}\win32\RzChromaSDK.dll"
	File "${FILES}\win64\RzChromaSDK64.dll"

	nsExec::ExecToLog '"$INSTDIR\nssm.exe" install RETC "$INSTDIR\retc-rpc-server-64.exe"'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC AppDirectory "$INSTDIR"'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC AppExit Default Restart'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC AppNoConsole 1'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC AppStdout "$INSTDIR\retc-server-nssm.log"'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC AppStdoutCreationDisposition 2'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC AppStderr "$INSTDIR\retc-server-nssm.log"'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC AppStderrCreationDisposition 2'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC Description "Allows programs that support the Razr Chroma SDK to use Corsair RGB devices."'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC DisplayName "RETC Service"'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC ObjectName LocalSystem'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC Start SERVICE_AUTO_START'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" set RETC Type SERVICE_WIN32_OWN_PROCESS'
	
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" start RETC'

	; Write the installation path into the registry
	WriteRegStr HKLM SOFTWARE\RETC "Install_Dir" "$INSTDIR"

	; Write the uninstall keys for Windows
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RETC" "DisplayName" "RETC"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RETC" "UninstallString" '"$INSTDIR\uninstall.exe"'
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RETC" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RETC" "NoRepair" 1
	WriteUninstaller "uninstall.exe"

SectionEnd

Section "Overwatch Support" Sec_OW

	ReadRegStr $OW64Path HKLM "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch" InstallLocation
	ReadRegStr $OWT64Path HKLM "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch Test" InstallLocation
	ReadRegStr $OW32Path HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch" InstallLocation
	ReadRegStr $OWT32Path HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch Test" InstallLocation

	; Set output path to the installation directory.
	${If} $OW64Path != ""
		SetOutPath $OW64Path
		File "${FILES}\win32\RzChromaSDK.dll"
		File "${FILES}\win64\RzChromaSDK64.dll"
	${EndIf}
	${If} $OWT64Path != ""
		SetOutPath $OWT64Path
		File "${FILES}\win32\RzChromaSDK.dll"
		File "${FILES}\win64\RzChromaSDK64.dll"
	${EndIf}
	${If} $OW32Path != ""
		SetOutPath $OW32Path
		File "${FILES}\win32\RzChromaSDK.dll"
		File "${FILES}\win64\RzChromaSDK64.dll"
	${EndIf}
	${If} $OWT32Path != ""
		SetOutPath $OWT32Path
		File "${FILES}\win32\RzChromaSDK.dll"
		File "${FILES}\win64\RzChromaSDK64.dll"
	${EndIf}

SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts" Sec_SM

	CreateDirectory "$SMPROGRAMS\RETC"
	CreateShortcut "$SMPROGRAMS\RETC\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"

	; Remove registry keys
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RETC"
	DeleteRegKey HKLM SOFTWARE\RETC
	
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" stop RETC'
	nsExec::ExecToLog '"$INSTDIR\nssm.exe" remove RETC confirm'

	; Remove files and uninstaller
	Delete "$INSTDIR\*.*"

	; Remove shortcuts, if any
	Delete "$SMPROGRAMS\RETC\*.*"

	; Remove directories used
	RMDir "$SMPROGRAMS\RETC"
	RMDir "$INSTDIR"

SectionEnd

Section "un.Remove Overwatch Support Files" unSec_OW

	ReadRegStr $OW64Path HKLM "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch" InstallLocation
	ReadRegStr $OWT64Path HKLM "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch Test" InstallLocation
	ReadRegStr $OW32Path HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch" InstallLocation
	ReadRegStr $OWT32Path HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch Test" InstallLocation

	; Set output path to the installation directory.
	${If} $OW64Path != ""
		Delete "$OW64Path\RzChromaSDK.dll"
		Delete "$OW64Path\RzChromaSDK64.dll"
	${EndIf}
	${If} $OWT64Path != ""
		Delete "$OWT64Path\RzChromaSDK.dll"
		Delete "$OWT64Path\RzChromaSDK64.dll"
	${EndIf}
	${If} $OW32Path != ""
		Delete "$OW32Path\RzChromaSDK.dll"
		Delete "$OW32Path\RzChromaSDK64.dll"
	${EndIf}
	${If} $OWT32Path != ""
		Delete "$OWT32Path\RzChromaSDK.dll"
		Delete "$OWT32Path\RzChromaSDK64.dll"
	${EndIf}

SectionEnd


LangString DESC_Sec_RETC ${LANG_ENGLISH} "The main RETC service files, as well as the RETC service."
LangString DESC_Sec_OW ${LANG_ENGLISH} "This will copy the Razr Chroma DLL files to any Overwatch installations that are found."
LangString DESC_Sec_SM ${LANG_ENGLISH} "Install start menu shortcuts"
LangString DESC_Un_Sec_OW ${LANG_ENGLISH} "Remove Razr Chroma DLL files from any Overwatch installations that are found."


!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${Sec_RETC} $(DESC_Sec_RETC)
	!insertmacro MUI_DESCRIPTION_TEXT ${Sec_OW} $(DESC_Sec_OW)
	!insertmacro MUI_DESCRIPTION_TEXT ${Sec_SM} $(DESC_Sec_SM)
	!insertmacro MUI_DESCRIPTION_TEXT ${Sec_OW} $(DESC_Un_Sec_OW)
!insertmacro MUI_FUNCTION_DESCRIPTION_END
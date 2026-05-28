[Setup]
; Informations de l'application
AppName=Contrôle Pharma
AppVersion=1.0.0
AppPublisher=ControlPharma
AppPublisherURL=https://controlpharma.com
DefaultDirName={autopf}\ControlePharma
DefaultGroupName=Contrôle Pharma
DisableProgramGroupPage=yes
OutputDir=c:\controle_pharma\installer_output
OutputBaseFilename=ControlePharma_Setup_v1.0.0
SetupIconFile=c:\controle_pharma\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\controle_pharma.exe

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; GroupDescription: "Raccourcis:"

[Files]
; Copier tout le contenu du dossier Release
Source: "c:\controle_pharma\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Contrôle Pharma"; Filename: "{app}\controle_pharma.exe"
Name: "{group}\Désinstaller Contrôle Pharma"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Contrôle Pharma"; Filename: "{app}\controle_pharma.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\controle_pharma.exe"; Description: "Lancer Contrôle Pharma"; Flags: nowait postinstall skipifsilent

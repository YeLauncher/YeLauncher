[Setup]
; Basic App Info
AppName=YeLauncher
AppVersion=1.0.0
AppPublisher=YeLauncher
AppPublisherURL=https://yelauncher.com
DefaultDirName={autopf}\YeLauncher
DisableProgramGroupPage=yes

; Output settings
OutputDir=Output
OutputBaseFilename=yelauncher-setup
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

; This requires admin privileges to install into Program Files
PrivilegesRequired=admin

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The main executable
Source: "build\windows\x64\runner\Release\yelauncher.exe"; DestDir: "{app}"; Flags: ignoreversion

; All other DLLs and the data folder required by Flutter
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\YeLauncher"; Filename: "{app}\yelauncher.exe"
Name: "{autodesktop}\YeLauncher"; Filename: "{app}\yelauncher.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\yelauncher.exe"; Description: "{cm:LaunchProgram,YeLauncher}"; Flags: nowait postinstall skipifsilent

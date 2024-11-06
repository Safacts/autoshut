[Setup]
AppName=AutoShut
AppVersion=1.0
DefaultDirName={commonpf}\AutoShut
DefaultGroupName=AutoShut
OutputBaseFilename=AutoShutInstaller
Compression=lzma
SolidCompression=yes

[Files]
Source: "C:\autoshut\git\autoshut\build\windows\x64\runner\Release\autoshut.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\autoshut\git\autoshut\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\autoshut\git\autoshut\build\windows\x64\runner\Release\data\icudtl.dat"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\autoshut\git\autoshut\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs
;Source: "C:\autoshut\git\autoshut\build\windows\x64\runner\Release\plugins\*"; DestDir: "{app}\plugins"; Flags: ignoreversion recursesubdirs
Source: "C:\autoshut\git\autoshut\dist\idle_server.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\AutoShut"; Filename: "{app}\autoshut.exe"

[Run]
Filename: "{app}\autoshut.exe"; Description: "{cm:LaunchProgram,AutoShut}"; Flags: nowait postinstall skipifsilent

[Setup]
AppName=YouTube Downloader by StormGamesStudios
AppVersion=1.0.5
DefaultDirName={userappdata}\StormGamesStudios\Programs\YouTubeDownloader
DefaultGroupName=StormGamesStudios
OutputDir=C:\Users\melio\Documents\GitHub\youtube-downloader\output
OutputBaseFilename=YouTubeDownloader_Launcher_Installer
Compression=lzma
SolidCompression=yes
AppCopyright=Copyright © 2025 StormGamesStudios. All rights reserved.
VersionInfoCompany=StormGamesStudios
AppPublisher=StormGamesStudios
SetupIconFile=youtube-downloader.ico
VersionInfoVersion=1.0.5.0
DisableProgramGroupPage=yes
; Habilitar selección de carpeta
DisableDirPage=yes

[Files]
Source: "C:\Users\melio\Documents\GitHub\youtube-downloader\YoutubeDownloader\*"; DestDir: "{app}\YoutubeDownloader"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\Users\melio\Documents\GitHub\youtube-downloader\youtube-downloader.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\melio\Documents\GitHub\youtube-downloader\youtube-downloader.png"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{commonprograms}\StormGamesStudios\YouTube Downloader"; Filename: "{app}\YoutubeDownloader\YoutubeDownloader.exe"; IconFilename: "{app}\youtube-downloader.ico"; Comment: "Lanzador de YouTube Downloader"; WorkingDir: "{app}\YoutubeDownloader"
Name: "{commonprograms}\StormGamesStudios\Desinstalar YouTube Downloader"; Filename: "{uninstallexe}"; IconFilename: "{app}\youtube-downloader.ico"; Comment: "Desinstalar YouTube Downloader"

[Registry]
Root: HKCU; Subkey: "Software\YouTube Downloader"; ValueType: string; ValueName: "Install_Dir"; ValueData: "{app}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Run]
Filename: "{app}\YoutubeDownloader\YoutubeDownloader.exe"; Description: "Ejecutar YouTube Downloader"; Flags: nowait postinstall skipifsilent

[Code]
function IsDirectoryEmpty(DirPath: String): Boolean;
var
  FindRec: TFindRec;
begin
  Result := True;
  if DirExists(DirPath) then
  begin
    if FindFirst(DirPath + '\*', FindRec) then
    begin
      try
        repeat
          if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
          begin
            Result := False;
            Break;
          end;
        until not FindNext(FindRec);
      finally
        FindClose(FindRec);
      end;
    end;
  end;
end;

procedure RunUninstaller(DirPath: String);
var
  FindRec: TFindRec;
  ResultCode: Integer;
  Attempts: Integer;
begin
  if DirExists(DirPath) then
  begin
    // Busca cualquier archivo que coincida con unins*.exe (unins000.exe, unins001.exe, etc.)
    if FindFirst(DirPath + '\unins*.exe', FindRec) then
    begin
      try
        repeat
          // Ejecutar el desinstalador de forma muy silenciosa y esperar a que termine
          Exec(DirPath + '\' + FindRec.Name, '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
        until not FindNext(FindRec);
      finally
        FindClose(FindRec);
      end;
    end;

    // Esperar hasta que la carpeta esté vacía (máximo 5 segundos de espera activa)
    Attempts := 0;
    while (not IsDirectoryEmpty(DirPath)) and (Attempts < 10) do
    begin
      Sleep(500); // Esperar 500ms antes de volver a comprobar
      Attempts := Attempts + 1;
      
      // Intentar borrar lo que quede (por si son archivos de log o restos que el desinstalador no quitó)
      if Attempts > 5 then
      begin
        DelTree(DirPath, True, True, True);
      end;
    end;
  end;
end;

procedure UninstallOldVersion();
begin
  // 1. Revisar la ruta de la versión anterior específica
  RunUninstaller(ExpandConstant('{userappdata}\StormGamesStudios\Programs\YouTubeDownloader'));
  
  // 2. Revisar la ruta donde se va a instalar actualmente (por si es una reinstalación/actualización)
  RunUninstaller(ExpandConstant('{app}'));
end;

procedure CloseApp();
var
  ResultCode: Integer;
begin
  // Cierra el actualizador y el launcher si están abiertos
  Exec('taskkill', '/F /IM installer_updater.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('taskkill', '/F /IM win_launcher.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('taskkill', '/F /IM "YoutubeDownloader.exe"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // Durante la instalación, cierra cualquier instancia abierta
  if CurStep = ssInstall then
  begin
    CloseApp();
    UninstallOldVersion();
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  // Durante la desinstalación, cierra cualquier instancia abierta
  if CurUninstallStep = usUninstall then
  begin
    CloseApp();
  end;
end;
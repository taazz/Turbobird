unit utbConfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Graphics, Forms, typinfo, turbocommon, FileUtil, uTBTypes;

const
  cQuerySection = 'SQL Editor';

function ToString  (aStyles:TFontStyles):string; overload;
function ToString  (aColor:TColor):string;overload;
function FromString(aCSV:string):TFontStyles; overload;

function FromString(aValue:string):TColor;overload;

procedure IniLoadData(const aSection:string; const aFont:TFont);overload;
//procedure IniLoadData(const aSection:string; const aFont:TFont);overload;
procedure IniSaveData(const aSection:String; const aFont:TFont);overload;

//the directory where the configuration files are kept.
function GetConfigurationDirectory :string;
// the file name where the application settings are saved (ini).
function GetConfigFileName :String;
//The file name where the database registration information are kept.
function GetRegistryFileName:String;
//encrypt the saved passwords using the password returneds from this function.
function GetEncryptionPassword:string; experimental;
//Salt is never the same, once a password is given the salt is encrypted
//with the password and saved in the file the database passwords are encrypted
//with the password + salt
function NewSalt:TByteArray;unimplemented;

implementation
const
  cCfgExt = '.cfg';

function GetRegistryFileName :String;
begin
  if turbocommon.IsWindows then begin
    Result := ExtractFileNameOnly(Application.ExeName);
  end else begin
    Result := ExtractFileNameOnly(ParamStr(0));
  end;
  ChangeFileExt(Result,'.reg');
end;

function GetEncryptionPassword:string;
begin
  {$IFDEF LINUX}
  Result := GetEnvironmentVariable('HOSTName');
  {$ELSE}
  Result := GetEnvironmentVariable('ComputerName');
  {$ENDIF}
  {$IFDEF USER_SPECIFIC}
    Result := Result + '.'+GetEnvironmentVariable('USER');
  {$ENDIF}
end;

function NewSalt :TByteArray;
begin

end;

function ToString(aStyles:TFontStyles):string; overload;
var
  vStyle :TFontStyle;
begin
  Result := '';
  for vStyle in aStyles do begin
    Result := Result + GetEnumName(TypeInfo(TFontStyle), Integer(vStyle))+',';
  end;
  SetLength(Result, Length(Result)-1);//delete the last comma in the text;
end;

function GetConfigurationDirectory :string;
begin
  if turbocommon.IsWindows then begin
    if FileExists(ChangeFileExt(application.ExeName,'.cfg')) then begin //portable installation.
      Result := IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName));
      Exit;
    end;
  end;
  Result := IncludeTrailingPathDelimiter(SysUtils.GetAppConfigDir(False));
  if not DirectoryExists(Result) then ForceDirectories(Result);
end;

function ToString(aColor :TColor) :string;
begin
  Result := ColorToString(aColor);
end;

function FromString(aCSV:string):TFontStyles; overload;
var
  vList :TStringList;
  vCntr :Integer;
begin
  vList := TStringList.Create;
  try
    vList.CommaText := aCSV;
    Result := [];
    for vCntr := 0 to vList.Count -1 do begin
      Include(Result, TFontStyle(GetEnumValue(TypeInfo(TFontStyle), vList[vCntr])));
    end;
  finally
    vList.Free;;
  end;
end;

function GetConfigFileName :String;
begin
  if turbocommon.IsWindows then begin
    Result := ChangeFileExt(ExtractFileNameOnly(Application.ExeName),cCfgExt)
  end else
    //Result := Application.Name+'.cfg';
    //use existing code.
    Result := ChangeFileExt(ExtractFileNameOnly(ParamStr(0)),cCfgExt);
end;

function FromString(aValue :string) : TColor;
begin
  Result := StringToColor(aValue);
end;

procedure IniLoadData(const aSection:string; const aFont:TFont);
var
  vConfigFile : TIniFile;
begin
  vConfigFile := TIniFile.Create(GetConfigFileName);
  try
    aFont.Name  := vConfigFile.ReadString (aSection, 'Font_Name', 'monospace');
    aFont.Size  := vConfigFile.ReadInteger(aSection, 'Font_Size', 10);
    aFont.style := FromString(vConfigFile.ReadString(aSection, 'Font_Style', ''));
  finally
    vConfigFile.Free;
  end;
end;

procedure IniSaveData(const aSection:String; const aFont:TFont);
var
  vConfigFile : TIniFile;
begin
  vConfigFile := TIniFile.Create(GetConfigFileName);
  try
    vConfigFile.WriteString (aSection, 'Font_Name' , aFont.Name);
    vConfigFile.WriteInteger(aSection, 'Font_Size' , aFont.Size);
    vConfigFile.WriteString (aSection, 'Font_Style', ToString(aFont.Style));
  finally
    vConfigFile.Free;
  end;
end;

end.


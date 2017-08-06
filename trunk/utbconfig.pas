unit utbConfig;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Graphics, Forms, typinfo, utbcommon, FileUtil, uTBTypes;

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
function GetEncryptionPassword(aLocal:Boolean =False) :string; experimental;
//Salt is never the same, once a password is given the salt is encrypted
//with the password and saved in the file the database passwords are encrypted
//with the password + salt
function NewSalt:TByteArray;unimplemented;

implementation
const
  cCfgExt = '.cfg';
  cRegExt = '.Reg';

function GetRegistryFileName :String;
begin
  if utbcommon.IsWindows then begin
    Result := ExtractFileNameOnly(Application.ExeName);
  end else begin
    Result := ExtractFileNameOnly(ParamStr(0));
  end;
  if ExtractFileExt(Result) <> '' then
    ChangeFileExt(Result,'.reg')
  else Result := Result + cRegExt;
end;

function GetEncryptionPassword(aLocal:Boolean =False) :string;
begin
  {$IFDEF LINUX}
  Result := GetEnvironmentVariable('HOSTName');
  {$ELSE}
  Result := GetEnvironmentVariable('ComputerName');
  {$ENDIF}
  if aLocal then begin
      Result := Result + '.'+GetEnvironmentVariable('USER');
  end;
end;

function NewSalt :TByteArray;
begin
  SetLength(Result, 0);
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

function ExcludeLeadingCliSeperators(Const Path: string): string;
const
  KnownCliSeperators:Set of char =['-',{$IFDEF WINDOWS}'/'{$ELSE}'\'{$ENDIF},':'];
Var
  vIdx :Integer;
begin
  Result := Path;
  vIdx := 0; //L := Length(Result);
  repeat
    Inc(vIdx);
  until (not(Result[vIdx] in KnownCliSeperators)) or (vIdx>Length(Path));
  if (vIdx > 1) and (vIdx <= Length(Path)) then Result := Copy(Path, vIdx, Length(Path));
end;

function IsPortable:Boolean;
var
  vCntr :Integer;
  vParam:String;
begin
  Result := FileExists(ChangeFileExt(Application.ExeName,'.cfg'));
  if Result then Exit;
  if Paramcount >= 1 then begin
    for vCntr := 1 to Paramcount do begin
      vParam := ExcludeLeadingCliSeperators(ParamStr(vCntr));
      if (CompareText(vParam, 'P') = 0) or (CompareText(vParam, 'portable')= 0) then Exit(True);
    end;
  end;
end;

function GetConfigurationDirectory :string;
begin
  if utbcommon.IsWindows then begin
    if IsPortable then begin //portable installation.
      Exit(IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName)));
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
  if utbcommon.IsWindows then begin
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

Function DoVendorName:String;
begin
  Result := 'Evosi';
end;


initialization
  OnGetVendorName := DoVendorName;
end.


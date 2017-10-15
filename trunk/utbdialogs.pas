unit uTbDialogs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Dialogs, uEvsDBSchema, uTBTypes, uTbToArray, uTBCommon, ufrFontEditor, uEvsFrameDialog, Forms, Graphics;

Function RegisterDatabase(const aDatabase: IEvsDatabaseInfo):word;
Function CreateDatabase(var aDatabase: IEvsDatabaseInfo):word;
//empty result means the user canceled, otherwise it will return all the files the user selected.
Function OpenFiles(const aFilter:String; const StartupDir:String;const MultiSelect:Boolean=False):TStringArray;
Function Login(const aDB:IEvsDatabaseInfo):Boolean;
Function ShowInfo(const Caption,Message:String; aButtons:TMsgDlgButtons=[mbOK]):TModalResult;
Function ShowInfoFmt(const Caption,Message:string; aParams:Array of const; aButtons:TMsgDlgButtons=[mbOK]):TModalResult;
Function ShowError(const Caption,Message:String; aButtons:TMsgDlgButtons=[mbOK]):TModalResult;
Function GetConfirmation(const Caption, Message:String; aButtons:TMsgDlgButtons=[mbYes,mbNo]):TModalResult;
//Function GetCredentials(const aDB:IEvsDatabaseInfo):Boolean;
Function BackupDB(const aDB:IEvsDatabaseInfo):Integer;
Function RestoreDB(var aDB:IEvsDatabaseInfo):Integer;
Function SelectFont(const aFont:TFont):Integer;

implementation

uses uDBDetails, uLoginForm, uEvsBackupRestore, ButtonPanel;

Function RegisterDatabase(const aDatabase :IEvsDatabaseInfo) :word;
var
  vFrm :TDBDetailsForm;
begin
  vFrm := TDBDetailsForm.Create(nil);
  try
    vFrm.DB := aDatabase;
    Result := vFrm.ShowModal;
  finally
    vFrm.Free;
  end;
end;

Function CreateDatabase(var aDatabase :IEvsDatabaseInfo) :word;
var
  vFrm :TDBDetailsForm;
begin
  vFrm := TDBDetailsForm.Create(nil);
  try
    vFrm.DB := aDatabase;
    vFrm.CreateDB := True;
    Result := vFrm.ShowModal;
  finally
    vFrm.Free;
  end;
end;

Function OpenFiles(const aFilter :String; const StartupDir :String; const MultiSelect :Boolean) :TStringArray;
var
  vDlg:TOpenDialog;
begin
  SetLength(Result,0);
  vDlg := TOpenDialog.Create(Nil);
  try
    vDlg.Filter := aFilter;
    if StartupDir <> '' then
      vDlg.FileName := StartupDir;
    if MultiSelect then vDlg.Options := vDlg.Options + [ofAllowMultiSelect];
    if vDlg.Execute then begin
      if MultiSelect then begin
        Result := ToArray(vDlg.Files);
      end else begin
        SetLength(Result,1);
        Result[0] := vDlg.FileName;
      end;
    end;
  finally
    vDlg.Free;
  end;
end;

Function Login(const aDB :IEvsDatabaseInfo) :Boolean;
var
  vFrm:uLoginForm.TLoginForm;
begin
  vFrm := TLoginForm.Create(Nil);
  try
    if vFrm.Execute(aDB, aDB.Credentials.UserName, aDB.Credentials.Password, aDB.Credentials.Role) = mrOK then begin
      aDB.Credentials.UserName := vFrm.UserName;
      aDB.Credentials.Password := vFrm.Password;
      aDB.Credentials.Role     := vFrm.Role;
      Result := Assigned(aDB.Connection);
    end;
  finally
    vFrm.Free;
  end;
end;

Function ShowInfo(const Caption, Message :String; aButtons :TMsgDlgButtons=[mbOK]) :TModalResult;
begin
  Result := MessageDlg(Caption, Message, mtInformation, aButtons, 0);
end;

Function ShowInfoFmt(const Caption, Message :string; aParams :Array of const; aButtons :TMsgDlgButtons) :TModalResult;
begin
  Result := ShowInfo(Caption,Format(Message,aParams), aButtons);
end;

Function ShowError(const Caption, Message :String; aButtons :TMsgDlgButtons=[mbOK]) :TModalResult;
begin
  Result := MessageDlg(Caption, Message, mtError, aButtons, 0);
end;

Function GetConfirmation(const Caption, Message :String; aButtons :TMsgDlgButtons=[mbYes,mbNo]) :TModalResult;
begin
  Result := MessageDlg(Caption, Message, mtConfirmation, aButtons, 0);
end;

//Function GetCredentials(const aDB :IEvsDatabaseInfo) :Boolean;
//var
//  vFrm :TLoginForm;
//begin
//  Result := False;
//  raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
//end;

Function BackupDB(const aDB :IEvsDatabaseInfo) :Integer;
var
  vFrm : TBackupRestoreForm;
begin
  vFrm := TBackupRestoreForm.Create(Nil);
  try
    vFrm.Restore        := False;
    vFrm.Database       := aDB;
    vFrm.AllowDBChanges := (aDB = nil);
    Result := vFrm.ShowModal;
  finally
    vFrm.Free;
  end;
end;

Function RestoreDB(var aDB :IEvsDatabaseInfo) :Integer;
var
  vFrm : TBackupRestoreForm;
  vTmp : IEvsDatabaseInfo;
begin
  vFrm := TBackupRestoreForm.Create(Nil);
  try
    if Assigned(aDB) then vTmp := aDB else vTmp := NewDatabase(stFirebird);
    vFrm.Restore := True;
    vFrm.Database := vTmp;
    vFrm.AllowDBChanges := (aDB = nil);
    Result := vFrm.ShowModal;
    if (Result = mrOK) and (aDB = nil) then aDB := vTmp;
  finally
    vFrm.Free;
  end;
end;

Function SelectFont(const aFont:TFont):Integer;
var
  vFrm       :TEvsFrameDialog;
  vFont      :TFont;
  vFontFrame :TEvsFontEditFrame;
begin
  vFrm := TEvsFrameDialog.Create(Nil);
  try
    vFrm.BorderStyle := bsDialog;
    vFontFrame := TEvsFontEditFrame.Create(Nil);
    try
      vFontFrame.Top := 0;
      vFontFrame.Left := 0;
      vFontFrame.Parent := vFrm;
      vFontFrame.EditFont := aFont;
      vFrm.Height := vFontFrame.Height+vFrm.ButtonPanel1.Height + 4;
      vFrm.Height := vFontFrame.Width +2;
      Result := vFrm.ShowModal;
      if Result = mrOK then begin
        vFont := vFontFrame.EditFont; //execute the ScreenToObject
      end;
    finally
      vFontFrame.Free;
    end;
  finally
    vFrm.Free;
  end;
end;

end.


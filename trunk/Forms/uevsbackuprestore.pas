unit uEvsBackupRestore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, Buttons, uUserLoginFrame,
  ufrDatabaseEdit, uEvsDBSchema, uTBTypes, uTBCommon, uDMMain;

type

  { TBackupRestoreForm }

  TBackupRestoreForm = class(TForm)
    BitBtn1 :TBitBtn;
    BitBtn2 :TBitBtn;
    BitBtn3 :TBitBtn;
    DatabaseEditorFrame1 :TDatabaseEditorFrame;
    edtFilename :TEdit;
    imgBackup :TImage;
    imgRestore :TImage;
    Label1 :TLabel;
    Panel1 :TPanel;
    Panel2 :TPanel;
    SpeedButton1 :TSpeedButton;
    UserLoginFrame1 :TUserLoginFrame;
    procedure BitBtn2Click(Sender :TObject);
    procedure SpeedButton1Click(Sender :TObject);
  private
    { private declarations }
    FDB:IEvsDatabaseInfo;
    FRestore :Boolean;
    function GetAllowDBChanges :Boolean;
    function GetDatabase :IEvsDatabaseInfo;
    function GetFileName :String;
    procedure SetAllowDBChanges(aValue :Boolean);
    procedure SetDatabase(aValue :IEvsDatabaseInfo);
    procedure SetFileName(aValue :String);
    procedure SetRstore(aValue :Boolean);
    procedure FromScreen;
    procedure ToScreen;
    Procedure Clear;
  public
    { public declarations }
    destructor Destroy; override;
    property Database:IEvsDatabaseInfo read GetDatabase write SetDatabase;
    Property Restore :Boolean read FRestore write SetRstore;
    property FileName:String read GetFileName write SetFileName;
    property AllowDBChanges:Boolean read GetAllowDBChanges write SetAllowDBChanges;
  end;

implementation
uses uTbDialogs;
{$R *.lfm}

{ TBackupRestoreForm }

procedure TBackupRestoreForm.BitBtn2Click(Sender :TObject);
begin
  Screen.Cursor := crSQLWait;
  try
    FromScreen;
    if FRestore then dmMain.RestoreDatabase(FDB, FileName)
    else             dmMain.BackupDatabase (FDB, FileName);
    ModalResult := mrOK;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TBackupRestoreForm.SpeedButton1Click(Sender :TObject);
var
  vFilename:TStringArray;
begin
  vFilename := uTbDialogs.OpenFiles('*.*','',False);
  FileName := vFilename[0];
end;

function TBackupRestoreForm.GetDatabase :IEvsDatabaseInfo;
begin
  Result := FDB;
end;

function TBackupRestoreForm.GetAllowDBChanges :Boolean;
begin
  Result := DatabaseEditorFrame1.Enabled;
end;

function TBackupRestoreForm.GetFileName :String;
begin
  Result := edtFilename.Text;
end;

procedure TBackupRestoreForm.SetAllowDBChanges(aValue :Boolean);
begin
  DatabaseEditorFrame1.Enabled := aValue;
end;

procedure TBackupRestoreForm.SetDatabase(aValue :IEvsDatabaseInfo);
begin
  FDB := aValue;
  Clear;
  ToScreen;
end;

procedure TBackupRestoreForm.SetFileName(aValue :String);
begin
  edtFilename.Text:= aValue;
end;

procedure TBackupRestoreForm.SetRstore(aValue :Boolean);
begin
  if FRestore=aValue then Exit;
  FRestore:=aValue;
  if FRestore then begin
    imgBackup.Visible := False;
    imgRestore.Visible := True;
    imgRestore.Align := alLeft;
  end else begin
    imgBackup.Visible := True;
    imgBackup.Align   := alLeft;
    imgRestore.Visible := False;
  end;
end;

procedure TBackupRestoreForm.FromScreen;
begin
  FDB.Database := DatabaseEditorFrame1.FullDBName;
  FDB.Credentials.UserName := UserLoginFrame1.UserName;
  FDB.Credentials.Password := UserLoginFrame1.Password;
  FDB.Credentials.Role     := UserLoginFrame1.Role;
end;

procedure TBackupRestoreForm.ToScreen;
begin
  DatabaseEditorFrame1.FullDBName := FullDBName(FDB);
  UserLoginFrame1.UserName := FDB.Credentials.UserName;
  UserLoginFrame1.Password := FDB.Credentials.Password;
  UserLoginFrame1.Role     := FDB.Credentials.Role;
end;

Procedure TBackupRestoreForm.Clear;
begin
  DatabaseEditorFrame1.DatabaseName :='';
  DatabaseEditorFrame1.Host         :='';
  DatabaseEditorFrame1.Port         :='';
  UserLoginFrame1.UserName := '';
  UserLoginFrame1.Password := '';
  UserLoginFrame1.Role     := '';
end;

destructor TBackupRestoreForm.Destroy;
var
  vClass:TClass;
begin
  FDB := nil;
  inherited Destroy;
end;

end.


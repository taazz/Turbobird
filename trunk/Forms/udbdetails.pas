unit uDBDetails;

{$mode objfpc}{$H+}
{$I EvsDefs.inc}
interface
{ TODO -oJKOZ -cMetadata upgrade : Add support for Collation selection. }
{ TODO -oJKOZ -cMetadata upgrade : Add support for page size }
{ TODO -oJKOZ -cMetadata upgrade : Add support for multiple files }
uses
  Classes, SysUtils, IBConnection, FileUtil, Forms, Controls, sqldb,
  Graphics, Dialogs, StdCtrls, Buttons, ExtCtrls, Spin, MDODatabase, MDOQuery, MDO,
  uTBTypes, utbConfig, utbcommon, uEvsDBSchema, ufrDatabaseEdit, uUserLoginFrame;
{ TODO -oJKOZ -cUser Expirience : Retreive the database default characterset during registration.(The button is
  in place write the code to go with it and make it visible). }
type

  { TDBDetailsForm }

  TDBDetailsForm = class(TForm)
    bbCancel :TBitBtn;
    bbReg :TBitBtn;
    bbTest :TBitBtn;
    BitBtn1 :TBitBtn;
    cbCharset :TComboBox;
    cmbCollation :TComboBox;
    cmbPageSize :TComboBox;
    cxSavePassword :TCheckBox;
    DatabaseEditorFr :TDatabaseEditorFrame;
    edTitle :TEdit;
    Image1 :TImage;
    Connection     :TMDODatabase;
    Label4 :TLabel;
    Label5 :TLabel;
    Label7 :TLabel;
    lblPageSize :TLabel;
    OpenDialog1    :TOpenDialog;
    Panel1 :TPanel;
    Panel2 :TPanel;
    Panel3 :TPanel;
    Panel4 :TPanel;
    Panel5 :TPanel;
    pnlDBTitle :TPanel;
    Panel6 :TPanel;
    UserLoginFr :TUserLoginFrame;
    procedure bbRegClick(Sender: TObject);
    procedure bbTestClick(Sender: TObject);
    procedure BitBtn1Click(Sender :TObject);
    procedure btBrowseClick(Sender: TObject);
    procedure cbCharsetChange(Sender :TObject);
    procedure cbCharsetCloseUp(Sender :TObject);
    procedure cbCharsetEditingDone(Sender :TObject);

  private
    { private declarations }
    FDBInfo     :IEvsDatabaseInfo;
    FCreateDB   :Boolean;
    FServerType :Integer;
    function GetCharSet :string;
    function GetCollation :string;
    function GetDBInfo :IEvsDatabaseInfo;
    function GetDBName :string;
    function GetHost :string;
    function GetPageSize :Integer;
    function GetPassword :string;
    function GetRole :string;
    function GetSavePwd :Boolean;
    function GetServerType :Integer;
    function GetTitle :string;
    function GetUserName :string;
    procedure SetCharset(aValue :string);
    procedure SetCollation(aValue :string);
    procedure SetDBInfo(aValue :IEvsDatabaseInfo);
    procedure SetDBName(aValue :string);
    procedure SetHost(aValue :string);
    procedure SetCreateDB(aValue :Boolean);
    procedure SetPageSize(aValue :Integer);
    procedure SetPassword(aValue :string);
    procedure SetRole(aValue :string);
    procedure SetSavePwd(aValue :Boolean);
    procedure SetServerType(aValue :Integer);
    procedure SetTitle(aValue :string);
    procedure SetUserName(aValue :string);
  protected
    procedure ToScreen(const aDB:IEvsDatabaseInfo);
    procedure FromScreen(const aDB:IEvsDatabaseInfo);
    procedure SetupForCreation(Creation:Boolean = True);
  public
    { public declarations }
    constructor Create(aOwner :TComponent); override;
    procedure ValidateData;
    function TestConnection(DatabaseName, UserName, Password, Role, Charset :string) :Boolean;
    function GetDefaultCharSet:string;
    //database properties.
    property DatabaseName  :string  read GetDBName    write SetDBName;
    property Host          :string  read GetHost      write SetHost;
    property UserName      :string  read GetUserName  write SetUserName;
    property Password      :string  read GetPassword  write SetPassword;
    property Charset       :string  read GetCharSet   write SetCharset;
    property Collation     :string  read GetCollation write SetCollation;
    property Role          :string  read GetRole      write SetRole;
    property Title         :string  read GetTitle     write SetTitle;
    property SavePassword  :Boolean read GetSavePwd   write SetSavePwd;
    property PageSize      :Integer read GetPageSize  write SetPageSize;
    Property CreateDB      :Boolean read FCreateDB    write SetCreateDB;//if true the dialog is used to create a database find a way to select page size.
    PRoperty ServerType    :Integer read GetServerType write SetServerType;
    Property DB   :IEvsDatabaseInfo read GetDBInfo    write SetDBInfo;
  end;

var
  DBDetailsForm: TDBDetailsForm;

implementation

uses uTbDialogs;

  {$R *.lfm}
{ TDBDetailsForm }


procedure TDBDetailsForm.bbRegClick(Sender: TObject);
begin
  if Trim(edTitle.Text) = '' then
    ShowMessage('You should fill all fields')
  else
  if FCreateDB then  begin// New registration
    ValidateData;
    FromScreen(FDBInfo);
  end else
    if TestConnection(DatabaseName , UserName, Password, Role, Charset) then FromScreen(FDBInfo);
  ModalResult := mrOK;
end;

procedure TDBDetailsForm.bbTestClick(Sender: TObject);
begin
  if TestConnection(DatabaseName, UserName, Password, Role, Charset) then
    ShowMessage('Connected successfully');
end;

procedure TDBDetailsForm.BitBtn1Click(Sender :TObject);
//var
//  vTest :String;
  //vIdx  :Integer;
begin
  //vTest := GetDefaultCharSet;
  //vIdx  := cbCharset.Items.IndexOf(Trim(vTest));
  //cbCharset.Text := vTest;
  //cbCharset.ItemIndex := vIdx;
  cbCharset.Text := GetDefaultCharSet;
  if cbCharset.Text = '' then cbCharset.Text := 'NONE';
end;

procedure TDBDetailsForm.btBrowseClick(Sender: TObject);
begin
  //if OpenDialog1.Execute then
  //  fr DatabaseName := OpenDialog1.FileName;
end;

procedure TDBDetailsForm.cbCharsetChange(Sender :TObject);
var
  vColl:TWideStringArray;
begin
  if cbCharset.ItemIndex > -1 then begin
    vColl := Collations(cbCharset.Text, FServerType);
    cmbCollation.Items.Clear;
    //cmbCollation.Items.Add('NONE');
    ToStrings(vColl,cmbCollation.Items);
  end;
end;

procedure TDBDetailsForm.cbCharsetCloseUp(Sender :TObject);
var
  vColl:TWideStringArray;
begin
  if cbCharset.ItemIndex > -1 then begin
    vColl := Collations(cbCharset.Text, FServerType);
    cmbCollation.Items.Clear;
    //cmbCollation.Items.Add('NONE');
    ToStrings(vColl,cmbCollation.Items);
  end;
end;

procedure TDBDetailsForm.cbCharsetEditingDone(Sender :TObject);
var
  vColl:TWideStringArray;
begin
  if cbCharset.ItemIndex > 0 then begin
    vColl := Collations(cbCharset.Text, FServerType);
    cmbCollation.Items.Clear;
    //cmbCollation.Items.Add('NONE');
    ToStrings(vColl,cmbCollation.Items);
  end;
end;

procedure WriteString(aDest:TStream; aValue:String);overload;
var
  vWriter:TWriter;
begin
  vWriter := TWriter.Create(aDest,1024);
  with TWriter.Create(aDest,1024) do
    try
      vWriter.WriteString(aValue);
    finally
      Free;
    end;
end;

procedure WriteString(aDest:TStream; aValue:WideString);overload;
var
  vWriter:TWriter;
begin
  vWriter := TWriter.Create(aDest,1024);
  with TWriter.Create(aDest,1024) do
  try
    vWriter.WriteString(aValue);
  finally
    Free;
  end;
end;

procedure TDBDetailsForm.SetupForCreation(Creation :Boolean);
begin
  { TODO -oJKOZ -cUser Interface : Code to hide/show editors as needed for database creation or registration. }
  if Creation then begin
    Panel4.Visible := True;
    Panel4.Top     := DatabaseEditorFr.Top+DatabaseEditorFr.Height-1;
    Title := 'New database';
    bbReg.Caption := 'Create';
  end else begin
    Panel4.Visible := False;
    bbReg.Caption := 'Register';
  end;
end;

constructor TDBDetailsForm.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  FServerType := stFirebird;
end;

procedure TDBDetailsForm.ValidateData;
var
  vPort:Integer;
begin
  if Trim(DatabaseEditorFr.Port) = '' then vPort := 3050 else vPort := StrToInt(Trim(DatabaseEditorFr.Port));
  ServerIsUp(DatabaseEditorFr.Host, vPort);
end;

function TDBDetailsForm.GetCharSet :string;
begin
  Result := cbCharset.Text;
end;

function TDBDetailsForm.GetCollation :string;
begin
  Result := cmbCollation.Text;
end;

function TDBDetailsForm.GetDBInfo :IEvsDatabaseInfo;
begin
  Result := FDBInfo;
end;

function TDBDetailsForm.GetDBName :string;
begin
  Result := DatabaseEditorFr.FullDBName;
end;

function TDBDetailsForm.GetHost :string;
begin
  Result := DatabaseEditorFr.Host;
end;

function TDBDetailsForm.GetPageSize :Integer;
begin
  Result := StrToInt(cmbPageSize.Text);
end;

function TDBDetailsForm.GetPassword :string;
begin
  Result := UserLoginFr.Password;
end;

function TDBDetailsForm.GetRole :string;
begin
  Result := UserLoginFr.Role;
end;

function TDBDetailsForm.GetSavePwd :Boolean;
begin
  Result := cxSavePassword.Checked;
end;

function TDBDetailsForm.GetServerType :Integer;
begin
  Result := FServerType;
end;

function TDBDetailsForm.GetTitle :string;
begin
  Result := edTitle.Text;
end;

function TDBDetailsForm.GetUserName :string;
begin
  Result := UserLoginFr.UserName;
end;

procedure TDBDetailsForm.SetCharset(aValue :string);
begin
  cbCharset.Text:=aValue;
end;

procedure TDBDetailsForm.SetCollation(aValue :string);
begin
  cmbCollation.Text := aValue;
end;

procedure TDBDetailsForm.SetDBInfo(aValue :IEvsDatabaseInfo);
begin
  if aValue = FDBInfo then exit;
  FDBInfo := aValue;
  ToScreen(FDBInfo);
end;

procedure TDBDetailsForm.SetDBName(aValue :string);
begin
  DatabaseEditorFr.FullDBName := aValue;
end;

procedure TDBDetailsForm.SetHost(aValue :string);
begin
  DatabaseEditorFr.Host := aValue;
end;

procedure TDBDetailsForm.SetCreateDB(aValue :Boolean);
begin
  if FCreateDB=aValue then Exit;
  FCreateDB:=aValue;
  SetupForCreation(FCreateDB);
end;

procedure TDBDetailsForm.SetPageSize(aValue :Integer);
begin
  if not FCreateDB then Exit;
  cmbPageSize.ItemIndex := cmbPageSize.Items.IndexOf(IntToStr(aValue));
  if cmbPageSize.ItemIndex < 0 then begin
    cmbPageSize.ItemIndex := 1;
    ShowInfoFmt('Database Details',
                'Invalid page size %D. The Default size of %S was used instead',
                [aValue,cmbPageSize.Items[cmbPageSize.ItemIndex]]);
  end;
end;

procedure TDBDetailsForm.SetPassword(aValue :string);
begin
  UserLoginFr.Password := aValue;
end;

procedure TDBDetailsForm.SetRole(aValue :string);
begin
  UserLoginFr.Role := aValue;
end;

procedure TDBDetailsForm.SetSavePwd(aValue :Boolean);
begin
  cxSavePassword.Checked := aValue;
end;

procedure TDBDetailsForm.SetServerType(aValue :Integer);
begin
  if aValue = FServerType then Exit;
  FServerType := aValue;
end;

procedure TDBDetailsForm.SetTitle(aValue :string);
begin
  edTitle.Text := aValue;
end;

procedure TDBDetailsForm.SetUserName(aValue :string);
begin
  UserLoginFr.UserName := aValue;
end;

procedure TDBDetailsForm.ToScreen(const aDB :IEvsDatabaseInfo);
var
  vData :TWideStringArray;
begin
  if Assigned(aDB) then begin
    DatabaseName := aDB.Database;
    Title        := aDB.Title;
    UserName     := aDB.Credentials.UserName;
    Password     := aDB.Credentials.Password;
    Role         := aDB.Credentials.Role;
    SavePassword := aDB.Credentials.SavePassword;
    vData :=  uEvsDBSchema.CharacterSets(aDB.ServerKind);
    if Length(vData) > 0 then begin
      cbCharset.Items.Clear;
      ToStrings(vData, cbCharset.Items);
    end;
    vData := uEvsDBSchema.Collations(aDB.DefaultCharset, aDB.ServerKind);
    if Length(vData) > 0 then begin
      cmbCollation.Items.Clear;
      ToStrings(vData, cmbCollation.Items);
    end;
    Charset   := aDB.Credentials.Charset;
    Collation := aDB.DefaultCollation;
    if aDB.ServerKind <> 0 then ServerType := aDB.ServerKind else ServerType := stFirebird;{$MESSAGE WARN 'Default server should be selectable by the end user'}
  end;
end;

procedure TDBDetailsForm.FromScreen(const aDB :IEvsDatabaseInfo);
begin
  if Assigned(aDB) then begin
    aDB.Database := DatabaseEditorFr.FullDBName;
    aDB.Title    := Title;
    if FCreateDB then aDB.PageSize := PageSize;
    aDB.Credentials.UserName       := UserName;
    aDB.Credentials.Password       := Password;
    aDB.Credentials.Charset        := Charset;
    aDB.Credentials.Role           := Role;
    aDB.Credentials.SavePassword   := SavePassword;
    //if FCreateDB then begin
      if cbCharset.Text  <> '' then aDB.DefaultCharset   := Charset;
      if cmbCollation.Text <> '' then aDB.DefaultCollation := Collation;
    //end;
  end;
end;

function TDBDetailsForm.TestConnection(DatabaseName, UserName, Password, Role, Charset: string): Boolean;
var
  vDB  :IEvsDatabaseInfo = Nil;
  vCnn :IEvsConnection = Nil;
begin
  if FCreateDB then Exit(True);
  Result := False;
  vDB := NewDatabase(ServerType);
  FromScreen(vDB);
  try
    vCnn := Connect(vDB, ServerType);
    Result := Assigned(vCnn);
  Except
    on E:Exception do begin
      Application.ShowException(E);
    end;
  end;
end;

function TDBDetailsForm.GetDefaultCharSet :string;
const
  cSQLCmd = 'SELECT RDB$CHARACTER_SET_NAME FROM RDB$DATABASE';
var
  vQry :TMDOQuery;
  vDB  :IEvsDatabaseInfo;
  vCnn :IEvsConnection = nil;
  vDts : IEvsDataset = nil;
begin {$MESSAGE WARN 'Make server agnostic.'}
  vDB := NewDatabase(ServerType);
  try
  FromScreen(vDB);
  if TryConnect(vDB, vCnn, ServerType) then begin
    try
      vDts := vCnn.Query(cSQLCmd);
      try
        vDts.First;
        if not vDts.Field[0].IsNull then Result := Trim(vDts.Field[0].AsString);
      finally
        vDts := nil;
      end;
    finally
      vCnn := Nil;
    end;
  end;

  finally
    vDB := Nil;
  end;
  Result := Trim(Result);
end;


end.


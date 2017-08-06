unit Reg;

{$mode objfpc}{$H+}
{$I EvsDefs.inc}
interface
{ TODO -oJKOZ -cMetadata upgrade : Add support for Collation selection. }
{ TODO -oJKOZ -cMetadata upgrade : Add support for page size }
{ TODO -oJKOZ -cMetadata upgrade : Add support for multiple files }
uses
  Classes, SysUtils, IBConnection, FileUtil, Forms, Controls, sqldb,
  Graphics, Dialogs, StdCtrls, Buttons, ExtCtrls, MDODatabase, MDOQuery, MDO,
  uTBTypes, utbConfig, utbcommon, uEvsDBSchema, ufrDatabaseEdit;
{ TODO -oJKOZ -cUser Expirience : Retreive the database default characterset during registration.(The button is
  in place write the code to go with it and make it visible). }
type

  { TfmReg }

  TfmReg = class(TForm)
    bbCancel :TBitBtn;
    bbReg :TBitBtn;
    bbTest :TBitBtn;
    BitBtn1 :TBitBtn;
    btBrowse :TButton;
    cbCharset :TComboBox;
    cbCharset1 :TComboBox;
    cxSavePassword :TCheckBox;
    DatabaseEditorFr :TDatabaseEditorFrame;
    edDatabaseName :TEdit;
    edPassword :TEdit;
    edRole :TEdit;
    edTitle :TEdit;
    edUserName :TEdit;
    Image1 :TImage;
    Connection     :TMDODatabase;
    Label1 :TLabel;
    Label2 :TLabel;
    Label3 :TLabel;
    Label4 :TLabel;
    Label5 :TLabel;
    Label6 :TLabel;
    Label7 :TLabel;
    OpenDialog1    :TOpenDialog;
    Panel1 :TPanel;
    Panel2 :TPanel;
    Panel3 :TPanel;
    pnlDBTitle :TPanel;
    Panel5 :TPanel;
    Panel6 :TPanel;
    Panel7 :TPanel;
    procedure bbRegClick(Sender: TObject);
    procedure bbTestClick(Sender: TObject);
    procedure BitBtn1Click(Sender :TObject);
    procedure btBrowseClick(Sender: TObject);

  private
    FCollation :string;
    { private declarations }
    FDBDetails :PDBDetails;
    FDBInfo    :IEvsDatabaseInfo;

    function EditRegisteration(Index: Integer; Title, DatabaseName, UserName, Password, Charset, Role: string;
                               SavePassword: Boolean): Boolean;
    function GetCharSet :string;
    function GetDBInfo :IEvsDatabaseInfo;
    function GetDBName :string;
    function GetHost :string;
    function GetPassword :string;
    function GetRec :PDBDetails;
    function GetRole :string;
    function GetSavePwd :Boolean;
    function GetTitle :string;
    function GetUserName :string;
    procedure SetCharset(aValue :string);
    procedure SetCollation(aValue :string);
    procedure SetDBInfo(aValue :IEvsDatabaseInfo);
    procedure SetDBName(aValue :string);
    procedure SetHost(aValue :string);
    procedure SetPassword(aValue :string);
    procedure SetRec(aValue :PDBDetails);
    procedure SetRole(aValue :string);
    procedure SetSavePwd(aValue :Boolean);
    procedure SetTitle(aValue :string);
    procedure SetUserName(aValue :string);
  protected
    procedure ToScreen;
    procedure FromScreen;
  public
    { public declarations }
    NewReg: Boolean;
    //RecPos: Integer;
    function RegisterDatabase(Title, DatabaseName, UserName, Password, Charset, Role: string; SavePassword: Boolean): Boolean;

    function TestConnection(DatabaseName, UserName, Password, Charset: string): Boolean;
    function GetDefaultCharSet:string;
    function GetEmptyRec: Integer;
    function SaveRegistrations: Boolean;
    procedure Sort;

    property DatabaseName  :string  read GetDBName   write SetDBName;
    property Host          :string  read GetHost     write SetHost;
    property UserName      :string  read GetUserName write SetUserName;
    property Password      :string  read GetPassword write SetPassword;
    property Charset       :string  read GetCharSet  write SetCharset;
    property Collation     :string  read FCollation  write SetCollation;
    property Role          :string  read GetRole     write SetRole;
    property Title         :string  read GetTitle    write SetTitle;
    property SavePassword  :Boolean read GetSavePwd  write SetSavePwd;

    //Property DBRec : PDBDetails read GetRec write SetRec;
    {$IFDEF EVS_Intf}
    Property DB :IEvsDatabaseInfo read GetDBInfo write SetDBInfo;
    {$ENDIF}
  end;

var
  fmReg: TfmReg;

implementation
  {$R *.lfm}
{ TfmReg }


procedure TfmReg.bbRegClick(Sender: TObject);
begin
  if Trim(edTitle.Text) = '' then
    ShowMessage('You should fill all fields')
  else
  if TestConnection(edDatabaseName.Text, edUserName.Text, edPassword.Text, cbCharset.Text) then
  //if NewReg then  // New registration
  //begin
  //  if RegisterDatabase(edTitle.Text, edDatabaseName.Text, edUserName.Text, edPassword.Text, cbCharset.Text,
  //    edRole.Text, cxSavePassword.Checked) then
  //     ModalResult:= mrOK;
  //end
  //else // if not NewReg, edit registration
  //  if EditRegisteration(RecPos, edTitle.Text, edDatabaseName.Text, edUserName.Text, edPassword.Text,
  //    cbCharset.Text, edRole.Text, cxSavePassword.Checked) then
  //    MOdalResult:= mrOk;
    FromScreen;
  ModalResult := mrOK;
end;

procedure TfmReg.bbTestClick(Sender: TObject);
begin
  if TestConnection(DatabaseName, UserName, Password, Charset) then
    ShowMessage('Connected successfully');
end;

procedure TfmReg.BitBtn1Click(Sender :TObject);
var
  vTest :String;
  vIdx  :Integer;
begin
  vTest := GetDefaultCharSet;
  vIdx  := cbCharset.Items.IndexOf(Trim(vTest));
  cbCharset.Text := vTest;
  cbCharset.ItemIndex := vIdx;
end;

procedure TfmReg.btBrowseClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    edDatabaseName.Text:= OpenDialog1.FileName;
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

procedure SaveDataBaseRec(const aDest:TStream; aSrc:TDBDetails);
begin
   { TODO -oJKOZ -cData persistance. : write the procedure that saves a single registered database to a stream }
end;
procedure LoadDatabaseRec(const aSrc:TStream; var aDest:TDBDetails);
begin
  { TODO -oJKOZ -cData Persistance : Write the procedure to load the data of a registered database from a stream. }
end;

function TfmReg.RegisterDatabase(Title, DatabaseName, UserName, Password, Charset, Role: string; SavePassword: Boolean): Boolean;
var
  vRec        :TDBDetails;
  vFile       :file of TDBDetails;
  vEmptyIndex :Integer;
  vFileName   :string;
begin
  try
    raise ReplaceException('Function TfmReg.RegisterDatabase is replaced it will be removed'); {$MESSAGE WARN 'Function is replaced will be removed'}
    //vFileName:= GetConfigurationDirectory + GetRegistryFileName; //'turbobird.reg';
    //
    //AssignFile(vFile, vFileName);
    //if FileExists(vFileName) then
    //begin
    //  vEmptyIndex:= GetEmptyRec;
    //  FileMode := 2;//2!? what 2 means?
    //
    //  Reset(vFile);
    //  if vEmptyIndex <> -1 then
    //    Seek(vFile, vEmptyIndex)
    //  else
    //    Seek(vFile, System.FileSize(vFile));
    //end
    //else
    //  Rewrite(vFile);
    //
    //vRec.Title       := Title;
    //vRec.DatabaseName:= DatabaseName;
    //vRec.UserName    := UserName;
    //if SavePassword then
    //  vRec.Password:= Password
    //else
    //  vRec.Password:= '';
    //vRec.Charset     :=Charset;
    //vRec.Role        :=Role;
    //vRec.SavePassword:=SavePassword;
    //vRec.Deleted     :=False;
    //vRec.LastOpened  :=Now;
    //
    //Write(vFile, vRec);
    //CloseFile(vFile);
    Result:= True;
  except
    on E: Exception do
    begin
      Result:= False;
      ShowMessage('Error: ' + e.Message);
    end;
  end;
end;

function TfmReg.EditRegisteration(Index: Integer; Title, DatabaseName, UserName, Password, Charset, Role: string;
   SavePassword: Boolean): Boolean;
var
  Rec: TDBDetails;
  F: file of TDBDetails;
  FileName: string;
begin
  try
    FileName:= utbConfig.getConfigurationDirectory + 'turbobird.reg';

    AssignFile(F, FileName);
    FileMode:= 2;
    Reset(F);
    Seek(F, Index);

    Rec.Title:= Title;
    Rec.DatabaseName:= DatabaseName;
    Rec.UserName:= UserName;
    if SavePassword then
      Rec.Password:= Password
    else
      Rec.Password:= '';
    Rec.Charset:= Charset;
    Rec.Role:= Role;
    Rec.SavePassword:= SavePassword;
    Rec.Deleted:= False;

    Write(F, Rec);
    CloseFile(F);
    Result:= True;
  except
    on E: Exception do
    begin
      Result:= False;
      ShowMessage('Error: ' + e.Message);
    end;
  end;
end;

function TfmReg.GetCharSet :string;
begin
  Result := cbCharset.Text;
end;

function TfmReg.GetDBInfo :IEvsDatabaseInfo;
begin
  Result := FDBInfo
end;

function TfmReg.GetDBName :string;
begin
  //Result := extractDBName(edDatabaseName.Text);
  Result := DatabaseEditorFr.FullDBName;
end;

function TfmReg.GetHost :string;
begin
  Result := GetServerName(edDatabaseName.Text);
end;

function TfmReg.GetPassword :string;
begin
  Result := edPassword.Text;
end;

function TfmReg.GetRec :PDBDetails;
begin
  Result := FDBDetails;
end;

function TfmReg.GetRole :string;
begin
  Result := edRole.Text;
end;

function TfmReg.GetSavePwd :Boolean;
begin
  Result := cxSavePassword.Checked;
end;

function TfmReg.GetTitle :string;
begin
  Result := edTitle.Text;
end;

function TfmReg.GetUserName :string;
begin
  Result := edUserName.Text;
end;

procedure TfmReg.SetCharset(aValue :string);
begin
  cbCharset.Text:=aValue;
end;

procedure TfmReg.SetCollation(aValue :string);
begin
  if FCollation=aValue then Exit;
  FCollation:=aValue;
end;

procedure TfmReg.SetDBInfo(aValue :IEvsDatabaseInfo);
begin
  FDBInfo := aValue;
end;

procedure TfmReg.SetDBName(aValue :string);
begin
  edDatabaseName.Text := aValue;
  DatabaseEditorFr.FullDBName := aValue;
end;

procedure TfmReg.SetHost(aValue :string);
begin
  edDatabaseName.Text := ChangeServerName(edDatabaseName.Text,aValue);
end;

procedure TfmReg.SetPassword(aValue :string);
begin
  edPassword.Text := aValue;
end;

procedure TfmReg.SetRec(aValue :PDBDetails);
begin
  FDBDetails := aValue;
  ToScreen;
end;

procedure TfmReg.SetRole(aValue :string);
begin
  edRole.Text := aValue;
end;

procedure TfmReg.SetSavePwd(aValue :Boolean);
begin
  cxSavePassword.Checked := aValue;
end;

procedure TfmReg.SetTitle(aValue :string);
begin
  edTitle.Text := aValue;
end;

procedure TfmReg.SetUserName(aValue :string);
begin
  edUserName.Text := aValue;
end;

procedure TfmReg.ToScreen;
begin
  if Assigned(FDBDetails) then begin
    DatabaseName := FDBDetails^.DatabaseName;
    Title        := FDBDetails^.Title;
    UserName     := FDBDetails^.UserName;
    Password     := FDBDetails^.Password;
    Charset      := FDBDetails^.Charset;
    Role         := FDBDetails^.Role;
    SavePassword := FDBDetails^.SavePassword;
  end;
  {$IFDEF EVS_INTF} // the new interfaces are to be prefered.
  if Assigned(FDBInfo) then begin
    DatabaseName := FDBInfo.Database;
    Title        := FDBInfo.Title;
    UserName     := FDBInfo.Credentials.UserName;
    Password     := FDBInfo.Credentials.Password;
    Charset      := FDBInfo.Credentials.Charset;
    Role         := FDBInfo.Credentials.Role;
    SavePassword := FDBInfo.Credentials.SavePassword;
    FCollation   := FDBInfo.DefaultCollation;
  end;
  {$ENDIF}

end;

procedure TfmReg.FromScreen;
begin
  if Assigned(FDBDetails) then begin
    FDBDetails^.DatabaseName := DatabaseName;
    FDBDetails^.Title        := Title;
    FDBDetails^.UserName     := UserName;
    FDBDetails^.Password     := Password;
    FDBDetails^.Charset      := Charset;
    FDBDetails^.Role         := Role;
    FDBDetails^.SavePassword := SavePassword;
  end;
  if Assigned(FDBInfo) then begin
    FDBInfo.Database     := DatabaseName;
    FDBInfo.Title        := Title;
    FDBInfo.Credentials.UserName     := UserName;
    FDBInfo.Credentials.Password     := Password;
    FDBInfo.Credentials.Charset      := Charset;
    FDBInfo.Credentials.Role         := Role;
    FDBInfo.Credentials.SavePassword := SavePassword;
  end;
end;

function TfmReg.TestConnection(DatabaseName, UserName, Password, Charset: string): Boolean;
begin
  try
    Connection.Close;
    Connection.DatabaseName:= DatabaseName;
    Connection.UserName:= UserName;
    Connection.Password:= Password;
    Connection.CharSet:= Charset;
    Connection.Open;
    Connection.Close;
    Result := True;
  except
    on d: EIBDatabaseError do begin
      Result:= False;
      ShowMessage('Unable to connect: '+ d.Message + LineEnding +
        'Details: GDS error code: '+inttostr(d.GDSErrorCode));
    end;
    on E: EMDOError do begin
      Result:= False;
      ShowMessage('Unable to connect: ' + LineEnding + e.Message);
    end;
  end;
end;

function TfmReg.GetDefaultCharSet :string;
const
  cSQLCmd = 'SELECT RDB$CHARACTER_SET_NAME FROM RDB$DATABASE';
var
  vQry : TMDOQuery;
begin
  Connection.Close;
  Connection.DatabaseName := edDatabaseName.Text;
  Connection.UserName     := edUserName.Text;
  Connection.Password     := edPassword.Text;
  Connection.Role         := edRole.Text;
  Connection.Open;
  vQry := GetQuery(Connection,cSQLCmd,[]);
  try
    if vQry.Fields[0].IsNull then Result := 'None'
    else Result := vQry.Fields[0].AsString;
  finally
    ReleaseQuery(vQry);
    Connection.Close;
  end;
  Result := Trim(Result);
end;

function TfmReg.GetEmptyRec: Integer;
var
  FileName: string;
  Rec: TDBDetails;
  F: file of TDBDetails;
begin
  Result:= -1;

  FileName := utbConfig.getConfigurationDirectory + GetRegistryFileName; //'turbobird.reg';

  AssignFile(F, FileName);
  if FileExists(FileName) then
  begin
    Reset(F);
    while not system.Eof(F) do begin
      Read(F, Rec);
      if Rec.Deleted then
      begin
        Result := FilePos(F) - 1;
        Break;
      end;
    end;
    Closefile(F);
  end;
end;

function TfmReg.SaveRegistrations: Boolean;
var
  F: file of TDBDetails;
  FileName: string;
  i: Integer;
begin
  try
    Sort;
    FileName:= utbConfig.GetConfigurationDirectory + GetRegistryFileName; //'turbobird.reg';

    AssignFile(F, FileName);
    FileMode:= 2;
    Rewrite(F);

    //for i:= 0 to High(fmMain.RegisteredDatabases) do
    //  Write(F, fmMain.RegisteredDatabases[i].OrigRegRec);
    CloseFile(F);
    Result:= True;
  except
    on E: Exception do
    begin
      Result:= False;
    end;
  end;
end;

procedure TfmReg.Sort;
var
  TempRec: TDBDetails;
  Done: Boolean;
  i: Integer;
  TempIndex: Integer;
begin
  repeat
    Done:= True;
    //for i:= 0 to High(fmMain.RegisteredDatabases) - 1 do
    //with fmMain do
    //  if RegisteredDatabases[i].RegRec.LastOpened < RegisteredDatabases[i + 1].RegRec.LastOpened then
    //  begin
    //    Done:= False;
    //    TempRec:= RegisteredDatabases[i].OrigRegRec;
    //    RegisteredDatabases[i].OrigRegRec:= RegisteredDatabases[i + 1].OrigRegRec;
    //    RegisteredDatabases[i].RegRec:= RegisteredDatabases[i + 1].RegRec;
    //    RegisteredDatabases[i + 1].OrigRegRec:= TempRec;
    //    RegisteredDatabases[i + 1].RegRec:= TempRec;
    //
    //    TempIndex:= RegisteredDatabases[i].Index;
    //    RegisteredDatabases[i].Index:= RegisteredDatabases[i + 1].Index;
    //    RegisteredDatabases[i + 1].Index:= TempIndex;
    //  end;
  until Done;
end;

//initialization
//  {$I reg.lrs}

end.


unit Reg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, FileUtil, LResources, Forms, Controls, sqldb, sqldblib,
  Graphics, Dialogs, StdCtrls, Buttons, ExtCtrls, MDODatabase, MDOQuery, uTBTypes, utbConfig, turbocommon;
{ TODO -oJKOZ -cUser Expirience : Retreive the database default characterset during registration.(The button is in place write the code to go with it and make it visible). }
type

  { TfmReg }

  TfmReg = class(TForm)
    bbCancel: TBitBtn;
    bbTest: TBitBtn;
    bbReg: TBitBtn;
    BitBtn1 :TBitBtn;
    btBrowse: TButton;
    cbCharset: TComboBox;
    cxSavePassword: TCheckBox;
    edRole: TEdit;
    edDatabaseName: TEdit;
    edTitle: TEdit;
    edPassword: TEdit;
    edUserName: TEdit;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Connection :TMDODatabase;
    OpenDialog1: TOpenDialog;
    procedure bbRegClick(Sender: TObject);
    procedure bbTestClick(Sender: TObject);
    procedure BitBtn1Click(Sender :TObject);
    procedure btBrowseClick(Sender: TObject);

  private
    { private declarations }
    function EditRegisteration(Index: Integer; Title, DatabaseName, UserName, Password, Charset, Role: string;
      SavePassword: Boolean): Boolean;
  public
    { public declarations }
    NewReg: Boolean;
    RecPos: Integer;
    function RegisterDatabase(Title, DatabaseName, UserName, Password, Charset, Role: string;
      SavePassword: Boolean): Boolean;
    function TestConnection(DatabaseName, UserName, Password, Charset: string): Boolean;
    function GetDefaultCharSet:string;
    function GetEmptyRec: Integer;
    function SaveRegistrations: Boolean;
    procedure Sort;
  end;

var
  fmReg: TfmReg;

implementation
  {$R *.lfm}
{ TfmReg }

uses main;

procedure TfmReg.bbRegClick(Sender: TObject);
begin
  if Trim(edTitle.Text) = '' then
    ShowMessage('You should fill all fields')
  else
  if TestConnection(edDatabaseName.Text, edUserName.Text, edPassword.Text, cbCharset.Text) then
  if NewReg then  // New registration
  begin
    if RegisterDatabase(edTitle.Text, edDatabaseName.Text, edUserName.Text, edPassword.Text, cbCharset.Text,
      edRole.Text, cxSavePassword.Checked) then
       ModalResult:= mrOK;
  end
  else // if not NewReg, edit registration
    if EditRegisteration(RecPos, edTitle.Text, edDatabaseName.Text, edUserName.Text, edPassword.Text,
      cbCharset.Text, edRole.Text, cxSavePassword.Checked) then
      MOdalResult:= mrOk;
end;

procedure TfmReg.bbTestClick(Sender: TObject);
begin
  if TestConnection(edDatabaseName.Text, edUserName.Text, edPassword.Text, cbCharset.Text) then
    ShowMessage('Connected successfully');
end;

procedure TfmReg.BitBtn1Click(Sender :TObject);
var
  vTest :String;
  vIdx  :Integer;
begin
  vTest := GetDefaultCharSet;
  vIdx := cbCharset.Items.IndexOf(Trim(vTest));
  cbCharset.Text := vTest;
  cbCharset.ItemIndex := vIdx;
  //cbCharset;
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
  Rec        : TDBDetails;
  F          : file of TDBDetails;
  EmptyIndex : Integer;
  FileName   : string;
begin
  try
    FileName:= GetConfigurationDirectory + GetRegistryFileName; //'turbobird.reg';

    AssignFile(F, FileName);
    if FileExists(FileName) then
    begin
      EmptyIndex:= GetEmptyRec;
      FileMode := 2;//2!? what 2 means?

      Reset(F);
      if EmptyIndex <> -1 then
        Seek(F, EmptyIndex)
      else
        Seek(F, System.FileSize(F));
    end
    else
      Rewrite(F);

    Rec.Title       := Title;
    Rec.DatabaseName:= DatabaseName;
    Rec.UserName    := UserName;
    if SavePassword then
      Rec.Password:= Password
    else
      Rec.Password:= '';
    Rec.Charset     :=Charset;
    Rec.Role        :=Role;
    Rec.SavePassword:=SavePassword;
    Rec.Deleted     :=False;
    Rec.LastOpened  :=Now;

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
    Result:= True;
  except
    on d: EIBDatabaseError do
    begin
      Result:= False;
      ShowMessage('Unable to connect: '+ d.Message + LineEnding +
        'Details: GDS error code: '+inttostr(d.GDSErrorCode));
    end;
    on E: Exception do
    begin
      Result:= False;
      ShowMessage('Unable to connect: ' + e.Message);
    end;
  end;
end;

function TfmReg.GetDefaultCharSet :string;
const
  cSQLCmd = 'SELECT RDB$CHARACTER_SET_NAME FROM RDB$DATABASE';
var
  vQry : TMDOQuery;
begin
  //, , , cbCharset.Text
  Connection.Close;
  Connection.DatabaseName := edDatabaseName.Text;
  Connection.UserName     := edUserName.Text;
  Connection.Password     := edPassword.Text;
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

    for i:= 0 to High(fmMain.RegisteredDatabases) do
      Write(F, fmMain.RegisteredDatabases[i].OrigRegRec);
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
    for i:= 0 to High(fmMain.RegisteredDatabases) - 1 do
    with fmMain do
      if RegisteredDatabases[i].RegRec.LastOpened < RegisteredDatabases[i + 1].RegRec.LastOpened then
      begin
        Done:= False;
        TempRec:= RegisteredDatabases[i].OrigRegRec;
        RegisteredDatabases[i].OrigRegRec:= RegisteredDatabases[i + 1].OrigRegRec;
        RegisteredDatabases[i].RegRec:= RegisteredDatabases[i + 1].RegRec;
        RegisteredDatabases[i + 1].OrigRegRec:= TempRec;
        RegisteredDatabases[i + 1].RegRec:= TempRec;

        TempIndex:= RegisteredDatabases[i].Index;
        RegisteredDatabases[i].Index:= RegisteredDatabases[i + 1].Index;
        RegisteredDatabases[i + 1].Index:= TempIndex;
      end;
  until Done;
end;

//initialization
//  {$I reg.lrs}

end.


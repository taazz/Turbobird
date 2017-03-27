unit EnterPass;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, uTBTypes, SysTables;

type

  { TfmEnterPass }

  TfmEnterPass = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    cbRole : TComboBox;
    edUser : TEdit;
    Label1 : TLabel;
    Label2 : TLabel;
    Label3 : TLabel;
    Label4 : TLabel;
    lbDatabaseName: TLabel;
    edPassword    : TEdit;
    procedure BitBtn1Click(Sender :TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FDBInfo     :PDBInfo;
    FMaxRetries :Integer;
    FTryCounter :Integer;
    function GetDBCaption :String;
    function GetDBInfo :PDBInfo;
    function GetPassword :String;
    function GetRole :String;
    function GetUserName :String;
    procedure SetDBCaption(aValue :String);
    procedure SetDBInfo(aValue :PDBInfo);
    procedure SetPassword(aValue :String);
    procedure SetRole(aValue :String);
    procedure SetUserName(aValue :String);
    function ValidateCredentials:Boolean;
  public
    { public declarations }
    function Execute(const aDBInfo :PDBInfo; aUser :string; aPassword :String; aRole :string;aRetries:Integer=3) :TModalResult;
    constructor Create(aOwner :TComponent); override;
    procedure Clear;
    property DBCaption   :String  read GetDBCaption write SetDBCaption;
    property UserName    :String  read GetUserName  write SetUserName;
    property Password    :String  read GetPassword  write SetPassword;
    property Role        :String  read GetRole      write SetRole;
    property DatabaseRec :PDBInfo read GetDBInfo    write SetDBInfo;
    property MaxRetries  :Integer read FMaxRetries  write FMaxRetries;
  end; 

var
  fmEnterPass: TfmEnterPass;

implementation
{$R *.lfm}
{ TfmEnterPass }

procedure TfmEnterPass.FormActivate(Sender: TObject);
begin
  if Showing then
    edPassword.SetFocus;
end;

procedure TfmEnterPass.BitBtn1Click(Sender :TObject);
begin
  //system.InitExceptions
  try
    inc(FTryCounter);
    SysTables.ValidateConnection(FDBInfo^.RegRec.DatabaseName,UserName,Password,Role,FDBInfo^.RegRec.Charset);
    ModalResult := mrOK;
  except
    on E:Exception do begin
      Application.ShowException(E);
      if FTryCounter >= FMaxRetries then ModalResult := mrCancel;
    end;
  end;
end;

procedure TfmEnterPass.FormShow(Sender: TObject);
begin
  //cbRole.ItemIndex:= -1;
end;

function TfmEnterPass.GetDBCaption :String;
begin
  Result := lbDatabaseName.Caption;
end;

function TfmEnterPass.GetDBInfo :PDBInfo;
begin
  Result := FDBInfo;
end;

function TfmEnterPass.GetPassword :String;
begin
  Result := edPassword.Text ;
end;

function TfmEnterPass.GetRole :String;
begin
  Result := cbRole.Text;
end;

function TfmEnterPass.GetUserName :String;
begin
  Result := edUser.Text;
end;

procedure TfmEnterPass.SetDBCaption(aValue :String);
begin
  lbDatabaseName.Caption := aValue;
end;

procedure TfmEnterPass.SetDBInfo(aValue :PDBInfo);
begin
  FDBInfo   := aValue;
  UserName  := FDBInfo^.RegRec.UserName;
  DBCaption := FDBInfo^.RegRec.Title;
  if FDBInfo^.RegRec.SavePassword then Password := FDBInfo^.RegRec.Password else Password := '';
  try
    dmSysTables.GetDBObjectNames(FDBInfo^, otRoles, cbRole.Items);
  except
    on e:Exception do begin
        //do nothing ignore the error
    end;
  end;
  Role      := FDBInfo^.RegRec.Role;
  DBCaption := FDBInfo^.RegRec.DatabaseName;
end;

procedure TfmEnterPass.SetPassword(aValue :String);
begin
  edPassword.Text := aValue;
end;

procedure TfmEnterPass.SetRole(aValue :String);
begin
  cbRole.Text := aValue;
end;

procedure TfmEnterPass.SetUserName(aValue :String);
begin
  edUser.Text := aValue;
end;

function TfmEnterPass.ValidateCredentials :Boolean;
begin
  Result := False;
  if Assigned(FDBInfo) then begin
    SysTables.ValidateConnection(FDBInfo^.RegRec.DatabaseName, UserName, Password, Role, FDBInfo^.RegRec.Charset);
    Result := True;
  end else raise ETBException.Create('Invalid Database info.');
end;

function TfmEnterPass.Execute(const aDBInfo :PDBInfo; aUser :string; aPassword :String; aRole :string; aRetries :Integer) :TModalResult;
begin
  Clear;
  FDBInfo := aDBInfo;
  SetUserName(aUser);
  SetPassword(aPassword);
  SetRole    (aRole);
  FMaxRetries := aRetries;
  FTryCounter := 0;
  Result := ShowModal;
end;

constructor TfmEnterPass.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  FMaxRetries := 0;
  FTryCounter := 0;
end;

procedure TfmEnterPass.Clear;
var
  vCntr :Integer;
begin
  edPassword.Clear;
  edUser.Clear;
  cbRole.Clear;
  //for vCntr := 0 to ControlCount -1 do begin
  //  if Controls[vCntr] is TCustomEdit then TCustomEdit(Controls[vCntr]).Clear
  //  else if Controls[vCntr] is TCustomComboBox then TCustomComboBox(Controls[vCntr]).Clear;
  //end;
end;

end.


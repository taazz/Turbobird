unit uLoginForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, uTBTypes, {SysTables,} uEvsDBSchema;

type

  { TLoginForm }

  TLoginForm = class(TForm)
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
    procedure FormActivate(Sender :TObject);
  private
    { private declarations }
    FDBInfo     :IEvsDatabaseInfo;
    FMaxRetries :Integer;
    FTryCounter :Integer;
    function GetDBCaption :String;
    function GetDBInfo :IEvsDatabaseInfo;
    function GetPassword :String;
    function GetRole :String;
    function GetUserName :String;
    procedure SetDBCaption(aValue :String);
    procedure SetDBInfo(aValue :IEvsDatabaseInfo);
    procedure SetPassword(aValue :String);
    procedure SetRole(aValue :String);
    procedure SetUserName(aValue :String);
    function ValidateCredentials:Boolean;
  public
    { public declarations }
    function Execute(const aDBInfo :IEvsDatabaseInfo; const aUser, aPassword, aRole :string; aRetries:Integer=3) :TModalResult;
    constructor Create(aOwner :TComponent); override;
    procedure Clear;
    property DBCaption   :String           read GetDBCaption write SetDBCaption;
    property UserName    :String           read GetUserName  write SetUserName;
    property Password    :String           read GetPassword  write SetPassword;
    property Role        :String           read GetRole      write SetRole;
    property Database    :IEvsDatabaseInfo read GetDBInfo    write SetDBInfo;
    property MaxRetries  :Integer          read FMaxRetries  write FMaxRetries;
  end; 

var
  LoginForm: TLoginForm;

implementation
{$R *.lfm}
{ TLoginForm }

procedure TLoginForm.FormActivate(Sender: TObject);
begin
  if Showing then
    edPassword.SetFocus;
end;

procedure TLoginForm.BitBtn1Click(Sender :TObject);
begin
  try
    inc(FTryCounter);
    FDBInfo.Connection := ConnectAs(FDBInfo, UserName, Password, Role);
    FDBInfo.Credentials.UserName := UserName;
    FDBInfo.Credentials.Password := Password;
    FDBInfo.Credentials.Role     := Role;
    ModalResult := mrOK;
  except
    on E:Exception do begin
      if MessageDlg('Connection', 'Connection failed with message :'+LineEnding+E.Message,mtInformation,[mbRetry, mbCancel],0) = mrCancel then begin
        ModalResult := mrCancel;
        Exit;
      end;
      if FTryCounter >= FMaxRetries then ModalResult := mrAbort;
    end;
  end;
end;

function TLoginForm.GetDBCaption :String;
begin
  Result := lbDatabaseName.Caption;
end;

function TLoginForm.GetDBInfo :IEvsDatabaseInfo;
begin
  Result := FDBInfo;
end;

function TLoginForm.GetPassword :String;
begin
  Result := edPassword.Text ;
end;

function TLoginForm.GetRole :String;
begin
  Result := cbRole.Text;
end;

function TLoginForm.GetUserName :String;
begin
  Result := edUser.Text;
end;

procedure TLoginForm.SetDBCaption(aValue :String);
begin
  lbDatabaseName.Caption := aValue;
end;

procedure TLoginForm.SetDBInfo(aValue :IEvsDatabaseInfo);
  procedure RolesToScreen;
  var
    vCntr :Integer;
  begin
    for vCntr := 0 to FDBInfo.RoleCount -1 do
      cbRole.Items.Add(FDBInfo.Role[vCntr].Name);
  end;

begin
  FDBInfo   := aValue;
  UserName  := FDBInfo.Credentials.UserName;
  DBCaption := FDBInfo.Title;
  if FDBInfo.Credentials.SavePassword then Password := FDBInfo.Credentials.Password else Password := '';
  try

  //dmSysTables.GetDBObjectNames(FDBInfo^, otRoles, cbRole.Items);
    RolesToScreen;
  except
    on e:Exception do begin
        //do nothing ignore the error
    end;
  end;
  Role      := FDBInfo.Credentials.Role;
  DBCaption := FDBInfo.Database;
end;

procedure TLoginForm.SetPassword(aValue :String);
begin
  edPassword.Text := aValue;
end;

procedure TLoginForm.SetRole(aValue :String);
begin
  cbRole.Text := aValue;
end;

procedure TLoginForm.SetUserName(aValue :String);
begin
  edUser.Text := aValue;
end;

function TLoginForm.ValidateCredentials :Boolean;
var
  vCnn : IEvsConnection = Nil;
begin
  Result := False;
  if Assigned(FDBInfo) then begin
    Result := TryConnectAs(FDBInfo,UserName,Password,Role, vCnn, FDBInfo.ServerKind);
    vCnn := Nil;
  end else raise ETBException.Create('Invalid Database info.');
end;

function TLoginForm.Execute(const aDBInfo :IEvsDatabaseInfo; const aUser, aPassword, aRole :string; aRetries :Integer=3) :TModalResult;
begin
  Clear;
  FDBInfo := aDBInfo;
  SetDBCaption(FDBInfo.Title);
  SetUserName(aUser);
  SetPassword(aPassword);
  SetRole    (aRole);
  FMaxRetries := aRetries;
  FTryCounter := 0;
  Result      := ShowModal;
end;

constructor TLoginForm.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  FMaxRetries := 0;
  FTryCounter := 0;
end;

procedure TLoginForm.Clear;
begin
  edPassword.Clear;
  edUser.Clear;
  cbRole.Clear;
end;

end.


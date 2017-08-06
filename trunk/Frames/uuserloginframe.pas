unit uUserLoginFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls;

type

  { TUserLoginFrame }

  TUserLoginFrame = class(TFrame)
    cmbRole :TComboBox;
    edtUserName :TEdit;
    edtPassword :TEdit;
    lblUserName :TLabel;
    lblPassword :TLabel;
    lblRole :TLabel;
  private
    function GetPaSsword :String;
    function GetRole :String;
    function GetUserName :String;
    procedure SetPassword(aValue :String);
    procedure SetRole(aValue :String);
    procedure SetUserName(aValue :String);
    { private declarations }
  public
    { public declarations }
    property UserName :String read GetUserName write SetUserName;
    Property Password :String read GetPaSsword write SetPassword;
    property Role     :String read GetRole     write SetRole;
  end;

implementation

{$R *.lfm}

{ TUserLoginFrame }

function TUserLoginFrame.GetPaSsword :String;
begin
  Result := edtPassword.Text;
end;

function TUserLoginFrame.GetRole :String;
begin
  Result := cmbRole.Text;
end;

function TUserLoginFrame.GetUserName :String;
begin
  Result := edtUserName.Text;
end;

procedure TUserLoginFrame.SetPassword(aValue :String);
begin
  edtPassword.Text := aValue;
end;

procedure TUserLoginFrame.SetRole(aValue :String);
begin
  cmbRole.Text := aValue;
end;

procedure TUserLoginFrame.SetUserName(aValue :String);
begin
  edtUserName.Text := aValue;
end;

end.


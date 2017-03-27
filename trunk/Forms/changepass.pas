unit ChangePass;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons;

type

  { TfmChangePass }

  TfmChangePass = class(TForm)
    bbCanel: TBitBtn;
    bbCreate: TBitBtn;
    edPassword: TEdit;
    edConfirm: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure bbCreateClick(Sender: TObject);
  private
    function GetPassword :string;
    procedure SetPassword(aValue :string);
    { private declarations }
  public
    { public declarations }
    property Password:string read GetPassword write SetPassword;
  end; 

var
  fmChangePass: TfmChangePass;

implementation
{$R *.lfm}
{ TfmChangePass }

procedure TfmChangePass.bbCreateClick(Sender: TObject);
begin
  if edPassword.Text = '' then
    ShowMessage('You have to input a password')
  else
  if edPassword.Text <> edConfirm.Text then
    ShowMessage('Passwords do not match')
  else
    ModalResult:= mrOK;
end;

function TfmChangePass.GetPassword :string;
begin
  Result := edPassword.Text;
end;

procedure TfmChangePass.SetPassword(aValue :string);
begin
  edPassword.Text := aValue;
end;

//initialization
//  {$I changepass.lrs}

end.


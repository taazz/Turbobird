unit ufrDatabaseEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, EditBtn, StdCtrls, Buttons, ExtCtrls, utbcommon;

type

  { TDatabaseEditorFrame }

  TDatabaseEditorFrame = class(TFrame)
    cmbHost :TComboBox;
    edtPort :TEdit;
    edtDatabase :TEdit;
    Label1 :TLabel;
    Label2 :TLabel;
    Label3 :TLabel;
    btnFileSelect :TSpeedButton;
  private
    { private declarations }
    Function GetHost     :WideString;
    Function GetPort     :WideString;
    Function GetDBName   :WideString;
    Function GetFullname :WideString;
    procedure SetDBName(aValue :WideString);
    procedure SetFullName(aValue :WideString);
    procedure SetHost(aValue :WideString);
    procedure SetPort(aValue :WideString);
  public
    { public declarations }
    Property Host         :WideString read GetHost     write SetHost;
    Property Port         :WideString read GetPort     write SetPort;
    Property DatabaseName :WideString read GetDBName   write SetDBName;
    Property FullDBName   :WideString read GetFullname write SetFullName;
  end;

implementation

{$R *.lfm}

{ TDatabaseEditorFrame }

Function TDatabaseEditorFrame.GetHost :WideString;
begin
  Result := cmbHost.Text;
end;

Function TDatabaseEditorFrame.GetPort :WideString;
begin
  Result := edtPort.Text;
end;

Function TDatabaseEditorFrame.GetDBName :WideString;
begin
  Result := edtDatabase.Text;
end;

Function TDatabaseEditorFrame.GetFullname :WideString;
begin
  Result := Host+'/'+Port+':'+DatabaseName;
end;

procedure TDatabaseEditorFrame.SetDBName(aValue :WideString);
begin
  edtDatabase.Text := aValue;
end;

procedure TDatabaseEditorFrame.SetFullName(aValue :WideString);
var
  vPos    :Integer;
  vHost,
  vPort,
  vDBName :WideString;
begin
  //ParseFullDBName(aValue);
  raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
  vPos := Pos(':', aValue);
  if vPos > 2 then begin
    vHost   := Copy(aValue, 1, vPos);
    vPos    := Pos('/',vHost);
    if vPos > 0 then begin
      vPort   := Copy(vHost,vPos,Length(vHost));
      SetLength(vHost,vPos);
    end;
    vDBName := Copy(aValue, vPos, Length(aValue));
  end;
end;

procedure TDatabaseEditorFrame.SetHost(aValue :WideString);
begin
  cmbHost.Text := aValue;
end;

procedure TDatabaseEditorFrame.SetPort(aValue :WideString);
begin
  edtPort.Text := aValue;
end;

end.


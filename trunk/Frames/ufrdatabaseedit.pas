unit ufrDatabaseEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, EditBtn, StdCtrls, Buttons, ExtCtrls, Dialogs, uTBTypes, uEvsDBSchema;

type

  { TDatabaseEditorFrame }

  TDatabaseEditorFrame = class(TFrame)
    cmbHost :TComboBox;
    DlgFBDatabase :TOpenDialog;
    edtPort :TEdit;
    edtDatabase :TEdit;
    Label1 :TLabel;
    Label2 :TLabel;
    Label3 :TLabel;
    btnFileSelect :TSpeedButton;
    procedure btnFileSelectClick(Sender :TObject);
  private
    FDatabase :IEvsDatabaseInfo;
    { private declarations }
    Function GetHost     :WideString;
    Function GetPort     :WideString;
    Function GetDBName   :WideString;
    Function GetFullname :WideString;
    procedure SetDatabase(aValue :IEvsDatabaseInfo);
    procedure SetDBName(aValue :WideString);
    procedure SetFullName(aValue :WideString);
    procedure SetHost(aValue :WideString);
    procedure SetPort(aValue :WideString);
  protected
    procedure Clear;
    procedure ToScreen;
    procedure FromScreen;
  public
    { public declarations }
    Property Host         :WideString read GetHost     write SetHost;
    Property Port         :WideString read GetPort     write SetPort;
    Property DatabaseName :WideString read GetDBName   write SetDBName;
    Property FullDBName   :WideString read GetFullname write SetFullName;
    property Database:IEvsDatabaseInfo read FDatabase write SetDatabase;
  end;

implementation

{$R *.lfm}
uses uTbDialogs, uTBCommon;
{ TDatabaseEditorFrame }

procedure TDatabaseEditorFrame.btnFileSelectClick(Sender :TObject);
var
  vTmp : TStringArray;
begin
  vTmp := OpenFiles('Firebird databases|*.fdb;*.gdb','');
  if Length(vTmp) > 0 then begin
    DatabaseName := vTmp[0];
    SetLength(vTmp,0);
  end;
end;

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
var
  vHost:String;
begin
  if Host<>'' then vHost := Host;
  if (Port<>'') and (vHost<>'') then vHost := vHost+'/'+Port ;
  if vHost <> '' then Result := vHost+':'+DatabaseName
  else Result := DatabaseName;
end;

procedure TDatabaseEditorFrame.SetDatabase(aValue :IEvsDatabaseInfo);
begin
  if FDatabase=aValue then Exit;
  FDatabase:=aValue;
  Clear;
  ToScreen;
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
  //raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
  vPort :=''; vHost:='';vDBName:='';
  vPos := Pos(':', aValue);
  if vPos > 2 then begin
    vHost   := Copy(aValue, 1, vPos-1);
    vDBName := Copy(aValue, vPos+1, Length(aValue));
    vPos    := Pos('/',vHost);
    if vPos > 0 then begin
      vPort   := Copy(vHost,vPos+1,Length(vHost));
      SetLength(vHost,vPos-1);
    end;
  end else vDBName := aValue;
  Host := vHost;
  Port := vPort;
  DatabaseName := vDBName;
end;

procedure TDatabaseEditorFrame.SetHost(aValue :WideString);
begin
  cmbHost.Text := aValue;
end;

procedure TDatabaseEditorFrame.SetPort(aValue :WideString);
begin
  edtPort.Text := aValue;
end;

procedure TDatabaseEditorFrame.Clear;
begin
  edtDatabase.Text := '';
  edtPort.Text := '';
  cmbHost.Text := '';
end;

procedure TDatabaseEditorFrame.ToScreen;
begin
  if Assigned(FDatabase) then begin
    if FDatabase.Host <> '' then
      FullDBName := FDatabase.Host+':'+FDatabase.Database
    else
      FullDBName := FDatabase.Database;
  end;
end;

procedure TDatabaseEditorFrame.FromScreen;
begin
  FDatabase.Database := FullDBName;
end;

end.


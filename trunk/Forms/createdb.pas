unit CreateDb;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, FileUtil, {LResources,} Forms, Controls,
  Graphics, Dialogs, StdCtrls, Buttons, ExtCtrls, utbcommon;

type

  { TfmCreateDB }

  TfmCreateDB = class(TForm)
    bbCreate         : TBitBtn;
    btDBFileName     : TButton;
    bbCancel         : TBitBtn;
    cbCharset        : TComboBox;
    edUserName       : TEdit;
    edNewDatabase    : TEdit;
    edPassword       : TEdit;
    IBConnection1    : TIBConnection;
    Image1           : TImage;
    lblServerDBName  : TLabel;
    lblUserName      : TLabel;
    lblPassword      : TLabel;
    lblCharset       : TLabel;
    SaveDialog1      : TSaveDialog;
    procedure bbCreateClick(Sender: TObject);
    procedure btDBFileNameClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  fmCreateDB: TfmCreateDB;

implementation

uses Reg;
 {$R *.lfm}
{ TfmCreateDB }

procedure TfmCreateDB.btDBFileNameClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    edNewDatabase.Text:= SaveDialog1.FileName;
  end;
end;

procedure TfmCreateDB.FormCreate(Sender: TObject);
begin
  // Load available character sets. Because we are not connected to a server,
  // we cannot retrieve the available charater sets.
  // Perhaps this can be done through the Services API but not high priority
  CbCharSet.Items.AddStrings(FBCharacterSets);
  CbCharSet.ItemIndex:=DefaultFBCharacterSet;
end;

procedure TfmCreateDB.bbCreateClick(Sender: TObject);
begin
  IBConnection1.UserName:= edUserName.Text;
  IBConnection1.Password:= edPassword.Text;
  IBConnection1.DatabaseName:= edNewDatabase.Text;
  IBConnection1.CharSet:= cbCharset.Text;
  IBConnection1.CreateDB;

  ShowMessage('Successfully created');
  fmReg.edTitle.Clear;
  fmReg.edDatabaseName.Text:= edNewDatabase.Text;
  fmReg.edUserName.Text:= edUserName.Text;
  fmReg.edPassword.Text:= edPassword.Text;
  fmReg.cbCharset.Text:= cbCharset.Text;
  fmReg.NewReg:= True;
  ModalResult:= fmReg.ShowModal;
  ModalResult:= mrOK;
end;

//initialization
//  {$I createdb.lrs}

end.


unit ufrFontEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, Dialogs, ExtCtrls, ColorBox, Graphics;

type
  //JKOZ: main font selection frame, it will be used in options form and in the
  //drop down list of a font combo editor in Freeware version only not open source.
  //{ TODO -oJKOZ -cOptions Editing. : add funcitonality for script selection }
  { TfrFontEdit }

  TfrFontEdit = class(TFrame)
    FontDialog1 :TFontDialog;
    grpEffects  :TCheckGroup;
    cmbColor    :TColorBox;
    cmbScript   :TComboBox;
    edFontName  :TEdit;
    edSize      :TEdit;
    edStyle     :TEdit;
    grpSample   :TGroupBox;
    lblFontName :TLabel;
    lblStyle    :TLabel;
    lblSize     :TLabel;
    lblSample   :TLabel;
    Label5      :TLabel;
    Label6      :TLabel;
    lbFontName  :TListBox;
    lbSize      :TListBox;
    lbStyle     :TListBox;
    procedure edFontNameChange(Sender :TObject);
    procedure edFontNameExit(Sender :TObject);
    procedure lbFontNameSelectionChange(Sender :TObject; User :boolean);
  private
    { private declarations }
    FEditFont :TFont;
    function  GetFont :TFont;
    procedure SetFont(aValue :TFont);
    procedure ObjectToScreen; unimplemented;
    procedure ScreenToObject; unimplemented;
    function  StyleString(const aStyle :TFontStyles):String;
  public
    { public declarations }
    property EditFont:TFont read GetFont write SetFont;
    constructor Create(aOwner :TComponent); override;
  end;

implementation

{$R *.lfm}

{ TfrFontEdit }

procedure TfrFontEdit.lbFontNameSelectionChange(Sender :TObject; User :boolean);
begin
  edFontName.Text := lbFontName.Items[lbFontName.ItemIndex];
  lblSample.Font.Name := edFontName.Text;
end;

procedure TfrFontEdit.edFontNameExit(Sender :TObject);
begin
  //select the first partialy equal font name.
end;

procedure TfrFontEdit.edFontNameChange(Sender :TObject);
begin
  //{ TODO -oJKOZ -cUsability : select the first font that starts with the text keyed in. }
end;

function TfrFontEdit.GetFont :TFont;
begin
  ScreenToObject;
  Result := FEditFont;
end;

procedure TfrFontEdit.SetFont(aValue :TFont);
begin
  FEditFont := aValue;
  ObjectToScreen;
end;

procedure TfrFontEdit.ObjectToScreen;
begin
  //Font Name;
  edFontName.Text       := FEditFont.Name;
  lbFontName.ItemIndex  := lbFontName.Items.IndexOf(FEditFont.Name);
  //-------------------
  edStyle.Text          := StyleString(FEditFont.Style);
  lbStyle.ItemIndex     := lbStyle.Items.IndexOf(edStyle.Text);
  grpEffects.Checked[0] := fsStrikeOut in FEditFont.Style;
  grpEffects.Checked[1] := fsUnderline in FEditFont.Style;
  //-------------------
  edSize.Text           := IntToStr(FEditFont.Size);
  lbSize.ItemIndex      := lbSize.Items.IndexOf(edSize.Text);
  //-------------------
  cmbColor.Selected := FEditFont.Color;
  //cmbScript.Text    := string(FEditFont.CharSet);//JKOZ write a charset to string function.
  //---------------------
  lblSample.Font        := FEditFont;//uses assign internally.

end;

procedure TfrFontEdit.ScreenToObject;
begin
  FEditFont.Name                           := edFontName.Text;
  //-------------------
  case lbStyle.ItemIndex of
    0: FEditFont.Style := [];
    1: FEditFont.Style := [fsBold];
    2: FEditFont.Style := [fsItalic];
    3: FEditFont.Style := [fsBold,fsItalic];
  end;
  if grpEffects.Checked[0] then FEditFont.Style := FEditFont.Style +[fsStrikeOut];
  if grpEffects.Checked[1] then FEditFont.Style := FEditFont.Style +[fsUnderline];
  //-------------------
  FEditFont.Size                 := StrToInt(edSize.Text);
  //-------------------
  FEditFont.Color                          := cmbColor.Selected;
  FEditFont.CharSet                        := PtrInt(cmbScript.Items.Objects[cmbScript.ItemIndex]);
  //---------------------
  lblSample.Font := FEditFont;
end;

function TfrFontEdit.StyleString(const aStyle :TFontStyles) :String;
begin
  Result := '';
  if fsBold in aStyle then Result := 'Bold';
  if fsItalic in aStyle then Result := Result + ' Ialic';
  Result := Trim(Result);
  if Result = '' then Result:='Regular';
end;

constructor TfrFontEdit.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  lbFontName.Items.Clear;
  lbFontName.Items.AddStrings(Screen.Fonts);
  Font.CharSet;
end;

end.


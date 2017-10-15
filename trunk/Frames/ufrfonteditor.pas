unit ufrFontEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, strings, FileUtil, Forms, Controls, StdCtrls, Dialogs, ExtCtrls, ColorBox, Graphics, LCLType, LMessages, strutils;

type
  //JKOZ: main font selection frame, it will be used in options form and in the
  //drop down list of a font combo editor in Freeware version only not open source.
  //{ TODO -oJKOZ -cOptions Editing. : add funcitonality for script selection }

  { TListBox }
  //Failed Experiment for some reason the control refuses to handle the key passed.
  //TListBox = class(StdCtrls.TListBox)
  //public
  //  procedure PerformKeyDown(var aKey:Word; aShift:TShiftState);
  //end;

  { TEvsFontEditFrame }

  TEvsFontEditFrame = class(TFrame)
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
    procedure cmbColorChange(Sender :TObject);
    procedure edFontNameChange(Sender :TObject);
    procedure edFontNameKeyDown(Sender :TObject; var Key :Word; Shift :TShiftState);
    procedure edSizeChange(Sender :TObject);
    procedure edSizeKeyDown(Sender :TObject; var Key :Word; Shift :TShiftState);
    procedure edStyleChange(Sender :TObject);
    procedure edStyleKeyDown(Sender :TObject; var Key :Word; Shift :TShiftState);
    procedure grpEffectsItemClick(Sender :TObject; Index :integer);
    procedure lbFontNameSelectionChange(Sender :TObject; User :boolean);
    procedure lbSizeSelectionChange(Sender :TObject; User :boolean);
    procedure lbStyleSelectionChange(Sender :TObject; User :boolean);
  private
    { private declarations }
    FEditFont :TFont;
    FControlChar:Boolean;
    function GetStyleFromListBox:TFontStyles;
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

{ TListBox }

//procedure TListBox.PerformKeyDown(var aKey :Word; aShift :TShiftState);
//begin
//  ControlKeyDown(aKey, aShift);
//end;

{ TEvsFontEditFrame }

procedure TEvsFontEditFrame.lbFontNameSelectionChange(Sender :TObject; User :boolean);
begin
  //edFontName.Text := lbFontName.Items[lbFontName.ItemIndex];
  if lbFontName.ItemIndex > -1 then begin
    lblSample.Font.Name := lbFontName.Items.Strings[lbFontName.ItemIndex];
    if not FControlChar then begin
      edFontName.Text     := lbFontName.Items.Strings[lbFontName.ItemIndex];
      edFontName.SelectAll;
    end;
  end;
end;

procedure TEvsFontEditFrame.lbSizeSelectionChange(Sender :TObject; User :boolean);
begin
  if lbSize.ItemIndex > -1 then begin
    if not FControlChar then begin
      edSize.Text     := lbSize.Items.Strings[lbSize.ItemIndex];
      //edSize.SelectAll;
    end;
  end else edSize.Text := '0';
  lblSample.Font.Size := StrToIntDef(edSize.Text,0);
end;

procedure TEvsFontEditFrame.lbStyleSelectionChange(Sender :TObject; User :boolean);
begin
  if lbStyle.ItemIndex > -1 then begin;
    if not FControlChar then begin
      edStyle.Text     := lbStyle.Items.Strings[lbStyle.ItemIndex];
      edStyle.SelectAll;
    end;
  end else edStyle.Text := '';
  lblSample.Font.Style := GetStyleFromListBox;
end;

function TEvsFontEditFrame.GetStyleFromListBox :TFontStyles;
begin
  case lbStyle.ItemIndex of
    0: Result := [];
    1: Result := [fsItalic];
    2: Result := [fsBold];
    3: Result := [fsBold, fsItalic];
  end;
end;

function StartsWith(aSubString, aString:string; aCaseSensitive:Boolean = False):Boolean;
type
  TCompareFunc = function (const S1, S2: string): integer;
var
  vCompare:array[Boolean] of TCompareFunc;
begin //initialization
  Result := False;
  vCompare[False] := @CompareText;
  vCompare[True]  := @CompareStr;
  //check for if the string starts with the substring
  if (Length(aSubString) <= Length(aString)) then begin
    SetLength(aString, Length(aSubString));
    Result := vCompare[aCaseSensitive](aSubString,aString) = 0;
  end;
end;

function EndsWith(aSubString, aString:string; CaseSensitive:Boolean = False):Boolean;
type
  TCompareFunc = function (const S1, S2: string): integer;
var
  vCompare:array[Boolean] of TCompareFunc;
begin //initialization
  Result := False;
  vCompare[False] := @CompareText;
  vCompare[True]  := @CompareStr;
  //check if the string starts with the substring
  if (Length(aSubString) <= Length(aString)) then begin
    aString := Copy(aString, Length(aString) - Length(aSubString), Length(aString));
    SetLength(aString, Length(aSubString));
    Result := vCompare[CaseSensitive](aSubString,aString) = 0;
  end;
end;

procedure TEvsFontEditFrame.edFontNameChange(Sender :TObject);
var
  vCntr :Integer;
  vLen  :Integer;
begin
  //select the first partialy equal font name.

  for vCntr := 0 to lbFontName.Items.Count -1 do begin
    if StartsWith(edFontName.Text,lbFontName.Items.Strings[vCntr]) then begin
      if Not FControlChar then begin
        vLen := Length(edFontName.Text);
        edFontName.Text := lbFontName.Items.Strings[vCntr];
        edFontName.SelStart := vLen;
        edFontName.SelLength := Length(lbFontName.Items.Strings[vCntr])-vLen;
      end;
      lbFontName.ItemIndex := vCntr;
      Break;
    end;
  end;
end;

procedure TEvsFontEditFrame.cmbColorChange(Sender :TObject);
begin
  lblSample.Font.Color := cmbColor.Selected;
end;

function Between(constref aValue, aMin, aMax :Integer):Boolean;inline;
begin
  Result := (aValue >= aMin) and (aValue <= aMax);
end;

function InSet(const aValue:Integer; const aSet:Array of Integer):Boolean;
var
  vItem:Integer;
begin
  Result := False;
  for vItem in aSet do begin
    Result := Result or (vItem = aValue);
    if Result then Exit;
  end;
end;

procedure TEvsFontEditFrame.edFontNameKeyDown(Sender :TObject; var Key :Word; Shift :TShiftState);
begin
  FControlChar := (Key < VK_HELP) and (Key <> VK_SPACE);
  //if InSet(Key, [VK_UP, VK_DOWN, {VK_PRIOR, VK_NEXT}]) then begin
    //lbFontName.PerformKeyDown(Key, Shift); failed for some reason the control does not react on the keys passed.
  if Key = VK_DOWN then begin
    FControlChar := False;
    if (lbFontName.ItemIndex < lbFontName.Items.Count -1) then lbFontName.ItemIndex := lbFontName.ItemIndex + 1;
    Key := VK_UNKNOWN;
  end else if Key = VK_UP then begin
    FControlChar := False;
    if lbFontName.ItemIndex > 0 then lbFontName.ItemIndex := lbFontName.ItemIndex - 1;
    Key := VK_UNKNOWN;
  end;
  //end;
end;

procedure TEvsFontEditFrame.edSizeChange(Sender :TObject);
var
  vCntr :Integer;
  vLen  :Integer;
begin
  for vCntr := 0 to lbSize.Items.Count -1 do begin
    if StartsWith(edSize.Text,lbSize.Items.Strings[vCntr]) then begin
      if Not FControlChar then begin
        vLen := Length(edSize.Text);
        edSize.Text := lbSize.Items.Strings[vCntr];
        edSize.SelStart := vLen;
        edSize.SelLength := Length(lbSize.Items.Strings[vCntr])-vLen;
      end;
      FControlChar := True;
      lbSize.ItemIndex := vCntr;
      FControlChar := False;
      Break;
    end;
  end;
  lblSample.Font.Size := StrToIntDef(edSize.Text,0);
end;

procedure TEvsFontEditFrame.edSizeKeyDown(Sender :TObject; var Key :Word; Shift :TShiftState);
begin
  FControlChar := (Key < VK_HELP) and (Key <> VK_SPACE);
  if Key = VK_DOWN then begin
    FControlChar := False;
    if (lbSize.ItemIndex < lbSize.Items.Count -1) then lbSize.ItemIndex := lbSize.ItemIndex + 1;
    Key := VK_UNKNOWN;
  end else if Key = VK_UP then begin
    FControlChar := False;
    if lbSize.ItemIndex > 0 then lbSize.ItemIndex := lbSize.ItemIndex - 1;
    Key := VK_UNKNOWN;
  end;
end;

procedure TEvsFontEditFrame.edStyleChange(Sender :TObject);
var
  vCntr :Integer;
  vLen  :Integer;
begin
  //select the first partialy equal font name.
  for vCntr := 0 to lbStyle.Items.Count -1 do begin
    if StartsWith(edStyle.Text,lbStyle.Items.Strings[vCntr]) then begin
      if Not FControlChar then begin
        vLen := Length(edStyle.Text);
        edStyle.Text := lbStyle.Items.Strings[vCntr];
        edStyle.SelStart := vLen;
        edStyle.SelLength := Length(lbStyle.Items.Strings[vCntr])-vLen;
      end;
      lbStyle.ItemIndex := vCntr;
      Break;
    end;
  end;
end;

procedure TEvsFontEditFrame.edStyleKeyDown(Sender :TObject; var Key :Word; Shift :TShiftState);
begin
  FControlChar := (Key < VK_HELP) and (Key <> VK_SPACE);
  if Key = VK_DOWN then begin
    FControlChar := False;
    if (lbStyle.ItemIndex < lbStyle.Items.Count -1) then lbStyle.ItemIndex := lbStyle.ItemIndex + 1;
    Key := VK_UNKNOWN;
  end else if Key = VK_UP then begin
    FControlChar := False;
    if lbStyle.ItemIndex > 0 then lbStyle.ItemIndex := lbStyle.ItemIndex - 1;
    Key := VK_UNKNOWN;
  end;
end;

procedure TEvsFontEditFrame.grpEffectsItemClick(Sender :TObject; Index :integer);
begin
  case Index of
    0: if grpEffects.Checked[Index] then
         lblSample.Font.Style := lblSample.Font.Style + [fsStrikeOut]
       else
         lblSample.Font.Style := lblSample.Font.Style - [fsStrikeOut];
    1: if grpEffects.Checked[Index] then
         lblSample.Font.Style := lblSample.Font.Style + [fsUnderline]
       else
         lblSample.Font.Style := lblSample.Font.Style - [fsUnderline];
  end;
end;

function TEvsFontEditFrame.GetFont :TFont;
begin
  ScreenToObject;
  Result := FEditFont;
end;

procedure TEvsFontEditFrame.SetFont(aValue :TFont);
begin
  FEditFont := aValue;
  ObjectToScreen;
end;

procedure TEvsFontEditFrame.ObjectToScreen;
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

procedure TEvsFontEditFrame.ScreenToObject;
begin
  FEditFont.Name                           := edFontName.Text;
  //-------------------
  FEditFont.Style := GetStyleFromListBox;
  if grpEffects.Checked[0] then FEditFont.Style := FEditFont.Style +[fsStrikeOut];
  if grpEffects.Checked[1] then FEditFont.Style := FEditFont.Style +[fsUnderline];
  //-------------------
  FEditFont.Size    := StrToInt(edSize.Text);
  //-------------------
  FEditFont.Color   := cmbColor.Selected;
  //-------------------
  if cmbScript.ItemIndex > -1 then FEditFont.CharSet := PtrInt(cmbScript.Items.Objects[cmbScript.ItemIndex]);
  //lblSample.Font := FEditFont;
end;

function TEvsFontEditFrame.StyleString(const aStyle :TFontStyles) :String;
begin
  Result := '';
  if fsBold in aStyle then Result := 'Bold';
  if fsItalic in aStyle then Result := Result + ' Ialic';
  Result := Trim(Result);
  if Result = '' then Result:='Regular';
end;

constructor TEvsFontEditFrame.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  lbFontName.Items.Clear;
  lbFontName.Items.AddStrings(Screen.Fonts);
  Font.CharSet;
end;

end.


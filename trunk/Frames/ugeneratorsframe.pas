unit uGeneratorsFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, Spin, uEvsDBSchema;

type

  { TSequenceFrame }

  TSequenceFrame = class(TFrame)
    edtSequenceName :TEdit;
    lblSeqName :TLabel;
    lblCurValue :TLabel;
    sedtSequenceValue :TSpinEdit;
    procedure edtSequenceNameEditingDone(Sender :TObject);
    procedure edtSequenceNameExit(Sender :TObject);
    procedure sedtSequenceValueEditingDone(Sender :TObject);
    procedure sedtSequenceValueExit(Sender :TObject);
  private
    { private declarations }
    FSequence :IEvsSequenceInfo;
    function GetSequenceName :String;
    function GetSequenceValue :Int64;
    procedure SetSequence(aValue :IEvsSequenceInfo);
    procedure SetSequenceName(aValue :String);
    procedure SetSequenceValue(aValue :Int64);
    procedure Clear;
  public
    { public declarations }
    procedure FromScreen;
    property SequenceName:String read GetSequenceName write SetSequenceName;
    property SequenceValue:Int64 read GetSequenceValue write SetSequenceValue;
    property Sequence :IEvsSequenceInfo read FSequence write SetSequence;
  end;

implementation

{$R *.lfm}

{ TSequenceFrame }

procedure TSequenceFrame.SetSequenceName(aValue :String);
begin
  edtSequenceName.Text := aValue;
end;

procedure TSequenceFrame.edtSequenceNameExit(Sender :TObject);
begin
  FromScreen;
end;

procedure TSequenceFrame.edtSequenceNameEditingDone(Sender :TObject);
begin
  FromScreen;
end;

procedure TSequenceFrame.sedtSequenceValueEditingDone(Sender :TObject);
begin
  FromScreen;
end;

procedure TSequenceFrame.sedtSequenceValueExit(Sender :TObject);
begin
  FromScreen;
end;

function TSequenceFrame.GetSequenceName :String;
begin
  Result := edtSequenceName.Text;
end;

function TSequenceFrame.GetSequenceValue :Int64;
begin
  Result := sedtSequenceValue.Value;
end;

procedure TSequenceFrame.SetSequence(aValue :IEvsSequenceInfo);
begin
  if FSequence = aValue then Exit;
  FSequence := aValue;
  if Assigned(FSequence) then begin
    SetSequenceName(FSequence.Name);
    SetSequenceValue(FSequence.CurrentValue);
  end else Clear;
end;

procedure TSequenceFrame.SetSequenceValue(aValue :Int64);
begin
  sedtSequenceValue.Value := aValue;
end;

procedure TSequenceFrame.Clear;
begin
  SetSequenceName('');
  SetSequenceValue(0);
end;

procedure TSequenceFrame.FromScreen;
begin
  if Assigned(FSequence) then begin
    FSequence.Name := SequenceName;
    FSequence.CurrentValue := SequenceValue;
  end;
end;

end.


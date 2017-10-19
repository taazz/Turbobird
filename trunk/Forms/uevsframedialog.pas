unit uEvsFrameDialog;
 {LICENSE GPL}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel, uTBCommon, uTBTypes;

type

  { TEvsFrameDialog }

  TEvsFrameDialog = class(TForm)
    ButtonPanel1 :TButtonPanel;
    procedure CancelButtonClick(Sender :TObject);
    procedure CloseButtonClick(Sender :TObject);
    procedure OKButtonClick(Sender :TObject);
  private
    { private declarations }
  public
    { public declarations }
    function Execute(const aFrame :TFrame = Nil):Boolean;
  end;

var
  EvsFrameDialog : TEvsFrameDialog;

implementation

{$R *.lfm}

{ TEvsFrameDialog }

procedure TEvsFrameDialog.OKButtonClick(Sender :TObject);
begin
  ModalResult := mrOK;
end;

procedure TEvsFrameDialog.CancelButtonClick(Sender :TObject);
begin
  ModalResult := mrCancel;
end;

procedure TEvsFrameDialog.CloseButtonClick(Sender :TObject);
begin
  ModalResult := mrClose;
end;

function TEvsFrameDialog.Execute(const aFrame :TFrame) :Boolean;
var
  vParent  : TWinControl = nil;
  vTopLeft : TPoint;
begin
  vParent := nil;
  vTopLeft := Point(0,0);
  try
    if Assigned(aFrame) then begin
      vTopLeft := Point(aframe.Left, aFrame.Top);
      vParent  := aFrame.Parent;
      Width := cHBorderGap+aFrame.Width+cHBorderGap;
      Height := cVBorderGap+aFrame.Height+cVBorderGap+ButtonPanel1.Height;
      aFrame.Top := cVBorderGap;
      aFrame.Left := cHBorderGap;
      aFrame.Parent := Self;
    end;
    Result := (ShowModal = mrOK);
  finally
    if Assigned(aFrame) then begin
      //make sure that the backups have real values or do not use them.
      if Assigned(vParent) then aFrame.Parent := vParent;
      if vTopLeft.X <> 0 then aFrame.Left := vTopLeft.X;
      if vTopLeft.Y <> 0 then aFrame.Top  := vTopLeft.Y;
    end;
  end;
end;

end.


unit uEvsFrameDialog;
 {LICENSE GPL}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel;

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
    function Execute:Boolean;
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

function TEvsFrameDialog.Execute :Boolean;
begin
  Result := (ShowModal = mrOK);
end;

end.


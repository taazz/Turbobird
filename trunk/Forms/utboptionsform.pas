unit uTBOptionsform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ColorBox;

type

  { TForm1 }

  TForm1 = class(TForm)
  private
    { private declarations }
    FFont : TFont;
    function GetFont :TFont;
    procedure SetFont(aValue :TFont);
  protected
    Procedure ScreenToObject;
    procedure ObjectToScreen;
  public
    { public declarations }
    property EditFont :TFont read GetFont write SetFont;
  end;

//var
//  Form1 : TForm1;

implementation

{$R *.lfm}

{ TForm1 }

function TForm1.GetFont :TFont;
begin
  ScreenToObject;
end;

procedure TForm1.SetFont(aValue :TFont);
begin
  ObjectToScreen;
end;

Procedure TForm1.ScreenToObject;
begin

end;

procedure TForm1.ObjectToScreen;
begin

end;

end.


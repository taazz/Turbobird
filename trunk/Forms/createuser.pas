{ TODO -oJKOZ -cSecurity : Custom Password Control that hides it self from password reveal utility. }unit CreateUser;

{$mode objfpc}

interface

uses
  Classes, SysUtils, math, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, ExtCtrls, LCLIntf, LCLType, LMessages, utbcommon, uTBTypes, types;

type

  { TEvsEdit }
  //hacking around to convert the * password char to the dot that newer windows use.
  TEvsEdit = class(TCustomEdit)
    procedure SetEchoMode(Val :TEchoMode); override;
    procedure SetReadOnly(Value :Boolean); override;
  end;

  { TShape } //the round corners are a bit too small make them bigger.

  TShape = class(ExtCtrls.TShape)
  public
    procedure Paint; override;
  end;

  { TfmCreateUser }

  TfmCreateUser = class(TForm)
    bbCreate: TBitBtn;
    bbCanel: TBitBtn;
    cbRoles: TComboBox;
    cxGrantRole: TCheckBox;
    edUserName: TEdit;
    edPassword: TEdit;
    Image1: TImage;
    Image3 :TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4 :TLabel;
    Label5 :TLabel;
    lblRole :TLabel;
    Shape1 :TShape;
    Shape2 :TShape;
    procedure cxGrantRoleChange(Sender: TObject);
    procedure FormCreate(Sender :TObject);
    procedure Shape1MouseDown(Sender :TObject; Button :TMouseButton; Shift :TShiftState; X, Y :Integer);
    procedure Shape1MouseMove(Sender :TObject; Shift :TShiftState; X, Y :Integer);
    procedure Shape1MouseUp(Sender :TObject; Button :TMouseButton; Shift :TShiftState; X, Y :Integer);
  private
    { private declarations }
    FMouse : Boolean;
    FStart : TPoint;
    function GetPassword :String;
    function GetRole :string;
    function GetUserName :String;
    procedure SetPassword(aValue :String);
    procedure SetRole(aValue :string);
    procedure SetUserName(aValue :String);
  public
    { public declarations }
    //procedure Init(dbIndex: Integer); deprecated 'Pass the TDBInfo not the index';
    procedure Init(const DBInfo:TDBInfo);
    procedure Clear;
    property UserName:String read GetUserName write SetUserName;
    property Password:String read GetPassword write SetPassword;
    property Role:string read GetRole write SetRole; //can have any number of roles you want seperated with semicolumn ';'.
                                                     //input only from keyboard at this time. A multi check combo box is rquired.
  end;

var
  fmCreateUser: TfmCreateUser;

implementation
{$R *.lfm}
uses main, SysTables;
const
  cDiv = 3; //round corners of the borders, do not use it.
{ TShape }

procedure TShape.Paint;
var
  PaintRect: TRect;
  MinSize: Longint;
  P: array[0..3] of TPoint;
  PenInc, PenDec: Integer;
begin //make the round corners a bit bigger
  if  Shape = stRoundRect then begin
    Canvas.Pen := Pen;
    Canvas.Brush := Brush;
    PenInc := Pen.Width div 2;
    PenDec := (Pen.Width - 1) div 2;
    PaintRect := Rect(PenInc, PenInc, Self.Width - PenDec, Self.Height - PenDec);
    if PaintRect.Left = PaintRect.Right then PaintRect.Right := PaintRect.Right + 1;
    if PaintRect.Top = PaintRect.Bottom then PaintRect.Bottom := PaintRect.Bottom + 1;
    MinSize := Min(PaintRect.Right - PaintRect.Left, PaintRect.Bottom - PaintRect.Top);
    Canvas.RoundRect(PaintRect, MinSize div cDiv, MinSize div cDiv);
    if Assigned(OnPaint) then OnPaint(Self);
  end else
    inherited Paint;
end;

{ TEvsEdit }

procedure TEvsEdit.SetEchoMode(Val :TEchoMode);
begin
  inherited SetEchoMode(Val);
end;

procedure TEvsEdit.SetReadOnly(Value :Boolean);
begin
  inherited SetReadOnly(Value);
end;

{ TfmCreateUser }



procedure TfmCreateUser.cxGrantRoleChange(Sender: TObject);
begin
  cbRoles.Visible:= cxGrantRole.Checked;
end;

procedure TfmCreateUser.FormCreate(Sender :TObject);
var
  vMin: Longint;
  vRgn, vRgn2 :HRGN;
  vRect:TRect;
  vRegion:TRegion;
begin
  {algorithm copied from Tshape.paint}
  vRect := Rect(Shape1.Left+(Shape1.Pen.Width div 2), Shape1.Top+(Shape1.Pen.Width div 2), Shape1.Width - ((Shape1.Pen.Width - 1) div 2), Shape1.Height - ((Shape1.Pen.Width - 1) div 2));
  if vRect.Left = vRect.Right then Inc(vRect.Right);
  if vRect.Top = vRect.Bottom then Inc(vRect.Bottom);
    vMin := Math.Min(vRect.Right - vRect.Left, vRect.Bottom - vRect.Top);
  InflateRect(vRect,1,1);
  vRgn := CreateRoundRectRgn(vRect.Left,vRect.Top,vRect.Right,vRect.Bottom, vMin div cDiv, vMin div cDiv);
  vRect := Shape2.ClientRect;
  OffsetRect(vRect,shape2.Left,shape2.Top);
  InflateRect(vRect,1,1);
  vRgn2 := CreateRectRgn(vRect.Left,vRect.Top,vRect.Right,vRect.Bottom);
  CombineRgn(vRgn, vRgn, vRgn2, RGN_OR);
  SelectClipRGN(GetDC(Handle), vRgn);
  vRegion :=  TRegion.Create;
  vRegion.Handle := vRgn;
  SetShape(vRegion);
  FMouse := False;
end;

procedure TfmCreateUser.Shape1MouseDown(Sender :TObject; Button :TMouseButton; Shift :TShiftState; X, Y :Integer);
begin
  FMouse := True;
  FStart := Point(X, Y);
end;

procedure TfmCreateUser.Shape1MouseMove(Sender :TObject; Shift :TShiftState; X, Y :Integer);
begin
  If FMouse then SetBounds(Left+X-FStart.x,Top+Y-FStart.y,Width,Height);
end;

procedure TfmCreateUser.Shape1MouseUp(Sender :TObject; Button :TMouseButton; Shift :TShiftState; X, Y :Integer);
begin
  FMouse := False;
end;

function TfmCreateUser.GetPassword :String;
begin
  Result := edPassword.Text;
end;

function TfmCreateUser.GetRole :string;
begin
  Result := '';
  if cbRoles.ItemIndex>-1 then
    Result := cbRoles.Text;
end;

function TfmCreateUser.GetUserName :String;
begin
  Result := edUserName.Text;
end;

procedure TfmCreateUser.SetPassword(aValue :String);
begin
  edPassword.Text := aValue;
end;

procedure TfmCreateUser.SetRole(aValue :string);
begin
  cbRoles.Text := aValue;
  cbRoles.ItemIndex := cbRoles.Items.IndexOf(Trim(aValue));
end;

procedure TfmCreateUser.SetUserName(aValue :String);
begin
  edUserName.Text := aValue;
end;

//procedure TfmCreateUser.Init(dbIndex: Integer);
////var
////  Count: Integer=0;
//begin
//  //cbRoles.Items.CommaText:= Trim(dmSysTables.GetDBObjectNames(fmMain.RegisteredDatabases[dbIndex], otRoles, Count));
//  dmSysTables.GetDBObjectNames(fmMain.RegisteredDatabases[dbIndex], otRoles, cbRoles.Items)
//  raise DeprecatedException;
//end;

procedure TfmCreateUser.Init(const DBInfo :TDBInfo);
begin
  dmSysTables.GetDBObjectNames(DBInfo, otRoles, cbRoles.Items)
end;

procedure TfmCreateUser.Clear;
begin
  edUserName.Clear;
  edPassword.Clear;
end;

//initialization
//  {$I createuser.lrs}

end.


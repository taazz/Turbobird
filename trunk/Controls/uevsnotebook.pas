unit uEvsNoteBook;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Graphics, ExtCtrls, uEvsTypes, types, contnrs;

type
  { TODO -oJKOZ -cSpecial : Support for screen reader.  }
  { TODO -oJKOZ -cText : Add support for LTR }

  { TEvsPage }

  TEvsPage = class(TCustomControl)
  private
    { TODO -oJKOZ -cVisuals : Add support for a background image tiled, centered, stretched and semi transparent.}
    { TODO -oJKOZ -cVisuals : Add support for a background gradients.}
    //FPicture      :TPicture;
  protected
    procedure SetVisible(Value :Boolean); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  published
    //property OnBeforeShow: TBeforeShowPageEvent read FOnBeforeShow write FOnBeforeShow;//called from tnotebook directly
    // Other events and properties
    property BiDiMode;
    property ChildSizing;
    property Color;
    property Left stored False;
    property Top stored False;
    property Width stored False;
    property Height stored False;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property ParentBiDiMode;
    property ParentShowHint;
    property PopupMenu;
    property TabOrder stored False;
    property Visible stored False;
  end;

  TEvsPageClass = class of TEvsPage;

  TEvsNotebook = class;

  { TEvsNoteImage }

  TEvsNoteImage = class(TImage){$MESSAGE WARN 'Needs Implementation'}
    constructor Create(aOwner :TComponent); override;
  end;
  TEvsPageEnumerator = class;
  { TEvsNotebook }

  TEvsNotebook = class(TCustomControl)
  private
  { TODO -oJKOZ -cVisuals : Add a background image/picture mostly centered/tiled. Allow childcontrols to replicate the image when added. }
    FPageIndex  :Integer;
    FPageList   :TObjectList;
    FBackGround :Graphics.TPicture;{$MESSAGE WARN 'Needs Implementation'}
    function GetActiveCaption: String;
    function GetActivePage: TEvsPage;
    function GetPage(AIndex: Integer): TEvsPage;
    function GetPageCount : integer;
    function GetPageIndex: Integer;
    procedure InsertPage(APage: TEvsPage; Index: Integer);
  protected
    function ChildClassAllowed(ChildClass :TClass) :Boolean; override;
    procedure Notification (aComponent :TComponent; aOperation :TOperation); override;
    function RemovePage(Index: Integer):TEvsPage;
    function GetTrueIndex(Const aIndex:integer):Integer;
    procedure SetActivePage(aValue :TEvsPage);virtual;
    procedure SetPageIndex(aValue: Integer);virtual;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure InsertControl(aControl: TControl; Index: Integer); override;
    procedure RemoveControl(aControl: TControl); override;
    procedure ShowControl(AControl: TControl); override;
  public
    function IndexOf(const aPage:TEvsPage):Integer;
    function IndexOf(const aCaption:string):Integer;
    function NewPage(aCaption:TCaption):TEvsPage;virtual;overload;
    Procedure NextPage(const aForward:Boolean);
    property ActiveCaption: String read GetActiveCaption;// write SetActivePage;
    property ActivePage: TEvsPage read GetActivePage write SetActivePage;
    property Page[Index: Integer]: TEvsPage read GetPage;
    property PageCount: integer read GetPageCount;
    function Pages : TEvsPageEnumerator;
  published
    property PageIndex: Integer read GetPageIndex write SetPageIndex default -1;
    // Generic properties
    property Align;
    property AutoSize;
    property Anchors;
    property BiDiMode;
    property BorderSpacing;
    property Color;
    property Constraints;
    property DragCursor;
    property DragMode;
    property Enabled;
    property OnChangeBounds;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDrag;
    property ParentBiDiMode;
    property PopupMenu;
    property TabOrder;
    property TabStop;
  end;

  { TEvsPageEnumerator }

  TEvsPageEnumerator = class
  private
    FNotebook :TEvsNotebook;
    FPosition :Integer;
  public
    constructor Create(aComponent: TEvsNotebook);
    function GetCurrent: TEvsPage;
    function MoveNext: Boolean;
    property Current: TEvsPage read GetCurrent;
  end;

implementation

function CheckBounds(aLowerLimit, aUpperLimit, aIndex:Integer; const aSender:String=''; const RaiseException:Boolean=False):Boolean;
begin
  Result := (aIndex>=aLowerLimit) and (aIndex<=aUpperLimit);
  if not Result and RaiseException then
    raise EEvsException.CreateFmt('%S Index <%D> out of bounds',[aSender,aIndex]) at get_caller_addr(get_frame);
end;

{ TEvsPageEnumerator }

constructor TEvsPageEnumerator.Create(aComponent :TEvsNotebook);
begin
  inherited Create;
  FNotebook := AComponent;
  FPosition := -1;
end;

function TEvsPageEnumerator.GetCurrent :TEvsPage;
begin
  Result := FNotebook.Page[FPosition];
end;

function TEvsPageEnumerator.MoveNext :Boolean;
begin
  Inc(FPosition);
  Result := FPosition < FNotebook.PageCount;
end;

{ TEvsNoteImage }

constructor TEvsNoteImage.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  ControlStyle := ControlStyle -[csDesignInteractive];
end;

{$REGION ' TNotebook '}
function TEvsNotebook.GetActiveCaption: String;
begin
  Result := ActivePage.Caption;
end;

function TEvsNotebook.GetActivePage: TEvsPage;
begin
  Result := nil;
  if CheckBounds(0,PageCount-1, PageIndex, '', False) then
    Result := Page[FPageIndex];
end;

function TEvsNotebook.GetPage(AIndex: Integer): TEvsPage;
begin
  CheckBounds(0, PageCount-1, AIndex,'GetPage :', True);
  Result := TEvsPage(FPageList.Items[AIndex]);
end;

function TEvsNotebook.GetPageCount :integer;
begin
  Result := FPageList.Count;
end;

function TEvsNotebook.GetPageIndex: Integer;
begin
  Result := FPageIndex;
end;

procedure TEvsNotebook.InsertPage(APage: TEvsPage; Index: Integer);
begin
  if FPageList.IndexOf(APage) >= 0 then Exit;

  FPageList.Insert(Index, APage);

  APage.Parent := Self;
  APage.Align := alClient;
  APage.Visible := False;
  APage.ControlStyle := APage.ControlStyle + [csNoDesignVisible];

  if PageIndex = -1 then SetPageIndex(Index);
end;

procedure TEvsNotebook.SetActivePage(aValue :TEvsPage);
var
  vIdx:Integer;
begin
  vIdx := IndexOf(aValue);
  if vIdx > -1 then SetPageIndex(vIdx);
end;

function TEvsNotebook.RemovePage(Index :Integer) :TEvsPage;
begin
  Result := Page[Index];
  Result.Parent := Nil;
end;

function TEvsNotebook.GetTrueIndex(Const aIndex :integer) :Integer;
begin
  //controlcount has all controls that are parented to this notebook
  //FPageList.count has all page lists that are parented to this notebook
  //the difference of the two counts dictates the index in the page list and in the tablist.
  Result := aIndex - ControlCount + FPageList.Count;
  //this must only be used inside the insertcontrol and removeconhtrol methods where index is defined by lcl
end;

procedure TEvsNotebook.SetPageIndex(aValue: Integer);
var
  vTmp: TEvsPage;
begin
  if (not CheckBounds(-1, FPageList.Count-1 ,aValue)) or (FPageIndex = aValue) then Exit;

  vTmp := GetActivePage;
  if Assigned(vTmp) then begin
    if (csDesigning in ComponentState) then vTmp.ControlStyle := vTmp.ControlStyle + [csNoDesignVisible];
    vTmp.Visible := False;
  end;

  FPageIndex := AValue;
  if (FPageIndex = -1) then
    Exit;

  vTmp := Page[FPageIndex];
  vTmp.Visible := True;
  if csDesigning in ComponentState then vTmp.ControlStyle := vTmp.ControlStyle - [csNoDesignVisible];
  vTmp.Align := alClient;
end;

function TEvsNotebook.ChildClassAllowed(ChildClass :TClass) :Boolean;
begin
  Result := inherited ChildClassAllowed(ChildClass)
  //This needs more of the EVS library.
  //Result := (ChildClass = TEvsPage) or (ChildClass = TEvsNoteImage) or (ChildClass = TEvsTabset); //only TEvsPage controls are allowed in this container
end;

procedure TEvsNotebook.InsertControl(aControl :TControl; Index :Integer);
var
  vDif : Integer;
begin
  inherited InsertControl(aControl, Index);
  if (AControl is TEvsPage) and (FPageList.IndexOf(aControl) <0 )then begin
    //if page list count is different than control count then the index provided
    //must be shifted down. This means that the notebook is parent to other controls
    //like the tabset or a background image etc those controls usually are static
    //and added before any page was ever created. all other controls use a page as a parent.
    Index := GetTrueIndex(Index) + 1;//1 because controlcount already includes the new page.
    FPageList.Insert(Index, aControl);
    aControl.FreeNotification(Self);
    //if PageIndex = -1 then
    //  SetPageIndex(Index);
  end;
end;

procedure TEvsNotebook.RemoveControl(aControl :TControl);
begin
  inherited RemoveControl(AControl);
  if csDestroying in ComponentState then Exit;
  if (AControl is TEvsPage) then begin
    if ActivePage = aControl then
      NextPage(False);
    FPageList.Extract(AControl);
    if FPageList.Count = 0 then FPageIndex := -1;
    if not (csDestroying in aControl.ComponentState) then aControl.RemoveFreeNotification(Self);
  end;
end;

procedure TEvsNotebook.Notification(aComponent :TComponent; aOperation :TOperation);
begin
  if (aOperation = opRemove) and (aComponent is TEvsPage) then FPageList.Extract(aComponent);
  inherited Notification(aComponent, aOperation);
end;

constructor TEvsNotebook.Create(aOwner: TComponent);
var
  lSize: TSize;
begin
  inherited Create(aOwner);
  FBackGround := TPicture.Create;
  FPageList := TObjectList.create;
  FPageList.OwnsObjects := False;
  FPageIndex := -1;

  ControlStyle := []; // do not add csAcceptsControls
  TabStop := true;

  // Initial size
  lSize := GetControlClassDefaultSize();
  SetInitialBounds(0, 0, lSize.CX, lSize.CY);
end;

destructor TEvsNotebook.Destroy;
begin
  FreeAndNil(FPageList);
  inherited Destroy;
end;

procedure TEvsNotebook.ShowControl(AControl: TControl);
var
  i: Integer;
begin
  if AControl = ActivePage then exit;
  i := FPageList.IndexOf(aControl);
  if i >= 0 then
    PageIndex := i;
  inherited ShowControl(AControl);
end;

function TEvsNotebook.IndexOf(const aPage :TEvsPage) :Integer;
begin
  Result := FPageList.IndexOf(aPage);
end;

function TEvsNotebook.IndexOf(const aCaption :string) :Integer;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to FPageList.Count -1 do begin
    if CompareText(aCaption, Page[vCntr].Caption) = 0 then Exit(vCntr)
  end;
end;

function TEvsNotebook.NewPage(aCaption :TCaption) :TEvsPage;
begin
  Result := TEvsPage.Create(Self);
  Result.Caption := aCaption;
  Result.Visible := False;
  Result.Parent  := Self;
  ActivePage := Result;
end;

Procedure TEvsNotebook.NextPage(const aForward :Boolean{; aVisibleOnly:Boolean = True});
const
  cStep:Array[Boolean] of Integer = (-1,1);
var
  vTmp : Integer;
begin
  if PageCount >0 then begin
    vTmp := PageIndex;
    inc(vTmp, cStep[aForward]);
    if vTmp < 0 then vTmp := PageCount-1;
    if vTmp >= PageCount then vTmp := 0;
    PageIndex := vTmp;
  end;
end;

function TEvsNotebook.Pages :TEvsPageEnumerator;
begin
  Result := TEvsPageEnumerator.Create(Self);
end;


{$ENDREGION}


{$Region ' TPage '}

procedure TEvsPage.SetVisible(Value :Boolean);
begin
  { TODO -oJKOZ -cBehavior : Raise an event give the chance to cancel the operation. }
  inherited SetVisible(Value);
end;

constructor TEvsPage.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  //FPicture := TPicture.Create;
  ControlStyle := ControlStyle +
    [csAcceptsControls, csDesignFixedBounds, csNoDesignVisible, csNoFocus];

  // height and width depends on parent, align to client rect
  Align   := alClient;
  Caption := '';
  Visible := False;
end;

destructor TEvsPage.Destroy;
begin
  //FPicture.Free;
  inherited Destroy;
end;
{$ENDREGION}

end.


unit uEvsTabNotebook;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, typinfo, Controls, Graphics, ExtCtrls ,ComCtrls, {$IFDEF EvosiLib} uEvsTypes, {$ENDIF}
  uEvsNoteBook, ATTabs;

type
  EEvsPageControl = class({$IFDEF EvosiLib} EEvsException {$ELSE} Exception {$ENDIF});
  TEvsNewTabClick = procedure(var Allow:Boolean; var aCaption:string; var aChildClass:TControlClass = nil) of Object;
  { TEvsATTabsNoteBook }

  TEvsATTabsNoteBook = class(TEvsNotebook)
  private
    FOnChanging      :TATTabChangeQueryEvent;
    FOnNewTabClicked :TEvsNewTabClick;
    FPageClass :TEvsPageClass;
    FTabPosition     :TTabPosition;
    FTabSet          :TATTabs;
    function GetAddButtonVisible :Boolean;
    function GetNewPageButton :Boolean;
    function GetTabset :TATTabs;
    function GetTabsVisible :Boolean;
    procedure SetAddButtonVisible(aValue :Boolean);
    procedure SetNewPageButton(aValue :Boolean);
    procedure SetOnChanging(aValue :TATTabChangeQueryEvent);
    procedure SetOnNewTabClicked(aValue :TEvsNewTabClick);
    procedure SetPageClass(aValue :TEvsPageClass);
    procedure SetTabPosition(aValue :TTabPosition);
    procedure SetTabSet(aValue :TATTabs);
    procedure SetTabsVisible(aValue :Boolean);
  protected
    procedure DoNewTab(aSender :TObject);
    procedure TabChanging(Sender: TObject; ANewTabIndex: Integer; var ACanChange: boolean) ;
    procedure TabClosing(Sender: TObject; ATabIndex: Integer; var ACanClose, aCanContinue: Boolean);
    property Tabset:TATTabs read GetTabset write SetTabSet;
    procedure ApplyTheme1;
    function TabIndex(const aPage:TEvsPage):Integer;
  public
    constructor Create(aOwner :TComponent); override;
    property PageClass:TEvsPageClass read FPageClass write SetPageClass;
    function NewPage(aCaption :TCaption) :TEvsPage; override; overload;
    function AddChildToNewPage(const aCaption :String; const aChild :TControl=nil; ChildAlignment :TAlign=alClient) :TEvsPage; overload;
    function AddNewPage(const aCaption :String; const aChildClass :TControlClass=nil; ChildAlignment :TAlign=alClient) :TEvsPage; overload;
    procedure DeletePage(const aPage:TEvsPage);
    Property NewPageButton:Boolean read GetNewPageButton write SetNewPageButton;
    property OnChanging :TATTabChangeQueryEvent read FOnChanging write SetOnChanging;
    property ShowAddTabButton:Boolean read GetAddButtonVisible write SetAddButtonVisible;
    Property ShowTabs:Boolean read GetTabsVisible write SetTabsVisible;
    property TabPosition : TTabPosition read FTabPosition write SetTabPosition default tpTop; //tpLeft, tpRight are not supported

    property OnNewTabClicked:TEvsNewTabClick read FOnNewTabClicked write SetOnNewTabClicked;
  end;


implementation
{$IFNDEF EvosiLib}
type

  EEvsException = class(exception)

  end;

{$ENDIF}
function EvsRandomColor :TColor;
begin
  Result := RGBToColor(150 + Round(Random*100), 150 + round(Random*100),155 + round(random*100));
end;


{$REGION ' TEvsNoteBook '}

function TEvsATTabsNoteBook.GetTabset :TATTabs;
begin
  Result := FTabSet;
end;

function TEvsATTabsNoteBook.GetTabsVisible :Boolean;
begin
  Result := FTabSet.Visible;
end;

procedure TEvsATTabsNoteBook.SetAddButtonVisible(aValue :Boolean);
begin
  FTabSet.TabShowPlus := aValue;
end;

function TEvsATTabsNoteBook.GetNewPageButton :Boolean;
begin
  Result := FTabSet.TabShowPlus;
end;

function TEvsATTabsNoteBook.GetAddButtonVisible :Boolean;
begin
  Result := FTabSet.TabShowPlus;
end;

procedure TEvsATTabsNoteBook.SetNewPageButton(aValue :Boolean);
begin
  if FTabSet.TabShowPlus <> aValue then Exit;
    FTabSet.TabShowPlus :=aValue;
end;

procedure TEvsATTabsNoteBook.SetOnChanging(aValue :TATTabChangeQueryEvent);
begin
  FOnChanging := aValue;
end;

procedure TEvsATTabsNoteBook.SetOnNewTabClicked(aValue :TEvsNewTabClick);
begin
  if FOnNewTabClicked=aValue then Exit;
  FOnNewTabClicked:=aValue;
end;

procedure TEvsATTabsNoteBook.SetPageClass(aValue :TEvsPageClass);
begin
  if FPageClass=aValue then Exit;
  FPageClass:=aValue;
end;

procedure TEvsATTabsNoteBook.SetTabPosition(aValue :TTabPosition);
begin
  if aValue in [tpLeft, tpRight] then
    raise EEvsException.Create('Tab Position. UnSupported Value :'+ typinfo.GetEnumName(TypeInfo(TTabPosition),Integer(aValue)));// enumtostrin aValue) ;
  if FTabPosition=aValue then Exit;
  case avalue of
    tpTop    :begin
                FTabSet.Align     := alTop;
                FTabSet.TabBottom := False;
              end;
    tpBottom :begin
                FTabSet.Align     := alBottom;
                FTabSet.TabBottom := True;
              end;
  end;
  FTabPosition := aValue;
end;

procedure TEvsATTabsNoteBook.SetTabSet(aValue :TATTabs);
begin
  if FTabSet <> aValue then FTabSet.Assign(aValue);
end;

procedure TEvsATTabsNoteBook.SetTabsVisible(aValue :Boolean);
begin
  FTabSet.Visible := aValue;
end;

constructor TEvsATTabsNoteBook.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  FTabSet                := TATTabs.Create(Self);
  FTabSet.Parent         := Self;
  FTabSet.Align          := alTop;
  FTabSet.OnTabClose     := @TabClosing;
  FTabSet.OnTabPlusClick := @DoNewTab;
  FTabSet.OnTabChangeQuery := @TabChanging;
  FTabSet.TabShowPlus      := False;
  FTabSet.TabDoubleClickClose := False;
  FTabSet.TabMiddleClickClose := True;
  FTabPosition                := tpTop;
  ApplyTheme1;
  FPageClass := TEvsPage;
end;

function TEvsATTabsNoteBook.NewPage(aCaption :TCaption) :TEvsPage;
begin
  Result := FPageClass.Create(Self);
  Result.Parent := Self;
  Result.Caption := aCaption;
  Result.Visible := False;
  ActivePage := Result;
end;

function TEvsATTabsNoteBook.AddChildToNewPage(const aCaption :String; const aChild:TControl = nil; ChildAlignment : TAlign = alClient):TEvsPage;
var
  vIdx:Integer;
begin
  Result := NewPage(aCaption);
  vIdx   := IndexOf(Result);
  FTabSet.AddTab(vIdx, aCaption, Result);
  FTabSet.TabIndex := vIDx;
  if Assigned(aChild) then begin
    aChild.Parent    := Result;
    aChild.Align     := ChildAlignment;
  end;
end;

function TEvsATTabsNoteBook.AddNewPage(const aCaption :String; const aChildClass :TControlClass; ChildAlignment :TAlign) :TEvsPage;
var
  vIdx:Integer;
begin
  Result := NewPage(aCaption);
  vIdx   := IndexOf(Result);
  FTabSet.AddTab(vIdx, aCaption, Result);
  FTabSet.TabIndex := vIDx;
  if Assigned(aChildClass) then begin
    with aChildClass.Create(Result) do begin
      Parent := Result;
      Align  := ChildAlignment;
    end;
  end;
end;

procedure TEvsATTabsNoteBook.DeletePage(const aPage :TEvsPage);
var
  vIdx:Integer;
begin
  vIdx := TabIndex(aPage);
  if vIdx > -1 then begin
    FTabSet.DeleteTab(vIdx, False, False);
    aPage.Free;
  end else raise EEvsPageControl.Createfmt('Invalid Page : %S',[aPage.Caption]);
end;

procedure TEvsATTabsNoteBook.DoNewTab(aSender :TObject);
var
  vChild   :TControlClass;
  vAllow   :Boolean = False;
  vCaption :String;
begin
  vCaption := Format('New Tab %D ',[FTabSet.TabCount]);
  if Assigned(FOnNewTabClicked) then FOnNewTabClicked(vAllow, vCaption, vChild);
  if vAllow then AddNewPage(vCaption, vChild);
end;

procedure TEvsATTabsNoteBook.TabChanging(Sender :TObject; ANewTabIndex :Integer; var ACanChange :boolean);
var
  vData:TATTabData;
begin
  if Assigned(FOnChanging) then FOnChanging(Sender,ANewTabIndex, ACanChange);
  if ACanChange then begin;
    vData := FTabSet.GetTabData(ANewTabIndex);
    ACanChange := (vData.TabObject is TEvsPage);
    if ACanChange then begin
      PageIndex := IndexOf(TEvsPage(vData.TabObject));
    end;
  end;
end;

procedure TEvsATTabsNoteBook.TabClosing(Sender :TObject; ATabIndex :Integer; var ACanClose, aCanContinue :Boolean);
var
  vObj:TATTabData;
begin
  if Sender is TATTabs then begin
    vObj := TATTabs(Sender).GetTabData(ATabIndex);
    if Assigned(vObj) and(vObj.TabObject is TEvsPage) then begin
        FreeAndNil(vObj.TabObject);
    end;
    NextPage(False);
  end else aCanClose := False;
end;

procedure TEvsATTabsNoteBook.ApplyTheme1;
begin
  FTabSet.ColorBg         := clBtnFace;
  //FTabSet.ColorBg         := clBtnFace;//how can I convert cldefault to an actual color?
  FTabSet.ColorTabActive  := RGBToColor(240,240,240);
  FTabSet.ColorTabPassive := RGBToColor(190,190,190);
  FTabSet.ColorTabOver    := RGBToColor(200,200,200);;
  FTabSet.Font.Color      := clBlack;
  FTabSet.TabAngle        := 4;
  FTabSet.Height          := 34;
  FTabSet.TabHeight       := 28;
end;

function TEvsATTabsNoteBook.TabIndex(const aPage :TEvsPage) :Integer;
var
  vCntr :Integer;
begin
  for vCntr := 0 to FTabSet.TabCount -1 do begin
    if FTabSet.GetTabData(vCntr).TabObject = aPage then Exit(vCntr);
  end;
end;

{$ENDRegion 'TEvsNoteBook' }

end.


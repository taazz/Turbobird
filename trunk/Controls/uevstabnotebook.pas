unit uEvsTabNotebook;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, typinfo, Controls, Graphics, ExtCtrls ,ComCtrls, {$IFDEF EvosiLib} uEvsTypes, {$ENDIF}
  uEvsNoteBook, ATTabs;

type
  EEvsPageControl = class({$IFDEF EvosiLib} EEvsException {$ELSE} Exception {$ENDIF});
  TEvsNewTabClick = procedure(var Allow:Boolean; var aCaption:string; var aChildClass:TControlClass = nil) of Object;

  { TEvsTabProperties }

  TEvsTabProperties = class(TPersistent)
  private
    function GetHeight :Integer;
    function GetShowCloseButton :Boolean;
    function GetTabAngle :Integer;
    procedure SetHeight(aValue :Integer);
    procedure SetShowCloseButton(aValue :Boolean);
    procedure SetTabAngle(aValue :Integer);
  published
    property TabAngle : Integer read GetTabAngle write SetTabAngle;
    property ShowCloseButton:Boolean Read GetShowCloseButton Write SetShowCloseButton;
    property Height:Integer read GetHeight Write SetHeight;
  end;

  { TEvsATTabsNoteBook }

  TEvsATTabsNoteBook = class(TEvsNotebook)
  private
    FOnChanging      :TATTabChangeQueryEvent;
    FOnNewTabClicked :TEvsNewTabClick;
    FPageClass       :TEvsPageClass;
    FTabPosition     :TTabPosition;
    FTabSet          :TATTabs;
    function GetAddButtonVisible :Boolean;
    function GetNewPageButton :Boolean;
    function GetShowCloseButton :Boolean;
    function GetTabAngle :integer;
    function GetTabData(aIndex :Integer) :TATTabData;
    function GetTabHeight :Integer;
    function GetTabset :TATTabs;
    function GetTabsVisible :Boolean;
    procedure SetAddButtonVisible(aValue :Boolean);
    procedure SetNewPageButton(aValue :Boolean);
    procedure SetOnChanging(aValue :TATTabChangeQueryEvent);
    procedure SetOnNewTabClicked(aValue :TEvsNewTabClick);
    procedure SetPageClass(aValue :TEvsPageClass);
    procedure SetShowCloseButton(aValue :Boolean);
    procedure SetTabAngle(aValue :integer);
    procedure SetTabHeight(aValue :Integer);
    procedure SetTabPosition(aValue :TTabPosition);
    procedure SetTabSet(aValue :TATTabs);
    procedure SetTabsVisible(aValue :Boolean);
  protected
    function  IndexOfTab(aCaption:String):Integer;overload;
    function  IndexOfTab(aPage:TEvsPage):Integer;overload;
    procedure DoNewTabButtonClick(aSender :TObject);
    procedure TabChanging(Sender: TObject; ANewTabIndex: Integer; var ACanChange: boolean) ;
    procedure TabClosing(Sender: TObject; ATabIndex: Integer; var ACanClose, aCanContinue: Boolean);
    property Tabset:TATTabs read GetTabset write SetTabSet;
    procedure ApplyTheme1;
    function TabIndex(const aPage:TEvsPage):Integer;
  protected
    procedure SetActivePage(aValue :TEvsPage); override;
    procedure SetPageIndex(aValue :Integer); override;
    property Tab[aIndex:Integer]:TATTabData read GetTabData;
  public //overriden methods.
    procedure InsertControl(aControl :TControl; Index :Integer); override;
    procedure RemoveControl(aControl :TControl); override;
    property TabHeight : Integer read GetTabHeight write SetTabHeight;
    property TabAngle:integer read GetTabAngle Write SetTabAngle;
  public
    Constructor Create(aOwner :TComponent); override;
    Function NewPage          (aCaption :TCaption) :TEvsPage; override; overload;
    Function NewPage          (aCaption :TCaption; aPageClass:TEvsPageClass) :TEvsPage; overload;
    Function AddChildToNewPage(const aCaption :String; const aChild :TControl=nil; ChildAlignment :TAlign=alClient) :TEvsPage; overload;
    Function AddNewPage       (const aCaption :String) :TEvsPage; overload;deprecated 'Use NewPage Instead';
    Procedure DeletePage      (const aPage:TEvsPage);

    Property PageClass          :TEvsPageClass read FPageClass          write SetPageClass;
    Property NewPageButton      :Boolean       read GetNewPageButton    write SetNewPageButton;
    Property ShowAddTabButton   :Boolean       read GetAddButtonVisible write SetAddButtonVisible;
    Property TabShowCloseButton :Boolean       read GetShowCloseButton  write SetShowCloseButton;
    Property ShowTabs           :Boolean       read GetTabsVisible      write SetTabsVisible;
    Property TabPosition        :TTabPosition  read FTabPosition        write SetTabPosition    default tpTop; //tpLeft, tpRight are not supported

    Property OnNewTabClicked:TEvsNewTabClick        read FOnNewTabClicked write SetOnNewTabClicked;
    Property OnChanging     :TATTabChangeQueryEvent read FOnChanging      write SetOnChanging;
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

{ TEvsTabProperties }

function TEvsTabProperties.GetHeight :Integer;
begin

end;

function TEvsTabProperties.GetShowCloseButton :Boolean;
begin

end;

function TEvsTabProperties.GetTabAngle :Integer;
begin

end;

procedure TEvsTabProperties.SetHeight(aValue :Integer);
begin

end;

procedure TEvsTabProperties.SetShowCloseButton(aValue :Boolean);
begin

end;

procedure TEvsTabProperties.SetTabAngle(aValue :Integer);
begin

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

function TEvsATTabsNoteBook.GetShowCloseButton :Boolean;
begin
  Result := FTabSet.TabShowClose <> tbShowNone;
end;

function TEvsATTabsNoteBook.GetTabAngle :integer;
begin
  Result := FTabSet.TabAngle;
end;

function TEvsATTabsNoteBook.GetTabData(aIndex :Integer) :TATTabData;
begin
  Result := FTabSet.GetTabData(aIndex);
end;

function TEvsATTabsNoteBook.GetTabHeight :Integer;
begin
  Result := FTabSet.TabHeight;
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

procedure TEvsATTabsNoteBook.SetShowCloseButton(aValue :Boolean);
const
  CloseBtnVal : array[Boolean] of TATTabShowClose = (tbShowNone, tbShowAll);
begin
  FTabSet.TabShowClose := CloseBtnVal[aValue];
end;

procedure TEvsATTabsNoteBook.SetTabAngle(aValue :integer);
begin
  FTabSet.TabAngle := aValue;
end;

procedure TEvsATTabsNoteBook.SetTabHeight(aValue :Integer);
begin
  FTabSet.TabHeight := aValue;
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

procedure TEvsATTabsNoteBook.InsertControl(aControl :TControl; Index :Integer);
begin
  inherited InsertControl(aControl, Index);
  Index := GetTrueIndex(Index)+1;//1 because controlcount already includes the new page.
  if aControl is TEvsPage then begin
    FTabSet.AddTab(Index, TEvsPage(aControl).Caption, aControl, False, TEvsPage(aControl).Color);
  end;
end;

procedure TEvsATTabsNoteBook.RemoveControl(aControl :TControl);
var
  vIdx:Integer;
begin
  if aControl is TEvsPage then vIdx := IndexOfTab(TEvsPage(aControl));
  inherited RemoveControl(aControl);
  if vIdx > -1 then FTabSet.DeleteTab(vIdx, False, False);
end;

function TEvsATTabsNoteBook.IndexOfTab(aCaption :String) :Integer;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to FTabSet.TabCount -1 do begin
    if AnsiCompareText(aCaption, Tab[vCntr].TabCaption) = 0 then Exit(vCntr);
  end;
end;

function TEvsATTabsNoteBook.IndexOfTab(aPage :TEvsPage) :Integer;
var
  vCntr :Integer;
  vObj:TObject;
begin
  Result := -1;
  for vCntr := 0 to FTabSet.TabCount -1 do begin
    vObj := Tab[vCntr].TabObject;
    if (Tab[vCntr].TabObject = aPage) then
      Exit(vCntr);
  end;
end;

Constructor TEvsATTabsNoteBook.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  FTabSet                := TATTabs.Create(Self);
  FTabSet.Parent         := Self;
  FTabSet.Align          := alTop;
  FTabSet.OnTabClose     := @TabClosing;
  FTabSet.OnTabPlusClick := @DoNewTabButtonClick;
  FTabSet.OnTabChangeQuery := @TabChanging;
  FTabSet.TabShowPlus      := False;
  FTabSet.TabDoubleClickClose := False;
  FTabSet.TabMiddleClickClose := True;
  FTabPosition                := tpTop;
  FTabSet.TabShowClose := tbShowAll;
  ApplyTheme1;
  FPageClass := TEvsPage;
end;

Function TEvsATTabsNoteBook.NewPage(aCaption :TCaption) :TEvsPage;
begin
  Result := FPageClass.Create(Self);
  Result.Caption := aCaption;
  Result.Visible := False;
  Result.Parent := Self;
  ActivePage := Result;
end;

Function TEvsATTabsNoteBook.NewPage(aCaption :TCaption; aPageClass :TEvsPageClass) :TEvsPage;
begin
  if Assigned(aPageClass ) then
    Result := aPageClass.Create(Self)
  else
    Result := FPageClass.Create(Self);
  Result.Caption := aCaption;
  Result.Visible := False;
  Result.Parent := Self;
  ActivePage := Result;
end;

Function TEvsATTabsNoteBook.AddChildToNewPage(const aCaption :String; const aChild :TControl; ChildAlignment :TAlign) :TEvsPage;
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

Function TEvsATTabsNoteBook.AddNewPage(const aCaption :String) :TEvsPage;
var
  vIdx:Integer;
begin
  Result := NewPage(aCaption);
  vIdx   := IndexOf(Result);
  //FTabSet.AddTab(vIdx, aCaption, Result);
  //FTabSet.TabIndex := vIDx;
  //if Assigned(aChildClass) then begin
  //  with aChildClass.Create(Result) do begin
  //    Parent := Result;
  //    Align  := ChildAlignment;
  //  end;
  //end;
end;

Procedure TEvsATTabsNoteBook.DeletePage(const aPage :TEvsPage);
var
  vIdx:Integer;
begin
  vIdx := TabIndex(aPage);
  if vIdx > -1 then begin
    FTabSet.DeleteTab(vIdx, False, False);
    aPage.Free;
  end else raise EEvsPageControl.Createfmt('Invalid Page : %S',[aPage.Caption]);
end;

procedure TEvsATTabsNoteBook.DoNewTabButtonClick(aSender :TObject);
var
  vChild   :TControlClass;
  vAllow   :Boolean = False;
  vCaption :String;
  vPage    :TEvsPage;
begin
  vCaption := Format('New Tab %D ',[FTabSet.TabCount]);
  if Assigned(FOnNewTabClicked) then FOnNewTabClicked(vAllow, vCaption, vChild);
  if vAllow then begin
    vPage := NewPage(vCaption);
  end;
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
      inherited SetPageIndex(IndexOf(TEvsPage(vData.TabObject)));
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
      FreeAndNil(vObj.TabObject);//remember this one nil first and then free the object
      aCanContinue := True;      //so the removecontrol method will not find the tab to delete.
    end;
  end else
    aCanClose := False;
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

procedure TEvsATTabsNoteBook.SetActivePage(aValue :TEvsPage);
begin
  FTabSet.TabIndex := TabIndex(aValue);
end;

procedure TEvsATTabsNoteBook.SetPageIndex(aValue :Integer);
begin
  Tabset.TabIndex := aValue;
end;

{$EndRegion 'TEvsNoteBook' }

end.


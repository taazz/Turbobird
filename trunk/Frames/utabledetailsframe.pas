unit uTableDetailsFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CommCtrl, FileUtil, Forms, Controls, StdCtrls, ComCtrls, uEvsTabNotebook, uEvsNoteBook, uEvsDBSchema, uTBTypes,
  uTableFieldsFrame;

type

  { TTableDetailsFrame }

  TTableDetailsFrame = class(TFrame)
    Label1 :TLabel;
  private
    { private declarations }
    FTable   :IEvsTableInfo;
    FFieldFr :TTableFieldsFrame;
    FTabset:TEvsATTabsNoteBook;
    procedure SetTable(aValue :IEvsTableInfo);
  public
    { public declarations }
    procedure CreateTabset;
    procedure CreateFieldsTab;
    procedure CreateIndicesTab;
    procedure CreateForeignKeyTab;
    procedure CreateChecksTab;
    procedure CreateTriggersTab;
    constructor Create(aOwner : TComponent); override;
  public
    property Table:IEvsTableInfo read FTable write SetTable;
  end;

implementation

{$R *.lfm}

{ TTableDetailsFrame }

procedure TTableDetailsFrame.SetTable(aValue :IEvsTableInfo);

  //procedure SetPageTable(aPage:TEvsTablePage);
  //var
  //  vControl : TControl;
  //begin
  //  for vControl in aPage.GetEnumeratorControls do begin
  //    if vControl is TTableFieldsFrame then TTableFieldsFrame(vControl).Table := FTable
  //    //else if vControl is TTableFieldsFrame then TTableFieldsFrame(vControl).Table := FTable
  //  end;
  //end;

var
  vCntr :Integer;
begin
  if FTable=aValue then Exit;
  FTable := aValue;
  FFieldFr.Table := FTable;
  //for vCntr := 0 to FTabset.PageCount -1 do begin
  //  if FTabset.Page[vCntr] is TEvsTablePage then
  //    TEvsTablePage(0).Table := FTable;
  //    SetPageTable(TEvsTablePage(FTabset.Page[vCntr]));
  //end;
end;

procedure TTableDetailsFrame.CreateTabset;
begin
  FTabset := TEvsATTabsNoteBook.Create(Self);
  FTabset.Parent    := Self;
  FTabset.Align     := alClient;
  FTabset.TabHeight := 18;
  FTabset.ShowAddTabButton   := False;
  FTabset.TabShowCloseButton := False;
  FTabset.TabPosition := tpBottom;//tpTop;
  FTabset.TabAngle := 0;
end;

procedure TTableDetailsFrame.CreateFieldsTab;
var
  vPage:TEvsPage;
begin
  vPage    := FTabset.NewPage('Fields');
  FFieldFr := TTableFieldsFrame.Create(Self);
  FFieldFr.Align  := alClient;
  FFieldFr.Parent := vPage;
  vPage.Parent    := FTabset;
end;

procedure TTableDetailsFrame.CreateIndicesTab;
begin
  NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

procedure TTableDetailsFrame.CreateForeignKeyTab;
begin
  NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

procedure TTableDetailsFrame.CreateChecksTab;
begin
  NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

procedure TTableDetailsFrame.CreateTriggersTab;
begin
  NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

constructor TTableDetailsFrame.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  CreateTabset;
  CreateFieldsTab;
  CreateIndicesTab;
  CreateForeignKeyTab;
  CreateChecksTab;
  CreateTriggersTab;
end;

end.


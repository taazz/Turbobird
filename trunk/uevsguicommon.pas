unit uEvsGUICommon;

{$mode objfpc}{$H+}

interface

uses //system units
  Classes, SysUtils, Controls, ComCtrls, SynEdit, ActnList,
  //Evosi units.
  uEvsTabNotebook, uEvsNoteBook, uEvsDBSchema, uTBTypes,
  uTableDetailsFrame, uEvsSqlEditor, uGridResultFrame;
  { TEvsDBPage }
const
  cTgNoToolbar = 0;//no toolbar used in the object merge menu only.
  cTgQuery     = 1;//Toolbar group 1 in the case of   query editor this is on the query related toolbar/group.
  cTgData      = 2;//Toolbar group 2 in the case of a query editor this is on the data related toolbar/group.
  cTgEdit      = 3;//Toolbar group 2 in the case of a query editor this is on the data related toolbar/group.

type

  TEvsDBPage = class(TEvsPage)
  private
    FDatabase :IEvsDatabaseInfo;
    function GetDatabase :IEvsDatabaseInfo;virtual;
  protected
    procedure SetDatabase(aValue :IEvsDatabaseInfo);virtual;
  public
    constructor Create(aOwner :TComponent); override;
    destructor Destroy; override;
    property Database:IEvsDatabaseInfo read GetDatabase write SetDatabase;
  end;

  { TEvsQueryPage }

  TEvsQueryPage = class(TEvsDBPage)
  private
    FActionList :TActionList;
    FQueryFrame  :TSqlEditorFrame;
    FResultFrame :TGridResultFrame;
    FTabSet      :TEvsATTabsNoteBook;
    //Query Actions
    actExecute   :TAction;
    //DAta Actions
    actExport    :TAction;
    actImport    :TAction;

    //Editing actions
    actToggleComment :TAction;
    actCopy          :TAction;
    actCut           :TAction;
    actPaste         :TAction;
    actFind          :TAction;
    actReplace       :TAction;

    function GetEditor :TSynEdit;
    function GetSQL :string;
    procedure SetSQL(aValue :string);
  protected
    procedure SetDatabase(aValue :IEvsDatabaseInfo);override;
  public
    constructor Create(aOwner :TComponent); override;overload;
    constructor Create(aOwner :TComponent; aSQL:String); overload;

    property SQLFrame  :TSqlEditorFrame read FQueryFrame;
    property SqlEditor :TSynEdit read GetEditor;
    Property ActionList:TActionList read FActionList;// write SetActionList;
    property Sql :string read GetSQL write SetSQL;
  end;

  { TEvsTablePage }

  TEvsTablePage = class(TEvsDBPage)
  private
    FActionList :TActionList;
    FOnTableChanged :TNotifyEvent;
    FTable          :IEvsTableInfo;
    FFrame          :TTableDetailsFrame;
    function  GetTable :IEvsTableInfo;
    procedure SetActionList(aValue :TActionList);
    procedure SetonTableChanged(aValue :TNotifyEvent);
    procedure SetTable(aValue :IEvsTableInfo);
  protected
    procedure DoTableChanged;virtual;
    procedure SetDatabase(aValue :IEvsDatabaseInfo); override;
    function GetDatabase :IEvsDatabaseInfo; override;
  public
    constructor Create(aOwner :TComponent); override;
    destructor Destroy; override;
    property Table :IEvsTableInfo read GetTable write SetTable;
    property OnTableChanged : TNotifyEvent read FonTableChanged write SetonTableChanged;
    Property ActionList:TActionList read FActionList;// write SetActionList;
  end;

function NewDBPage(const aCaption:String; aControl:TEvsATTabsNoteBook):TEvsDBPage;

resourcestring {$MESSAGE WARN 'Move to a common Resource string file'}
  rsReadOnlyDB = 'Database is a read only property.';
  rsQuery      = 'Query';
  rsResults    = 'Result';
  rsData       = 'Data';

implementation

function NewDBPage(const aCaption :String; aControl :TEvsATTabsNoteBook) :TEvsDBPage;
begin
  Result := TEvsDBPage.Create(aControl);
  Result.Caption := aCaption;
  Result.Parent := aControl;
end;

{ TEvsQueryPage }

function TEvsQueryPage.GetEditor :TSynEdit;
begin
  Result := FQueryFrame.sneQuery;
end;

function TEvsQueryPage.GetSQL :string;
begin
  Result := SqlEditor.Lines.Text;
end;

procedure TEvsQueryPage.SetSQL(aValue :string);
begin
  SqlEditor.Lines.Text := aValue;
end;

procedure TEvsQueryPage.SetDatabase(aValue :IEvsDatabaseInfo);
begin
  inherited SetDatabase(aValue);
  FQueryFrame.Database := aValue;
end;

constructor TEvsQueryPage.Create(aOwner :TComponent);
  procedure InitTabset;
  begin
    FTabSet           := TEvsATTabsNoteBook.Create(Self);
    FTabSet.Align     := alClient;
    FTabSet.TabAngle  := 0;
    FTabSet.TabPosition := tpBottom;
    FTabSet.Parent      := Self;
    FQueryFrame         := TSqlEditorFrame.Create(Self);
    FQueryFrame.Align   := alClient;
    FQueryFrame.Parent  := FTabSet.NewPage(rsQuery);
    FResultFrame        := TGridResultFrame.Create(Self);
    FResultFrame.Align  := alClient;
    FResultFrame.Parent := FTabSet.NewPage(rsResults);
  end;

  Function NewAction(const aCaption, aCategory:String):TAction;
  begin
    Result := TAction.Create(Self);
    Result.ActionList := FActionList;
    Result.Caption    := aCaption;
    Result.Category   := aCategory;
  end;

  procedure InitActions;
  begin
    FActionList    := TActionList.Create(Self);
    actExecute     := NewAction('Execute', rsQuery);
    actExecute.Tag := cTgQuery;                     //Query toolbar.
    actExport      := NewAction('Export', rsData);
    actExport.Tag  := cTgData;                      //Data toolbar.
    actImport      := NewAction('Import', rsData);
    actImport.Tag  := cTgData;                      //Data toolbar.
    actToggleComment     := NewAction('Execute', rsQuery);
    actToggleComment.Tag := cTgEdit;                //Query toolbar.
  end;

begin
  inherited Create(aOwner);
  InitActions;
  InitTabset;
  Sql := '';
end;

constructor TEvsQueryPage.Create(aOwner :TComponent; aSQL :String);
begin
  Create(aOwner);
  Sql := aSQL;
end;

{ TEvsTablePage }

function TEvsTablePage.GetTable :IEvsTableInfo;
begin
  Result := FTable;
end;

procedure TEvsTablePage.SetActionList(aValue :TActionList);
begin
  if FActionList=aValue then Exit;
  FActionList:=aValue;
end;

procedure TEvsTablePage.SetonTableChanged(aValue :TNotifyEvent);
begin
  if FonTableChanged=aValue then Exit;
  FonTableChanged:=aValue;
end;

procedure TEvsTablePage.SetTable(aValue :IEvsTableInfo);
begin
  if FTable <> aValue then begin
    FTable := aValue;
    FFrame.Table := FTable;
    DoTableChanged;
  end;
end;

procedure TEvsTablePage.DoTableChanged;
begin
  if Assigned(FonTableChanged) then FonTableChanged(Self);
end;

procedure TEvsTablePage.SetDatabase(aValue :IEvsDatabaseInfo);
begin
  raise ETBException.Create(rsReadOnlyDB);
end;

function TEvsTablePage.GetDatabase :IEvsDatabaseInfo;
begin
  //Result:=inherited GetDatabase;
  result := GetDatabase(FTable);
end;

constructor TEvsTablePage.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  FTable := Nil;
  FFrame        := TTableDetailsFrame.Create(Self);
  FFrame.Align  := alClient;
  FFrame.Parent := Self;
end;

destructor TEvsTablePage.Destroy;
begin
  FTable := nil; //dec ref count.
  inherited Destroy;
end;

{$REGION ' TEvsDBPage '}

function TEvsDBPage.GetDatabase :IEvsDatabaseInfo;
begin
  Result := FDatabase;
end;

procedure TEvsDBPage.SetDatabase(aValue :IEvsDatabaseInfo);
begin
  if FDatabase=aValue then Exit;
  FDatabase:=aValue;
end;

constructor TEvsDBPage.Create(aOwner :TComponent);
begin
  FDatabase := Nil;
  inherited Create(aOwner);
end;

destructor TEvsDBPage.Destroy;
begin
  FDatabase := Nil;
  inherited Destroy;
end;
{$ENDREGION}


end.


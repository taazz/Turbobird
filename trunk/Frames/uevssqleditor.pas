unit uEvsSqlEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, SynHighlighterSQL, SynCompletion, Forms, Controls, ExtCtrls, uEvsTabNotebook, uEvsDBSchema, uBaseFrame,
  ComCtrls, ActnList;

type

  { TSqlEditorFrame }

  TSqlEditorFrame = class(TfrBase)
    aclQuery :TActionList;
    actExecute :TAction;
    actExport :TAction;
    actImport :TAction;
    actToggleComment :TAction;
    SynCompletion1 :TSynCompletion;
    sneQuery :TSynEdit;
    SynSQLSyn1 :TSynSQLSyn;
    ToolBar1 :TToolBar;
    procedure actExecuteUpdate(Sender :TObject);
  private
    { private declarations }
    //FDatabase  :IEvsDatabaseInfo;
    FResultSet :TEvsATTabsNoteBook;
    procedure SetupResultSet;
    procedure NewGridResultPage;
    procedure NewTextResultPage;
  protected
    procedure SetDatabase(aValue :IEvsDatabaseInfo);override;
    procedure Clear;
    function GetCommand:String;
  public
    { public declarations }
    constructor Create(aOwner :TComponent); override;
    destructor Destroy; override;
    //property Database:IEvsDatabaseInfo read FDatabase write SetDatabase;
  end;

implementation

{$R *.lfm}

{ TSqlEditorFrame }

procedure TSqlEditorFrame.actExecuteUpdate(Sender :TObject);
begin
  actExecute.Enabled := (FDatabase <> nil) and ( FDatabase.Connection <> nil ) and (GetCommand <> '');
end;

procedure TSqlEditorFrame.SetupResultSet;
begin
  FResultSet := TEvsATTabsNoteBook.Create(Self);
  FResultSet.Parent := Self;
  FResultSet.Align  := alBottom;
  FResultSet.Height := 250;
  FResultSet.TabPosition := tpBottom;
  With TSplitter.Create(Self) do begin
    Parent := Self;
    Align := alBottom;
  end;
end;

procedure TSqlEditorFrame.SetDatabase(aValue :IEvsDatabaseInfo);
begin
  if FDatabase = aValue then Exit;
  inherited SetDatabase(aValue);
  Clear;
end;

procedure TSqlEditorFrame.NewGridResultPage;
begin

end;

procedure TSqlEditorFrame.NewTextResultPage;
begin

end;

procedure TSqlEditorFrame.Clear;
begin
  sneQuery.ClearAll;
end;

function TSqlEditorFrame.GetCommand :String;
begin
  if sneQuery.SelAvail then Result := sneQuery.SelText else Result := sneQuery.Text;
end;

constructor TSqlEditorFrame.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  SetupResultSet;
end;

destructor TSqlEditorFrame.Destroy;
begin
  FDatabase := Nil;
  inherited Destroy;
end;

end.


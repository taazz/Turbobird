unit QueryWindow;

{$mode objfpc}{$H+}

interface
{ TO DO LIST
   01 : Generic clean up
     0001 : rewrite all code based on a control's caption to use something else eg control's tag
     0002 : show the first 200 characters of a memo field in the grid it self.
}
{ TODO -oJKOZ -cGUI : Make sure that the font sizes and data are the same in design and run time. }
uses
  Classes, SysUtils, IBConnection, db, sqldb, FileUtil, LResources, Forms,
  Controls, Graphics, Dialogs, ExtCtrls, {PairSplitter,} StdCtrls, Buttons,
  DBGrids, Menus, ComCtrls, SynEdit, SynHighlighterSQL, {Reg,} SynEditTypes,
  SynCompletion, ExtendedNotebook, Clipbrd, grids, DbCtrls, types, LCLType, ActnList, MDODatabase, MDOQuery, MDOScript, dbugintf,
  utbcommon, variants, strutils, IniFiles, uTBTypes, utbConfig, SysTables;

type

  { TWinControlHelper }

  TWinControlHelper = class helper for TWinControl
    function GetChildControl(const aTag:integer):TControl;overload;
    function GetChildcontrol(const aClass :TClass):TControl;overload;
  end;

  { TQueryThread }

  TQueryThread = class(TThread)
    private
      FSQLQuery    :TMDOQuery;
      FTrans       :TMDOTransaction;
      FConnection  :TMDODataBase;

      Error        :Boolean;
      ErrorMsg     :string;
      fTerminated  :Boolean;
      fType        :TQueryActions;
      fStatement   :string;
    public
      constructor Create(aType: TQueryActions);
      procedure DoJob;
      procedure Execute; override; //Jkoz : Query, Trans & Connect can not be shared between threads (including the main thread).
      property Query      :TMDOQuery       read FSQLQuery   write FSQLQuery;
      property Trans      :TMDOTransaction read FTrans      write FTrans;
      property Connection :TMDODataBase    read FConnection write FConnection;
      property Statement  :string          read fStatement  write fStatement;
  end;

  //JKOZ: Modifications.
  //  1) Thread use is wrong needs to be either removed or corrected.
  //  2) move the code from the menus and tool buttons to actions.
  //  3) move the new actionlist outside the query window?
  //  4) simplify the user interface.
  //     a. move the auto commit auto commit retaining etc away from the toolbar
  //     b. use only execute.
  //     c. remove the ctrl+enter and add proper short cut support. Most cases I know execute is either F9 or F5.
  //     d. error messages and results must be seperated and clearly marked so.

  // Extensions.
  //  1) add copy paste support for the data. (use a tab seperated format to allow them to be pasted in spread sheets as columns.
  //  2) add drag drop support for the columns and data between result grid and query editor.

  { TfmQueryWindow }

  TfmQueryWindow = class(TForm)
    aclQuery :TActionList;
    cxAutoCommit        :TCheckBox;
    cxCommitRetaining   :TCheckBox;
    FindDialog1         :TFindDialog;
    bbClose             :TSpeedButton;
    FontDialog1         :TFontDialog;
    pgOutputPageCtl     :TExtendedNotebook;
    pgOutputPageCtlOld  :TPageControl;
    pnlOutputPanelOLD   :TPanel;
    Splitter1           :TSplitter;
    SQLQuery1           :TSQLQuery;
    SQLQuery1test1      :TMemoField;
    toolbarImagesNew    :TImageList;
    Panel2              :TPanel;
    toolbarImages       :TImageList;
    imTools             :TImageList;
    imTabs              :TImageList;
    lmCloseTab          :TMenuItem;
    lmCopy              :TMenuItem;
    lmPaste             :TMenuItem;
    lmSelectAll         :TMenuItem;
    lmUndo              :TMenuItem;
    MainMenu1           :TMainMenu;
    MenuItem1           :TMenuItem;
    MenuItem10          :TMenuItem;
    lmCut               :TMenuItem;
    lmExport            :TMenuItem;
    lmCommaDelimited    :TMenuItem;
    lmHTML              :TMenuItem;
    lmRedo              :TMenuItem;
    MenuItem2           :TMenuItem;
    lmFind              :TMenuItem;
    lmFindAgain         :TMenuItem;
    MenuItem3           :TMenuItem;
    lmCopyCell          :TMenuItem;
    lmExportAsComma     :TMenuItem;
    lmExportAsHTML      :TMenuItem;
    lmCopyAll           :TMenuItem;
    MenuItem5           :TMenuItem;
    lmRun               :TMenuItem;
    lmRunSelect         :TMenuItem;
    lmRunExec           :TMenuItem;
    lmRunScript         :TMenuItem;
    OpenDialog1         :TOpenDialog;
    Panel1              :TPanel;
    pmTab               :TPopupMenu;
    pmMemo              :TPopupMenu;
    pmGrid              :TPopupMenu;
    SaveDialog1         :TSaveDialog;
    meQuery             :TSynEdit;
    SynCompletion1      :TSynCompletion;
    SynSQLSyn1          :TSynSQLSyn;
    ToolBar1            :TToolBar;
    tbNew               :TToolButton;
    tbOpen              :TToolButton;
    tbSave              :TToolButton;
    tbRun               :TToolButton;
    tbCommit            :TToolButton;
    tbRollback          :TToolButton;
    tbCommitRetaining   :TToolButton;
    tbRollbackRetaining :TToolButton;
    ToolButton1         :TToolButton;
    ToolButton2         :TToolButton;
    ToolButton3         :TToolButton;
    tbHistory           :TToolButton;
    ToolButton4         :TToolButton;
    ToolButton5         :TToolButton;
    tbMenu              :TToolButton;
    ToolButton6         :TToolButton;
    procedure bbRunClick      (Sender: TObject);
    procedure DBGrid1DblClick (Sender: TObject);
    procedure DBGridTitleClick(column: TColumn);
    procedure FindDialog1Find (Sender: TObject);
    procedure FormClose       (Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate      (Sender: TObject);
    procedure FormDestroy     (Sender: TObject);
    procedure FormKeyDown     (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow        (Sender: TObject);
    procedure lmCloseTabClick (Sender: TObject);
    procedure lmCommaDelimitedClick(Sender: TObject);
    procedure lmCopyAllClick (Sender: TObject);
    procedure lmCopyCellClick(Sender: TObject);
    procedure lmCopyClick    (Sender: TObject);
    procedure lmCutClick     (Sender: TObject);
    procedure lmExportAsCommaClick(Sender: TObject);
    procedure lmExportAsHTMLClick (Sender: TObject);
    procedure lmHTMLClick     (Sender: TObject);
    procedure lmPasteClick    (Sender: TObject);
    procedure lmRedoClick     (Sender: TObject);
    procedure lmRunClick      (Sender: TObject);
    procedure lmRunExecClick  (Sender: TObject);
    procedure lmRunScriptClick(Sender: TObject);
    procedure lmRunSelectClick(Sender: TObject);
    procedure lmSelectAllClick(Sender: TObject);
    procedure lmUndoClick     (Sender: TObject);
    procedure lmFindClick     (Sender: TObject);
    procedure lmFindAgainClick(Sender: TObject);
    procedure meQueryKeyDown  (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SQLQuery1test1GetText(Sender :TField; var aText :string; DisplayText :Boolean);

    procedure SQLScript1Exception(Sender :TObject; Statement :TStrings; TheException :Exception; var Continue :boolean);
    procedure SynCompletion1CodeCompletion(var Value :string; SourceValue :string; var SourceStart, SourceEnd :TPoint;
                                           KeyChar :TUTF8Char; Shift :TShiftState);
    procedure tbCloseClick  (Sender: TObject);
    procedure tbCommitClick (Sender: TObject);
    procedure tbCommitRetainingClick(Sender: TObject);
    procedure tbHistoryClick (Sender: TObject);
    procedure tbMenuClick    (Sender: TObject);
    procedure tbNewClick     (Sender: TObject);
    procedure tbOpenClick    (Sender: TObject);
    procedure tbRollbackClick(Sender: TObject);
    procedure tbRollbackRetainingClick(Sender: TObject);
    procedure tbRunClick (Sender: TObject);
    procedure tbSaveClick(Sender: TObject);
  private
    {private declarations}
    FDB            :PDBInfo;
    FOptions       :set of TSynSearchOption;
    FConn          :TMDODatabase;
    FTrans         :TMDOTransaction;

    FCanceled      :Boolean;
    FStartLine     :Integer;
    FQuery         :TStringList; //query text
    FOrigQueryType :TQueryTypes;
    FFinished      :Boolean;
    FQT            :TQueryThread;
    FQueryPart     :string;
    FTab           :TTabSheet;
    FResultMemo    :TMemo;
    FScript        :TMDOScript;
    // Text for caption
    FAText         :string;
    FModifyCount   :Integer;
    FCounter       :Integer;
    OutputTabsList :TStrings;

    // Makes commit button in current tabsheet visible
    procedure EnableCommitButton;
    procedure ExecuteQuery;deprecated;
    procedure ExecuteQuery2;
    function GetAutoCommit :Boolean;
    function GetEditorFont :TFont;
    function  GetNewTabNum: string;
    // Gets TSQLQuery of current result tabsheet - only if it is a select query
    function GetCurrentSelectQuery: TSQLQuery;
    // Gets both querytype and whether SQL is DML or DDL
    // Investigates QueryList[LookAtIndex] to find out
    function  GetQuerySQLType(QueryList: TStringList; var LookAtIndex: Integer; var IsDDL: Boolean): TQueryTypes;
    procedure NewCommitButton(const Pan: TPanel; var ATab: TTabSheet);
    procedure RemoveComments(QueryList: TStringList; StartLine: Integer; var RealStartLine: Integer);
    procedure RemoveAllSingleLineComments(QueryList: TStringList);
    procedure RemoveEmptyLines(QueryList: TStringList; var SecondRealStart: Integer; const RealStartLine: Integer);
    procedure ApplyClick(Sender: TObject);
    procedure EnableApplyButton;
    function  GetTableName(SQLText: string): string;
    procedure CommitResultClick(Sender: TObject);
    procedure RemovePreviousResultTabs;
    procedure SetAutocommit(aValue :Boolean);
    procedure SetEditorFont(aValue :TFont);
    //
    procedure Init(dbIndex: Integer);overload;deprecated 'pass the TDBinfo record not the index';
  protected
    // This procedure will receive the events that are logged by the Connect:
    procedure GetLogEvent(Sender: TSQLConnection; EventType: TDBEventType; Const Msg : String);
    function QueryIsActive(aDB:PDBInfo) :Boolean;
    function SameConnection(constref aDB:PDBInfo):Boolean;
  public
    { public declarations }
    OnCommit :TNotifyEvent;
    procedure Init(const aDB :PDBInfo);overload;
    procedure ApplyFont(const aFont: TFont);
    function GetQueryType(AQuery: string): TQueryTypes;
    // Get query text from GUI/memo into
    // QueryContents
    function GetQuery(aQueryContents: tstrings): boolean;
    function CreateResultTab(QueryType: TQueryTypes; var aSqlQuery: TMDOQuery; var aSQLScript: TMDOScript;
                             var meResult: TMemo; AdditionalTitle: string = ''): TTabSheet;
    // Runs SQL script; returns result
    function ExecuteScript(Script: string): Boolean;
    // Create a new Apply button in the specified panel
    procedure NewApplyButton(var Pan: TPanel; var ATab: TTabSheet);
    // Returns whether query is DDL or DML
    function GetSQLType(Query: string; var Command: string): string;
    // Tries to split up text into separate queries
    function GetSQLSegment(QueryList: TStringList; StartLine: Integer;
                           var QueryType: TQueryTypes; var EndLine: Integer;
                           var SQLSegment: string; var IsDDL: Boolean): Boolean;
    procedure QueryAfterPost (DataSet: TDataSet);
    procedure QueryAfterScroll(DataSet: TDataSet);
    // Run query; use aQueryType to force running as e.g. script or open query
    procedure CallExecuteQuery(aQueryType: TQueryTypes);
    procedure SortSynCompletion;
    procedure ThreadTerminated(Sender: TObject);
    procedure EnableButtons;
    procedure LoadSettings; //used to force reload when font is changed.
    //property EditorFont:TFont read GetEditorFont write SetEditorFont;
    property AutoCommit :Boolean read GetAutoCommit write SetAutocommit;

  end;

var
  fmQueryWindow: TfmQueryWindow;

implementation

{$R *.lfm}

uses main, SQLHistory;

{ TWinControlHelper }

function TWinControlHelper.GetChildControl(const aTag :integer) :TControl;
var
  vCntr :Integer;
begin
  Result := Nil;
  for vCntr := 0 to Self.ControlCount -1 do begin
    if Controls[vCntr].Tag = aTag then begin
      Result := Controls[vCntr];
      Break;
    end;
  end;
end;

function TWinControlHelper.GetChildcontrol(const aClass :TClass) :TControl;
var
  vCntr :Integer;
begin
  Result := Nil;
  for vCntr := 0 to Self.ControlCount -1 do begin
    if Controls[vCntr].InheritsFrom(aClass) then begin
      Result := Controls[vCntr];
      Break;
    end;
  end;
end;

{ TfmQueryWindow }
{ NewCommitButton: Create commit button for editable query result }

procedure TfmQueryWindow.NewCommitButton(const Pan: TPanel; var ATab: TTabSheet);
var
  Commit: TBitBtn;
begin
  Commit         := TBitBtn.Create(self);
  Commit.Parent  := Pan;
  Commit.Caption := 'Commit'; //don't change this; code looks for this exact caption
  Commit.Left    := 400;
  Commit.Visible := False;
  Commit.OnClick := @CommitResultClick;
  Commit.Tag     := ATab.TabIndex;
end;


{ RemoveComments: Remove comments from Query window }

procedure TfmQueryWindow.RemoveComments(QueryList: TStringList; StartLine: Integer; var RealStartLine: Integer);
var
  Comment: Boolean;
  i: Integer;
  MultiComment: Boolean;
begin
  MultiComment:= False;
  for i:= StartLine to QueryList.Count - 1 do begin
    if Pos('/*', Trim(QueryList[i])) = 1 then begin
      MultiComment:= True;
      Comment:= False;
    end;
    // Avoid checking for comments if there's any chance they're within
    // a string literal e.g. select 'this is -- no -- comment' from rdb$database
    if (not MultiComment) and (pos('''',QueryList[i])=0) then
      Comment:= Pos('--', Trim(QueryList[i])) = 1;
    if (Trim(QueryList[i]) <> '') and (not Comment) and (not MultiComment) then begin
      RealStartLine:= i;
      Break;
    end;
    if MultiComment and (Pos('*/', QueryList[i]) > 0) then begin // End of multi-line comment
      QueryList[i] := Trim(Copy(QueryList[i], Pos('*/', QueryList[i]) + 2, Length (QueryList[i])));
      RealStartLine := i;
      MultiComment := False;
      Comment := False;
      if (i = QueryList.Count -1) or ((Trim(QueryList[i + 1]) <> '') and
         (Pos('/*',Trim(QueryList[i + 1]))<>1) and (Pos('--', Trim(QueryList[i + 1])) <> 1)) then begin
        Break;
      end;
    end;
  end;
end;


{ RemoveAllSingleLineComments: remove single line comments from query }

procedure TfmQueryWindow.RemoveAllSingleLineComments(QueryList: TStringList);
var
  i: Integer;
begin
  for i:= QueryList.Count - 1 downto 0 do
  begin
    if Pos('--', QueryList[i]) > 0 then
    begin
      if Pos('--', Trim(QueryList[i])) = 1 then
        QueryList.Delete(i);
      {
      else
        // this will also pick up -- within string literals which is wrong
        QueryList[i]:= Copy(QueryList[i], 1, Pos('--', QueryList[i]) - 1);
      }
    end;
  end;
end;


{ RemoveEmptyLines: remove empty lines in query }

procedure TfmQueryWindow.RemoveEmptyLines(QueryList: TStringList; var SecondRealStart: Integer;
  const RealStartLine: Integer);
var
  i: integer;
begin
  for i:= RealStartLine to QueryList.Count - 1 do
  begin
    if Trim(QueryList[i]) <> '' then
    begin
      SecondRealStart:= i;
      Break;
    end;
  end;
end;


{ ApplyClick: Save Updates for the query }

procedure TfmQueryWindow.ApplyClick(Sender: TObject);
var
  //i, x           :Integer;
  //TableName      :string;
  //UpdateQuery    :TSQLQuery;
  //PKIndexName    :string;
  //ConstraintName :string;
  //KeyList,
  //FieldsList     : TStringList;
  //WhereClause    :string;
  UserData       :TSQLQuery;
  //TabIndex       :Integer;
  //FieldsSQL      :string;
begin
  try
    //TabIndex := pgOutputPageCtl.TabIndex;
    UserData := nil;
    UserData := GetCurrentSelectQuery;
    // Better safe than sorry
    if not(Assigned(UserData)) then begin
      ShowMessage('Error getting query from tabsheet.');
      {$IFDEF DEBUG}
      SendDebug('ApplyClick: GetRecordSet call returned nil recordset');
      {$ENDIF}
      exit;
    end;
    UserData.ApplyUpdates; // lets query run InsertSQL, UpdateSQL, DeleteSQL

    //(Sender as TBitBtn).Visible:= False; //Jkoz: this one raises an exception if sender is not tbitbtn, restricting our use cases.
    if Sender is TBitBtn then TBitBtn(Sender).Visible := False;
    // Auto commit
    if AutoCommit then //Jkoz : convert auto commit to a property before removing the check box.
      FTrans.Commit
    else
      EnableCommitButton;

    UserData.EnableControls;//JKOZ: with out disable controls??
  except
    on E: Exception do begin
      ShowMessage('Error trying to save data: ' + e.Message);
    end;
  end;
end;

{ EnableApplyButton: enable save updates button on current tab when records have been modified }

procedure TfmQueryWindow.EnableApplyButton;
var
  vCntr        :Integer;
  vCtl         :TControl;
  vParentPanel :TPanel;
begin
  // The page has a panel that contains the button
  vParentPanel := nil;
  for vCntr := 0 to pgOutputPageCtl.ActivePage.ControlCount-1 do
  begin
    vCtl := pgOutputPageCtl.ActivePage.Controls[vCntr];
    if vCtl is TPanel then begin
      vParentPanel := TPanel(vCtl); //found
      Break;
    end;
  end;
  // Found the hosting panel; this should have the Apply button
  // as well as the commit button and the tdbnavigator
  if Assigned(vParentPanel) then begin
    for vCntr := 0 to vParentPanel.ControlCount-1 do begin
      vCtl := vParentPanel.Controls[vCntr];
      if (vCtl is TBitBtn) and ((vCtl as TBitBtn).Caption = 'Apply') then begin //jkoz:0001 remove caption dependencies
        (vCtl as TBitBtn).Visible:= True; //jkoz:0002 visual elements shoold never be hiden.
        Break;
      end;
    end;
  end;
end;


{ EnableCommitButton: enable commit button after applying updates }

procedure TfmQueryWindow.EnableCommitButton;
var
  i: Integer;
  Ctl: TControl;
  ParentPanel: TPanel;
begin
  // The page has a panel that contains the button
  ParentPanel:=nil;
  for i:= 0 to pgOutputPageCtl.ActivePage.ControlCount-1 do
  begin
    Ctl:=pgOutputPageCtl.ActivePage.Controls[i];
    if Ctl is TPanel then
    begin
      ParentPanel:= TPanel(Ctl); //found
      break;
    end;
  end;
  // Found the hosting panel; this should have the Apply, Commit button
  // as well as the navigator
  if assigned(ParentPanel) then
  begin
    for i:= 0 to ParentPanel.ControlCount - 1 do //jkoz: remove parent panel, has no advantage over ttabcontrol as the container it just adds one more level of indirection with out reason.
    begin
      Ctl:=ParentPanel.Controls[i];
      if (Ctl is TBitBtn) and ((Ctl as TBitBtn).Caption = 'Commit') then //Jkoz:00001: remove caption dependency the caption makes it impossible to support multiple languages.
      begin
        (Ctl as TBitBtn).Visible:= true;
        Break;
      end;
    end;
  end;
end;


{ GetTableName: get table name from query text }

function TfmQueryWindow.GetTableName(SQLText: string): string;
begin
  SQLText:= Trim(Copy(SQLText, Pos('from', LowerCase(SQLText)) + 4, Length(SQLText)));
  if Pos('"', SQLText) = 1 then begin
    Delete(SQLText, 1, 1);
    Result:= Copy(SQLText, 1, Pos('"', SQLText) - 1);
  end else begin
    if Pos(' ', SQLText) > 0 then
      Result:= Copy(SQLText, 1, Pos(' ', SQLText) - 1)
    else
      Result:= SQLText;
  end;
  if Pos(';', Result) > 0 then
    Delete(Result, Pos(';', Result), 1);
end;


{ CommitResultClick: commit current transaction }

procedure TfmQueryWindow.CommitResultClick(Sender: TObject);
begin
  FTrans.CommitRetaining;
  (Sender as TBitBtn).Visible:= False;
end;

procedure TfmQueryWindow.RemovePreviousResultTabs;
var
  i: Integer;
begin
  for i:= OutputTabsList.Count - 1 downto 0 do begin
    OutputTabsList.Objects[i].Free;
    OutputTabsList.Objects[i]:=Nil;
    //OutputTabsList.Delete(i);
  end;
end;

procedure TfmQueryWindow.SetAutocommit(aValue :Boolean);
begin
  cxAutoCommit.Checked := aValue;
end;

procedure TfmQueryWindow.SetEditorFont(aValue :TFont);
begin
  meQuery.Font := aValue;
end;

procedure TfmQueryWindow.GetLogEvent(Sender :TSQLConnection; EventType :TDBEventType; Const Msg :String);
// Used to log everything sent through the Connect
var
  Source: string;
begin
  case EventType of
    detCustom   :Source := 'Custom:  ';
    detPrepare  :Source := 'Prepare: ';
    detExecute  :Source := 'Execute: ';
    detFetch    :Source := 'Fetch:   ';
    detCommit   :Source := 'Commit:  ';
    detRollBack :Source := 'Rollback:';
  else
    Source := 'Unknown event. Please fix program code.';
  end;
  {$IFDEF DEBUG}
  SendDebug(Source + Msg);
  {$ENDIF}
end;

function TfmQueryWindow.QueryIsActive(aDB :PDBInfo) :Boolean;
begin
  Result := Result and FConn.Connected and FTrans.Active;
end;

function TfmQueryWindow.SameConnection(constref aDB :PDBInfo) :Boolean;
begin
  Result := aDB = FDB;
  if Result then Exit;  //same memory, same data.
  Result := Result or ((CompareText(aDB^.RegRec.DatabaseName, FDB^.RegRec.DatabaseName) = 0)
                   and (CompareText(aDB^.RegRec.UserName, FDB^.RegRec.UserName) = 0)
                   and (CompareText(aDB^.RegRec.Password, FDB^.RegRec.Password) = 0));
end;


{ GetCurrentSelectQuery: return result recordset of a page tab }

function TfmQueryWindow.GetCurrentSelectQuery: TSQLQuery;
//var
//  i   : Integer;
//  Ctl : TControl;
begin
  // Tabsheet's tag property should point to any select query
  Result:= nil;
  if (pgOutputPageCtl.PageCount > 0) then
  begin
    if (pgOutputPageCtl.ActivePage.Tag<>0) then begin
      Result:= TSQLQuery(pgOutputPageCtl.ActivePage.Tag);
    end;
  end;
end;


{ GetQuerySQLType: get query type: select, script, execute from current string list }

function TfmQueryWindow.GetQuerySQLType(QueryList: TStringList; var LookAtIndex: Integer; var IsDDL: Boolean): TQueryTypes;
var
  MassagedSQL: string;
begin
  Result:= qtUnknown;
  IsDDL:= False; //default
  if LookAtIndex < QueryList.Count then
  begin
    MassagedSQL:= LowerCase(Trim(QueryList[LookAtIndex]));

    // Script overrides rest
    if Pos('set term', MassagedSQL) = 1 then
    begin
      // Using set term does not mean the SQL you're running has to be
      // DDL (could be an execute block or something) but it most probably is
      IsDDL:= true;
      exit(qtScript);
    end;

    if (Pos('select', MassagedSQL) = 1) then
      { todo: (low priority) misses insert...returning,
       update...returning, merge.. returning...}
      Result:= qtSelectable
    else
    begin
      Result:= qtExecute;
      IsDDL:= (Pos('alter', MassagedSQL) = 1) or
        (Pos('create', MassagedSQL) = 1) or
        (Pos('drop', MassagedSQL) = 1) or
        (Pos('grant', MassagedSQL) = 1) {actually DCL} or
        (Pos('revoke', MassagedSQL) = 1) {actually DCL};
    end;
  end;
end;

{ TQueryThread }

{ DoJob: Execute thread job: open query, execute, commit, rollback, etc }

procedure TQueryThread.DoJob;
begin
  try
    //if fType = qaOpen then
    //  FSQLQuery.Open
    //else if fType = qaExec then
    //  FSQLQuery.ExecSQL
    //else if fType = qaDDL then
    //  FConnection.ExecuteDirect(fStatement)
    //else if fType = qaCommit then
    //  FTrans.Commit
    //else if fType = qaCommitRet then
    //  FTrans.CommitRetaining
    //else if fType = qaRollBack then
    //  FTrans.Rollback
    //else if fType = qaRollbackRet then
    //  FTrans.RollbackRetaining;
  //TQueryActions = (qaCommit, qaCommitRet, qaRollBack, qaRollbackRet, qaOpen, qaDDL, qaExec );

    case FType of
      qaCommit      :FTrans.Commit;
      qaCommitRet   :FTrans.CommitRetaining ;
      qaRollBack    :FTrans.Rollback;
      qaRollbackRet :FTrans.RollbackRetaining;
      qaOpen        :FSQLQuery.Open;
      qaDDL         :SQLExecute(FConnection,fStatement,[],FTrans); //FConnection.ExecuteDirect(fStatement);
      qaExec        :FSQLQuery.ExecSQL;
    end; ;
    Error := False;
    fTerminated:= True;
  except
    on E :Exception do begin
      Error       := True;
      ErrorMsg    := e.Message;
      fTerminated := True;
    end;
  end;
end;


{ Execute: Query thread main loop }

procedure TQueryThread.Execute;
begin
  try
    fTerminated:= False;
    Error:= False;
    DoJob;
    fTerminated:= True;
  except
    on E: Exception do
    begin
      Error:= True;
      ErrorMsg:= e.Message;
      fTerminated:= True;
    end;
  end;
end;


{ Create query thread }

constructor TQueryThread.Create(aType: TQueryActions);
begin
  inherited Create(True);
  fType:= aType;
  FreeOnTerminate:= False;
end;


{ Display SQL script exception message }

procedure TfmQueryWindow.SQLScript1Exception(Sender: TObject; Statement: TStrings; TheException: Exception; var Continue: boolean);
begin
  ShowMessage('Error running script: '+TheException.Message);
end;


procedure TfmQueryWindow.SynCompletion1CodeCompletion(var Value: string;
  SourceValue: string; var SourceStart, SourceEnd: TPoint; KeyChar: TUTF8Char;
  Shift: TShiftState);
begin
  SynCompletion1.Deactivate;
end;


{ Close button pressed: close current Query window and free parent page tab }

procedure TfmQueryWindow.tbCloseClick(Sender: TObject);
begin
  Close;
  //Parent.Free; //JKOZ : Remove this call and make sure that a close event is used instead.
end;


{ Commit current transaction }

procedure TfmQueryWindow.tbCommitClick(Sender: TObject);
var
  meResult: TMemo;
  SqlQuery: TMDOQuery;
  //SqlScript: TSQLScript;
  SqlScript: TMDOScript;
  ATab: TTabSheet;
  QT: TQueryThread;
begin
  ATab:= CreateResultTab(qtExecute, SqlQuery, SqlScript, meResult);
  QT:= TQueryThread.Create(qaCommit);
  try
    QT.Trans := FTrans;
    ATab.ImageIndex:= 6;

    // Run thread
    QT.Resume;
    repeat
      application.ProcessMessages;
    until QT.fTerminated;

    if QT.Error then
    begin
      ATab.ImageIndex := 3;
      meResult.Lines.Text:= QT.ErrorMsg;
      meResult.Font.Color:= clRed;
    end else begin
      ATab.ImageIndex:= 4;
      meResult.Lines.Add('Commited');
      meResult.Font.Color:= clGreen;

      // Call OnCommit procedure if assigned, it is used to refresh table management view
      if OnCommit <> nil then
        OnCommit(self);
      OnCommit:= nil;
    end;

  finally
    QT.Free;
  end;

end;


{ Commit retaining for current transaction }

procedure TfmQueryWindow.tbCommitRetainingClick(Sender: TObject);
var
  QT: TQueryThread;
begin
  QT:= TQueryThread.Create(qaCommitRet);
  try
    QT.Trans:= FTrans;

    // Run thread
    QT.Resume;
    repeat
      application.ProcessMessages;
    until QT.fTerminated;

    if QT.Error then
      ShowMessage('Error trying commit retaining: '+QT.ErrorMsg)
    else
    begin
      // Call OnCommit procedure if assigned, it is used to refresh table management view
      if OnCommit <> nil then
        OnCommit(self);
      OnCommit:= nil;
    end;

  finally
    QT.Free;
  end;
end;


{HistoryClick: show SQL history form }

procedure TfmQueryWindow.tbHistoryClick(Sender: TObject);
begin
  fmSQLHistory.Init(FDB^.RegRec.Title, Self);
  fmSQLHistory.Show;
end;


{ Display popup menu }

procedure TfmQueryWindow.tbMenuClick(Sender: TObject);
begin
  //pmTab.PopUp;
end;


{ display New SQL Window tab }

procedure TfmQueryWindow.tbNewClick(Sender: TObject);
var
  i: Integer;
begin
  // Get a free number to be assigned to the new Query window
  for i:= 1 to 1000 do
  begin
    if utbcommon.FindCustomForm(FDB^.RegRec.Title {FRegRec.Title} + ': Query Window # ' + IntToStr(i), TfmQueryWindow) = nil then
    begin
      fmMain.ShowCompleteQueryWindow(FDB, 'Query Window # ' + IntToStr(i), '');
      Break;
    end;
  end;
end;


{ Read SQL query from text file }

procedure TfmQueryWindow.tbOpenClick(Sender: TObject);
begin
  OpenDialog1.DefaultExt:= '.sql';
  if OpenDialog1.Execute then
    meQuery.Lines.LoadFromFile(OpenDialog1.FileName);
end;


{ RollBack current transaction }

procedure TfmQueryWindow.tbRollbackClick(Sender: TObject);
var
  meResult: TMemo;
  SqlQuery: TMDOQuery;
  SqlScript: TMDOScript;
  ATab: TTabSheet;
  QT: TQueryThread;
begin
  ATab:= CreateResultTab(qtExecute, SqlQuery, SqlScript, meResult);
  QT:= TQueryThread.Create(qaRollBack);
  try
    QT.Trans:= FTrans;
    ATab.ImageIndex:= 6;
    QT.Resume;
    repeat
      application.ProcessMessages;
    until QT.fTerminated;

    if QT.Error then
    begin
      ATab.ImageIndex:= 3;
      meResult.Lines.Text:= QT.ErrorMsg;
      meResult.Font.Color:= clRed;
    end
    else
    begin
      ATab.ImageIndex:= 4;
      meResult.Lines.Add('Rollback');
      meResult.Font.Color:= clGreen;
      if OnCommit <> nil then
        OnCommit(self);
      OnCommit:= nil;
      meResult.Font.Color:= $AA6666;
    end;

  finally
    QT.Free;
  end;
end;


{ Rollback retaning for current transaction }

procedure TfmQueryWindow.tbRollbackRetainingClick(Sender: TObject);
var
  QT: TQueryThread;
begin
  QT:= TQueryThread.Create(qaRollbackRet);
  try
    QT.Trans:= FTrans;

    QT.Resume;
    repeat
      application.ProcessMessages;
    until QT.fTerminated or (FCanceled);
    if QT.Error then
      ShowMessage('Error trying rollback retaining: '+QT.ErrorMsg);
  finally
    QT.Free;
  end;
end;


{ Run current SQL, auto-detect type }
procedure TfmQueryWindow.tbRunClick(Sender: TObject);
begin
  CallExecuteQuery(qtUnknown);
end;


{ Save current SQL in a text file }

procedure TfmQueryWindow.tbSaveClick(Sender: TObject);
begin
  SaveDialog1.DefaultExt:= '.sql';
  if SaveDialog1.Execute then
    meQuery.Lines.SaveToFile(SaveDialog1.FileName);
end;


{GetNewTabNum: get last tab number and increase result by one }

function TfmQueryWindow.GetNewTabNum: string;
var
  i: Integer;
  Cnt: Integer;
begin
  Cnt:= 0;
  for i:= 0 to pgOutputPageCtl.ControlCount - 1 do
  if pgOutputPageCtl.Pages[i].TabVisible then
   Inc(Cnt);
  Result:= IntToStr(Cnt);
end;


{ Initialize query window: fill Connect parameters from selected registered database }

procedure TfmQueryWindow.Init(dbIndex: Integer);
begin
  //FDBIndex := dbIndex;
  //FIBConnection := fmMain.RegisteredDatabases[dbIndex].IBConnection;
  //FRegRec := fmMain.RegisteredDatabases[dbIndex].RegRec;
  //FDB := @fmMain.RegisteredDatabases[dbIndex];
  // Remove old tabs in case of opening the same QueryWindow
  if Assigned(OutputTabsList) then
    RemovePreviousResultTabs
  else
    OutputTabsList:= TStringList.Create;

  // Set instances of FIBConnection and SQLTransaction for the current Query Window
  SetTransactionIsolation(FTrans.Params);
  FTrans.DataBase:= FConn;

  // Set Connect parameters to FIBConnection
  with fmMain.RegisteredDatabases[dbIndex] do
  begin
    //FConn.Connected := False;
    //FConn.DatabaseName := RegRec.DatabaseName;
    //FConn.UserName     := RegRec.UserName;
    //FConn.Password     := RegRec.Password;
    //FConn.CharSet      := RegRec.Charset;
    //FConn.Role         := RegRec.Role;
    Connect(FConn, RegRec);
  end;

  // Get current database tables to be highlighted in SQL query editor
  SynSQLSyn1.TableNames.CommaText:= fmMain.GetTableNames(dbIndex);
  SynCompletion1.ItemList.AddStrings(SynSQLSyn1.TableNames);
  SortSynCompletion;
end;

procedure TfmQueryWindow.Init(const aDB :PDBInfo);
begin
  //FRegRec := aDB.RegRec;
  if QueryIsActive(aDB) and SameConnection(aDB) then Exit;

  FDB := aDB;
  if Assigned(OutputTabsList) then
    RemovePreviousResultTabs
  else
    OutputTabsList:= TStringList.Create;
  FTrans.EndTransaction;
  FConn.Connected := False;
  SetTransactionIsolation(FTrans.Params);
  FTrans.DataBase:= FConn;
  //Rollback;
  //FConn.DatabaseName := aDB.RegRec.DatabaseName;
  //FConn.UserName     := aDB.RegRec.UserName;
  //FConn.Password     := aDB.RegRec.Password;
  //FConn.CharSet      := aDB.RegRec.Charset;
  //FConn.Role         := aDB.RegRec.Role;
  Connect(FConn, aDB^.RegRec);

  dmSysTables.GetTableNames(aDB^, SynSQLSyn1.TableNames);
  SynCompletion1.ItemList.AddStrings(SynSQLSyn1.TableNames);
  SortSynCompletion;
end;

procedure TfmQueryWindow.ApplyFont(const aFont :TFont);
begin
  meQuery.Font.Assign(aFont);
end;

(************* Is Selectable (Check statement type Select, Update, Alter, etc) *******************)

function TfmQueryWindow.GetQueryType(AQuery: string): TQueryTypes;
var
  List: TStringList;
  i: Integer;
  Line: string;
  StartPos, EndPos: Integer;
begin
  List:= TStringList.Create;
  try
    List.Text:= AQuery;
    Result:= qtExecute; // Default Execute
    for i:= 0 to List.Count - 1 do
    begin
      Line:= List[i];
      // Remove comments
      if Pos('--', Line) > 0 then
        Line:= Copy(Line, 1, Pos('--', Line) - 1);
      if (Pos('/*', Line) > 0) and (Pos('*/', Line) > 0) then
      begin
        StartPos:= (Pos('/*', Line));
        EndPos:= (Pos('*/', Line));
        Delete(Line, StartPos, EndPos - StartPos + 1);
      end;

      if (Pos('select', LowerCase(Trim(Line))) = 1) then
      begin
        Result:= qtSelectable; // Selectable
        Break;
      end
      else
      if Pos('set term', LowerCase(Trim(Line))) = 1 then
      begin
        Result:= qtScript;
        Break;
      end;

      if Trim(Line) <> '' then
      begin
        Result := qtExecute; // Executable
        Break;
      end;
    end;
  finally
    List.Free;
  end;
end;


{ GetQuery: get query text from editor }

function TfmQueryWindow.GetQuery(aQueryContents :tstrings) :boolean;
//var
//  Seltext: string;
begin
  Result:= false;
  if Assigned(aQueryContents) then begin
    if meQuery.SelAvail then
      aQueryContents.Text := Trim(meQuery.SelText)
    else
      aQueryContents.Text := Trim(meQuery.Lines.Text);

    //if SelTExt <> '' then
    //  aQueryContents.Text := SelText
    //else
    //  aQueryContents.Text := Trim(meQuery.Lines.Text);
    //
    Result := true;
  end;
end;


{ Create new result tab depending on query type }

function TfmQueryWindow.CreateResultTab(QueryType :TQueryTypes; var aSqlQuery :TMDOQuery; var aSQLScript :TMDOScript; var meResult :TMemo;
  AdditionalTitle :string) :TTabSheet;
var
  ATab       :TTabSheet;
  DBGrid     :TDBGrid;
  DataSource :TDataSource;
  StatusBar  :TStatusBar;
  Nav        :TDBNavigator;
  Pan        :TPanel;
begin
  ATab := TTBTabsheet.Create(nil);
  OutputTabsList.AddObject('', ATab);
  BeginUpdateBounds;
  Result := ATab;
  ATab.Parent := pgOutputPageCtl;
  pgOutputPageCtl.ActivePage := ATab; //set focus to new tab
  ATab.Caption := 'Result # ' + GetNewTabNum + ' ' + AdditionalTitle;
  if QueryType = qtSelectable then // Select, need record set result
  begin
    // Query
    // Clean up any existing object to avoid memory leak
    if assigned(aSQLQuery) then
      ReleaseQuery(aSQLQuery);//.Free;
    aSqlQuery := utbcommon.GetQuery(FConn,FTrans); //TSQLQuery.Create(self);
    //aSqlQuery.DataBase    := FConn;
    //aSqlQuery.Transaction := FTrans;
    aSqlQuery.AfterPost   := @QueryAfterPost; //detect user-edited grid
    aSqlQuery.AfterScroll := @QueryAfterScroll;
    aSqlQuery.Tag         := ATab.TabIndex; //Query points to tabsheet number
    {Tab points to query object so we can look it up more easily via the
    tab sheet if we need to enable Apply/Commit buttons etc}
    ATab.Tag              := PtrInt(aSQLQuery);

    // Status Bar //JKOZ: change it to a single status bar for all tabs
    StatusBar        := TStatusBar.Create(ATab);
    StatusBar.Parent := ATab;
    StatusBar.Tag    := aSqlQuery.Tag;

    // Datasource
    DataSource         := TDataSource.Create(self);
    DataSource.DataSet := aSqlQuery;

    // Panel
    pan         := TPanel.Create(self);
    pan.Parent  := ATab;
    Pan.Height  := 30;
    Pan.Align   := alTop;

    // Query result Grid
    DBGrid            := TDBGrid.Create(self);
    DBGrid.Parent     := ATab;
    DBGrid.DataSource := DataSource;
    DBGrid.Align      := alClient;
    DBGrid.OnDblClick := @DBGrid1DblClick;

    DBGrid.Tag        := ATab.TabIndex;
    DBGrid.ReadOnly   := False;
    DBGrid.AutoEdit   := True;

    DBGrid.PopupMenu  := pmGrid;
    DBGrid.TitleStyle := tsNative;
    DBGrid.Options    := DBGrid.Options + [dgAutoSizeColumns, dgHeaderHotTracking, dgHeaderPushedLook, dgAnyButtonCanSelect];

    DBGrid.OnTitleClick := @DBGridTitleClick;

    // Navigator
    Nav                 := TDBNavigator.Create(self);
    Nav.Parent          := Pan;
    Nav.VisibleButtons  := [nbFirst, nbNext, nbPrior, nbLast];
    Nav.DataSource      := DataSource;

    // Apply button
    NewApplyButton(Pan, ATab);

    // Commit button
    NewCommitButton(Pan, ATab);
  end else if QueryType in [qtExecute, qtScript] then begin
    meResult          := TMemo.Create(self);
    meResult.Parent   := ATab;
    meResult.ReadOnly := True;
    meResult.Align    := alClient;
    case QueryType of
      qtExecute:
      begin
        aSqlQuery     := utbcommon.GetQuery(FConn,FTrans); //TSQLQuery.Create(self);
        //aSqlQuery.DataBase    := FConn;
        //aSqlQuery.Transaction := FTrans;
      end;
      qtScript: // Script
      begin
        // Clean up to avoid memory leak
        if assigned(aSQLScript) then
          aSQLScript.Free;
        aSQLScript               := TMDOScript.Create(Self);
        aSQLScript.DataBase      := FConn;
        aSQLScript.Transaction   := FTrans;
        //aSQLScript.CommentsInSQL := True;
        //aSQLScript.UseSetTerm    := true; //needed if set term is used, e.g. for stored procedures
      end;
    end;
  end;
end;

(***************  Execute Query   ******************)

procedure TfmQueryWindow.ExecuteQuery;
var
  StartTime : TDateTime;
  SqlType   : string;
  vEndLine  : Integer;
  Command   : string;
  IsDDL     : Boolean;
  Affected  : Integer;
  fQueryType  : TQueryTypes;
  TempQuery   : TMDOQuery;
  SanitizedSQL: string;
  i           : integer;
  vSQLQuery   : TMDOQuery;
  vTemp       : String;
begin
  //pmMemo.PopUp(mouse.CursorPos.x,mouse.CursorPos.Y);
  try
    // Script
    if (FOrigQueryType = qtScript) then begin // script
      ExecuteScript(FQuery.Text);
      Inc(FModifyCount);
      SqlType:= GetSQLType(FQuery.Text, Command);
      fmMain.AddToSQLHistory(FDB^.RegRec.Title, SqlType, FQuery.Text);
      FFinished:= True;
      FQuery.Clear;
    end else  begin // normal statement / Multi statements
      Inc(FCounter);
      if not GetSQLSegment(FQuery, FStartLine, fQueryType, vEndLine, FQueryPart, IsDDL) then begin
        FFinished:= True;
        Exit;
      end;

      if vEndLine < FStartLine then
        FStartLine:= FStartLine + 1
      else{}
        FStartLine:= vEndLine + 1;

      if Trim(FQueryPart) <> '' then   // Select
      if fQueryType = qtSelectable then begin
        FTab:= nil;
        try
          vSQLQuery:= utbcommon.GetQuery(FConn,FTrans);// TSQLQuery.Create(self);
          //vSQLQuery.DataBase:= FConn;
          //vSQLQuery.Transaction:= FTrans;
          if (cxAutoCommit.Checked and FTrans.Active) then
            FTrans.Commit;

          FTab:= CreateResultTab(qtSelectable, vSQLQuery, FScript, FResultMemo);
          FTab.ImageIndex:= 6;
          FTab.Hint:= FQueryPart;
          FTab.ShowHint:= True;
          vSQLQuery.SQL.Text:= FQueryPart;

          // Work around sqldb not detecting insert/updatesql for FIRST x queries
          // Massage the SQL, assign it to a temp query and use the insertquery
          // etc generated by sqldb.
          // Support for ROWS x TO y at the end of the statement could be
          // added perhaps

          if (pos('select first ',lowercase(FQueryPart))=1) then begin
            // Get rid of the select first x part by copying everything after
            // the third word
            SanitizedSQL:= ExtractWordPos(3, FQueryPart, StdWordDelims, i);
            if i > 0 then begin
              SanitizedSQL:= 'select ' + trim(copy(FQueryPart, i+length(SanitizedSQL), maxint));
              TempQuery:= utbcommon.GetQuery(FConn,FTrans); //TQuery.Create(nil);
              try
                //TempQuery.ParseSQL:= true;
                //vTemp := TempQuery.InsertSQL.Text;
                //vSQLQuery.InsertSQL:= TempQuery.InsertSQL;
                //vTemp := TempQuery.UpdateSQL.Text;
                //vSQLQuery.UpdateSQL:= TempQuery.UpdateSQL;
                //vTemp := TempQuery.DeleteSQL.Text;
                //vSQLQuery.DeleteSQL:= TempQuery.DeleteSQL;
              finally
                TempQuery.Free;
              end;
            end;
          end;

          // Create thread to open dataset
          FQT       := TQueryThread.Create(qaOpen); //JKOZ:THREADS;
          FQT.Query := vSQLQuery;
          FQT.Trans := FTrans;
          // FQT.OnTerminate:= @ThreadTerminated;
          FAText       := FTab.Caption;
          FTab.Caption := 'Running..';
          FQT.Resume;

          // Wait for the thread to complete
          repeat
            Sleep(100);
            application.ProcessMessages; // This prevents display freeze
          until FQT.fTerminated;

          // Raise exception if an error occured during thread execution (Open)
          if FQT.Error then
            raise Exception.Create(FQT.ErrorMsg);

          FQT.Free;
          FTab.Caption    := FAText;
          FTab.ImageIndex := 0;
          fmMain.AddToSQLHistory(FDB^.RegRec.Title, 'SELECT', FQueryPart);
        except
          on e: Exception do
          begin
            if Assigned(FTab) then
              FTab.TabVisible:= False;
            FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);
            pgOutputPageCtl.ActivePage := FTab;
            FResultMemo.Text := e.message;
            FResultMemo.Lines.Add(FQueryPart);
            FResultMemo.Font.Color := clRed;
            FTab.Font.Color := clRed;
            FTab.ImageIndex := 3;
          end;
        end;
      end else  // Execute
        if fQueryType = qtExecute then begin
          FTab := nil;
          FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);

          FTab.ImageIndex := 1;
          SqlType := GetSQLType(FQueryPart, Command);
          StartTime := Now;
          Affected := 0;
          try
            if IsDDL then begin
              // Execute the statement in thread
              FQT := TQueryThread.Create(qaDDL);
              FQT.Connection := FConn;
              FQT.Trans := FTrans;
              FQT.Statement := FQueryPart;
              FQT.Resume;
              FAText := FTab.Caption;
              FTab.Caption := 'Running..';

              // Wait for thread completion
              repeat
                application.ProcessMessages;
              until (FQT.fTerminated) or (FCanceled);

              // Raise exception if an error occured during thread execution (ExecProc)
              if FQT.Error then
                raise Exception.Create(FQT.ErrorMsg);

              FTab.Caption:= FAText;

              // Auto commit
              if cxAutoCommit.Checked then
                FTrans.CommitRetaining;
              FQT.Free;
            end else begin // DML
              vSQLQuery.Close;
              vSQLQuery.SQL.Text := FQueryPart;
              FTab.ImageIndex := 6;
              FTab.Hint := FQueryPart;
              FTab.ShowHint := True;
              vSQLQuery.SQL.Text := FQueryPart;

              // Execute the statement in thread
              FQT:= TQueryThread.Create(qaExec);
              try
                FQT.Query := vSQLQuery;
                FQT.Trans := FTrans;
                FQT.Resume;
                FAText := FTab.Caption;
                FTab.Caption := 'Running..';

                // Wait for thread completion
                repeat
                  application.ProcessMessages;
                until (FQT.fTerminated) or (FCanceled);

                // Raise exception if an error occured during thread execution (ExecProc)
                if FQT.Error then
                  raise Exception.Create(FQT.ErrorMsg);

                // Auto commit
                if cxAutoCommit.Checked then
                  FTrans.CommitRetaining;
              finally
                FQT.Free;
              end;
              FTab.Caption := FAText;
              FTab.ImageIndex := 1;
              Affected := vSQLQuery.RowsAffected;
            end;
            Inc(FModifyCount);

            fmMain.AddToSQLHistory(FDB^.RegRec.Title, SQLType, FQueryPart);
            FResultMemo.Visible := True;
            FResultMemo.Clear;
            FResultMemo.Lines.Add('statement #' + IntToStr(FCounter));
            if IsDDL then
              FResultMemo.Lines.Add(FormatDateTime('hh:nn:ss.z', Now) + ' - DDL Executed. Takes (H:M:S.MS) ' +
                FormatDateTime('HH:nn:ss.z', Now - StartTime))
            else begin // DML
              FResultMemo.Lines.Add(FormatDateTime('hh:nn:ss.z', Now) + ' - DML Executed. Takes (H:M:S.MS) ' +
                FormatDateTime('HH:nn:ss.z', Now - StartTime));
              FResultMemo.Lines.Add('Rows affected: ' + Format('%3.0n', [Affected / 1]));
            end;
            FResultMemo.Lines.Add('----');
            FResultMemo.Lines.Add(FQueryPart);
          except
            on E: Exception do begin
              if Assigned(FTab) then
                FTab.TabVisible := False;
              FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);
              pgOutputPageCtl.ActivePage := FTab;
              FResultMemo.Text := e.message;
              FResultMemo.Lines.Add(FQueryPart);
              FResultMemo.Font.Color := clRed;
              FTab.Font.Color := clRed;
              FTab.ImageIndex := 3;
            end;
          end;
        end else begin // Script
          try
            if ExecuteScript(FQueryPart) then begin
              Inc(FModifyCount);
              SqlType:= GetSQLType(FQueryPart, Command);
              fmMain.AddToSQLHistory(FDB^.RegRec.Title, SqlType, FQueryPart);
            end;
          except
            on E: Exception do begin
              if Assigned(FTab) then FTab.TabVisible:= False;
              FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);
              pgOutputPageCtl.ActivePage := FTab;
              FResultMemo.Text := e.message;
              FResultMemo.Lines.Add(FQueryPart);
              FResultMemo.Lines.Add('--------');
              FResultMemo.Font.Color := clRed;
              FTab.Font.Color := clRed;
              FTab.ImageIndex := 3;
            end;
          end;
        end;
        if (FModifyCount > 50) then begin
          if (MessageDlg('Commit', 'There are too many transactions, do you want to commit', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then begin
            FTrans.CommitRetaining;
            FModifyCount := 0;
          end else begin
            FModifyCount := 0;
          end;
        end;
      if FStartLine >= FQuery.Count then
        FFinished := True;
    end;
  except
    on E: Exception do begin
      if Assigned(FTab) then FTab.TabVisible := False;
      FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);
      FTab.ImageIndex := 2;
      pgOutputPageCtl.ActivePage := FTab;
      FResultMemo.Text := e.message;
      FResultMemo.Lines.Add('--------');
      FResultMemo.Lines.Add(FQueryPart);
      FResultMemo.Font.Color := clRed;
      FFinished := True;
    end;
  end;
end;

procedure TfmQueryWindow.ExecuteQuery2;
var
  StartTime : TDateTime;
  SqlType   : string;
  vEndLine  : Integer;
  Command   : string;
  IsDDL     : Boolean;
  Affected  : Integer;
  fQueryType  : TQueryTypes;
  //TempQuery   : TMDOQuery;
  //SanitizedSQL: string;
  //i           : integer;
  vSQLQuery     : TMDOQuery;
  //vTemp       : String;
begin
  try
    // Script
    if (FOrigQueryType = qtScript) then begin // script
      ExecuteScript(FQuery.Text);
      Inc(FModifyCount);
      SqlType := GetSQLType(FQuery.Text, Command);
      fmMain.AddToSQLHistory(FDB^.RegRec.Title, SqlType, FQuery.Text);
      FFinished := True;
      FQuery.Clear;
    end else begin // normal statement / Multi statements
      Inc(FCounter);
      if not GetSQLSegment(FQuery, FStartLine, fQueryType, vEndLine, FQueryPart, IsDDL) then begin
        FFinished:= True;
        Exit;
      end;

      if vEndLine < FStartLine then
        FStartLine:= FStartLine + 1
      else{}
        FStartLine:= vEndLine + 1;

      if Trim(FQueryPart) <> '' then   // Select
      if fQueryType = qtSelectable then begin
        FTab:= nil;
        vSQLQuery := utbcommon.GetQuery(FConn,FTrans); //TSQLQuery.Create(self);
        try
          //vSQLQuery.DataBase:= FIBConnection;
          //vSQLQuery.Transaction:= FSQLTrans;
          if cxAutoCommit.Checked and FTrans.InTransaction then
            FTrans.Commit;
          FTab := CreateResultTab(qtSelectable, vSQLQuery, FScript, FResultMemo);
          FTab.ImageIndex:= 6;
          FTab.Hint:= FQueryPart;
          FTab.ShowHint:= True;
          vSQLQuery.SQL.Text:= FQueryPart;

          // Work around sqldb not detecting insert/updatesql for FIRST x queries
          // Massage the SQL, assign it to a temp query and use the insertquery
          // etc generated by sqldb.
          // Support for ROWS x TO y at the end of the statement could be
          // added perhaps

          ////////////////////////////////////////////////////////////////////if (pos('select first ',lowercase(FQueryPart))=1) then begin
          ////////////////////////////////////////////////////////////////////  // Get rid of the select first x part by copying everything after
          ////////////////////////////////////////////////////////////////////  // the third word
          ////////////////////////////////////////////////////////////////////  SanitizedSQL:= ExtractWordPos(3, FQueryPart, StdWordDelims, i);
          ////////////////////////////////////////////////////////////////////  if i > 0 then begin
          ////////////////////////////////////////////////////////////////////    SanitizedSQL:= 'select ' + trim(copy(FQueryPart, i+length(SanitizedSQL), maxint));
          ////////////////////////////////////////////////////////////////////    TempQuery:= GetQuery(); //TSQLQuery.Create(nil);
          ////////////////////////////////////////////////////////////////////    try
          ////////////////////////////////////////////////////////////////////      TempQuery.ParseSQL:= true;
          ////////////////////////////////////////////////////////////////////      vTemp := TempQuery.InsertSQL.Text;
          ////////////////////////////////////////////////////////////////////      vSQLQuery.InsertSQL:= TempQuery.InsertSQL;
          ////////////////////////////////////////////////////////////////////      vTemp := TempQuery.UpdateSQL.Text;
          ////////////////////////////////////////////////////////////////////      vSQLQuery.UpdateSQL:= TempQuery.UpdateSQL;
          ////////////////////////////////////////////////////////////////////      vTemp := TempQuery.DeleteSQL.Text;
          ////////////////////////////////////////////////////////////////////      vSQLQuery.DeleteSQL:= TempQuery.DeleteSQL;
          ////////////////////////////////////////////////////////////////////    finally
          ////////////////////////////////////////////////////////////////////      TempQuery.Free;
          ////////////////////////////////////////////////////////////////////    end;
          ////////////////////////////////////////////////////////////////////  end;
          ////////////////////////////////////////////////////////////////////end;

          // Create thread to open dataset
          FQT       := TQueryThread.Create(qaOpen);
          FQT.Query := vSQLQuery;
          FQT.Trans := FTrans;
          // FQT.OnTerminate:= @ThreadTerminated;
          FAText       := FTab.Caption;
          FTab.Caption := 'Running..';
          FQT.Resume;

          // Wait for the thread to complete
          repeat
            Sleep(100);
            application.ProcessMessages; // This prevents display freeze
          until FQT.fTerminated;

          // Raise exception if an error occured during thread execution (Open)
          if FQT.Error then
            raise Exception.Create(FQT.ErrorMsg);

          FQT.Free;
          FTab.Caption    := FAText;
          FTab.ImageIndex := 0;
          fmMain.AddToSQLHistory(FDB^.RegRec.Title, 'SELECT', FQueryPart);
        except
          on e: Exception do
          begin
            if Assigned(FTab) then
              FTab.TabVisible:= False;
            FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);
            pgOutputPageCtl.ActivePage := FTab;
            FResultMemo.Text := e.message;
            FResultMemo.Lines.Add(FQueryPart);
            FResultMemo.Font.Color := clRed;
            FTab.Font.Color := clRed;
            FTab.ImageIndex := 3;
          end;
        end;
      end else  // Execute
        if fQueryType = qtExecute then begin
          FTab := nil;
          FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);

          FTab.ImageIndex := 1;
          SqlType := GetSQLType(FQueryPart, Command);
          StartTime := Now;
          Affected := 0;
          try
            if IsDDL then begin
              // Execute the statement in thread
              FQT := TQueryThread.Create(qaDDL);
              FQT.Connection := FConn;
              FQT.Trans := FTrans;
              FQT.Statement := FQueryPart;
              FQT.Resume;
              FAText := FTab.Caption;
              FTab.Caption := 'Running..';

              // Wait for thread completion
              repeat
                application.ProcessMessages;
              until (FQT.fTerminated) or (FCanceled);

              // Raise exception if an error occured during thread execution (ExecProc)
              if FQT.Error then
                raise Exception.Create(FQT.ErrorMsg);

              FTab.Caption:= FAText;

              // Auto commit
              if cxAutoCommit.Checked then
                FTrans.CommitRetaining;
              FQT.Free;
            end else begin // DML
              vSQLQuery.Close;
              vSQLQuery.SQL.Text := FQueryPart;
              FTab.ImageIndex := 6;
              FTab.Hint := FQueryPart;
              FTab.ShowHint := True;
              vSQLQuery.SQL.Text := FQueryPart;

              // Execute the statement in thread
              FQT:= TQueryThread.Create(qaExec);
              try
                FQT.Query := vSQLQuery;
                FQT.Trans := FTrans;
                FQT.Resume;
                FAText := FTab.Caption;
                FTab.Caption := 'Running..';

                // Wait for thread completion
                repeat
                  application.ProcessMessages;
                until (FQT.fTerminated) or (FCanceled);

                // Raise exception if an error occured during thread execution (ExecProc)
                if FQT.Error then
                  raise Exception.Create(FQT.ErrorMsg);

                // Auto commit
                if cxAutoCommit.Checked then
                  FTrans.CommitRetaining;
              finally
                FQT.Free;
              end;
              FTab.Caption := FAText;
              FTab.ImageIndex := 1;
              Affected := vSQLQuery.RowsAffected;
            end;
            Inc(FModifyCount);

            fmMain.AddToSQLHistory(FDB^.RegRec.Title, SQLType, FQueryPart);
            FResultMemo.Visible := True;
            FResultMemo.Clear;
            FResultMemo.Lines.Add('statement #' + IntToStr(FCounter));
            if IsDDL then
              FResultMemo.Lines.Add(FormatDateTime('hh:nn:ss.z', Now) + ' - DDL Executed. Takes (H:M:S.MS) ' +
                FormatDateTime('HH:nn:ss.z', Now - StartTime))
            else begin // DML
              FResultMemo.Lines.Add(FormatDateTime('hh:nn:ss.z', Now) + ' - DML Executed. Takes (H:M:S.MS) ' +
                FormatDateTime('HH:nn:ss.z', Now - StartTime));
              FResultMemo.Lines.Add('Rows affected: ' + Format('%3.0n', [Affected / 1]));
            end;
            FResultMemo.Lines.Add('----');
            FResultMemo.Lines.Add(FQueryPart);
          except
            on E: Exception do begin
              if Assigned(FTab) then
                FTab.TabVisible := False;
              FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);
              pgOutputPageCtl.ActivePage := FTab;
              FResultMemo.Text := e.message;
              FResultMemo.Lines.Add(FQueryPart);
              FResultMemo.Font.Color := clRed;
              FTab.Font.Color := clRed;
              FTab.ImageIndex := 3;
            end;
          end;
        end else begin // Script
          try
            if ExecuteScript(FQueryPart) then begin
              Inc(FModifyCount);
              SqlType:= GetSQLType(FQueryPart, Command);
              fmMain.AddToSQLHistory(FDB^.RegRec.Title, SqlType, FQueryPart);
            end;
          except
            on E: Exception do begin
              if Assigned(FTab) then FTab.TabVisible:= False;
              FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);
              pgOutputPageCtl.ActivePage := FTab;
              FResultMemo.Text := e.message;
              FResultMemo.Lines.Add(FQueryPart);
              FResultMemo.Lines.Add('--------');
              FResultMemo.Font.Color := clRed;
              FTab.Font.Color := clRed;
              FTab.ImageIndex := 3;
            end;
          end;
        end;
        if (FModifyCount > 50) then begin
          if (MessageDlg('Commit', 'There are too many transactions, do you want to commit', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then begin
            FTrans.CommitRetaining;
            FModifyCount := 0;
          end else begin
            FModifyCount := 0;
          end;
        end;
      if FStartLine >= FQuery.Count then
        FFinished := True;
    end;
  except
    on E: Exception do begin
      if Assigned(FTab) then FTab.TabVisible := False;
      FTab := CreateResultTab(qtExecute, vSQLQuery, FScript, FResultMemo);
      FTab.ImageIndex := 2;
      pgOutputPageCtl.ActivePage := FTab;
      FResultMemo.Text := e.message;
      FResultMemo.Lines.Add('--------');
      FResultMemo.Lines.Add(FQueryPart);
      FResultMemo.Font.Color := clRed;
      FFinished := True;
    end;
  end;
end;

function TfmQueryWindow.GetAutoCommit :Boolean;
begin
  Result := cxAutoCommit.Checked;
end;

function TfmQueryWindow.GetEditorFont :TFont;
begin
  Result := meQuery.Font;
end;


{ Execute script }

function TfmQueryWindow.ExecuteScript(Script: string): Boolean;
var
  StartTime: TDateTime;
  SqlQuery: TMDOQuery;
  SqlScript: TMDOScript;
  meResult: TMemo;
  ATab: TTabSheet;
begin
  StartTime:= Now;
  ATab:= nil;
  SQLScript:= nil;
  try
    // CreateResultTab creates the SQLScript object for us.
    ATab:= CreateResultTab(qtScript, SqlQuery, SQLScript, meResult);
    try
      ATab.ImageIndex:= 2;
      SQLScript.Script.Text:= Script;
      {$IFDEF DEBUG}
      SendDebug('going to run script: '+SQLScript.Script.Text);
      {$Endif}
      SQLScript.ExecuteScript;

      // Auto commit
      if cxAutoCommit.Checked then
        FTrans.CommitRetaining;

      Result:= True;
      meResult.Lines.Text:= FormatDateTime('hh:nn:ss.z', Now) + ' - Script Executed. It took (H:M:S.MS) ' +
        FormatDateTime('HH:nn:ss.z', Now - StartTime);
      meResult.Lines.Add('--------');
      meResult.Lines.Add(Script);
    finally
      SQLScript.Free;
    end;
  except
    on E: Exception do
    begin
      {$IFDEF DEBUG}
      SendDebug('ExecuteScript failed; error '+E.Message);
      {$Endif}
      Result:= False;
      if Assigned(ATab) then
        ATab.TabVisible:= False;
      ATab:= CreateResultTab(qtExecute, SqlQuery, SqlScript, meResult);
      pgOutputPageCtl.ActivePage:= ATab;
      meResult.Text:= e.Message;
      meResult.Lines.Add('--------');
      meResult.Lines.Add(Script);
      meResult.Font.Color:= clRed;
      ATab.Font.Color:= clRed;
      ATab.ImageIndex:= 3;
    end;
  end;
end;



{ Display new Save/Apply button for current query result been edited }

procedure TfmQueryWindow.NewApplyButton(var Pan: TPanel; var ATab: TTabSheet);
var
  Apply: TBitBtn;
begin
  Apply:= TBitBtn.Create(self);
  Apply.Parent:= Pan;
  Apply.Caption:= 'Apply'; //don't change this; code looks for this exact caption
  Apply.Left:= 300;
  Apply.Visible:= False;
  Apply.OnClick:= @ApplyClick;
  Apply.Tag:= ATab.TabIndex;
end;


{ GetSQLType: get SQL type of current SQL text }

function TfmQueryWindow.GetSQLType(Query: string; var Command: string): string;
begin
  Result:= 'DML'; //default
  Query:= Trim(Query);
  if (Query <> '') and (Pos(' ', Query) > 0) then
  begin
    // to do: this does not take comments into account...
    Command:= Copy(Query, 1, Pos(' ', Query) - 1);
    Command:= LowerCase(Command);
    if (Command = 'alter') or
       (Command = 'create') or
       (Command = 'drop') or
       (Command = 'grant') {actually DCL} or
       (Command = 'revoke') {actually DCL} then
      Result:= 'DDL';
  end;
end;


{ GetSQLSeqment: read part of SQL end by ; }

function TfmQueryWindow.GetSQLSegment(QueryList: TStringList; StartLine: Integer;
  var QueryType: TQueryTypes; var EndLine: Integer;
  var SQLSegment: string; var IsDDL: Boolean): Boolean;
var
  i: Integer = 0;
  RealStartLine: Integer = 0;
  SecondRealStart: Integer = 0;
  BeginExists: Boolean = False;
begin
  // Get start
  SQLSegment:= '';
  RealStartLine:= StartLine;
  SecondRealStart:= RealStartLine;
  Result:= False;

  // Remove comments
  RemoveAllSingleLineComments(QueryList);
  RemoveComments(QueryList, StartLine, RealStartLine);

  SecondRealStart:= RealStartLine;

  // remove empty lines
  RemoveEmptyLines(QueryList, SecondRealStart, RealStartLine);

  // Get SQL type
  QueryType:= GetQuerySQLType(QueryList, SecondRealStart, IsDDL);

  // Concatenate
  SQLSegment:= '';
  BeginExists:= False;
  for i:= SecondRealStart to QueryList.Count - 1 do
  begin
    if Pos('begin', Trim(LowerCase(QueryList[i]))) > 0 then
      BeginExists:= True;

    SQLSegment:= SQLSegment + QueryList[i] + LineEnding;

    if (QueryType in [qtSelectable, qtExecute]) and
      (((Pos(';', QueryList[i]) > 0) and (Not BeginExists)) or
      ((Pos('end', LowerCase(Trim(QueryList[i]))) = 1) and BeginExists)
      or (i = QueryList.Count - 1)) then
    begin
      Result:= True;
      if (not BeginExists) and (Pos(';', QueryList[i]) > 0) then
      begin
        QueryList[i]:= Trim(Copy(QueryList[i],  Pos(';', QueryList[i]) + 1, Length(QueryList[i])));
        if QueryList[i] = '' then
        EndLine:= i
        else
        begin
          EndLine:= i - 1;
          SQLSegment:= Trim(Copy(SQLSegment, 1, Pos(';',  SQLSegment)));
        end;
      end
      else
        EndLine:= i;
      Break;
    end
    else
    if (QueryType = qtScript) and
      ((i > SecondRealStart) and (Pos('set term', LowerCase(Trim(QueryList[i]))) = 1)) or
      (i = QueryList.Count - 1) then
    begin
      Result:= True;
      EndLine:= i;
      Break;
    end;
  end;
end;

procedure TfmQueryWindow.QueryAfterPost(DataSet: TDataSet);
begin
  // User has edited cells, so let him save
  EnableApplyButton;
end;



{ Run query, 0 for auto-detect query type }

procedure TfmQueryWindow.bbRunClick(Sender: TObject);
begin
  CallExecuteQuery(qtUnknown);
end;


{ Display Blob contents in a message box }

procedure TfmQueryWindow.DBGrid1DblClick(Sender: TObject);
begin
  ShowMessage('Field contents: ' + LineEnding +
    (Sender as TDBGrid).SelectedField.AsString)
end;


{ Sort by columns }

procedure TfmQueryWindow.DBGridTitleClick(column: TColumn);
var
  SqlQuery: TSQLQuery;
//    indexoption : TIndexOptions;
begin
  SQLQuery:= nil;
  SqlQuery:= GetCurrentSelectQuery;
  if (assigned(SqlQuery)) and
    (SqlQuery.IndexFieldNames = Column.Field.FieldName) then
    SqlQuery.IndexFieldNames := Column.Field.FieldName //+ 'DESC'
    //   indexoption :=[ixDescending];
    //   SqlQuery.AddIndex('',Column.Field.FieldName,indexoption,'');
  else
    SqlQuery.IndexFieldNames := Column.Field.FieldName
end;


{ Find text }

procedure TfmQueryWindow.FindDialog1Find(Sender: TObject);
begin
  FOptions:= [];

  if frMatchCase in FindDialog1.Options then
    FOptions:= FOptions + [ssoMatchCase];

  if frWholeWord in FindDialog1.Options then
    FOptions:= FOptions + [ssoWholeWord];

  if not (frDown in FindDialog1.Options) then
    FOptions:= FOptions + [ssoBackwards];

   if frEntireScope in FindDialog1.Options then
     FOptions:= FOptions + [ssoEntireScope];

  meQuery.SearchReplace(FindDialog1.FindText, '', FOptions);
end;


{ QueryWindow onClose event, commit active transaction, remove controls }

procedure TfmQueryWindow.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  // Check if the transaction is active; then commit it
  if FTrans.Active then
  begin
    FTrans.Commit;
    if OnCommit <> nil then
      OnCommit(self);
    OnCommit:= nil;
  end;
  FConn.Close;
  RemovePreviousResultTabs;
  OutputTabsList.Free;
  CloseAction:= caFree;
end;


{ Initialize auto-completion text in QueryWindow OnCreate event }

procedure TfmQueryWindow.FormCreate(Sender: TObject);
var
  vConfigFile     :TIniFile;
  vConfigFilePath :String;
begin
  OutputTabsList:= nil;
  {$IFNDEF DEBUG}
  // Do not log to debug server if built as release instead of debug
  SetDebuggingEnabled(false);
  {$ENDIF}
  FQuery:= TStringList.Create;
  // Initialize new instance of FIBConnection and SQLTransaction
  FConn := TMDODataBase.Create(nil);
  {$IFDEF DEBUG}
  //FConn.OnLog:=@GetLogEvent;                                          //JKOZ:LOG
  //FConn.LogEvents:=[detCustom,detExecute,detCommit,detRollBack];
  {$ENDIF DEBUG}
  FTrans := TMDOTransaction.Create(nil);//JKOZ: MEMORY LEAK?
  SynCompletion1.ItemList.CommaText := 'create,table,Select,From,INTEGER,FLOAT';
  SortSynCompletion;

  // Set the editor font from config.ini
  utbConfig.IniLoadData(cQuerySection, meQuery.Font);
end;

procedure TfmQueryWindow.FormDestroy(Sender: TObject);
begin
  // Clean up resources to avoid memory leaks
  FTrans.Free;
  FConn.Free;
  FQuery.Free;
end;

procedure TfmQueryWindow.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (ssCtrl in Shift) and
    ((Key=VK_F4) or (Key=VK_W)) then
  begin
    if ((Trim(meQuery.Lines.Text) = '') or
      (MessageDlg('Do you want to close this query window?', mtConfirmation, [mbNo, mbYes], 0) = mrYes))
      then
    begin
      // Close when pressing Ctrl-W or Ctrl-F4 (Cmd-W/Cmd-F4 on OSX)
      Close;
      Parent.Free;
    end;
  end;
end;


{ focus on Query SQL window editor on form show }

procedure TfmQueryWindow.FormShow(Sender: TObject);
begin
  meQuery.SetFocus;
end;


{ Close current Query window }

procedure TfmQueryWindow.lmCloseTabClick(Sender: TObject);
begin
  if (Trim(meQuery.Lines.Text) = '') or
    (MessageDlg('Do you want to close this query window?', mtConfirmation, [mbNo, mbYes], 0) = mrYes) then
  begin
    Close;
    Parent.Free;
  end;
end;


{ Save query result in a comma delimited file }

procedure TfmQueryWindow.lmCommaDelimitedClick(Sender: TObject);
var
  i: Integer;
  F: TextFile;
  SqlQuery: TSQLQuery;
begin
  SaveDialog1.DefaultExt:= '.txt';
  SqlQuery:= nil;
  SqlQuery:= GetCurrentSelectQuery;
  if not(assigned(SqlQuery)) then
  begin
    ShowMessage('There is no recordset in result');
    Exit;
  end;
  if (not SqlQuery.Active) or (SqlQuery.RecordCount = 0) then
    MessageDlg('No data', mtError, [mbOk], 0)
  else
  if SaveDialog1.Execute then
  begin
    SqlQuery.DisableControls;
    SqlQuery.First;
    AssignFile(F, SaveDialog1.FileName);
    Rewrite(F);
    for i:= 0 to SqlQuery.FieldCount - 1 do
    begin
      Write(F, '"', SqlQuery.Fields[i].FieldName, '"');
      if i = SqlQuery.FieldCount - 1 then
        Writeln(F)
      else
        Write(F, ', ');
    end;

    while not SqlQuery.EOF do
    begin
      for i:= 0 to SqlQuery.FieldCount - 1 do
      begin
        Write(F, '"', SqlQuery.Fields[i].AsString, '"');
        if i = SqlQuery.FieldCount - 1 then
          Writeln(F)
        else
          Write(F, ', ');
      end;
      SqlQuery.Next;
    end;
    CloseFile(F);
    SqlQuery.EnableControls;
  end;

end;


{ Copy query result in Clipboard }

procedure TfmQueryWindow.lmCopyAllClick(Sender: TObject);
var
   Grid: TDBGrid;
   i: Integer;
   List: TStringList;
   Line: string;
begin
  Grid:= TDBGrid(pmGrid.PopupComponent);
  try
    Grid.DataSource.DataSet.DisableControls;
    Grid.DataSource.DataSet.First;
    List:= TStringList.Create;
    try
      Line:= '';

      // Copy fields header
      with Grid.DataSource.DataSet do
      for i:= 0 to FieldCount - 1 do
      begin
        Line:= Line + '"' + Fields[i].FieldName + '"';
        if i + 1 < FieldCount then
          Line:= Line + ',';
      end;
      List.Add(Line);

      // Copy table data
      with Grid.DataSource.DataSet do
      while not Eof do
      begin
        Line:= '';
        for i:= 0 to FieldCount - 1 do
        begin
          Line:= Line + '"' + Trim(Fields[i].AsString) + '"';
          if i + 1 < FieldCount then
            Line:= Line + ',';
        end;
        List.Add(Line);
        Next;
      end;
      Clipboard.AsText:= List.Text;
    finally
      List.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Error trying to copy: '+e.Message);
  end;
  grid.DataSource.DataSet.EnableControls;
end;


{ Copy cell in clipboard }

procedure TfmQueryWindow.lmCopyCellClick(Sender: TObject);
begin
  Clipboard.AsText:= TdbGrid(pmGrid.PopupComponent).SelectedField.AsString;
end;


{ Copy query text into clipboard }

procedure TfmQueryWindow.lmCopyClick(Sender: TObject);
begin
  meQuery.CopyToClipboard;
end;


{ Cut query text into clipboard}

procedure TfmQueryWindow.lmCutClick(Sender: TObject);
begin
  meQuery.CutToClipboard;
end;


{ Export to comma delimited file }

procedure TfmQueryWindow.lmExportAsCommaClick(Sender: TObject);
begin
  lmCommaDelimitedClick(nil);
end;

{ Export as HTML }

procedure TfmQueryWindow.lmExportAsHTMLClick(Sender: TObject);
begin
  lmHTMLClick(nil);
end;


{ Save query result as HTML }

procedure TfmQueryWindow.lmHTMLClick(Sender: TObject);
var
  i: Integer;
  F: TextFile;
  SqlQuery: TSQLQuery;
begin
  SaveDialog1.DefaultExt:= '.htm';
  SqlQuery:= nil;
  SqlQuery:= GetCurrentSelectQuery;

  // Check for results being present:
  if not(assigned(SqlQuery)) then
  begin
    MessageDlg('There is no record set in result', mtError, [mbOk], 0);
    exit;
  end;
  if (not SQLQuery.Active) or (SQLQuery.RecordCount = 0) then
  begin
    MessageDlg('No data', mtError, [mbOk], 0);
    exit;
  end;

  // We know there's valid data, let's try to save:
  if SaveDialog1.Execute then
  begin
    SQLQuery.DisableControls;
    SQLQuery.First;
    AssignFile(F, SaveDialog1.FileName);
    Rewrite(F);
    Writeln(F, '<table border=0><tr bgcolor="DDDDDD">');
    for i:= 0 to SQLQuery.FieldCount - 1 do
    begin
      Write(F, '<th>', SQLQuery.Fields[i].FieldName, '</th>');
      if i = SQLQuery.FieldCount - 1 then
        Writeln(F, '</tr>');
    end;

    while not SQLQuery.EOF do
    begin
      Write(f, '<tr bgcolor="');
      // Zebra stripes in output:
      if SQLQuery.RecNo mod 2 = 0 then
        Write(F, '#EEDDFF">')
      else
        Write(F, '#FFFFFF">');

      for i:= 0 to SQLQuery.FieldCount - 1 do
      begin
        Write(F, '<td>', SQLQuery.Fields[i].AsString, '</td>');
        if i = SQLQuery.FieldCount - 1 then
          Writeln(F, '</tr>');
      end;
      SQLQuery.Next;
    end;
    Writeln(F, '</table>');
    CloseFile(F);
    SQLQuery.EnableControls;
  end;
end;



{ Paste from clipboard into SQL editor }

procedure TfmQueryWindow.lmPasteClick(Sender: TObject);
begin
  meQuery.PasteFromClipboard;
end;


{ SQL Editor Redo }

procedure TfmQueryWindow.lmRedoClick(Sender: TObject);
begin
  meQuery.Redo;
end;


{ Run Query, auto type detection }

procedure TfmQueryWindow.lmRunClick(Sender: TObject);
begin
  CallExecuteQuery(qtUnknown);
end;


{ Run query and force its type as executable statement}

procedure TfmQueryWindow.lmRunExecClick(Sender: TObject);
begin
  CallExecuteQuery(qtExecute);
end;


{ Run query, and force its type as script }

procedure TfmQueryWindow.lmRunScriptClick(Sender: TObject);
begin
  CallExecuteQuery(qtScript);
end;


{ Run query, force its type as select statement }

procedure TfmQueryWindow.lmRunSelectClick(Sender: TObject);
begin
  CallExecuteQuery(qtSelectable);
end;


{ select all in SQL Editor }

procedure TfmQueryWindow.lmSelectAllClick(Sender: TObject);
begin
  meQuery.SelectAll;
end;


{ SQL Editor undo }

procedure TfmQueryWindow.lmUndoClick(Sender: TObject);
begin
  meQuery.Undo;
end;


{ Search in SQL Editor }

procedure TfmQueryWindow.lmFindClick(Sender: TObject);
begin
  FindDialog1.Execute;
end;


{ Find again }

procedure TfmQueryWindow.lmFindAgainClick(Sender: TObject);
begin
  meQuery.SearchReplace(FindDialog1.FindText, '', FOptions);
end;


{ Run query by pressing Ctrl + Enter }

procedure TfmQueryWindow.meQueryKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Execute query by pressing Ctrl + Enter
  if (ssCtrl in shift) and (key = VK_RETURN) then
  begin
    CallExecuteQuery(qtUnknown);
    key:= 0;
  end;
end;

procedure TfmQueryWindow.SQLQuery1test1GetText(Sender :TField; var aText :string; DisplayText :Boolean);
var
  vStrm :TStream;
  vLen  :Integer;
begin
  vStrm := Sender.DataSet.CreateBlobStream(Sender, bmRead);
  if vStrm <> nil then
    try
      vLen := vStrm.Size;
      SetLength(aText, vLen);
      if vLen > 0 then
        vStrm.ReadBuffer(aText[1], vLen);
    finally
      vStrm.Free
    end
  else aText := '';
end;


{ Scrolling in query result recordset }

procedure TfmQueryWindow.QueryAfterScroll(DataSet: TDataSet);
var
  Ctl: TControl;
  TabSheet: TTabSheet;
  i: Integer;
begin
  TabSheet:= nil;

  // Get DataSet's TTabsheet
  // The query object's tag should be the tab index number
  if (Dataset is TSQLQuery) then
    TabSheet:= pgOutputPageCtl.Pages[TSQLQuery(DataSet).Tag];

  if assigned(TabSheet) then begin
    for i := 0 to TabSheet.ControlCount-1 do begin
      Ctl := TabSheet.Controls[i];
      if (Ctl is TStatusBar) then begin
        // Display current record and number of total records in status bar
        TStatusBar(Ctl).SimpleText:= IntToStr(DataSet.RecordCount) + ' records fetched. At record # ' + IntToStr(DataSet.RecNo);
        Break;
      end;
    end;
  end;
end;


{ Execute query according to passed query type }

procedure TfmQueryWindow.CallExecuteQuery(aQueryType: TQueryTypes);
begin
  // Get query text from memo
  if not(GetQuery(FQuery)) then begin
    ShowMessage('Could not get valid query');
    exit;
  end;
  FStartLine:= 0;
  RemovePreviousResultTabs;

  // Disable buttons to prevent query interrupt
  tbRun.Enabled               := False;
  tbCommit.Enabled            := False;
  tbCommitRetaining.Enabled   := False;
  tbRollback.Enabled          := False;
  tbRollbackRetaining.Enabled := False;

  FModifyCount:= 0;

  // Get initial query type; this can be changed later in the next parts
  if aQueryType = qtUnknown then // Auto
    FOrigQueryType := GetQueryType(FQuery.Text)
  else
    FOrigQueryType := aQueryType;

  // Call execute query for each part until finished
  FCounter := 0;
  FFinished := False;
  repeat      //JKOZ:REMOVE LOOP
    ExecuteQuery2;
  until FFinished;
  EnableButtons;
end;


{ sort auto completion options }

procedure TfmQueryWindow.SortSynCompletion;
var
  SortingList: TStringList;
  i: Integer;
begin
  SortingList:=TStringList.Create;
  try
    for i:=0 to SynCompletion1.ItemList.Count-1 do
       SortingList.Add(SynCompletion1.ItemList.Strings[i]);
    SortingList.Sort;
    SynCompletion1.ItemList.Clear;
    for i:=0 to SortingList.Count-1 do
      SynCompletion1.ItemList.Add(SortingList.Strings[i]);
  finally
    SortingList.Free;
  end;
end;


{ SQL thread termination }

procedure TfmQueryWindow.ThreadTerminated(Sender: TObject);
var
  aSQLQuery: TMDOQuery;
begin
  // Raise exception if an error occured during thread execution (Open)
  if FQT.Error then
  begin
    if Assigned(FTab) then
      FTab.TabVisible:= False;
    aSQLQuery:= (Sender as TQueryThread).Query;
    FTab := CreateResultTab(qtExecute, aSQLQuery, FScript, FResultMemo);
    pgOutputPageCtl.ActivePage:= FTab;

    FResultMemo.Text:= FQT.ErrorMsg;
    FResultMemo.Lines.Add(FQueryPart);
    FResultMemo.Font.Color:= clRed;
    FTab.Font.Color:= clRed;
    FTab.ImageIndex:= 3;
  end
  else
  begin
    FTab.Caption:= FAText;
    FTab.ImageIndex:= 0;
    fmMain.AddToSQLHistory(FDB^.RegRec.Title, 'SELECT', FQueryPart);
  end;
  FQT.Free;
  if FFinished then
    EnableButtons;

  if not FFinished then
    ExecuteQuery;

end;

{ Enable SQL buttons: Run, Commit, Rollbak after thread termination }

procedure TfmQueryWindow.EnableButtons;
begin
  tbRun.Enabled               := True;
  tbCommit.Enabled            := True;
  tbCommitRetaining.Enabled   := True;
  tbRollback.Enabled          := True;
  tbRollbackRetaining.Enabled := True;
end;

procedure TfmQueryWindow.LoadSettings;
begin
  utbConfig.IniLoadData(cQuerySection,meQuery.Font);
end;

//initialization
//  {.$I querywindow.lrs}

{ move to evstring unit.
function DamerauLevenshteinDistance(const Str1, Str2: String): Integer;

  function Min(const A, B, C: Integer): Integer;
  begin
    Result := A;
    if B < Result then
      Result := B;
    if C < Result then
      Result := C;
  end;

var
  LenStr1, LenStr2: Integer;
  I, J, T, Cost, PrevCost: Integer;
  pStr1, pStr2, S1, S2: PChar;
  D: PIntegerArray;
begin
  LenStr1 := Length(Str1);
  LenStr2 := Length(Str2);

  // save a bit memory by making the second index points to the shorter string
  if LenStr1 < LenStr2 then
  begin
    T := LenStr1;
    LenStr1 := LenStr2;
    LenStr2 := T;
    pStr1 := PChar(Str2);
    pStr2 := PChar(Str1);
  end
  else
  begin
    pStr1 := PChar(Str1);
    pStr2 := PChar(Str2);
  end;

  // bypass leading identical characters
  while (LenStr2 <> 0) and (pStr1^ = pStr2^) do
  begin
    Inc(pStr1);
    Inc(pStr2);
    Dec(LenStr1);
    Dec(LenStr2);
  end;

  // bypass trailing identical characters
  while (LenStr2 <> 0) and ((pStr1 + LenStr1 - 1)^ = (pStr2 + LenStr2 - 1)^) do
  begin
    Dec(LenStr1);
    Dec(LenStr2);
  end;

  // is the shorter string empty? so, the edit distance is length of the longer one
  if LenStr2 = 0 then
  begin
    Result := LenStr1;
    Exit;
  end;

  // calculate the edit distance
  GetMem(D, (LenStr2 + 1) * SizeOf(Integer));

  for I := 0 to LenStr2 do
    D[I] := I;

  S1 := pStr1;
  for I := 1 to LenStr1 do
  begin
    PrevCost := I - 1;
    Cost := I;
    S2 := pStr2;
    for J := 1 to LenStr2 do
    begin
      if (S1^ = S2^) or ((I > 1) and (J > 1) and (S1^ = (S2 - 1)^) and (S2^ = (S1 - 1)^)) then
        Cost := PrevCost
      else
        Cost := 1 + Min(Cost, PrevCost, D[J]);
      PrevCost := D[J];
      D[J] := Cost;
      Inc(S2);
    end;
    Inc(S1);
  end;
  Result := D[LenStr2];
  FreeMem(D);
end;
}
end.


unit main;

{ Main TurboBird form
If you want to add popup menus for tables, views etc, please set the Tag
property of the popup menu to the right value.
}

//JKoz modifications.
// 1) Only the database node should hold database specific information in its data variable.
// 2) Add support for node type.
// 3) change popup filtering by incorporating the node type logic or absorbing the existing logic to node type.
// 4) Convert all the code from the click events to actions make sure that no logic is lost in the process.
// 5) Create a new main menu with all the menus present in the application everything must be accesible from the menu.
// 6) Remove all session information from the main form.
//    delete TDBInfo record and move the management of this information to the systables datamodule.
// 7) make sure that threads have their own data objects to use and never share objects with the main thread.
// 8) Cleanup the main form. Leave only behavioral and GUI code on the form. Move the logic to the datamodule.
// 9) each database will create its own datamodule on connect and destroy it on disconnect.
//10) the tree will only show the connected databases remove all the disconnected data from it.
//11) retreive all data on connection (in a thread) and remove the double click logic.
//12) replace all icons with my own, make sure that both open source and freeware have the same look and feel.
//13) Create a logo and an Icon for the application. (done).
// 01 : Data Changes.
//   0001 : move all public variables to private and replace them with properties if required.
//   0002 : Replace array with the TevsDBRegistry class.

// 02 : Meta Data.
//   0001 : make sure that the metadata are cached in the application and do not requery the database continuesly.
//   0002 : Refresh existing data on request.
//       01 : clear all the child nodes data.
//       02 : requery the database for the nodes details.

{$mode objfpc}{$H+}
{$DEFINE UseDebugLog}
{$DEFINE DEBUG_CONFIG}
{$DEFINE EVS_TKControl}
interface
{ TODO -oJKOZ -cMeta Data : Add Refresh to all nodes of the tree except the root node. }
{ TODO -oJKOZ -cUser Interface : Drag and drop objects between databases, aka carbon copy an object, mostly tables generators and triggers.}
{ TODO -oJKOZ -cUser Interface. : Middle click on a tab closes the tab. }
{ TODO : Remove the Query node from the tree, move it to the toolbar and menu system as it should be. }
{ TODO -oJKOZ -cUser interface. : Make sure that the tree can change the ammount and style of grouping to what ever the user needs it to be.For now
that means remove all the unwanted groups and leave only the absolutely minimum required to be able to work with the data. }
{ TODO -oJKOZ -cMeta Data : Move all the database specific code outside the forms for example getConstrainFields in the main form must be
move to a firebird specific unit }
{$DEFINE IBCNN}
uses
  Classes, SysUtils, Menus, sqldb, memds, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls, Reg, QueryWindow, Grids, ExtCtrls, TableManage,
  Buttons, ActnList, dbugintf, turbocommon, IBConnection, Clipbrd, MDOQuery, MDODatabase, MDO, MDOServices, MDOCustomDataSet, MDODatabaseInfo,
  uTBTypes, utbConfig, uEvsOptions, utbDBRegistry, typinfo, importtable;

type
  //TDBInfo = record
  //  Index        :Integer;
  //  RegRec       :TDBDetails;
  //  OrigRegRec   :TDBDetails;
  //  IBConnection :TIBConnection;
  //  SQLTrans     :TSQLTransaction;
  //end;

  { TPageControl }
 //replace the existing pagecontrol with this one that closes
 //tabs with a middle click.
  TOnCloseEvent = procedure (aSender:TObject; aTab:TCustomPage) of object;
  TPageControl = Class(ComCtrls.TPageControl)
  private
    FOnTabClose :TOnCloseEvent;
    procedure TabDestruction(aSender:TObject);
    procedure SetOnTabClose(aValue :TOnCloseEvent);
  published
    procedure MouseUp(Button :TMouseButton; Shift :TShiftState; X, Y :Integer); override;
    property OnTabClose:TOnCloseEvent read FOnTabClose write SetOnTabClose;
  end;

  { TfmMain }

  TfmMain = class(TForm)
    actExit                 :TAction;
    actFontEditor           :TAction;
    actAbout                :TAction;
    actBackupDB             :TAction;
    actQuery :TAction;
    actOptions              :TAction;
    actRefre                :TAction;
    actRefresh              :TAction;
    actRefreshDatabase      :TAction;
    actRegisterDB           :TAction;
    actRestoreDB            :TAction;
    actNewDB                :TAction;
    ActionList1             :TActionList;
    CoolBar1                :TCoolBar;
    editorFontDialog        :TFontDialog;
    Image2                  :TImage;
    ImageList1              :TImageList;
    MDODatabase1 :TMDODatabase;
    mniDummy :TMenuItem;
    qryMain                 :TMDOQuery;
    MenuImageList22         :TImageList;
    MainMenu2               :TMainMenu;
    MenuItem1               :TMenuItem;
    MenuItem10              :TMenuItem;
    MenuItem3               :TMenuItem;
    MenuItem4               :TMenuItem;
    mniBackupDB             :TMenuItem;
    mniSeperator1           :TMenuItem;
    mnuConnect              :TMenuItem;
    MenuItem2               :TMenuItem;
    mnuDatabase             :TMenuItem;
    mniNewDatabase          :TMenuItem;
    mniRegisterDatabase     :TMenuItem;
    mniRestoreDatabase      :TMenuItem;
    MenuItem7               :TMenuItem;
    MenuItem8               :TMenuItem;
    MenuItem9               :TMenuItem;
    mnOptions               :TMenuItem;
    mnEditorFont            :TMenuItem;
    SQLQueryOLD             :TSQLQuery;
    tbtnAbout               :TToolButton;
    tbtnCreateNewDB         :TToolButton;
    tbtnEditorFont          :TToolButton;
    tbtnRegDatabase         :TToolButton;
    tbtnRestoreDatabase     :TToolButton;
    ToolBar1                :TToolBar;
    toolbarImages           :TImageList;
    MainMenu1               :TMainMenu;
    mdsHistory              :TMemDataset;
    lmImportTable           :TMenuItem;
    mnFile                  :TMenuItem;
    lmDisplayView           :TMenuItem;
    lmViewTrigger           :TMenuItem;
    lmCreateDB              :TMenuItem;
    lmRegdb                 :TMenuItem;
    lmRestore               :TMenuItem;
    lmSweep                 :TMenuItem;
    lmAddUser               :TMenuItem;
    lmChangePassword        :TMenuItem;
    lmUserPermManagement    :TMenuItem;
    lmRolePerManagement     :TMenuItem;
    lmSetGen                :TMenuItem;
    lmDisconnect            :TMenuItem;
    lmCopyTable             :TMenuItem;
    lmCopyUserPermission    :TMenuItem;
    lmViewFields            :TMenuItem;
    lmEditField             :TMenuItem;
    lmDBInfo                :TMenuItem;
    lmCopyRolePermission    :TMenuItem;
    lmCompare               :TMenuItem;
    lmGetIncrementGen       :TMenuItem;
    lmDropTable             :TMenuItem;
    lmRecalculateStatistics :TMenuItem;
    mnuImport               :TMenuItem;
    mnExit                  :TMenuItem;
    mnCreateDB              :TMenuItem;
    mnRegDB                 :TMenuItem;
    mnHelp                  :TMenuItem;
    mnAbout                 :TMenuItem;
    lmEditReg               :TMenuItem;
    lmUnregisterDatabase    :TMenuItem;
    lmViewFirst1000         :TMenuItem;
    lmViewStoredProcedure   :TMenuItem;
    lmViewGen               :TMenuItem;
    lmNewTable              :TMenuItem;
    lmNewGen                :TMenuItem;
    lmCreateAutoInc         :TMenuItem;
    lmCreateStoredProc      :TMenuItem;
    lmEditProc              :TMenuItem;
    lmCreateView            :TMenuItem;
    lmDisplay1000V          :TMenuItem;
    lmEditView              :TMenuItem;
    lmCreateTrigger         :TMenuItem;
    lmEditTrigger           :TMenuItem;
    lmActivateTrig          :TMenuItem;
    lmDeactiveTrig          :TMenuItem;
    lmScriptTable           :TMenuItem;
    lmScriptTableCreate     :TMenuItem;
    lmScriptInsert          :TMenuItem;
    lmScriptUpdate          :TMenuItem;
    lmEditTable             :TMenuItem;
    lmCallStoreProc         :TMenuItem;
    lmEditDataForm          :TMenuItem;
    lmNewUDF                :TMenuItem;
    lmViewUDF               :TMenuItem;
    lmOpenSystemTable       :TMenuItem;
    lmViewDomain            :TMenuItem;
    lmNewDomain             :TMenuItem;
    lmNewRole               :TMenuItem;
    lmSeparator             :TMenuItem;
    lmOpenQuery             :TMenuItem;
    lmNewException          :TMenuItem;
    lmRefresh               :TMenuItem;
    lmDropException         :TMenuItem;
    lmScriptException       :TMenuItem;
    lmScriptDatabase        :TMenuItem;
    lmConnectAs             :TMenuItem;
    lmPermissions           :TMenuItem;
    lmRolePermissions       :TMenuItem;
    lmTableManage           :TMenuItem;
    lmSeparator2            :TMenuItem;
    lmBackup                :TMenuItem;
    mnRestore               :TMenuItem;
    PageControl1            :TPageControl;
    pmDatabase              :TPopupMenu;
    Splitter1               :TSplitter;
    StatusBar1              :TStatusBar;
    tbMain                  :TTabSheet;
    TBarImages32            :TImageList;
    ToolButton1 :TToolButton;
    ToolButton2 :TToolButton;
    ToolButton3             :TToolButton;
    tvMain                  :TTreeView;
    procedure actExitExecute      (Sender :TObject);
    procedure actFontEditorExecute(Sender :TObject);
    procedure actAboutExecute     (Sender :TObject);
    procedure actNewDBExecute     (Sender :TObject);
    procedure actQueryExecute(Sender :TObject);
    procedure actRefreshDatabaseExecute(Sender :TObject);
    procedure actRefreshExecute   (Sender :TObject);
    procedure actRegisterDBExecute(Sender :TObject);
    procedure actRestoreDBExecute (Sender :TObject);
    procedure FormActivate        (Sender: TObject);
    procedure FormClose           (Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate          (Sender: TObject);
    procedure FormDestroy         (Sender: TObject);
    procedure lmAddUserClick      (Sender: TObject);
    procedure lmBackupClick       (Sender: TObject);
    procedure lmChangePasswordClick(Sender: TObject);
    procedure lmCompareClick       (Sender: TObject);
    procedure lmCopyRolePermissionClick(Sender: TObject);
    procedure lmCopyUserPermissionClick(Sender: TObject);
    procedure lmCopyTableClick (Sender: TObject);
    procedure lmCreateDBClick  (Sender: TObject);
    procedure lmDBInfoClick    (Sender: TObject);
    procedure lmDisconnectClick(Sender: TObject);
    procedure lmEditFieldClick (Sender: TObject);
    procedure lmGetIncrementGenClick(Sender: TObject);
    procedure lmImportTableClick    (Sender: TObject);
    // Show all records in table
    procedure lmOpenSystemTableClick(Sender: TObject);
    procedure lmActivateTrigClick   (Sender: TObject);
    procedure lmCallStoreProcClick  (Sender: TObject);
    procedure lmConnectAsClick      (Sender: TObject);
    procedure lmCreateAutoIncClick  (Sender: TObject);
    procedure lmCreateTriggerClick  (Sender: TObject);
    procedure lmCreateViewClick     (Sender: TObject);
    procedure lmDeactiveTrigClick   (Sender: TObject);
    procedure lmDisplay1000VClick   (Sender: TObject);
    procedure lmDropExceptionClick  (Sender: TObject);
    procedure lmEditDataFormClick   (Sender: TObject);
    procedure lmEditProcClick       (Sender: TObject);
    procedure lmEditTableClick      (Sender: TObject);
    procedure lmEditTriggerClick    (Sender: TObject);
    procedure lmEditViewClick       (Sender: TObject);
    procedure lmNewDomainClick      (Sender: TObject);
    procedure lmNewExceptionClick   (Sender: TObject);
    procedure lmNewGenClick         (Sender: TObject);
    procedure lmNewTableClick       (Sender: TObject);
    procedure lmNewUDFClick         (Sender: TObject);
    procedure lmOpenQueryClick      (Sender: TObject);
    procedure lmPermissionsClick    (Sender: TObject);
    procedure lmRefreshClick        (Sender: TObject);
    procedure lmRegdbClick          (Sender: TObject);
    procedure lmRestoreClick        (Sender: TObject);
    procedure lmRolePermissionsClick(Sender: TObject);
    procedure lmScriptDatabaseClick (Sender: TObject);
    procedure lmScriptExceptionClick(Sender: TObject);
    procedure lmScriptInsertClick   (Sender: TObject);
    procedure lmUserPermManagementClick(Sender: TObject);
    procedure lmCreateStoredProcClick  (Sender: TObject);
    procedure lmRolePerManagementClick (Sender: TObject);
    procedure lmScriptTableCreateClick (Sender: TObject);
    procedure lmScriptUpdateClick (Sender: TObject);
    procedure lmSetGenClick       (Sender: TObject);
    procedure lmSweepClick        (Sender: TObject);
    procedure lmTableManageClick  (Sender: TObject);
    procedure lmViewDomainClick   (Sender: TObject);
    procedure lmDisplayViewClick  (Sender: TObject);
    // Expand table field nodes
    procedure lmViewFieldsClick (Sender: TObject);
    procedure lmViewGenClick    (Sender: TObject);
    procedure lmViewTriggerClick(Sender: TObject);
    procedure lmViewUDFClick    (Sender: TObject);
    procedure lmDropTableClick  (Sender: TObject);
    procedure lmEditRegClick    (Sender: TObject);
    procedure lmViewFirst1000Click(Sender: TObject);
    procedure lmNewRoleClick      (Sender: TObject);
    procedure PageControl1Change  (Sender :TObject);
    procedure lmViewStoredProcedureClick  (Sender: TObject);
    procedure lmRecalculateStatisticsClick(Sender: TObject);
    procedure lmUnregisterDatabaseClick   (Sender: TObject);
    procedure PageControl1Changing(Sender :TObject; var AllowChange :Boolean);
    procedure PageControl1CloseTabClicked (Sender: TObject);
    procedure PageControl1MouseUp(Sender :TObject; Button :TMouseButton; Shift :TShiftState; X, Y :Integer);
    procedure pmDatabasePopup(Sender: TObject);
    procedure tvMainDblClick (Sender: TObject);
    procedure tvMainExpanded (Sender: TObject; Node: TTreeNode);
    procedure GlobalException(Sender: TObject; E : Exception);
  private
    //Page changing variables
    FOldPage : Integer;
    //session varaibles
    FConn               :TMDODataBase;
    FTrans              :TMDOTransaction;
    FCurrentHistoryFile :string;
    FActivated          :Boolean;

    function FindCustomForm(aTitle: string; aClass: TClass): TComponent;overload;
    function _FindCustomForm(aTitle: string; aClass: TFormClass): TForm;overload;
    // Show new generator form
    procedure InitNewGen(DatabaseIndex: Integer);
    function GetServerNameNode(ServerName: string): TTreeNode;
    // Remove RegisteredDatabases and clean up memory held by its objects
    procedure ReleaseRegisteredDatabases;
    // Set Connect for SQLQuery1 to selected registered database
    procedure SetConnection(Index: Integer);overload;
    procedure SetConnection(aDB:TDBInfo);overload;
    procedure SetFocus; override; // solve a bug in Lazarus //Which bug?
    function IsQueryNode(constref aNode:TTreeNode):Boolean;
  protected
    // This procedure will receive the events that are logged by the Connect:
    procedure GetLogEvent(Sender: TSQLConnection; EventType: TDBEventType; Const Msg : String); //JKOZ:MDO No logging yet
    //JKOZ : Extensions;
    function GetDBNode(aStart:TTreeNode):TTreenode;
    function IsDBNode(Const aNode :TTreeNode):Boolean;
    function GetDBIndex(const aNode:TTreeNode):Integer;overload;
    function GetDBIndex(const aDB:TDBInfo):Integer;overload;
    function GetTableName(const aNode:TTreeNode):string;
    //procedure SetNodeType(const aNode:TTreeNode; const aType:Integer);
    //function GetNodeType(Const aNode:TTreeNode):
    Function NewTab(const aParent:TWinControl; aIndex:Integer):TTabSheet;overload;inline;
    //Function NewTab(const aParent:TWinControl; aIndex:Integer; aTitle:String):TWinControl;overload;inline;
  public
    // Array of database Connect details as stored in turbobird.reg file
    RegisteredDatabases : TDBInfoArray;// array of TDBInfo; //JKOZ :01.002
    Version             : string;
    VersionDate         : string;
    Major, Minor,
    ReleaseVersion      : word;

    function GetServerName(DBName: string): string;
    function RetrieveInputParamFromSP(Body: string): string;
    // Load registered databases from file and show them in treeview
    function LoadRegisteredDatabases: Boolean;   //JKOZ :01.002
    function LoadRegisteredDatabases2: Boolean;  //JKOZ :01.002
    function FindQueryWindow(ATitle: string): TComponent;deprecated 'Use _FindCustomForm instead';
    function DeleteRegistration(Index: Integer): Boolean;
    // Returns BLOB subtype clause depending on subtype
    function GetBlobSubTypeName(SubType: integer): string;
    // Get name of index used for primary key
    // Also returns name of constraint used
    function GetPrimaryKeyIndexName(DatabaseIndex: Integer; ATableName: string; var ConstraintName: string): string;
    // Get primary key field(s) names into KeyFields
    function GetPrimaryKeyFields(DatabaseIndex: Integer; ATableName: string; var KeyFields: TStringList): boolean; //JKOZ : move to systables.
    function GetConstraintFields(ATableName, AIndexName: string; var List: TStringList): Boolean; //JKOZ : move to systables.
    // Get fields information for specified table
    // Fills SQLQuery1 with details
    procedure Get_Fields(DatabaseIndex :Integer; ATableName: string; FieldsList: TStringList);overload; deprecated ' pass the record not the index ';
    procedure Get_Fields(const aDatabase : TDBInfo; ATableName: string; const FieldsList: TStringList=nil);overload;
    // Get body of a stored procedure (without SET TERM... clauses)
    // Fills SQLQuery1 with details
    function GetStoredProcBody(DatabaseIndex: Integer; AProcName: string; var SPOwner: string): string;
    // Get body and output parameters of a view
    // Does *not* fill SQLQuery1 with details
    function GetViewInfo(DatabaseIndex: Integer; AViewName: string; var Columns, Body: string): Boolean;
    function ChangeTriggerActivity(DatabaseIndex: Integer; ATriggerName: string; ActiveState: Boolean): Boolean;
    function GetIndices(ATableName: string; AQuery: TSQLQuery): Boolean;deprecated 'Use the mdoQuery instead';
    function GetIndices(ATableName: string; const aQuery: TMDOQuery): Boolean;
    function GetIndexFields(ATableName, AIndexName: string; AQuery: TMDOQuery; var FieldsList: TStringList): Boolean;
    function GetUDFInfo(DatabaseIndex: Integer; UDFName: string; var ModuleName, EntryPoint, Params: string): Boolean;
    function ShowQueryWindow(DatabaseIndex: Integer; aTitle: string): TfmQueryWindow;overload;deprecated;
    function ShowQueryWindow(const aDatabase: PDBInfo; aTitle: string): TfmQueryWindow;overload;
    procedure FillObjectRoot(aNode: TTreeNode);
    procedure FillAndShowConstraintsForm(Form: TfmTableManage; ATableName: string; dbIndex: Integer);
    procedure ShowCompleteQueryWindow(DatabaseIndex: Integer; const ATitle:String; AQueryText: string; const OnCommitProcedure: TNotifyEvent = nil);
    procedure ShowCompleteQueryWindow(const aDatabase: PDBInfo; const ATitle, AQueryText: string; const OnCommitProcedure: TNotifyEvent = nil);
    // Gets fields info and fills TableManage form(!) grids with info
    procedure ViewTableFields(ATableName: string; dbIndex: Integer; AStringGrid: TStringGrid);
    procedure ShowIndicesManagement(AForm: TForm; DatabaseIndex: Integer; ATableName: string);
    function GetTableNames(dbIndex: Integer): string;
    function CreateNewTrigger(dbIndex: Integer; ATableName: string; OnCommitProcedure: TNotifyEvent = nil): Boolean;
    function AddToSQLHistory(DatabaseTitle: string; SQLType, SQLStatement: String): Boolean;
    function SaveAndCloseSQLHistory: Boolean;
    function OpenSQLHistory(DatabaseTitle: string): Boolean;
    // Connects to database.
    // If not succesful (or if ForceConnectDialog is true), ask user for credentials and try again
    function ConnectToDBAs(dbIndex: Integer; ForceConnectDialog: boolean=false): Boolean;
    function GetNodeObjectType(const aNode:TTreenode):uTBTypes.TObjectType;

    procedure ApplyEditorFont(const aFont:TFont);
  end;


var
  fmMain: TfmMain;


implementation

  {$R *.lfm}

{ TfmMain }

uses CreateDb, ViewView, ViewTrigger, ViewSProc, ViewGen, NewTable, NewGen,
     EnterPass, CreateTrigger, EditTable, CallProc, EditDataFullRec, UDFInfo, ViewDomain,
     NewDomain, SysTables, Scriptdb, UserPermissions, BackupRestore, UnitFirebirdServices, CreateUser, ChangePass,
     PermissionManage, CopyTable, About, NewEditField, dbInfo, Comparison;

{ TPageControl }

procedure TPageControl.TabDestruction(aSender :TObject);
begin
  raise ETBNotImplemented.Create('');
end;

procedure TPageControl.SetOnTabClose(aValue :TOnCloseEvent);
begin
  if FOnTabClose=aValue then Exit;
  FOnTabClose:=aValue;
end;

procedure TPageControl.MouseUp(Button :TMouseButton; Shift :TShiftState; X, Y :Integer);
var
  vIdx:integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbMiddle then begin
    vIdx := TabIndexAtClientPos(Point(X, Y));
    if vIdx > -1 then Self.Pages[vIdx].Free;// CloseTab(vIdx);
  end;
end;

{ TPageControl }

procedure TfmMain.FormCreate(Sender: TObject);
begin
  {$IFDEF DEBUG}
  // Do not log to debug server if built as release instead of debug
  SetDebuggingEnabled(false);
  {$ENDIF}
  Application.OnException:= @GlobalException;
  FActivated := False;
  LoadRegisteredDatabases;
  //utbConfig.IniLoadData('Editor Font', editorFontDialog.Font);
  StatusBar1.Panels[0].Text:= 'TurboBird for ' + Target + '-' + Arch;
  FCurrentHistoryFile := '';
  {$IFNDEF DEBUG}
  mniDummy.Free;
  {$ENDIF}
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  // Clean up objects in registered database records
  try
    ReleaseRegisteredDatabases;
  except
    // Ignore exceptions/errors; just close
  end;
end;

(*****************  Add New user  ***********************)

procedure TfmMain.lmAddUserClick(Sender: TObject);
var
  //SelNode: TTreeNode;
  dbIndex: Integer;
  //vQry     : TMDOQuery;
  //vUserFrm : TfmCreateUser;
begin
  with TfmCreateUser.Create(nil) do //JKOZ:Create and destroy the form as needed do not keep it always on.
  try
    try
      //SelNode:= tvMain.Selected;
      dbIndex := self.GetDBIndex(tvMain.Selected); //JKOZ:Removed direct access to database node. More freedom to change, lost some speed.
      Init(RegisteredDatabases[dbIndex]);
      Clear; //JKOZ: removed direct access to form's controls.
      if ShowModal = mrOK then
      begin
        dmSysTables.Init(RegisteredDatabases[dbIndex]);
        //dmSysTables.sqQuery.Close;
        //dmSysTables.sqQuery.SQL.Text:= 'create user ' + UserName + ' password ' + QuotedStr(Password);//jkoz: Removed direct access to external controls.
        //dmSysTables.sqQuery.ExecSQL; //JKOZ: replace with a method on the dmSysTables instead of accessing external controls.
        //dmSysTables.ExecuteAction();
        // Grant rule
        dmSysTables.CreateUser(RegisteredDatabases[dbIndex], UserName, Password, Role);
        //////////////if SQLExecute(RegisteredDatabases[dbIndex],'create user ' + UserName + ' password ' + QuotedStr(Password),[]) then begin
        //////////////  if Role<>'' then dmSysTables.GrandRolesToUser(RegisteredDatabases[dbIndex], role, UserName);//(Role) then //cxGrantRole.Checked then begin
        //////////////    //dmSysTables.sqQuery.SQL.Text:= 'grant ' + Role + ' to ' + UserName; //JKOZ Removed direct access to external control.
        //////////////    //dmSysTables.sqQuery.ExecSQL;
        //////////////  end;//JKOZ: replace the check box use with trim(cbRoles.text) <> ''. Extend the mechanism to allow for multiple roles.
        //////////////end;
        //TSQLTransaction(dmSysTables.sqQuery.Transaction).Commit;//JKOZ: remove access to external controls.
        MessageDlg('New user (' + UserName + ') has been created successfully', mtInformation, [mbOk], 0);
        if not cxGrantRole.Checked then
          ShowMessage('User (' + edUserName.Text + ') will not appear in users list unless you grant it a permission');
        lmRefreshClick(nil);
      end;
    except
      on E: Exception do begin
        MessageDlg('Error while creating new user: ' + e.Message, mtError, [mbOk], 0);
      end;
    end;
  finally
    Free;
  end;
end;

(***********  Backup / Restore database ************)

procedure TfmMain.lmBackupClick(Sender: TObject);
var
  SelNode: TTreeNode;
  fmBackupRestore : TfmBackupRestore;
begin
  fmBackupRestore := TfmBackupRestore.Create(Nil);
  try
    SelNode:= tvMain.Selected;
    with RegisteredDatabases[PtrInt(tvMain.Selected.Data)].RegRec do
      fmBackupRestore.Init(SelNode.Text, DatabaseName, UserName, Password);
    fmBackupRestore.cbOperation.Enabled:= True;
    fmBackupRestore.ShowModal;
  finally
    fmBackupRestore.Free;
  end;
end;

(**********  change user password  **********)

procedure TfmMain.lmChangePasswordClick(Sender: TObject);
const
  cAlterUser = 'alter user %S password %S';
var
  vQry : TMDOQuery;

begin
  fmChangePass.Caption:= 'Change password for user: ' + tvMain.Selected.Text;
  fmChangePass.edPassword.Clear;
  fmChangePass.edConfirm.Clear;
  if fmChangePass.ShowModal = mrOK then begin
    try
       //dmSysTables.Init(RegisteredDatabases[GetDBIndex(tvMain.Selected)]);//PtrInt(tvMain.Selected.Parent.Parent.Data));
       //dmSysTables.sqQuery.Close;
       //dmSysTables.sqQuery.SQL.Text:= 'alter user ' + tvMain.Selected.Text +
       //  ' password ' + QuotedStr(fmChangePass.edPassword.Text);
       //dmSysTables.sqQuery.ExecSQL;
       //vQry := GetQuery();
       //TSQLTransaction(dmSysTables.sqQuery.Transaction).Commit;
       if SQLExecute(RegisteredDatabases[GetDBIndex(tvMain.Selected)],cAlterUser, [tvMain.Selected.Text,QuotedStr(fmChangePass.Password)]) then
         MessageDlg('Password has been changed', mtInformation, [mbOk], 0);
    except
      on E: Exception do
        ShowMessage('Error while changing password: ' + e.Message);
    end;
  end;
end;

procedure TfmMain.lmCompareClick(Sender: TObject);
var
  dbIndex: Integer;
  Title: string;
  ATab: TTabSheet;
begin
  dbIndex:= PtrInt(tvMain.Selected.Data);

  // Check if password is saved - it may be empty, which can be valid for
  // e.g. embedded databases
  if (RegisteredDatabases[dbIndex].RegRec.SavePassword) or
    ConnectToDBAs(dbIndex) then
  begin
    Title:= RegisteredDatabases[dbIndex].RegRec.Title + ': Database Comparison';
    fmComparison:= TfmComparison(_FindCustomForm(Title, TfmComparison));
    if fmComparison = nil then
    begin
      fmComparison             := TfmComparison.Create(Application);
      ATab                     := NewTab(PageControl1, dbIndex); //TTBTabsheet.Create(Self);
      //ATab.Parent              := PageControl1;
      fmComparison.Parent      := ATab;
      fmComparison.Left        := 0;
      fmComparison.Top         := 0;
      fmComparison.BorderStyle := bsNone;
      fmComparison.Align       := alClient;
      fmComparison.Caption     := Title;
    end
    else
      ATab:= fmComparison.Parent as TTabSheet;

    PageControl1.ActivePage:= ATab;
    //ATab.Tag:= dbIndex;
    ATab.Caption:= Title;
    fmComparison.Init(dbIndex);
    fmComparison.Show;
  end;
end;

procedure TfmMain.lmCopyRolePermissionClick(Sender: TObject);
begin
  lmCopyUserPermissionClick(nil);
end;

procedure TfmMain.lmCopyUserPermissionClick(Sender: TObject);
var
  List: TStringList;
  dbIndex: Integer;
  UserName: string;
  NewUser: string;
begin
  if InputQuery('Permission', 'Please type a User/Role name to copy perissions to', NewUser) then
  begin
    UserName:= tvMain.Selected.Text;
    dbIndex:= PtrInt(tvMain.Selected.Parent.Parent.Data);
    List:= TStringList.Create;
    try
      Scriptdb.ScriptUserAllPermissions(dbIndex, UserName, List, NewUser);
      ShowCompleteQueryWindow(dbIndex, 'Script permissions for : ' + UserName, List.Text);
    finally
      List.Free;
    end;
  end;
end;

procedure TfmMain.lmCopyTableClick(Sender: TObject);
var
  vCpTableFrm : TfmCopyTable;
begin
  vCpTableFrm := TfmCopyTable(FindCustomForm(cCpTblCaption, TfmCopyTable));
  if not Assigned(vCpTableFrm) then vCpTableFrm := TfmCopyTable.Create(Application);
  fmCopyTable.Init(PtrInt(tvMain.Selected.Parent.Parent.Data), tvMain.Selected.Text);
  fmCopyTable.Show;
end;

procedure TfmMain.lmCreateDBClick(Sender: TObject);
begin
  fmCreateDB.edNewDatabase.Text:= tvMain.Selected.Text + ':';
  //mnCreateDBClick(nil);
  actNewDBExecute(Nil);
end;

procedure TfmMain.lmDBInfoClick(Sender: TObject);
var
  ATab: TTabSheet;
  Title: string;
  dbIndex: Integer;
begin
  Title:= 'Database information for: ' + tvMain.Selected.Text;
  dbIndex:= PtrInt(tvMain.Selected.Data);

  fmDBInfo:= FindCustomForm(Title, TfmDBInfo) as TfmDBInfo;

  if fmDBInfo = nil then
  begin
    fmDBInfo := TfmDBInfo.Create(Application);
    ATab     := NewTab(PageControl1, dbIndex); //TTBTabsheet.Create(self);
    ATab.Parent := PageControl1;
    fmDBInfo.Parent := ATab;
    fmDBInfo.Left   := 0;
    fmDBInfo.Top    := 0;
    fmDBInfo.BorderStyle := bsNone;
    fmDBInfo.Align       := alClient;
    Caption              := Title;
  end
  else
    ATab:= fmDBInfo.Parent as TTabSheet;

  PageControl1.ActivePage:= ATab;
  //ATab.Tag:= dbIndex;
  ATab.Caption := Title;
  fmDBInfo.Init(dbIndex);
end;

procedure TfmMain.lmDisconnectClick(Sender: TObject);
var
  dbIndex: Integer;
  i: Integer;
  j: Integer;
  TabSheet: TTabSheet;
  vNode :TTreeNode;
begin
  dbIndex:= PtrInt(tvMain.Selected.Data);
  RegisteredDatabases[dbIndex].Conn.Close;
  //if not RegisteredDatabases[dbIndex].RegRec.SavePassword then RegisteredDatabases[dbIndex].RegRec.Password := '';
  for i:= PageControl1.PageCount - 1 downto 0 do
    if (PageControl1.Pages[i] as TComponent).Tag = dbIndex then
    begin
      TabSheet:= PageControl1.Page[i] as TTabSheet;
      for j:= 0 to TabSheet.ControlCount - 1 do
      if TabSheet.Controls[j] is TForm then
      begin
        (TabSheet.Controls[j] as TForm).Close;
        TabSheet.Free;
        Break;
      end;
    end;
  tvMain.Selected.Collapse(True);
  vNode :=  tvMain.Selected.GetFirstChild;
  while (vNode <> nil) do begin
    vNode.DeleteChildren;
    if Pos('(', vNode.Text) > 0 then vNode.Text := Trim(Copy(vNode.Text,1,Pos('(', vNode.Text)-1));
    vNode := vNode.GetNextSibling;
  end;
end;

procedure TfmMain.lmEditFieldClick(Sender: TObject);
var
  SelNode: TTreeNode;
  dbIndex: Integer;
  FieldName: string;
  FieldType, DefaultValue: string;
  Size, Scale: Integer;
  Description, Characterset, Collation: string;
  NotNull: Boolean;
begin
  SelNode:= tvMain.Selected;
  dbIndex:= PtrInt(SelNode.Parent.Parent.Parent.Data);
  FieldName:= Copy(SelNode.Text, 1, Pos(' ', SelNode.Text) - 1);
  if dmSysTables.GetFieldInfo(dbIndex, SelNode.Parent.Text, FieldName,
    FieldType, Size, Scale, NotNull,
    DefaultValue, Characterset, Collation, Description) then
  begin
    fmNewEditField:= TfmNewEditField.Create(nil);
    fmNewEditField.Init(dbIndex, SelNode.Parent.Text, foEdit,
      FieldName, FieldType,
      CharacterSet, Collation,
      DefaultValue, Description,
      Size, Scale,
      PtrInt(SelNode.Data), not NotNull,
      nil);
    fmNewEditField.Show;
  end
  else
    ShowMessage('Unable to locate the field: ' + SelNode.Text);
end;

procedure TfmMain.lmGetIncrementGenClick(Sender: TObject);
var
  SelNode: TTreeNode;
  AGenName: string;
  dbIndex: Integer;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);

    AGenName:= SelNode.Text;

    ShowCompleteQueryWindow(dbIndex, 'get increment generator SQL for:' + AGenName,
      'select GEN_ID(' + AGenName + ', 1) from RDB$Database;');
  end;
end;

procedure TfmMain.lmImportTableClick(Sender: TObject);
var
  MyImportTable: TfmImportTable;
begin
  MyImportTable:=TfmImportTable.Create(nil);
  try
	  // Pass db index and table name
	  MyImportTable.Init(PtrInt(tvMain.Selected.Parent.Parent.Data),
		  tvMain.Selected.Text);
    MyImportTable.ShowModal;
  finally
    MyImportTable.Free;
  end;
end;

procedure TfmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Length(RegisteredDatabases) > 0 then
    fmReg.SaveRegistrations;
  SaveAndCloseSQLHistory;
end;

procedure TfmMain.FormActivate(Sender: TObject);
begin
  FActivated:= True;
end;

procedure TfmMain.actRegisterDBExecute(Sender :TObject);
var
  vRegDlg :TfmReg;
begin
  vRegDlg := TfmReg.Create(Nil);
  try
    vRegDlg.NewReg:= True;
    vRegDlg.bbReg.Caption:= 'Register';
    if vRegDlg.ShowModal = mrOK then begin
      LoadRegisteredDatabases;
      vRegDlg.SaveRegistrations;
      LoadRegisteredDatabases;
    end;
  finally
    vRegDlg.Free;
  end;
end;

procedure TfmMain.actRestoreDBExecute(Sender :TObject);
var
  vBackupDlg : TfmBackupRestore;
begin
  vBackupDlg := TfmBackupRestore.Create(nil);
  try
    vBackupDlg.Init('', tvMain.Selected.Text +  ':', '', '');
    vBackupDlg.cbOperation.ItemIndex:= 1;
    vBackupDlg.cbOperation.Enabled:= False;
    vBackupDlg.meLog.Clear;
    vBackupDlg.ShowModal;
  finally
    vBackupDlg.Free;
  end;
end;

procedure TfmMain.actNewDBExecute(Sender :TObject);
var
  fmCreateDB : TfmCreateDB;
begin
  fmCreateDB := TfmCreateDB.Create(Nil);
  try
    if fmCreateDB.ShowModal = mrOk then
      LoadRegisteredDatabases;
  finally
    fmCreateDB.Free;
  end;
end;

procedure TfmMain.actQueryExecute(Sender :TObject);
var
  vType : TObjectType;
begin
  vType := GetNodeObjectType(tvMain.Selected);
  case vType of
    otTables: lmDisplay1000VClick(Nil);
    otGenerators: ;
    otTriggers: ;
    otViews: ;
    otStoredProcedures: ;
    otUDFs: ;
    otDomains: ;
    otSystemTables: ;
    otRoles: ;
    otExceptions: ;
    otUsers: ;
    otIndexes: ;
    otConstraints: ;
  end; ;
end;

procedure TfmMain.actRefreshDatabaseExecute(Sender :TObject);
begin
  if tvMain.Selected.Expanded then
    tvMain.Selected.Collapse(False);
  tvMainExpanded(nil, tvMain.Selected)
end;

procedure TfmMain.actRefreshExecute(Sender :TObject);
begin
  //??jkoz: did I deleted this?

end;

procedure TfmMain.actExitExecute(Sender :TObject);
begin
  Close;
end;

procedure TfmMain.actFontEditorExecute(Sender :TObject);
begin
  IniLoadData(cQuerySection, editorFontDialog.Font); //make sure the end user see the current selection.
  if editorFontDialog.Execute then begin
    IniSaveData(cQuerySection, editorFontDialog.Font);
    ApplyEditorFont(editorFontDialog.Font);
  end;
end;
                      //C:\Users\jkoz\AppData\Local\Evosi\TurboBird\
procedure TfmMain.actAboutExecute(Sender :TObject);
begin
  //fmAbout:= TfmAbout.Create(nil);
  with TfmAbout.Create(Nil) do try
    Init;
    ShowModal;
  finally
    Free;
  end;
end;

(***************  Open System table  **************)

procedure TfmMain.lmOpenSystemTableClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Parent.Data), SelNode.Text);
    QWindow.meQuery.Lines.Text:= 'select * from ' + SelNode.Text;
    QWindow.bbRunClick(nil);
    QWindow.Show;
  end;
end;

procedure TfmMain.lmActivateTrigClick(Sender: TObject);
var
  SelNode: TTreeNode;
begin
  SelNode:= tvMain.Selected;
  if ChangeTriggerActivity(PtrInt(SelNode.Parent.Parent.Data), SelNode.Text, True) then
    MessageDlg('Trigger has been activated', mtInformation, [mbOk], 0);
end;


(*******************  Call stored procedure  *****************)

procedure TfmMain.lmCallStoreProcClick(Sender: TObject);
var
  SelNode: TTreeNode;
  Body: string;
  AProcName: string;
  SPOwner: string;
  Params: string;
  OneParam: string;
  i: Integer;
  QWindow: TfmQueryWindow;
  Line: string;
  Called: Boolean;
  WithParams: Boolean;
begin
  SelNode:= tvMain.Selected;

  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    AProcName:= SelNode.Text;
    Body:= GetStoredProcBody(PtrInt(SelNode.Parent.Parent.Data), AProcName, SPOwner);
    Params:= RetrieveInputParamFromSP(Body);
    withParams:= Params <> '';
    with fmCallProc do
    begin
      StringGrid1.RowCount:= 1;
      if WithParams then
        Params:= Params + ',';
      i:= 1;
      if WithParams then
      while Params <> '' do
      begin
        OneParam:= Copy(Params, 1, Pos(',', Params) - 1);
        Delete(Params, 1, Pos(',', Params));
        Params:= Trim(Params);

        StringGrid1.RowCount:= i + 1;

        StringGrid1.Cells[1, i]:= Trim(Copy(OneParam, 1, Pos(' ', OneParam)));
        StringGrid1.Cells[2, i]:= Trim(Copy(OneParam, Pos(' ', OneParam), Length(OneParam)));

        Inc(i);
      end;

      Caption:= 'Call stored procedure: ' + AProcName;

      if WithParams then
        Called:= ShowModal = mrOK;  // View parameters form

      if (Called) or (not WithParams) then
      begin
        QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Parent.Data), 'Call procedure: ' + AProcName);
        QWindow.meQuery.lines.Clear;
        if Pos('suspend', LowerCase(Body)) > 0 then
          Line:= 'select * from ' + AProcName
        else
          Line:= 'execute procedure ' + AProcName;

        if WithParams then
          Line:= Line + '(';

        for i:= 1 to StringGrid1.RowCount - 1 do
          if Pos('CHAR', StringGrid1.Cells[2, i]) > 0 then
            Line:= Line + QuotedStr(StringGrid1.Cells[0, i]) + ', '
          else
            Line:= Line + StringGrid1.Cells[0, i] + ', ';
        if WithParams then
        begin
          Delete(Line, Length(Line) - 1, 2);
          Line:= Line + ')';
        end;
        Line:= Line + ';';
        QWindow.meQuery.Lines.Add(Line);
        QWindow.Show;

      end;
    end;
  end;
end;

(****************  Connect As  *****************)

procedure TfmMain.lmConnectAsClick(Sender: TObject);
begin
  if ConnectToDBAs(PtrInt(tvMain.Selected.Data), True) then
    tvMain.Selected.Expand(False)
  else
    tvMain.Selected.Collapse(False);
end;

function TfmMain.ConnectToDBAs(dbIndex: Integer; ForceConnectDialog: boolean=false): Boolean;
var
  Rec: TDBDetails;
  Count: Integer;
  vPasswordForm : TfmEnterPass;
begin
  Result:= False;
  Rec   := RegisteredDatabases[dbIndex].RegRec;
  vPasswordForm := TfmEnterPass.Create(Nil);
  try
    //vPasswordForm.DatabaseRec := @RegisteredDatabases[dbIndex];
    //vPasswordForm.DBCaption := Rec.Title;
    //vPasswordForm.UserName  := Rec.UserName;
    //vPasswordForm.Password := '';
    //vPasswordForm.Role := '';
    if vPasswordForm.Execute(@RegisteredDatabases[dbIndex],Rec.UserName,'',rec.Role) = mrOK then //the data are alrady passed in the 1st parameter
    begin
      RegisteredDatabases[dbIndex].RegRec.UserName := vPasswordForm.UserName;
      RegisteredDatabases[dbIndex].RegRec.Password := vPasswordForm.Password;
      RegisteredDatabases[dbIndex].RegRec.Role     := vPasswordForm.Role;
      Connect(RegisteredDatabases[dbIndex].Conn, RegisteredDatabases[dbIndex].RegRec);
      Result:= True;
    end;//no the database registration is not to be changed by the connect as dialog connect as gives us a way to emulate a different user if needed only.
    //JKOZ: Moved the relevant parts to the password form and everything else is removed.
    // Use may have saved an empty password, which is valid for embedded dbs
    // So check SavePassword instead of Password itself.
    //if (ForceConnectDialog=false) and Rec.SavePassword then
    //try
    //  vPasswordForm.cbRole.Items.CommaText:= dmSysTables.GetDBObjectNames(fmMain.RegisteredDatabases[dbIndex], otRoles, Count);
    //  //vPasswordForm.cbRole.ItemIndex:= -1;
    //  vPasswordForm.cbRole.Text:= '';
    //  Result:= True; //this works, no need to go through a retry attempt below
    //except
    //  // We don't particularly care which error occurred; we're trying again below.
    //  Result:= False;
    //end;
    //// Only show form if Connect failed before
    //if (ForceConnectDialog or (Result=false)) and
    //  (vPasswordForm.ShowModal = mrOk) then
    //begin
    //  //testing and retries moved to the connect dialog instead.
    //  //if fmReg.TestConnection(Rec.DatabaseName, vPasswordForm.edUser.Text, vPasswordForm.edPassword.Text,
    //  //  Rec.Charset) then
    //  //begin
    //    RegisteredDatabases[dbIndex].RegRec.UserName := vPasswordForm.edUser.Text;
    //    RegisteredDatabases[dbIndex].RegRec.Password := vPasswordForm.edPassword.Text;
    //    RegisteredDatabases[dbIndex].RegRec.Role     := vPasswordForm.cbRole.Text;
    //    Result:= True;
    //  //end;
    //end;
  finally
    vPasswordForm.Free;
  end;
end;

function TfmMain.GetNodeObjectType(const aNode :TTreenode) :uTBTypes.TObjectType;
var
  vNode :TTreeNode;
  vCntr :TObjectType;
  function isChildNode(const avNode:TTreeNode) :boolean;INLINE;
  begin
    Result := False;
    if Assigned(avNode) then Result := avNode.Level>2; //0 is the server eg localhost, 1 is the database eg contacts, 2 is the object group eg tables 3 is the table name and 4 is the fild name or the childrent in the table.
  end;
begin
  vNode:=aNode;
  Result := otUnknown;
  while isChildNode(vNode) do vNode:=vNode.Parent;
  if Assigned(vNode) then begin
    if assigned(vNode.Data) then result := TObjectType(PtrInt(vNode.Data)) else begin
      for vCntr := Low(TObjectType) to High(TObjectType) do begin
        if vNode.Text = dbObjectsEN[vCntr] then begin
          Result := vCntr;
          Break;
        end;
      end;
    end;
  end;
end;

procedure TfmMain.ApplyEditorFont(const aFont :TFont);
var
  vForm :TForm;
begin
  for vForm in Screen.FormByClass(TfmQueryWindow) do
    TfmQueryWindow(vForm).ApplyFont(aFont);
end;

(****************  Fill and show constraints form ************************)

procedure TfmMain.FillAndShowConstraintsForm(Form: TfmTableManage; ATableName: string; dbIndex: Integer);
begin
  dmSysTables.Init(dbIndex);
  dmSysTables.GetTableConstraints(ATableName, Form.qryMain);
  Form.FillConstraints(dbIndex);
end;

(***********  Show and Fill Query Window *****************)

procedure TfmMain.ShowCompleteQueryWindow(DatabaseIndex :Integer; const ATitle :String; AQueryText :string; const OnCommitProcedure :TNotifyEvent);
var
  vQWindow : TfmQueryWindow;
  vPart     : string;
begin
  vQWindow := ShowQueryWindow(DatabaseIndex, ATitle);
  vQWindow.meQuery.ClearAll;
  vQWindow.OnCommit := OnCommitProcedure;
  vQWindow.meQuery.Lines.Text := AQueryText;
  //JKOZ: why? lines.text will break on line endings why do it here as well?
  repeat
    if Pos(LineEnding, AQueryText) > 0 then
      vPart := Copy(AQueryText, 1, Pos(LineEnding, AQueryText))
    else
      vPart:= AQueryText;
    Delete(AQueryText, 1, Length(vPart));
    vPart:= StringReplace(vPart, LineEnding, ' ', [rfReplaceAll]);

    vQWindow.meQuery.Lines.Add(vPart);
  until AQueryText = '';

end;

procedure TfmMain.ShowCompleteQueryWindow(const aDatabase :PDBInfo; const ATitle, AQueryText :string; const OnCommitProcedure :TNotifyEvent);
var
  vQWindow : TfmQueryWindow;
  //vPart     : string;
begin
  vQWindow := ShowQueryWindow(aDatabase, ATitle);
  vQWindow.meQuery.ClearAll;
  vQWindow.OnCommit := OnCommitProcedure;
  vQWindow.meQuery.Lines.Text := AQueryText;
  //JKOZ: why? lines.text will break on line endings why do it here as well?
  //repeat
  //  if Pos(LineEnding, AQueryText) > 0 then
  //    vPart := Copy(AQueryText, 1, Pos(LineEnding, AQueryText))
  //  else
  //    vPart:= AQueryText;
  //  Delete(AQueryText, 1, Length(vPart));
  //  vPart:= StringReplace(vPart, LineEnding, ' ', [rfReplaceAll]);
  //
  //  vQWindow.meQuery.Lines.Add(vPart);
  //until AQueryText = '';
end;

(***********************  Constraint Management  ********************)


(**********  Create Auto Increment Trigger from current generator  **********)

procedure TfmMain.lmCreateAutoIncClick(Sender: TObject);
var
  SelNode: TTreeNode;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    InitNewGen(PtrInt(SelNode.Parent.Parent.Data));
    fmNewGen.edGenName.Text:= SelNode.Text;
    fmNewGen.edGenName.Enabled:= False;
    fmNewGen.cxTrigger.Checked:= True;
    fmNewGen.ShowModal;
  end;
end;

(****************  Create new stored proc  *******************)

procedure TfmMain.lmCreateStoredProcClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
  AProcName: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  if InputQuery('Create new stored procedure', 'Please enter new procedure name', AProcName) then
  begin
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Data), 'Create new stored procedure');
    QWindow.meQuery.Lines.Clear;
 //   QWindow.meQuery.Lines.Add('SET TERM ^;');
    QWindow.meQuery.Lines.Add('CREATE PROCEDURE ' + AProcName);
    QWindow.meQuery.Lines.Add('-- Input parameters, you can modify,remove them');

    QWindow.meQuery.Lines.Add('( Input1 int, -- You can replace it by your first parameter');
    QWindow.meQuery.Lines.Add(' Input2 varchar(20) -- you can replace it by your second parameter');
    QWindow.meQuery.Lines.Add(')');
    QWindow.meQuery.Lines.Add('RETURNS');
    QWindow.meQuery.Lines.Add('( Out1 int -- You can replace it by your first parameter');
    QWindow.meQuery.Lines.Add(')');
    QWindow.meQuery.Lines.Add('AS');
    QWindow.meQuery.Lines.Add('BEGIN');
    QWindow.meQuery.Lines.Add('  -- Write your procedure code here');
    QWindow.meQuery.Lines.Add('END;');
   // QWindow.meQuery.Lines.Add('SET TERM ;^');
    QWindow.Show;
  end;
end;

(***************  Create new Trigger  ****************)

function TfmMain.CreateNewTrigger(dbIndex: Integer; ATableName: string; OnCommitProcedure: TNotifyEvent = nil): Boolean;
var
  QWindow: TfmQueryWindow;
  TrigType: string;
begin
  Result:= False;
  if ATableName <> '' then
  begin
    fmCreateTrigger.cbTables.Clear;
    fmCreateTrigger.cbTables.Items.Add(ATableName);
    fmCreateTrigger.cbTables.ItemIndex:= 0;
  end;
  fmCreateTrigger.edTriggerName.Clear;
  fmCreateTrigger.cxUpdate.Checked:= False;
  fmCreateTrigger.cxInsert.Checked:= False;
  fmCreateTrigger.cxDelete.Checked:= False;

  if fmCreateTrigger.ShowModal = mrOK then
  begin
    Result:= True;
    QWindow:= ShowQueryWindow(dbIndex, 'Create new Trigger');
    if fmCreateTrigger.rbAfter.Checked then
      TrigType:= 'After'
    else
      TrigType:= 'Before';
    if fmCreateTrigger.cxInsert.Checked then
      TrigType:= TrigType + ' insert or';
    if fmCreateTrigger.cxUpdate.Checked then
      TrigType:= TrigType + ' update or';
    if fmCreateTrigger.cxDelete.Checked then
      TrigType:= TrigType + ' delete or';
    Delete(TrigType, Length(TrigType) - 2, 3);

    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('CREATE TRIGGER ' + fmCreateTrigger.edTriggerName.Text + ' for ' +
      fmCreateTrigger.cbTables.Text);
    QWindow.meQuery.Lines.Add('Active');
    QWindow.meQuery.Lines.Add(TrigType);
    QWindow.meQuery.Lines.Add('Position 0');
    QWindow.meQuery.Lines.Add('AS');
    QWindow.meQuery.Lines.Add('BEGIN');
    QWindow.meQuery.Lines.Add(' -- Your code here');
    QWindow.meQuery.Lines.Add(' -- New.FieldName = YourData;');
    QWindow.meQuery.Lines.Add('END;');
    fmMain.Show;

    if OnCommitProcedure <> nil then
      QWindow.OnCommit:= OnCommitProcedure;
  end;
end;

(*******  Create Trigger click  ********)

procedure TfmMain.lmCreateTriggerClick(Sender: TObject);
var
  SelNode: TTreeNode;
  DBIndex: Integer;
  TableNames: string;
  Count: Integer;
begin
  SelNode:= tvMain.Selected;
  DBIndex:= PtrInt(SelNode.Parent.Data);

  TableNames:= dmSysTables.GetDBObjectNames(fmMain.RegisteredDatabases[DBIndex], otTables, Count);
  fmCreateTrigger.cbTables.Items.CommaText:= TableNames;
  CreateNewTrigger(DBIndex, '');
end;

(******************  Create New View   ***************)

procedure TfmMain.lmCreateViewClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
  AViewName: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  if InputQuery('Create new view', 'Please enter new view name', AViewName) then
  begin
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Data), 'Create new view');
    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('CREATE VIEW "' + AViewName + '" (');
    QWindow.meQuery.Lines.Add('Field1Name, Field2Name) ');
    QWindow.meQuery.Lines.Add('AS');
    QWindow.meQuery.Lines.Add('SELECT Field1, Field2 FROM ATableName');
    QWindow.meQuery.Lines.Add('-- WHERE condition');
    QWindow.Show;
  end;
end;

procedure TfmMain.lmDeactiveTrigClick(Sender: TObject);
var
  SelNode: TTreeNode;
begin
  SelNode:= tvMain.Selected;
  if ChangeTriggerActivity(PtrInt(SelNode.Parent.Parent.Data), SelNode.Text, False) then
    MessageDlg('Trigger has been DeActivated', mtInformation, [mbOk], 0);
end;

(***************  Display view top 1000 records  ************)

procedure TfmMain.lmDisplay1000VClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    QWindow := ShowQueryWindow( GetDBIndex(SelNode) {PtrInt(SelNode.Parent.Parent.Data)},  'Select first 1000 from ' + SelNode.Text);
    QWindow.meQuery.Lines.Text:= 'select first 1000 * from "' + SelNode.Text + '"';
    QWindow.bbRunClick(nil);
    QWindow.Show;
  end;
end;

(**********  Drop Exception ********)

procedure TfmMain.lmDropExceptionClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
begin
  SelNode:= tvMain.Selected;
  if MessageDlg('Are you sure you want to delete ' + SelNode.Text + ' permanently', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Parent.Data), 'Drop Exception');
    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('DROP EXCEPTION ' + SelNode.Text + ';');
    QWindow.Show;
  end;
end;

(***********  Edit Data in a form  *****************)

procedure TfmMain.lmEditDataFormClick(Sender: TObject);
var
  SelNode: TTreeNode;
  Rec: TDBInfo;
  EditForm: TfmEditDataFullRec;
  ATableName: string;
  dbIndex: Integer;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
    ATableName:= SelNode.Text;
    Rec:= RegisteredDatabases[dbIndex];
    EditForm:= TfmEditDataFullRec(FindCustomForm(Rec.RegRec.Title + ': Edit Data (Form) for Table : ' +
      ATableName, TfmEditDataFullRec));
    if EditForm = nil then
    begin
      EditForm:= TfmEditDataFullRec.Create(Application);
      EditForm.Init(dbIndex, ATableName);
      EditForm.Caption:= Rec.RegRec.Title + ': Edit Data (Form) for Table : ' + ATableName;
    end;
    EditForm.Show;
  end;
end;

(***************  Edit stored procedure  *****************)

procedure TfmMain.lmEditProcClick(Sender: TObject);
var
  SelNode: TTreeNode;
  AProcName: string;
  SPOwner: string;
  spBody: string;
  QWindow: TfmQueryWindow;
  DBIndex: Integer;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    AProcName:= SelNode.Text;
    DBIndex:= PtrInt(SelNode.Parent.Parent.Data);
    SPBody:= GetStoredProcBody(DBIndex, AProcName, SPOwner);

    // Procedure body
    QWindow:= ShowQueryWindow(DBIndex, 'Edit stored procedure ' + AProcName);
    QWindow.meQuery.Lines.Clear;
  //  QWindow.meQuery.Lines.Add('SET TERM ^ ;');
    QWindow.meQuery.Lines.Add('ALTER PROCEDURE ' + AProcName);
    QWindow.meQuery.Text:= QWindow.meQuery.Text + Trim(spBody) + ';';
   // QWindow.meQuery.Lines.Add('SET TERM ; ^');

    QWindow.Show;
  end;
end;

(**********************  Edit Table data  ***************************)


procedure TfmMain.lmEditTableClick(Sender: TObject);
var
  SelNode: TTreeNode;
  Rec: TDBInfo;
  EditWindow: TfmEditTable;
  ATableName: string;
  dbIndex: Integer;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    ATableName:= SelNode.Text;
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
    Rec:= RegisteredDatabases[dbIndex];
    EditWindow:= TfmEditTable(FindCustomForm(Rec.RegRec.Title + ': Edit Data for Table : ' + ATableName, TfmEditTable));
    if EditWindow = nil then
    begin
      EditWindow:= TfmEditTable.Create(Application);
      EditWindow.Rec:= Rec;
      EditWindow.Caption:= EditWindow.Rec.RegRec.Title + ': Edit Data for Table : ' + ATableName;

      EditWindow.Init(dbIndex, ATableName);
    end;
    EditWindow.Show;
  end;
end;

(****************  Edit Trigger  ******************)

procedure TfmMain.lmEditTriggerClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
  ATriggerName: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    ATriggerName:= SelNode.Text;
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Parent.Data), 'Edit Trigger ' + ATriggerName);

    QWindow.meQuery.Lines.Clear;
    dmSysTables.ScriptTrigger(PtrInt(SelNode.Parent.Parent.Data), ATriggerName, QWindow.meQuery.Lines);
    QWindow.Show;
  end;

end;

(********************  Edit View  ********************)

procedure TfmMain.lmEditViewClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
  AViewName: string;
  ViewBody, Columns: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    AViewName:= SelNode.Text;
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Parent.Data), 'Edit view ' + AViewName);

    GetViewInfo(PtrInt(SelNode.Parent.Parent.Data), AViewName, Columns, ViewBody);
    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('DROP VIEW "' + AViewName + '";');
    QWindow.meQuery.Lines.Add('');
    QWindow.meQuery.Lines.Add('CREATE VIEW "' + AViewName + '" (' + Columns + ')');
    QWindow.meQuery.Lines.Add('AS');

    QWindow.meQuery.Text:= QWindow.meQuery.Text + ViewBody;
    QWindow.Show;
  end;

end;

(***********  Show Indices Management  **************)

procedure TfmMain.ShowIndicesManagement(AForm: TForm; DatabaseIndex: Integer; ATableName: string);
var
  //AQuery: TSQLQuery;
  AQuery: TMDOQuery;
  i: Integer;
  IndexFields: string;
  Rec: TDBInfo;
  CurrentRow: Integer;
  FieldsList: TStringList;
  ConstraintName: string;
  Form: TfmTableManage;
begin
  Form:= AForm as TfmTableManage;
  Rec:= RegisteredDatabases[DatabaseIndex];
  AQuery:= TMDOQuery.Create(nil);
  try
    AQuery.Close;

    if FConn <> RegisteredDatabases[DatabaseIndex].Conn then
    begin
      FConn:= RegisteredDatabases[DatabaseIndex].Conn;
      FTrans:= RegisteredDatabases[DatabaseIndex].Trans;
    end;
    AQuery.DataBase:= FConn;
    FTrans.Commit;

    Form.sgIndices.RowCount:= 1;

    // Get primary key index name
    Form.PKeyName:= GetPrimaryKeyIndexName(DatabaseIndex, ATableName, ConstraintName);
    Form.ConstraintName:= ConstraintName;

    // Index names
    if GetIndices(ATableName, AQuery) then
    with Form do
    while not AQuery.EOF do
    begin
      if Trim(AQuery.FieldByName('RDB$Index_name').AsString) = PKeyName then
      begin
        sgIndices.InsertColRow(False, 1);
        CurrentRow:= 1;
      end
      else
      begin
        sgIndices.RowCount:= sgIndices.RowCount + 1;
        CurrentRow:= sgIndices.RowCount - 1;
      end;
      sgIndices.Cells[0, CurrentRow]:= Trim(AQuery.FieldByName('RDB$Index_Name').AsString);
      if AQuery.FieldByName('RDB$Unique_Flag').AsString = '1' then
        sgIndices.Cells[1, CurrentRow]:= '1'
      else
        sgIndices.Cells[1, CurrentRow]:= '0';

      if AQuery.FieldByName('RDB$Index_Type').AsString = '1' then
        sgIndices.Cells[2, CurrentRow]:= 'Desc'
      else
        sgIndices.Cells[2, CurrentRow]:= 'Asc';

      if Trim(AQuery.FieldByName('RDB$Index_Name').AsString) = Form.PKeyName then
        sgIndices.Cells[4, CurrentRow]:= '1'
      else
        sgIndices.Cells[4, CurrentRow]:= '0';
      AQuery.Next;
    end;

    FieldsList:= TStringList.Create;
    try
      // Index fields
      with Form do
      for i:= 1 to sgIndices.RowCount - 1 do
      begin
        IndexFields:= '';
        if GetIndexFields(ATableName, sgIndices.Cells[0, i], AQuery, FieldsList) then
        begin
          IndexFields:= FieldsList.CommaText;
          sgIndices.Cells[3, i]:= IndexFields;
        end;
      end;
    finally
      FieldsList.Free;
    end;

    Form.edIndexName.Text:= 'IX_' + ATableName + '_' + IntToStr(Form.sgIndices.RowCount);

    // Field names
    Get_Fields(DatabaseIndex, ATableName, nil);
    with Form, Self.qryMain do
    begin
      clbFields.Clear;
      while not EOF do
      begin
        // Allow creating indexes on any field except blobs
        if (FieldByName('field_type_int').AsInteger <> BlobType) then
          clbFields.Items.Add(FieldByName('Field_Name').AsString);
        Next;
      end;
      Self.qryMain.Close;
    end;
    AQuery.Close;
  finally
    AQuery.Free;
  end;

  if Form.sgIndices.RowCount > 1 then
    Form.sgIndices.Row:= 1;
end;

(**************  New Domain  *************)

procedure TfmMain.lmNewDomainClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
  Line: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  if fmNewDomain.ShowModal = mrOk then
  with QWindow do
  begin
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Data), 'Create new domain');
    meQuery.Lines.Clear;
    Line:= 'CREATE DOMAIN ' + fmNewDomain.edName.Text + ' AS ' + fmNewDomain.cbType.Text;
    if Pos('char', LowerCase(fmNewDomain.cbType.Text)) > 0 then
      Line:= Line + '(' + IntToStr(fmNewDomain.seSize.Value) + ')';
    meQuery.Lines.Add(Line);

    if Trim(fmNewDomain.edDefault.Text) <> '' then
    begin
      if (Pos('char', LowerCase(fmNewDomain.cbType.Text)) > 0) or
        (LowerCase(fmNewDomain.cbType.Text)='cstring') then
        meQuery.Lines.Add('DEFAULT ' + QuotedStr(fmNewDomain.edDefault.Text))
      else
        meQuery.Lines.Add('DEFAULT ' + fmNewDomain.edDefault.Text);
    end;
    Show;
  end;
end;

(***********  Add New exception  ****************)

procedure TfmMain.lmNewExceptionClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Data), 'Create new Exception');
    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('CREATE EXCEPTION Exception_name_1 ''exception message'';');
    QWindow.Show;
  end;
end;


(**************  Initialize New Generator form  *************)

procedure TfmMain.InitNewGen(DatabaseIndex: Integer);
var
  Rec: TDBInfo;
begin
  Rec:= RegisteredDatabases[DatabaseIndex];

  fmNewGen.Init(DatabaseIndex);
end;

(*  Get server name from database string  *)

function TfmMain.GetServerName(DBName: string): string;
begin
  if Pos(':', DBName) > 2 then
    Result:= Copy(DBName, 1, Pos(':', DBName) - 1)
  else
    Result:= 'localhost';
end;


(* Search and get server node in tree view *)

function TfmMain.GetServerNameNode(ServerName: string): TTreeNode;
var
  Node: TTreeNode;
begin
  Node:= nil;
  ServerName:= LowerCase(ServerName);
  if tvMain.Items.Count > 0 then
    Node:= tvMain.Items[0];
  Result:= nil;
  while Node <> nil do
  begin
    if (Node.Text <> '') and (LowerCase(Node.Text) = ServerName) then
    begin
      Result:= Node;
      Break;
    end;
    Node:= Node.GetNextSibling;
  end;
end;

procedure TfmMain.ReleaseRegisteredDatabases;
var
  vCntr: Integer;
begin
  for vCntr:= 0 to High(RegisteredDatabases) do begin
    RegisteredDatabases[vCntr].Conn.Close;
    RegisteredDatabases[vCntr].Trans.Free;
    RegisteredDatabases[vCntr].Conn.Free;
  end;
  SetLength(RegisteredDatabases, 0);
  RegisteredDatabases:= nil;
end;

procedure TfmMain.SetConnection(Index: Integer);
begin
  SetConnection(RegisteredDatabases[Index]);
end;

procedure TfmMain.SetConnection(aDB :TDBInfo);
begin
  if (FConn <> aDB.Conn) then begin
    FConn := aDB.Conn;
    // This used to say FConn.Close which will simply also close all open
    // queries - not a good idea
    // FConn.Close;
    FTrans           := aDB.Trans;
    FConn.DefaultTransaction  := FTrans;
    qryMain.Database          := FConn;
    qryMain.Transaction       := FTrans;
  end;
end;

procedure TfmMain.SetFocus;
begin
  if not FActivated then //1?
    inherited SetFocus;
end;

function TfmMain.IsQueryNode(constref aNode :TTreeNode) :Boolean;
begin
  Result := PtrInt(aNode.Data) = -1;
end;

procedure TfmMain.GetLogEvent(Sender :TSQLConnection; EventType :TDBEventType; Const Msg :String);
// Used to log everything sent through the Connect
var
  Source: string;
begin
  case EventType of
    detCustom:   Source:='Custom:   ';
    detPrepare:  Source:='Prepare:  ';
    detExecute:  Source:='Execute:  ';
    detFetch:    Source:='Fetch:    ';
    detCommit:   Source:='Commit:   ';
    detRollBack: Source:='Rollback: ';
    else         Source:='Unknown event. Please fix program code.';
  end;
  {$IFDEF USEDEBUGLOG}
  try
    SendDebug(Source + Msg);
  except
    // Ignore errors (e.g. debug server not active)
    on e:Exception do begin
      ShowException(E, ExceptAddr);
    end;
  end;
  {$ELSE}
  //use some other logging mechanism
  {$ENDIF}
end;

function TfmMain.GetDBNode(aStart :TTreeNode) :TTreenode;
begin
  Result := aStart;
  if tvMain.Selected.Level > 1 then begin
    while Result.Level > 1 do
      if Assigned(Result) then Result := Result.Parent;
  end;
  if (Result.Level <> 1) then Result := nil;
end;

function TfmMain.IsDBNode(Const aNode :TTreeNode) :Boolean;
begin
  //JKOZ : for now this will do, refactor it for the node's data property to be used for ID
  Result := aNode.Level = 1; //assigned(aNode.Parent) and (not assigned(aNode.Parent.Parent));
end;

function TfmMain.GetDBIndex(const aNode :TTreeNode) :Integer;
var
  vNode :TTreeNode;
begin
  Result := -1; //invalid dbindex
  vNode := GetDBNode(aNode);
  if Assigned(vNode) then Result := PtrInt(vNode.Data);
end;

function TfmMain.GetDBIndex(const aDB :TDBInfo) :Integer;
var
  vCntr :Integer;
begin
  for vCntr := Low(RegisteredDatabases) to High(RegisteredDatabases) do begin
    if (RegisteredDatabases[vCntr].Conn = aDB.Conn) and (RegisteredDatabases[vCntr].Trans = aDB.Trans) and
       (RegisteredDatabases[VCntr].Index = aDB.Index) then begin
      Exit(vCntr);
    end;
  end;
end;

function TfmMain.GetTableName(const aNode :TTreeNode) :string;
begin
  Result := '';
end;

Function TfmMain.NewTab(const aParent :TWinControl; aIndex :Integer) :TTabSheet;
begin
  //support for custom tabsheet. Allows us to auto select
  //the next active tabsheet even if its tab is not visible.
  Result        := TTBTabsheet.Create(Self);
  Result.Parent := aParent;
  Result.Tag    := aIndex;
end;

//Function TfmMain.NewTab(const aParent :TWinControl; aIndex :Integer; aTitle :String) :TWinControl;
//begin
//  //Result        := TKTabSheet.Create(Self);
//  ////Result.Parent := aParent;
//  //Result.Tag    := aIndex;
//  //if aParent is TKPageControl then TKTabSheet(Result).PageControl := TKPageControl(aParent);//.insertpage;
//end;


(* Insert SQL query into database history file *)

function TfmMain.AddToSQLHistory(DatabaseTitle :string; SQLType, SQLStatement :String) :Boolean;
begin
  try
    Result:= OpenSQLHistory(DatabaseTitle);
    if Result then
    begin
      mdsHistory.Last;
      if (SQLType <> 'SELECT') or (mdsHistory.FieldByName('SQLStatement').AsString <> SQLStatement) then
      begin
        mdsHistory.AppendRecord([Now, SQLType, SQLStatement, 0]);
        if SQLType = 'DDL' then
          mdsHistory.SaveToFile(FCurrentHistoryFile);
      end;
    end;
  except
    on E: Exception do
    begin
      Result:= False;
      ShowMessage(e.Message);
    end;
  end;
end;

function TfmMain.SaveAndCloseSQLHistory: Boolean;
begin
  try
    if mdsHistory.Active then
      mdsHistory.SaveToFile(FCurrentHistoryFile);

    mdsHistory.Close;
    Result:= True;

  except
    on E: Exception do
    begin
      Result:= False;
      ShowMessage(e.Message)
    end;
  end;
end;


(* Open SQL history file for current database *)

function TfmMain.OpenSQLHistory(DatabaseTitle: string): Boolean;
var
  AFileName :string;
  i         :Integer;

  // Removes spaces, braces, brackets etc
  function RemoveSpecialChars(AText: string): string;
  var
    i: Integer;
  begin
    for i:= Length(AText) to 1 do
      if Pos(AText[i], ' !@#$%^&*()[]{}/?<>:;"|\,.~`''') > 0 then
        System.Delete(AText, i, 1);
    Result:= AText;
  end;

begin
  try
    AFileName := getConfigurationDirectory + LowerCase(RemoveSpecialChars(DatabaseTitle)) + '.history';

    // Different opened history file
    if mdsHistory.Active and (AFileName <> FCurrentHistoryFile) then begin
      if FCurrentHistoryFile <> '' then
        mdsHistory.SaveToFile(FCurrentHistoryFile);
       mdsHistory.Close;
    end;

    if not mdsHistory.Active then
      if FileExists(AFileName) then begin
        try
          mdsHistory.LoadFromFile(AFileName);
        except
          on E: Exception do
            mdsHistory.SaveToFile(AFileName);
        end;
      end
    else
      mdsHistory.CreateTable;

    if not mdsHistory.Active then
      mdsHistory.Open;

    if mdsHistory.RecNo > 10000 then begin
      mdsHistory.First;
      for i:= 1 to 2 do
        mdsHistory.Delete;
    end;
    FCurrentHistoryFile:= AFileName;
    Result:= True;
  except
    on E: Exception do begin
      Result:= False;
      ShowMessage(e.Message);
    end;
  end;
end;


(* Get input parameters from stored procedure body *)

function TfmMain.RetrieveInputParamFromSP(Body: string): string;
var
  i: Integer;
  SizeStarted: Boolean;
begin
  SizeStarted:= False;
  if (Pos('(', Body) > 0) and (Pos('(', Body) < Pos(')', Body)) then
  for i:= 1 to Length(Body) do
  begin
    if (Body[i] = ')') and (not SizeStarted) then
    begin
      Result:= Trim(Copy(Body, 1, i - 1));
      Break;
    end;

    if (Body[i] = ')') and (SizeStarted) then
      SizeStarted:= False;

    if Body[i] = '(' then
      SizeStarted:= True;

  end
  else
    Result:= Trim(Copy(Body, 1, Pos(')', Body) - 1));
end;

(**************  New Generator  *******************)

procedure TfmMain.lmNewGenClick(Sender: TObject);
var
  SelNode: TTreeNode;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    InitNewGen(PtrInt(SelNode.Parent.Data));
    fmNewGen.edGenName.Clear;
    fmNewGen.edGenName.Enabled:= True;
    fmNewGen.cxTrigger.Checked:= False;
    fmNewGen.ShowModal;
  end;
end;

(************  Add New Table   ******************)

procedure TfmMain.lmNewTableClick(Sender: TObject);
var
  Rec: TDBInfo;
  SelNode: TTreeNode;
  dbIndex: Integer;
  Form: TfmNewTable;
  Title: string;
  ATab: TTabSheet;
begin
  SelNode:= tvMain.Selected;
  dbIndex:= PtrInt(SelNode.Parent.Data);
  Rec:= RegisteredDatabases[dbIndex];

  Title:= SelNode.Parent.Text + ': New Table';

  Form:= FindCustomForm(Title, TfmNewTable) as TfmNewTable;
  if Form = nil then
  begin
    Form:= TfmNewTable.Create(Application);
    ATab:= NewTab(PageControl1, dbIndex);// TTBTabSheet.Create(self);
    //ATab.Parent:= PageControl1;
    Form.Parent:= ATab;
    Form.Caption:= Title;
    ATab.Caption:= Form.Caption;
    Form.Left:= 0;
    Form.Top:= 0;
    Form.BorderStyle:= bsNone;
    Form.Align:= alClient;
    Form.Init(dbIndex);
  end
  else
    ATab:= Form.Parent as TTabSheet;
  PageControl1.ActivePage:= ATab;
  Form.Show;
  Form.edNewTable.SetFocus;

  //ATab.Tag:= dbIndex;
  PageControl1.ActivePage:= ATab;
end;

(*************  Create new function  ******************)

procedure TfmMain.lmNewUDFClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
  AFuncName: string;
  ModuleName, EntryPoint: string;
begin
  SelNode:= tvMain.Selected;
  ModuleName:= '<modulename>';
  EntryPoint:= '<entryname>';
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  if InputQuery('Create new function', 'Please enter new function name', AFuncName) then
  if InputQuery('Create new function', 'Please enter module name (Library)', ModuleName) then
  if InputQuery('Create new function', 'Please enter entry point (External function name)', EntryPoint) then
  begin
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Data), 'Create new function');
    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('DECLARE EXTERNAL FUNCTION "' + AFuncName + '"');
    QWindow.meQuery.Lines.Add('-- (int, varchar(100))');
    QWindow.meQuery.Lines.Add('RETURNS (int)');
    QWindow.meQuery.Lines.Add('ENTRY_POINT ' + QuotedStr(entryPoint));
    QWindow.meQuery.Lines.Add('MODULE_NAME ' + QuotedStr(modulename) + ';');
    QWindow.Show;
  end;
end;

(**********  Open Query 2 Click ************)


(**********  Open Query Window from Database  *************)

procedure TfmMain.lmOpenQueryClick(Sender: TObject);
var
  QWindow: TfmQueryWindow;
  Rec: TDBDetails;
  Count: Integer;
  dbIndex: Integer;
begin
  dbIndex:= PtrInt(tvMain.Selected.Data);
  Rec:= RegisteredDatabases[dbIndex].RegRec;
  // Password form
  if (Rec.Password = '') and (not tvMain.Selected.Expanded) then
  begin
    fmEnterPass.edPassword.Clear;
    try
      fmEnterPass.cbRole.Items.CommaText:= dmSysTables.GetDBObjectNames(fmMain.RegisteredDatabases[dbIndex], otRoles, Count);
    except
    end;
    if fmEnterPass.ShowModal = mrOk then
    begin
      if fmReg.TestConnection(Rec.DatabaseName, fmEnterPass.edUser.Text, fmEnterPass.edPassword.Text,
        Rec.Charset) then
          RegisteredDatabases[dbIndex].RegRec.Password:= fmEnterPass.edPassword.Text
        else
          Exit;
    end;
  end;
  QWindow:= ShowQueryWindow(dbIndex, 'Query Window');
  QWindow.Show;
end;

procedure TfmMain.lmPermissionsClick(Sender: TObject);
var
  dbIndex: Integer;
  Form: TfmUserPermissions;
  List: TStringList;
  UserName: string;
  i: Integer;
  Permission: string;
  ObjType: Integer;
  ObjTypeName: string;
  ObjName: string;
  ATab: TTabSheet;
  Title: string;
begin
  dbIndex:= PtrInt(tvMain.Selected.Parent.Parent.Data);
  UserName:= tvMain.Selected.Text;
  List:= TStringList.Create;
  try
    List.CommaText:= dmSysTables.GetUserObjects(dbIndex, UserName);
    Title:= 'Permissions for: ' + UserName;

    Form:= FindCustomForm(Title, TfmUserPermissions) as TfmUserPermissions;
    if Form = nil then
    begin
      Form:= TfmUserPermissions.Create(Application);
      ATab:= NewTab(PageControl1, dbIndex); //TTBTabSheet.Create(self);
      //ATab.Parent:= PageControl1;
      Form.Parent:= ATab;
      Form.Caption:= Title;
      ATab.Caption:= Form.Caption;
      Form.Left:= 0;
      Form.Top:= 0;
      Form.BorderStyle:= bsNone;
      Form.Align:= alClient;
    end
    else
      ATab:= Form.Parent as TTabSheet;

    //ATab.Tag:= dbIndex;
    PageControl1.ActivePage:= ATab;
    Form.StringGrid1.RowCount:= 1;
    Form.laObject.Caption:= UserName;
    with Form do
    for i:= 0 to List.Count - 1 do
    begin
      ObjName:= List[i];
      if Pos('<G>', ObjName) = 1 then
        Delete(ObjName, 1, 3);
      Permission:= dmSysTables.GetObjectUserPermission(dbIndex, ObjName, UserName, ObjType);
      StringGrid1.RowCount:= StringGrid1.RowCount + 1;

      case ObjType of
        0: ObjTypeName:= 'Table/View';
        5: ObjTypeName:= 'Procedure';
        13: ObjTypeName:= 'Role';
      else
        ObjTypeName:= IntToStr(ObjType);
      end;
      StringGrid1.Cells[0, i + 1]:= ObjTypeName;
      StringGrid1.Cells[1, i + 1]:= ObjName;
      StringGrid1.Cells[2, i + 1]:= Permission;
    end;
    Form.Show;
  finally
    List.Free;
  end;
end;

(***********  Refresh Click  *************)

procedure TfmMain.lmRefreshClick(Sender: TObject);
begin
  if tvMain.Selected.Expanded then
    tvMain.Selected.Collapse(False);
  tvMainExpanded(nil, tvMain.Selected)
end;

procedure TfmMain.lmRegdbClick(Sender: TObject);
begin
  fmReg.edDatabaseName.Text:= tvMain.Selected.Text + ':';
  actRegisterDBExecute(Nil);
  //mnRegDBClick(nil);
end;

procedure TfmMain.lmRestoreClick(Sender: TObject);
begin
  actRestoreDBExecute(Sender);
end;

procedure TfmMain.lmRolePerManagementClick(Sender: TObject);
var
  fmPermissions: TfmPermissionManage;
  ATab: TTabSheet;
  Title: string;
  dbIndex: Integer;
begin
  dbIndex:= PtrInt(tvMain.Selected.Parent.Parent.Data);
  Title:= 'Permission management for: ' + tvMain.Selected.Text;
  fmPermissions:= FindCustomForm(Title, TfmPermissionManage) as TfmPermissionManage;
  if fmPermissions = nil then
  begin
    fmPermissions:= TfmPermissionManage.Create(nil);
    ATab := NewTab(PageControl1,dbIndex); //TTBTabSheet.Create(self);
    ATab.Parent:= PageControl1;
    fmPermissions.Parent:= ATab;
    fmPermissions.Left:= 0;
    fmPermissions.Top:= 0;
    fmPermissions.BorderStyle:= bsNone;
    fmPermissions.Align:= alClient;
    ATab.Caption:= Title;
  end
  else
    ATab:= fmViewGen.Parent as TTabSheet;
  PageControl1.ActivePage:= ATab;
  //ATab.Tag:= dbIndex;
  fmPermissions.Init(dbIndex, '', tvMain.Selected.Text, 2);
  fmPermissions.Show;
end;

procedure TfmMain.lmRolePermissionsClick(Sender: TObject);
begin
  lmPermissionsClick(Sender);
end;

(***********  Script Database  ************)

procedure TfmMain.lmScriptDatabaseClick(Sender: TObject);
var
  QueryWindow: TfmQueryWindow;
  List: TStringList;
  dbIndex: Integer;
begin
  dbIndex:= PtrInt(tvMain.Selected.Data);
  QueryWindow:= ShowQueryWindow(dbIndex, 'Database Script');
  Screen.Cursor:= crSQLWait;
  List:= TStringList.Create;
  try //...finally for resource release
    try //...except for error reporting
      Application.ProcessMessages;
      with QueryWindow.meQuery do
      begin
        ClearAll;
        Lines.Add('-- ' + tvMain.Selected.Text + ' database script. Generated on: ' + DateTimeToStr(Now) );

        Lines.Add('');
        Lines.Add('--     Roles');
        Lines.Add('');
        ScriptAllRoles(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--     Exceptions');
        Lines.Add('');
        ScriptAllExceptions(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--     Functions (UDF)');
        Lines.Add('');
        ScriptAllFunctions(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--     Domains');
        Lines.Add('');
        ScriptAllDomains(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--      Generators/Sequences');
        Lines.Add('');
        ScriptAllGenerators(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--      Tables');
        ScriptAllTables(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--      Stored Procedures');
        Lines.Add('');
        ScriptAllProcedureTemplates(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('/*      Views  */');
        Lines.Add('');
        ScriptAllViews(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--      Triggers');
        Lines.Add('');
        ScriptAllTriggers(dbIndex, List);
        Lines.AddStrings(List);


        Lines.Add('');
        Lines.Add('--      Secondary Indices');
        Lines.Add('');
        ScriptAllSecIndices(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--      Constraints');
        Lines.Add('');
        ScriptAllConstraints(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--      Check constraints');
        Lines.Add('');
        ScriptAllCheckConstraints(dbIndex, List);
        Lines.AddStrings(List);

        Lines.Add('');
        Lines.Add('--      Permissions');
        Lines.Add('');
        ScriptAllPermissions(dbIndex, List);
        Lines.AddStrings(List);
        Lines.Add('');
      end;
      QueryWindow.Show;
    except
      on E: Exception do
      begin
        Screen.Cursor:= crDefault;
        ShowMessage(E.Message);
      end;
    end;
  finally
    Screen.Cursor:= crDefault;
    List.Free;
  end;
end;

(**************  Script Exception  ****************)

procedure TfmMain.lmScriptExceptionClick(Sender: TObject);
var
  SelNode: TTreeNode;
  Script, Msg, Desc: string;
begin
  SelNode:= tvMain.Selected;
  if dmSysTables.GetExceptionInfo(PtrInt(tvMain.Selected.Data), SelNode.Text,
    Msg, Desc, Script, false) then
    ShowCompleteQueryWindow(PtrInt(SelNode.Parent.Parent.Data), 'Script Exception ' + SelNode.Text, Script, nil);
end;

(**************  Script table as Insert stored procedure ************)

procedure TfmMain.lmScriptInsertClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
  ATableName: string;
  FieldLine: string;
  FieldNames: string;
  ParamNames: string;
  Skipped: Boolean;
  dbIndex: Integer;
  LastParam: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    ATableName:= SelNode.Text;
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
    QWindow:= ShowQueryWindow(dbIndex, 'Script Table as insert : ' + ATableName);
    Get_Fields(dbIndex, ATableName, nil);
    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('create procedure InsertTo' + ATableName + ' (');

    // Params
    FieldNames:= '';
    ParamNames:= '';
    with qryMain do
    while not EOF do begin
      Skipped:= False;
      if (FieldByName('computed_source').AsString = '') then
      begin
        FieldNames:= FieldNames + Trim(FieldByName('Field_Name').AsString);
        ParamNames:= ParamNames + ':' + Trim(FieldByName('Field_Name').AsString);
        FieldLine:= Trim(FieldByName('Field_Name').AsString) + ' ';
        FieldLine:= FieldLine +
          GetFBTypeName(qryMain.FieldByName('field_type_int').AsInteger,
            qryMain.FieldByName('field_sub_type').AsInteger,
            qryMain.FieldByName('field_length').AsInteger,
            qryMain.FieldByName('field_precision').AsInteger,
            qryMain.FieldByName('field_scale').AsInteger);
        if FieldByName('field_type_int').AsInteger in [CStringType,CharType,VarCharType] then
          FieldLine:= FieldLine + '(' + FieldByName('CharacterLength').AsString + ') ';
      end
      else
        Skipped:= True;

      Next;

      if not Skipped then
      begin
        if not EOF then
        begin
          FieldLine:= FieldLine + ',';
          FieldNames:= FieldNames + ', ';
          ParamNames:= ParamNames + ', ';
        end;
        QWindow.meQuery.Lines.Add(FieldLine);
      end;
    end;
    qryMain.Close;

    // Remote last , if any
    if RightStr(FieldNames, 2) = ', ' then
    begin
      System.Delete(FieldNames, Length(FieldNames) - 1, 2);
      System.Delete(ParamNames, Length(ParamNames) - 1, 2);
    end;

    // Remove last , if any
    LastParam:= QWindow.meQuery.Lines[QWindow.meQuery.Lines.Count - 1];
    if Pos(',', LastParam) > 0 then
    begin
      LastParam:= StringReplace(LastParam, ',', '', []);
      QWindow.meQuery.Lines[QWindow.meQuery.Lines.Count - 1]:= LastParam;
    end;

    QWindow.meQuery.Lines.Add(')');
    QWindow.meQuery.Lines.Add('AS');
    QWindow.meQuery.Lines.Add('BEGIN');
    QWindow.meQuery.Lines.Add('insert into ' + ATableName + ' (' + FieldNames + ')');
    QWindow.meQuery.Lines.Add('values (' + ParamNames + ');');
    QWindow.meQuery.Lines.Add('end;');

    QWindow.Show;
  end;
end;

(********  Script table as Create  ***********)

procedure TfmMain.lmScriptTableCreateClick(Sender: TObject);
var
  SelNode     :TTreeNode;
  QWindow     :TfmQueryWindow;
  ATableName  :string;
  dbIndex     :Integer;
  ScriptList  :TStringList;
  Line        :string;
  PKIndexName :string;
  ConstraintName :string;
  List           :TStringList;
  i              :Integer;
  UserName       :string;
  ObjType        :Integer;
  Triggers       :TStringList;
  j              :Integer;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    ATableName:= SelNode.Text;
    dbIndex := PtrInt(SelNode.Parent.Parent.Data);
    ScriptList:= TStringList.Create;
    try
      ScriptTableAsCreate(dbIndex, ATableName, ScriptList);
      QWindow:= ShowQueryWindow(dbIndex, 'Script Table as Create: ' + ATableName);
      QWindow.meQuery.Lines.Clear;
      QWindow.meQuery.Lines.AddStrings(ScriptList);

      // Script table constraints
      dmSysTables.MDOQuery.Close;
      qryMain.Close;
      dmSysTables.GetTableConstraints(ATableName, dmSysTables.MDOQuery);
      with dmSysTables do
      while not MDOQuery.EOF do
      begin
         Line:= 'alter table ' + ATableName + ' add constraint ' + MDOQuery.Fields[0].AsString +
           ' foreign key (' + MDOQuery.Fields[3].AsString + ') references ' +  MDOQuery.Fields[4].AsString  +
           ' (' + dmSysTables.GetConstraintForeignKeyFields(MDOQuery.Fields[5].AsString, fmMain.qryMain) + ') ';
         if Trim(MDOQuery.Fields[6].AsString) <> 'RESTRICT' then
           Line:= Line + ' on update ' + Trim(MDOQuery.Fields[6].AsString);
         if Trim(MDOQuery.Fields[7].AsString) <> 'RESTRICT' then
           Line:= Line + ' on delete ' + Trim(MDOQuery.Fields[7].AsString);
         QWindow.meQuery.Lines.Add(Line + ';');
         MDOQuery.Next;
      end;
      dmSysTables.MDOQuery.Close;
      qryMain.Close;
      QWindow.meQuery.Lines.Add('');

      // Script indices
      PKIndexName:= GetPrimaryKeyIndexName(dbIndex, ATableName, ConstraintName);
      List:= TStringList.Create;
      try
        with dmSysTables do
        if fmMain.GetIndices(ATableName, MDOQuery) then
        with MDOQuery do
        while not EOF do
        begin
          if PKIndexName <> Trim(FieldByName('RDB$Index_name').AsString) then
          begin
            Line:= 'create ';
            if FieldByName('RDB$Unique_Flag').AsString = '1' then
              Line:= Line + 'Unique ';
            if FieldByName('RDB$Index_Type').AsString = '1' then
              Line:= Line + 'Descending ';

            Line:= Line + 'index ' + Trim(FieldByName('RDB$Index_name').AsString) + ' on ' + ATableName;

            GetIndexFields(ATableName, Trim(FieldByName('RDB$Index_Name').AsString), fmMain.qryMain, List);

            Line:= Line + ' (' + List.CommaText + ') ;';
            QWindow.meQuery.Lines.Add(Line);
          end;
          Next;
        end;

        QWindow.meQuery.Lines.Add('');
        qryMain.Close;
        dmSysTables.MDOQuery.Close;

        // Script triggers
        qryMain.Close;
        qryMain.SQL.Text:= 'SELECT RDB$Trigger_Name, RDB$Trigger_Inactive FROM RDB$TRIGGERS WHERE RDB$SYSTEM_FLAG=0 ' +
          'and RDB$Relation_Name = ' + QuotedStr(aTableName);
        qryMain.Open;
        Triggers:= TStringList.Create;
        try
          with qryMain do
          while not EOF do
          begin
            Triggers.Add(Trim(Fields[0].AsString));
            Next;
          end;
          qryMain.Close;
          for j:= 0 to Triggers.Count - 1 do
          begin
            List.Clear;
            dmSysTables.ScriptTrigger(dbIndex, Triggers[j], List, True);

            // Search for generators
            Line:= '';
            for i:= 0 to List.Count - 1 do
              if Pos('gen_id', LowerCase(List[i])) > 0 then
              begin
                Line:= Copy(List[i], Pos('gen_id', LowerCase(List[i])), Length(List[i]));
                System.Delete(Line, 1, Pos('(', Line));
                Line:= Trim(Copy(Line, 1, Pos(', ', Line) - 1));
              end;

             // Script Generator
             if Trim(Line) <> '' then
             begin
               QWindow.meQuery.Lines.Add('Create Generator ' + Line + ';');
               QWindow.meQuery.Lines.Add('');
             end;

            QWindow.meQuery.Lines.AddStrings(List);
          end;
        finally
          Triggers.Free;
        end;

        QWindow.meQuery.Lines.Add('');

        // Script permissions
        List.CommaText:= dmSysTables.GetDBUsers(dbIndex);


        for i:= 0 to List.Count - 1 do
        begin
          if Pos('<R>', List[i]) = 1 then
            UserName:= Copy(List[i], 4, Length(List[i]) - 3)
          else
            UserName:= List[i];

          ScriptObjectPermission(dbIndex, '<T>' + ATableName, UserName, ObjType, QWindow.meQuery.Lines);
        end;
      finally
        List.Free;
      end;
    finally
      ScriptList.Free;
    end;
    QWindow.Show;
  end;
end;

(*****************  Script as Update table stored proc  ****************)

procedure TfmMain.lmScriptUpdateClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
  ATableName: string;
  i: Integer;
  PKFieldsList: TStringList;
  FieldLine: string;
  ParamAndValue: string;
  AFieldName: string;
  WhereClause: string;
  Skipped: Boolean;
  PKIndexName: string;
  dbIndex: Integer;
  ConstraintName: string;
  LastParam: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    ATableName:= SelNode.Text;
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
    QWindow:= ShowQueryWindow(dbIndex, 'Script Table as update: ' + ATableName);
    Get_Fields(dbIndex, ATableName, nil);
    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('create procedure Update' + ATableName + ' (');

    // Params
    ParamAndValue:= '';
    with qryMain do
    while not EOF do
    begin
      Skipped:= False;
      if (FieldByName('computed_source').AsString = '') then
      begin
        AFieldName:= Trim(qryMain.FieldByName('Field_Name').AsString);
        ParamAndValue:= ParamAndValue + AFieldName + ' = :' + AFieldName;
        FieldLine:= AFieldName + ' ';
        FieldLine:= FieldLine + GetFBTypeName(qryMain.FieldByName('field_type_int').AsInteger,
          qryMain.FieldByName('field_sub_type').AsInteger,
          qryMain.FieldByName('field_length').AsInteger,
          qryMain.FieldByName('field_precision').AsInteger,
          qryMain.FieldByName('field_scale').AsInteger);
        if qryMain.FieldByName('field_type_int').AsInteger in [CStringType,CharType,VarCharType] then
          FieldLine:= FieldLine + '(' + FieldByName('CharacterLength').AsString + ') ';
      end
      else
        Skipped:= True;
      Next;

      if not Skipped then
      begin
        if not EOF then
        begin
          FieldLine:= FieldLine + ',';
          ParamAndValue:= ParamAndValue + ', ';
        end;
        QWindow.meQuery.Lines.Add(FieldLine);

      end;
    end;

    // Remote last , if any
    if RightStr(ParamAndValue, 2) = ', ' then
      Delete(ParamAndValue, Length(ParamAndValue) - 1, 2);
    qryMain.Close;

    // Primary Keys
    WhereClause:= '';
    PKFieldsList:= TStringList.Create;
    PKIndexName:= GetPrimaryKeyIndexName(dbIndex, ATableName, ConstraintName);
    if PKIndexName <> '' then
    begin
      GetConstraintFields(ATableName, PKIndexName, PKFieldsList);
      for i:= 0 to PKFieldsList.Count - 1 do
      begin
        WhereClause:= WhereClause + PKFieldsList[i] + ' = :' + PKFieldsList[i];
        if i < PKFieldsList.Count - 1 then
          WhereClause:= WhereClause + ' and ';
      end;
    end;

    // Remove last , if any
    LastParam:= QWindow.meQuery.Lines[QWindow.meQuery.Lines.Count - 1];
    if Pos(',', LastParam) > 0 then
    begin
      LastParam:= StringReplace(LastParam, ',', '', []);
      QWindow.meQuery.Lines[QWindow.meQuery.Lines.Count - 1]:= LastParam;
    end;

    QWindow.meQuery.Lines.Add(')');
    QWindow.meQuery.Lines.Add('AS');
    QWindow.meQuery.Lines.Add('BEGIN');
    QWindow.meQuery.Lines.Add('update ' + ATableName);
    QWindow.meQuery.Lines.Add('set ' + ParamAndValue);
    QWindow.meQuery.Lines.Add('where ' + WhereClause + ';');
    QWindow.meQuery.Lines.Add('END;');

    QWindow.Show;

  end;
end;

(******************  Set generator value  *********************)

procedure TfmMain.lmSetGenClick(Sender: TObject);
var
  SelNode: TTreeNode;
  Rec: TDBInfo;
  AGenName: string;
  OrigValue: string;
  dbIndex: Integer;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
    Rec:= RegisteredDatabases[dbIndex];
    SetConnection(dbIndex);

    AGenName:= SelNode.Text;
    qryMain.Close;
    qryMain.SQL.Text:= 'select GEN_ID(' + AGenName + ', 0) from RDB$Database;';

    qryMain.Open;
    OrigValue:= qryMain.Fields[0].AsString;
    qryMain.Close;

    ShowCompleteQueryWindow(dbIndex, 'set generator value', 'set generator ' + AGenName + ' to ' + OrigValue);
  end;

end;

(*************   Sweep Database   ***********)

procedure TfmMain.lmSweepClick(Sender: TObject);
var
  FireBirdServices: TFirebirdServices;
  dbIndex: Integer;
  AdbName: string;
  Lines: string;
  s: string;
begin
  dbIndex:= PtrInt(tvMain.Selected.Data);
  FireBirdServices:= TFirebirdServices.Create;
  Screen.Cursor:= crSQLWait;
  try
    FireBirdServices.VerboseOutput:= True;
    with FireBirdServices, RegisteredDatabases[dbIndex] do
    begin
      HostName:= GetServerName(RegRec.DatabaseName);
      AdbName:= RegRec.DatabaseName;
      if Pos(':', AdbName) > 2 then
        Delete(AdbName, 1, Pos(':', AdbName));
      DBName:= AdbName;
      UserName := RegRec.UserName;
      Password := RegRec.Password;

      try
        AttachService;
        StartSweep;
        while ServiceQuery(S) do
          Lines:= Lines + S;
        Screen.Cursor:= crDefault;
        ShowMessage('Sweep database: ' + AdbName + ' completed');
      except
        on E: Exception do
        begin
          MessageDlg('Error: ' + E.Message, mtError, [mbOK], 0);
        end;
      end;
      DetachService;
    end;
  finally
    Screen.Cursor:= crDefault;
    FireBirdServices.Free;
  end;
end;


(*************  Table management  ****************)

procedure TfmMain.lmTableManageClick(Sender: TObject);
var
  SelNode: TTreeNode;
  dbIndex: Integer;
  fmTableManage: TfmTableManage;
  ATab: TTabSheet;
  Title: string;
begin
  try
    SelNode:= tvMain.Selected;
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);

    Title:= RegisteredDatabases[dbIndex].RegRec.Title +  ': Management of : ' + SelNode.Text;
    // Fields
    fmTableManage:= FindCustomForm(Title, TfmTableManage) as TfmTableManage;
    if fmTableManage = nil then
    begin
      fmTableManage:= TfmTableManage.Create(Application);
      ATab := NewTab(PageControl1, dbIndex); //TTBTabSheet.Create(self);
      //ATab.Parent:= PageControl1;
      fmTableManage.Parent:= ATab;
      fmTableManage.Left:= 0;
      fmTableManage.Top:= 0;
      fmTableManage.Align:= alClient;
      fmTableManage.BorderStyle:= bsNone;
    end
    else
      ATab:= fmTableManage.Parent as TTabSheet;

    PageControl1.ActivePage:= ATab;
    fmTableManage.Caption:= Title;
    ATab.Caption:= Title;
    //ATab.Tag:= dbIndex;
    fmTableManage.Init(dbIndex, SelNode.Text);
    fmTableManage.PageControl1.TabIndex:= 0;

    // Fields
    ViewTableFields(SelNode.Text, dbIndex, fmTableManage.sgFields);

    // Indices
    ShowIndicesManagement(fmTableManage, dbIndex, SelNode.Text);

    // Constraints
    FillAndShowConstraintsForm(fmTableManage, SelNode.Text, dbIndex);

    // Triggers
    fmTableManage.FillTriggers;

    // Permissions
    fmTableManage.FillPermissions;

    fmTableManage.bbRefreshReferencesClick(nil);
    fmTableManage.Show;
  except
    on E: Exception do
      MessageDlg('Error while opening Table Management: ' + e.Message, mtError, [mbOk], 0);
  end;
end;

procedure TfmMain.lmUserPermManagementClick(Sender: TObject);
begin
  lmRolePerManagementClick(nil);
end;

(**********  View Domain info ************)

procedure TfmMain.lmViewDomainClick(Sender: TObject);
var
  SelNode: TTreeNode;
  ADomainName: string;
  CheckConstraint: string;
  CharacterSet: string;
  Collation: string;
  DomainType: string;
  DomainSize: Integer;
  ADomainForm: TFmViewDomain;
  DefaultValue: string;
  ATab: TTabSheet;
  dbIndex: Integer;
  Title: string;
begin
  SelNode:= tvMain.Selected;
  dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    ADomainName:= SelNode.Text;
    Title:= SelNode.Parent.Parent.Text + ': Domain: ' + ADomainName;
    ADomainForm:= TfmViewDomain(FindCustomForm(Title, TfmViewDomain));
    if ADomainForm  = nil then
    begin
      ADomainForm:= TfmViewDomain.Create(Application);
      ATab:= NewTab(PageControl1,dbIndex); //TTBTabSheet.Create(self);
      ATab.Parent:= PageControl1;
      ADomainForm.Parent:= ATab;
      ADomainForm.Left:= 0;
      ADomainForm.Top:= 0;
      ADomainForm.BorderStyle:= bsNone;
      ADomainForm.Align:= alClient;
      PageControl1.ActivePage:= ATab;
    end
    else
      ATab:= ADomainForm.Parent as TTabSheet;
    PageControl1.ActivePage:= ATab;

    dmSysTables.GetDomainInfo(dbIndex, ADomainName, DomainType, DomainSize, DefaultValue, CheckConstraint, CharacterSet, Collation);
    //ATab.Tag:= dbIndex;
    if Pos('default', LowerCase(DefaultValue)) = 1 then
      DefaultValue:= Trim(Copy(DefaultValue, 8, Length(DefaultValue)));
    if (Pos('CHAR', DomainType) > 0) or
      (Pos('CSTRING', DomainType) >0) then
      DomainType:= DomainType + '(' + IntToStr(DomainSize) + ')';

    // Fill ViewDomain form
    with ADomainForm do
    begin
      Caption:= Title;
      ATab.Caption:= Caption;
      edName.Caption:= ADomainName;
      laType.Caption:= DomainType;
      laSize.Caption:= IntToStr(DomainSize);
      laDefault.Caption:= DefaultValue;
      laCheckConstraint.Caption:= CheckConstraint;
      laCharacterSet.Caption:= CharacterSet;
      laCollation.Caption:= Collation;
    end;
    ADomainForm.Show;
  end;
end;


(********************  Get Fields  **************************)

procedure TfmMain.Get_Fields(DatabaseIndex: Integer; ATableName: string; FieldsList: TStringList);
const
  QueryTemplate= 'SELECT r.RDB$FIELD_NAME AS field_name, ' +
    ' r.RDB$DESCRIPTION AS field_description, ' +
    ' r.RDB$DEFAULT_SOURCE AS field_default_source, ' {SQL source for default value }+
    ' r.RDB$NULL_FLAG AS field_not_null_constraint, ' +
    ' f.RDB$FIELD_LENGTH AS field_length, ' +
    ' f.RDB$CHARACTER_LENGTH AS characterlength, ' + {character_length seems a reserved word}
    ' f.RDB$FIELD_PRECISION AS field_precision, ' +
    ' f.RDB$FIELD_SCALE AS field_scale, ' +
    ' f.RDB$FIELD_TYPE as field_type_int, ' +
    ' f.RDB$FIELD_SUB_TYPE AS field_sub_type, ' +
    ' coll.RDB$COLLATION_NAME AS field_collation, ' +
    ' cset.RDB$CHARACTER_SET_NAME AS field_charset, ' +
    ' f.RDB$computed_source AS computed_source, ' +
    ' dim.RDB$UPPER_BOUND AS array_upper_bound, ' +
    ' r.RDB$FIELD_SOURCE AS field_source ' {domain if field based on domain}+
    ' FROM RDB$RELATION_FIELDS r ' +
    ' LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME ' +
    ' LEFT JOIN RDB$COLLATIONS coll ON f.RDB$COLLATION_ID = coll.RDB$COLLATION_ID and f.rdb$character_set_id=coll.rdb$character_set_id ' +
    ' LEFT JOIN RDB$CHARACTER_SETS cset ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID ' +
    ' LEFT JOIN RDB$FIELD_DIMENSIONS dim ON f.RDB$FIELD_NAME = dim.RDB$FIELD_NAME ' +
    ' WHERE r.RDB$RELATION_NAME=''%s'' ' +
    ' ORDER BY r.RDB$FIELD_POSITION;';
var
  vRec: TDBInfo;
  FieldName: string;
begin
  qryMain.Close;
  {A bit unclear why the transaction needs to be committed but at least do it
  before changing the query's transaction}
  if (Assigned(FTrans) and FTrans.Active) then
    FTrans.Commit;
  vRec := RegisteredDatabases[DatabaseIndex];
  SetConnection(DatabaseIndex);
  qryMain.SQL.Text:= format(QueryTemplate,[ATableName]);
  {$IFDEF NEVER}
  // Left for debugging
  SendDebug('GetFields: '+SQLQuery1.SQL.Text);
  {$ENDIF}
  qryMain.Open;
  // If FieldsList is nil, don't try to fill results. Calling code probably
  // just wants the query. Let's hope so.
  if FieldsList <> nil then begin
    FieldsList.Clear;
    qryMain.First;//JKOZ: opening a query does not quaranty that it will be set on the first record (as far as I remember)
    while not qryMain.EOF do begin
      FieldName:= Trim(qryMain.FieldByName('field_name').AsString);
      // Avoid duplicate field names
      if FieldsList.IndexOf(FieldName) = -1 then
        FieldsList.Add(FieldName);
      qryMain.Next;
    end;
  end;
  qryMain.First;
end;

procedure TfmMain.Get_Fields(const aDatabase :TDBInfo; ATableName :string; const FieldsList :TStringList);
const
  QueryTemplate = 'SELECT r.RDB$FIELD_NAME AS field_name, ' +
                  'r.RDB$DESCRIPTION       AS field_description, ' +
                  'r.RDB$DEFAULT_SOURCE    AS field_default_source, ' {SQL source for default value }+
                  'r.RDB$NULL_FLAG         AS field_not_null_constraint, ' +
                  'f.RDB$FIELD_LENGTH      AS field_length, ' +
                  'f.RDB$CHARACTER_LENGTH  AS characterlength, ' + {character_length seems a reserved word}
                  'f.RDB$FIELD_PRECISION   AS field_precision, ' +
                  'f.RDB$FIELD_SCALE       AS field_scale, ' +
                  'f.RDB$FIELD_TYPE        As field_type_int, ' +
                  'f.RDB$FIELD_SUB_TYPE    AS field_sub_type, ' +
                  'coll.RDB$COLLATION_NAME AS field_collation, ' +
                  'cset.RDB$CHARACTER_SET_NAME AS field_charset, ' +
                  'f.RDB$computed_source       AS computed_source, ' +
                  'dim.RDB$UPPER_BOUND         AS array_upper_bound, ' +
                  'r.RDB$FIELD_SOURCE          AS field_source ' {domain if field based on domain}+
                  'FROM RDB$RELATION_FIELDS r ' +
                  'LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME ' +
                  'LEFT JOIN RDB$COLLATIONS coll ON f.RDB$COLLATION_ID = coll.RDB$COLLATION_ID and f.rdb$character_set_id=coll.rdb$character_set_id ' +
                  'LEFT JOIN RDB$CHARACTER_SETS cset ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID ' +
                  'LEFT JOIN RDB$FIELD_DIMENSIONS dim ON f.RDB$FIELD_NAME = dim.RDB$FIELD_NAME ' +
                  'WHERE r.RDB$RELATION_NAME=''%s'' ' +
                  'ORDER BY r.RDB$FIELD_POSITION;';
var
  vRec: TDBInfo;
  FieldName: string;
begin
  qryMain.Close;
  qryMain.SQL.Text;
  {A bit unclear why the transaction needs to be committed but at least do it
  before changing the query's transaction}
  if (Assigned(FTrans)) then FTrans.Commit;
  //vRec := RegisteredDatabases[DatabaseIndex];
  SetConnection(aDatabase);
  qryMain.SQL.Text := Format(QueryTemplate,[ATableName]);
  {$IFDEF NEVER}
  // Left for debugging
  SendDebug('GetFields: ' + SQLQuery1.SQL.Text);
  {$ENDIF}
  qryMain.Open;
  // If FieldsList is nil, don't try to fill results. Calling code probably
  // just wants the query. Let's hope so.
  if FieldsList <> nil then begin
    FieldsList.Clear;
    qryMain.First;//JKOZ: opening a query does not quaranty that it will be set on the first record (as far as I remember)
    while not qryMain.EOF do begin
      FieldName := Trim(qryMain.FieldByName('field_name').AsString);
      // Avoid duplicate field names
      if FieldsList.IndexOf(FieldName) = -1 then
        FieldsList.Add(FieldName);
      qryMain.Next;
    end;
  end;
  qryMain.First;
end;
//
(**********  Get Stored Proc body  ****************)

function TfmMain.GetStoredProcBody(DatabaseIndex: Integer; AProcName: string; var SPOwner: string): string;
const
  BodyTemplate=
    'SELECT * FROM rdb$procedures where rdb$Procedure_name =  ''%s'' ';
  ParamTemplate=
   'SELECT rdb$parameter_name, rdb$field_type, rdb$field_sub_type, '+
   'rdb$field_length, rdb$field_scale, rdb$field_precision, '+
   'rdb$character_length, rdb$parameter_type '+
   'FROM rdb$procedure_parameters sp_param '+
   'JOIN rdb$fields fld '+
   'ON sp_param.rdb$field_source = fld.rdb$field_name '+
   'WHERE '+
   'sp_param.rdb$procedure_name =''%s'' ' +
   'order by rdb$parameter_type, rdb$parameter_number';
var
  Rec: TDBInfo;
  i: Integer;
  InputParams: integer; //count of input parameters
  Line: string;
  ParamName: string;
  OutputParams: integer; //count of output params
  BodyList: TStringList; // procedure body
begin
  try
    AProcName:= UpperCase(AProcName);
    BodyList:= TStringList.Create;
    try
      Rec:= RegisteredDatabases[DatabaseIndex];
      SetConnection(DatabaseIndex);

      // Get number of input and output parameters
      qryMain.Close;
      qryMain.SQL.Text:= format(BodyTemplate,[AProcName]);
      qryMain.Open;
      // Null will result in 0 which is fine here
      InputParams:= qryMain.FieldByName('rdb$procedure_inputs').AsInteger;
      OutputParams:= qryMain.FieldByName('rdb$procedure_outputs').AsInteger;

      qryMain.Close;
      qryMain.SQL.Text:= format(ParamTemplate,[AProcName]);
      qryMain.Open;

      // Get input parameters
      if InputParams>0 then begin
        BodyList.Add('(');
        i:= 1;
        while (not qryMain.EOF) and (i<=InputParams) do begin
          // Check for input parameter type:
          if (qryMain.FieldByName('rdb$parameter_type').AsInteger=0) then begin
            ParamName:= Trim(qryMain.FieldByName('rdb$parameter_name').AsString);
            Line:= '  ' + ParamName + '    ' +
              GetFBTypeName(qryMain.FieldByName('RDB$Field_Type').AsInteger,
              qryMain.FieldByName('rdb$field_sub_type').AsInteger,
              qryMain.FieldByName('rdb$field_length').AsInteger,
              qryMain.FieldByName('rdb$field_precision').AsInteger,
              qryMain.FieldByName('rdb$field_scale').AsInteger);
            if qryMain.FieldByName('RDB$Field_Type').AsInteger in [CharType,CStringType,VarCharType] then
              Line:= Line + '(' + qryMain.FieldByName('RDB$Character_Length').AsString + ')';
            if (InputParams>1) and (i<InputParams) then
              Line:= Line + ',';
            BodyList.Add(Line);
            inc(i);
          end;
          qryMain.Next;
        end;
        BodyList.Add(')' + LineEnding);
      end;

      // Get output parameters
      if OutputParams>0 then begin
        BodyList.Add('RETURNS (');
        i:= 1;
        while (not qryMain.EOF) and (i<=OutputParams) do
        begin
          // Check for input parameter type:
          if (qryMain.FieldByName('rdb$parameter_type').AsInteger=1) then
          begin
            ParamName:= Trim(qryMain.FieldByName('rdb$parameter_name').AsString);
            Line:= '  ' + ParamName + '    ' +
              GetFBTypeName(qryMain.FieldByName('RDB$Field_Type').AsInteger,
              qryMain.FieldByName ('rdb$field_sub_type').AsInteger,
              qryMain.FieldByName ('rdb$field_length').AsInteger,
              qryMain.FieldByName ('rdb$field_precision').AsInteger,
              qryMain.FieldByName ('rdb$field_scale').AsInteger);
            if qryMain.FieldByName('RDB$Field_Type').AsInteger in [CharType,CStringType,VarCharType] then
              Line := Line + '(' + qryMain.FieldByName('RDB$Character_Length').AsString + ')';
            if (OutputParams>1) and (i<OutputParams) then
              Line := Line + ',';
            BodyList.Add(Line);
            inc(i);
          end;
          qryMain.Next;
        end;
        BodyList.Add(')' + LineEnding);
      end;
      qryMain.Close;

      BodyList.Add('AS');

      // Get Procedure body (using the same query as before)
      qryMain.SQL.Text:= format(BodyTemplate,[AProcName]);
      qryMain.Open;
      SPOwner:= Trim(qryMain.FieldByName('rdb$Owner_Name').AsString);
      // Actual body text:
      BodyList.Add(qryMain.FieldByName('rdb$Procedure_Source').AsString);
      qryMain.Close;
      Result:= BodyList.Text;
    finally
      BodyList.Free;
    end;
  except
    on E: Exception do
      MessageDlg('Error while getting stored procedure information: ' + e.Message, mtError, [mbOk], 0);
  end;
end;

(******************  Get View Info (SQL Source) ***************)

function TfmMain.GetViewInfo(DatabaseIndex: Integer; AViewName: string; var Columns, Body: string): Boolean;
const//JKOZ : Metadata move.
  BodyTemplate= 'SELECT RDB$VIEW_SOURCE ' +
    ' FROM RDB$RELATIONS ' +
    ' WHERE RDB$VIEW_SOURCE IS NOT NULL ' +
    ' AND UPPER(RDB$RELATION_NAME) = ''%s'';';
  ColumnsTemplate= 'select r.rdb$field_name '+
    ' from rdb$relation_fields r ' +
    ' inner join rdb$fields f on ' +
    ' r.rdb$field_source=f.rdb$field_name ' +
    ' inner join rdb$types t on ' +
    ' f.rdb$field_type=t.rdb$type ' +
    ' where upper(r.rdb$relation_name)=''%s'' and ' +
    ' t.rdb$field_name=''RDB$FIELD_TYPE'' ' +
    ' order by r.RDB$FIELD_POSITION ';
var
  Rec: TDBInfo;
begin
  Rec := RegisteredDatabases[DatabaseIndex];
  SetConnection(DatabaseIndex);

  // View Body
  qryMain.Close;
  qryMain.SQL.Text:= format(BodyTemplate, [UpperCase(AViewName)]);

  qryMain.Open;
  Body := qryMain.Fields[0].AsString;

  // View Columns
  qryMain.Close;
  qryMain.SQL.Text := format(ColumnsTemplate, [UpperCase(AViewName)]);
  Columns:= '';
  qryMain.Open;
  while not qryMain.EOF do
  begin
    Columns := Columns + Trim(qryMain.FieldByName('rdb$field_name').AsString);
    qryMain.Next;
    if not qryMain.EOF then
      Columns:= Columns + ', ';
  end;
  qryMain.Close;
  Result:= True;
end;


(************  Change Trigger activity  *************)

function TfmMain.ChangeTriggerActivity(DatabaseIndex: Integer;
  ATriggerName: string; ActiveState: Boolean): Boolean;
var
  Rec: TDBInfo;
  ActiveStr: string;
begin //JKOZ: metadata move;
  try
    Rec:= RegisteredDatabases[DatabaseIndex];
    SetConnection(DatabaseIndex);

    qryMain.Close;
    if ActiveState then
      ActiveStr:= 'Active'
    else
      ActiveStr:= 'InActive';
    qryMain.SQL.Text:= 'alter trigger '+ ATriggerName + ' ' + ActiveStr;

    qryMain.ExecSQL;
    Result:= True;
    FTrans.Commit;
    AddToSQLHistory(Rec.RegRec.Title, 'DDL', qryMain.SQL.Text);
  except
    on E: Exception do
    begin
      ShowMessage('Error: ' + e.Message);
      Result:= False;
    end;
  end;
end;

(***************  Get Index fields  *******************)

function TfmMain.GetIndexFields(ATableName, AIndexName :string; AQuery :TMDOQuery; var FieldsList :TStringList) :Boolean;
const
  cSQL = 'SELECT RDB$INDEX_SEGMENTS.RDB$FIELD_NAME AS field_name, ' + //LineEnding +
     'RDB$INDICES.RDB$DESCRIPTION AS description, ' + //LineEnding +
     '(RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION + 1) AS field_position ' +//LineEnding +
     'FROM RDB$INDEX_SEGMENTS ' +//LineEnding +
     'LEFT JOIN RDB$INDICES ON RDB$INDICES.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME ' + //LineEnding +
     'LEFT JOIN RDB$RELATION_CONSTRAINTS ON RDB$RELATION_CONSTRAINTS.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME ' + //LineEnding +
     ' WHERE UPPER(RDB$INDICES.RDB$RELATION_NAME)=''%S''         -- table name ' + //LineEnding +
     '  AND UPPER(RDB$INDICES.RDB$INDEX_NAME)=''%S'' -- index name ' + //LineEnding +
     //'--  AND RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_TYPE IS NULL ' +LineEnding +
     'ORDER BY RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION;';
begin//JKOZ: Metadata Move;
  AQuery.Close;
  //AQuery.SQL.Text:= 'SELECT RDB$INDEX_SEGMENTS.RDB$FIELD_NAME AS field_name, ' + LineEnding +
  //   'RDB$INDICES.RDB$DESCRIPTION AS description, ' +LineEnding +
  //   '(RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION + 1) AS field_position ' +LineEnding +
  //   'FROM RDB$INDEX_SEGMENTS ' +LineEnding +
  //   'LEFT JOIN RDB$INDICES ON RDB$INDICES.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME ' +LineEnding +
  //   'LEFT JOIN RDB$RELATION_CONSTRAINTS ON RDB$RELATION_CONSTRAINTS.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME ' +LineEnding +
  //   ' WHERE UPPER(RDB$INDICES.RDB$RELATION_NAME)=''' + UpperCase(ATablename) + '''         -- table name ' +LineEnding +
  //   '  AND UPPER(RDB$INDICES.RDB$INDEX_NAME)=''' + UpperCase(AIndexName) + ''' -- index name ' +LineEnding +
  //   '--  AND RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_TYPE IS NULL ' +LineEnding +
  //   'ORDER BY RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION;';
  AQuery.SQL.Text := Format(cSQL,[UpperCase(ATableName),UpperCase(aIndexName)]);
  AQuery.Open;
  Result:= AQuery.FieldCount > 0;
  FieldsList.Clear;

  // Get index field names
  if Result then
  while not AQuery.EOF do
  begin
    FieldsList.Add(Trim(AQuery.FieldByName('field_name').AsString));
    AQuery.Next;
  end;
  if not Result then
    AQuery.Close;
end;

(***********  Get UDF Info  ***************)

function TfmMain.GetUDFInfo(DatabaseIndex: Integer; UDFName: string;
  var ModuleName, EntryPoint, Params: string): Boolean;
var
  Rec: TDBInfo;
begin//JKOZ: Metadata Move
  try
    Rec:= RegisteredDatabases[DatabaseIndex];
    SetConnection(DatabaseIndex);

    qryMain.Close;
    qryMain.SQL.Text:= Format('SELECT * FROM RDB$FUNCTIONS WHERE RDB$FUNCTION_NAME = ''%s'' ',[UDFName]);
    qryMain.Open;
    ModuleName:= Trim(qryMain.FieldByName('RDB$MODULE_NAME').AsString);
    EntryPoint:= Trim(qryMain.FieldByName('RDB$ENTRYPOINT').AsString);

    //todo: (low priority) probably domain based datatypes should be supported for input and output params in UDF declarations

    // input Params
    qryMain.Close;
    qryMain.SQL.Text:= 'SELECT * FROM RDB$FUNCTION_ARGUMENTS WHERE RDB$FUNCTION_Name = ''' +
     UDFName + ''' and RDB$MECHANISM = 1';
    qryMain.Open;
    Params:= '';
    while not qryMain.EOF do
    begin
      Params:= Params + LineEnding + GetFBTypeName(qryMain.FieldByName('RDB$FIELD_TYPE').AsInteger,
        qryMain.FieldByName('RDB$FIELD_SUB_TYPE').AsInteger,
        qryMain.FieldByName('RDB$FIELD_LENGTH').AsInteger,
        qryMain.FieldByName('RDB$FIELD_PRECISION').AsInteger,
        qryMain.FieldByName('RDB$FIELD_SCALE').AsInteger);
      if qryMain.FieldByName('RDB$FIELD_TYPE').AsInteger in [CharType, CStringType, VarCharType] then
        Params:= Params + '(' + qryMain.FieldByName('RDB$Character_LENGTH').AsString + ')';
      qryMain.Next;
      if not qryMain.EOF then
        Params:= Params + ', ';
    end;
    qryMain.Close;
    Params:= Params + ')' + LineEnding + LineEnding + 'Returns ';

    // Result Params
    qryMain.SQL.Text:= Format('SELECT * FROM RDB$FUNCTION_ARGUMENTS '+
      'where RDB$FUNCTION_Name = ''%s'' and RDB$MECHANISM = 0',[UDFName]);
    qryMain.Open;
    while not qryMain.EOF do
    begin
      Params:= Params + LineEnding + GetFBTypeName(qryMain.FieldByName('RDB$FIELD_TYPE').AsInteger,
        qryMain.FieldByName('RDB$FIELD_SUB_TYPE').AsInteger,
        qryMain.FieldByName('RDB$FIELD_LENGTH').AsInteger,
        qryMain.FieldByName('RDB$FIELD_PRECISION').AsInteger,
        qryMain.FieldByName('RDB$FIELD_SCALE').AsInteger);
      if qryMain.FieldByName('field_type_int').AsInteger in [CharType, CStringType, VarCharType] then
        Params:= Params + '(' + qryMain.FieldByName('RDB$Character_LENGTH').AsString + ')';
      qryMain.Next;
      if not qryMain.EOF then
        Params:= Params + ', ';
    end;
    qryMain.Close;
    Result:= True;
  except
    on E: Exception do
    begin
      ShowMessage(e.Message);
      FConn.Close;
      Result:= False;
    end;
  end;
end;

(***********  Show Query window  ************)

function TfmMain.ShowQueryWindow(DatabaseIndex: Integer; aTitle: string): TfmQueryWindow;
var
  vRec     :TDBInfo;
  vTab     :TTabSheet;
  //vTab     :TKTabSheet;
  vCaption :string;
begin
  vRec := RegisteredDatabases[DatabaseIndex];
  vCaption:= vRec.RegRec.Title + ': ' + ATitle;

  // Search for already opened query window for the same title
  //Result := TfmQueryWindow(FindQueryWindow(vCaption));
  Result := TfmQueryWindow(_FindCustomForm(vCaption, TfmQueryWindow));
  if Result = nil then begin
    // No opened query window
    vTab               := NewTab(PageControl1, DatabaseIndex);//, vCaption); //TTBTabSheet.Create(self);
    Result             := TfmQueryWindow.Create(vTab);
    vTab.Caption       := vCaption;
    Result.Left        := 0;
    Result.Top         := 0;
    Result.Align       := alClient;
    Result.Font.Name   := 'Arial';
    Result.BorderStyle := bsNone;
    Result.Caption     := vCaption;
    //vTab.Parent        := PageControl1;
    Result.Parent      := vTab;
    //vTab.Tag           := DatabaseIndex;
  end else // Already opened query window found
    vTab := Result.Parent as TTabSheet;
  Result.Init(@RegisteredDatabases[DatabaseIndex]);
  vTab.Show;
  OpenSQLHistory(vRec.RegRec.Title);
  Result.Show;
end;

function TfmMain.ShowQueryWindow(const aDatabase :PDBInfo; aTitle :string) :TfmQueryWindow;
var
  vTab     :TTabSheet;
  vCaption :string;
begin
  vCaption:= aDatabase^.RegRec.Title + ': ' + ATitle;

  Result := TfmQueryWindow(_FindCustomForm(vCaption, TfmQueryWindow));
  if Result = nil then begin
    // No opened query window
    vTab               := NewTab(PageControl1, GetDBIndex(aDatabase^)); //TTBTabSheet.Create(self);
    Result             := TfmQueryWindow.Create(vTab);
    vTab.Caption       := vCaption;
    Result.Left        := 0;
    Result.Top         := 0;
    Result.Align       := alClient;
    Result.Font.Name   := 'Arial';
    Result.BorderStyle := bsNone;
    Result.Caption     := vCaption;
    Result.Parent      := vTab;
  end else // Already opened query window found
    vTab := Result.Parent as TTabSheet;
  Result.Init(aDatabase);
  vTab.Show;
  OpenSQLHistory(aDatabase^.RegRec.Title);
  Result.Show;
end;

(******* Fill Object Root, like (Tables, Views, etc)  ******)

procedure TfmMain.FillObjectRoot(aNode :TTreeNode);
var
  vRec                           :TDBDetails;
  vObjects                       :TStringList;
  vTableNode,   vItem,
  vGenNode,     vTrigNode,
  vViewsNode,   vStoredProcNode,
  vUDFNode,     vSysTableNode,
  vDomainsNode, vExceptionNode,
  vRoleNode,    vUserNode        :TTreeNode;
  i, vDBIndex,  vCount           :Integer;
  vNodeText                      :string;
begin
  //vDBIndex := PtrInt(aNode.Parent.Data);
  vDBIndex := GetDBIndex(aNode);
  //vRec := RegisteredDatabases[vDBIndex].RegRec;
  //vRec := RegisteredDatabases[GetDBIndex(aNode)].RegRec;
  Screen.Cursor:= crSQLWait;
  vObjects:= TStringList.Create;
  try //try..finally for making sure vObjects is released
    try //try..except for error reporting
      vNodeText:= aNode.Text;
      if Pos('(', vNodeText) > 0 then
        vNodeText:= Trim(Copy(vNodeText, 1, Pos('(', vNodeText) - 1));
                                                //otTables
      // Tables
      if vNodeText = 'Tables' then begin
        //vObjects.CommaText := dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otTables, vCount); //Jkoz:cleanup remove it after testing.
        vCount := dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otTables, vObjects);

        vTableNode := aNode;

        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';

        vTableNode.DeleteChildren;

        for i:= 0 to vObjects.Count - 1 do begin
          vItem := tvMain.Items.AddChildObject(vTableNode, vObjects[i], tobject(Integer(uTBTypes.otTables)));
          vItem.ImageIndex := 4;
          vItem.SelectedIndex := 4;
        end;

      end else if vNodeText = 'Generators' then  begin        // Generators
        vGenNode := aNode;
        vObjects.CommaText := dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otGenerators, vCount);
        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';
        vGenNode.DeleteChildren;
        for i:= 0 to vObjects.Count - 1 do begin
          vItem:= tvMain.Items.AddChild(vGenNode, vObjects[i]);
          vItem.ImageIndex:= 6;
          vItem.SelectedIndex:= 6;
        end;
      end else if aNode.Text = 'Triggers' then begin           // Triggers
        vTrigNode:= aNode;
        vObjects.CommaText:= dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otTriggers, vCount);
        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';
        vTrigNode.DeleteChildren;
        for i:= 0 to vObjects.Count - 1 do begin
          vItem:= tvMain.Items.AddChild(vTrigNode, vObjects[i]);
          vItem.ImageIndex:= 8;
          vItem.SelectedIndex:= 8;
        end;
      end else if aNode.Text = 'Views' then begin              // Views

        vViewsNode:= aNode;
        vObjects.CommaText:= dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otViews, vCount);
        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';
        vViewsNode.DeleteChildren;
        for i:= 0 to vObjects.Count - 1 do begin
          vItem:= tvMain.Items.AddChild(vViewsNode, vObjects[i]);
          vItem.ImageIndex:= 10;
          vItem.SelectedIndex:= 10;
        end;
      end else if aNode.Text = 'Stored Procedures' then begin  // Stored Procedures
        vStoredProcNode:= aNode;
        vObjects.CommaText:= dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otStoredProcedures, vCount);
        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';
        vStoredProcNode.DeleteChildren;
        for i:= 0 to vObjects.Count - 1 do begin
          vItem:= tvMain.Items.AddChild(vStoredProcNode, vObjects[i]);
          vItem.ImageIndex:= 12;
          vItem.SelectedIndex:= 12;
        end;
      end  else if aNode.Text = 'Functions' then begin         // UDF (Functions)
        vUDFNode := aNode;
        vObjects.CommaText := dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otUDFs, vCount);
        aNode.Text := vNodeText + ' (' + IntToStr(vCount) + ')';
        vUDFNode.DeleteChildren;
        for i := 0 to vObjects.Count - 1 do begin
          vItem:= tvMain.Items.AddChild(vUDFNode, vObjects[i]);
          vItem.ImageIndex:= 14;
          vItem.SelectedIndex:= 14;
        end;
      end else if aNode.Text = 'System Tables' then  begin     // System Tables
        vSysTableNode:= aNode;
        vObjects.CommaText:= dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otSystemTables, vCount);
        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';
        vSysTableNode.DeleteChildren;
        for i:= 0 to vObjects.Count - 1 do begin
          vItem:= tvMain.Items.AddChild(vSysTableNode, vObjects[i]);
          vItem.ImageIndex:= 16;
          vItem.SelectedIndex:= 16;
        end;
      end else
      if aNode.Text = 'Domains' then begin                     // Domains
        vDomainsNode:= aNode;
        vObjects.CommaText:= dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otDomains, vCount);
        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';
        vDomainsNode.DeleteChildren;
        for i:= 0 to vObjects.Count - 1 do begin
          vItem:= tvMain.Items.AddChild(vDomainsNode, vObjects[i]);
          vItem.ImageIndex:= 18;
          vItem.SelectedIndex:= 18;
        end;
      end else
      if aNode.Text = 'Roles' then begin                       // Roles
        vRoleNode:= aNode;
        vObjects.CommaText:= dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otRoles, vCount);
        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';
        vRoleNode.DeleteChildren;
        for i:= 0 to vObjects.Count - 1 do begin
          vItem:= tvMain.Items.AddChild(vRoleNode, vObjects[i]);
          vItem.ImageIndex:= 20;
          vItem.SelectedIndex:= 20;
        end;
      end else
        // Exceptions
      if aNode.Text = 'Exceptions' then
      begin
        vExceptionNode:= aNode;
        vObjects.CommaText:= dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otExceptions, vCount);
        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';
        vExceptionNode.DeleteChildren;
        for i:= 0 to vObjects.Count - 1 do
        begin
          vItem:= tvMain.Items.AddChild(vExceptionNode, vObjects[i]);
          vItem.ImageIndex:= 22;
          vItem.SelectedIndex:= 22;
        end;
      end
      else
        // Users
      if aNode.Text = 'Users' then
      begin
        vUserNode:= aNode;
        vObjects.CommaText:= dmSysTables.GetDBObjectNames(RegisteredDatabases[vDBIndex], otUsers, vCount);
        aNode.Text:= vNodeText + ' (' + IntToStr(vCount) + ')';
        vUserNode.DeleteChildren;
        for i:= 0 to vObjects.Count - 1 do
        begin
          vItem:= tvMain.Items.AddChild(vUserNode, vObjects[i]);
          vItem.ImageIndex:= 24;
          vItem.SelectedIndex:= 24;
        end;
      end;

      if not aNode.Expanded then
        aNode.Expand(False);
    except
      on E: Exception do
      begin
        Screen.Cursor:= crDefault;
        ShowMessage(e.Message);
      end;
    end;
  finally
    vObjects.Free;
    Screen.Cursor:= crDefault;
  end;
end;

(*************  Get main indices information  ******************)

function TfmMain.GetIndices(ATableName: string; AQuery: TSQLQuery): Boolean;
begin
  AQuery.Close;
  AQuery.SQL.Text:= 'SELECT * FROM RDB$INDICES WHERE RDB$RELATION_NAME=''' + UpperCase(ATableName) +
    ''' AND RDB$FOREIGN_KEY IS NULL';
  AQuery.Open;
  Result:= AQuery.RecordCount > 0;
  if not Result then
    AQuery.Close;
end;

function TfmMain.GetIndices(ATableName :string; const aQuery :TMDOQuery) :Boolean;
begin
  aQuery.Close;
  aQuery.SQL.Text:= 'SELECT * FROM RDB$INDICES WHERE RDB$RELATION_NAME=' + QuotedStr(UpperCase(ATableName)) +
                    ' AND RDB$FOREIGN_KEY IS NULL';
  aQuery.Open;
  Result:= aQuery.RecordCount > 0;
  if not Result then
    aQuery.Close;
end;

(***************  View Table Fields/ Fields Management  ***************)
{ todo: getting table field data should be moved to tablemanage.pas if possible; even better split out
between non-GUI query part and GUI updater part}
procedure TfmMain.ViewTableFields(ATableName: string; dbIndex: Integer; AStringGrid: TStringGrid);
var
  vFieldSize   : integer = 0;
  vFieldType   : string  = '';
  vCntr        : Integer;
  vPKFieldsList: TStringList;
  vDefaultValue: string;
  vPKIndexName : string;
  vConstraintName: string;

begin
  try
    Get_Fields(dbIndex, ATableName, nil);

    // Fill TableInfo grid
    AStringGrid.RowCount:= 1;
    with AStringGrid, qryMain do
    while not EOF do begin
      RowCount:= RowCount + 1;

      // Field Name
      Cells[1, RowCount - 1]:= Trim(FieldByName('Field_Name').AsString);

      // Field Type
      GetFieldType(qryMain, vFieldType, vFieldSize);
      Cells[2, RowCount - 1]:= vFieldType;

      // Computed fields (Calculated)
      if FieldByName('computed_source').AsString <> '' then
        Cells[2, RowCount - 1]:= FieldByName('computed_source').AsString;

      // Field Size
      if FieldByName('field_type_int').AsInteger in [CharType,CStringType,VarCharType] then
        Cells[3, RowCount - 1]:= FieldByName('CharacterLength').AsString
      else // why show byte size for numerical fields like integer fields?
        Cells[3, RowCount - 1]:= FieldByName('Field_Length').AsString;

      // Null/Not null
      if FieldByName('field_not_null_constraint').AsString = '1' then
        Cells[4, RowCount - 1]:= '0'
      else
        Cells[4, RowCount - 1]:= '1';

      // Default Value
      vDefaultValue:= FieldByName('Field_Default_Source').AsString;
      if Pos('default', vDefaultValue) > 0 then
        vDefaultValue:= Trim(StringReplace(vDefaultValue, 'default', '', []));
      Cells[5, RowCount - 1]:= vDefaultValue;

      Cells[6, RowCount - 1]:= FieldByName('Field_Description').AsString;
      Next;
    end;
    qryMain.Close;

    // Primary Keys
    vPKFieldsList:= TStringList.Create;
    try
      vPKIndexName:= GetPrimaryKeyIndexName(dbIndex, ATableName, vConstraintName);
      if vPKIndexName <> '' then
        GetConstraintFields(ATableName, vPKIndexName, vPKFieldsList);

      with AStringGrid do
      for vCntr:= 1 to RowCount - 1 do
        if vPKFieldsList.IndexOf(Cells[1, vCntr]) <> -1 then
          Cells[0, vCntr]:= '1'
        else
          Cells[0, vCntr]:= '0';
    finally
      vPKFieldsList.Free;
    end;
  except
    on E: Exception do
      MessageDlg('Error while reading table fields: ' + e.Message, mtError, [mbOk], 0);
  end;
end;


(*************   Display View DDL *******************)

procedure TfmMain.lmDisplayViewClick(Sender: TObject);
var
  SelNode: TTreeNode;
  Rec: TDBInfo;
  AViewName: string;
  ViewBody, Columns: string;
  dbIndex: Integer;
  ATab: TTabSheet;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
    Rec:= RegisteredDatabases[dbIndex];
    AViewName:= SelNode.Text;

    // Fill ViewView grid
    ATab:= NewTab(PageControl1,dbIndex); //TTBTabSheet.Create(self);
    //ATab.Parent:= PageControl1;
    fmViewView:= TfmViewView.Create(nil);
    fmViewView.Parent:= ATab;
    fmViewView.Left:= 0;
    fmViewView.Top:= 0;
    fmViewView.BorderStyle:= bsNone;
    fmViewView.Align:= alClient;
    fmViewView.SynSQLSyn1.TableNames.CommaText:= GetTableNames(dbIndex);
    fmViewView.Caption:= 'View DDL: ' + AViewName;
    ATab.Caption:= fmViewView.Caption;
    fmViewView.edName.Caption:= AViewName;
    //ATab.Tag:= dbIndex;

    GetViewInfo(dbIndex, AViewName, Columns, ViewBody);
    fmViewView.seScript.Lines.Clear;
    fmViewView.seScript.Lines.Text:= 'create view "' + AviewName + '" (' + Columns + ')' + LineEnding + ViewBody;
    PageControl1.ActivePage:= ATab;
    fmViewView.Show;
  end;

end;

(***************  ExpandFields: Expand table fields  ************)

procedure TfmMain.lmViewFieldsClick(Sender: TObject);
var
  Node: TTreeNode;
  dbIndex: Integer;
  FieldTitle: string;
  FieldNode: TTreeNode;
  PKFieldsList: TStringList;
  PKIndexName: string;
  ConstraintName: string;
  AFieldName: string;
  i: Integer;
  LenStr: string;
begin
  try
    Node:= tvMain.Selected;
    dbIndex:= PtrInt(Node.Parent.Parent.Data);
    Node.DeleteChildren;

    // Primary Keys
    PKFieldsList:= TStringList.Create;
    try
      PKIndexName:= GetPrimaryKeyIndexName(dbIndex, Node.Text, ConstraintName);
      if PKIndexName <> '' then
        GetConstraintFields(Node.Text, PKIndexName, PKFieldsList);

      // Fields
      Get_Fields(dbIndex, Node.Text, nil);
      i:= 1;
      with qryMain do
      while not EOF do
      begin
        AFieldName:= Trim(FieldByName('Field_Name').AsString);

        if (FieldByName('field_type_int').AsInteger) in [CharType, CStringType, VarCharType] then
          LenStr:= FieldByName('CharacterLength').AsString
        else
          {note: this shows number of bytes for numerical datatypes. Is this really wanted?
          It's very awkward e.g. for decimal: e.g. Decimal(12,2) 8 }
          LenStr:= FieldByName('Field_Length').AsString;

        // Array datatype:
        if not(FieldByName('array_upper_bound').IsNull) then
          LenStr:= LenStr + ' [' + FieldByName('array_upper_bound').AsString + '] ';

        FieldTitle:= AFieldName + '   ' +
        GetFBTypeName(qryMain.FieldByName('field_type_int').AsInteger,
          qryMain.FieldByName('field_sub_type').AsInteger,
          qryMain.FieldByName('field_length').AsInteger,
          qryMain.FieldByName('field_precision').AsInteger,
          qryMain.FieldByName('field_scale').AsInteger) +
          ' ' + LenStr;
        FieldNode:= tvMain.Items.AddChild(Node, FieldTitle);
        FieldNode.Data:= Pointer(i); //store field order in node's data property

        // Visually distinguish primary keys
        if PKFieldsList.IndexOf(AFieldname) <> -1 then
        begin
          FieldNode.ImageIndex:= 28;
          FieldNode.SelectedIndex:= 28;
        end
        else
        begin
          FieldNode.ImageIndex:= 27;
          FieldNode.SelectedIndex:= 27;
        end;
        Inc(i);
        Next;
      end;
      qryMain.Close;
      Node.Expand(False);
    finally
      PKFieldsList.Free;
    end;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;


(***************  View Generator  *****************)

procedure TfmMain.lmViewGenClick(Sender: TObject);
var
  SelNode: TTreeNode;
  Rec: TDBInfo;
  AGenName: string;
  dbIndex: Integer;
  ATab: TTabSheet;
  Title: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
    Rec:= RegisteredDatabases[dbIndex];
    qryMain.Close;
    SetConnection(dbIndex);
    AGenName:= SelNode.Text;
    qryMain.SQL.Text:= 'select GEN_ID(' + AGenName + ', 0) from RDB$Database;';
    qryMain.Open;

    // Fill ViewGen form
    Title:= 'Generator : ' + AGenName;
    fmViewGen:= FindCustomForm(Title, TfmViewGen) as TfmViewGen;
    if fmViewGen = nil then
    begin
      fmViewGen:= TfmViewGen.Create(Application);
      ATab:= NewTab(PageControl1,dbIndex); //TTBTabSheet.Create(self);
      //ATab.Parent:= PageControl1;
      fmViewGen.Parent:= ATab;
      fmViewGen.Left:= 0;
      fmViewGen.Top:= 0;
      fmViewGen.BorderStyle:= bsNone;
      fmViewGen.Align:= alClient;
    end
    else
      ATab:= fmViewGen.Parent as TTabSheet;
    PageControl1.ActivePage:= ATab;
    //ATab.Tag:= dbIndex;

    with fmViewGen do
    begin
      Caption:= Title;
      ATab.Caption:= Caption;
      edGenName.Caption:= AGenName;
      edValue.Caption:= qryMain.Fields[0].AsString;
    end;
    ATab.Caption:= Title;
    fmViewGen.Show;
  end;

end;

(*******************  view Stored Procedure  ****************************)

procedure TfmMain.lmViewStoredProcedureClick(Sender: TObject);
var
  SelNode: TTreeNode;
  AProcName: string;
  SPOwner: string;
  spBody: string;
  dbIndex: Integer;
  ATab: TTabSheet;
  Title: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    AProcName:= SelNode.Text;
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
    SPBody:= GetStoredProcBody(dbIndex, AProcName, SPOwner);
    Title:= SelNode.Parent.Parent.Text +  ': StoredProcedure : ' + AProcName;
    // Fill SProc Parameters
    fmViewSProc:= FindCustomForm(Title, TfmViewSProc) as TfmViewSProc;
    if fmViewSProc = nil then
    begin
      fmViewSProc:= TfmViewSProc.Create(Application);
      ATab:= NewTab(PageControl1,dbIndex); //TTBTabSheet.Create(self);
      //ATab.Parent:= PageControl1;
      fmViewSProc.Parent:= ATab;
      fmViewSProc.Left:= 0;
      fmViewSProc.Top:= 0;
      fmViewSProc.BorderStyle:= bsNone;
      fmViewSProc.Align:= alClient;
    end
    else
      ATab:= fmViewSProc.Parent as TTabSheet;
    PageControl1.ActivePage:= ATab;
    with fmViewSProc do
    begin
      SynSQLSyn1.TableNames.CommaText:= GetTableNames(dbIndex);
      Caption:= Title;
      ATab.Caption:= Caption;
      //ATab.Tag:= dbIndex;
      edName.Caption:= AProcName;
      seScript.Lines.Clear;
      seScript.Lines.Add('create procedure ' + AProcName + '(');
      edOwner.Caption:= SPOwner;

      // Procedure body
      seScript.Lines.Text:= seScript.Lines.Text + spBody;

      fmViewSProc.Show;
    end; // with fmViewSProc
  end;

end;


(*******************  View Trigger   **********************)

procedure TfmMain.lmViewTriggerClick(Sender: TObject);
var
  SelNode: TTreeNode;
  ATriggerName: string;
  Event: string;
  TriggerEnabled: Boolean;
  Body: string;
  BeforeAfter: string;
  OnTable: string;
  TriggerPosition: Integer;
  ATab: TTabSheet;
  Title: string;
  dbIndex: Integer;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    ATriggerName:= SelNode.Text;
    Title:= SelNode.Parent.Parent.Text +  ': Trigger : ' + ATriggerName;
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);
    dmSysTables.GetTriggerInfo(dbIndex, ATriggerName, BeforeAfter, OnTable,
                               Event, Body, TriggerEnabled, TriggerPosition);

    // Fill ViewTrigger form
    fmViewTrigger:= FindCustomForm(Title, TfmViewTrigger) as TfmViewTrigger;
    if fmViewTrigger = nil then
    begin
      fmViewTrigger:= TfmViewTrigger.Create(Application);
      ATab:= NewTab(PageControl1,dbIndex);//TTBTabSheet.Create(self);
      //ATab.Parent:= PageControl1;
      fmViewTrigger.Parent:= ATab;
      fmViewTrigger.Left:= 0;
      fmViewTrigger.Top:= 0;
      fmViewTrigger.BorderStyle:= bsNone;
      fmViewTrigger.Align:= alClient;
    end
    else
      ATab:= fmViewTrigger.Parent as TTabSheet;

    PageControl1.ActivePage:= ATab;
    //ATab.Tag:= dbIndex;
    with fmViewTrigger do
    begin
      Caption:= Title;
      ATab.Caption:= Caption;
      edName.Caption:= ATriggerName;
      edOnTable.Caption:= OnTable;
      laEvent.Caption:= Event;
      laType.Caption:= BeforeAfter;
      laPos.Caption:= IntToStr(TriggerPosition);
      seScript.Lines.Text:= Body;
      if TriggerEnabled then
      begin
        laEnabled.Caption:= 'Yes';
        laEnabled.Font.Color:= clGreen;
      end
      else
      begin
        laEnabled.Caption:= 'No';
        laEnabled.Font.Color:= clRed;
      end;
    end;
    fmViewTrigger.Show;
  end;

end;

(********  View UDF  **********)

procedure TfmMain.lmViewUDFClick(Sender: TObject);
var
  SelNode: TTreeNode;
  AFuncName: string;
  ModuleName, EntryPoint: string;
  Params: string;
  ATab: TTabSheet;
  dbIndex: Integer;
  Title: string;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    AFuncName:= SelNode.Text;
    Title:= SelNode.Parent.Parent.Text + ': UDF: ' + AFuncName;
    dbIndex:= PtrInt(SelNode.Parent.Parent.Data);

    if GetUDFInfo(dbIndex, AFuncName, ModuleName, EntryPoint, Params) then
    with fmUDFINfo do
    begin
      fmUDFInfo:= FindCustomForm(Title, TfmUDFInfo) as TfmUDFInfo;
      if fmUDFInfo = nil then
      begin
        fmUDFInfo:= TfmUDFInfo.Create(Application);
        fmUDFInfo.Caption:= Title;
        ATab:= NewTab(PageControl1,DBIndex);// TControl; //TTBTabSheet.Create(self);
        //ATab.Tag := dbIndex;
        //ATab.Parent:= PageControl1;
        fmUDFInfo.Parent:= ATab;
        fmUDFInfo.Left:= 0;
        fmUDFInfo.Top:= 0;
        fmUDFInfo.BorderStyle:= bsNone;
        fmUDFInfo.Align:= alClient;
      end
      else
        ATab:= fmUDFInfo.Parent as TTabSheet;

      PageControl1.ActivePage:= ATab;
      ATab.Caption:= Title;
      edName.Caption:= AFuncName;
      edModule.Caption:= ModuleName;
      edEntry.Caption:= EntryPoint;
      meBody.Clear;
      meBody.Lines.Add('function ' + AFuncName + '(');
      meBody.Lines.Add(Params);
      fmUDFInfo.Show;
    end; // with fmUDFInfo
  end;
end;

procedure TfmMain.lmDropTableClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
begin
  SelNode:= tvMain.Selected;
  if MessageDlg('Are you sure you want to delete ' + SelNode.Text + ' permanently', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    // Move selection to tables above so object is not in use when deleting it
    SelNode.Collapse(true);
    SelNode.Parent.Selected:=true;
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Parent.Data), 'Drop Table');
    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('DROP TABLE ' + SelNode.Text + ';');
    QWindow.Show;
  end;
end;

procedure TfmMain.lmRecalculateStatisticsClick(Sender: TObject);
var
  Message: string;
begin
  //Recalculate index statistics. May take a while for big dbs.
  Message:= '';
  Screen.Cursor:= crSQLWait;
  try
    try
      dmSysTables.RecalculateIndexStatistics(PtrInt(tvMain.Selected.Data));
    except
      on E: Exception do
      begin
        Message:= E.Message
      end;
    end;
  finally
    Screen.Cursor:= crDefault;
  end;
  if Message='' then
    ShowMessage('Recalculation of index statistics complete.')
  else
    ShowMessage('Error recalculating index statistics: '+Message);
end;

(********  Create new database  ********)

(**********  Register New database  ***********)

(**********  About  ****************)

(************* Edit Registration  *************)

procedure TfmMain.lmEditRegClick(Sender: TObject);
var
  Rec: TDBDetails;
  SelNode: TTreeNode;
  vRegDlg : TfmReg;
begin
  vRegDlg := TfmReg.Create(nil);
  try
  SelNode:= tvMain.Selected;
  if SelNode <> nil then
  begin
    vRegDlg.NewReg:= False;
    vRegDlg.bbReg.Caption:= 'Save';
    vRegDlg.RecPos:= RegisteredDatabases[PtrInt(SelNode.Data)].Index;

    Rec:= RegisteredDatabases[PtrInt(SelNode.Data)].OrigRegRec;
    vRegDlg.edDatabaseName.Text:= Rec.DatabaseName;
    vRegDlg.edTitle.Text:= Rec.Title;
    vRegDlg.edUserName.Text:= Rec.UserName;
    vRegDlg.edPassword.Text:= Rec.Password;
    vRegDlg.cbCharset.Text:= Rec.Charset;
    vRegDlg.edRole.Text:= Rec.Role;
    vRegDlg.cxSavePassword.Checked:= Rec.SavePassword;

    if vRegDlg.ShowModal = mrOK then
    begin
      LoadRegisteredDatabases;
      vRegDlg.SaveRegistrations;
      LoadRegisteredDatabases;
    end;
  end;

  finally
    vRegDlg.Free;
  end;
end;


(****************  Unregister database *************)

procedure TfmMain.lmUnregisterDatabaseClick(Sender: TObject);
var
  SelNode: TTreeNode;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) and (SelNode.Parent.Parent = nil) then
  if MessageDlg('Are you sure you want to Unregister this database', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    DeleteRegistration(RegisteredDatabases[PtrInt(SelNode.Data)].Index);
    LoadRegisteredDatabases;
  end;
  SelNode:= nil;
end;

procedure TfmMain.PageControl1Changing(Sender :TObject; var AllowChange :Boolean);
//var
//  vIdx:integer;
begin
  //if Button = mbMiddle then begin
  //  vIdx := PageControl1.TabIndexAtClientPos(Point(X, Y));
  //  if vIdx > -1 then PageControl1.Pages[vIdx].Free;//  CloseTab(vIdx);
  //end;
  FOldPage := TPageControl(Sender).PageIndex;
  // return the toolbar to the control (ee change parent).
  //TPageControl(Sender).ActivePage.FindChildControl();
end;

(**********  View 1000 records  **************)

procedure TfmMain.lmViewFirst1000Click(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Parent.Data), 'Select first 1000 from ' + SelNode.Text);
    QWindow.meQuery.Lines.Text:= 'select first 1000 * from "' + SelNode.Text + '"';
    QWindow.bbRunClick(nil);
    QWindow.Show;
  end;
end;

(***********  Create New Role   ************)

procedure TfmMain.lmNewRoleClick(Sender: TObject);
var
  SelNode: TTreeNode;
  QWindow: TfmQueryWindow;
begin
  SelNode:= tvMain.Selected;
  if (SelNode <> nil) and (SelNode.Parent <> nil) then
  begin
    QWindow:= ShowQueryWindow(PtrInt(SelNode.Parent.Data), 'Create new Role');
    QWindow.meQuery.Lines.Clear;
    QWindow.meQuery.Lines.Add('CREATE ROLE role_name;');
    QWindow.Show;
  end;
end;

procedure TfmMain.PageControl1Change(Sender :TObject);
begin
  // this is never executed why?
  if PageControl1.ActivePage = nil then
    PageControl1.ActivePage := tbMain;
  //take the toolbar and attach it to the coolbar.
end;

procedure TfmMain.PageControl1CloseTabClicked(Sender: TObject);
//var
//  i: Integer;
begin
  //for i:= 0 to Application.ComponentCount - 1 do
  //  if Application.Components[i] is TfmQueryWindow then
  //  begin
  //    (Application.Components[i] as TfmQueryWindow).lmCloseTabClick(nil);
  //    Break;
  //  end;
end;

procedure TfmMain.PageControl1MouseUp(Sender :TObject; Button :TMouseButton; Shift :TShiftState; X, Y :Integer);
var
  vIdx:integer;
begin
  if Button = mbMiddle then begin
    vIdx := PageControl1.TabIndexAtClientPos(Point(X, Y));
    if vIdx > -1 then PageControl1.Pages[vIdx].Free;//  CloseTab(vIdx);
  end;
end;

(*****************   Database Popup menu   ********************)

procedure TfmMain.pmDatabasePopup(Sender: TObject);
var
  SelNode: TTreeNode;
  Filter: Integer;
  i: Integer;
  ParentNodeText: string;
  NodeText: string;

begin
  SelNode:= tvMain.Selected;

  if SelNode <> nil then
  begin
    NodeText:= SelNode.Text;
    if Pos('(', NodeText) > 0 then
      NodeText:= Trim(Copy(NodeText, 1, Pos('(', NodeText) - 1));

    ParentNodeText:= '';
    if SelNode.Parent <> nil then
      ParentNodeText:= SelNode.Parent.Text;
    if Pos('(', ParentNodeText) > 0 then
      ParentNodeText:= Trim(Copy(ParentNodeText, 1, Pos('(', ParentNodeText) - 1));

    if (SelNode <> nil) then
    if (SelNode.Parent = nil) then // Servers
      Filter:= -2
    else
    if (SelNode.Parent.Parent = nil) then // Database
      Filter:= 0
    else
    if ParentNodeText = 'Tables' then // Tables
      Filter:= 1
    else
    if ParentNodeText = 'Generators' then // Generators
      Filter:= 2
    else
    if ParentNodeText = 'Triggers' then // Triggers
      Filter:= 3
    else
    if ParentNodeText = 'Views' then // View
      Filter:= 4
    else
    if ParentNodeText = 'Stored Procedures' then // Stored Proc
      Filter:= 5
    else
    if ParentNodeText = 'Functions' then // UDF
      Filter:= 6
    else
    if ParentNodeText = 'System Tables' then // System Tables
      Filter:= 7
    else
    if ParentNodeText = 'Domains' then // Domains
      Filter:= 8
    else
    if ParentNodeText = 'Roles' then // Roles
      Filter:= 9
    else
    if ParentNodeText = 'Exceptions' then // Roles
      Filter:= 10
    else
    if ParentNodeText = 'Users' then // Users
      Filter:= 111
    else
    if NodeText = 'Tables' then // Tables root              //  Higher level (Roots)
      Filter:= 11
    else
    if NodeText = 'Generators' then // Generators root
      Filter:= 12
    else
    if NodeText = 'Stored Procedures' then // Stored Proc root
      Filter:= 15
    else
    if NodeText = 'Functions' then // UDF root
      Filter:= 16
    else
    if NodeText = 'Views' then // Views root
      Filter:= 14
    else
    if NodeText = 'Triggers' then // Triggers root
      Filter:= 13
    else
    if NodeText = 'Domains' then // Domains root
      Filter:= 18
    else
    if NodeText = 'Roles' then // Roles root
      Filter:= 19
    else
    if NodeText = 'Exceptions' then // Exceptions
      Filter:= 20
    else
    if NodeText = 'Users' then // Users
      Filter:= 21
    else
    if NodeText = 'Query Window' then // Query Window
      Filter:= 30
    else
      Filter:= -1;

    // Table Fields
    if (SelNode.Level = 4) then
    begin
      ParentNodeText:= SelNode.Parent.Parent.Text;
      if Pos('(', ParentNodeText) > 0 then
        ParentNodeText:= Trim(Copy(ParentNodeText, 1, Pos('(', ParentNodeText) - 1));
      if (ParentNodeText = 'Tables') then
        Filter:= 112;
    end;


  end
  else
    Filter:= -1;

  // Show menu for specific filter
  for i:= 0 to pmDatabase.Items.Count - 1 do
    pmDatabase.Items[i].Visible:= (pmDatabase.Items[i].Tag = Filter) or
      ((pmDatabase.Items[i].Tag = 100) and (SelNode <> nil) and (SelNode.Parent <> nil) and
      (SelNode.Parent.Parent <> nil) and (SelNode.Parent.Parent.Parent = nil));


  SelNode:= nil;
end;


(**********************            Double click        *********************************)

procedure TfmMain.tvMainDblClick(Sender: TObject);
var
  QWindow: TfmQueryWindow;
  Rec: TDBDetails;
  Node: TTreeNode;
  ParentText: string;
begin
  Node := tvMain.Selected;
  if node <> nil then begin
    case Node.Level of
      1: ;//begin
         // Database level: fill objects;
      2: begin // Objects Type Level
           if tvMain.Selected.Text = 'Query Window' then begin
             QWindow:= ShowQueryWindow(PtrInt(tvMain.Selected.Parent.Data), 'Query Window');
             QWindow.Show;
           end else begin // Expand object
             tvMainExpanded(nil, Node);
             Rec := RegisteredDatabases[PtrInt(Node.Parent.Data)].RegRec;
           end;
         end;
      3: begin // Object Item Level, like tables, procedures....
           ParentText:= Node.Parent.Text;
           if Pos('(', ParentText) > 0 then
             ParentText:= Trim(Copy(ParentText, 1, Pos('(', ParentText) - 1));
           case ParentText of
             'Tables': begin
               lmViewFieldsClick(nil);
               //lmViewFirst1000Click(nil);       // add a way to allow the end user to select what to do.
               lmTableManageClick(Nil);//lets make sure we are in management mode. add a short cut for the query window
             end;
             'Generators'        : lmViewGenClick(nil);
             'Triggers'          : lmViewTriggerClick(nil);
             'Views'             : lmDisplay1000VClick(nil);
             'Stored Procedures' : lmViewStoredProcedureClick(nil);
             'Functions'         : lmViewUDFClick(nil);
             'System Tables'     : begin
               lmViewFieldsClick(nil); // also works for system tables
               lmOpenSystemTableClick(nil);
             end;
             'Domains'    :lmViewDomainClick(nil);
             'Roles'      :lmPermissionsClick(nil);
             'Exceptions' :lmScriptExceptionClick(nil);
             'Users'      :lmPermissionsClick(nil);
             else ShowMessage('Error in TurboBird code tVMainDblClick level 3. Please correct.');
           end;
         end;
      4: begin     // Table fields (Edit)
           lmEditFieldClick(nil);
         end;
      //else
      //begin
      //  // do nothing; ignore
      //end;
    end;
  end;
end;

(**************    Expanded     *****************)

procedure TfmMain.tvMainExpanded(Sender: TObject; Node: TTreeNode);
var
  Rec: TDBDetails;
begin
  if (Node <> nil) then
  if (Node.Parent <> nil) and (Node.Parent.Parent = nil) then   // Expand database    { TODO -ojkoz -cInternals : Mark and recognization method change }
  begin
    Rec:= RegisteredDatabases[PtrInt(Node.Data)].RegRec;
    RegisteredDatabases[PtrInt(Node.Data)].RegRec.LastOpened:= Now;
    RegisteredDatabases[PtrInt(Node.Data)].OrigRegRec.LastOpened:= Now;
    // Password form
    if Rec.Password = '' then
    if ConnectToDBAs(PtrInt(Node.Data)) then
      Node.Expand(False)
    else
      Node.Collapse(False);
  end
  else  // Expand objects root (Tables, Procedures, etc)
  if (Node.Parent <> nil) and (Node.Parent.Parent <> nil) and
     (Node.Parent.Parent.Parent = nil) and (not Node.Expanded) then
  begin
    if Node.HasChildren then
    begin
      Node.DeleteChildren;
      Node.Text:= Trim(Copy(Node.Text, 1, Pos('(', Node.Text) - 1));
    end;
    FillObjectRoot(Node);
  end;
end;

procedure TfmMain.GlobalException(Sender: TObject; E : Exception);
begin
  MessageDlg('Exception', e.Message, mtError, [mbOk], 0);
end;

(**********************             Load databases            *********************************)

function TfmMain.LoadRegisteredDatabases: Boolean;
var
  Rec: TDBDetails;
  F: file of TDBDetails;
  FileName: string;
  MainNode, CNode: TTreeNode;
  i: Integer;
  AServerName: string;
  ServerNode: TTreeNode;
begin
  try
    tvMain.Items.Clear;
    ReleaseRegisteredDatabases;
    FileName := getConfigurationDirectory + ChangeFileExt(GetConfigFileName,'.reg');// 'turbobird.reg';

    // Copy old configuration file
    if not FileExists(FileName) and (FileExists(ChangeFileExt(ParamStr(0), '.reg'))) then
    begin
      CopyFile(ChangeFileExt(ParamStr(0), '.reg'), FileName);
    end;

    AssignFile(F, FileName);
    if FileExists(FileName) then
    begin
      Reset(F);
      i:= 0;
      while not system.EOF(F) do begin
        Read(F, Rec);
        if not Rec.Deleted then begin
          SetLength(RegisteredDatabases, Length(RegisteredDatabases) + 1);
          with RegisteredDatabases[high(RegisteredDatabases)] do begin
            RegRec:= Rec;
            OrigRegRec:= Rec;
            Index:= FilePos(F) - 1;
            //JKOZ :01.002
            Conn := GetConnection(RegisteredDatabases[high(RegisteredDatabases)]); //TMDODataBase.Create(Nil); //TIBConnection.Create(nil);
            {$IFDEF DEBUG}
            {$WARNING 'Enable Logging of commands'} //JKOZ
            //Conn.OnLog := @GetLogEvent;
            //Conn.LogEvents := [detCustom,detExecute,detCommit,detRollBack];
            Conn.TraceFlags := [tfQPrepare, tfQExecute, tfQFetch, tfError, tfStmt, tfMisc];
            //tfConnect, tfTransact, tfBlob, tfService
            {$ENDIF DEBUG}
            Trans:= TMDOTransaction.Create(nil);//TSQLTransaction.Create(nil);
            SetTransactionIsolation(Trans.Params);
            Conn.DefaultTransaction:= Trans;
            Trans.DefaultDatabase := Conn;
          end;

          // Server node
          AServerName := GetServerName(Rec.DatabaseName);

          ServerNode := GetServerNameNode(AServerName);
          if ServerNode = nil then // Add new Server node
          begin
            tvMain.Items.Add(nil, '');
            ServerNode:= tvMain.Items.Add(nil, AServerName);
            ServerNode.ImageIndex:= 25;
            ServerNode.SelectedIndex:= 26;
          end;

          // Display databases
          MainNode:= tvMain.Items.AddChild(ServerNode, Rec.Title);
          MainNode.ImageIndex:= 0;
          MainNode.SelectedIndex:= 3;
          MainNode.Data:= Pointer(i);
          tvMain.PopupMenu:= pmDatabase;

          CNode:= tvMain.Items.AddChild(MainNode, 'Query Window');
          CNode.ImageIndex:= 1;
          CNode.SelectedIndex:= 1;

          CNode:= tvMain.Items.AddChild(MainNode, 'Tables');
          CNode.ImageIndex:= 2;
          CNode.SelectedIndex:= 2;

          CNode:= tvMain.Items.AddChild(MainNode, 'Generators');
          CNode.ImageIndex:= 5;
          CNode.SelectedIndex:= 5;

          CNode:= tvMain.Items.AddChild(MainNode, 'Triggers');
          CNode.ImageIndex:= 7;
          CNode.SelectedIndex:= 7;

          CNode:= tvMain.Items.AddChild(MainNode, 'Views');
          CNode.ImageIndex:= 9;
          CNode.SelectedIndex:= 9;

          CNode:= tvMain.Items.AddChild(MainNode, 'Stored Procedures');
          CNode.ImageIndex:= 11;
          CNode.SelectedIndex:= 11;

          CNode:= tvMain.Items.AddChild(MainNode, 'Functions');
          CNode.ImageIndex:= 13;
          CNode.SelectedIndex:= 13;

          CNode:= tvMain.Items.AddChild(MainNode, 'System Tables');
          CNode.ImageIndex:= 15;
          CNode.SelectedIndex:= 15;

          CNode:= tvMain.Items.AddChild(MainNode, 'Domains');
          CNode.ImageIndex:= 17;
          CNode.SelectedIndex:= 17;

          CNode:= tvMain.Items.AddChild(MainNode, 'Roles');
          CNode.ImageIndex:= 19;
          CNode.SelectedIndex:= 19;

          CNode:= tvMain.Items.AddChild(MainNode, 'Exceptions');
          CNode.ImageIndex:= 21;
          CNode.SelectedIndex:= 21;

          CNode:= tvMain.Items.AddChild(MainNode, 'Users');
          CNode.ImageIndex:= 23;
          CNode.SelectedIndex:= 23;

          Inc(i);
        end;
      end;
      CloseFile(F);

      // Add spaces at end of tree
      tvMain.Items.Add(nil, '');
      tvMain.Items.Add(nil, '');
      tvMain.Items.Add(nil, '');
    end;
    Result:= True;
  except
    on E: Exception do
    begin
      Result:= False;
      ShowMessage('Error: ' + E.Message);
    end;
  end;
end;

function TfmMain.LoadRegisteredDatabases2 :Boolean;

  function AppendNode(aParent:TTreeNode; aTitle:String; aImageIndex,aSelectedIndex:Integer; aData:Pointer):TTreeNode;inline;
  begin
    Result := aParent.TreeNodes.AddChild(aParent, aTitle);
    Result.ImageIndex   := aImageIndex;
    Result.SelectedIndex:= aSelectedIndex;
    Result.Data := aData;
  end;

  procedure RebuildTree;
  var
    vNode,
    vParentNode : TTreenode;
    vCntr       : Integer;
  begin
    tvMain.Items.Clear;
    for vCntr := low(RegisteredDatabases) to high(RegisteredDatabases) do begin;
      // Server node
      tvMain.Items.Add(nil, '');
      vParentNode := AppendNode(nil, GetServerName(RegisteredDatabases[vCntr].RegRec.DatabaseName), 25, 26, nil);
      vParentNode := AppendNode(vParentNode, RegisteredDatabases[vCntr].RegRec.Title, 0, 3, Pointer(vCntr));

      vNode := AppendNode(vParentNode, rsotQueryWindow,   1, 1,  Pointer(-1));
      vNode := AppendNode(vParentNode, rsotTables,        2, 2,  Pointer(Ord(otTables)));
      vNode := AppendNode(vParentNode, rsotGenerators,    5, 5,  Pointer(Ord(otGenerators)));
      vNode := AppendNode(vParentNode, rsotTriggers,      7, 7,  Pointer(Ord(otTriggers)));
      vNode := AppendNode(vParentNode, rsotViews,         9, 9,  Pointer(Ord(otViews)));
      vNode := AppendNode(vParentNode, rsotStoredProced, 11, 11, Pointer(Ord(otStoredProcedures)));
      vNode := AppendNode(vParentNode, rsotFunctions,    13, 13, Pointer(Ord(otUDFs)));
      vNode := AppendNode(vParentNode, rsotSystemTables, 15, 15, Pointer(-2));
      vNode := AppendNode(vParentNode, rsotDomains,      17, 17, Pointer(Ord(otDomains)));
      vNode := AppendNode(vParentNode, rsotRoles,        19, 19, Pointer(Ord(otRoles)));
      vNode := AppendNode(vParentNode, rsotExceptions,   21, 21, Pointer(Ord(otExceptions)));
      vNode := AppendNode(vParentNode, rsotUsers,        21, 21, Pointer(Ord(otUsers)));
    end;
    tvMain.PopupMenu:= pmDatabase;
    // Add spaces at end of tree //JKOZ: Why?
    tvMain.Items.Add(nil, '');
    tvMain.Items.Add(nil, '');
    tvMain.Items.Add(nil, '');
  end;

//var
  //Rec: TDBDetails;
  //F: file of TDBDetails;
  //FileName: string;
  //MainNode, CNode: TTreeNode;
  //i: Integer;
  //AServerName: string;
  //ServerNode: TTreeNode;

begin
  try
    ReleaseRegisteredDatabases;
    LoadRegistrations(RegisteredDatabases);
    RebuildTree;
    Result := True;
  except
    on E: Exception do
    begin
      Result:= False;
      ShowMessage('Error: ' + E.Message);
    end;
  end;
end;


(**********************           Find QueryWindow                *********************************)

function TfmMain.FindQueryWindow(ATitle: string): TComponent;
//var
//  vCntr: Integer;
begin
  //Result:= nil;
  //for vCntr := 0 to Application.ComponentCount - 1 do
  //  if Application.Components[vCntr] is TfmQueryWindow then
  //    if (Application.Components[vCntr] as TfmQueryWindow).Caption = ATitle then begin
  //      Result := Application.Components[vCntr];
  //      Break;
  //    end;
end;

(**********************   Find CustomForm   *********************************)

function TfmMain.FindCustomForm(aTitle: string; aClass: TClass): TComponent;
var
  vCntr: Integer;
begin
  //JKoz : all forms are registeres with the screen global object but not all the forms register the application as owner.
  Result := nil;
  if aClass.InheritsFrom(TForm) then Result := _FindCustomForm(aTitle, TFormClass(aClass))
  else //old code. Remove it in a future update for simplification.
    for vCntr:= 0 to Application.ComponentCount- 1 do begin
      if Application.Components[vCntr] is AClass then
        if (Application.Components[vCntr] as TForm).Caption = ATitle then begin
          Result := Application.Components[vCntr];
          Break;
        end;
    end;
end;

function TfmMain._FindCustomForm(aTitle :string; aClass :TFormClass) :TForm;
var
  vCntr: Integer;
begin
  Result:= nil;
  for vCntr:= 0 to Screen.FormCount - 1 do begin
    if Screen.Forms[vCntr] is AClass then
      if Screen.Forms[vCntr].Caption = ATitle then begin
        Result:= Screen.Forms[vCntr];
        Break;
      end;
  end;
end;

(****************  Delete Registration   *************************)
//JKOZ:DBRegistration
function TfmMain.DeleteRegistration(Index: Integer): Boolean;
var
  F: file of TDBDetails;
  Rec: TDBDetails;
  FileName: string;
begin
  Result:= False;
  FileName:= getConfigurationDirectory + 'turbobird.reg';

  AssignFile(F, FileName);
  if FileExists(FileName) then
  begin
    FileMode:= 2;
    Reset(F);
    Seek(F, Index);
    Read(F, Rec);
    Rec.Deleted:= True;
    Seek(F, Index);
    Write(F, Rec);
    CloseFile(F);
    Result:= True;
  end;
end;

function TfmMain.GetBlobSubTypeName(SubType: integer): string;
begin
  case SubType of
    //<0: user-defined
    0: Result:= 'SUB_TYPE BINARY';
    1: Result:= 'SUB_TYPE TEXT';
    2: Result:= 'SUB_TYPE BLR'; //(used for definitions of Firebird procedures, triggers, etc.
    //>2: reserved by Firebird
    else Result:= ''; //unknown
  end;
end;


(*******************  Get Primary Key fields  ************************)

function TfmMain.GetPrimaryKeyIndexName(DatabaseIndex: Integer; ATableName: string; var ConstraintName: string): string;
begin
  qryMain.Close;
  SetConnection(DatabaseIndex);
  qryMain.SQL.Text:= 'select RDB$Index_name, RDB$Constraint_Name from RDB$RELATION_CONSTRAINTS ' +
    'where RDB$Relation_Name = ''' + UpperCase(ATableName) + ''' and RDB$Constraint_Type = ''PRIMARY KEY'' ';
  qryMain.Open;
  if qryMain.RecordCount > 0 then
  begin
    Result:= Trim(qryMain.FieldByName('RDB$Index_name').AsString);
    ConstraintName:= Trim(qryMain.FieldByName('RDB$Constraint_Name').AsString);
  end
  else
    Result:= '';
  qryMain.Close;
end;

function TfmMain.GetPrimaryKeyFields(DatabaseIndex: Integer;
  ATableName: string; var KeyFields: TStringList): boolean;
const
  // Select field(s) that make up primary key
  Template= ' SELECT r.rdb$field_name ' +
            ' FROM RDB$RELATION_FIELDS r ' +
            ' LEFT JOIN RDB$FIELDS f         ON r.RDB$FIELD_SOURCE       = f.RDB$FIELD_NAME ' +
            ' LEFT JOIN RDB$INDEX_SEGMENTS s ON s.RDB$FIELD_NAME         = r.RDB$FIELD_NAME ' +
            ' LEFT JOIN RDB$INDICES i        ON i.RDB$INDEX_NAME         = s.RDB$INDEX_NAME ' +
            '                               AND i.RDB$RELATION_NAME      = r.RDB$RELATION_NAME ' +
            ' LEFT JOIN RDB$RELATION_CONSTRAINTS rc ON rc.RDB$INDEX_NAME = s.RDB$INDEX_NAME ' +
            '                                      AND rc.RDB$INDEX_NAME = i.RDB$INDEX_NAME ' +
            '                                      AND rc.RDB$RELATION_NAME = i.RDB$RELATION_NAME ' +
            ' WHERE r.RDB$RELATION_NAME = ''%s'' '+
            '   AND rc.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' ';
begin
  Result := False;
  KeyFields.Clear;
  qryMain.Close;
  SetConnection(DatabaseIndex);
  qryMain.SQL.Text := Format(Template, [UpperCase(ATableName)] );
  qryMain.Open;
  while not(qryMain.EOF) do begin
    KeyFields.Add(Trim(qryMain.FieldByName('rdb$field_name').AsString));
    qryMain.Next;
  end;
  qryMain.Close;
  Result := True;
end;

(*********  Get constrain fields  *********)

function TfmMain.GetConstraintFields(ATableName, AIndexName: string; var List: TStringList): Boolean;
begin
  qryMain.Close;
  qryMain.SQL.Text:= 'SELECT s.RDB$FIELD_NAME AS field_name ' +
     'FROM RDB$INDEX_SEGMENTS s ' +
     'LEFT JOIN RDB$INDICES i ON i.RDB$INDEX_NAME = s.RDB$INDEX_NAME ' +
     'LEFT JOIN RDB$RELATION_CONSTRAINTS rc ON rc.RDB$INDEX_NAME = s.RDB$INDEX_NAME ' +
     'LEFT JOIN RDB$REF_CONSTRAINTS refc ON rc.RDB$CONSTRAINT_NAME = refc.RDB$CONSTRAINT_NAME ' +
     'LEFT JOIN RDB$RELATION_CONSTRAINTS rc2 ON rc2.RDB$CONSTRAINT_NAME = refc.RDB$CONST_NAME_UQ ' +
     'LEFT JOIN RDB$INDICES i2 ON i2.RDB$INDEX_NAME = rc2.RDB$INDEX_NAME ' +
     'LEFT JOIN RDB$INDEX_SEGMENTS s2 ON i2.RDB$INDEX_NAME = s2.RDB$INDEX_NAME ' +
     '   WHERE i.RDB$RELATION_NAME=''' + UpperCase(ATableName) + '''  ' +
      'AND rc.RDB$INDEX_NAME=''' + UpperCase(AIndexName) + ''' ' +
      'AND rc.RDB$CONSTRAINT_TYPE IS NOT NULL ' +
      'ORDER BY s.RDB$FIELD_POSITION';
  List.Clear;
  qryMain.Open;
  while not qryMain.EOF do begin
    List.Add(Trim(qryMain.Fields[0].AsString));
    qryMain.Next;
  end;
  qryMain.Close;
  Result:= List.Count > 0;
end;

(********  Get table names   ********)

function TfmMain.GetTableNames(dbIndex: Integer): string;
var
  Count: Integer = 0;
begin
  Result:= dmSysTables.GetDBObjectNames(RegisteredDatabases[dbIndex], otTables, Count);
end;

Procedure RegisterOptions(aOptions:TEvsOptions);
begin

end;

initialization
  RegisterInitProc(@RegisterOptions);
  SeTMDODataBaseErrorMessages([ShowSQLCode, ShowMDOMessage]);
end.


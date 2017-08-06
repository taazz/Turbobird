unit uEvsMain;

{.$mode delphi}
{$mode objfpc}
{$H+}
interface
{$INCLUDE EvsDEfs.inc}
uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs, ComCtrls, Buttons, ExtCtrls, StdCtrls, Grids, ActnList, StdActns, Menus,
  VirtualTrees, uevscolorutils, utbDBRegistry, GpStructuredStorage, uEvsTabNotebook, uEvsNoteBook, uEvsGenIntf, uTBCommon, uTBTypes, uEvsDBSchema,
  utbConfig, uTbDialogs, uEvsIntfObjects, uEvsSqlEditor, uDMMain;

type

  //Thoughts on Design.
  // Is it desirable to have multiple windows from multiple databases open on the same work space?
  // Or is it better to organize them per database?
  //
  // for example I could have 2 page controls one on top for the job windows and one on bottom for
  // the database those windows communicate with changing the database on the bottom should change
  // the window list on the top.
  // what happens if I add the ability to change the database inside one of those windows? how
  // is this going to be potrait in the GUI? a move to the correct database page with every neighbor
  // window changing on the fly. Doesn't that create a small instability feeling?
  //
  // Should I auto focus the correct tree node in the tree when a page is activated? this is a smaller change
  // and probably the user is already used or can learn to ignore easier.

  { TEvsDBPage }

  TEvsDBPage = class(TEvsPage)
  private
    FDatabase :IEvsDatabaseInfo;
    procedure SetDatabase(aValue :IEvsDatabaseInfo);
  public
    constructor Create(aOwner :TComponent); override;
    destructor Destroy; override;
    property Database:IEvsDatabaseInfo read FDatabase write SetDatabase;
  end;

  { TEvsDBTreeData }
  //under consideration do not use.
  TEvsDBTreeData = class(TEvsInterfacedObject, IEvsTreeNode)
  private
    FDB: IEvsDatabaseInfo;
  protected
    Function GetChildCount :integer;         extdecl;
    Function GetDisplayText :String;         extdecl;
    Function GetFirstChild :IEvsTreeNode;    extdecl;
    Function GetNextSibling :IEvsTreeNode;   extdecl;
  public
    constructor Create(aDB :IEvsDatabaseInfo);
    destructor Destroy; override;
    Property DisplayText :String       read GetDisplayText;
    Property ChildCount  :Integer      read GetChildCount;
    Property FirstChild  :IEvsTreeNode read GetFirstChild;
    Property NextSibling :IEvsTreeNode read GetNextSibling;
  end;

  { TMainForm }
  TMainForm = class(TForm, IEvsObserver)
    actAbout           :TAction;
    actBackupDB        :TAction;
    actCopy            :TAction;
    actCut             :TAction;
    actDatabaseEdit    :TAction;
    actExit            :TAction;
    actFontEditor      :TAction;
    aclMain            :TActionList;
    actDropDatabase    :TAction;
    actDropTable :TAction;
    actEditTable :TAction;
    actDisconnectDB :TAction;
    actConnectDB :TAction;
    actConnectAs :TAction;
    actRefreshTable :TAction;
    actNewTable :TAction;
    actUnRegister      :TAction;
    actNewDB           :TAction;
    actOptions         :TAction;
    actPaste           :TAction;
    actQuery           :TAction;
    actRefresh         :TAction;
    actRefreshDatabase :TAction;
    actRegisterDB      :TAction;
    actRestoreDB       :TAction;
    actSelectAll       :TAction;
    Bevel1             :TBevel;
    cbMain             :TCoolBar;
    Image1             :TImage;
    MainMenu1 :TMainMenu;
    MenuItem1 :TMenuItem;
    MenuItem10 :TMenuItem;
    MenuItem11 :TMenuItem;
    MenuItem12 :TMenuItem;
    MenuItem13 :TMenuItem;
    MenuItem14 :TMenuItem;
    MenuItem2 :TMenuItem;
    MenuItem3 :TMenuItem;
    MenuItem4 :TMenuItem;
    MenuItem5 :TMenuItem;
    MenuItem6 :TMenuItem;
    MenuItem7 :TMenuItem;
    MenuItem8 :TMenuItem;
    MenuItem9 :TMenuItem;
    mnuDatabase :TMenuItem;
    mniCreateDB :TMenuItem;
    Splitter1          :TSplitter;
    StatusBar1         :TStatusBar;
    ToolBar1           :TToolBar;
    ToolBar2           :TToolBar;
    tlbNewDB           :TToolButton;
    tlbEditDB          :TToolButton;
    ToolBar3           :TToolBar;
    ToolButton1        :TToolButton;
    ToolButton11       :TToolButton;
    tlbUnregisterDB    :TToolButton;
    tlbRegisterDB      :TToolButton;
    tlbRestoreDB       :TToolButton;
    tlbBackupDB        :TToolButton;
    ToolButton2        :TToolButton;
    tlbDisconnect :TToolButton;
    ToolButton4 :TToolButton;
    ToolButton9        :TToolButton;
    vstMain            :TVirtualStringTree;
    procedure actBackupDBExecute    (Sender :TObject);
    procedure actBackupDBUpdate     (Sender :TObject);
    procedure actConnectAsExecute(Sender :TObject);
    procedure actConnectAsUpdate(Sender :TObject);
    procedure actConnectDBExecute(Sender :TObject);
    procedure actConnectDBUpdate(Sender :TObject);
    procedure actCutUpdate(Sender :TObject);
    procedure actDatabaseEditExecute(Sender :TObject);
    procedure actDatabaseEditUpdate(Sender :TObject);
    procedure actDisconnectDBExecute(Sender :TObject);
    procedure actDisconnectDBUpdate(Sender :TObject);
    procedure actDropDatabaseExecute(Sender :TObject);
    procedure actDropDatabaseUpdate (Sender :TObject);
    procedure actExitExecute        (Sender :TObject);
    procedure actNewDBExecute       (Sender :TObject);
    procedure actQueryUpdate(Sender :TObject);
    procedure actRefreshDatabaseExecute(Sender :TObject);
    procedure actRefreshDatabaseUpdate (Sender :TObject);
    procedure actRegisterDBExecute     (Sender :TObject);
    procedure actRestoreDBExecute      (Sender :TObject);
    procedure actRestoreDBUpdate       (Sender :TObject);
    procedure actUnRegisterExecute     (Sender :TObject);
    procedure actUnRegisterUpdate      (Sender :TObject);

    //Main object Tree
    procedure vstMainDblClick          (Sender :TObject);
    procedure vstMainExpanding         (Sender :TBaseVirtualTree; Node :PVirtualNode; var Allowed :Boolean);
    procedure vstMainFocusChanged      (Sender :TBaseVirtualTree; Node :PVirtualNode; Column :TColumnIndex);
    procedure vstMainFreeNode          (Sender :TBaseVirtualTree; Node :PVirtualNode);
    procedure vstMainGetImageIndex     (Sender :TBaseVirtualTree; Node :PVirtualNode; Kind :TVTImageKind;
                                        Column :TColumnIndex; var Ghosted :Boolean; var ImageIndex :Integer);{$MESSAGE WARN 'Needs Implementation'}
    procedure vstMainGetNodeDataSize(Sender :TBaseVirtualTree; var NodeDataSize :Integer);
    procedure vstMainGetText(Sender :TBaseVirtualTree; Node :PVirtualNode; Column :TColumnIndex; TextType :TVSTTextType; var CellText :String);
    procedure vstMainInitChildren(Sender :TBaseVirtualTree; Node :PVirtualNode; var ChildCount :Cardinal);
    procedure vstMainInitNode(Sender :TBaseVirtualTree; ParentNode, Node :PVirtualNode; var InitialStates :TVirtualNodeInitStates);
  private
    { private declarations }
    FSettingFileName :string;
    FWorkBench       :IGpStructuredStorage; //settings monitored sql and known databases.
    FWorkSpace       :TEvsATTabsNoteBook; //all the windows, queries and editors
    function FocusedDBTitle:String;inline;
    procedure HandleNewTabClik(var Allow:Boolean; var aCaption:string; var aChild:TControlClass = nil);
    function GetDB(aNode:PVirtualNode):IEvsDatabaseInfo;inline;
    procedure TabChanging(aSender: TObject; aNewTabIndex: Integer; var ACanChange: Boolean);
    Function IsDatabaseNode(const aNode :PVirtualNode):Boolean;inline;
    procedure LoadConfig;
    procedure SaveConfig;
    procedure SetupWorkbench;
    procedure SaveRegistry;
    procedure CloseAllAndDisconnect(aDB:IEvsDatabaseInfo);
    function NewPage(const aDatabase:IEvsDatabaseInfo; const aCaption:string):TEvsDBPage;
    function NodeGenID(const aNode:PVirtualNode):Integer;
    function GetDBNode (const aNode:PVirtualNode):PVirtualNode;inline;
    procedure DefaultAction(const aNode:PVirtualNode);
    function SupportedClass(const aControl:TObject):Boolean;
    Function FocusedDB:IEvsDatabaseInfo;inline;
   public
    { public declarations }
    constructor Create(aOwner :TComponent); override;
    destructor Destroy; override;
    Function ObjectRef :TObject; extdecl;
    procedure RefreshTree;
    procedure IEvsObserver.Update = DoUpdate;
    procedure DoUpdate(aSubject :IEvsObjectRef; aAction :TEVSGenAction;const aData:NativeUInt); extdecl;
  end;

var
  MainForm : TMainForm;

implementation

{$R *.lfm}

const
  cDBReg = 'Databases.reg';
  cRootFolder ='/';
  cDBInfoLevel = 0;
  cGroupLevel1 = 1;
  cGroupLevel2 = 3;
  cObjectLevel = 2;
  cFieldLevel  = 3; //Only tables have extra info under them and for now only fields. In the next relase more will be added.

type
  PIEvsDBBaseObject = ^IEvsDBBaseObject;
  PIEvsDataBaseInfo = ^IEvsDatabaseInfo;
  PIEvsTableInfo    = ^IEvsTableInfo;

{ TEvsDBPage }

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

{$REGION ' TEvsDBTreeData '}

constructor TEvsDBTreeData.Create(aDB :IEvsDatabaseInfo);
begin
  FDB := aDB;
  inherited Create(True);
end;

destructor TEvsDBTreeData.Destroy;
begin
  FDB := Nil;
  inherited Destroy;
end;

Function TEvsDBTreeData.GetChildCount :integer;extdecl;
begin
  Result := 10;
end;

Function TEvsDBTreeData.GetDisplayText :String;extdecl;
begin
  Result := '';
  if Assigned(FDB) then Result := FDB.Title;
end;

Function TEvsDBTreeData.GetFirstChild :IEvsTreeNode;extdecl;
begin
  Result := nil;
end;

Function TEvsDBTreeData.GetNextSibling :IEvsTreeNode;extdecl;
begin
  Result := Nil;
end;
{$ENDREGION}

{$REGION ' TMainForm '}

procedure TMainForm.vstMainFocusChanged(Sender :TBaseVirtualTree; Node :PVirtualNode; Column :TColumnIndex);
begin
  {$MESSAGE WARN 'Needs Implementation'}
  //change the active database/dataserver?
end;

procedure TMainForm.vstMainDblClick(Sender :TObject);
begin
  if Assigned(vstMain.FocusedNode) then DefaultAction(vstMain.FocusedNode)
end;

procedure TMainForm.actRegisterDBExecute(Sender :TObject);
var
  vTmp :IEvsDatabaseInfo;
begin
  DBRegistry.BeginUpdate;
  try
    vTmp := uEvsDBSchema.NewDatabase(stFirebird); {$MESSAGE WARN 'should the registration dialog know the server type?'}
    if uTbDialogs.RegisterDatabase(vTmp) = mrOK then begin
      DBRegistry.Append(vTmp);
    end;
  finally
    DBRegistry.EndUpdate;
  end;
end;

procedure TMainForm.actRestoreDBExecute(Sender :TObject);
var
  vDB  :IEvsDatabaseInfo;
  vNew :Boolean;
begin
  vDB := GetDB(vstMain.FocusedNode);
  vNew := not Assigned(vDB);
  if uTbDialogs.RestoreDB(vDB) = mrOK then ShowInfo('Restore','Restore completed successfully.');
end;

procedure TMainForm.actRestoreDBUpdate(Sender :TObject);
begin
  actRestoreDB.Enabled := True; //Assigned(GetDB(vstMain.FocusedNode));
end;

procedure TMainForm.actUnRegisterExecute(Sender :TObject);
var
  vDB   :IEvsDatabaseInfo;
  vNode :PVirtualNode;
begin
  vDB := GetDB(vstMain.FocusedNode);
  if Assigned(vDB) then begin //avoid using beginupdate etc in here to avoid complete tree refresh.
    DBRegistry.RemoveDatabase(vDB);
    CloseAllAndDisconnect(vDB);
    vNode := GetDBNode(vstMain.FocusedNode);
    if Assigned(vNode) then vstMain.DeleteNode(vNode);
  end;
end;

procedure TMainForm.actUnRegisterUpdate(Sender :TObject);
begin
  actUnRegister.Enabled := Assigned(GetDB(vstMain.FocusedNode));
end;

procedure TMainForm.actNewDBExecute(Sender :TObject);
var
  vTmp : IEvsDatabaseInfo;
begin
  vTmp := uEvsDBSchema.NewDatabase(stFirebird);
  if uTbDialogs.CreateDatabase(vTmp) = mrOK then begin
    uEvsDBSchema.CreateDB(vTmp, vTmp.PageSize, stFirebird);
    DBRegistry.Append(vTmp);
    vstMain.RootNodeCount := vstMain.RootNodeCount+1;
  end;
end;

procedure TMainForm.actQueryUpdate(Sender :TObject);
begin
  actQuery.Enabled := Assigned(FocusedDB) and Assigned(FocusedDB.Connection);
end;

procedure TMainForm.actRefreshDatabaseExecute(Sender :TObject);
var
  vNode:PVirtualNode;
begin
  vNode := GetDBNode(vstMain.FocusedNode);
  if vNode <> vstMain.FocusedNode then vstMain.FocusedNode := vNode;
  dmMain.RefreshDatabase(GetDB(vstMain.FocusedNode));
  vstMain.ReinitNode(vNode, False);
end;

procedure TMainForm.actRefreshDatabaseUpdate(Sender :TObject);
begin
  actRefresh.Enabled := Assigned(GetDB(vstMain.FocusedNode));
end;

procedure TMainForm.actExitExecute(Sender :TObject);
begin
  Application.Terminate;
end;

procedure TMainForm.actBackupDBUpdate(Sender :TObject);
begin
  actBackupDB.Enabled := Assigned(GetDB(vstMain.FocusedNode)) and (not Assigned(FocusedDB.Connection));
end;

procedure TMainForm.actConnectAsExecute(Sender :TObject);
begin
  dmMain.ConnectDatabaseAs(FocusedDB);
end;

procedure TMainForm.actConnectAsUpdate(Sender :TObject);
begin
  actConnectAs.Enabled := IsDatabaseNode(vstMain.FocusedNode);
end;

procedure TMainForm.actConnectDBExecute(Sender :TObject);
begin
  dmMain.ConnectDatabase(FocusedDB);
end;

procedure TMainForm.actConnectDBUpdate(Sender :TObject);
begin
  actConnectDB.Enabled := IsDatabaseNode(vstMain.FocusedNode);
end;

procedure TMainForm.actCutUpdate(Sender :TObject);
begin
  actCut.Enabled := SupportedClass(ActiveControl);
end;

procedure TMainForm.actDatabaseEditExecute(Sender :TObject);
var
  vDB:IEvsDatabaseInfo;
  procedure CopyRegInfoFrom(const aDB:IEvsDatabaseInfo);
  begin
    vDB.Title := aDB.Title;
    vDB.Host := aDB.Host;
    vDB.Database := aDB.Database;
    vDB.DefaultCharset := aDB.DefaultCharset;
    vDB.DefaultCollation := aDB.DefaultCollation;
    vDB.Credentials.CopyFrom(aDB.Credentials);
  end;

begin
  vDB  := NewDatabase(FocusedDB.ServerKind);
  CopyRegInfoFrom(FocusedDB);
  if uTbDialogs.RegisterDatabase(vDB) = mrOK then begin
    FocusedDB.CopyFrom(vDB);
  end;
end;

procedure TMainForm.actDatabaseEditUpdate(Sender :TObject);
begin
  actDatabaseEdit.Enabled := Assigned(FocusedDB);
end;

procedure TMainForm.actDisconnectDBExecute(Sender :TObject);
begin
  If GetConfirmation('Disconnect Database','Are you sure you want to disconnect %S database and close all open windows?') = mrYes then begin
    CloseAllAndDisconnect(FocusedDB);
  end;
end;

procedure TMainForm.actDisconnectDBUpdate(Sender :TObject);
begin
  actDisconnectDB.Enabled := Assigned(FocusedDB);
end;

procedure TMainForm.actDropDatabaseExecute(Sender :TObject);
var
  vDB:IEvsDatabaseInfo;
begin
  vDB := FocusedDB;
  if GetConfirmation('Drop Database',Format('Are you sure you want to Drop the Database <%S>?',[vDB.Host+':'+FocusedDBTitle])) = mrYes then begin
    dmMain.DropDatabase(GetDB(vstMain.FocusedNode));
    vstMain.DeleteNode(GetDBNode(vstMain.FocusedNode));
    DBRegistry.RemoveDatabase(vDB);
    vDB := Nil;
  end;
end;

procedure TMainForm.actDropDatabaseUpdate(Sender :TObject);
begin
  actDropDatabase.Enabled := GetDB(vstMain.FocusedNode) <> nil;
end;

procedure TMainForm.actBackupDBExecute(Sender :TObject);
var
  vDB : IEvsDatabaseInfo;
begin
  vDB := GetDB(vstMain.FocusedNode);
  if Assigned(vDB) then if uTbDialogs.BackupDB(vDB) = mrOK then ShowInfo('Backup','Backup completed successfully.');
end;

procedure TMainForm.vstMainExpanding(Sender :TBaseVirtualTree; Node :PVirtualNode; var Allowed :Boolean);
var
  vData:PIEvsDBBaseObject = nil;
  vDB:IEvsDatabaseInfo;// absolute vData;//= nil;
begin
  Allowed := False;
  vData   := Sender.GetNodeData(Node);
  case Sender.GetNodeLevel(Node) of
    cDBInfoLevel : begin
        if Supports(vData^.ObjectRef, IEvsDatabaseInfo, vDB) then begin
          if vDB.Connection = nil then
            dmMain.ConnectDatabase(vDB);
          Allowed := Assigned(vDB.Connection);
          if Allowed then Sender.ReinitChildren(Node,False);
        end;
      end;
    cGroupLevel1 : begin
        vData  := Sender.GetNodeData(Node);
        vDB    := GetDB(Node);//
        case Node^.Index of
          0: begin
              if (vDB.SequenceCount = 0) and (Assigned(vDB) and Assigned(vDB.Connection)) then vDB.Connection.MetaData.GetTables(vDB);
              Allowed := (vDB.TableCount > 0)
            end;
          1: begin
               if (vDB.SequenceCount = 0) and (Assigned(vDB) and Assigned(vDB.Connection)) then
                 vDB.Connection.MetaData.GetSequences(vDB);//Sequences
               Allowed := (vDB.TableCount > 0);
             end;
          2: if Assigned(vDB) then Allowed := vDB.TriggerCount>0;   //vData^ := vDB.Trigger   [Node^.Index]; //Trigger
          3: if Assigned(vDB) then Allowed := vDB.ViewCount>0;      //vData^ := vDB.View      [Node^.Index];//View
          4: if Assigned(vDB) then Allowed := vDB.ProcedureCount>0; //vData^ := vDB.StoredProc[Node^.Index]; //Procedure
          5: if Assigned(vDB) then Allowed := vDB.UdfCount>0;       //vData^ := vDB.UDF       [Node^.Index];//Udf
          6: if Assigned(vDB) then Allowed := False;                //vData^ := nil; //'System Tables';
          7: if Assigned(vDB) then Allowed := vDB.DomainCount>0;    //vData^ := vDB.Domain    [Node^.Index];//Domain
          8: if Assigned(vDB) then Allowed := vDB.RoleCount>0;      //vData^ := vDB.Role      [Node^.Index];//Role
          9: if Assigned(vDB) then Allowed := vDB.ExceptionCount>0; //vData^ := vDB.Exception [Node^.Index];//Exception
        end;
      end;
  else Allowed := True;
  end;
end;

Function TMainForm.IsDatabaseNode(const aNode :PVirtualNode) :Boolean;inline;
var
  vDt : Pointer;
  vDBObj:PIEvsDBBaseObject absolute vDt;
  vBase:IEvsDatabaseInfo;
begin
  vDt := vstMain.GetNodeData(aNode);
  Result := Supports(vDBObj^, IEvsDatabaseInfo, vBase);
end;

procedure TMainForm.LoadConfig;
var
  vStrm:TStream;
begin
  FWorkBench.Initialize(FSettingFileName, fmOpenReadWrite or fmShareExclusive);
  if FWorkBench.FileExists(cRootFolder+cDBReg) then begin
    vStrm := FWorkBench.OpenFile(cRootFolder+cDBReg, fmOpenReadWrite or fmShareExclusive);
    try
      try
        DBRegistry.LoadFrom(vStrm);
      except
        on E:Exception do
          Application.ShowException(E);
      end;
    finally
      vStrm.Free;
    end;
  end;
end;

procedure TMainForm.SaveConfig;
begin
  SaveRegistry;
end;

procedure TMainForm.SetupWorkbench;
begin
  FWorkBench.Initialize(FSettingFileName, fmCreate);
end;

procedure TMainForm.SaveRegistry;
var
  vStrm :TStream;
  vMode :Word;
begin
  if (FWorkBench.IsInitialized) and Assigned(FWorkBench) then begin
    if FWorkBench.FileExists(cRootFolder + cDBReg) then vMode := fmOpenReadWrite or fmShareExclusive
    else vMode := fmCreate;
    vStrm := FWorkBench.OpenFile(cRootFolder + cDBReg, vMode);
    try
      DBRegistry.SaveTo(vStrm);
    finally
      vStrm.Free;
    end;
  end;
end;

procedure TMainForm.CloseAllAndDisconnect(aDB :IEvsDatabaseInfo);
var
  vCntr :Integer;
  vPage :TEvsPage;
begin
  for vCntr := 0 to FWorkSpace.PageCount -1 do begin
      vPage := FWorkSpace.Page[vCntr];
    if vPage is TEvsDBPage and (TEvsDBPage(vPage).Database = aDB) then begin
      FWorkSpace.DeletePage(vPage);
    end;
  end;
end;

function TMainForm.NewPage(const aDatabase :IEvsDatabaseInfo; const aCaption :string) :TEvsDBPage;
begin
  Result := TEvsDBPage.Create(FWorkSpace);
  Result.Caption := aCaption;
  Result.Database := aDatabase;
end;

function TMainForm.NodeGenID(const aNode :PVirtualNode) :Integer;
var
  vData:PIEvsDBBaseObject;
begin // a generic ID to identify a node based on its data, to be used for the default action when one double clicks a node and the icon for the node
  vData := vstMain.GetNodeData(aNode);
  if not Assigned(vData^) then begin
    Result := 0; // not a dbobject node probably a group node like tables or fields try to expand.
    if vstMain.GetNodeLevel(aNode) = cGroupLevel1 then begin
      case aNode^.Index of
        0: Result := 101;//vData^ := vDB.Table     [Node^.Index];//table
        1: Result := 102;//vData^ := vDB.Sequence  [Node^.Index];//Sequence
        2: Result := 103;//vData^ := vDB.Trigger   [Node^.Index];//Trigger
        3: Result := 104;//vData^ := vDB.View      [Node^.Index];//View
        4: Result := 105;//vData^ := vDB.StoredProc[Node^.Index];//Procedure
        5: Result := 106;//vData^ := vDB.UDF       [Node^.Index];//Udf
        6: Result := 107;//vData^ := nil;                        //System Tables;
        7: Result := 108;//vData^ := vDB.Domain    [Node^.Index];//Domain
        8: Result := 109;//vData^ := vDB.Role      [Node^.Index];//Role
        9: Result := 110;//vData^ := vDB.Exception [Node^.Index];//Exception
      end;
    end;
  end else if Supports(vData^, IEvsDatabaseInfo)  then Result := -1   //Database
  else if Supports(vData^, IEvsTableInfo)     then Result := -2   //table;
  else if Supports(vData^, IEvsViewInfo)      then Result := -3   //view
  else if Supports(vData^, IEvsStoredInfo)    then Result := -4   //stored
  else if Supports(vData^, IEvsExceptionInfo) then Result := -5   //exception
  else if Supports(vData^, IEvsUDFInfo)       then Result := -6   //UDF
  else if Supports(vData^, IEvsDomainInfo)    then Result := -7   //Domain
  else if Supports(vData^, IEvsField)         then Result := -8   //Field
  else if Supports(vData^, IEvsForeignKey)    then Result := -9   //ForeignKey
  else if Supports(vData^, IEvsSequenceInfo)  then Result := -10  //Sequence
  else if Supports(vData^, IEvsIndexInfo)     then Result := -11  //Index
  else if Supports(vData^, IEvsRoleInfo)      then Result := -12  //Role
  else if Supports(vData^, IEvsUserInfo)      then Result := -13  //User
  else if Supports(vData^, IEvsTriggerInfo)   then Result := -14  //Trigger
  //else if Supports(vData^, IEvsConnection)    then Result := -15; //Connection??
  ;
end;

function TMainForm.GetDBNode(const aNode :PVirtualNode) :PVirtualNode;
begin
  Result := nil;
  if (aNode = nil) or (aNode = vstMain.RootNode) then Exit;
  if vstMain.GetNodeLevel(aNode) = cDBInfoLevel then Result := aNode
  else Result := GetDBNode(aNode^.Parent);
end;

procedure TMainForm.DefaultAction(const aNode :PVirtualNode);
begin

  if NodeGenID(aNode) = 0 then vstMain.Expanded[aNode] := not vstMain.Expanded[aNode];
end;

function TMainForm.SupportedClass(const aControl :TObject) :Boolean;
begin
  Result := (aControl is TCustomEdit) or (aControl is TMemo) or Supports(aControl, IEvsCopyPaste) or (aControl is TCustomSynEdit);
end;

Function TMainForm.FocusedDB :IEvsDatabaseInfo;inline;
begin
  Result := GetDB(vstMain.FocusedNode);
end;

procedure TMainForm.vstMainFreeNode(Sender :TBaseVirtualTree; Node :PVirtualNode);
var
  vData:PIEvsDBBaseObject;
begin
  vData := Sender.GetNodeData(Node);
  vData^ := Nil;
end;

procedure TMainForm.vstMainGetImageIndex(Sender :TBaseVirtualTree; Node :PVirtualNode; Kind :TVTImageKind;
                                         Column :TColumnIndex; var Ghosted :Boolean; var ImageIndex :Integer);
begin  {$MESSAGE WARN 'Needs Implementation'}
  case Sender.GetNodeLevel(Node) of
    cDBInfoLevel : ;// connected or not connected image
    cGroupLevel1: ;//group image index (tables,roles etc);
    cObjectLevel: ;//object type icon (table, view etc);
    3: ;//object type icon (field only on this level)
  else
    ShowInfo('vstMAin.GetImageIndex','Unexpected node''s level '+IntToStr(Sender.GetNodeLevel(Node)));
  end
  //raise NotImplementedException;
end;

procedure TMainForm.vstMainGetNodeDataSize(Sender :TBaseVirtualTree; var NodeDataSize :Integer);
begin
  NodeDataSize := SizeOf(IEvsDBBaseObject);
end;

procedure TMainForm.vstMainGetText(Sender :TBaseVirtualTree; Node :PVirtualNode; Column :TColumnIndex; TextType :TVSTTextType; var CellText :String);
  function GetObjGroupName(const aIndex:Integer):String;
  begin
    Result := '';
    case aIndex of
      0: Result := 'Tables';
      1: Result := 'Generators';
      2: Result := 'Triggers';
      3: Result := 'Views';
      4: Result := 'Stored Procedures';
      5: Result := 'Functions';
      6: Result := 'System Tables';
      7: Result := 'Domains';
      8: Result := 'Roles';
      9: Result := 'Exceptions';
    else
      Raise ETBException.CreateFmt('Unknown object group %D',[aIndex]);
    end;
  end;
var
  vData :PIEvsDBBaseObject;
  //vTmp :IEvsDatabaseInfo;
  vDB   :IEvsDatabaseInfo;
begin
  case TextType of
    ttNormal: begin
      case Sender.GetNodeLevel(node) of
        0 : CellText := DBRegistry.Database[Node^.Index].Title;
        1 : CellText := GetObjGroupName(Node^.Index);
      else begin
          vData := Sender.GetNodeData(Node);
          if Assigned(vData^) then begin
          if (vData^ is IEvsDBBaseObject) then
              CellText := vData^.ObjectTitle;
          end else CellText := ' ';
        end;
      end;
    end;
    ttStatic: begin //this should be shown as a grayed out text I might have to add the parenthesis characters or not lets see.
      CellText := '';
      case Sender.GetNodeLevel(Node) of
        1: begin
          vDB := GetDB(Node);
          case Node^.Index of
            0: CellText := IntToStr(vDB.TableCount);// Node.Parent 'Tables';
            1: CellText := IntToStr(vDB.SequenceCount);//'Generators';
            2: CellText := IntToStr(vDB.TriggerCount);//'Triggers';
            3: CellText := IntToStr(vDB.ViewCount);//'Views';
            4: CellText := IntToStr(vDB.ProcedureCount);//'Stored Procedures';
            5: CellText := IntToStr(vDB.UdfCount);//'Functions';
            6: CellText := '';//IntToStr(IEvsDatabaseInfo(vData^).TableCount);//'System Tables';
            7: CellText := IntToStr(vDB.DomainCount);//'Domains';
            8: CellText := IntToStr(vDB.RoleCount);//'Roles';
            9: CellText := IntToStr(vDB.ExceptionCount);//'Exceptions';
          end;
        end;
      end;
    end;
  end;
end;

procedure TMainForm.vstMainInitChildren(Sender :TBaseVirtualTree; Node :PVirtualNode; var ChildCount :Cardinal);
var
  vData :PIEvsDBBaseObject;
  vDB   :IEvsDatabaseInfo;
begin
  vData := Sender.GetNodeData(Node);
  ChildCount := 0;
  case Sender.GetNodeLevel(Node) of
    0: ChildCount := 10;
    1: begin
      vData := Sender.GetNodeData(Node^.Parent);
      vDB := GetDB(Node);
      case Node^.Index of
        0: ChildCount := vDB.TableCount;// Node.Parent 'Tables';
        1: ChildCount := vDB.SequenceCount;//'Generators';
        2: ChildCount := vDB.TriggerCount;//'Triggers';
        3: ChildCount := vDB.ViewCount;//'Views';
        4: ChildCount := vDB.ProcedureCount;//'Stored Procedures';
        5: ChildCount := vDB.UdfCount;//'Functions';
        6: ChildCount := 0 ;//IntToStr(IEvsDatabaseInfo(vData^).TableCount);//'System Tables';
        7: ChildCount := vDB.DomainCount;//'Domains';
        8: ChildCount := vDB.RoleCount;//'Roles';
        9: ChildCount := vDB.ExceptionCount;//'Exceptions';
      end;
    end;
  else begin
      vData := Sender.GetNodeData(Node);
      if vData^ is IEvsTableInfo then ChildCount := IEvsTableInfo(vData^).FieldCount;
    end;
  end;
end;

procedure TMainForm.vstMainInitNode(Sender :TBaseVirtualTree; ParentNode, Node :PVirtualNode; var InitialStates :TVirtualNodeInitStates);
type
  TDumType = PByte;
var
  vData  :PIEvsDBBaseObject;
  vNode  :PVirtualNode;
  vLevel :Integer;
  vDB    :IEvsDatabaseInfo;
  vCnt   :Integer;
begin
  vData := Sender.GetNodeData(Node);
  vLevel := Sender.GetNodeLevel(Node);
  if vLevel = cDBInfoLevel then begin
    vDB := DBRegistry.Database[Node^.Index];
    vData^ :=  vDB as IEvsDBBaseObject;
    //if not Assigned(vData^) then ShowInfo('vstMain.InitNode','Unexpected Value nil for node''s data');
    Include(InitialStates, ivsHasChildren)
  end else if vLevel = cGroupLevel1 then begin
    vData  := Sender.GetNodeData(Node);
    vData^ := nil;//vDB as IEvsDBBaseObject;
    vDB    := GetDB(Node);
    vCnt   := 0;
    case Node^.Index of
      0: vCnt := vDB.TableCount;
      1: vCnt := vDB.SequenceCount;
      2: vCnt := vDB.TriggerCount;
      3: vCnt := vDB.ViewCount;
      4: vCnt := vDB.ProcedureCount;
      5: vCnt := vDB.UdfCount;
      6: Sender.IsVisible[Node] := False; {$MESSAGE WARN 'Needs Implementation'}  //'System Tables';
      7: vCnt := vDB.DomainCount;
      8: vCnt := vDB.RoleCount;
      9: vCnt := vDB.ExceptionCount;
    end;
    if vCnt > 0 then
      Include(InitialStates, ivsHasChildren)
    else
      Exclude(InitialStates, ivsHasChildren);

  end else if vLevel = cObjectLevel  then begin
    Exclude(InitialStates, ivsHasChildren);
    vDB := GetDB(Node);
    if not Assigned(vDB) then begin
      vNode := GetDBNode(Node);//.index
      vDB := DBRegistry.Database[vNode^.Index];
    end;
    case ParentNode^.Index of
      0: begin
           vData^ := vDB.Table     [Node^.Index];//table
           Include(InitialStates, ivsHasChildren);
        end;
      1: vData^ := vDB.Sequence  [Node^.Index];//Sequence
      2: vData^ := vDB.Trigger   [Node^.Index];//Trigger
      3: vData^ := vDB.View      [Node^.Index];//View
      4: vData^ := vDB.StoredProc[Node^.Index];//Procedure
      5: vData^ := vDB.UDF       [Node^.Index];//Udf
      6: vData^ := nil;                        //System Tables;
      7: vData^ := vDB.Domain    [Node^.Index];//Domain
      8: vData^ := vDB.Role      [Node^.Index];//Role
      9: vData^ := vDB.Exception [Node^.Index];//Exception
    end;
  end else vData^ := Nil; {$MESSAGE WARN 'pass the fields as well'}
end;

function TMainForm.FocusedDBTitle :String;inline;
var
  vDBInfo:IEvsDatabaseInfo;
begin
  Result := '';
  vDBInfo := GetDB(vstMain.FocusedNode);
  if Assigned(vDBInfo) then Result := vDBInfo.Title;
end;

procedure TMainForm.HandleNewTabClik(var Allow :Boolean; var aCaption :string; var aChild :TControlClass);
var
  vDB:IEvsDatabaseInfo;
  vPg:TEvsPage;
  vFr:TSqlEditorFrame;
begin
  vDB := GetDB(vstMain.FocusedNode);
  Allow := False; //Assigned(vDB) and Assigned(vDB.Connection);
  if Assigned(vDB) and Assigned(vDB.Connection) then begin
    vPg := FWorkSpace.AddNewPage(vDB.Title+':Query');//don't use newpage directly it does not handle the tab creation.
    if vPg is TEvsDBPage then TEvsDBPage(vPg).Database := vDB;
    vFr := TSqlEditorFrame.Create(vPg);
    vFr.Database := vDB;
    vFr.Align    := alClient;
    vFr.Parent   := vPg;
  end;
end;

function TMainForm.GetDB(aNode :PVirtualNode) :IEvsDatabaseInfo;inline;
var
  vData : PIEvsDBBaseObject;
begin
  if aNode = Nil then Exit(Nil);
  vData := vstMain.GetNodeData(aNode);
  if not Supports(vData^, IEvsDatabaseInfo, Result) then
    Result := GetDB(aNode^.Parent);
end;

procedure TMainForm.TabChanging(aSender :TObject; aNewTabIndex :Integer; var ACanChange :Boolean);
begin
  StatusBar1.Panels[0].Text := 'New Index will become '+ IntToStr(aNewTabIndex);
end;

constructor TMainForm.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  FWorkSpace := TEvsATTabsNoteBook.Create(Self);
  FWorkSpace.Parent := Self;
  FWorkSpace.Align := alClient;
  FWorkSpace.ShowAddTabButton := True;
  FWorkSpace.TabPosition := tpTop;
  FWorkSpace.OnNewTabClicked := @HandleNewTabClik;
  FWorkSpace.PageClass := TEvsDBPage;
  Image1.Parent := FWorkSpace;
  DBRegistry.AddObserver(Self);
  FWorkBench := CreateStorage;
  FSettingFileName := utbConfig.GetConfigurationDirectory + utbConfig.GetConfigFileName;
  if FileExists(FSettingFileName) then LoadConfig
  else SetupWorkbench;
end;

destructor TMainForm.Destroy;
begin
  SaveConfig;
  inherited Destroy;
end;

procedure TMainForm.DoUpdate(aSubject :IEvsObjectRef; aAction :TEVSGenAction;const aData:NativeUInt); extdecl;
begin //an observer can have multiple observables informing it for changes.
  if (aSubject.ObjectRef = DBRegistry) then begin //future proof..
    SaveRegistry;
    RefreshTree;
  end;
end;

Function TMainForm.ObjectRef :TObject; extdecl;
begin
  Result := Self;
end;

procedure TMainForm.RefreshTree;
begin
  vstMain.RootNodeCount := DBRegistry.Count;
  vstMain.ReinitChildren(vstMain.RootNode, True);
end;
{$ENDREGION}

end.


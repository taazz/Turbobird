unit uTBTypes;

{$mode objfpc}{$H+}

interface
//Generic unit to hold all the custom data types of the application to help with the deletion of public/published
//variables and avoid circular reference
{.$DEFINE EVS_Internal}
{$Include EvsDefs.inc}
{.$DEFINE EVS_MDO}//undefine this to use with the original MDO package.

uses
  Classes, SysUtils, sqldb, syncobjs, ComCtrls, controls, StdCtrls, uEvsGenIntf, MDODatabase {$IFDEF EVS_Internal},uEvsTypes{$ENDIF};

type

  { TMDODatabaseHelper }

  TMDODatabaseHelper = class helper for TMDODataBase
  private
    //HostName :String;
    {$IFNDEF EVS_MDO}
    function GetCharSet :String;
    function GetPassword :String;
    function GetRole :String;
    function GetUserName :String;
    procedure SetCharSet(aValue :String);
    procedure SetPassword(aValue :String);
    procedure SetRole(aValue :String);
    procedure SetUserName(aValue :String);
    {$ENDIF}
    function GetHostName :String;
    function GetTransaction :TMDOTransaction;
    procedure SetHostName(aValue :String);
    procedure SetTransaction(aValue :TMDOTransaction);
  published
    {$IFNDEF EVS_MDO}
    property UserName    :String read GetUserName write SetUserName;
    property Password    :String read GetPassword write SetPassword;
    property CharSet     :String read GetCharSet write SetCharSet;
    property Role        :String read GetRole write SetRole;
    {$ENDIF}
    property Transaction :TMDOTransaction read GetTransaction write SetTransaction;
    property HostName    :String read GetHostName write SetHostName;
  end;

  { TMDOTransactionHelper }

  TMDOTransactionHelper = class helper for TMDOTransaction
  private
    function GetDatabase :TMDODataBase;
    procedure SetDatabase(aValue :TMDODataBase);
  public
    procedure BeginTransaction;
    procedure EndTransaction;
  published
    property DataBase : TMDODataBase read GetDatabase write SetDatabase;
  end;

  TByteArray = array of Byte;
  TStringArray = array of string;
  TWideStringArray = array of WideString;
  //JKOZ: moved here from Reg.pas
  ETBException = class( {$IFDEF EVS_Internal} EEVSException {$ELSE} Exception {$EndIf} );
  ETBSilentException = class(EAbort)
  end;

  { ETBNotImplemented }

  ETBNotImplemented=class(ETBException)
    constructor Create(const msg :string);
  end;

  //jkoz: Seperate the database name to host, database.
  //hosts can be defined by name or ip make sure that no duplicates exist on the tree.
  TDBServerDetails = packed record
     HostName:string; // the host name as seen the network
     HostIP  :string; // last known ip of the host.
  end;
  PRegisteredDatabase = ^TDBDetails;
  //jkoz: convert from short string to string.
  PDBDetails = ^TDBDetails;
  TDBDetails = packed record
    Title        :string[30];
    DatabaseName :string[200];
    UserName     :string[100];
    Password     :string[100];
    Charset      :string[40];
    Deleted      :Boolean;
    SavePassword :Boolean;
    Role         :string[100];
    LastOpened   :TDateTime;
    Reserved     :array [0 .. 40] of Byte;
  end;

  //JKOZ: moved here from main.pas
//  PDBInfo = ^TDBInfo;

  { TDBInfo }

{  TDBInfo = record
    Index        :Integer;     //index of the database info in the file.
    RegRec       :TDBDetails;  //Database connection details.
    OrigRegRec   :TDBDetails;  //database details as they are loaded from the file.
    //active database session data.
    Conn         :TMDODataBase;
    Trans        :TMDOTransaction;
    {$IFDEF EVS_INTF}
    DataBase     :IEvsDatabaseInfo;
    {$ENDIF}
    {$IFDEF EVS_ThreadSafe}
    aLock        :TCriticalSection;
    procedure Lock;unimplemented;
    procedure Unlock;unimplemented;
    {$ENDIF}
  end;
  TDBInfoArray = array of TDBInfo;//to be used in a custom list class.
 }
  //JKOZ: moved here from systables.pas
  // e.g. used for composite foreign key constraints
  TConstraintCount = record
    Name  :string; // name of constraint
    Count :integer; // count of occurrences
  end;

  TConstraintCounts = array of TConstraintCount;
  //TEvsOperation =(opBackup, opRestore);
  TEvsBackupRestoreOperation  {:TEvsOperation} = (opBackup, opRestore);

  {$PACKENUM 1}
                             {all queries are executable what is the point of qtExecute}
  TQueryTypes = (qtUnknown=0, qtSelectable=1, qtExecute=2, qtScript=3);

  TQueryActions = (qaCommit, qaCommitRet, qaRollBack, qaRollbackRet, qaOpen, qaDDL, qaExec );

  // Types of objects in database
  // Note: the order and count must match the array below
  // Also, do not assign values to the individual enums; code depends
  // on them starting with 0 and being continious
  TObjectType = ( //Groups as seen in the tree.  //***** DELETE
                  otUnknown,  otTables,  otGenerators,  otTriggers, otViews,   otStoredProcedures,
                  otUDFs,    otDomains, otSystemTables,
                  otRoles,  otExceptions, otUsers,   otIndexes, otConstraints);
                  //objects in the server? do I need them?.
                 // otTable, otGenerator, otTrigger, otView,   otStoredProcedure,
                 // otUDF , otSystemTable, otDomain, otRole,  otException, otUser, otIndex, otConstraint,
                 // otField // should I distinguish between fields in a table and fields in a view? for now no.
                 //);

  { TTBTabsheet }
  // make sure that the main tabsheet is visible when no other tabs exist.
  TTBTabsheet = class(TTabSheet)
  public
    Destructor Destroy; override;
  end;

//various constants used through out the application will be moved to the new utbcommons when done.
const
  cVBorderGap = 2;
  cHBorderGap = 2;

procedure NotImplementedException;

implementation

//uses utbcommon;

procedure NotImplementedException;
begin
  raise ETBNotImplemented.Create('Not implemented.') at get_caller_addr(get_frame);
end;

{ TDBInfo }
{$IFDEF EVS_ThreadSafe}
procedure TDBInfo.Lock;
begin
  raise NotImplementedException;
end;

procedure TDBInfo.Unlock;
begin
  raise NotImplementedException;
end;
{$ENDIF}

{ TMDOTransactionHelper }

function TMDOTransactionHelper.GetDatabase :TMDODataBase;
begin
  Result := DefaultDatabase;
end;

procedure TMDOTransactionHelper.SetDatabase(aValue :TMDODataBase);
begin
  DefaultDatabase := aValue;
end;

procedure TMDOTransactionHelper.BeginTransaction;
begin
  StartTransaction;
end;

procedure TMDOTransactionHelper.EndTransaction;
begin
  if InTransaction then ApplyDefaultAction;
end;

{ TMDODatabaseHelper }
{$IFNDEF EVS_MDO}
function TMDODatabaseHelper.GetCharSet :String;
begin
  Result := Params.Values['lc_ctype'];
end;

function TMDODatabaseHelper.GetPassword :String;
begin
  Result := Params.Values['password'];
end;

function TMDODatabaseHelper.GetRole :String;
begin
  Result := Params.Values['sql_role_name'];
end;

function TMDODatabaseHelper.GetUserName :String;
begin
  Result := Params.Values['user_name'];
end;

procedure TMDODatabaseHelper.SetCharSet(aValue :String);
var
  vIdx : Integer;
begin
  if aValue = '' then begin
    vIdx := Params.IndexOfName('lc_ctype');
    if vIdx > -1 then Params.Delete(vIdx);
  end else Params.Values['lc_ctype'] := aValue;
end;

procedure TMDODatabaseHelper.SetPassword(aValue :String);
var
  vIdx : Integer;
begin
  if aValue = '' then begin
    vIdx := Params.IndexOfName('password');
    if vIdx > -1 then Params.Delete(vIdx);
  end else Params.Values['password'] := aValue;
end;

procedure TMDODatabaseHelper.SetRole(aValue :String);
var
  vIdx : Integer;
begin
  if aValue = '' then begin
    vIdx := Params.IndexOfName('sql_role_name');
    if vIdx > -1 then Params.Delete(vIdx);
  end else Params.Values['sql_role_name'] := aValue;
end;

procedure TMDODatabaseHelper.SetUserName(aValue :String);
var
  vIdx : Integer;
begin
  if aValue = '' then begin
    vIdx := Params.IndexOfName('user_name');
    if vIdx > -1 then Params.Delete(vIdx);
  end else Params.Values['user_name'] := aValue;
end;
{$ENDIF}

function TMDODatabaseHelper.GetHostName :String;
begin
  Result := '';
  if Pos(':', databasename)>2 then begin //second place is usualy a drive letter in windows.
    Result := Copy(DatabaseName, 1, Pos(':', databasename));
  end;
end;

function TMDODatabaseHelper.GetTransaction :TMDOTransaction;
begin
  Result := DefaultTransaction;
end;

procedure TMDODatabaseHelper.SetHostName(aValue :String);
var
  vName:String;
  vIdx:Integer;
begin
  vIdx := pos(':',DatabaseName);
  if vIdx>2 then  //remove the old hostname
    vName := Copy(DatabaseName,vIdx+1,Length(DatabaseName))
  else
    vName := DatabaseName;
  if aValue <> '' then //add the new
    DatabaseName := aValue+':'+vName
  else
    DatabaseName := vName;
end;

//user_name=evosi
//password=isove
//sql_role_name=admin

procedure TMDODatabaseHelper.SetTransaction(aValue :TMDOTransaction);
begin
  DefaultTransaction := aValue;
end;

{ ETBNotImplemented }

constructor ETBNotImplemented.Create(const msg :string);
var
  vMsg:string;
begin
  if msg <> '' then vMsg := msg else vMsg := 'Not Implemented';
  inherited Create(vMsg);
end;

{ TTBTabsheet }

Destructor TTBTabsheet.Destroy;
begin
  //if TabIndex>=pagecontrol.pagecount then this is the last tab. go backwards;
  //The first tabsheet has a hiden tab make sure it is visible.
  if Assigned(PageControl) then
    if PageControl.PageCount<=2 then
      PageControl.SelectNextPage(TabIndex < PageControl.PageCount -1, False);
  inherited Destroy;
end;


end.


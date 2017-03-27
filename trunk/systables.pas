unit SysTables;

{$mode objfpc}{$H+}

{$DEFINE EVS_NEW}

interface

uses
  Classes, SysUtils, sqldb, db, IBConnection, FileUtil, {LResources,} Forms, Controls,
  Dialogs, MDOQuery, MDODatabase, dbugintf, turbocommon, uTBTypes;
{ TODO -oJKOZ -cCode Hierarchy : Convert this datamodule to a plugin and move all external data and meta data access code here. }
{ TODO -oJKOZ -cDB Support : Move from sqldb to MDO objects, better array support. IBX4laz requires fpc3 and laz 1.6 }
type
  TEvsIBConnection = class(TIBConnection)
    //Password
  end;

  { TdmSysTables }

  TdmSysTables = class(TDataModule)
    IBConnection1 :TIBConnection;
    MDODatabase1 :TMDODatabase;
    //MDODatabase1 :TMDODatabase;
    MDOQuery :TMDOQuery;
    MDOTransaction :TMDOTransaction;
    QryMain :TSQLQuery;
  private
    { private declarations }
    ibcDatabase : TMDODatabase; //Remove both.
    stTrans     : TMDOTransaction;// TSQLTransaction;
  protected
    procedure OpenQuery(aObjectType: TObjectType);                                                                                                     //CHECK
  public
    { public declarations }
    // Fills array with composite (multikey) foreign key constraint names
    // and field count for specified table
    // Then use GetCompositeFKConstraint to check this array for a specified
    // constraint name
    procedure FillCompositeFKConstraints(const TableName: string; var ConstraintsArray: TConstraintCounts);                                            //CHECK
    // Initialize unit to work with specified database
    procedure Init(dbIndex: Integer);overload;deprecated;//jkoz use the one with the TDBInfo param.                                                    //CHECK
    procedure Init(aDB: TDBInfo);overload;                                                                                                             //CHECK
    // Gets list of object names that have type specified by TVIndex
    // Returns count of objects in Count
    //function GetDBObjectNames(DatabaseIndex: integer; ObjectType: TObjectType; var Count: Integer): string;overload;deprecated 'pass the record not the index';
    function GetServerVersion:string;                                                                                                                  //CHECK JK
    //Find the names of the database objects;
    //aDatabase, holds the Connect information for the database to query.
    //aObjectType, filters the names to a specific group of objects.
    //aCount, holds the number of names returned.
    //the function return a CSV string with the names.
    function GetDBObjectNames(const aDatabase: TDBInfo; aObjectType: TObjectType; var aCount: Integer): string;overload; //deprecated;                 //CHECK
    //Find the names of the database objects;
    //aDatabase   : holds the Connect information for the database to query.
    //aObjectType : filters the names to a specific group of objects.
    //aList       : is the stringlist that the procedure populates with the object names.
    //The function returns the number of objects retreived.
    function GetDBObjectNames(const aDatabase: TDBInfo; aObjectType: TObjectType; aList:TStrings):integer;overload;                                    //CHECK

    // Recalculates index statistics for all fields in database
    // Useful when a large amount of inserts/deletes may have changed the statistics
    // and indexes are not as efficient as they could be.
    function RecalculateIndexStatistics(dbIndex: integer): boolean;                                                                                    //CHECK

    // Returns object list (list of object names, i.e. tables, views) sorted by dependency
    // Limits sorting within one category (e.g. views)
    procedure SortDependencies(var ObjectList: TStringList);                                                                                           //CHECK
    // Gets information on specified trigger
    function GetTriggerInfo(DatabaseIndex: Integer; ATriggername: string;                                                                              //CHECK
      var AfterBefore, OnTable, Event, Body: string; var TriggerEnabled: Boolean;
      var TriggerPosition: Integer): Boolean;
    // Scripts all check constraints for a database's tables as alter table
    // statement, adding the SQL to List
    function ScriptCheckConstraints(dbIndex: Integer; List: TStrings): boolean;                                                                        //CHECK
    // Script trigger creation for specified trigger
    function ScriptTrigger(dbIndex: Integer; ATriggerName: string; List: TStrings;                                                                     //CHECK
                           AsCreate: Boolean = False): Boolean;
    // Used e.g. in scripting foreign keys
    function GetTableConstraints(ATableName: string; var SqlQuery: TSQLQuery;                                                                          //CHECK
                                 ConstraintsList: TStringList = nil): Boolean;
    function GetTableConstraints(const aTableName: string; var aSqlQry: TMDOQuery;                                                                     //CHECK
                                 ConstraintsList: TStringList = nil): Boolean;

    function GetAllConstraints(dbIndex: Integer; ConstraintsList, TablesList: TStringList): Boolean;                                                   //CHECK

    // Returns non-0 if foreign key constraint has a composite index (multiple fields)
    // Returns 0 otherwise
    // Expects array that has been filled by FillCompositeFKConstraints
    function GetCompositeFKConstraint(const ConstraintName: string; ConstraintsArray: TConstraintCounts): integer;                                     //CHECK

    function GetConstraintInfo(dbIndex: integer; ATableName, ConstraintName: string; var KeyName,                                                      //CHECK
        CurrentTableName, CurrentFieldName, OtherTableName, OtherFieldName, UpdateRule, DeleteRule: string): Boolean;

    // Gets information about exception.
    // Returns CREATE EXCEPTION statement in SQLQuery, or
    // CREATE OR ALTER EXCEPTION if CreateOrAlter is true
    function GetExceptionInfo(dbIndex: integer; ExceptionName: string; var Msg, Description, SqlQuery: string; CreateOrAlter: boolean): Boolean;       //CHECK
    // Gets information about domain
    procedure GetDomainInfo(dbIndex: integer; DomainName: string; var DomainType: string;                                                              //CHECK
      var DomainSize: Integer; var DefaultValue: string; var CheckConstraint: string; var CharacterSet: string; var Collation: string);
    function GetConstraintForeignKeyFields(AIndexName: string; SqlQuery: TSQLQuery): string;deprecated 'use the MDOQuery method';                      //CHECK
    function GetConstraintForeignKeyFields(AIndexName: string; aSqlQry: TMDOQuery): string;                                                            //CHECK

    function GetDBUsers(aDBIndex: Integer; ObjectName: string = ''): string;                                                                           //CHECK
    function GetDBUsers(adb: TDBInfo; ObjectName: string = ''): string;                                                                                //CHECK
    function GetDBObjectsForPermissions(dbIndex: Integer; AObjectType: Integer = -1): string;                                                          //CHECK
    function GetObjectUsers(dbIndex: Integer; ObjectName: string): string;                                                                             //CHECK
    function GetUserObjects(dbIndex: Integer; UserName: string; AObjectType: Integer = -1): string;                                                    //CHECK
    // Get permissions that specified user has for indicated object
    function GetObjectUserPermission(dbIndex: Integer; ObjectName, UserName: string; var ObjType: Integer): string;                                    //CHECK

    // Add field types into List
    procedure GetBasicTypes(List: TStrings);                                                                                                           //CHECK
    // Gets domain types; used in addition to basic types for GUI selections
    procedure GetDomainTypes(dbIndex: Integer; List: TStrings);
    function GetDefaultTypeSize(dbIndex: Integer; TypeName: string): Integer;                                                                          //CHECK
    function GetDomainTypeSize(dbIndex: Integer; DomainTypeName: string): Integer;                                                                     //CHECK

    // Gets details of field for given database/table/field
    function GetFieldInfo(dbIndex: Integer; TableName, FieldName: string; var FieldType: string;                                                       //CHECK
                          var FieldSize: integer; var FieldScale: integer; var NotNull: Boolean;
                          var DefaultValue, CharacterSet, Collation, Description : string): Boolean;

    function GetDatabaseInfo(dbIndex: Integer; var DatabaseName, CharSet, CreationDate, ServerTime: string;                                            //CHECK
                             var ODSVerMajor, ODSVerMinor, Pages, PageSize: Integer;
                             var ProcessList: TStringList; var ErrorMsg: string): Boolean;

    // Gets index info for a certain database+table
    function GetIndices(dbIndex: Integer; ATableName: string; PrimaryIndexName: string; var List: TStringList): Boolean;                               //CHECK

    // Gets all index info for a certain database
    function GetAllIndices(dbIndex: Integer; List, TablesList: TStringList): Boolean;                                                                  //CHECK

    // Gets index names associated with a primary key
    function GetPrimaryKeyIndexName(dbIndex: Integer; ATableName: string; var ConstraintName: string): string;                                         //CHECK

    function GetIndexInfo(dbIndex: Integer; ATableName, AIndexName: string;                                                                            //CHECK
                          var FieldsList: TStringList; var ConstraintName: string;
                          var Unique, Ascending, IsPrimary: Boolean): Boolean;

    // Gets field names for table
    procedure GetTableFields(dbIndex :Integer; aTableName :string; FieldTypes : array of Integer; FieldsList :TStrings);overload; deprecated'pass the dbinfo rec';//CHECK
    procedure GetTableFields(aDB :TDBInfo; aTableName :string; aFieldTypes : array of Integer; aFieldList :TStrings);overload;                         //CHECK
    procedure GetTableFields(aDB :TDBInfo; aTablename, aCondition :string; aFieldList :TStrings);overload;                                             //CHECK
    procedure GetTableFields(aDB :Integer; aTablename, aCondition :string; aFieldList :TStrings);overload;                                             //CHECK

    procedure GetTableNames(aDB :TDBInfo; aList:TStrings);                                                                                             //CHECK

    procedure CreateUser      (constref aDB:TDBInfo; aUserName,aPassword,aRole:String; const aTransaction:TMDOTransaction = nil);
    procedure GrandRolesToUser(Constref aDB:TDBInfo; aUserName, aRole:String; const aTransaction:TMDOTransaction = nil);
    procedure DeleteUser      (constref aDB:TDBInfo; aUserName:String; const aTransaction:TMDOTransaction = nil);
    procedure RevokeRoleFromUser(constref aDB:TDBInfo; aUserName, aRole:String; const aTransaction:TMDOTransaction = nil);

    function GetConstraintsOfTable(ATableName: string; const aSqlQuery: TMDOQuery; {var SqlQuery: TSQLQuery;} ConstraintsList: TStringList=nil): Boolean;//CHECK
  end;

function TestConnection(aDatabaseName, aUserName, aPassword, aRole, aCharset: string): Boolean;

procedure ValidateConnection(aDatabaseName, aUserName, aPassword, aRole, aCharset: string);

var
  dmSysTables: TdmSysTables;

implementation
{$R *.lfm}
uses main, topologicalsort;

var
  FConnectionPool :turbocommon.TEvsConnectionPool;

function DecToBin(Dec, Len: Byte): string;
var
  Temp: string;
  i: byte;
begin
  Temp:= '';
  for i:= 1 to Len do
  begin
    Temp:= Char((Dec mod 2) + 48) + Temp;
    Dec:= Dec shr 1;
  end;
  Result:= Temp;
end;

function TestConnection(aDatabaseName, aUserName, aPassword, aRole, aCharset :string) :Boolean;
begin
  Result := False;
  try
    ValidateConnection(aDatabaseName,aUserName,aPassword,aRole,aCharset);
    Result := True;
  except
    on E: Exception do begin  //add some short of intenral errorlist that can be used to iterate the past errors?
      if E is EIBDatabaseError then
        SendDebug(E.Message+LineEnding+'Error Code :'+inttostr(EIBDatabaseError(E).GDSErrorCode))
      else SendDebug(E.Message);
    end;
  end;
end;

procedure ValidateConnection(aDatabaseName, aUserName, aPassword, aRole, aCharset :string);
var
  vConn :TIBConnection;
begin
  vConn := TIBConnection.Create(Nil);
  try
      vConn.DatabaseName := aDatabaseName;
      vConn.UserName     := aUserName;
      vConn.Password     := aPassword;
      vConn.CharSet      := aCharset;
      vConn.Role         := aRole;
      vConn.Open;
  finally
    vConn.Free;
  end;
end;

{ TdmSysTables }

procedure TdmSysTables.Init(dbIndex: Integer);
begin
  //JKOZ : Deprecated and replaced, will be removed in the near future.
  // todo: first step: do not close, reopen Connect if we're using the correct
  // Connect/transaction already
  //with fmMain.RegisteredDatabases[dbIndex] do
  //begin
  //  if not IBConnection.Connected then begin
  //    IBConnection.DatabaseName := RegRec.DatabaseName;
  //    IBConnection.UserName     := RegRec.UserName;
  //    IBConnection.Password     := RegRec.Password;
  //    IBConnection.Role         := RegRec.Role;
  //    IBConnection.CharSet      := RegRec.Charset;
  //    IBConnection.Connected    := True;
  //  end;
  //  sqQuery.Close;
  //  ibcDatabase := IBConnection;
  //  stTrans:= SQLTrans;
  //  sqQuery.DataBase:= ibcDatabase;
  //  sqQuery.Transaction:= stTrans;
  //end;
  Init(fmMain.RegisteredDatabases[dbIndex]);
end;

procedure TdmSysTables.Init(aDB :TDBInfo);
begin
  // todo: first step: do not close, reopen Connect if we're using the correct
  // Connect/transaction already
  //JKOZ : there is no way to use the wrong Connect/transaction it uses the objects in the databaserec.
  //if ibcDatabase = aDB.IBConnection then Exit;

  if not aDB.Conn.Connected then begin
    Connect(adb.Conn, aDB.RegRec);
    //aDB.IBConnection.DatabaseName := aDB.RegRec.DatabaseName;
    //aDB.IBConnection.UserName     := aDB.RegRec.UserName;
    //aDB.IBConnection.Password     := aDB.RegRec.Password;
    //aDB.IBConnection.Role         := aDB.RegRec.Role;
    //aDB.IBConnection.CharSet      := aDB.RegRec.Charset;
    //aDB.IBConnection.Connected    := True;
  end;
  MDOQuery.Close;
  ibcDatabase := aDB.Conn;
  if aDB.Trans.Active then aDB.Trans.Active := False;
  stTrans := aDB.Trans;
  MDOQuery.DataBase    := ibcDatabase;
  MDOQuery.Transaction := stTrans;

  //MDO transfer
  if not IsConnectedTo(MDODatabase1, aDB.RegRec) then begin
    MDODatabase1.Connected := False;
    Connect(MDODatabase1, aDB.RegRec);
  end;
end;

function TdmSysTables.GetServerVersion :string;
var
  vQry : TMDOQuery;//TSqlQuery;
begin //fb 2.1 or newer only.
  vQry := GetQuery(ibcDatabase, 'SELECT rdb$get_context(''SYSTEM'', ''ENGINE_VERSION'') from rdb$database;', [], stTrans);
  try
    vQry.Active := True;
    Result      := vQry.Fields[0].AsString;
  finally
    ReleaseQuery(vQry);
  end;
end;

(*****  GetDBObjectNames, like Table names, Triggers, Generators, etc according to TVIndex  ****)

//function TdmSysTables.GetDBObjectNames(DatabaseIndex: integer; ObjectType: TObjectType; var Count: Integer): string;
//begin
//  GetDBObjectNames(fmMain.RegisteredDatabases[dbIndex], ObjectType, Count);
//end;

function TdmSysTables.GetDBObjectNames(const aDatabase :TDBInfo; aObjectType :TObjectType; var aCount :Integer) :string;
begin
  Init(aDatabase);
{$IFDEF EVS_New}
  //GetDBObjectNames(aDatabase, aObjectType, vList);
  OpenQuery(aObjectType);
  Result := '';
  while not MDOQuery.EOF do begin
    Result := Result + Trim(MDOQuery.Fields[0].AsString);
    MDOQuery.Next;
    if not MDOQuery.EOF then Result := Result + ',';
  end;
  aCount := MDOQuery.RecordCount;
  MDOQuery.Close;
{$ELSE}
  sqQuery.Close;
  if aObjectType         = otTables then // Tables
    sqQuery.SQL.Text := 'select rdb$relation_name from rdb$relations where rdb$view_blr is null ' +
                        'and (rdb$system_flag is null or rdb$system_flag = 0) order by rdb$relation_name'
  else if aObjectType    = otGenerators then // Generators
    sqQuery.SQL.Text := 'select RDB$GENERATOR_Name from RDB$GENERATORS where RDB$SYSTEM_FLAG = 0 order by rdb$generator_Name'
  else if aObjectType    = otTriggers then // Triggers
    sqQuery.SQL.Text := 'SELECT rdb$Trigger_Name FROM RDB$TRIGGERS WHERE RDB$SYSTEM_FLAG=0 order by rdb$Trigger_Name'
  else if aObjectType    = otViews then // Views
    sqQuery.SQL.Text := 'SELECT DISTINCT RDB$VIEW_NAME FROM RDB$VIEW_RELATIONS order by rdb$View_Name'
  else if aObjectType    = otStoredProcedures then // Stored Procedures
    sqQuery.SQL.Text := 'SELECT RDB$Procedure_Name FROM RDB$PROCEDURES order by rdb$Procedure_Name'
  else if aObjectType    = otUDF then // UDF
    sqQuery.SQL.Text := 'SELECT RDB$FUNCTION_NAME FROM RDB$FUNCTIONS where RDB$SYSTEM_FLAG=0 order by rdb$Function_Name'
  else if aObjectType    = otSystemTables then // System Tables
    sqQuery.SQL.Text := 'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS where RDB$SYSTEM_FLAG=1 ' +
                        'order by RDB$RELATION_NAME'
  else if aObjectType    = otDomains then // Domains, excluding system-defined domains
    sqQuery.SQL.Text := 'select RDB$FIELD_NAME from RDB$FIELDS where RDB$Field_Name not like ''RDB$%''  order by rdb$Field_Name'
  else if aObjectType    = otRoles then // Roles
    sqQuery.SQL.Text := 'select RDB$ROLE_NAME from RDB$ROLES order by rdb$Role_Name'
  else if aObjectType    = otExceptions then // Exceptions
    sqQuery.SQL.Text := 'select RDB$EXCEPTION_NAME from RDB$EXCEPTIONS order by rdb$Exception_Name'
  else if aObjectType    = otUsers then // Users
    sqQuery.SQL.Text := 'select distinct RDB$User from RDB$USER_PRIVILEGES where RDB$User_Type = 8 order by rdb$User';

  sqQuery.Open;
  sqQuery.First;
  while not sqQuery.EOF do begin
    Result := Result + Trim(sqQuery.Fields[0].AsString);
    sqQuery.Next;
    if not sqQuery.EOF then Result:= Result + ',';
  end;
  aCount := sqQuery.RecordCount;
  sqQuery.Close;
  stTrans.Rollback;
{$ENDIF}
end;

function TdmSysTables.GetDBObjectNames(const aDatabase :TDBInfo; aObjectType :TObjectType; aList :TStrings) :integer;
begin
  Init(aDatabase);
  {$IFDEF EVS_New}
  OpenQuery(aObjectType);
  {$ELSE}
  sqQuery.Close;
  if aObjectType         = otTables then // Tables
    sqQuery.SQL.Text := 'select rdb$relation_name from rdb$relations where rdb$view_blr is null ' +
                        'and (rdb$system_flag is null or rdb$system_flag = 0) order by rdb$relation_name'
  else if aObjectType    = otGenerators then // Generators
    sqQuery.SQL.Text := 'select RDB$GENERATOR_Name from RDB$GENERATORS where RDB$SYSTEM_FLAG = 0 order by rdb$generator_Name'
  else if aObjectType    = otTriggers then // Triggers
    sqQuery.SQL.Text := 'SELECT rdb$Trigger_Name FROM RDB$TRIGGERS WHERE RDB$SYSTEM_FLAG=0 order by rdb$Trigger_Name'
  else if aObjectType    = otViews then // Views
    sqQuery.SQL.Text := 'SELECT DISTINCT RDB$VIEW_NAME FROM RDB$VIEW_RELATIONS order by rdb$View_Name'
  else if aObjectType    = otStoredProcedures then // Stored Procedures
    sqQuery.SQL.Text := 'SELECT RDB$Procedure_Name FROM RDB$PROCEDURES order by rdb$Procedure_Name'
  else if aObjectType    = otUDF then // UDF
    sqQuery.SQL.Text := 'SELECT RDB$FUNCTION_NAME FROM RDB$FUNCTIONS where RDB$SYSTEM_FLAG=0 order by rdb$Function_Name'
  else if aObjectType    = otSystemTables then // System Tables
    sqQuery.SQL.Text := 'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS where RDB$SYSTEM_FLAG=1 ' +
                        'order by RDB$RELATION_NAME'
  else if aObjectType    = otDomains then // Domains, excluding system-defined domains
    sqQuery.SQL.Text := 'select RDB$FIELD_NAME from RDB$FIELDS where RDB$Field_Name not like ''RDB$%''  order by rdb$Field_Name'
  else if aObjectType    = otRoles then // Roles
    sqQuery.SQL.Text := 'select RDB$ROLE_NAME from RDB$ROLES order by rdb$Role_Name'
  else if aObjectType    = otExceptions then // Exceptions
    sqQuery.SQL.Text := 'select RDB$EXCEPTION_NAME from RDB$EXCEPTIONS order by rdb$Exception_Name'
  else if aObjectType    = otUsers then // Users
    sqQuery.SQL.Text := 'select distinct RDB$User from RDB$USER_PRIVILEGES where RDB$User_Type = 8 order by rdb$User';

  sqQuery.Open;
  sqQuery.First;
  {$ENDIF}
  aList.Clear;
  while not MDOQuery.EOF do begin
    aList.Add(Trim(MDOQuery.Fields[0].AsString));
    MDOQuery.Next;
  end;
  MDOQuery.Close;
  stTrans.Rollback;//no long leaved transactions please.
  Result := aList.Count;
end;

function TdmSysTables.RecalculateIndexStatistics(dbIndex: integer): boolean;
var
  i: integer;
  Indices, Tables: TStringList;
  TransActive: boolean;
begin
  result:= false;
  Init(dbIndex);
  MDOQuery.Close;
  Indices:= TStringList.Create;
  Tables:= TStringList.Create;
  try
    if not(GetAllIndices(dbIndex, Indices, Tables)) then
    begin
      {$IFDEF DEBUG}
      SendDebug('RecalculateIndexStatistics: GetAllIndices call failed.');
      {$ENDIF}
      exit(false);
    end;

    // Loop through all indices and reset statistics
    TransActive:= stTrans.Active;
    if (TransActive) then
      stTrans.Commit;
    for i:= 0 to Indices.Count-1 do
    begin
      stTrans.StartTransaction;
      MDOQuery.SQL.Text:= format('SET statistics INDEX %s',[Indices[i]]);
      MDOQuery.ExecSQL;
      { Commit after each index; no need to batch it all up in one
      big atomic transaction...}
      stTrans.Commit;
    end;
    if TransActive then
      stTrans.StartTransaction; //leave transaction the way we found it
  finally
    Indices.Free;
    Tables.Free;
  end;
  result:= true;
end;

procedure TdmSysTables.SortDependencies(var ObjectList: TStringList);
const
  QueryTemplate =
    'select rdb$dependent_name, ' +
    ' rdb$depended_on_name, ' +
    ' rdb$dependent_type, '+
    ' rdb$depended_on_type '+
    ' from rdb$dependencies ';
var
  i: integer;
  TopSort: TTopologicalSort;
begin
  TopSort:= TTopologicalSort.Create;
  try
    MDOQuery.SQL.Text:= QueryTemplate;
    MDOQuery.Open;
    // First add all objects that should end up as results without any depdencies
    for i:=0 to ObjectList.Count-1 do
    begin
      TopSort.AddNode(ObjectList[i]);
    end;
    // Now add dependencies:
    while not MDOQuery.EOF do
    begin
      for i:=0 to ObjectList.Count-1 do
      begin
        if trim(MDOQuery.FieldByName('rdb$dependent_name').AsString)=uppercase(ObjectList[i]) then
          begin
            // Get kind of object using dependency type in query;
            // limit to same category (i.e. all views or all stored procedures)
            if MDOQuery. FieldByName('rdb$dependent_type').AsInteger=
              MDOQuery. FieldByName('rdb$depended_on_type').AsInteger then
              TopSort.AddDependency(
                trim(MDOQuery.FieldByName('rdb$dependent_name').AsString),
                trim(MDOQuery.FieldByName('rdb$depended_on_name').AsString));
          end;
      end;
      MDOQuery.Next;
    end;
    MDOQuery.Close;
    // Resulting sorted list should end up in ObjectList:
    ObjectList.Clear;
    TopSort.Sort(ObjectList);
  finally
    TopSort.Free;
  end;
end;

(***********  Get Trigger Info  ***************)

function TdmSysTables.GetTriggerInfo(DatabaseIndex: Integer; ATriggername: string;
  var AfterBefore, OnTable, Event, Body: string; var TriggerEnabled: Boolean; var TriggerPosition: Integer): Boolean;
var
  Encode: string;
begin
  try
    Init(DatabaseIndex);
    MDOQuery.Close;
    MDOQuery.SQL.Text:= 'SELECT RDB$TRIGGER_NAME AS trigger_name, ' +
      '  RDB$RELATION_NAME AS table_name, ' +
      '  RDB$TRIGGER_SOURCE AS trigger_body, ' +
      '  RDB$TRIGGER_TYPE as Trigger_Type, ' +
      '  RDB$Trigger_Sequence as TPos, ' +
      '   CASE RDB$TRIGGER_INACTIVE ' +
      '   WHEN 1 THEN 0 ELSE 1 ' +
      ' END AS trigger_enabled, ' +
      ' RDB$DESCRIPTION AS trigger_comment ' +
      ' FROM RDB$TRIGGERS ' +
      ' WHERE UPPER(RDB$TRIGGER_NAME)=''' + ATriggerName + ''' ';

    MDOQuery.Open;
    Body:= Trim(MDOQuery.FieldByName('Trigger_Body').AsString);
    OnTable:= Trim(MDOQuery.FieldByName('Table_Name').AsString);
    TriggerEnabled:= MDOQuery.FieldByName('Trigger_Enabled').AsBoolean;
    TriggerPosition:= MDOQuery.FieldByName('TPos').AsInteger;
    Encode:= DecToBin(MDOQuery.FieldByName('Trigger_Type').AsInteger + 1, 7);
    if Encode[7] = '1' then
      AfterBefore:= 'After'
    else
      AfterBefore:= 'Before';
    Delete(Encode, 7, 1);
    Event:= '';
    while Length(Encode) > 0 do
    begin
      if Copy(Encode, Length(Encode) - 1, 2) = '01' then
        Event:= Event + 'Insert'
      else
      if Copy(Encode, Length(Encode) - 1, 2) = '10' then
        Event:= Event + 'Update'
      else
      if Copy(Encode, Length(Encode) - 1, 2) = '11' then
        Event:= Event + 'Delete';
      Delete(Encode, Length(Encode) - 1, 2);
      if (Encode <> '') and (Copy(Encode, Length(Encode) - 1, 2) <> '00') then
        Event:= Event + ' or ';
    end;
    MDOQuery.Close;
    Result:= True;
  except
    on E: Exception do
    begin
      MessageDlg('Error: ' + e.Message, mtError, [mbOk], 0);
      Result:= False;
    end;
  end;
end;

function TdmSysTables.ScriptCheckConstraints(dbIndex: Integer; List: TStrings
  ): boolean;
const
  QueryTemplate='select '+
    'rc.rdb$relation_name, t.rdb$trigger_source '+
    'from rdb$check_constraints cc '+
    'inner join rdb$relation_constraints rc '+
    'on cc.rdb$constraint_name=rc.rdb$constraint_name '+
    'inner join rdb$triggers t '+
    'on cc.rdb$trigger_name=t.rdb$trigger_name '+
    'where rc.rdb$constraint_type=''CHECK'' and '+
    't.rdb$trigger_inactive<>1 and '+
    't.rdb$trigger_type=1' {type=1:before insert probably};
begin
  Result:= false;
  List.Clear;
  try
    Init(dbIndex);
    MDOQuery.Close;
    MDOQuery.SQL.Text:= QueryTemplate;
    MDOQuery.Open;
    while not MDOQuery.EOF do
    begin
      List.Add(Format('ALTER TABLE %s ADD ',
        [trim(MDOQuery.FieldByName('rdb$relation_name').AsString)]));
      // Field starts with CHECK
      List.Add(trim(MDOQuery.FieldByName('rdb$trigger_source').AsString)+';');
      MDOQuery.Next;
    end;
    MDOQuery.Close;
    Result:= True;
  except
    on E: Exception do
    begin
      MessageDlg('Error: ' + e.Message, mtError, [mbOk], 0);
    end;
  end;
end;

(****************  Script Trigger  ***************)

function TdmSysTables.ScriptTrigger(dbIndex: Integer; ATriggerName: string;
  List: TStrings; AsCreate: Boolean): Boolean;
var
  Body: string;
  AfterBefore: string;
  Event: string;
  OnTable: string;
  TriggerEnabled: Boolean;
  TriggerPosition: Integer;
begin
  Result:= GetTriggerInfo(dbIndex, ATriggerName, AfterBefore, OnTable, Event, Body, TriggerEnabled, TriggerPosition);
  if Result then
  begin
    List.Add('SET TERM ^ ;');
    if AsCreate then
      List.Add('Create Trigger ' + ATriggerName + ' for ' + OnTable)
    else
      List.Add('Alter Trigger ' + ATriggerName);
      if TriggerEnabled then
        List.Add('ACTIVE')
      else
        List.Add('INACTIVE');

    List.Add(AfterBefore + ' ' + Event);
    List.Add('Position ' + IntToStr(TriggerPosition));

    List.Text:= List.Text + Body + ' ^';
    List.Add('SET TERM ; ^');
  end;
end;

(**********  Get Table Constraints Info  ********************)

function TdmSysTables.GetTableConstraints(ATableName: string; var SqlQuery: TSQLQuery;
   ConstraintsList: TStringList = nil): Boolean;
const
  // Note that this query differs from the way constraints are
  // presented in GetConstraintsOfTable.
  // to do: find out what the differences are and indicate better in code/comments
  QueryTemplate='select '+
    'trim(rc.rdb$constraint_name) as ConstName, '+
    'trim(rfc.rdb$const_name_uq) as KeyName, '+
    'trim(rc2.rdb$relation_name) as OtherTableName, '+
    'trim(flds_pk.rdb$field_name) as OtherFieldName, '+
    'trim(rc.rdb$relation_name) as CurrentTableName, '+
    'trim(flds_fk.rdb$field_name) as CurrentFieldName, '+
    'trim(rfc.rdb$update_rule) as UpdateRule, '+
    'trim(rfc.rdb$delete_rule) as DeleteRule '+
    'from rdb$relation_constraints AS rc '+
    'inner join rdb$ref_constraints as rfc on (rc.rdb$constraint_name = rfc.rdb$constraint_name) '+
    'inner join rdb$index_segments as flds_fk on (flds_fk.rdb$index_name = rc.rdb$index_name) ' +
    'inner join rdb$relation_constraints as rc2 on (rc2.rdb$constraint_name = rfc.rdb$const_name_uq) ' +
    'inner join rdb$index_segments as flds_pk on ' +
    '((flds_pk.rdb$index_name = rc2.rdb$index_name) and (flds_fk.rdb$field_position = flds_pk.rdb$field_position)) ' +
    'where rc.rdb$constraint_type = ''FOREIGN KEY'' '+
    'and rc.rdb$relation_name = ''%s'' '+
    'order by rc.rdb$constraint_name, flds_fk.rdb$field_position ';
begin
  SqlQuery.Close;
  SQLQuery.SQL.Text:= format(QueryTemplate, [UpperCase(ATableName)]);
  SqlQuery.Open;
  Result:= SqlQuery.RecordCount > 0;
  with SqlQuery do
  if Result and Assigned(ConstraintsList) then
  begin
    ConstraintsList.Clear;
    while not Eof do
    begin
      ConstraintsList.Add(FieldByName('ConstName').AsString);
      Next;
    end;
    First;
  end;
end;

function TdmSysTables.GetTableConstraints(const aTableName :string; var aSqlQry :TMDOQuery; ConstraintsList :TStringList) :Boolean;
const
  // Note that this query differs from the way constraints are
  // presented in GetConstraintsOfTable.
  // to do: find out what the differences are and indicate better in code/comments
  QueryTemplate='select '+
    'trim(rc.rdb$constraint_name) as ConstName, '+
    'trim(rfc.rdb$const_name_uq) as KeyName, '+
    'trim(rc2.rdb$relation_name) as OtherTableName, '+
    'trim(flds_pk.rdb$field_name) as OtherFieldName, '+
    'trim(rc.rdb$relation_name) as CurrentTableName, '+
    'trim(flds_fk.rdb$field_name) as CurrentFieldName, '+
    'trim(rfc.rdb$update_rule) as UpdateRule, '+
    'trim(rfc.rdb$delete_rule) as DeleteRule '+
    'from rdb$relation_constraints AS rc '+
    'inner join rdb$ref_constraints as rfc on (rc.rdb$constraint_name = rfc.rdb$constraint_name) '+
    'inner join rdb$index_segments as flds_fk on (flds_fk.rdb$index_name = rc.rdb$index_name) ' +
    'inner join rdb$relation_constraints as rc2 on (rc2.rdb$constraint_name = rfc.rdb$const_name_uq) ' +
    'inner join rdb$index_segments as flds_pk on ' +
    '((flds_pk.rdb$index_name = rc2.rdb$index_name) and (flds_fk.rdb$field_position = flds_pk.rdb$field_position)) ' +
    'where rc.rdb$constraint_type = ''FOREIGN KEY'' '+
    'and rc.rdb$relation_name = ''%s'' '+
    'order by rc.rdb$constraint_name, flds_fk.rdb$field_position ';
begin
  aSqlQry.Close;
  aSqlQry.SQL.Text:= format(QueryTemplate, [UpperCase(ATableName)]);
  aSqlQry.Open;
  Result:= aSqlQry.RecordCount > 0;
  with aSqlQry do
    if Result and Assigned(ConstraintsList) then begin
      First;
      ConstraintsList.Clear;
      while not Eof do begin
        ConstraintsList.Add(FieldByName('ConstName').AsString);
        Next;
      end;
      First;
    end;
end;

(**********  Get Constraints for a table Info  ********************)

function TdmSysTables.GetConstraintsOfTable(ATableName :string; const aSqlQuery :TMDOQuery; ConstraintsList :TStringList) :Boolean;
begin
  aSqlQuery.Close;
  aSQLQuery.SQL.Text := 'select '+
                       'trim(rc.rdb$constraint_name) as ConstName, '+
                       'trim(rfc.rdb$const_name_uq) as KeyName, '+
                       'trim(rc2.rdb$relation_name) as CurrentTableName, '+
                       'trim(flds_pk.rdb$field_name) as CurrentFieldName, '+
                       'trim(rc.rdb$relation_name) as OtherTableName, '+
                       'trim(flds_fk.rdb$field_name) as OtherFieldName, '+
                       'trim(rfc.rdb$update_rule) as UpdateRule, '+
                       'trim(rfc.rdb$delete_rule) as DeleteRule '+
                       'from rdb$relation_constraints AS rc '+
                       'inner join rdb$ref_constraints as rfc on (rc.rdb$constraint_name = rfc.rdb$constraint_name) '+
                       'inner join rdb$index_segments as flds_fk on (flds_fk.rdb$index_name = rc.rdb$index_name) ' +
                       'inner join rdb$relation_constraints as rc2 on (rc2.rdb$constraint_name = rfc.rdb$const_name_uq) ' +
                       'inner join rdb$index_segments as flds_pk on ' +
                       '((flds_pk.rdb$index_name = rc2.rdb$index_name) and (flds_fk.rdb$field_position = flds_pk.rdb$field_position)) ' +
                       'where rc.rdb$constraint_type = ''FOREIGN KEY'' '+
                       'and rc2.rdb$relation_name = ''' + UpperCase(ATableName) + ''' '+
                       'order by rc.rdb$constraint_name, flds_fk.rdb$field_position ';
  aSqlQuery.Open;
  Result:= aSqlQuery.RecordCount > 0;
  with aSqlQuery do
  if Result and Assigned(ConstraintsList) then
  begin
    ConstraintsList.Clear;
    while not Eof do
    begin
      ConstraintsList.Add(FieldByName('ConstName').AsString);
      Next;
    end;
    First;
  end;

end;

function TdmSysTables.GetAllConstraints(dbIndex: Integer; ConstraintsList, TablesList: TStringList): Boolean;
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'select Trim(Refc.RDB$Constraint_Name) as ConstName, ' +
    'Trim(Refc.RDB$CONST_NAME_UQ) as KeyName, ' +
    'Trim(Ind.RDB$Relation_Name) as CurrentTableName, ' +
    'Trim(Seg.RDB$Field_name) as CurrentFieldName, ' +
    'Trim(Con.RDB$Relation_Name) as OtherTableName, ' +
    'Trim(Ind.RDB$Foreign_key) as OtherFieldName, ' +
    'RDB$Update_Rule as UpdateRule, RDB$Delete_Rule as DeleteRule ' +
    'from RDB$RELATION_CONSTRAINTS Con, rdb$REF_Constraints Refc, RDB$INDEX_SEGMENTS Seg, ' +
    'RDB$INDICES Ind ' +
    'where Con.RDB$COnstraint_Name = Refc.RDB$Const_Name_UQ ' +
    '  and Refc.RDB$COnstraint_Name = Ind.RDB$Index_Name' +
    '  and Refc.RDB$COnstraint_Name = Seg.RDB$Index_Name';
  MDOQuery.Open;
  Result:= MDOQuery.RecordCount > 0;
  with MDOQuery do
  if Result then
  begin
    ConstraintsList.Clear;
    if Assigned(TablesList) then
      TablesList.Clear;
    while not Eof do
    begin
      ConstraintsList.Add(FieldByName('ConstName').AsString);
      if Assigned(TablesList) then
        TablesList.Add(FieldByName('CurrentTableName').AsString);
      Next;
    end;
  end;
  MDOQuery.Close;
end;

procedure TdmSysTables.OpenQuery(aObjectType :TObjectType);
const
                  //otUnknown, otTables,  otGenerators,  otTriggers, otViews,   otStoredProcedures,
                  //otUDFs,    otDomains, otSystemTables,
                  //otRoles,  otExceptions, otUsers,   otIndexes, otConstraints);

  cObjectSQL :array[TObjectType] of string =('',                                         //otunknown
     'select rdb$relation_name from rdb$relations where rdb$view_blr is null ' +
     ' and (rdb$system_flag is null or rdb$system_flag = 0) order by rdb$relation_name', //tables

     'select RDB$GENERATOR_Name from RDB$GENERATORS where RDB$SYSTEM_FLAG = 0 order by rdb$generator_Name',//generators
     '',
     '',
     '',
     '',
     '',
     '',
     '',
     '',
     '',
     '',
     '');


{$IFDEF DEBUG}
var
  vSQL : string;
{$ENDIF}
begin
  MDOQuery.Close;
  if aObjectType         = otTables then // Tables
    MDOQuery.SQL.Text := 'select rdb$relation_name from rdb$relations where rdb$view_blr is null ' +
                         ' and (rdb$system_flag is null or rdb$system_flag = 0) order by rdb$relation_name'
  else if aObjectType    = otGenerators then // Generators
    MDOQuery.SQL.Text := 'select RDB$GENERATOR_Name from RDB$GENERATORS where RDB$SYSTEM_FLAG = 0 order by rdb$generator_Name'
  else if aObjectType    = otTriggers then // Triggers
    MDOQuery.SQL.Text := 'SELECT rdb$Trigger_Name FROM RDB$TRIGGERS WHERE RDB$SYSTEM_FLAG=0 order by rdb$Trigger_Name'
  else if aObjectType    = otViews then // Views
    MDOQuery.SQL.Text := 'SELECT DISTINCT RDB$VIEW_NAME FROM RDB$VIEW_RELATIONS order by rdb$View_Name'
  else if aObjectType    = otStoredProcedures then // Stored Procedures
    MDOQuery.SQL.Text := 'SELECT RDB$Procedure_Name FROM RDB$PROCEDURES order by rdb$Procedure_Name'
  else if aObjectType    = otUDFs then // UDF
    MDOQuery.SQL.Text := 'SELECT RDB$FUNCTION_NAME FROM RDB$FUNCTIONS where RDB$SYSTEM_FLAG=0 order by rdb$Function_Name'
  else if aObjectType    = otSystemTables then // System Tables
    MDOQuery.SQL.Text := 'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS where RDB$SYSTEM_FLAG=1 ' +
                        'order by RDB$RELATION_NAME'
  else if aObjectType    = otDomains then // Domains, excluding system-defined domains
    MDOQuery.SQL.Text := 'select RDB$FIELD_NAME from RDB$FIELDS where RDB$Field_Name not like ''RDB$%''  order by rdb$Field_Name'
  else if aObjectType    = otRoles then // Roles
    MDOQuery.SQL.Text := 'select RDB$ROLE_NAME from RDB$ROLES order by rdb$Role_Name'
  else if aObjectType    = otExceptions then // Exceptions
    MDOQuery.SQL.Text := 'select RDB$EXCEPTION_NAME from RDB$EXCEPTIONS order by rdb$Exception_Name'
  else if aObjectType    = otUsers then // Users
    MDOQuery.SQL.Text := 'select distinct RDB$User from RDB$USER_PRIVILEGES where RDB$User_Type = 8 order by rdb$User';

  // Save the result list as comma delimited string
  {$IFDEF DEBUG}
  vSQL := MDOQuery.SQL.Text;
  {$ENDIF}
  MDOQuery.SQL.Text := MDOQuery.SQL.Text;
  MDOQuery.Open;
  MDOQuery.First;
end;

procedure TdmSysTables.FillCompositeFKConstraints(const TableName: string;
  var ConstraintsArray: TConstraintCounts);
const
  // For specified table, returns foreign key constraints and count
  // if it has a composite key (i.e. multiple foreign key fields).
  // Based on query in GetTableConstraints
  CompositeCountSQL =
   'select trim(rc.rdb$constraint_name) as ConstName, '+
   'count(rfc.rdb$const_name_uq) as KeyCount '+
   'from rdb$relation_constraints AS rc '+
   'inner join rdb$ref_constraints as rfc on (rc.rdb$constraint_name = rfc.rdb$constraint_name) '+
   'inner join rdb$index_segments as flds_fk on (flds_fk.rdb$index_name = rc.rdb$index_name) '+
   'inner join rdb$relation_constraints as rc2 on (rc2.rdb$constraint_name = rfc.rdb$const_name_uq) '+
   'inner join rdb$index_segments as flds_pk on '+
   '((flds_pk.rdb$index_name = rc2.rdb$index_name) and (flds_fk.rdb$field_position = flds_pk.rdb$field_position)) '+
   'where rc.rdb$constraint_type = ''FOREIGN KEY'' and '+
   'upper(rc.rdb$relation_name) = ''%s'' '+
   'group by rc.rdb$constraint_name '+
   'having count(rfc.rdb$const_name_uq)>1 '+
   'order by rc.rdb$constraint_name ';
var
  CompositeQuery: TMDOQuery;// TSQLQuery;
  i:integer;
begin
  CompositeQuery:= TMDOQuery.Create(nil);
  try
    CompositeQuery.DataBase:= ibcDatabase;
    CompositeQuery.Transaction:= stTrans;
    CompositeQuery.SQL.Text:= Format(CompositeCountSQL,[TableName]);
    CompositeQuery.Open;
    CompositeQuery.Last; //needed for accurate recordcount
    if CompositeQuery.RecordCount=0 then
    begin
      SetLength(ConstraintsArray,0);
    end
    else
    begin
      SetLength(ConstraintsArray,CompositeQuery.RecordCount);
      i:= 0;
      CompositeQuery.First;
      while not(CompositeQuery.EOF) do
      begin
        ConstraintsArray[i].Name:= CompositeQuery.FieldByName('ConstName').AsString;
        ConstraintsArray[i].Count:= CompositeQuery.FieldByName('KeyCount').AsInteger;
        CompositeQuery.Next;
        inc(i);
      end;
    end;
    CompositeQuery.Close;
  finally
    CompositeQuery.Free;
  end;
end;

function TdmSysTables.GetCompositeFKConstraint(const ConstraintName: string; ConstraintsArray: TConstraintCounts): integer;
var
  i: integer;
begin
  result:= 0;
  for i:= low(ConstraintsArray) to high(ConstraintsArray) do
  begin
    if ConstraintsArray[i].Name=ConstraintName then
    begin
      result:= ConstraintsArray[i].Count;
      break;
    end;
  end;
end;

(**********  Get Constraint Info  ********************)

function TdmSysTables.GetConstraintInfo(dbIndex :integer; ATableName, ConstraintName :string; var KeyName, CurrentTableName, CurrentFieldName,
  OtherTableName, OtherFieldName, UpdateRule, DeleteRule :string) :Boolean;
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'select Trim(Refc.RDB$Constraint_Name) as ConstName, Trim(Refc.RDB$CONST_NAME_UQ) as KeyName, ' +
    'Trim(Ind.RDB$Relation_Name) as CurrentTableName, ' +
    'Trim(Seg.RDB$Field_name) as CurrentFieldName, ' +
    'Trim(Con.RDB$Relation_Name) as OtherTableName, ' +
    'Trim(Ind.RDB$Foreign_key) as OtherFieldName, ' +
    'RDB$Update_Rule as UpdateRule, RDB$Delete_Rule as DeleteRule ' +
    'from RDB$RELATION_CONSTRAINTS Con, rdb$REF_Constraints Refc, RDB$INDEX_SEGMENTS Seg, ' +
    'RDB$INDICES Ind ' +
    'where Con.RDB$COnstraint_Name = Refc.RDB$Const_Name_UQ ' +
    '  and Refc.RDB$COnstraint_Name = Ind.RDB$Index_Name' +
    '  and Refc.RDB$COnstraint_Name = Seg.RDB$Index_Name' +
    '  and Ind.RDB$Relation_Name = ' + QuotedStr(UpperCase(ATableName)) + ' ' +
    '  and Refc.RDB$Constraint_Name = ' + QuotedStr(ConstraintName);
  MDOQuery.Open;
  Result:= MDOQuery.RecordCount > 0;
  with MDOQuery do
  if Result then
  begin
    KeyName:= FieldByName('KeyName').AsString;
    CurrentTableName:= FieldByName('CurrentTableName').AsString;
    CurrentFieldName:= FieldByName('CurrentFieldName').AsString;
    OtherTableName:= FieldByName('OtherTableName').AsString;
    OtherFieldName:= FieldByName('OtherFieldName').AsString;
    UpdateRule:= FieldByName('UpdateRule').AsString;
    DeleteRule:= FieldByName('DeleteRule').AsString;
  end;
  MDOQuery.Close;

end;

(*********  Get Exception Info ***************)

function TdmSysTables.GetExceptionInfo(dbIndex: integer; ExceptionName: string; var Msg, Description,
  SqlQuery: string; CreateOrAlter: boolean): Boolean;
var
  CreatePart: string;
begin
  MDOQuery.Close;
  init(dbIndex);
  MDOQuery.SQL.Text:= 'select * from RDB$EXCEPTIONS ' +
   'where RDB$EXCEPTION_NAME = ' + QuotedStr(ExceptionName);
  MDOQuery.Open;
  Result:= MDOQuery.RecordCount > 0;
  if Result then
  begin
    if CreateOrAlter then
      CreatePart:= 'CREATE OR ALTER EXCEPTION ' {Since Firebird 2.0; create or replace existing}
    else
      CreatePart:= 'CREATE EXCEPTION ';
    Msg:= MDOQuery.FieldByName('RDB$MESSAGE').AsString;
    Description:= MDOQuery.FieldByName('RDB$DESCRIPTION').AsString;
    SqlQuery:= CreatePart + ExceptionName + LineEnding +
      QuotedStr(Msg) + ';';
    if Description<>'' then
      SQLQuery:= SQLQuery + LineEnding +
        'UPDATE RDB$EXCEPTIONS set ' + LineEnding +
        'RDB$DESCRIPTION = ''' + Description + ''' ' + LineEnding +
        'where RDB$EXCEPTION_NAME = ''' + ExceptionName + ''';';
  end;
  MDOQuery.Close;
end;


(************  View Domain info  ***************)

procedure TdmSysTables.GetDomainInfo(dbIndex :integer; DomainName :string; var DomainType :string; var DomainSize :Integer; var DefaultValue :string;
  var CheckConstraint :string; var CharacterSet :string; var Collation :string);
const
  // Select domain and associated collation (if text type domain)
  // note weird double join fields required...
  //
  QueryTemplate= 'select f.*, '+
    'coll.rdb$collation_name, '+
    'cs.rdb$character_set_name '+
    'from rdb$fields as f '+
    'left join '+
    { the entire inner join in the next part is treated as one entity that
    is left outer joined. Result: you get collation info with associated
    character set or just NULL }
    '( '+
    'rdb$collations as coll '+
    'inner join rdb$character_sets as cs on '+
    'coll.rdb$character_set_id=cs.rdb$character_set_id '+
    ') '+
    'on f.rdb$collation_id=coll.rdb$collation_id and '+
    'f.rdb$character_set_id=coll.rdb$character_set_id '+
    'where f.rdb$field_name=''%s'' ';
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= format(QueryTemplate, [UpperCase(DomainName)]);
  {$IFDEF NEVER}
  // Left for debugging
  SendDebug(MDOQuery.SQL.Text);
  {$ENDIF}
  MDOQuery.Open;

  if MDOQuery.RecordCount > 0 then
  begin
    DomainType:= GetFBTypeName(MDOQuery.FieldByName('RDB$FIELD_TYPE').AsInteger,
      MDOQuery.FieldByName('RDB$FIELD_SUB_TYPE').AsInteger,
      MDOQuery.FieldByName('RDB$FIELD_LENGTH').AsInteger,
      MDOQuery.FieldByName('RDB$FIELD_PRECISION').AsInteger,
      MDOQuery.FieldByName('RDB$FIELD_SCALE').AsInteger);
    DomainSize:= MDOQuery.FieldByName('RDB$FIELD_LENGTH').AsInteger;
    DefaultValue:= trim(MDOQuery.FieldByName('RDB$DEFAULT_SOURCE').AsString);
    CheckConstraint:= trim(MDOQuery.FieldByName('RDB$VALIDATION_SOURCE').AsString); //e.g. CHECK (VALUE > 10000 AND VALUE <= 2000000)
    CharacterSet:= trim(MDOQuery.FieldByName('rdb$character_set_name').AsString);
    Collation:= trim(MDOQuery.FieldByName('rdb$collation_name').AsString);
  end
  else
    DomainSize:= 0;
  MDOQuery.Close;
end;


(*************  Get constraint foreign key fields  *************)

function TdmSysTables.GetConstraintForeignKeyFields(AIndexName: string; SqlQuery: TSQLQuery): string;
begin
  SQLQuery.Close;
  SQLQuery.SQL.Text:= 'select RDB$Index_Name as IndexName, RDB$Field_name as FieldName from RDB$INDEX_SEGMENTS ' +
    'where RDB$Index_name = ' + QuotedStr(UpperCase(Trim(AIndexName)));
  SQLQuery.Open;
  while not SQLQuery.EOF do
  begin
    Result:= Result + Trim(SQLQuery.FieldByName('FieldName').AsString);
    SQLQuery.Next;
    if not SQLQuery.EOF then
      Result:= Result + ',';
  end;
  SQLQuery.Close;
end;

function TdmSysTables.GetConstraintForeignKeyFields(AIndexName :string; aSqlQry :TMDOQuery) :string;
begin
  aSqlQry.Close;
  aSqlQry.SQL.Text:= 'select RDB$Index_Name as IndexName, RDB$Field_name as FieldName from RDB$INDEX_SEGMENTS ' +
                     'where RDB$Index_name = ' + QuotedStr(UpperCase(Trim(AIndexName)));
  aSqlQry.Open;
  while not aSqlQry.EOF do begin
    Result:= Result + Trim(aSqlQry.FieldByName('FieldName').AsString);
    aSqlQry.Next;
    if not aSqlQry.EOF then
      Result:= Result + ',';
  end;
  aSqlQry.Close;
end;


(************  Get Database Users  ************)

function TdmSysTables.GetDBUsers(aDBIndex: Integer; ObjectName: string = ''): string;
begin
  {$IFDEF EVS_New}
    GetDBUsers(fmMain.RegisteredDatabases[aDBIndex]);
  {$ENDIF}
  {$IFDEF EVS_OLD}
  Init(dbIndex);
  sqQuery.Close;
  sqQuery.SQL.Text:= 'select distinct RDB$User, RDB$User_Type from RDB$USER_PRIVILEGES ';
  if ObjectName <> '' then // Specify specific Object
    sqQuery.SQL.Add('where RDB$Relation_Name = ''' + UpperCase(ObjectName) + ''' ');
  sqQuery.SQL.Add('order by RDB$User_Type');
  sqQuery.Open;
  while not sqQuery.EOF do
  begin
    if sqQuery.Fields[1].AsInteger = 13 then // Role
      Result:= Result + '<R>';
    Result:= Result + Trim(sqQuery.Fields[0].Text);
    sqQuery.Next;
    if not sqQuery.EOF then
      Result:= Result + ',';
  end;
  sqQuery.Close;
  {$ENDIF}
end;

function TdmSysTables.GetDBUsers(adb :TDBInfo; ObjectName :string) :string;
begin
  Init(aDB);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'select distinct RDB$User, RDB$User_Type from RDB$USER_PRIVILEGES ';
  if ObjectName <> '' then // Specify specific Object
    MDOQuery.SQL.Add('where RDB$Relation_Name = ' + QuotedStr(UpperCase(ObjectName)));
  MDOQuery.SQL.Add('order by RDB$User_Type');
  MDOQuery.Open;
  while not MDOQuery.EOF do
  begin
    if MDOQuery.Fields[1].AsInteger = 13 then // Role
      Result:= Result + '<R>';
    Result:= Result + Trim(MDOQuery.Fields[0].Text);
    MDOQuery.Next;
    if not MDOQuery.EOF then
      Result:= Result + ',';
  end;
  MDOQuery.Close;
end;


(************  Get Database Objects for permissions ************)

function TdmSysTables.GetDBObjectsForPermissions(dbIndex: Integer; AObjectType: Integer = -1): string;
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'select distinct RDB$Relation_Name, RDB$Object_Type from RDB$USER_PRIVILEGES ';
  if AObjectType <> -1 then
    MDOQuery.SQL.Add('where RDB$Object_Type = ' + IntToStr(AObjectType));
  MDOQuery.SQL.Add(' order by RDB$Object_Type');
  MDOQuery.Open;
  while not MDOQuery.EOF do
  begin
    if Pos('$', MDOQuery.Fields[0].AsString) = 0 then
    begin
      if AObjectType = -1 then
      case MDOQuery.Fields[1].AsInteger of
        0: Result:= Result + '<T>'; // Table/View
        5: Result:= Result + '<P>'; // Procedure
        13: Result:= Result + '<R>'; // Role
      end;
      Result:= Result + Trim(MDOQuery.Fields[0].Text);
      MDOQuery.Next;
      if not MDOQuery.EOF then
        Result:= Result + ',';

    end
    else
      MDOQuery.Next;
  end;
  MDOQuery.Close;
end;

(************  Get Object Users ************)

function TdmSysTables.GetObjectUsers(dbIndex: Integer; ObjectName: string): string;
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'select distinct RDB$User, RDB$User_Type from RDB$USER_PRIVILEGES  ' +
    'where RDB$Relation_Name = ' + QuotedStr(ObjectName);
  MDOQuery.Open;
  while not MDOQuery.EOF do
  begin
      if MDOQuery.Fields[1].AsInteger = 13 then // Role
        Result:= Result + '<R>';
      Result:= Result + Trim(MDOQuery.Fields[0].Text);

      MDOQuery.Next;
      if not MDOQuery.EOF then
        Result:= Result + ',';
  end;
  MDOQuery.Close;
end;

(************  Get Users Objects ************)

function TdmSysTables.GetUserObjects(dbIndex: Integer; UserName: string; AObjectType: Integer = -1): string;
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'select distinct RDB$Relation_Name, RDB$Grant_Option from RDB$USER_PRIVILEGES  ' +
    'where RDB$User = ''' + UserName + ''' ';
  if AObjectType <> -1 then
    MDOQuery.SQL.Add(' and RDB$Object_Type = ' + IntToStr(AObjectType));
  MDOQuery.SQL.Add(' order by RDB$Object_Type');
  MDOQuery.Open;
  Result:= '';
  while not MDOQuery.EOF do
  begin
    if MDOQuery.FieldByName('RDB$Grant_Option').AsInteger <> 0 then
      Result:= Result + '<G>';
    Result:= Result + Trim(MDOQuery.Fields[0].Text);

    MDOQuery.Next;
    if not MDOQuery.EOF then
      Result:= Result + ',';
  end;
  MDOQuery.Close;
end;


(************  Get Object User permission ************)

function TdmSysTables.GetObjectUserPermission(dbIndex: Integer; ObjectName, UserName: string;
  var ObjType: Integer): string;
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'select * from RDB$User_Privileges ' +
    'where RDB$Relation_Name = ' + QuotedStr(ObjectName) + ' ' +
    'and RDB$User = ' + QuotedStr(UserName);
  MDOQuery.Open;
  Result:= '';
  if MDOQuery.RecordCount >  0 then
  begin
    ObjType:= MDOQuery.FieldByName('RDB$Object_Type').AsInteger;
    while not MDOQuery.EOF do
    begin
      Result:= Result + Trim(MDOQuery.FieldByName('RDB$Privilege').AsString);
      if MDOQuery.FieldByName('RDB$Grant_Option').AsInteger <> 0 then
        Result:= Result + 'G';
      MDOQuery.Next;
      if not MDOQuery.EOF then
        Result:= Result + ',';
    end;
  end;
  MDOQuery.Close;
end;

procedure TdmSysTables.GetBasicTypes(List: TStrings);
begin
  List.CommaText:= List.CommaText +
    'SMALLINT,INTEGER,BIGINT,VARCHAR,'+
    'FLOAT,"DOUBLE PRECISION",DECIMAL,NUMERIC,'+
    'CHAR,DATE,TIME,' +
    'TIMESTAMP,CSTRING,D_FLOAT,QUAD,BLOB';
end;

procedure TdmSysTables.GetDomainTypes(dbIndex: Integer; List: TStrings);
var
  Count: Integer;
begin
  List.CommaText:= List.CommaText + ',' + GetDBObjectNames(fmMain.RegisteredDatabases[dbIndex], otDomains, Count);
end;

function TdmSysTables.GetDefaultTypeSize(dbIndex: Integer; TypeName: string): Integer;
begin
  TypeName:= LowerCase(TypeName);
  if TypeName = 'varchar' then
    Result:= 50
  else
  if TypeName = 'char' then
    Result:= 20
  else
  if TypeName = 'smallint' then
    Result:= 2
  else
  if TypeName = 'integer' then
    Result:= 4
  else
  if TypeName = 'bigint' then
    Result:= 8
  else
  if TypeName = 'float' then
    Result:= 4
  else
  if TypeName = 'timestamp' then
    Result:= 8
  else
  if TypeName = 'date' then
    Result:= 4
  else
  if TypeName = 'time' then
    Result:= 4
  else
  if TypeName = 'double precision' then
    Result:= 8
  else
    Result:= GetDomainTypeSize(dbIndex, TypeName);
end;

function TdmSysTables.GetDomainTypeSize(dbIndex: Integer; DomainTypeName: string): Integer;
var
  DomainType, DefaultValue, CheckConstraint, CharacterSet, Collation: string;
begin
  GetDomainInfo(dbIndex, DomainTypeName, DomainType, Result, DefaultValue, CheckConstraint, CharacterSet, Collation);
end;


function TdmSysTables.GetFieldInfo(dbIndex: Integer; TableName, FieldName: string;
  var FieldType: string;
  var FieldSize: integer; var FieldScale: integer;
  var NotNull: Boolean;
  var DefaultValue, CharacterSet, Collation, Description : string): Boolean;
begin
  Init(dbIndex);
  MDOQuery.SQL.Text:= 'SELECT r.RDB$FIELD_NAME AS field_name, ' +
                     'r.RDB$DESCRIPTION AS field_description, ' +
                     'r.RDB$DEFAULT_SOURCE AS field_default_source, ' {SQL text for default value}+
                     'r.RDB$NULL_FLAG AS field_not_null_constraint, ' +
                     'f.RDB$FIELD_LENGTH AS field_length, ' +
                     'f.RDB$Character_LENGTH AS characterlength, ' + {character_length seems a reserved word }
                     'f.RDB$FIELD_PRECISION AS field_precision, ' +
                     'f.RDB$FIELD_SCALE AS field_scale, ' +
                     'f.RDB$FIELD_TYPE as field_type_int, ' +
                     'f.RDB$FIELD_SUB_TYPE AS field_sub_type, ' +
                     'coll.RDB$COLLATION_NAME AS field_collation, ' +
                     'cset.RDB$CHARACTER_SET_NAME AS field_charset, ' +
                     'f.RDB$computed_source AS computed_source, ' +
                     'dim.RDB$UPPER_BOUND AS array_upper_bound, ' +
                     'r.RDB$FIELD_SOURCE AS field_source ' {domain if field based on domain} +
                     'FROM RDB$RELATION_FIELDS r ' +
                     'LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME ' +
                     'LEFT JOIN RDB$COLLATIONS coll ON f.RDB$COLLATION_ID = coll.RDB$COLLATION_ID and f.rdb$character_set_id=coll.rdb$character_set_id ' +
                     'LEFT JOIN RDB$CHARACTER_SETS cset ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID ' +
                     'LEFT JOIN RDB$FIELD_DIMENSIONS dim on f.RDB$FIELD_NAME = dim.RDB$FIELD_NAME '+
                     'WHERE r.RDB$RELATION_NAME=''' + TableName + '''  and Trim(r.RDB$FIELD_NAME) = ''' + UpperCase(FieldName) + ''' ' +
                     'ORDER BY r.RDB$FIELD_POSITION ';
  MDOQuery.Open;
  Result:= MDOQuery.RecordCount > 0;
  if Result then
  begin
    with MDOQuery do
    begin
      //todo: harmonize with implementation in turbocommon
      if (FieldByName('field_source').IsNull) or
        (trim(FieldByName('field_source').AsString)='') or
        (IsFieldDomainSystemGenerated(trim(FieldByname('field_source').AsString))) then
      begin
        // Field type is not based on a domain but a standard SQL type
        FieldType:= GetFBTypeName(FieldByName('field_type_int').AsInteger,
                                  FieldByName('field_sub_type').AsInteger,
                                  FieldByName('field_length').AsInteger,
                                  FieldByName('field_precision').AsInteger,
                                  FieldByName('field_scale').AsInteger);
        // Array should really be [lowerbound:upperbound] (if dimension is 0)
        // but for now don't bother as arrays are not supported anyway
        // Assume 0 dimension, 1 lower bound; just fill in upper bound
        if not(FieldByName('array_upper_bound').IsNull) then
          FieldType := FieldType + ' [' +
                       FieldByName('array_upper_bound').AsString + ']';
        if FieldByName('field_type_int').AsInteger = VarCharType then
          FieldSize:= FieldByName('characterlength').AsInteger
        else
          FieldSize:= FieldByName('field_length').AsInteger;
      end else begin
        // Field is based on a domain
        FieldType := Trim(FieldByName('field_source').AsString);
        // Reset other value to avoid strange values
        FieldSize := 0;
      end;

      FieldScale   := FieldByName('field_scale').AsInteger;
      NotNull      := (FieldByName('field_not_null_constraint').AsString = '1');
      Collation    := trim(FieldByName('field_collation').AsString);
      CharacterSet := trim(FieldByName('field_charset').AsString);
      // Note: no trim here - defaultvalue could be an empty string
      DefaultValue := FieldByName('field_default_source').AsString;
      Description  := trim(FieldByName('field_description').AsString);
    end;
  end;
  MDOQuery.Close;
end;

function TdmSysTables.GetDatabaseInfo(dbIndex: Integer; var DatabaseName, CharSet, CreationDate, ServerTime: string;
                                      var ODSVerMajor, ODSVerMinor, Pages, PageSize: Integer; var ProcessList: TStringList;
                                      var ErrorMsg: string) :Boolean;
begin
  try
    Init(dbIndex);
    stTrans.Commit;
    MDOQuery.SQL.Text := 'select * from RDB$DATABASE';
    MDOQuery.Open;
    CharSet := MDOQuery.fieldbyName('RDB$Character_Set_Name').AsString;
    MDOQuery.Close;

    MDOQuery.SQL.Text:= 'select * from MON$DATABASE';
    MDOQuery.Open;
    DatabaseName := MDOQuery.FieldByName('MON$Database_Name').AsString;
    PageSize     := MDOQuery.FieldByName('MON$Page_Size').AsInteger;
    ODSVerMajor  := MDOQuery.FieldByName('MON$ODS_Major').AsInteger;
    ODSVerMinor  := MDOQuery.FieldByName('MON$ODS_Minor').AsInteger;
    CreationDate := Trim(MDOQuery.FieldByName('MON$Creation_Date').AsString);
    Pages        := MDOQuery.FieldByName('MON$Pages').AsInteger;
    MDOQuery.Close;

    // Attached clients
    MDOQuery.SQL.Text:= 'select * from MON$ATTACHMENTS';
    if ProcessList = nil then ProcessList:= TStringList.Create;
    MDOQuery.Open;
    with MDOQuery do
    while not EOF do begin
      ProcessList.Add('Host: ' + Trim(FieldByName('MON$Remote_Address').AsString) +
                      ' User: ' + Trim(FieldByName('Mon$User').AsString)  +
                      ' Process: ' + Trim(FieldByName('Mon$Remote_Process').AsString));
      Next;
    end;
    MDOQuery.Close;

    // Server time
    MDOQuery.SQL.Text := 'select current_timestamp from RDB$Database';
    MDOQuery.Open;
    ServerTime := MDOQuery.Fields[0].AsString;
    MDOQuery.Close;
    Result := True;
  except
    on E: Exception do
    begin
      ErrorMsg := E.Message;
      Result := False;
    end;
  end;
end;

function TdmSysTables.GetIndices(dbIndex: Integer; ATableName: string; PrimaryIndexName: string;
  var List: TStringList): Boolean;
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'SELECT * FROM RDB$INDICES WHERE RDB$RELATION_NAME=''' + UpperCase(ATableName) +
                     ''' AND RDB$FOREIGN_KEY IS NULL';
  MDOQuery.Open;
  Result:= MDOQuery.RecordCount > 0;
  with MDOQuery do
  if Result then
  begin
    while not Eof do begin
      if UpperCase(Trim(PrimaryIndexName)) <> Trim(Fields[0].AsString) then
        List.Add(Trim(Fields[0].AsString));
      Next;
    end;
  end;
  MDOQuery.Close
end;

function TdmSysTables.GetAllIndices(dbIndex: Integer; List, TablesList: TStringList): Boolean;
const
  SQL = 'SELECT * FROM RDB$INDICES ' +
    'WHERE RDB$FOREIGN_KEY IS NULL ' +
    'and RDB$system_flag = 0';
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= SQL;
  MDOQuery.Open;
  Result:= MDOQuery.RecordCount > 0;
  List.Clear;
  if TablesList <> nil then TablesList.Clear;
  with MDOQuery do
  if Result then begin
    while not Eof do begin
      List.Add(Trim(Fields[0].AsString));
      if TablesList <> nil then
        TablesList.Add(Trim(FieldByName('RDB$Relation_Name').AsString));
      Next;
    end;
  end;
  MDOQuery.Close
end;

function TdmSysTables.GetPrimaryKeyIndexName(dbIndex: Integer; ATableName: string; var ConstraintName: string): string;
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'select RDB$Index_name, RDB$Constraint_Name from RDB$RELATION_CONSTRAINTS ' +
                     'where RDB$Relation_Name = ''' + UpperCase(ATableName) +
                     ''' and RDB$Constraint_Type = ''PRIMARY KEY'' ';
  MDOQuery.Open;
  if MDOQuery.RecordCount > 0 then begin
    Result:= Trim(MDOQuery.Fields[0].AsString);
    ConstraintName:= Trim(MDOQuery.Fields[1].AsString);
  end else
    Result:= '';
  MDOQuery.Close;
end;

function TdmSysTables.GetIndexInfo(dbIndex: Integer; ATableName, AIndexName: string;
  var FieldsList: TStringList; var ConstraintName: string; var Unique, Ascending, IsPrimary: Boolean): Boolean;
begin
  Init(dbIndex);
  MDOQuery.Close;
  MDOQuery.SQL.Text:= 'SELECT RDB$Indices.*, RDB$INDEX_SEGMENTS.RDB$FIELD_NAME AS field_name, ' + LineEnding +
                     'RDB$INDICES.RDB$DESCRIPTION AS description, ' + LineEnding +
                     '(RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION + 1) AS field_position, ' + LineEnding +
                     'RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_TYPE as IndexType, ' + LineEnding +
                     'RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_Name as ConstraintName' + LineEnding +
                     'FROM RDB$INDEX_SEGMENTS ' + LineEnding +
                     'LEFT JOIN RDB$INDICES ON RDB$INDICES.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME ' + LineEnding +
                     'LEFT JOIN RDB$RELATION_CONSTRAINTS ON RDB$RELATION_CONSTRAINTS.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME '
                     + LineEnding +
                     ' WHERE UPPER(RDB$INDICES.RDB$RELATION_NAME)=''' + UpperCase(ATablename) + '''         -- table name ' + LineEnding +
                     '  AND UPPER(RDB$INDICES.RDB$INDEX_NAME)=''' + UpperCase(AIndexName) + ''' ' + LineEnding +
                     'ORDER BY RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION;';
  MDOQuery.Open;
  Result:= MDOQuery.FieldCount > 0;
  if Result then
  begin
    Unique         := MDOQuery.FieldByName('RDB$Unique_Flag').AsString = '1';
    Ascending      := MDOQuery.FieldByName('RDB$Index_Type').AsString <> '1';
    IsPrimary      := Trim(MDOQuery.FieldByName('IndexType').AsString) = 'PRIMARY KEY';
    ConstraintName := Trim(MDOQuery.FieldByName('ConstraintName').AsString);
  end;
  FieldsList.Clear;
  if Result then
  while not MDOQuery.EOF do begin
    FieldsList.Add(Trim(MDOQuery.FieldByName('field_name').AsString));
    MDOQuery.Next;
  end;
  MDOQuery.Close;
end;

procedure TdmSysTables.GetTableFields(dbIndex :Integer; aTableName :string; FieldTypes :array of Integer; FieldsList :TStrings);
//var
//  FieldName: string;
begin
  //Jkoz : Deprecate and replaced.
  //
  //Init(dbIndex);
  //MDOQuery.SQL.Text:= 'SELECT r.RDB$FIELD_NAME AS field_name, ' +
  //    ' r.RDB$DESCRIPTION AS field_description, ' +
  //    ' r.RDB$DEFAULT_SOURCE AS field_default_source, ' {SQL source for default value}+
  //    ' r.RDB$NULL_FLAG AS field_not_null_constraint, ' +
  //    ' f.RDB$FIELD_LENGTH AS field_length, ' +
  //    ' f.RDB$FIELD_PRECISION AS field_precision, ' +
  //    ' f.RDB$FIELD_SCALE AS field_scale, ' +
  //    ' f.RDB$FIELD_TYPE as field_type_int, ' +
  //    ' f.RDB$FIELD_SUB_TYPE AS field_sub_type, ' +
  //    ' coll.RDB$COLLATION_NAME AS field_collation, ' +
  //    ' cset.RDB$CHARACTER_SET_NAME AS field_charset, ' +
  //    ' f.RDB$computed_source AS computed_source, ' +
  //    ' dim.RDB$UPPER_BOUND AS array_upper_bound, ' +
  //    ' r.RDB$FIELD_SOURCE AS field_source ' {domain if field based on domain} +
  //    ' FROM RDB$RELATION_FIELDS r ' +
  //    ' LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME ' +
  //    ' LEFT JOIN RDB$COLLATIONS coll ON f.RDB$COLLATION_ID = coll.RDB$COLLATION_ID ' +
  //    ' LEFT JOIN RDB$CHARACTER_SETS cset ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID ' +
  //    ' LEFT JOIN RDB$FIELD_DIMENSIONS dim on f.RDB$FIELD_NAME = dim.RDB$FIELD_NAME '+
  //    ' WHERE r.RDB$RELATION_NAME=''' + ATableName + '''  ' +
  //    ' ORDER BY r.RDB$FIELD_POSITION;';
  //MDOQuery.Open;
  //FieldsList.Clear;
  //while not MDOQuery.EOF do
  //begin
  //  FieldName:= Trim(MDOQuery.FieldByName('field_name').AsString);
  //  if FieldsList.IndexOf(FieldName) = -1 then
  //    FieldsList.Add(FieldName);
  //  MDOQuery.Next;
  //end;
  //MDOQuery.Close;
  GetTableFields(fmMain.RegisteredDatabases[dbIndex], ATableName, FieldTypes, FieldsList);
end;

procedure TdmSysTables.GetTableFields(aDB :TDBInfo; aTableName :string; aFieldTypes :array of Integer; aFieldList :TStrings);
var
  FieldName :string;
  vFldType  :TField;
  vSubType  :TField;
  vQry      :TMDOQuery;
  vSQL      :string;
  vTypes    :String;
  vCntr     :Integer;
  function FieldAccepted:Boolean;
  var
    vCntr :Integer;
  begin
    Result := True;
    if Length(aFieldTypes) > 0 then begin
      //jkoz : extend it to support subtypes in the mix, for now only subtype 0 is supported.
      for vCntr := 0 to Length(aFieldTypes) -1 do begin
        if (vFldType.AsInteger = aFieldTypes[vCntr]) and (vSubType.AsInteger = 0) then Exit;
      end;
      Result := False;
    end;
  end;

begin
  vQry := GetQuery(aDB.Conn); //Init(aDB);
  try
    vSQL := 'SELECT r.RDB$FIELD_NAME AS '     + cFldName        + ', ' +
                     'r.RDB$DESCRIPTION AS '           + cFldDescription + ', ' +
                     'r.RDB$DEFAULT_SOURCE AS '        + cFldDefSource   + ', ' + {SQL source for default value}
                     'r.RDB$NULL_FLAG AS '             + cFldNullFlag     + ', ' +
                     'f.RDB$FIELD_LENGTH AS '          + cFldLength      + ', ' +
                     'f.RDB$FIELD_PRECISION AS '       + cFldPrecision   + ', ' +
                     'f.RDB$FIELD_SCALE AS '           + cFldScale       + ', ' +
                     'f.RDB$FIELD_TYPE AS '            + cfldType        + ', ' +
                     'f.RDB$FIELD_SUB_TYPE AS '        + cFldSubType     + ', ' +
                     'coll.RDB$COLLATION_NAME AS '     + cFldCollation   + ', ' +
                     'cset.RDB$CHARACTER_SET_NAME AS ' + cFldCharset     + ', ' +
                     'f.RDB$computed_source AS '       + cFldComputedSrc + ', ' +
                     'dim.RDB$UPPER_BOUND AS '         + cArrUpBound     + ', ' +
                     'r.RDB$FIELD_SOURCE AS '          + cFldSource      + ' '  + {domain if field based on domain}
                     'FROM RDB$RELATION_FIELDS r ' +
                     'LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME ' +
                     'LEFT JOIN RDB$COLLATIONS coll ON f.RDB$COLLATION_ID = coll.RDB$COLLATION_ID ' +
                     'LEFT JOIN RDB$CHARACTER_SETS cset ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID ' +
                     'LEFT JOIN RDB$FIELD_DIMENSIONS dim on f.RDB$FIELD_NAME = dim.RDB$FIELD_NAME '+
                     'WHERE r.RDB$RELATION_NAME=''' + aTableName + '''  ';
    if Length(aFieldTypes) > 0 then begin
      for vCntr := low(aFieldTypes) to High(aFieldTypes) do begin
        vTypes := vTypes+IntToStr(aFieldTypes[vCntr]);
        if vCntr < High(aFieldTypes) then vTypes := vTypes+',';
      end;
      vSQL := vSQL+' and ' +cFldType+' in [' + vTypes + '] ';
    end;
    vQry.SQL.Text := vSQL + 'ORDER BY r.RDB$FIELD_POSITION;';
    vQry.Open;
    try
      vFldType := vQry.FieldByName(cfldType);
      vSubType := vQry.FieldByName(cFldSubType);
      aFieldList.Clear;
      vQry.First;
      while not vQry.EOF do begin
        if FieldAccepted then begin
          FieldName := Trim(vQry.FieldByName(cFldName).AsString);
          if aFieldList.IndexOf(FieldName) = -1 then aFieldList.Add(FieldName);
        end;
        vQry.Next;
      end;
    finally
      vQry.Close;
    end;
  finally
    ReleaseQuery(vQry);
  end;
end;

procedure TdmSysTables.GetTableFields(aDB :TDBInfo; aTablename, aCondition :string; aFieldList :TStrings);
var
  vFieldName :string;
  vFldType  :TField;
  vQry      :TMDOQuery;

  function ConditionStr(aCond :string):string;
  begin
    Result := ' ';
    if aCond <> '' then Result := ' AND (' + aCondition + ') ';
  end;

begin
  //Init(aDB);
  vQry := GetQuery(aDB.Conn);
  try
    vQry.SQL.Text := 'SELECT r.RDB$FIELD_NAME AS '     + cFldName        + ', ' +
                     'r.RDB$DESCRIPTION AS '           + cFldDescription + ', ' +
                     'r.RDB$DEFAULT_SOURCE AS '        + cFldDefSource   + ', ' + {SQL source for default value}
                     'r.RDB$NULL_FLAG AS '             + cFldNullFlag     + ', ' +
                     'f.RDB$FIELD_LENGTH AS '          + cFldLength      + ', ' +
                     'f.RDB$FIELD_PRECISION AS '       + cFldPrecision   + ', ' +
                     'f.RDB$FIELD_SCALE AS '           + cFldScale       + ', ' +
                     'f.RDB$FIELD_TYPE AS '            + cfldType        + ', ' +
                     'f.RDB$FIELD_SUB_TYPE AS '        + cFldSubType     + ', ' +
                     'coll.RDB$COLLATION_NAME AS '     + cFldCollation   + ', ' +
                     'cset.RDB$CHARACTER_SET_NAME AS ' + cFldCharset     + ', ' +
                     'f.RDB$computed_source AS '       + cFldComputedSrc + ', ' +
                     'dim.RDB$UPPER_BOUND AS '         + cArrUpBound     + ', ' +
                     'r.RDB$FIELD_SOURCE AS '          + cFldSource      + ' '  + {domain if field based on domain}
                     'FROM RDB$RELATION_FIELDS r '     +
                     'LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME ' +
                     'LEFT JOIN RDB$COLLATIONS coll ON f.RDB$COLLATION_ID = coll.RDB$COLLATION_ID ' +
                     'LEFT JOIN RDB$CHARACTER_SETS cset ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID ' +
                     'LEFT JOIN RDB$FIELD_DIMENSIONS dim on f.RDB$FIELD_NAME = dim.RDB$FIELD_NAME '+
                     'WHERE r.RDB$RELATION_NAME= ' + QuotedStr(ATableName) + ' ' + ConditionStr(aCondition) +
                     'ORDER BY r.RDB$FIELD_POSITION;';
    vQry.Open;
    vFldType := vQry.FieldByName(cfldType);
    aFieldList.Clear;
    vQry.First;
    while not vQry.EOF do begin
      vFieldName := Trim(vQry.FieldByName(cFldName).AsString);
      if aFieldList.IndexOf(vFieldName) = -1 then aFieldList.Add(vFieldName);
      vQry.Next;
    end;
    vQry.Close;
  finally
    ReleaseQuery(vQry);
  end;
end;

procedure TdmSysTables.GetTableFields(aDB :Integer; aTablename, aCondition :string; aFieldList :TStrings);
begin
  GetTableFields(fmMain.RegisteredDatabases[aDB],aTablename, aCondition, aFieldList);
end;

procedure TdmSysTables.GetTableNames(aDB :TDBInfo; aList :TStrings);
begin
  GetDBObjectNames(aDB, otTables, aList);
end;

procedure TdmSysTables.CreateUser(constref aDB :TDBInfo; aUserName, aPassword, aRole :String; const aTransaction :TMDOTransaction);
begin
  SQLExecute(aDB, 'Create user %S password %S', [aUserName, QuotedStr(aPassword)]);
  if Trim(aRole) <> '' then GrandRolesToUser(aDB, aUserName, aRole);
end;

procedure TdmSysTables.GrandRolesToUser(Constref aDB :TDBInfo; aUserName, aRole :String; const aTransaction:TMDOTransaction = nil);
var
  vList:TStringArray;
  vStr:string;
begin
  if CharCount(';',aRole)>1 then begin
    vList := Split(aRole,';');
    for vStr in vList do begin
      SQLExecute(aDB,'grant %S to %S ',[aUserName, vStr], aTransaction);
    end;
  end else begin
    vStr := trim(aRole);
    if vStr[Length(vStr)] = ';' then SetLength(vStr,Length(vStr)-1);
    SQLExecute(aDB,'grant %S to %S ',[aUserName, vStr]);
  end;

end;

procedure TdmSysTables.DeleteUser(constref aDB :TDBInfo; aUserName :String; const aTransaction :TMDOTransaction);
begin

end;

procedure TdmSysTables.RevokeRoleFromUser(constref aDB :TDBInfo; aUserName, aRole :String; const aTransaction :TMDOTransaction);
begin

end;

//initialization
//  {$I systables.lrs}

end.


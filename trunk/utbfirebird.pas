unit uTBFirebird;

{$mode delphi}{$H+}
{$I EvsDefs.inc}
interface

uses
  Classes, SysUtils, variants, db, MDODatabase, MDOQuery, MDODatabaseInfo, MDOServices, MDO, MDOIntf, MDOHeader, MDOExternals, uEvsDBSchema,
  utbcommon, uTBTypes, uWideStrings, uCharSets;

type

  { TMDOQueryPool }
  TMDOQueryPool = class(TEvsCustomComponentPool)
    function Aquire:TMDOQuery;
    constructor Create(const aMaxCount :Integer=10; const aNeededOnly :Boolean=False); overload;
  end;

  { TMDODatabasePool }
  TMDODatabasePool = class(TEvsCustomComponentPool)
    function Aquire:TMDODataBase;
    constructor Create(const aMaxCount :Integer=10; const aNeededOnly :Boolean=False); overload;
    //procedure BeforeDestruction; override;
  end;

  { TEvsMDODatasetProxy }
  TEvsMDODatasetProxy = class(TEvsDatasetProxy)
  protected
    function GetInTrans :ByteBool;override;  extdecl;
  public
    destructor Destroy; override;
    procedure Execute;extdecl;
    Procedure Commit; override; extdecl;
    procedure RollBack; override; extdecl;
    procedure BeforeDestruction; override;
  end;

  { TEvsMDOConnection }
  TEvsMDOConnection = class(TEvsAbstractConnectionProxy, IEvsMetaData)
  private
    //FActiveConnection : TMDODataBase;
    FReversing : Integer;
    {$IFDEF POOL_QRY}
    Class var FQryPool : TMDOQueryPool; //static;
    Class var FCnnPool : TMDODatabasePool;//static;
    {$ENDIF}
    Function GetServerID :Integer;extdecl;
    Class Function NewQuery:TMDOQuery;
  protected
    Function GetConnection :IEvsConnection; extdecl;
    Function GetMetaData   :IEvsMetaData; override;extdecl;
    Procedure SetParamValue(const aParamName, aParamValue:String);inline;//all code in one place.
    //called by the Interface directly.
    Function  InternalExecute(aSQL :WideString) :ByteBool;  override;extdecl; {$MESSAGE WARN 'Needs Testing'}
    Function  InternalQuery(aSQL :wideString) :IEvsDataset; override;extdecl; {$MESSAGE WARN 'Needs Testing'}
    Function  InternalGetCharSet :widestring;               override;extdecl;
    Function  InternalGetPassword :widestring;              override;extdecl;
    Function  InternalGetRole :widestring;                  override;extdecl;
    Function  InternalGetUserName :widestring;              override;extdecl;
    Procedure InternalSetCharSet(aValue :WideString);       override;extdecl;
    Procedure InternalSetPassword(aValue :widestring);      override;extdecl;
    Procedure InternalSetRole(aValue :widestring);          override;extdecl;
    Procedure InternalSetUserName(aValue :widestring);      override;extdecl;

    Procedure SetConnection(aValue :IEvsConnection);extdecl;{extdecl;}{$MESSAGE WARN 'Needs Implementation'}
    Procedure ParseFieldData(constref aDsFields :IEvsDataset; const aField:IEvsFieldInfo);extdecl;
  public
    Procedure BeforeDestruction; override;

    //function GetConnection :IEvsConnection;extdecl;
    //procedure SetConnection(aValue :IEvsConnection);extdecl;
    procedure DropDatabase; override;extdecl;
    Procedure GetTables(const aDB:IEvsTableList);       overload;extdecl; //append the tables in the list passed
    Procedure GetTableInfo(const aTable:IEvsTableInfo); extdecl;
    Procedure GetTables(const aDB:IEvsDatabaseInfo; const IncludeSystem:ByteBool = False);    overload;extdecl; //append the tables in the database passed.
    Procedure GetFields(const aObject:IEvsTableInfo);   overload;extdecl; //find all the fields of the table and return them in the table's field list.
    //function  GetFields  (const aObject :IEvsStoredInfo)  :IEvsFieldList; extdecl;
    //function  GetFields  (const aObject :IEvsDatabaseInfo):IEvsFieldList; extdecl;
    //procedure GetTriggers(const aObject :IEvsTriggerList);      overload; extdecl;
    Procedure GetTriggers (const aObject :IEvsTableInfo; const System:ByteBool = False);    overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Procedure GetTriggers (const aObject :IEvsDatabaseInfo);    overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Procedure GetStored   (const aObject :IEvsDatabaseInfo);    overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Procedure GetViews    (const aObject :IEvsDatabaseInfo);    overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Procedure GetViewInfo (const aObject :IEvsViewInfo);        Overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Procedure GetSequences(const aDB     :IEvsDatabaseInfo);             extdecl;{$MESSAGE WARN 'Needs Testing'}
    Procedure GetUDFs     (const aObject :IEvsDatabaseInfo);             extdecl;{$MESSAGE WARN 'Needs Implementation'}
    Procedure GetUsers    (const aDB     :IEvsDatabaseInfo);             extdecl;{$MESSAGE WARN 'Needs Implementation'}
    Procedure GetRoles    (const aDB     :IEvsDatabaseInfo);             extdecl;{$MESSAGE WARN 'Needs Implementation'}
    Procedure GetExceptions(const aDB    :IEvsDatabaseInfo);             extdecl;{$MESSAGE WARN 'Needs Testing'}
    Procedure GetIndices    (const aObject:IEvsDatabaseInfo); overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Procedure GetIndices    (const aObject:IEvsTableInfo);    overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Procedure GetDomains    (const aObject:IEvsDatabaseInfo); overload;extdecl;{$MESSAGE WARN 'Needs Implementation'}
    Procedure GetForeignKeys(Const aObject:IEvsTableInfo);    overload;extdecl;{$MESSAGE WARN 'Needs Implementation'}
    Procedure GetAll(const aDB:IEvsDatabaseInfo);                      extdecl;

    Function GetFieldDDL(Const aObject :IEvsFieldInfo):widestring; overload; extdecl;
    Function GetTableDDL(Const aObject :IEvsTableInfo):widestring; overload; extdecl;
    Function GetCharsets :PVarArray;extdecl;
    Function Collations(const aCharSet:Widestring) :PVarArray;               extdecl;

    Property Connection :IEvsConnection read GetConnection write SetConnection;
    Property ServerID   :Integer        read GetServerID;
  end;

//The Connection string must have all the required information to connect to the server separated semicolon.
//function Connect(aHost, aDatabase, aUser, aPwd, aRole, aCharset:Widestring) :IEvsConnection;

function ConncetionSting(const aDB:TDatabase):string;

implementation

uses {Forms,} strutils;

const
  pnCharset  = 'lc_type';
  pnPwd      = 'password';
  pnRole     = 'sql_role_name';
  pnUser     = 'user_name';
  cFieldsSQL = 'SELECT r.RDB$FIELD_NAME            AS field_name, '                + //0
                      'r.RDB$DESCRIPTION           AS field_description, '         + //1
                      'r.RDB$DEFAULT_SOURCE        AS field_default_source, '      + //2{SQL text for default value}
                      'r.RDB$NULL_FLAG             AS field_not_null_constraint, ' + //3
                      'f.RDB$FIELD_LENGTH          AS field_length, '              + //4
                      'f.RDB$Character_LENGTH      AS characterlength, '           + //5 {character_length seems a reserved word }
                      'f.RDB$FIELD_PRECISION       AS field_precision, '           + //6
                      'f.RDB$FIELD_SCALE           AS field_scale, '               + //7
                      'f.RDB$FIELD_TYPE            AS field_type_int, '            + //8
                      'f.RDB$FIELD_SUB_TYPE        AS field_sub_type, '            + //9
                      'coll.RDB$COLLATION_NAME     AS field_collation, '           + //10
                      'cset.RDB$CHARACTER_SET_NAME AS field_charset, '             + //11
                      'f.RDB$computed_source       AS computed_source, '           + //12
	              'F.RDB$SEGMENT_LENGTH        AS Field_Segment_Length, '      + //13
                      'dim.RDB$UPPER_BOUND         AS array_upper_bound, '         + //14
                      'r.RDB$FIELD_SOURCE          AS field_source '               + //15 {domain if field based on domain}
               'FROM RDB$RELATION_FIELDS r '                                                                 +
               '   LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME '                         +
               '   LEFT JOIN RDB$COLLATIONS coll ON f.RDB$COLLATION_ID = coll.RDB$COLLATION_ID '             +
                                             '  and f.rdb$character_set_id=coll.rdb$character_set_id '       +
               '   LEFT JOIN RDB$CHARACTER_SETS cset ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID ' +
               '   LEFT JOIN RDB$FIELD_DIMENSIONS dim on f.RDB$FIELD_NAME = dim.RDB$FIELD_NAME '             +
               '%S'                                                                                          + //'WHERE r.RDB$RELATION_NAME=''%S'''+
               'ORDER BY r.RDB$FIELD_POSITION';

{$REGION ' UTILS '}
function FieldValueDef(const aField:IEvsField; const aDefault:Int32):Int32;overload;inline;
begin
  Result := aDefault;
  if not aField.IsNull then Result := aField.AsInt32;
end;

function FieldValueDef(Const aField:IEvsField; const aDefault:Widestring; const AutoTrim:Boolean = True):Widestring;overload;inline;
begin
  Result := aDefault;
  if not aField.IsNull then Result := IfThen(AutoTrim, Trim(aField.AsString), aField.AsString);
end;

function FieldValueDef(Const aField:IEvsField; const aDefault:Boolean):Boolean;overload;inline;
begin
  Result := aDefault;
  if not aField.IsNull then Result := aField.AsBoolean;
end;

function FieldValueDef(const aField:IEvsField; const aDefault:TDateTime):TDateTime;overload;inline;
begin
  Result := aDefault;
  if not aField.IsNull then Result := aField.AsDateTime;
end;

function FieldValueDef(const aField:IEvsField; const aDefault:Double):Double;overload;inline;
begin
  Result := aDefault;
  if not aField.IsNull then Result := aField.AsDouble;
end;

function FieldValueDef(const aField:IEvsField; const aDefault:Byte):Byte;overload;inline;
begin
  Result := aDefault;
  if not aField.IsNull then Result := aField.AsByte;
end;

function ConncetionSting(const aDB :TDatabase) :string;
var
  vStrict:Boolean;
  vDelimeter:Char;
begin
  vStrict := aDB.Params.StrictDelimiter;
  vDelimeter:= adb.Params.Delimiter;
  try
    aDB.Params.StrictDelimiter:=True;
    aDB.Params.Delimiter := ';';
    Result := aDB.Params.DelimitedText;
  finally
    aDB.Params.StrictDelimiter := vStrict;
    adb.Params.Delimiter       := vDelimeter;
  end;
end;

function NewCnn:TMDODataBase;
begin
  {$IFDEF POOL_QRY}
   Result := TEvsMDOConnection.FCnnPool.Aquire;
  {$ELSE}
  Result := TMDODataBase.Create(Nil);
  //Result.Assign(TEvsMDOConnection.FActiveConnection);
  {$ENDIF}
end;

function Connect(aHost, aDatabase, aUser, aPwd, aRole, aCharset :Widestring) :IEvsConnection;
var
  vObj :TMDODataBase;
begin
  Result := Nil;
  {$IFDEF POOL_QRY}
  vObj := TEvsMDOConnection.FCnnPool.Aquire;
  {$ELSE}
  vObj := TMDODataBase.Create(Nil);
  {$ENDIF}
  vObj.UserName     := aUser;
  if aHost <> '' then  vObj.DatabaseName := aHost + ':' + aDatabase
  else vObj.DatabaseName := aDatabase;
  vObj.CharSet      := aCharset;
  vObj.Role         := aRole;
  vObj.Password     := aPwd;
  vObj.LoginPrompt  := False;
  vObj.Connected    := True;
  Result            := TEvsMDOConnection.Create(vObj);
end;

function CreateDirect(aHost,aDatabase,aUser,aPwd,aRole,aCharset,aCollation:Widestring;aPageSize:Integer):IEvsConnection;
var
  FHandle: TISC_DB_HANDLE;
  tr_handle: TISC_TR_HANDLE;
  function Check(ErrCode: ISC_STATUS; RaiseError: Boolean) : ISC_STATUS;
  begin
    result := ErrCode;
    if RaiseError and (ErrCode > 0) then
      MDODataBaseError;
  end;

begin
  //isc_dsql_execute_immediate(StatusVector, @FHandle, @tr_handle, 0,
  //                           PChar('CREATE DATABASE ''' + FDBName + ''' ' + {do not localize}
  //                           Params.Text), SQLDialect, nil),

end;

function Create(aHost,aDatabase,aUser,aPwd,aRole,aCharset,aCollation:Widestring;aPageSize:Integer):IEvsConnection;
var
  vObj :TMDODataBase;
begin
  Result := Nil;
  {$IFDEF POOL_QRY}
  vObj := TEvsMDOConnection.FCnnPool.Aquire;
  {$ELSE}
  vObj := TMDODataBase.Create(Nil);
  try
  {$ENDIF}
    //if aHost <> '' then  vObj.DatabaseName := aHost + ':' + aDatabase
    //else
    vObj.DatabaseName := aDatabase;
//CREATE {DATABASE | SCHEMA} '<filespec>'
//[USER 'username' [PASSWORD 'password']]
//[PAGE_SIZE [=] size]
//[LENGTH [=] num [PAGE[S]]
//[DEFAULT CHARACTER SET default_charset
//  [COLLATION collation]] -- not supported in ESQL
//[<sec_file> [<sec_file> ...]]
//[DIFFERENCE FILE 'diff_file']; -- not supported in ESQL
//
//<filespec> ::= [<server_spec>]{filepath | db_alias}
//
//<server_spec> ::= servername [/{port|service}]: | \\servername\
//
//<sec_file> ::= FILE 'filepath'
//[LENGTH [=] num [PAGE[S]] [STARTING [AT [PAGE]] pagenum]
    vObj.SQLDialect := 3;
    vObj.Params.Clear;
    vObj.Params.Add('USER '+QuotedStr(aUser));
    vObj.Params.Add('PASSWORD '+QuotedStr(aPwd));
    vObj.Params.Add('PAGE_SIZE '+IntToStr(aPageSize));
    vObj.Params.Add('DEFAULT CHARACTER SET '+ aCharset);
    vObj.Params.Add('COLLATION '+ aCollation);
    vObj.CreateDatabase;
    Result            := TEvsMDOConnection.Create(vObj);
  {$IFNDEF POOL_QRY}
  except
    vObj.Free;
    raise;
  end;
  {$ENDIF}
end;

function CharSets:TWideStringArray;
begin
  Result := uCharSets.SupportedCharacterSets;
end;

function CharSetCollations(const aCharset:String):TWideStringArray;
begin
  Result := uCharSets.SupportedCollations(aCharset);
end;

Function Backup(aFilename, aHost, aDatabase, aUser, aPwd, aRole:Widestring):Boolean;
var
  vSrv:TMDOBackupService;
  vHost,vDatabase:string;
  vStrL : TStringList;
begin  { TODO -oJKOZ -cDatabaseAccess : Add support for SQL_Role_Name }
  Result := False;
  vSrv := TMDOBackupService.Create(Nil);
  vStrL := TStringList.Create;
  try
    vSrv.BackupFile.Add(aFilename);
    vSrv.Params.Values['user_name']     := aUser;
    vSrv.Params.Values['password']      := aPwd;
    vDatabase := ExtractDBName(aDatabase);
    if aHost = '' then begin
      vHost:= ExtractHost(aDatabase)
    end else vHost    := aHost;
    vSrv.ServerName   := vHost;
    vSrv.DatabaseName := vDatabase;// ExtractDBName(aDatabase);
    vSrv.Protocol     := TCP;
    vSrv.Verbose      := True;
    vSrv.LoginPrompt  := False;
    vSrv.Active := True;
    vSrv.ServiceStart;
    while not vSrv.Eof do begin
      vStrL.Add(vSrv.GetNextChunk);
      Sleep(10);
    end;
    Result := True;
  finally
    vSrv.Free;
    vStrL.Free;
  end;
end;

Function Restore(aFilename, aHost, aDatabase, aUser, aPwd, aRole:Widestring):Boolean;
var
  vSrv  :TMDORestoreService;
  vHost,vDatabase:string;
  vStrL : TStringList;
begin  { TODO -oJKOZ -cDatabaseAccess : Add support for SQL_Role_Name }
  Result := False;
  vSrv := TMDORestoreService.Create(Nil);
  vStrL := TStringList.Create;
  try
    vSrv.BackupFile.Add(aFilename);
    vSrv.Params.Values['user_name'] := aUser;
    vSrv.Params.Values['password']  := aPwd;
    vDatabase := ExtractDBName(aDatabase);
    if aHost = '' then begin
      vHost:= ExtractHost(aDatabase)
    end else vHost := aHost;
    vSrv.ServerName := vHost;
    vSrv.DatabaseName.Add(vDatabase);// ExtractDBName(aDatabase);
    vSrv.Protocol := TCP;
    vSrv.Verbose := True;
    vSrv.LoginPrompt := False;
    vSrv.Active := True;
    vSrv.ServiceStart;
    while not vSrv.Eof do begin
      vStrL.Add(vSrv.GetNextChunk);
      Sleep(10);
    end;
    Result := True;
  finally
    //if vStrL.Count>0 then vStrL.SaveToFile(ChangeFileExt(Forms.Application.ExeName,'.log'))
    //else if fileexists(ChangeFileExt(Forms.Application.ExeName,'.log')) then
    //       DeleteFile(ChangeFileExt(Forms.Application.ExeName,'.log'));
    vSrv.Free;
    vStrL.Free;
  end;
end;

{$ENDREGION}

{$REGION ' TEvsMDODatasetProxy '}

function TEvsMDODatasetProxy.GetInTrans :ByteBool; extdecl;
begin
  Result := TMDOQuery(FDS).Transaction.InTransaction;
end;

destructor TEvsMDODatasetProxy.Destroy;
begin
  inherited Destroy;
end;

procedure TEvsMDODatasetProxy.Execute;extdecl;
begin
  if FDS is TMDOQuery then TMDOQuery(FDS).ExecSQL else inherited
end;

Procedure TEvsMDODatasetProxy.Commit; extdecl;
begin
  if Assigned(FDS) then
    if Assigned(TMDOQuery(FDS).Transaction) then
      if TMDOQuery(FDS).Transaction.Active then TMDOQuery(FDS).Transaction.Commit;
end;

procedure TEvsMDODatasetProxy.RollBack; extdecl;
begin
  if Assigned(FDS) then
    if Assigned(TMDOQuery(FDS).Transaction) then
      if TMDOQuery(FDS).Transaction.Active then TMDOQuery(FDS).Transaction.Rollback;
end;

procedure TEvsMDODatasetProxy.BeforeDestruction;
begin
  inherited BeforeDestruction;
  RollBack;
  {$IFDEF POOL_QRY}
  if not FOwnsDataset then TEvsMDOConnection.FQryPool.Return(FDS);
  {$ENDIF}
end;

{$ENDREGION}

{$REGION ' TMDODatabasePool '}

function TMDODatabasePool.Aquire :TMDODataBase;
begin
  Result := TMDODataBase(Get);
end;

constructor TMDODatabasePool.Create(const aMaxCount :Integer; const aNeededOnly :Boolean);
begin
  inherited Create(aMaxCount, aNeededOnly, TMDODataBase);
end;

{$ENDREGION}

{$REGION ' TMDOQueryPool '}

function TMDOQueryPool.Aquire :TMDOQuery;
begin
  Result := TMDOQuery(Get);
end;

constructor TMDOQueryPool.Create(const aMaxCount :Integer; const aNeededOnly :Boolean);
begin
  Create(aMaxCount, aNeededOnly, TMDOQuery);
end;
{$ENDREGION}

{$REGION ' TEvsMDOConnection '}

Class Function TEvsMDOConnection.NewQuery :TMDOQuery;
begin
  {$IFDEF POOL_QRY}
  Result := FQryPool.Aquire;
  {$ELSE}
  Result := TMDOQuery.Create(Nil);
  {$ENDIF}
  if not Assigned(Result.Transaction) then Result.Transaction := TMDOTransaction.Create(Result);
end;

Function TEvsMDOConnection.GetServerID :Integer; extdecl;
begin
  Result := stFirebird;
end;

Function TEvsMDOConnection.GetConnection :IEvsConnection; extdecl;
begin
  Result := Self;
end;

Procedure TEvsMDOConnection.SetConnection(aValue :IEvsConnection); extdecl;
begin
  raise ETBException.Create('This implementation does not support different connections');
end;

Procedure TEvsMDOConnection.ParseFieldData(constref aDsFields :IEvsDataset; const aField :IEvsFieldInfo); extdecl;
const DoTrim   :Boolean = True;
      DontTrim :Boolean = False;
var
  vScale,
  vLength,
  vPrecision,
  vSubType    :Integer;
  vCharSet,
  vFieldName,
  vCollation,
  vFieldType  :Widestring;
  vDataGroup  :TEvsDataGroup;
  function IsSystemDomain(const aField:IEvsField):Boolean;
  begin
    Result := uWideStrings.WideStartsText('RDB$', aField.AsString) or
              uWideStrings.WideStartsText('EVS$', aField.AsString) //used internally when the minimize system domains is checked;
  end;

begin
  vFieldName := Trim(aDsFields.Field[0].AsString);
  vScale     := Abs(aDsFields.Field[7].AsInt32);
  vLength    := FieldValueDef(aDsFields.Field[04], 0);
  vPrecision := FieldValueDef(aDsFields.Field[06], 0);
  vCharSet   := FieldValueDef(aDsFields.Field[11], '', DoTrim);
  vCollation := FieldValueDef(aDsFields.Field[10], '', DoTrim);

  case aDsFields.Field[8].AsInt32 of
    14,
    15: begin
          vFieldType := 'Char';//blr_text, blr_text2, uftChar;
          vDataGroup := dtgAlpha;
        end;
    37,
    38: begin //blr_varying, blr_varying2
          vFieldType := 'Varchar';
          vDataGroup := dtgAlpha;
        end;
    40,
    41: begin //blr_cstring, blr_cstring2
          vFieldType := 'Char';
          vDataGroup := dtgAlpha;
        end;
    7:  begin //blr_short
          vFieldType := 'Smallint';
          vLength    := -2;//16bit
          vDataGroup := dtgNumeric;
        end;
    8:  begin //blr_long
          vFieldType := 'Integer';
          vLength    := -4;//32bit
          vDataGroup := dtgNumeric;
        end;
    9:  begin
          vFieldType := 'Binary';
          vLength := vPrecision;
          vDataGroup := dtgBinary;
        end;
    10,
    11: begin //blr_float, blr_d_float
          vFieldType := 'Float';
          vLength    :=  -4;//32bit floating point // aDsFields.Field[6].AsInt32;//Precision;
          vDataGroup := dtgNumeric;
        end;
    27: begin //blr_double
          vFieldType := 'Double Precision';
          vLength    := -8;//64bit floating point
          vDataGroup := dtgNumeric;
        end;
    35: begin  //blr_timestamp
          vFieldType := 'Timestamp';
          //vLength    := vPrecision;// aDsFields.Field[6].AsInt32;//Precision;
          vLength    := -8;
          vDataGroup := dtgDateTime;
        end;
    261: begin //blr_blob
           vSubType   := aDsFields.Field[9].AsInt32;//subtype.
           vFieldType := 'Blob';
           vLength    := aDsFields.Field[13].AsInt32;//Segment_Length
           if vSubType = 1 then vFieldType := 'Memo';
           if vSubType = 2 then vFieldType := 'BLR';
           vDataGroup := dtgBlob;
         end;
    45: begin //blr_blob_id
          raise ETBException.CreateFmt('Unsupported Data Type %D, %S',[aDsFields.Field[8].AsInt32,'blr_BlobID']);
        end;
    12: begin //blr_sql_date
          vFieldType := 'Date';
          vLength    := -4;
          vDataGroup := dtgDateTime;
        end;
    13: begin  //blr_sql_time
          vFieldType := 'Time';
          vLength    := 4;
          vDataGroup := dtgDateTime;
        end;
    16: begin //blr_int64
          if vScale <> 0 then begin
            case aDsFields.Field[9].AsInt32 of
              0 : vFieldType := 'Numeric';
              1 : vFieldType := 'Decimal';
            end;
            vDataGroup := dtgNumeric;
            vLength := vPrecision;
          end else begin
            vFieldType :='BigInt';
            vLength    := -8;
            vDataGroup :=dtgInteger;
          end;
        end;
    23,
    17: begin
          vFieldType := 'Boolean';
          vLength    := -1;
          raise ETBException.CreateFmt('Unsupported Data Type %D, %S',[aDsFields.Field[8].AsInt32,'blr_bool']);
        end;
  end;

  aField.FieldName    := Trim(aDsFields.Field[0].AsString);
  aField.DataTypeName := Trim(vFieldType);
  aField.FieldSize    := vLength;
  aField.FieldScale   := vScale;
  aField.Charset      := trim(vCharSet);
  aField.Collation    := trim(vCollation);
  aField.AutoNumber   := False;
  aField.DefaultValue := Null;   {$MESSAGE WARN 'Retrieve default value from the dataset'}
  aField.DataGroup    := vDataGroup;

  if not IsSystemDomain(aDsFields.Field[15]) then begin
    aField.DataTypeName := Trim(aDsFields.Field[15].AsString);
    aField.DataGroup    := dtgCustomType; //user specified domain.
  end;

  if not aDsFields.Field[2].IsNull then
    aField.DefaultValue := Trim(aDsFields.Field[2].AsString);

  if aDsFields.Field[3].IsNull then
    aField.AllowNulls := True
  else
    aField.AllowNulls := not aDsFields.Field[3].AsBoolean;

end;

Function TEvsMDOConnection.GetMetaData :IEvsMetaData; extdecl;
begin
  Result := Self as IEvsMetaData;
end;

Procedure TEvsMDOConnection.SetParamValue(const aParamName, aParamValue :String);
var
  vIdx:Integer;
begin
  if aParamValue <> '' then
    TMDODataBase(FCnn).Params.Values[aParamName] := aParamValue
  else begin
    vIdx := TMDODataBase(FCnn).Params.IndexOfName(aParamName);
    if vIdx > -1 then TMDODataBase(FCnn).Params.Delete(vIdx);
  end;
end;

Function TEvsMDOConnection.InternalExecute(aSQL :WideString) :ByteBool; extdecl;
var
  vQry:TMDOQuery;
begin
  Result := False;
  vQry := TMDOQuery.Create(Nil);
  try
    vQry.Database := TMDODataBase(FCnn);
    vQry.SQL.Text := aSQL;
    vQry.ExecSQL;
    Result := True;
  finally
    //FQryPool.Return(vQry);
    vQry.Free;
  end;
end;

Function TEvsMDOConnection.InternalGetCharSet :widestring; extdecl;
begin
  Result := TMDODataBase(FCnn).Params.Values[pnCharset];
end;

Function TEvsMDOConnection.InternalGetPassword :widestring; extdecl;
begin
  Result := TMDODatabase(FCnn).Params.Values[pnPwd]; //FPassword;//Cnn.Connected;
end;

Function TEvsMDOConnection.InternalGetRole :widestring; extdecl;
begin
  Result := TMDODatabase(FCnn).Params.Values[pnRole]//FRole;// FCnn.Connected;
end;

Function TEvsMDOConnection.InternalGetUserName :widestring; extdecl;
begin
  Result := TMDODatabase(FCnn).Params.Values[pnUser];// username FUserName; //Cnn.Connected;
end;

Function TEvsMDOConnection.InternalQuery(aSQL :wideString) :IEvsDataset; extdecl;
var
  vObj:TMDOQuery;
begin
  {.$IFDEF POOL_QRY}
  vObj := NewQuery;
  {.$ELSE}
  //vObj := TMDOQuery.Create(Nil);
  {.$ENDIF}
  vObj.Database := TMDODataBase(FCnn);
  vObj.Transaction.DefaultDatabase := vObj.Database;
  vObj.SQL.Text := aSQL;
  vObj.Open;
  Result := TEvsMDODatasetProxy.Create(vObj, {$IFDEF POOL_QRY}True{$ELSE}False{$ENDIF});
end;

Procedure TEvsMDOConnection.InternalSetCharSet(aValue :WideString); extdecl;
begin
  SetParamValue(pnCharset,aValue);
end;

Procedure TEvsMDOConnection.InternalSetPassword(aValue :widestring); extdecl;
begin
  SetParamValue(pnPwd,aValue);
end;

Procedure TEvsMDOConnection.InternalSetRole(aValue :widestring); extdecl;
begin
  SetParamValue(pnRole,aValue);
end;

Procedure TEvsMDOConnection.InternalSetUserName(aValue :widestring); extdecl;
begin
  SetParamValue(pnUser,aValue);
end;

Procedure TEvsMDOConnection.BeforeDestruction;
begin
  inherited BeforeDestruction;
  {$IFDEF POOL_QRY}
   FCnnPool.Return(FCnn);
  {$ENDIF}
end;

procedure TEvsMDOConnection.DropDatabase;extdecl;
begin
  TMDODataBase(FCnn).DropDatabase;
end;


Procedure TEvsMDOConnection.GetTables(const aDB :IEvsTableList); extdecl;
const
  cSql = 'select rdb$relation_name from rdb$relations where rdb$view_blr is null ' +
        ' and (rdb$system_flag is null or rdb$system_flag = 0) order by rdb$relation_name';

  procedure GetAllInfo;
  var
    vCntr   :Integer;
    //vFkCntr :Integer;
  begin
    for vCntr := 0 to aDB.Count -1 do begin
      GetTableInfo(aDB[vCntr]);
      //for vFkCntr := 0 to aDB[vCntr].ForeignKeyCount -1 do begin
      //   aDB[vCntr].ForeignKey[vFkCntr].Relink;
      //end;
    end;
  end;

var
  vDts:IEvsDataset;
  vTbl :IEvsTableInfo;
begin
  inc(FReversing);
  try
    vDts := Query(cSql);
    vDts.First;
    while not vDts.EOF do begin
      vTbl := aDB.New;
      vTbl.TableName := Trim(vDts.Field[0].AsString);
      vTbl.ClearState;
      vDts.Next;
    end;
    GetAllInfo;
  finally
    Dec(FReversing);
  end;
end;

Procedure TEvsMDOConnection.GetTableInfo(const aTable:IEvsTableInfo); extdecl;
begin
  GetFields      (aTable);
  GetIndices     (aTable);
  GetTriggers    (aTable);
  //GetForeignKeys (aTable);
  //GetChecks
  {$MESSAGE WARN 'Needs more details.'}
end;

Procedure TEvsMDOConnection.GetTables(const aDB :IEvsDatabaseInfo; const IncludeSystem :ByteBool); extdecl;
const
  cSql = 'select rdb$relation_name, rdb$system_flag from rdb$relations '+
         'WHERE rdb$view_blr is null ' +
         //' AND (RDB$SYSTEM_FLAG is NULL or RDB$SYSTEM_FLAG = 0) ' +
         ' ORDER BY RDB$RELATION_NAME';
var
  vDts     :IEvsDataset;
  vTbl     :IEvsTableInfo;
  vSys     :Integer;
  procedure LoadForeignKeys;
  var
    vCntr :Integer;
    vTblName :String;
  begin
    for vCntr := 0 to aDB.TableCount -1 do begin
      vTblName := aDB.Table[vCntr].TableName;
      GetForeignKeys(aDB.Table[vCntr]);
    end;
  end;

begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    vSys := FieldValueDef(vDts.Field[1],0);
    if (vSys = 0) or IncludeSystem then begin
      vTbl := aDB.NewTable(Trim(vDts.Field[0].AsString));
      if vSys = 0 then vTbl.SystemTable := False else vTbl.SystemTable := True;
      GetTableInfo(vTbl);
      vTbl.ClearState;
    end;
    vDts.Next;
  end;
  LoadForeignKeys;
end;

Procedure TEvsMDOConnection.GetFields(const aObject :IEvsTableInfo); extdecl;
const
   cNumericType :Array[1..2] of string=('Numeric', 'Decimal');
  function iif(aCheck:Boolean; aTrue, aFalse:integer):integer;inline;
  begin
    if aCheck then Exit(aTrue) else Exit(aFalse);
  end;

var
  vDts        : IEvsDataset;
  vFld        : IEvsFieldInfo;
begin
  vDts := Query(Format(cFieldsSQL,['WHERE r.RDB$RELATION_NAME='+QuotedStr(aObject.TableName)]));
  vDts.First;
  while not vDts.EOF do begin
    vFld := aObject.NewField;
    ParseFieldData(vDts, vFld);
    vFld.ClearState;
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetTriggers(const aObject :IEvsDatabaseInfo); extdecl;
const
   cSQL = 'SELECT RDB$TRIGGER_NAME     AS TrName, '       + //0
          '       RDB$RELATION_NAME    AS TblName, '      + //1
          '       RDB$TRIGGER_SOURCE   AS TrBody, '       + //2
          '       RDB$TRIGGER_TYPE     AS TrType, '       + //3
          '       RDB$SYSTEM_FLAG    AS System,'          + //4
          '       RDB$TRIGGER_INACTIVE AS TrInactive, '   + //5
          '       RDB$DESCRIPTION      AS trComment '     + //6
          'FROM RDB$TRIGGERS '                            +
          'WHERE RDB$Trigger_Type between 8192 and 8196 ';
  cType : array[0..1] of TEvsTriggerType = (trAfter, trBefore); //trigger_type mod 2
var
  vSql : string;
  vDts :IEvsDataset;
  vTrg :IEvsTriggerInfo;
  procedure vClr;inline;
  begin
    aObject.Remove(vTrg);
    vTrg := nil;
  end;
begin
  vSql := cSQL; // Format(cSQL,[QuotedStr(aObject.TableName)]);
  vDts := Query(vSql);
  vDts.First;
  while not vDts.EOF do begin
    vTrg             := aObject.NewTrigger;
    vTrg.Name        := Trim(vDts.Field[0].AsString);
    vTrg.SQL         := Trim(vDts.Field[2].AsString);
    vTrg.Description := Trim(vDts.Field[6].AsString);
    vTrg.TriggerType := trDatabase;// cType[vDts.Field[3].AsInt32 mod 2];
    case vDts.Field[3].AsInt32 of
      //database triggers.
      8192 : vTrg.Event := [teOnConnect];     //- on connect
      8193 : vTrg.Event := [teOnDisconnect];  //- on disconnect
      8194 : vTrg.Event := [teTransStart];    //- on transaction start
      8195 : vTrg.Event := [teTransCommit];   //- on transaction commit
      8196 : vTrg.Event := [teTransRollback]; //- on transaction rollback
    else begin
        vClr;
        raise ETBException.CreateFmt('Unsupported trigger %D',[vDts.Field[3].AsInt32]);
      end;
    end;
    if Assigned(vTrg) then vTrg.ClearState;
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetTriggers(const aObject :IEvsTableInfo; const System :ByteBool); extdecl;
const
   cSQL = 'SELECT RDB$TRIGGER_NAME   AS trigger_name, ' + //0
                 'RDB$RELATION_NAME  AS table_name, '   + //1
                 'RDB$TRIGGER_SOURCE AS trigger_body, ' + //2
                 'RDB$TRIGGER_TYPE   AS Trigger_Type, ' + //3
                 'RDB$SYSTEM_FLAG    AS System,'        + //4
                 'RDB$TRIGGER_INACTIVE as Inactive, '   + //5
                 'RDB$DESCRIPTION AS trigger_comment '  + //6
        'FROM RDB$TRIGGERS '                            +
        'WHERE UPPER(RDB$RELATION_NAME)=%S';
  cType : array[0..1] of TEvsTriggerType = (trAfter, trBefore); //trigger_type mod 2

var
  vSql :String;
  vDts :IEvsDataset;
  vTrg :IEvsTriggerInfo;
  procedure vClr;inline;
  begin
    aObject.Remove(vTrg);
    vTrg := nil;
  end;
begin
  vSql := Format(cSQL,[QuotedStr(UpperCase(aObject.TableName))]);
  vDts := Query(vSql);
  vDts.First;
  while not vDts.EOF do begin
    if (vDts.Field[4].AsInt32 > 1) and (not System)then begin vDts.Next; Continue; end;
    vTrg := aObject.NewTrigger;
    vTrg.Name := Trim(vDts.Field[0].AsString);
    vTrg.SQL  := Trim(vDts.Field[2].AsString);
    vTrg.Description := Trim(vDts.Field[6].AsString);
    vTrg.TriggerType := cType[vDts.Field[3].AsInt32 mod 2];
    vTrg.Active      := vDts.Field[5].AsInt32 = 0;
    case vDts.Field[3].AsInt32 of
      1,2    : vTrg.Event := [teInsert];
      3,4    : vTrg.Event := [teUpdate];
      5,6    : vTrg.Event := [teDelete];
      17,18  : vTrg.Event := [teInsert,teUpdate];
      25,26  : vTrg.Event := [teInsert,teDelete];
      27,28  : vTrg.Event := [teDelete,teUpdate];
      113,114: vTrg.Event := [teInsert,teDelete,teUpdate];
      //database triggers.
      8192..8196 : vClr;
    else begin
        vClr;
        raise ETBException.CreateFmt('Unsupported trigger %D',[vDts.Field[3].AsInt32]);
      end;
    end;
    if Assigned(vTrg) then vTrg.ClearState;
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetStored(const aObject :IEvsDatabaseInfo); extdecl;
const
  cSql = 'SELECT RDB$PROCEDURE_NAME, '         +  //0
                'RDB$DESCRIPTION, '           +  //1
                'RDB$PROCEDURE_TYPE, '         +  //2
                'RDB$PROCEDURE_SOURCE '       +  //3
         'FROM RDB$PROCEDURES ';
  cParamSql = 'SELECT ' +
              '       pr.RDB$Parameter_Name       AS Field_Name, '                 + //00
              '       r.RDB$DESCRIPTION           AS field_description, '          + //01
              '       r.RDB$DEFAULT_SOURCE        AS field_default_source, '       + //02
              '       r.RDB$NULL_FLAG             AS field_not_null_constraint, '  + //03
              '       f.RDB$FIELD_LENGTH          AS field_length, '               + //04
              '       f.RDB$Character_LENGTH      AS characterlength, '            + //05
              '       f.RDB$FIELD_PRECISION       AS field_precision, '            + //06
              '       f.RDB$FIELD_SCALE           AS field_scale, '                + //07
              '       f.RDB$FIELD_TYPE            AS field_type_int, '             + //08
              '       f.RDB$FIELD_SUB_TYPE        AS field_sub_type, '             + //09
              '       F.RDB$SEGMENT_LENGTH        AS Field_Segment_Length, '       + //10
              '       coll.RDB$COLLATION_NAME     AS field_collation, '            + //11
              '       cset.RDB$CHARACTER_SET_NAME AS field_charset, '              + //12
              '       f.RDB$computed_source       AS computed_source, '            + //13
              '       dim.RDB$UPPER_BOUND         AS array_upper_bound, '          + //14
              '       r.RDB$FIELD_SOURCE          AS field_source '                + //15
              'FROM rdb$procedure_parameters pr ' +
              '   LEFT JOIN RDB$FIELDS f             ON f.rdb$field_name       = pr.rdb$field_source ' +
              '   LEFT JOIN RDB$RELATION_FIELDS r    ON r.RDB$FIELD_SOURCE     = f.RDB$FIELD_NAME ' +
              '   LEFT JOIN RDB$COLLATIONS coll      ON f.RDB$COLLATION_ID     = coll.RDB$COLLATION_ID '+
              '                                     AND f.rdb$character_set_id = coll.rdb$character_set_id ' +
              '   LEFT JOIN RDB$CHARACTER_SETS cset  ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID ' +
              '   LEFT JOIN RDB$FIELD_DIMENSIONS dim ON f.RDB$FIELD_NAME       = dim.RDB$FIELD_NAME ' +
              'WHERE pr.RDB$Procedure_Name = %S ' +
              'ORDER BY r.RDB$FIELD_POSITION';

var
  vDts  : IEvsDataset    = nil;
  vFlds : IEvsDataset    = nil;
  vFld  : IEvsFieldInfo  = nil;
  vPrc  : IEvsStoredInfo = nil;
  vName, vSQL : string;
begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    //vPrc := aObject.NewStored(FieldValueDef(vDts.Field[0],''), vDts.Field[4].AsString);
    vName := FieldValueDef(vDts.Field[0],'', True);
    vSQL  := FieldValueDef(vDts.Field[3],'', True);
    vPrc := aObject.NewStored(vName, vSQL);
    vPrc.Description := Trim(vDts.Field[1].AsString);
    vFlds := Query(Format(cParamSql,[QuotedStr(Trim(vDts.Field[0].AsString))]));
    vFlds.First;
    while not vFlds.EOF do begin
      vFld := vPrc.NewField(Trim(vFlds.Field[0].AsString));
      ParseFieldData(vFlds, vFld);
      vFld.ClearState;
      vFlds.Next;
      vFld := Nil;
    end;
    vFlds := Nil;
    vPrc.ClearState;
    vDts.Next;
  end;
  //raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
  vDts := Nil;
  vFld := Nil;
end;

Procedure TEvsMDOConnection.GetViewInfo (const aObject :IEvsViewInfo);    Overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
const
  cFldSql = 'SELECT f.rdb$field_name, '            + //0       'SELECT r.RDB$FIELD_NAME            AS field_name, '                                       + //0
                   'f.RDB$DESCRIPTION,  '          + //1       '       r.RDB$DESCRIPTION           AS field_description, '                                + //1
                   'f.rdb$default_source, '        + //2       '       r.RDB$DEFAULT_SOURCE        AS field_default_source, ' {SQL text for default value}+ //2
                   'f.rdb$null_flag, '             + //3       '       r.RDB$NULL_FLAG             AS field_not_null_constraint, '                        + //3
                   'fs.rdb$field_length, '         + //4       '       f.RDB$FIELD_LENGTH          AS field_length, '                                     + //4
                   'fs.rdb$character_length, '     + //5       '       f.RDB$Character_LENGTH      AS characterlength, '                                  + //5 {character_length seems a reserved word }
                   'fs.rdb$field_precision, '      + //6       '       f.RDB$FIELD_PRECISION       AS field_precision, '                                  + //6
                   'fs.rdb$field_scale, '          + //7       '       f.RDB$FIELD_SCALE           AS field_scale, '                                      + //7
                   'fs.rdb$field_type, '           + //8       '       f.RDB$FIELD_TYPE            AS field_type_int, '                                   + //8
                   'fs.rdb$field_sub_type, '       + //9       '       f.RDB$FIELD_SUB_TYPE        AS field_sub_type, '                                   + //9
                   'co.rdb$collation_name, '       + //10      '       coll.RDB$COLLATION_NAME     AS field_collation, '                                  + //10
                   'cr.rdb$character_set_name, '   + //11      '       cset.RDB$CHARACTER_SET_NAME AS field_charset, '                                    + //11
                   'fs.rdb$computed_source, '      + //12      '       f.RDB$computed_source       AS computed_source, '                                  + //12
                   'fs.rdb$segment_length, '       + //13      '       F.RDB$SEGMENT_LENGTH        AS Field_Segment_Length, '                             + //13
                   'd.rdb$upper_bound, '           + //14      '       dim.RDB$UPPER_BOUND         AS array_upper_bound, '                                + //14
                   'f.rdb$field_source, '          + //15      '       r.RDB$FIELD_SOURCE          AS field_source ' {domain if field based on domain}    + //15
                   'd.rdb$lower_bound, '           + //16      'FROM RDB$RELATION_FIELDS r ' +
                   'fs.rdb$dimensions, '           + //17      '   LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME ' +
                   'f.rdb$field_position, '        + //18      '   LEFT JOIN RDB$FIELD_DIMENSIONS dim on f.RDB$FIELD_NAME = dim.RDB$FIELD_NAME '+
                   'f.rdb$system_flag, '           + //19
                   'fs.rdb$validation_source, '    + //20
                   'f.rdb$relation_name as owner ' + //21
            'FROM RDB$Relation_fields f '          +
               'LEFT JOIN RDB$Fields fs on fs.rdb$field_name = f.rdb$field_source '                    +
               'LEFT JOIN RDB$Field_dimensions d on d.rdb$field_name = fs.rdb$field_name '             +
               'LEFT JOIN RDB$Character_sets cr on fs.rdb$character_set_id = cr.rdb$character_set_id ' +
               'LEFT JOIN RDB$Collations co on ((f.rdb$collation_id = co.rdb$collation_id) and (fs.rdb$character_set_id = co.rdb$character_set_id)) ' +
            'WHERE f.rdb$relation_name = %S ' +
            'ORDER BY f.rdb$field_position, d.rdb$dimension ';
var
  vFld  :IEvsFieldInfo;
  vFlds :IEvsDataset;
begin
  vFlds := Query(Format(cFldSql,[QuotedStr(aObject.Name)]));
  while not vFlds.EOF do begin
    vFld := aObject.FieldList.New;
    ParseFieldData(vFlds, vFld);
    vFlds.Next;
  end;
end;

Procedure TEvsMDOConnection.GetViews(const aObject :IEvsDatabaseInfo); extdecl;
const
  cSql = 'SELECT RDB$RELATION_NAME  AS View_Name, '        +//0
               'RDB$VIEW_BLR        AS View_BLR, '         +//1
               'RDB$VIEW_SOURCE     AS View_Body, '        +//2
               'RDB$DESCRIPTION     AS View_Description, ' +//3
               'RDB$RELATION_ID     AS View_ID, '          +//4
               'RDB$SYSTEM_FLAG     AS View_Flag '         +//5
         'FROM RDB$RELATIONS '                             +
         'WHERE RDB$VIEW_SOURCE IS NOT NULL ';

var
  vDts  :IEvsDataset;
  vVw   :IEvsViewInfo;
begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    vVw := aObject.NewView(Trim(vDts.Field[0].AsString), Trim(vDts.Field[2].AsString));
    vVw.Description := Trim(vDts.Field[3].AsString);
    GetViewInfo(vVw);
    vDts.Next;
  end;
  vDts := Nil;
end;

Procedure TEvsMDOConnection.GetUDFs(const aObject :IEvsDatabaseInfo); extdecl;{$MESSAGE WARN 'Needs Implementation'}
const
  cSQL     = 'SELECT RDB$FUNCTION_NAME, ' + //0
                    'RDB$MODULE_NAME, '   + //1
                    'RDB$ENTRYPOINT '     + //2
             'FROM RDB$FUNCTIONS '        +
             'WHERE RDB$SYSTEM_FLAG = 0 ' +
             'ORDER BY RDB$FUNCTION_NAME';
  cDetails = 'SELECT RDB$FUNCTION_NAME, '     + //0
                    'RDB$ARGUMENT_POSITION, ' + //1
                    'RDB$MECHANISM, '         + //2
                    'RDB$FIELD_TYPE, '        + //3
                    'RDB$FIELD_SCALE, '       + //4
                    'RDB$FIELD_LENGTH, '      + //5
                    'RDB$FIELD_SUB_TYPE, '    + //6
                    'RDB$CHARACTER_SET_ID, '  + //7
                    'RDB$FIELD_PRECISION, '   + //8
                    'RDB$CHARACTER_LENGTH '   + //9
             'FROM RDB$FUNCTION_ARGUMENTS '   +
             'WHERE RDB$MECHANISM = 1 '       +
               'AND RDB$FUNCTION_Name = %S ';
var
  vDts : IEvsDataset;
  vUdf : IEvsUDFInfo;
  vFldList:IEvsFieldList;
  procedure GetDetails(const aUdf:IEvsUDFInfo);
  var
    vDts : IEvsDataset;
  begin
    vDts := Query(Format(cDetails,[QuotedStr(UpperCase(aUdf.Name))]));
    vDts.First;
    While Not vDts.EOF do begin
        GetFBTypeName(vDts.Field[3].AsInt32, //qryMain.FieldByName('RDB$FIELD_TYPE').AsInteger,
                      vDts.Field[6].AsInt32, //qryMain.FieldByName('RDB$FIELD_SUB_TYPE').AsInteger,
                      vDts.Field[5].AsInt32, //qryMain.FieldByName('RDB$FIELD_LENGTH').AsInteger,
                      vDts.Field[8].AsInt32, //qryMain.FieldByName('RDB$FIELD_PRECISION').AsInteger,
                      vDts.Field[4].AsInt32  //qryMain.FieldByName('RDB$FIELD_SCALE').AsInteger
                     );
      //if qryMain.FieldByName('RDB$FIELD_TYPE').AsInteger in [CharType, CStringType, VarCharType] then
      //  Params:= Params + '(' + qryMain.FieldByName('RDB$Character_LENGTH').AsString + ')';
      //qryMain.Next;
      //if not qryMain.EOF then
      //  Params:= Params + ', ';
      vDts.Next;
    end;
  end;

begin
  //qryMain.SQL.Text:= Format('SELECT * FROM RDB$FUNCTIONS WHERE RDB$FUNCTION_NAME = ''%s'' ',[UDFName]);
  //qryMain.Open;
  //ModuleName:= Trim(qryMain.FieldByName('RDB$MODULE_NAME').AsString);
  //EntryPoint:= Trim(qryMain.FieldByName('RDB$ENTRYPOINT').AsString);
  vDts := Query(cSQL);
  vDts.First;
  While Not vDts.EOF do begin
    vUdf := aObject.NewUDF(Trim(vDts.Field[0].AsString));
    vUdf.ModuleName := Trim(vDts.Field[1].AsString);
    GetDetails(vUdf);
    vDts.Next;
  end;
  //raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

Procedure TEvsMDOConnection.GetUsers(const aDB :IEvsDatabaseInfo); extdecl;
const
  cSql = 'SELECT DISTINCT RDB$USER ' +
         'FROM RDB$USER_PRIVILEGES ' +
         'WHERE RDB$PRIVILEGE = ''M''';

var
  vDts :IEvsDataset;
  vUsr :IEvsUserInfo;
  vSrv :TMDOSecurityService;
begin
  vDts := Query(cSql);
  vDts.First;
  vUsr := aDB.NewUser;
  vUsr.UserName := 'SYSDBA';//special case always present.
  while not vDts.EOF do begin {$MESSAGE WARN 'unreliable method to get the users use the service.'}
    vUsr := aDB.NewUser;
    vUsr.UserName := Trim(vDts.Field[0].AsString);
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetRoles(const aDB :IEvsDatabaseInfo); extdecl;
const
  cSql = 'SELECT RDB$ROLE_NAME, '   + //0
                'RDB$OWNER_NAME, '  + //1
                'RDB$DESCRIPTION, ' + //2
                'RDB$SYSTEM_FLAG '  + //3
         'FROM RDB$ROLES ';
var
  vDts  :IEvsDataset;
  vRole :IEvsRoleInfo;
begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    vRole := aDB.NewRole;
    vRole.Name := Trim(vDts.Field[0].AsString);
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetExceptions(const aDB :IEvsDatabaseInfo); extdecl;
const
  cSQL = 'SELECT RDB$EXCEPTION_NAME, ' + //0
                'RDB$MESSAGE, '        + //1
                'RDB$DESCRIPTION, '    + //2
                'RDB$SYSTEM_FLAG '     + //3
         'FROM RDB$EXCEPTIONS '        +
         'ORDER BY RDB$EXCEPTION_NAME';

var
  vDts : IEvsDataset;
  vExc : IEvsExceptionInfo;
begin
  vDts := Query(cSQL);
  vDts.First;
  while not vDts.EOF do begin
    vExc := aDB.NewException(Trim(vDts.Field[0].AsString), Trim(vDts.Field[1].AsString));
    vExc.ClearState;
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetSequences(const aDB :IEvsDatabaseInfo); extdecl;
const
  cSql = 'SELECT RDB$GENERATOR_NAME '+
         'FROM RDB$GENERATORS '      +
         'WHERE RDB$SYSTEM_FLAG=0';
var
  vGen : IEvsGeneratorInfo;
  vDts : IEvsDataset;
begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    vGen := aDB.NewSequence;
    vGen.Name := Trim(vDts.Field[0].AsString);
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetIndices(const aObject :IEvsDatabaseInfo); extdecl;
var
  vCntr : Integer;
begin
  for vCntr := 0 to aObject.TableCount -1 do begin
    GetIndices(aObject.Table[vCntr]);
  end;
end;

Procedure TEvsMDOConnection.GetIndices(const aObject :IEvsTableInfo); extdecl;
const
   cIndicesSQL = 'SELECT RDB$INDICES.RDB$RELATION_NAME         AS Table_Name, '    + //0|
                 '       RDB$INDICES.RDB$INDEX_NAME            AS Index_Name, '    + //1|
	         '       RDB$INDEX_SEGMENTS.RDB$FIELD_NAME     AS Field_Name, '    + //2|
                 '       RDB$INDICES.RDB$INDEX_INACTIVE        AS Index_InActive, '+ //3|
                 '       RDB$INDICES.RDB$UNIQUE_FLAG           AS Index_Unique, '  + //4|
                 '       RDB$INDICES.RDB$INDEX_TYPE            AS Index_Order, '   + //5| 1 = desc , null=asc.
                 '       RDB$INDICES.RDB$DESCRIPTION           AS Description, '   + //6|
                 '       RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION AS Field_Position,' + //7|
                       ' RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_TYPE AS Rel_Type '+ //8| PRIMARY KEY, UNIQUE, FOREIGN KEY, CHECK, NULL
                 'FROM   RDB$INDEX_SEGMENTS '+
                 '  LEFT JOIN RDB$INDICES ON RDB$INDICES.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME '+
                 '  LEFT JOIN RDB$RELATION_CONSTRAINTS ON RDB$RELATION_CONSTRAINTS.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME '+
                 'WHERE UPPER(RDB$INDICES.RDB$RELATION_NAME)=%S ' + //table name
                 '  AND (RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_TYPE IS NULL  or '+
                 '       RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'') '+
                 'ORDER BY RDB$INDICES.RDB$RELATION_NAME, '+
		 '         RDB$INDICES.RDB$INDEX_NAME, '+
                 '         RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION ';
var
  vDts   : IEvsDataset   = nil;
  vIndex : IEvsIndexInfo = nil;
  function GetOrder:TEvsSortOrder;inline;
  begin
    Result := orAscending;
    if FieldValueDef(vDts.Field[5], 0) <> 0 then Result := orDescending;
  end;
begin
  vDts := Query(Format(cIndicesSQL, [QuotedStr(UpperCase(aObject.TableName))]));
  vDts.First;
  while not vDts.EOF do begin //while the index name is the same keep adding fields.
    if (Not Assigned(vIndex)) or (CompareText(vIndex.IndexName, trim(vDts.Field[1].AsString))<>0) then begin //this is a new index
      vIndex := aObject.AddIndex(trim(vDts.Field[1].AsString), orUnSupported);
      vIndex.IndexName := Trim(vDts.Field[1].AsString);
      vIndex.Order     := GetOrder;
      vIndex.Unique    := FieldValueDef(vDts.Field[4],False);
      vIndex.Primary   := WideCompareText('PRIMARY KEY', Trim(vDts.Field[8].AsString)) = 0;
    end;
    vIndex.AppendField(aObject.FieldByName(Trim(vDts.Field[2].AsString)), orUnSupported);
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetDomains(const aObject :IEvsDatabaseInfo); extdecl;
const
  cSQL = 'SELECT RDB$FIELDS.RDB$FIELD_NAME ' +
         'FROM  RDB$FIELDS ' +
           'INNER JOIN RDB$RELATION_FIELDS ON (RDB$RELATION_FIELDS.RDB$FIELD_SOURCE = RDB$FIELDS.RDB$FIELD_NAME) ' +
         'WHERE RDB$FIELDS.RDB$Field_Name not like ''RDB$%'' ' +
           'and RDB$FIELDS.RDB$SYSTEM_FLAG = 0 ' +
         'GROUP BY RDB$FIELDS.RDB$FIELD_NAME ';
  cDetails = 'SELECT f.RDB$FIELD_TYPE, '          + // 0
                    'f.RDB$FIELD_SUB_TYPE, '      + // 1
                    'f.RDB$FIELD_LENGTH, '        + // 2
                    'f.RDB$FIELD_PRECISION, '     + // 3
                    'f.RDB$FIELD_SCALE, '         + // 4
                    'f.RDB$FIELD_LENGTH, '        + // 5
                    'f.RDB$DEFAULT_SOURCE, '      + // 6
                    'f.RDB$VALIDATION_SOURCE, '   + // 7
                    'coll.rdb$collation_name, '   + // 9
                    'cs.rdb$character_set_name '  + //10
             'from rdb$fields as f ' +
               'left join (rdb$collations as coll inner join rdb$character_sets as cs on coll.rdb$character_set_id=cs.rdb$character_set_id ) ' +
                     'on f.rdb$collation_id=coll.rdb$collation_id and f.rdb$character_set_id=coll.rdb$character_set_id ' +
             'where f.rdb$field_name=%S ';
  procedure GetDomainDetails(const aDomain:IEvsDomainInfo);
  var
    vDtls:IEvsDataset;
  begin
    vDtls := Query(Format(cDetails, [QuotedStr(UpperCase(aDomain.Name))]));
    vDtls.First;
    while Not vDtls.EOF do begin
      //aDomain.DataType := vDtls.Field[0].AsString;
      aDomain.DataType := GetFBTypeName(vDtls.Field[0].AsInt32,
                                        vDtls.Field[1].AsInt32,
                                        vDtls.Field[2].AsInt32,
                                        vDtls.Field[3].AsInt32,
                                        vDtls.Field[4].AsInt32
                                       );
      aDomain.Size            := vDtls.Field[5].AsInt32;
      aDomain.DefaultValue    := Trim(vDtls.Field[6].AsString);
      aDomain.CheckConstraint := Trim(vDtls.Field[7].AsString);
      aDomain.CharSet         := Trim(vDtls.Field[8].AsString);
      aDomain.Collation       := Trim(vDtls.Field[9].AsString);
      vDtls.Next;
    end;
  end;
var
  vDts : IEvsDataset;
  vDmn : IEvsDomainInfo;
begin
  vDts := Query(cSQL);
  vDts.First;
  While Not vDts.EOF do begin
    vDmn := aObject.NewDomain(Trim(vDts.Field[0].AsString),'',0);
    GetDomainDetails(vDmn);
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetForeignKeys(Const aObject :IEvsTableInfo); extdecl;
const
  cSQL = 'SELECT PK.RDB$RELATION_NAME AS PrTable_Name' + //0
    LineEnding +' ,ISP.RDB$FIELD_NAME AS PrField_Name'    + //1
                ' ,FK.RDB$RELATION_NAME AS secTable_Name' + //2
                ' ,ISF.RDB$FIELD_NAME AS SecColumn_Name'  + //3
                ' ,ISP.RDB$FIELD_POSITION AS Key_Seq'     + //4
                ' ,RC.RDB$UPDATE_RULE AS Update_Rule'     + //5
                ' ,RC.RDB$DELETE_RULE AS Delete_Rule'     + //6
                ' ,PK.RDB$CONSTRAINT_NAME AS PK_NAME'     + //7
                ' ,FK.RDB$CONSTRAINT_NAME AS FK_NAME'     + //8
  LineEnding +' FROM  RDB$RELATION_CONSTRAINTS PK'      +
               ' ,RDB$RELATION_CONSTRAINTS FK'  +
               ' ,RDB$REF_CONSTRAINTS RC'       +
               ' ,RDB$INDEX_SEGMENTS ISP' +
               ' ,RDB$INDEX_SEGMENTS ISF' +
  LineEnding + ' WHERE FK.RDB$RELATION_NAME = %S'   +
             ' AND FK.RDB$CONSTRAINT_NAME = RC.RDB$CONSTRAINT_NAME' +
             ' AND PK.RDB$CONSTRAINT_NAME = RC.RDB$CONST_NAME_UQ'   +
             ' AND ISP.RDB$INDEX_NAME = PK.RDB$INDEX_NAME'          +
             ' AND ISF.RDB$INDEX_NAME = FK.RDB$INDEX_NAME'          +
             ' AND ISP.RDB$FIELD_POSITION = ISF.RDB$FIELD_POSITION' +
  LineEnding+' ORDER BY PK.RDB$RELATION_NAME, FK.RDB$RELATION_NAME, ISP.RDB$FIELD_POSITION ';

var
  vDts :IEvsDataset = nil;
  vFK  :IEvsForeignKey = nil;
  vCmd :string='';
  function CurrentFK:Widestring;inline;
  begin
    Result :='';
    if Assigned(vFK) then Result := vFK.Name;
  end;
  function ParseRule(const aValue:widestring):TEvsConstraintRule;inline;
  begin
    Result := crNoAction;//'' in case of unknown value assume restrict.
    if WideCompareText(aValue,'Cascade') = 0 then Result := crCascade
    else if WideCompareText(aValue,'Set Null') = 0 then Result := crSetNull
    else if WideCompareText(aValue,'Set Default') = 0 then Result := crSetDefault
    //else if WideCompareText(aValue,'Restrict') = 0 then Result := crNoAction
    ;
  end;
//var
//  dbg:integer;
begin
  vCmd := Format(cSQL,[QuotedStr(aObject.TableName)]);
  vDts := Query(Format(cSQL,[QuotedStr(aObject.TableName)]));
  vDts.First;
  while not vDts.EOF do begin
    //dbg := WideCompareText(CurrentFK, FieldValueDef(vDts.Field[8], '', True));
    if (WideCompareText(CurrentFK, FieldValueDef(vDts.Field[8], '', True)) <> 0) then begin
      vFK := aObject.NewForeignKey;
      vFK.Name := FieldValueDef(vDts.Field[8], '', True);
      vFK.PrimaryTable := FieldValueDef(vDts.Field[0], '', True);
      vFK.OnUpdate := ParseRule(FieldValueDef(vDts.Field[5],''));
      vFK.OnDelete := ParseRule(FieldValueDef(vDts.Field[6],''));
    end;
    vFK.AddPair(Trim(vDts.Field[1].AsString), Trim(vDts.Field[3].AsString));
    vDts.Next;
  end;
end;

Procedure TEvsMDOConnection.GetAll(const aDB :IEvsDatabaseInfo);extdecl;
begin
  inc(FReversing);// := True;
  try
    GetTables(aDB);
    GetDomains(aDB);
    GetExceptions(aDB);
    GetRoles(aDB);
    GetUDFs(aDB);
    GetStored(aDB);
    GetTriggers(aDB);
    GetSequences(aDB);
    GetUsers(aDB);
    GetViews(aDB);
  finally
    Dec(FReversing);// := False;
  end;
end;

Function TEvsMDOConnection.GetFieldDDL(Const aObject :IEvsFieldInfo) :widestring; extdecl;
begin
  raise utbcommon.NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

Function TEvsMDOConnection.GetTableDDL(Const aObject :IEvsTableInfo) :widestring; extdecl;
begin
  raise utbcommon.NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

Function TEvsMDOConnection.GetCharsets :PVarArray; extdecl;
begin
  Result := VarArrayAsPSafeArray(_VarArray(uCharSets.SupportedCharacterSets));
end;

Function TEvsMDOConnection.Collations(const aCharSet :Widestring) :PVarArray; extdecl;
begin
  Result := VarArrayAsPSafeArray(_VarArray(uCharSets.SupportedCollations(aCharSet)));
end;

{$ENDREGION}

initialization
  {$IFDEF POOL_QRY}
  TEvsMDOConnection.FQryPool := TMDOQueryPool.Create(10,True);
  TEvsMDOConnection.FCnnPool := TMDODatabasePool.Create(10,True);
  {$ENDIF}
  RegisterDBType(stFirebird, 'Firebird', @Connect, @Create, @Backup, @Restore,@CharSets, @CharSetCollations);
finalization
  {$IFDEF POOL_QRY}
  FreeAndNil(TEvsMDOConnection.FQryPool);
  FreeAndNil(TEvsMDOConnection.FCnnPool);
  {$ENDIF}

end.


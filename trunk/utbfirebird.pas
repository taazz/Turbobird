unit uTBFirebird;

{$mode delphi}{$H+}
{$Include EvsDefs.inc}
interface

uses
  Classes, SysUtils, db, MDODatabase, MDOQuery, MDODatabaseInfo, {SysTables,}  uEvsDBSchema, utbcommon, uTBTypes;

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
    procedure BeforeDestruction; override;
  end;

  { TEvsMDOConnection }
  TEvsMDOConnection = class(TEvsAbstractConnectionProxy, IEvsMetaData)
  private
    //FActiveConnection : TMDODataBase;


    class var FQryPool : TMDOQueryPool; //static;
    class var FCnnPool : TMDODatabasePool;//static;
    class function NewQuery:TMDOQuery;

  protected
    function GetConnection :IEvsConnection;extdecl;
    function GetMetaData   :IEvsMetaData; override;extdecl;
    procedure SetParamValue(const aParamName, aParamValue:String);inline;//all code in one place.
    //called by the Interface directly.
    function  InternalExecute(aSQL :WideString) :ByteBool;  override;extdecl; {$MESSAGE WARN 'Needs Testing'}
    function  InternalQuery(aSQL :wideString) :IEvsDataset; override;extdecl; {$MESSAGE WARN 'Needs Testing'}
    function  InternalGetCharSet :widestring;               override;extdecl;
    function  InternalGetPassword :widestring;              override;extdecl;
    function  InternalGetRole :widestring;                  override;extdecl;
    function  InternalGetUserName :widestring;              override;extdecl;
    procedure InternalSetCharSet(aValue :WideString);       override;extdecl;
    procedure InternalSetPassword(aValue :widestring);      override;extdecl;
    procedure InternalSetRole(aValue :widestring);          override;extdecl;
    procedure InternalSetUserName(aValue :widestring);      override;extdecl;

    procedure SetConnection(aValue :IEvsConnection);extdecl;{extdecl;}{$MESSAGE WARN 'Needs Implementation'}
    procedure ParseFieldData(constref aDsFields :IEvsDataset; const aField:IEvsFieldInfo);extdecl;
  public
    procedure BeforeDestruction; override;

    //function GetConnection :IEvsConnection;extdecl;
    //procedure SetConnection(aValue :IEvsConnection);extdecl;

    procedure GetTables(const aDB:IEvsTableList);       overload;extdecl; //append the tables in the list passed
    procedure GetTables(const aDB:IEvsDatabaseInfo);    overload;extdecl; //append the tables in the database passed.
    procedure GetFields(const aObject:IEvsTableInfo);   overload;extdecl; //find all the fields of the table and return them in the table's field list.
    //function GetFields(const aObject:IEvsStoredInfo):IEvsFieldList;extdecl;
    //function GetFields(const aObject:IEvsDatabaseInfo):IEvsFieldList;extdecl;
    //procedure GetTriggers(const aObject:IEvsTriggerList); overload;extdecl;
    procedure GetTriggers(const aObject :IEvsTableInfo);    overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    procedure GetTriggers(const aObject :IEvsDatabaseInfo); overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    procedure GetStored(const aObject:IEvsDatabaseInfo);    overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    procedure GetViews(const aObject:IEvsDatabaseInfo);     overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    procedure GetSequences(const aDB:IEvsDatabaseInfo);              extdecl;{$MESSAGE WARN 'Needs Testing'}
    procedure GetUDFs(const aObject:IEvsDatabaseInfo);               extdecl;{$MESSAGE WARN 'Needs Implementation'}
    procedure GetUsers(const aDB:IEvsDatabaseInfo);                  extdecl;{$MESSAGE WARN 'Needs Implementation'}
    procedure GetRoles(const aDB:IEvsDatabaseInfo);                  extdecl;{$MESSAGE WARN 'Needs Implementation'}
    procedure GetExceptions(const aDB:IEvsDatabaseInfo);             extdecl;{$MESSAGE WARN 'Needs Testing'}
    //procedure GetDomains(const aDB:IEvsDatabaseInfo);             extdecl;{$MESSAGE WARN 'Needs Testing'}
    //the aTableName can be empty in which case it should either
    //return all the indices in the database or raise an exception.
    //procedure GetIndices(const aObject:IEvsIndexList);      overload;extdecl;
    procedure GetIndices(const aObject:IEvsDatabaseInfo);   overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    procedure GetIndices(const aObject:IEvsTableInfo);      overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    procedure GetDomains(const aObject:IEvsDatabaseInfo);   overload;extdecl;{$MESSAGE WARN 'Needs Implementation'}

    //the aTableName can be empty in which case it should either
    //return all the indices in the database or raise an exception.
    //function GetIndices(const aObject:IInterface):IEvsIndexList;
    property Connection:IEvsConnection read GetConnection write SetConnection;
  end;

//The Connection string must have all the required information to connect to the server separated semicolon.
//function Connect(aHost, aDatabase, aUser, aPwd, aRole, aCharset:Widestring) :IEvsConnection;
function ConncetionSting(const aDB:TDatabase):string;

implementation
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

function FieldValueDef(Const aField:IEvsField; const aDefault:Widestring):Widestring;overload;inline;
begin
  Result := aDefault;
  if not aField.IsNull then Result := aField.AsString;
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

function Connect(aHost, aDatabase, aUser, aPwd, aRole, aCharset :Widestring) :IEvsConnection;
var
  vObj :TMDODataBase;
begin
  Result := Nil;
  vObj := TEvsMDOConnection.FCnnPool.Aquire;
  vObj.UserName     := aUser;
  vObj.DatabaseName := aHost + ':' + aDatabase;
  vObj.CharSet      := aCharset;
  vObj.Role         := aRole;
  vObj.Password     := aPwd;
  vObj.LoginPrompt  := False;
  vObj.Connected    := True;
  Result            := TEvsMDOConnection.Create(vObj);
end;

{$ENDREGION}

{$REGION ' TEvsMDODatasetProxy '}

procedure TEvsMDODatasetProxy.BeforeDestruction;
begin
  inherited BeforeDestruction;
  if TMDOQuery(FDS).Transaction.Active then TMDOQuery(FDS).Transaction.Rollback;
  TEvsMDOConnection.FQryPool.Return(FDS);
end;

{$ENDREGION}

{$REGION ' TMDODatabasePool '}

function TMDODatabasePool.Aquire :TMDODataBase;
begin
  Result := TMDODataBase(inherited Aquire);
end;

constructor TMDODatabasePool.Create(const aMaxCount :Integer; const aNeededOnly :Boolean);
begin
  inherited Create(aMaxCount, aNeededOnly, TMDODataBase);
end;
{$ENDREGION}

{$REGION ' TMDOQueryPool '}

function TMDOQueryPool.Aquire :TMDOQuery;
begin
  Result := TMDOQuery(inherited Aquire);
end;

constructor TMDOQueryPool.Create(const aMaxCount :Integer; const aNeededOnly :Boolean);
begin
  Create(aMaxCount, aNeededOnly, TMDOQuery);
end;
{$ENDREGION}

{$REGION ' TEvsMDOConnection '}

class function TEvsMDOConnection.NewQuery :TMDOQuery;
begin
  Result := FQryPool.Aquire;
  if not Assigned(Result.Transaction) then Result.Transaction := TMDOTransaction.Create(Result);
end;

function TEvsMDOConnection.GetConnection :IEvsConnection;extdecl;
begin
  Result := Self;
end;

procedure TEvsMDOConnection.SetConnection(aValue :IEvsConnection);extdecl;
begin
  raise ETBException.Create('This implementation does not support different connections');
end;

procedure TEvsMDOConnection.ParseFieldData(constref aDsFields :IEvsDataset; const aField :IEvsFieldInfo); extdecl;
var
  vScale,
  vLength,
  vPrecision,
  vSubType    : Integer;
  vCharSet,
  vCollation,
  vFieldType  : Widestring;
begin
  vScale     := Abs(aDsFields.Field[7].AsInt32);
  vLength    := FieldValueDef(aDsFields.Field[04], 0);
  vPrecision := FieldValueDef(aDsFields.Field[06], 0);
  vCharSet   := FieldValueDef(aDsFields.Field[11], '');
  vCollation := FieldValueDef(aDsFields.Field[10], '');

  case aDsFields.Field[8].AsInt32 of
    14,
    15: begin
          vFieldType := 'Char';//blr_text, blr_text2, uftChar;
        end;
    37,
    38: begin //blr_varying, blr_varying2
          vFieldType := 'Varchar';
        end;
    40,
    41: begin //blr_cstring, blr_cstring2
          vFieldType := 'Char';
        end;
    7:  begin //blr_short
          vFieldType := 'Smallint';
        end;
    8:  begin //blr_long
          vFieldType := 'Integer';
        end;
    9:  begin
          vFieldType := 'Binary';
          vLength := vPrecision;
        end;
    10,
    11: begin //blr_float, blr_d_float
          vFieldType := 'Float';
          vLength := vPrecision; //aDsFields.Field[6].AsInt32;//Precision;
        end;
    27: begin //blr_double
          vFieldType := 'Double Precision';
          vLength := -8;
        end;
    35: begin  //blr_timestamp
          vFieldType := 'Timestamp';
          vLength    := vPrecision;// aDsFields.Field[6].AsInt32;//Precision;
        end;
    261: begin //blr_blob
           vSubType   := aDsFields.Field[9].AsInt32;//subtype.
           vFieldType := 'Blob';
           vLength    := aDsFields.Field[13].AsInt32;//Segment_Length
           if vSubType = 1 then vFieldType := 'Memo';
           if vSubType = 2 then vFieldType := 'BLR';
         end;
    45: begin //blr_blob_id
          raise ETBException.CreateFmt('Unsupported Data Type %D, %S',[aDsFields.Field[8].AsInt32,'blr_BlobID']);
        end;
    12: begin //blr_sql_date
          vFieldType := 'Date';
        end;
    13: begin  //blr_sql_time
          vFieldType := 'Time';
        end;
    16: begin //blr_int64
          if vScale <> 0 then begin
            case aDsFields.Field[9].AsInt32 of
              0 : vFieldType := 'Numeric';
              1 : vFieldType := 'Decimal';
            end;
            vLength := vPrecision;
          end else begin
            vFieldType := 'BigInt';
            vLength := 8;
          end;
        end;
    23,
    17: begin
          vFieldType := 'Boolean';
          raise ETBException.CreateFmt('Unsupported Data Type %D, %S',[aDsFields.Field[8].AsInt32,'blr_bool']);
        end;
  end;

  aField.FieldName    := Trim(aDsFields.Field[0].AsString);
  aField.DataTypeName := Trim(vFieldType);
  aField.FieldSize    := vLength;
  aField.FieldScale   := vScale;
  aField.Charset      := vCharSet;
  aField.Collation    := vCollation;
  aField.AutoNumber   := False;
  aField.DefaultValue := Null;

  if not aDsFields.Field[2].IsNull then
    aField.DefaultValue := Trim(aDsFields.Field[2].AsString);

  if aDsFields.Field[3].IsNull then
    aField.AllowNulls := True
  else
    aField.AllowNulls := not aDsFields.Field[3].AsBoolean;

end;

function TEvsMDOConnection.GetMetaData :IEvsMetaData;extdecl;
begin
  Result := Self as IEvsMetaData;
end;

procedure TEvsMDOConnection.SetParamValue(const aParamName, aParamValue :String);inline;
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

function TEvsMDOConnection.InternalExecute(aSQL :WideString) :ByteBool;extdecl;
var
  vQry:TMDOQuery;
begin
  Result := False;
  vQry := FQryPool.Aquire;
  try
    vQry.Database := TMDODataBase(FCnn);
    vQry.SQL.Text := aSQL;
    vQry.ExecSQL;
    Result := True;
  finally
    FQryPool.Return(vQry);
  end;
end;

function TEvsMDOConnection.InternalGetCharSet :widestring;extdecl;
begin
  Result := TMDODataBase(FCnn).Params.Values[pnCharset];
end;

function TEvsMDOConnection.InternalGetPassword :widestring;extdecl;
begin
  Result := TMDODatabase(FCnn).Params.Values[pnPwd]; //FPassword;//Cnn.Connected;
end;

function TEvsMDOConnection.InternalGetRole :widestring;extdecl;
begin
  Result := TMDODatabase(FCnn).Params.Values[pnRole]//FRole;// FCnn.Connected;
end;

function TEvsMDOConnection.InternalGetUserName :widestring;extdecl;
begin
  Result := TMDODatabase(FCnn).Params.Values[pnUser];// username FUserName; //Cnn.Connected;
end;

function TEvsMDOConnection.InternalQuery(aSQL :wideString) :IEvsDataset;extdecl;
var
  vObj:TMDOQuery;
begin
  vObj := NewQuery;
  vObj.Database := TMDODataBase(FCnn);
  vObj.Transaction.DefaultDatabase := vObj.Database;
  vObj.SQL.Text := aSQL;
  vObj.Open;
  Result := TEvsMDODatasetProxy.Create(vObj);
end;

procedure TEvsMDOConnection.InternalSetCharSet(aValue :WideString);extdecl;
begin
  SetParamValue(pnCharset,aValue);
end;

procedure TEvsMDOConnection.InternalSetPassword(aValue :widestring);extdecl;
begin
  SetParamValue(pnPwd,aValue);
end;

procedure TEvsMDOConnection.InternalSetRole(aValue :widestring);extdecl;
begin
  SetParamValue(pnRole,aValue);
end;

procedure TEvsMDOConnection.InternalSetUserName(aValue :widestring);extdecl;
begin
  SetParamValue(pnUser,aValue);
end;

procedure TEvsMDOConnection.BeforeDestruction;
begin
  inherited BeforeDestruction;
  FCnnPool.Return(FCnn);
end;

procedure TEvsMDOConnection.GetTables(const aDB :IEvsTableList);overload;extdecl;
const
  cSql = 'select rdb$relation_name from rdb$relations where rdb$view_blr is null ' +
        ' and (rdb$system_flag is null or rdb$system_flag = 0) order by rdb$relation_name';
var
  vDts:IEvsDataset;
  vTbl :IEvsTableInfo;
begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    vTbl := aDB.New;//(,);
    vTbl.TableName := vDts.Field[0].AsString;
    vTbl.ClearState;
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetTables(const aDB :IEvsDatabaseInfo);overload;extdecl;
const
  cSql = 'select rdb$relation_name, rdb$system_flag from rdb$relations '+
         'WHERE rdb$view_blr is null ' +
         //' AND (RDB$SYSTEM_FLAG is NULL or RDB$SYSTEM_FLAG = 0) ' +
         ' ORDER BY RDB$RELATION_NAME';
var
  vDts:IEvsDataset;
  vTbl:IEvsTableInfo;
  vSys:Integer;
begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    vTbl := aDB.NewTable(vDts.Field[0].AsString);
    vSys := FieldValueDef(vDts.Field[1],0);
    if vSys = 0 then vTbl.SystemTable := False else vTbl.SystemTable := True;
    vTbl.ClearState;
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetFields(const aObject :IEvsTableInfo);extdecl;
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

//procedure TEvsMDOConnection.GetTriggers(const aObject :IEvsTriggerList); extdecl;
//begin
//  raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
//end;

procedure TEvsMDOConnection.GetTriggers(const aObject :IEvsDatabaseInfo); extdecl;
const
   cSQL = 'SELECT RDB$TRIGGER_NAME     AS TrName, '       + //0
          '       RDB$RELATION_NAME    AS TblName, '      + //1
          '       RDB$TRIGGER_SOURCE   AS TrBody, '       + //2
          '       RDB$TRIGGER_TYPE     AS TrType, '       + //3
          '       RDB$TRIGGER_INACTIVE AS TrInactive, '   + //4
          '       RDB$DESCRIPTION      AS trComment '     + //5
          'FROM RDB$TRIGGERS '                            +
          'WHERE RDB$Trigger_Type between 8192 and 8196 ';
  cType : array[0..1] of TEvsTriggerType = (trAfter, trBefore); //trigger_type mod 2
var
  vSql : string;
  vDts :IEvsDataset;
  vTrg :IEvsTriggerInfo;
  procedure Clear;inline;
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
    vTrg.Name        := vDts.Field[0].AsString;
    vTrg.SQL         := vDts.Field[2].AsString;
    vTrg.Description := vDts.Field[5].AsString;
    vTrg.TriggerType := trDatabase;// cType[vDts.Field[3].AsInt32 mod 2];
    case vDts.Field[3].AsInt32 of
      //database triggers.
      8192 : vTrg.Event := [teOnConnect];     //- on connect
      8193 : vTrg.Event := [teOnDisconnect];  //- on disconnect
      8194 : vTrg.Event := [teTransStart];    //- on transaction start
      8195 : vTrg.Event := [teTransCommit];   //- on transaction commit
      8196 : vTrg.Event := [teTransRollback]; //- on transaction rollback
    else begin
        Clear;
        raise ETBException.CreateFmt('Unsupported trigger %D',[vDts.Field[3].AsInt32]);
      end;
    end;
    if Assigned(vTrg) then vTrg.ClearState;
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetTriggers(const aObject :IEvsTableInfo); extdecl;
const
   cSQL = 'SELECT RDB$TRIGGER_NAME   AS trigger_name, ' + //0
                 'RDB$RELATION_NAME  AS table_name, '   + //1
                 'RDB$TRIGGER_SOURCE AS trigger_body, ' + //2
                 'RDB$TRIGGER_TYPE   AS Trigger_Type, ' + //3
                 ' RDB$TRIGGER_INACTIVE as Inactive, '  + //4
                 'RDB$DESCRIPTION AS trigger_comment '  + //5
        'FROM RDB$TRIGGERS '                            +
        'WHERE UPPER(RDB$RELATION_NAME)=%S';
  cType : array[0..1] of TEvsTriggerType = (trAfter, trBefore); //trigger_type mod 2

var
  vSql : string;
  vDts :IEvsDataset;
  vTrg :IEvsTriggerInfo;
  procedure Clear;inline;
  begin
    aObject.Remove(vTrg);
    vTrg := nil;
  end;
begin
  vSql := Format(cSQL,[QuotedStr(aObject.TableName)]);
  vDts := Query(vSql);
  vDts.First;
  while not vDts.EOF do begin
    vTrg := aObject.NewTrigger;
    vTrg.Name := vDts.Field[0].AsString;
    vTrg.SQL  := vDts.Field[2].AsString;
    vTrg.Description := vDts.Field[5].AsString;
    vTrg.TriggerType := cType[vDts.Field[3].AsInt32 mod 2];
    case vDts.Field[3].AsInt32 of
      1,2    : vTrg.Event := [teInsert];
      3,4    : vTrg.Event := [teUpdate];
      5,6    : vTrg.Event := [teDelete];
      17,18  : vTrg.Event := [teInsert,teUpdate];
      25,26  : vTrg.Event := [teInsert,teDelete];
      27,28  : vTrg.Event := [teDelete,teUpdate];
      113,114: vTrg.Event := [teInsert,teDelete,teUpdate];
      //database triggers.
      8192..8196 : begin Clear; Continue; end;
    else begin
        Clear;
        raise ETBException.CreateFmt('Unsupported trigger %D',[vDts.Field[3].AsInt32]);
      end;
    end;
    if Assigned(vTrg) then vTrg.ClearState;
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetStored(const aObject :IEvsDatabaseInfo);  overload;extdecl;
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
  vDts  : IEvsDataset;
  vFlds : IEvsDataset;
  vFld  : IEvsFieldInfo;
  vPrc  : IEvsStoredInfo;
  vName, vSQL : string;
begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    //vPrc := aObject.NewStored(FieldValueDef(vDts.Field[0],''), vDts.Field[4].AsString);
    vName := FieldValueDef(vDts.Field[0],'');
    vSQL  := FieldValueDef(vDts.Field[3],'');
    vPrc := aObject.NewStored(vName, vSQL);
    vPrc.Description := vDts.Field[1].AsString;
    vFlds := Query(Format(cParamSql,[QuotedStr(vDts.Field[0].AsString)]));
    vFlds.First;
    while not vFlds.EOF do begin
      vFld := vPrc.NewField(vFlds.Field[0].AsString);
      ParseFieldData(vFlds, vFld);
      vFld.ClearState;
      vFlds.Next;
    end;
    vPrc.ClearState;
    vDts.Next;
  end;
  //raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

procedure TEvsMDOConnection.GetViews(const aObject :IEvsDatabaseInfo);   overload;extdecl;
const
  cSql = 'SELECT RDB$RELATION_NAME        AS View_Name, '        +//0
               ' RDB$VIEW_BLR		  AS View_BLR, '         +//1
               ' RDB$VIEW_SOURCE	  AS View_Body, '        +//2
               ' RDB$DESCRIPTION	  AS View_Description, ' +//3
               ' RDB$RELATION_ID	  AS View_ID, '          +//4
               ' RDB$SYSTEM_FLAG	  AS View_Flag '         +//5
         'FROM RDB$RELATIONS '                                   +
         'WHERE RDB$VIEW_SOURCE IS NOT NULL ';

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
  vDts  :IEvsDataset;
  vVw   :IEvsViewInfo;
  vFld  :IEvsFieldInfo;
  vFlds :IEvsDataset;
begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    vVw := aObject.NewView(vDts.Field[0].AsString, vDts.Field[2].AsString);
    vVw.Description := vDts.Field[3].AsString;
    vFlds := Query(Format(cFldSql,[QuotedStr(vVw.Name)]));
    while not vFlds.EOF do begin
      vFld := vVw.FieldList.New;
      ParseFieldData(vFlds, vFld);
      vFlds.Next;
    end;
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetUDFs(const aObject :IEvsDatabaseInfo);    extdecl;{$MESSAGE WARN 'Needs Implementation'}
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
                      vDts.Field[4].AsInt32 //qryMain.FieldByName('RDB$FIELD_SCALE').AsInteger
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
    vUdf := aObject.NewUDF(vDts.Field[0].AsString);
    vUdf.ModuleName := vDts.Field[1].AsString;
    GetDetails(vUdf);
    vDts.Next;
  end;
  raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

procedure TEvsMDOConnection.GetUsers(const aDB :IEvsDatabaseInfo);       extdecl;
const
  cSql = 'SELECT DISTINCT RDB$USER '+
         'FROM RDB$USER_PRIVILEGES';
var
  vDts :IEvsDataset;
  vUsr :IEvsUserInfo;
begin
  vDts := Query(cSql);
  vDts.First;
  while not vDts.EOF do begin
    vUsr := aDB.NewUser;
    vUsr.UserName := vDts.Field[0].AsString;
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetRoles(const aDB :IEvsDatabaseInfo);       extdecl;
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
    vRole.Name := vDts.Field[0].AsString;
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetExceptions(const aDB :IEvsDatabaseInfo);  extdecl;
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
    vExc := aDB.NewException(vDts.Field[0].AsString, vDts.Field[1].AsString);
    vExc.ClearState;
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetSequences(const aDB :IEvsDatabaseInfo);   extdecl;
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
    vGen.GeneratorName := vDts.Field[0].AsString;
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetIndices(const aObject :IEvsDatabaseInfo); overload;extdecl;
var
  vCntr : Integer;
begin
  for vCntr := 0 to aObject.TableCount -1 do begin
    GetIndices(aObject.Table[vCntr]);
  end;
end;

procedure TEvsMDOConnection.GetIndices(const aObject :IEvsTableInfo);    overload;extdecl;
const
   cIndicesSQL = 'SELECT RDB$INDICES.RDB$RELATION_NAME         AS Table_Name, '    + //0|
                 '       RDB$INDICES.RDB$INDEX_NAME            AS Index_Name, '    + //1|
	         '       RDB$INDEX_SEGMENTS.RDB$FIELD_NAME     AS Field_Name, '    + //2|
                 '       RDB$INDICES.RDB$INDEX_INACTIVE        AS Index_InActive, '+ //3|
                 '       RDB$INDICES.RDB$UNIQUE_FLAG           AS Index_Unique, '  + //4|
                 '       RDB$INDICES.RDB$INDEX_TYPE            AS Index_Order, '   + //5| 1 = desc , null=asc.
                 '       RDB$INDICES.RDB$DESCRIPTION           AS Description, '   + //6|
                 '       RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION AS Field_Position ' + //7|
                 'FROM   RDB$INDEX_SEGMENTS '+
                 '  LEFT JOIN RDB$INDICES ON RDB$INDICES.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME '+
                 '  LEFT JOIN RDB$RELATION_CONSTRAINTS ON RDB$RELATION_CONSTRAINTS.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX_NAME '+
                 'WHERE UPPER(RDB$INDICES.RDB$RELATION_NAME)=%S ' + //table name
                 '  AND RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_TYPE IS NULL '+
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
    if (Not Assigned(vIndex)) or (CompareText(vIndex.IndexName, vDts.Field[1].AsString)<>0) then begin //this is a new index
      vIndex := aObject.AddIndex(vDts.Field[1].AsString, orUnSupported);
      vIndex.IndexName := vDts.Field[1].AsString;
      vIndex.Order     := GetOrder;
      vIndex.Unique    := FieldValueDef(vDts.Field[4],False);
    end;
    vIndex.AppendField(aObject.FieldByName(Trim(vDts.Field[2].AsString)), orUnSupported);
    vDts.Next;
  end;
end;

procedure TEvsMDOConnection.GetDomains(const aObject :IEvsDatabaseInfo); overload;extdecl;
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
      aDomain.DataType := GetFBTypeName(vDtls.Field[0].AsInt32, //FieldByName('RDB$FIELD_TYPE').AsInteger,
                                        vDtls.Field[1].AsInt32, //MDOQuery.FieldByName('RDB$FIELD_SUB_TYPE').AsInteger,
                                        vDtls.Field[2].AsInt32, //MDOQuery.FieldByName('RDB$FIELD_LENGTH').AsInteger,
                                        vDtls.Field[3].AsInt32, //MDOQuery.FieldByName('RDB$FIELD_PRECISION').AsInteger,
                                        vDtls.Field[4].AsInt32 //MDOQuery.FieldByName('RDB$FIELD_SCALE').AsInteger
                                       );
      aDomain.Size            := vDtls.Field[5].AsInt32; //ByName('RDB$FIELD_LENGTH')
      aDomain.DefaultValue    := Trim(vDtls.Field[6].AsString); //MDOQuery.FieldByName('RDB$DEFAULT_SOURCE').AsString);
      aDomain.CheckConstraint := Trim(vDtls.Field[7].AsString); //MDOQuery.FieldByName('RDB$VALIDATION_SOURCE').AsString); //e.g. CHECK (VALUE > 10000 AND VALUE <= 2000000)
      aDomain.CharSet         := Trim(vDtls.Field[8].AsString); //MDOQuery.FieldByName('rdb$character_set_name').AsString);
      aDomain.Collation       := Trim(vDtls.Field[9].AsString); //MDOQuery.FieldByName('rdb$collation_name').AsString);
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
    vDmn := aObject.NewDomain(vDts.Field[0].AsString,'',0);
    //vDmn.Name := vDts.Field[0].AsString;
    GetDomainDetails(vDmn);
    vDts.Next;
  end;
end;

{$ENDREGION}

initialization
  TEvsMDOConnection.FQryPool := TMDOQueryPool.Create(10,True);
  TEvsMDOConnection.FCnnPool := TMDODatabasePool.Create(10,True);
  RegisterDBType(stFirebird, 'Firebird', @Connect, nil, nil);

finalization
  FreeAndNil(TEvsMDOConnection.FQryPool);
end.


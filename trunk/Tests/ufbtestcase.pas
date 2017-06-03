unit uFBTestcase;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, TestFramework, MDO, uEvsDBSchema, uTBFirebird;

type

  { TFirebirdMetaDataTest }

  { TEvsFBMetaTester }

  TEvsFBMetaTester = class(TTestCase)
  protected
  protected
    FDB :IEvsDatabaseInfo;
    procedure SetUpOnce; override;
    procedure TearDownOnce; override;
    procedure DoConnect;
  public
    procedure CheckEquals(Expected,Actual:TEvsDataGroup; aMessage:string);overload;
    procedure CheckEqualFields(Expected,Actual:IEvsFieldInfo);
    procedure CheckEqualText(const Expected, Actual, aMessage:string);//case insensitive check
  end;

  { TEvsFBMetaTester }
  TFirebirdMetaDataTest= class(TEvsFBMetaTester)
  published
    procedure TestHookUp;
    procedure TestRetrieveFields;
    procedure TestRetrieveExceptions;
    procedure TestRetrieveTriggers;
    procedure TestRetrieveStored;
    procedure TestRetrieveViews;
    procedure TestRetrieveUDFs;
    procedure TestRetrieveDomains;
    procedure TestRetrieveSequences;
    procedure TestRetrieveRoles;
    procedure TestRetrieveUsers;
  public
    procedure TestReverse;
  end;

implementation
uses
   strutils, typinfo;

{$REGION ' UTILS '}

function TableByName(const aDB:IEvsDatabaseInfo; const aTableName:string):IEvsTableInfo;
var
  vCntr :Integer;
begin
  Result:=Nil;
  for vCntr := 0 to aDB.TableCount do
    if CompareText(aTableName,aDB.Table[vCntr].TableName) = 0 then Exit(aDB.Table[vCntr]);
end;

function GetTable(const aDB:IEvsDatabaseInfo; aTableName:String):IEvsTableInfo;
begin
  Result := TableByName(aDB,aTableName);
  if not assigned(Result) then Result := aDB.NewTable(aTableName);
end;

{ TEvsFBMetaTester }

procedure TEvsFBMetaTester.CheckEqualFields(Expected, Actual :IEvsFieldInfo);
begin
  CheckEqualText(Expected.FieldName,   Actual.FieldName,   'Names Differ');
  CheckEquals   (Expected.FieldScale,  Actual.FieldScale, 0.0001, 'Scale Differ');
  CheckEquals   (Expected.FieldSize,   Actual.FieldSize,   'Size  Differ');
  CheckEqualText(Expected.Description, Actual.Description, 'Descriptions Differ');
  CheckEquals   (Expected.AllowNulls,  Actual.AllowNulls,  'AllowNulls Differ');
  CheckEquals   (Expected.AutoNumber,  Actual.AutoNumber,  'AutoNumber Differ');
  CheckEqualText(Expected.Calculated,  Actual.Calculated,  'Calculate Differ');
  CheckEqualText(Expected.Charset,     Actual.Charset,     'CharSet Differ');
  CheckEqualText(Expected.Check,       Actual.Check,       'Check Differ');
  CheckEqualText(Expected.Collation,   Actual.Collation,   'collation Differ');
  CheckEquals   (Expected.DataGroup,   Actual.DataGroup,   'DataGroup Differ');
  CheckEqualText(Expected.DataTypeName,Actual.DataTypeName,'DataTypeName Differ');
  CheckEqualText(Expected.DefaultValue,Actual.DefaultValue,'Default Value Differ');
end;

procedure TEvsFBMetaTester.CheckEqualText(const Expected, Actual, aMessage :string);
begin
  OnCheckCalled;
  if AnsiCompareText(Expected, Actual)<>0 then
    FailNotEquals(Expected, Actual, aMessage, CallerAddr);
end;

procedure TEvsFBMetaTester.SetUpOnce;
begin
  FDB := NewDatabase(stFirebird, 'localhost', 'D:\Data\Firebird\EMPLOYEE.FDB', 'TESTCASES', 'TEST', 'RDB$ADMIN','');
end;

procedure TEvsFBMetaTester.TearDownOnce;
begin
  FDB := Nil;//inherited TearDownOnce;
end;

procedure TEvsFBMetaTester.DoConnect;
begin
  if FDB.Connection = Nil then
    FDB.Connection := Connect(FDB, stFirebird);
end;

procedure TEvsFBMetaTester.CheckEquals(Expected, Actual :TEvsDataGroup; aMessage :string);
begin
  OnCheckCalled;
  if Expected <> Actual then ;
    FailNotEquals(GetEnumName(TypeInfo(TEvsDataGroup),Integer(Expected)), GetEnumName(TypeInfo(TEvsDataGroup),Integer(Actual)), aMessage, CallerAddr);
end;

{$ENDREGION}

{$REGION ' TFirebirdMetaDataTest '}

procedure TFirebirdMetaDataTest.TestHookUp;
begin
  DoConnect;
  //FDB.Connection := Connect(FDB, stFirebird);
  CheckNotNull(FDB.Connection, Format('Connection to the database %S failed',[FDB.Database]));
end;

procedure TFirebirdMetaDataTest.TestRetrieveExceptions;
begin
  DoConnect;
  FDB.Connection.MetaData.GetExceptions(FDB); //database wide triggers.
  CheckEquals(5, FDB.ExceptionCount, 'Unexpected number of exceptions.');
  CheckEqualText('CUSTOMER_CHECK',   FDB.Exception[0].Name, 'Exception Name does not much');
  CheckEqualText('CUSTOMER_ON_HOLD', FDB.Exception[1].Name, 'Exception Name does not much');
  CheckEqualText('UNKNOWN_EMP_ID',   FDB.Exception[4].Name, 'Exception Name does not much');
end;

procedure TFirebirdMetaDataTest.TestRetrieveTriggers;
var
  vTbl :IEvsTableInfo;
begin
  DoConnect;
  FDB.Connection.MetaData.GetTriggers(FDB); //database wide triggers.
  CheckEquals(0, FDB.TriggerCount, 'Unexpected number of database Triggers found');
  vTbl := GetTable(FDB, 'Customer');
  FDB.Connection.MetaData.GetTriggers(vTbl);
  CheckEquals(1, vTbl.TriggerCount, 'Unexpected number of Triggers for talbe <Customer>');
  CheckEqualText('SET_CUST_NO', vTbl.Trigger[0].Name, 'Invalid trigger name');
  CheckTrue(vTbl.Trigger[0].Active, Format('Trigger %S was not active',[vTbl.Trigger[0].Name]));
end;

procedure TFirebirdMetaDataTest.TestRetrieveFields;
var
  vTbl : IEvsTableInfo;
begin
  DoConnect;
  vTbl := FDB.NewTable('CUSTOMER');
  FDB.Connection.MetaData.GetFields(vTbl);
  CheckEquals(12, vTbl.FieldCount, 'Invalid number of fields');
  CheckEqualText('CUST_NO', vTbl.Field[0].FieldName, 'Invalid field name');
  CheckEqualText('CUSTNO',  vTbl.Field[0].DataTypeName, 'Invalid field data type');
  CheckEqualText('ON_HOLD', vTbl.Field[11].FieldName, 'Invalid field name');
  CheckFalse(vTbl.Field[0].AllowNulls, 'Not null expected for the primary key');
end;

procedure TFirebirdMetaDataTest.TestRetrieveStored;
begin
  DoConnect;
  FDB.Connection.MetaData.GetStored(FDB);
  CheckEquals(12, FDB.ProcedureCount, format('unexpected number of procedures expected <%D> returned <>%D',[10,fdb.ProcedureCount]));
  CheckEqualText('GET_EMP_PROJ',   FDB.StoredProc[00].Name, 'Invalid procedure name at 0');
  CheckEqualText('SUB_TOT_BUDGET', FDB.StoredProc[02].Name, 'Invalid procedure name at 2');
  CheckEqualText('SERVERINFO',     FDB.StoredProc[11].Name, 'Invalid procedure name at 11');
end;

procedure TFirebirdMetaDataTest.TestRetrieveViews;
begin
  DoConnect;
  FDB.Connection.MetaData.GetViews(FDB);
  CheckEquals(01, FDB.ViewCount, 'Unexpected Number of views');
  CheckEqualText('PHONE_LIST', FDB.View[0].Name, 'Invalid View Name');
end;

procedure TFirebirdMetaDataTest.TestRetrieveUDFs;
begin
  DoConnect;
  FDB.Connection.MetaData.GetUDFs(FDB);
  CheckEquals(0, FDB.UdfCount,'Unexpected number of udfs.');
  Fail('I have no udfs installed to test.');
end;

procedure TFirebirdMetaDataTest.TestRetrieveRoles;
begin
  DoConnect;
  FDB.Connection.MetaData.GetRoles(FDB);
  CheckEquals(2,FDB.RoleCount,'Unexpected number of roles');
  CheckEqualText('RDB$Admin', FDB.Role[0].Name, 'Unexpected role name at 0');
  CheckEqualText('Test1',     FDB.Role[1].Name, 'Unexpected role name at 1');
end;

procedure TFirebirdMetaDataTest.TestRetrieveDomains;
begin
  DoConnect;
  FDB.Connection.MetaData.GetDomains(FDB);
  CheckEquals(15, FDB.DomainCount, 'Unexpected number of domains');
  CheckEqualText('AddressLine',FDB.Domain[0].Name,'Invalid Domain name at 0');
  CheckEqualText('Budget',FDB.Domain[1].Name,'Invalid Domain name at 1');
  CheckEqualText('CustNo',FDB.Domain[3].Name,'Invalid Domain name at 3');
  CheckEqualText('Salary',FDB.Domain[14].Name,'Invalid Domain name at 14');
end;

procedure TFirebirdMetaDataTest.TestRetrieveSequences;
begin
  DoConnect;
  FDB.Connection.MetaData.GetSequences(FDB);
  CheckEquals(2,FDB.SequenceCount,'Unexpected number of generators');
  CheckEqualText('Emp_No_Gen',FDB.Sequence[0].Name,'Invalid generator name at 0');
  CheckEqualText('Cust_no_Gen',FDB.Sequence[1].Name,'Invalid generator name at 1');
end;

procedure TFirebirdMetaDataTest.TestRetrieveUsers;
begin
  DoConnect;
  FDB.Connection.MetaData.GetUsers(FDB);
  CheckEquals(3,FDB.UserCount,'Unexpected number of users'); //evosi,testcases,sysdba
end;

procedure TFirebirdMetaDataTest.TestReverse;
begin
  //DoConnect;
  //Fail('No test written');
end;

{$ENDREGION}

Initialization
  SeTMDODataBaseErrorMessages([ShowSQLCode, ShowMDOMessage, ShowSQLMessage]);
  RegisterTest(TFirebirdMetaDataTest.Suite);
end.

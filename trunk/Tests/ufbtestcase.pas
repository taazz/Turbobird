unit uFBTestcase;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, TestFramework, MDO, uEvsDBSchema, uTBFirebird;

type

  { TFirebirdMetaDataTest }

  TEvsFBMetaTester = class(TTestCase)
  protected
    FDB :IEvsDatabaseInfo;
    procedure SetUpOnce; override;
    procedure TearDownOnce; override;
    procedure DoConnect;
  end;

  { TEvsFBMetaTester }
  TFirebirdMetaDataTest= class(TEvsFBMetaTester)
  published
    procedure TestHookUp;
    procedure TestReverseFields;
    procedure TestReverseExceptions;
    procedure TestReverseTriggers;
    procedure TestReverseStored;
    procedure TestReverseViews;
    procedure TestReverseUDFs;
    procedure TestReverseDomains;
    procedure TestReverseSequences;
    procedure TestReverseRoles;
    procedure TestReverseUsers;

    procedure TestReverse;
  end;

implementation
uses
   strutils;

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

//implementation
//
//procedure TFBMetaDataTest.TestHookUp;
//begin
//  Fail('Write your own test');
//  FDB.Connection := Connect(FDB,stFirebird);
//end;
//
//procedure TFBMetaDataTest.SetUp;
//begin
//  FDB := NewDatabase(stFirebird,localhost,'D:\data\firebird\Employee.fdb','TESTCASES','TEST','RDB$ADMIN','');
//end;
//
//procedure TFBMetaDataTest.TearDown;
//begin
//  FDB := Nil;
//end;
//
//initialization
//  RegisterTest(TFBMetaDataTest.Suite);
//end.
//
//
//function NewDB(const aHost, aPort, aDB, aUsr, aPwd, aRole, aCharSet:String):IEvsDatabaseInfo;
//begin
//  Result := TEvsDBInfoFactory.NewDatabase(Nil);
//  Result.Host := aHost + IfThen(aPort<>'','/'+aPort,'');
//  Result.Database := aDB;
//  Result.Credentials.UserName := aUsr;
//  Result.Credentials.Password := aPwd;
//  Result.Credentials.Charset  := aCharSet;
//  Result.Credentials.Role     := aRole;
//end;

{$ENDREGION}

{$REGION ' TFirebirdMetaDataTest '}

procedure TFirebirdMetaDataTest.TestHookUp;
begin
  FDB.Connection := Connect(FDB, stFirebird);
  CheckNotNull(FDB.Connection, format('Connection to the database %S failed',[FDB.Database]));
end;

//procedure TFirebirdMetaDataTest.SetUpOnce;
//begin
//  FDB := NewDatabase(stFirebird, 'localhost', 'D:\Data\Firebird\EMPLOYEE.FDB', 'TESTCASES', 'TEST', 'RDB$ADMIN','');
//end;

//procedure TFirebirdMetaDataTest.TearDownOnce;
//begin
//  FDB := Nil;//inherited TearDownOnce;
//end;
//
//procedure TFirebirdMetaDataTest.SetUp;
//begin //moved to setup once
//  //FDB := NewDB('LocalHost', '', 'D:\data\firebird\employee.fdb', 'TESTCASES', 'TEST', 'RDB$ADMIN', '');
//end;

//procedure TFirebirdMetaDataTest.TearDown;
//begin //moved to TearDownonce
//  //FDB := Nil;
//end;

//procedure TFirebirdMetaDataTest.DoConnect;
//begin
//  if FDB.Connection = Nil then
//    FDB.Connection := Connect(FDB, stFirebird);
//end;

procedure TFirebirdMetaDataTest.TestReverseExceptions;
begin
  DoConnect;
  FDB.Connection.MetaData.GetExceptions(FDB);
end;

procedure TFirebirdMetaDataTest.TestReverseTriggers;
var
  vTbl :IEvsTableInfo;
begin
  DoConnect;
  FDB.Connection.MetaData.GetTriggers(FDB); //database wide triggers.
  CheckEquals(FDB.TriggerCount,0,'Unexpected number of Triggers found');
  vTbl := GetTable(FDB, 'Customer');
  FDB.Connection.MetaData.GetTriggers(vTbl);
  CheckEquals(1, vTbl.TriggerCount, 'Unexpected number of Triggers found for talbe <Customer>');
  CheckEquals('SET_CUST_NO', vTbl.Trigger[0].Name, 'Invalid trigger name');
  CheckTrue(vTbl.Trigger[0].Active, Format('Trigger %S was not active',[vTbl.Trigger[0].Name]));
end;

procedure TFirebirdMetaDataTest.TestReverseFields;
var
  vTbl : IEvsTableInfo;
begin
  DoConnect;
  vTbl := FDB.NewTable('CUSTOMER');
  FDB.Connection.MetaData.GetFields(vTbl);
  CheckEquals(12, vTbl.FieldCount, 'Invalid number of fields');
  CheckEquals('CUST_NO', UpperCase(vTbl.Field[0].FieldName), 'Invalid field name');
  CheckEquals('CUSTNO',  UpperCase(vTbl.Field[0].DataTypeName), 'Invalid field data type');
  CheckEquals(False,  vTbl.Field[0].AllowNulls, 'Not null expected for the primary key');
  CheckEquals('ON_HOLD', UpperCase(vTbl.Field[11].FieldName), 'Invalid field name');
end;

procedure TFirebirdMetaDataTest.TestReverseStored;
begin
  DoConnect;
  FDB.Connection.MetaData.GetStored(FDB);
  CheckEquals(12,fdb.ProcedureCount,format('unexpected number of procedures expected <%D> returned <>%D',[10,fdb.ProcedureCount]));
end;

procedure TFirebirdMetaDataTest.TestReverseViews;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverseUDFs;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverseDomains;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverseSequences;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverseRoles;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverseUsers;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverse;
begin
  Fail('No test written');
end;

{$ENDREGION}

Initialization
  SeTMDODataBaseErrorMessages([ShowSQLCode, ShowMDOMessage, ShowSQLMessage]);
  RegisterTest(TFirebirdMetaDataTest.Suite);
end.

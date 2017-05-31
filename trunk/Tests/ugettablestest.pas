unit uGetTablesTest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, TestRegistry, uTBFirebird, uEvsDBSchema;

type

  { TFirebirdMetaDataTest }

  TFirebirdMetaDataTest= class(TTestCase)
  private
    FDB   :IEvsDatabaseInfo;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure DoConnect;
  published
    procedure TestHookUp;
    procedure TestReverseFields;
    procedure TestReverseTables;
    procedure TestReverseExceptions;
    procedure TestReverseTriggers;
    procedure TestReverseStored;
    procedure TestReverseViews;
    procedure TestReverse;
  end;

implementation
uses
   strutils;

function NewDB(const aHost, aPort, aDB, aUsr, aPwd, aRole, aCharSet:String):IEvsDatabaseInfo;
begin
  Result := TEvsDBInfoFactory.NewDatabase(Nil);
  Result.Host := aHost + IfThen(aPort<>'','/'+aPort,'');
  Result.Database := aDB;
  Result.Credentials.UserName := aUsr;
  Result.Credentials.Password := aPwd;
  Result.Credentials.Charset  := aCharSet;
  Result.Credentials.Role     := aRole;
end;

procedure TFirebirdMetaDataTest.TestHookUp;
begin
  FDB.Connection := Connect(FDB, stFirebird);
  CheckNotNull(FDB.Connection, Format('Connection to the database %S failed',[FDB.Database]));
end;

procedure TFirebirdMetaDataTest.SetUp;
begin
  FDB := NewDB('LocalHost', '', 'D:\data\firebird\employee.fdb', 'TESTCASES', 'TEST', 'RDB$ADMIN', '');
end;

procedure TFirebirdMetaDataTest.TearDown;
begin
  FDB := Nil;
end;

procedure TFirebirdMetaDataTest.DoConnect;
begin
  if FDB.Connection = Nil then
    FDB.Connection := Connect(FDB, stFirebird);
end;

procedure TFirebirdMetaDataTest.TestReverseTables;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverseExceptions;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverseTriggers;
begin
  Fail('No test written');
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
  CheckEquals('Integer',  UpperCase(vTbl.Field[0].DataTypeName), 'Invalid field data type');
  CheckNotEquals(False,  vTbl.Field[0].AllowNulls, 'Not null expected for the primary key');
  CheckEquals('ON_HOLD', UpperCase(vTbl.Field[11].FieldName), 'Invalid field name');
end;

procedure TFirebirdMetaDataTest.TestReverseStored;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverseViews;
begin
  Fail('No test written');
end;

procedure TFirebirdMetaDataTest.TestReverse;
begin
  Fail('No test written');
end;

Initialization
  RegisterTest(TFirebirdMetaDataTest);

end.


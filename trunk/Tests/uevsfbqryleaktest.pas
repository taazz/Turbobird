unit uevsfbqryleaktest;

{$mode objfpc}{$H+}
{$I ..\EVSDEFS.inc}

interface

uses
  Classes, SysUtils, TestFramework, uFBTestcase, uEvsDBSchema, uTBFirebird;

type

  { TFbQryLeakTest }

  TFbQryLeakTest= class(TEvsFBMetaTester)
  published
    Procedure TestConnect;
    Procedure TestDatasetProxy;
    Procedure TestConnectionProxy;
    Procedure TestFieldProxy;
    Procedure TestQuery;
    Procedure TestQueryFields;
  end;

implementation

Procedure TFbQryLeakTest.TestConnect;
var
  vCnn : IEvsConnection;
begin
  vCnn := Connect(FDB, stFirebird);
  CheckNotNull(vCnn);
  vCnn := Nil;
end;

Procedure TFbQryLeakTest.TestDatasetProxy;
var
  vTmp : IEvsDataset;// TEvsMDODatasetProxy
begin
  vTmp := TEvsMDODatasetProxy.Create(Nil, False);
  CheckNotNull(vTmp);
  vTmp := Nil;
end;

Procedure TFbQryLeakTest.TestConnectionProxy; //TEvsMDOConnection
var
  vTmp : IEvsConnection;// TEvsMDODatasetProxy
begin
  vTmp := TEvsMDOConnection.Create(Nil, False);
  CheckNotNull(vTmp);
  vTmp := Nil;
end;

Procedure TFbQryLeakTest.TestFieldProxy;
var
  vTmp : IEvsField;//TEvsMDODatasetProxy
begin
  vTmp := TEvsFieldProxy.Create(Nil, Nil);
  CheckNotNull(vTmp);
  vTmp := Nil;
end;

Procedure TFbQryLeakTest.TestQuery;
var
  vQry   :IEvsDataset;
  vCntr  :Integer;
begin
  DoConnect;
  vQry := FDB.Connection.Query('Select * from RDB$Database');
  CheckNotNull(vQry);
  vQry.First;
  vCntr := 0;
  while not vQry.EOF do begin
    Inc(vCntr);// := vCntr +1;
    vQry.Next;
  end;
  CheckNotEquals(0,vCntr,'No records returned?');
  vQry := nil;
end;

Procedure TFbQryLeakTest.TestQueryFields;
var
  vQry   :IEvsDataset;
  vCntr  :Integer;
  vFld   :IEvsField;
begin
  DoConnect;
  vQry := FDB.Connection.Query('Select * from RDB$Database');
  CheckNotNull(vQry);
  vQry.First;
  vCntr := 0;
  for vCntr := 0 to vQry.FieldCount -1 do begin
    vFld := vQry.Field[vCntr];
    CheckNotNull(vFld);
    CheckNotEquals('', vFld.FieldName, 'Empty field names are not allowed');
  end;
  CheckNotEquals(0, vCntr, 'No records returned?');
  vQry := nil;
end;

initialization
  {$IFDEF MEMORY_TRACE}
  RegisterTest('Memory Tests', TFbQryLeakTest.Suite);
  {$ENDIF}
end.


unit uevsfbqryleaktest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TestFramework, uFBTestcase, uEvsDBSchema;

type

  { TFbQryLeakTest }

  TFbQryLeakTest= class(TEvsFBMetaTester)
  published
    procedure TestConnect;
    procedure TestQuery;
  end;

implementation

procedure TFbQryLeakTest.TestConnect;
var
  vCnn : IEvsConnection;
begin
  vCnn := Connect(FDB, stFirebird);
  CheckNotNull(vCnn);
  vCnn := Nil;
end;

procedure TFbQryLeakTest.TestQuery;
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

initialization
  RegisterTest('Memory Tests', TFbQryLeakTest.Suite);
end.


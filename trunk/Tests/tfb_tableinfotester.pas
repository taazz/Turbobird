unit TFB_TableInfoTester;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TestFramework, uFBTestcase, uEvsDBSchema;

type

  { TFBTableInfoTester }

  TFBTableInfoTester= class(TEvsFBMetaTester)
  published
    procedure TestReverseTables;
    procedure TestCopyTable;
  end;

implementation

procedure TFBTableInfoTester.TestReverseTables;
begin
  DoConnect;// Fail('No test written');
  FDB.ClearTables;
  FDB.Connection.MetaData.GetTables(FDB);
  CheckEquals(10, FDB.TableCount, 'Unexpected number of tables found');
  CheckEquals('COUNTRY', FDB.Table[0].TableName);
  CheckEquals('SALES',FDB.Table[9].TableName);
  FDB.ClearTables;
  FDB.Connection.MetaData.GetTables(FDB, True);
end;

procedure TFBTableInfoTester.TestCopyTable;
var
  vTbl :IEvsTableInfo;
  vTblNo : Integer = 0;
  function DBTable:IEvsTableInfo;
  begin
    Result := FDB.Table[vTblNo];
  end;
  procedure Setup;
  begin
    vTblNo := Random(FDB.TableCount);
    vTbl   := TEvsDBInfoFactory.NewTable(Nil);
  end;

begin
  DoConnect;
  FDB.ClearTables;
  FDB.Connection.MetaData.GetTables(FDB);
  Setup;
  //DBTable.CopyTo(vTbl);
  //CheckEquals(dbTable.TableName, vTbl.TableName, 'CopyTo check failed');
  //CheckEquals(DBTable.Description, vTbl.Description, 'Description copy failed');
  //CheckEquals(DBTable.CharSet, vTbl.CharSet, 'CharSet copy failed');
  //CheckEquals(DBTable.Collation, vTbl.Collation, 'Collation copy failed');
  //CheckEquals(DBTable.FieldCount, vTbl.FieldCount, 'FieldCount copy failed');
  //CheckEquals(DBTable.IndexCount, vTbl.IndexCount, 'IndexCount copy failed');
  //CheckEquals(DBTable.TriggerCount, vTbl.TriggerCount, 'TriggerCount copy failed');
  //CheckEquals(DBTable.Index, vTbl.Index, 'Index copy failed');
  //CheckEquals(DBTable.Field, vTbl.Field, 'Field copy failed');
  //CheckEquals(DBTable.Trigger, vTbl.Trigger, 'Trigger copy failed');
  //CheckEquals(DBTable.SystemTable, vTbl.SystemTable, 'SystemTable copy failed');
  vTbl := Nil; //clear up
  Setup;
  vTbl.CopyFrom(DBTable); //never use copyto directly
  CheckEquals(dbTable.TableName, vTbl.TableName, 'CopyTo check failed');
  CheckEquals(DBTable.Description, vTbl.Description, 'Description copy failed');
  CheckEquals(DBTable.CharSet, vTbl.CharSet, 'CharSet copy failed');
  CheckEquals(DBTable.Collation, vTbl.Collation, 'Collation copy failed');
  //CheckEquals(DBTable.FieldCount, vTbl.FieldCount, 'FieldCount copy failed');
  //CheckEquals(DBTable.IndexCount, vTbl.IndexCount, 'IndexCount copy failed');
  //CheckEquals(DBTable.TriggerCount, vTbl.TriggerCount, 'TriggerCount copy failed');
  //CheckEquals(DBTable.Index, vTbl.Index, 'Index copy failed');
  //CheckEquals(DBTable.Field, vTbl.Field, 'Field copy failed');
  //CheckEquals(DBTable.Trigger, vTbl.Trigger, 'Trigger copy failed');
  CheckEquals(DBTable.SystemTable, vTbl.SystemTable, 'SystemTable copy failed');
end;

initialization
  RegisterTest(TFBTableInfoTester.Suite);

end.


unit uEvsMemLeakTesting;

{$mode objfpc}{$H+}
{$I ..\EVSDEFS.inc}
interface

uses
  Classes, SysUtils, TestFramework, TestFrameworkIfaces, uEvsDBSchema;

type

  { TSchemaLeakTester }
  //This test suite checks the memory leaks only it is used with
  //hepatrc to produce a report that will be used from the leak viewer
  //inside lazarus.
  TSchemaLeakTester= class(TTestCase)
  published
    Procedure TestField;
    Procedure TestFieldList;
    Procedure TestFieldListItems;
    Procedure TestTrigger;
    Procedure TestTriggerList;
    Procedure TestTriggerListItems;
    Procedure TestIndex;
    Procedure TestIndexList;
    procedure TestIndexListItems;
    Procedure TestDomain;
    Procedure TestDomainList;
    Procedure TestDomainListItems;
    Procedure TestSequence;
    Procedure TestSequenceList;
    Procedure TestSequenceListItems;
    Procedure TestUser;
    Procedure TestUserList;
    Procedure TestUserListItems;
    Procedure TestRole;
    Procedure TestRoleList;
    Procedure TestRoleListItems;
    Procedure TestTable;
    Procedure TestTableList;
    Procedure TestTableListItems;
    procedure TestDatabase;
    procedure TestDatabaseList;
    procedure TestDatabaseListItems;
  end;

implementation

Procedure TSchemaLeakTester.TestField;
var
  vFld : IEvsFieldInfo;
begin
  vFld := TEvsDBInfoFactory.NewField(nil);
  CheckNotNull(vFld);
  vFld := nil;
end;

Procedure TSchemaLeakTester.TestFieldList;
var
  vTmp :IEvsFieldList;
begin
  vTmp := TEvsDBInfoFactory.NewFieldList(nil);
  CheckNotNull(vTmp);
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestFieldListItems;
var
  vTmp :IEvsFieldList;
begin
  vTmp := TEvsDBInfoFactory.NewFieldList(nil);
  CheckNotNull(vTmp);
  vTmp.New;
  vTmp.New;
  vTmp.New;
  CheckEquals(3,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestTrigger;
var
  vTmp : IEvsTriggerInfo;
begin
  vTmp := TEvsDBInfoFactory.NewTrigger(nil);
  CheckNotNull(vTmp);
  vTmp := Nil;
end;

Procedure TSchemaLeakTester.TestTriggerList;
var
  vTmp :IEvsTriggerList;
begin
  vTmp := TEvsDBInfoFactory.NewTriggerList(nil);
  CheckNotNull(vTmp);
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestTriggerListItems;
var
  vTmp :IEvsTriggerList;
begin
  vTmp := TEvsDBInfoFactory.NewTriggerList(nil);
  CheckNotNull(vTmp);
  vTmp.New;
  vTmp.New;
  vTmp.New;
  CheckEquals(3, vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestDomain;
var
  vDm : IEvsDomainInfo;
begin
  vDm := TEvsDBInfoFactory.NewDomain(nil);
  CheckNotNull(vDm);
end;

Procedure TSchemaLeakTester.TestDomainList;
var
  vTmp :IEvsDomainList;
begin
  vTmp := TEvsDBInfoFactory.NewDomainList(nil);
  CheckNotNull(vTmp);
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestDomainListItems;
var
  vTmp :IEvsDomainList;
begin
  vTmp := TEvsDBInfoFactory.NewDomainList(nil);
  CheckNotNull(vTmp);
  vTmp.New;
  vTmp.New;
  vTmp.New;
  CheckEquals(3,vTmp.Count);
  vTmp.Clear;
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestSequence;
var
  vSeq :IEvsSequenceInfo;
begin
  vSeq := TEvsDBInfoFactory.NewSequence(nil);
  CheckNotNull(vSeq);
end;

Procedure TSchemaLeakTester.TestSequenceList;
var
  vTmp :IEvsSequenceList;
begin
  vTmp := TEvsDBInfoFactory.NewSequenceList(nil);
  CheckNotNull(vTmp);
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestSequenceListItems;
var
  vTmp :IEvsSequenceList;
begin
  vTmp := TEvsDBInfoFactory.NewSequenceList(nil);
  CheckNotNull(vTmp);
  vTmp.New;
  vTmp.New;
  vTmp.New;
  CheckEquals(3,vTmp.Count);
  vTmp.Clear;
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestIndex;
var
  vTmp :IEvsIndexInfo;
  vTmp2:TObject;
begin
  vTmp := TEvsDBInfoFactory.NewIndex(Nil);
  CheckNotNull(vTmp);
  vTmp2 := vTmp.ObjectRef;
  vTmp := Nil;
end;

Procedure TSchemaLeakTester.TestIndexList;
var
  vTmp :IEvsIndexList;
begin
  vTmp := TEvsDBInfoFactory.NewIndexList(nil);
  CheckNotNull(vTmp);
  CheckEquals(0, vTmp.Count);
  vTmp := nil;
end;

procedure TSchemaLeakTester.TestIndexListItems;
var
  vTmp :IEvsIndexList;
begin
  vTmp := TEvsDBInfoFactory.NewIndexList(nil);
  CheckNotNull(vTmp);
  vTmp.New;
  vTmp.New;
  vTmp.New;
  CheckEquals(3,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestUser;
var
  vTmp :IEvsUserInfo;
begin
  vTmp := TEvsDBInfoFactory.NewUser(nil);
  CheckNotNull(vTmp);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestUserList;
var
  vTmp :IEvsUserList;
begin
  vTmp := TEvsDBInfoFactory.NewUserList(nil);
  CheckNotNull(vTmp);
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestUserListItems;
var
  vTmp :IEvsUserList;
begin
  vTmp := TEvsDBInfoFactory.NewUserList(nil);
  CheckNotNull(vTmp);
  vTmp.New;
  vTmp.New;
  vTmp.New;
  CheckEquals(3,vTmp.Count);
  vTmp.Clear;
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestRole;
var
  vTmp :IEvsRoleInfo;
begin
  vTmp := TEvsDBInfoFactory.NewRole(nil);
  CheckNotNull(vTmp);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestRoleList;
var
  vTmp :IEvsRoleList;
begin
  vTmp := TEvsDBInfoFactory.NewRoleList(nil);
  CheckNotNull(vTmp);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestRoleListItems;
var
  vTmp :IEvsRoleList;
begin
  vTmp := TEvsDBInfoFactory.NewRoleList(nil);
  CheckNotNull(vTmp);
  vTmp.New;
  vTmp.New;
  vTmp.New;
  CheckEquals(3,vTmp.Count);
  vTmp.Clear;
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestTable;
var
  vTmp :IEvsTableInfo;
begin
  vTmp := TEvsDBInfoFactory.NewTable(Nil);
  CheckNotNull(vTmp);
  vTmp:=Nil;
end;

Procedure TSchemaLeakTester.TestTableList;
var
  vTmp :IEvsTableList;
begin
  vTmp := TEvsDBInfoFactory.NewTableList(nil);
  CheckNotNull(vTmp);
  vTmp := nil;
end;

Procedure TSchemaLeakTester.TestTableListItems;
var
  vTmp :IEvsRoleList;
begin
  vTmp := TEvsDBInfoFactory.NewRoleList(nil);
  CheckNotNull(vTmp);
  vTmp.New;
  vTmp.New;
  vTmp.New;
  CheckEquals(3,vTmp.Count);
  vTmp.Clear;
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

procedure TSchemaLeakTester.TestDatabase;
var
  vDB:IEvsDatabaseInfo;
begin
  vDB := TEvsDBInfoFactory.NewDatabase(nil);
  CheckNotNull(vDB);
  vDB := nil;
end;

procedure TSchemaLeakTester.TestDatabaseList;
var
  vDB:IEvsDatabaseList;
begin
  vDB := TEvsDBInfoFactory.NewDatabaseList(nil);
  CheckNotNull(vDB);
  vDB := nil;
end;

procedure TSchemaLeakTester.TestDatabaseListItems;
var
  vTmp :IEvsDatabaseList;
begin
  vTmp := TEvsDBInfoFactory.NewDatabaseList(nil);
  CheckNotNull(vTmp);
  vTmp.New;
  vTmp.New;
  vTmp.New;
  CheckEquals(3,vTmp.Count);
  vTmp.Clear;
  CheckEquals(0,vTmp.Count);
  vTmp := nil;
end;

initialization
  {$IFDEF MEMORY_TRACE}
  RegisterTest('Memory Tests', TSchemaLeakTester.Suite);
  {$ENDIF}
end.


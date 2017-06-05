unit uFBViewTestCase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TestFramework, uFBTestcase, uEvsDBSchema;

type

  { TFBViewTest }

  TFBViewTest= class(TEvsFBMetaTester)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Retrieval;
    procedure Copy;
  end;

implementation

procedure TFBViewTest.Retrieval;
begin
  CheckEquals(1, FDB.ViewCount,'Unexpected view count');
  CheckEquals(6, FDB.View[0].FieldCount, 'Unexpected number of fields');
  CheckEquals('EMP_NO', FDB.View[0].Field[0].FieldName, 'Unexpected number of fields');
  CheckEquals('PHONE_LIST', FDB.View[0].Name, 'view name mismatch');
end;

procedure TFBViewTest.Copy;
var
  vView:IEvsViewInfo;
begin
  vView:=TEvsDBInfoFactory.NewView(Nil);
  vView.CopyFrom(FDB.View[0]);
  CheckEquals(FDB.View[0].Name,        vView.Name,        'Name check failed');
  CheckEquals(FDB.View[0].Description, vView.Description, 'Description check failed');
  CheckEquals(FDB.View[0].SQL,         vView.SQL,         'Sql check failed');
  CheckEquals(FDB.View[0].FieldCount,  vView.FieldCount,  'Field Count check failed');

  Check(vView.FieldList.EqualsTo(FDB.View[0].FieldList),'Internal field list check failed');
  Check(vView.EqualsTo(FDB.View[0]),'Internal check failed');
end;

procedure TFBViewTest.SetUp;
begin
  DoConnect;
  FDB.Connection.MetaData.GetViews(FDB);
end;

procedure TFBViewTest.TearDown;
begin
  FDB.ClearViews;
end;

initialization
  RegisterTest('Schema Suite', TFBViewTest.Suite);
end.


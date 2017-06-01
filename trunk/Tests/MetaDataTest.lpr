program MetaDataTest;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GUITestRunner, TFB_TableInfoTester, uFBTestcase, mdolaz, ufptestHelper, uEvsFields;

{$R *.res}

begin
  Application.Initialize;
  RunRegisteredTests;
end.


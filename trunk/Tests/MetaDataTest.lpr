program MetaDataTest;

{$mode objfpc}{$H+}
{$I ..\EvsDefs.inc}

uses
  {$IFDEF MEMORY_TRACE}
  //FastMM4,
  heaptrc, sysutils,
  {$ENDIF}
  Interfaces, Forms, GUITestRunner, TFB_TableInfoTester, uFBTestcase, mdolaz, ufptestHelper, uEvsFields, uFBViewTestCase, uEvsMemLeakTesting,
  uEvsIntfObjects, uevsfbqryleaktest;

{$R *.res}

begin
  {$IFDEF MEMORY_TRACE}
    if FileExists('MemTests.trc') then DeleteFile('MemTests.trc');
    SetHeapTraceOutput('MemTests.trc');
  {$ENDIF}
  Application.Initialize;
  RunRegisteredTests;
end.


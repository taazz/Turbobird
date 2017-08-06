program MetaDataTest;

{$mode objfpc}{$H+}
{$I ..\EvsDefs.inc}

uses
{$IFDEF MEMORY_TRACE}
  {$IFDEF FASTMM}
  FastMM4,
  {$ELSE}
  heaptrc,
  {$ENDIF}
  sysutils,
{$ENDIF}
  Interfaces, Forms, GUITestRunner, TFB_TableInfoTester, uFBTestcase, mdolaz, ufptestHelper, uEvsFields,
  uEvsFieldInfoTest, uFBViewTestCase, uEvsMemLeakTesting, uEvsIntfObjects, uevsfbqryleaktest, TCheckTests;

{$R *.res}
{$IFDEF MEMORY_TRACE}
var
  vTrc :String;
{$ENDIF}
begin
  {$IFDEF MEMORY_TRACE}
    vTrc := ChangeFileExt(Application.ExeName,'.trc');
    if FileExists(vTrc) then DeleteFile(vTrc);
    SetHeapTraceOutput(vTrc);
  {$ENDIF}
  Application.Initialize;
  RunRegisteredTests;
end.


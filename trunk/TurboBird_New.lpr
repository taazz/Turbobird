program TurboBird_New;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, virtualtreeview_package, mdolaz, uEvsMain, uDMMain, uEvsNoteBook, utbDBRegistry, uTbToArray, uEvsDBSchema, uEvsGenIntf, uEvsIntfObjects,
  uEvsSqlEditor, uEvsTabNotebook, uGridResultFrame, uGeneratorsFrame, uBaseFrame, uEvsBackupRestore;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.ExceptionDialog := aedOkMessageBox;
  Application.CreateForm(TdmMain, dmMain);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.


program MetaDataTest;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, mdolaz, GuiTestRunner, uGetTablesTest;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.


unit uTableIndicesFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, VirtualTrees;

type

  { TFrame1 }

  TFrame1 = class(TFrame)
    vstFields :TVirtualStringTree;
  private
    { private declarations }
  public
    { public declarations }
  end;

implementation

{$R *.lfm}

end.


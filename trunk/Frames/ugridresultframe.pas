unit uGridResultFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, FileUtil, Forms, Controls, DBGrids, VirtualTrees, vte_treedata, uEvsDBSchema, uTBFirebird;

type

  { TGridResultFrame }

  TGridResultFrame = class(TFrame)
    vstResult :TVirtualStringTree;
  private
    FDataset :IEvsDataset;
    procedure SetDataset(aValue :IEvsDataset);
    { private declarations }
    procedure RefreshTree;
    procedure SetupTree;
  public
    { public declarations }
    property Dataset :IEvsDataset read FDataset write SetDataset;
  end;

implementation

{$R *.lfm}

{ TGridResultFrame }

procedure TGridResultFrame.SetDataset(aValue :IEvsDataset);
begin
  //dbgResultSet.DataSource;crap crap, crap, crap on a cracker
  if FDataset=aValue then Exit;
  FDataset := aValue;
  {$MESSAGE WARN 'Do not use rtl classes extend the interface unit to support dataset correctly.'}
  //if FDataset.ObjectRef is TDataSet then dsResultSet.DataSet := TDataSet(FDataset.ObjectRef) else dsResultSet.DataSet := nil;
  SetupTree;
end;

procedure TGridResultFrame.RefreshTree;
begin
  vstResult.RootNodeCount := FDataset.RowCount;
end;

procedure TGridResultFrame.SetupTree;
var
  vCntr:Integer;
  vClm : TVirtualTreeColumn;
begin
  vstResult.BeginUpdate;
  try
    vstResult.RootNodeCount := 0;
    vstResult.Header.Columns.Clear;
    for vCntr := 0 to FDataset.FieldCount -1 do begin
      vClm := vstResult.Header.Columns.Add;
      vClm.Text  := FDataset.Field[vCntr].FieldName;
      vClm.Width := FDataset.Field[vCntr].Length;
    end;
  finally
    vstResult.EndUpdate;
  end;
end;

end.


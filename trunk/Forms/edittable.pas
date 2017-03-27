unit EditTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, sqldb, IBConnection, FileUtil, LResources, Forms,
  Controls, Graphics, Dialogs, ExtCtrls, DbCtrls, DBGrids, StdCtrls, ComCtrls,
  Buttons, MDODatabase, MDOQuery, main, uTBTypes;

type
  {$WARNING no data shown. functionality is broken}
  { TfmEditTable }

  TfmEditTable = class(TForm)
    bbSave: TBitBtn;
    Datasource1: TDatasource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Label1: TLabel;
    laPos: TLabel;
    sqEditTable :TMDOQuery;
    Panel1: TPanel;
    sqEditTableOLD :TSQLQuery;
    procedure bbSaveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure sqEditTableAfterScroll(DataSet: TDataSet);
  private
    FConn : TMDODataBase;
    FTrans: TMDOTransaction;
    { private declarations }
  public
    { public declarations }
    Rec: TDBInfo;
    procedure Init(dbIndex: Integer; ATableName: string);
  end; 

var
  fmEditTable: TfmEditTable;

implementation
{$R *.lfm}
{ TfmEditTable }

procedure TfmEditTable.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  sqEditTable.Close;
  CloseAction:= caFree;
  FConn:= nil;
  FTrans:= nil;
end;

procedure TfmEditTable.FormCreate(Sender: TObject);
begin
  FConn:= nil;
  FTrans:= nil;
end;

procedure TfmEditTable.bbSaveClick(Sender: TObject);
begin
  try
    if sqEditTable.State in [dsInsert, dsEdit] then
      sqEditTable.Post;
    if sqEditTable.Active then
      sqEditTable.ApplyUpdates;
    if FTrans.Active then
      FTrans.CommitRetaining;
  except
    on E: Exception do
    begin
      ShowMessage(e.Message);
    end;
  end;
end;

procedure TfmEditTable.sqEditTableAfterScroll(DataSet: TDataSet);
begin
  laPos.Caption:= IntToStr(sqEditTable.RecNo) + ' of ' + IntToStr(sqEditTable.RecordCount);
end;

procedure TfmEditTable.Init(dbIndex: Integer; ATableName: string);
var
  FieldsList: TStringList;
  i: integer;
  PKField: TField;
begin
  sqEditTable.Close;
  if FConn = nil then
  begin
    FConn:= Rec.Conn;
    if not(FConn.Connected) then
      FConn.Open;
    FTrans:= Rec.Trans;
    sqEditTable.DataBase:= FConn;
  end;
  sqEditTable.SQL.Text:= 'select * from ' + ATableName;
  sqEditTable.Open; // need to have open query in order to access fields below

  bbSave.Visible:= true;
  {
  // ASSUME there's a generator/trigger
  //todo: verify this assumption using code to check this out. Then also modify
  //insert statement to leave out the relevant fields if not present
  FieldsList:= TStringList.Create;
  try
    if fmmain.GetPrimaryKeyFields(dbIndex, ATableName, FieldsList) then
    begin
      bbSave.Visible:= true;
      for i:= 0 to FieldsList.Count -1 do
      begin
        try
          sqEditTable.FieldByName(FieldsList[i]).Required:=false;
        except
          // field does not exist => error
          bbSave.Visible:=false;
          break;
        end;
      end;
    end
    else
    begin
      bbSave.Visible:= false;
    end;
  finally
    FieldsList.Free;
  end;
  }
  if not(bbSave.Visible) then
    ShowMessage('Primary key is not found for this table. It can not be edited.');
end;

//initialization
//  {$I edittable.lrs}

end.


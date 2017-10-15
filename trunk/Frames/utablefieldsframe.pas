unit uTableFieldsFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ActnList, VirtualTrees, uEvsDBSchema;

const
  ClmFieldName = 1;
  ClmDataType  = 2;
  ClmDataSize  = 3;
  ClmDataKey   = 4;

type

  { TTableFieldsFrame }

  TTableFieldsFrame = class(TFrame)
    actInsertField :TAction;
    actDeleteField :TAction;
    ActionList1    :TActionList;
    vstFields      :TVirtualStringTree;
    procedure actDeleteFieldExecute(Sender :TObject);
    procedure actDeleteFieldUpdate(Sender :TObject);
    procedure actInsertFieldExecute(Sender :TObject);
    procedure actInsertFieldUpdate(Sender :TObject);
    procedure vstFieldsGetText(Sender :TBaseVirtualTree; Node :PVirtualNode; Column :TColumnIndex; TextType :TVSTTextType; var CellText :String);
    procedure vstFieldsInitNode(Sender :TBaseVirtualTree; ParentNode, Node :PVirtualNode; var InitialStates :TVirtualNodeInitStates);
  private
    { private declarations }
    FTable       :IEvsTableInfo;
    FEditNewNode :LongBool;
    procedure SetTable(aValue :IEvsTableInfo);
  protected
    function ColumnType(const aColumn:TColumnIndex) :Byte;
    function FocusColumn(const aColumnID:Word):TColumnIndex;
    function ColumnIndex(const aColumnID:Word):TColumnIndex;
    procedure DoEdit(Data: PtrInt);
  public
    { public declarations }
    constructor Create(aOwner :TComponent); override;
    property Table:IEvsTableInfo read FTable write SetTable;
  end;

implementation

{$R *.lfm}

{ TTableFieldsFrame }

procedure TTableFieldsFrame.vstFieldsGetText(Sender :TBaseVirtualTree; Node :PVirtualNode;
                                             Column :TColumnIndex; TextType :TVSTTextType;
                                             var CellText :String);
begin
  if TextType = ttNormal then
    case ColumnType(Column) of
      ClmFieldName :CellText := FTable.Field[Node^.Index].FieldName;
      ClmDataType  :CellText := FTable.Field[Node^.Index].DataTypeName;
      ClmDataSize  :CellText := IntToStr(FTable.Field[Node^.Index].FieldSize);
      ClmDataKey   :CellText := BoolToStr(FTable.Field[Node^.Index].IsPrimary,'P','');
    end;
end;

procedure TTableFieldsFrame.vstFieldsInitNode(Sender :TBaseVirtualTree; ParentNode, Node :PVirtualNode; var InitialStates :TVirtualNodeInitStates);
var
  vEdt:LongBool;
begin
  vEdt := LongBool(InterLockedExchange(LongInt(FEditNewNode),LongInt(False)));//what a wanderful waste.
  if FEditNewNode then begin
    FEditNewNode := False;
    Application.QueueAsyncCall(@DoEdit, PtrInt(Node));
  end;
end;

procedure TTableFieldsFrame.actInsertFieldUpdate(Sender :TObject);
begin
  actInsertField.Enabled := Assigned(FTable);
end;

procedure TTableFieldsFrame.actInsertFieldExecute(Sender :TObject);
var
  vFld : IEvsFieldInfo;
begin
  vFld := FTable.NewField;
  vFld.FieldName := FTable.UniqueFieldName('','');
  FEditNewNode   := True;
  vstFields.RootNodeCount := vstFields.RootNodeCount+1;
end;

procedure TTableFieldsFrame.actDeleteFieldUpdate(Sender :TObject);
begin
  actDeleteField.Enabled := vstFields.FocusedNode <> nil;
end;

procedure TTableFieldsFrame.actDeleteFieldExecute(Sender :TObject);
var
  vFld :IEvsFieldInfo;
begin
  vFld := FTable.Field[vstFields.FocusedNode^.Index];
  vstFields.DeleteNode(vstFields.FocusedNode);
  FTable.Remove(vFld);
  vFld := nil;
end;

procedure TTableFieldsFrame.SetTable(aValue :IEvsTableInfo);
var
  vReInit:Boolean;
begin
  if FTable=aValue then Exit;
  FTable:=aValue;
  vReInit := vstFields.RootNodeCount>0; //instead of deleting the existing nodes and recreating them just reinitialize the existing ones.
  if Assigned(FTable) then begin
    vstFields.RootNodeCount := FTable.FieldCount;
    if vReInit then vstFields.ReinitNode(vstFields.RootNode, True);
  end else vstFields.RootNodeCount := 0;
end;

function TTableFieldsFrame.ColumnType(const aColumn :TColumnIndex) :Byte;
begin
  Result := vstFields.Header.Columns[aColumn].Tag;
end;

function TTableFieldsFrame.FocusColumn(const aColumnID :Word) :TColumnIndex;
begin
  Result := ColumnIndex(aColumnID);
  vstFields.FocusedColumn := Result;
end;

function TTableFieldsFrame.ColumnIndex(const aColumnID :Word) :TColumnIndex;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to vstFields.Header.Columns.Count -1 do begin
    if vstFields.Header.Columns[vCntr].Tag = aColumnID then Exit(vCntr);//vstFields.Header.Columns[vCntr].Index);// index the same as vCntr.
  end;
end;

procedure TTableFieldsFrame.DoEdit(Data :PtrInt);
var
  vNode : PVirtualNode;
begin
  vNode := PVirtualNode(Data);
  vstFields.EditNode(vNode, FocusColumn(ClmFieldName));
end;

constructor TTableFieldsFrame.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  FEditNewNode := False;
end;

end.


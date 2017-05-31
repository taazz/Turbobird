unit uobjInsp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RTTIGrids, RTTICtrls, Forms, Controls, Graphics, Dialogs, StdCtrls,
  vte_rttigrid, PropEdits, ObjectInspector;

type

  { TFrmObjectInspector }

  TFrmObjectInspector = class(TForm)
    ComboBox1 :TComboBox;
    TIPropertyGrid1 :TTIPropertyGrid;
    VirtualRttiGrid1 :TVirtualRttiGrid;
    procedure ComboBox1Change(Sender :TObject);
    procedure TIPropertyGrid1EditorFilter(Sender :TObject; aEditor :TPropertyEditor; var aShow :boolean);
  private
    { private declarations }
    FObjects    :TStringList;
    FRootObject :TComponent;
    function GetComponent(aIndex :Integer) :TComponent;
    function GetObject :TComponent;
    procedure SetObject(aValue :TComponent);
    procedure SetObjects(aValue :TStringList);
    procedure AppendComponents;
  public
    { public declarations }
    Procedure AddComponent(const aComponent:TComponent);
    Property Objects :TStringList read FObjects write SetObjects;
    Property Component[aIndex:Integer]:TComponent read GetComponent;
    Property RootObject:TComponent read GetObject write SetObject;
  end;

var
  FrmObjectInspector : TFrmObjectInspector;

implementation

{$R *.lfm}

{ TFrmObjectInspector }

procedure TFrmObjectInspector.SetObjects(aValue :TStringList);
begin
  if FObjects = aValue then Exit;
  FObjects.Assign(aValue);
end;

procedure TFrmObjectInspector.AppendComponents;
var
  vCntr :Integer;
begin
  ComboBox1.Items.BeginUpdate;
  try
    ComboBox1.Items.Clear;
    ComboBox1.Items.AddObject(FRootObject.Name, FRootObject);
    for vCntr := 0 to FRootObject.ComponentCount -1 do
      ComboBox1.Items.AddObject(FRootObject.Components[vCntr].Name, FRootObject.Components[vCntr]);
    ComboBox1.ItemIndex := ComboBox1.Items.IndexOfObject(FRootObject);
  finally
    ComboBox1.Items.EndUpdate;
  end;
end;

procedure TFrmObjectInspector.ComboBox1Change(Sender :TObject);
begin
  //VirtualRttiGrid1.SetObject(TPersistent(ComboBox1.Items.Objects[ComboBox1.ItemIndex]));
  TIPropertyGrid1.TIObject := TPersistent(ComboBox1.Items.Objects[ComboBox1.ItemIndex]);
end;

procedure TFrmObjectInspector.TIPropertyGrid1EditorFilter(Sender :TObject; aEditor :TPropertyEditor; var aShow :boolean);
begin
  //
end;

function TFrmObjectInspector.GetComponent(aIndex :Integer) :TComponent;
begin
  Result := TComponent(FObjects.Objects[aIndex]);// AddObject(,);
end;

function TFrmObjectInspector.GetObject :TComponent;
begin
  Result := FRootObject;
end;

procedure TFrmObjectInspector.SetObject(aValue :TComponent);
begin
  if FRootObject <> aValue then begin
    FRootObject := aValue;
    VirtualRttiGrid1.SetObject(FRootObject);
    TIPropertyGrid1.TIObject := FRootObject;
    //TIPropertyGrid1.;
    AppendComponents;
  end;
end;

Procedure TFrmObjectInspector.AddComponent(const aComponent :TComponent);
begin
  FObjects.AddObject(aComponent.Name, aComponent);
end;

end.


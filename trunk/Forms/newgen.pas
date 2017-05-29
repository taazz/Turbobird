unit NewGen;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, FileUtil, LResources, Forms, Controls,
  Graphics, Dialogs, StdCtrls, Buttons, Spin, utbcommon, uTBTypes, uEvsDBSchema, uEvsWideString;

type

  { TfmNewGen }

  TfmNewGen = class(TForm)
    bbCreateGen :TBitBtn;
    BitBtn1     :TBitBtn;
    cbTables    :TComboBox;
    cbFields    :TComboBox;
    cxTrigger   :TCheckBox;
    edGenName   :TEdit;
    gbTrigger   :TGroupBox;
    Label1      :TLabel;
    Label2      :TLabel;
    Label3      :TLabel;
    Label4      :TLabel;
    SpinEdit1   :TSpinEdit;
    procedure bbCreateGenClick(Sender :TObject);
    procedure cbTablesChange  (Sender :TObject);
    procedure cxTriggerChange (Sender :TObject);
  private
    { private declarations }
    FGenerator    :IEvsGeneratorInfo;

    FDBIndex      :Integer;
    FIBConnection :TIBConnection;
    FSQLTrans     :TSQLTransaction;
    function GetFieldName :string;
    function GetGenName :String;
    function GetInTrigger :Boolean;
    function GetStartValue :Int64;
    function GetTableName :string;
    procedure SetFieldName(aValue :string);
    procedure SetGenerator(aValue :IEvsGeneratorInfo);
    procedure SetGenName(aValue :String);
    procedure SetInTrigger(aValue :Boolean);
    procedure SetStartValue(aValue :Int64);
    procedure SetTableName(aValue :string);
    procedure ToScreen;
    procedure FromScreen;
    procedure PopulateFields(const aTableName:String);
  public
    { public declarations }
    procedure Init(dbIndex    :Integer);overload;DEPRECATED 'pass the IEvsGeneratorInfo to init';
    procedure Init(aGenerator :IEvsGeneratorInfo);overload;
    property Generator :IEvsGeneratorInfo read FGenerator    write SetGenerator;
    property GeneratorName       :String  read GetGenName    write SetGenName;
    property GeneratorStartValue :Int64   read GetStartValue write SetStartValue;
    property UseInTableTrigger   :Boolean read GetInTrigger  write SetInTrigger;
    property TableName           :string  read GetTableName  write SetTableName;
    property FieldName           :string  read GetFieldName  write SetFieldName;
  end;

var
  fmNewGen: TfmNewGen;

implementation
{$R *.lfm}
{ TfmNewGen }

uses main, SysTables;

procedure TfmNewGen.bbCreateGenClick(Sender: TObject);
var
  List: TStringList;
  Valid: Boolean;
begin
  if Trim(edGenName.Text) <> '' then
  begin
    Valid:= True;
    List:= TStringList.Create;
    try
      List.Add('create generator ' + edGenName.Text + ';');
      if cxTrigger.Checked then
      begin
        Valid:= False;
        if (cbTables.ItemIndex = -1) or (cbFields.ItemIndex = -1) then
          MessageDlg('You should select a table and a field', mtError, [mbOk], 0)
        else
        if Trim(edGenName.Text) = '' then
          MessageDlg('You should enter generator name', mtError, [mbOK], 0)
        else
        begin
          List.Add('CREATE TRIGGER ' + Trim(edGenName.Text) + ' FOR ' + cbTables.Text);
          List.Add('ACTIVE BEFORE INSERT POSITION 0 ');
          List.Add('AS BEGIN ');
          List.Add('IF (NEW.' + cbFields.Text + ' IS NULL OR NEW.' + cbFields.Text + ' = 0) THEN ');
          List.Add('  NEW.' + cbFields.Text + ' = GEN_ID(' + edGenName.Text + ', 1);');
          List.Add('END;');
          Valid:= True;
        end;

      end;
      fmMain.ShowCompleteQueryWindow(FDBIndex, 'Create Generator: ' + edGenName.Text, List.Text);
      Close;
    finally
      List.Free;
    end;
  end
  else
    MessageDlg('You should write Generator name', mtError, [mbOK], 0);
end;

procedure TfmNewGen.cbTablesChange(Sender: TObject);
//var
//  FType: string;
begin
  if cbTables.ItemIndex > -1 then begin
    dmSysTables.GetTableFields(FDBIndex, cbTables.Text, cFldSubType + ' = 0 and '+cFldType + ' in (7,8,16)', cbFields.Items);
    //fmMain.GetFields(FDBIndex, cbTables.Text, nil);
    //cbFields.Clear;
    //while not fmMain.qryMain.EOF do
    //begin
      //FType := GetFBTypeName(fmMain.qryMain.FieldByName(cfldType).AsInteger,
      //                      fmMain.qryMain.FieldByName(cFldSubType).AsInteger,
      //                      fmMain.qryMain.FieldByName(cFldLength).AsInteger,
      //                      fmMain.qryMain.FieldByName(cFldPrecision).AsInteger,
      //                      fmMain.qryMain.FieldByName(cFldScale).AsInteger);
    //  // Only show field name if they are numeric/suitable for generators
    //  // In practice, integer type fields are probably always used
    //  if (FType = 'INTEGER') or (FType = 'BIGINT') or (FType = 'SMALLINT') then
    //    cbFields.Items.Add(Trim(fmMain.SQLQuery1.FieldByName('Field_Name').AsString));
    //  fmMain.SQLQuery1.Next;
    //end;
    //fmMain.SQLQuery1.Close;

  end;
end;

procedure TfmNewGen.cxTriggerChange(Sender: TObject);
begin
  gbTrigger.Enabled := cxTrigger.Checked;
end;

procedure TfmNewGen.SetGenerator(aValue :IEvsGeneratorInfo);
begin
  if FGenerator=aValue then Exit;
  FGenerator:=aValue;
end;

function TfmNewGen.GetGenName :String;
begin
  Result := edGenName.Text;
end;

function TfmNewGen.GetFieldName :string;
begin
  Result := cbFields.Text;
end;

function TfmNewGen.GetInTrigger :Boolean;
begin
  Result := cxTrigger.Checked;
end;

function TfmNewGen.GetStartValue :Int64;
begin
  Result := SpinEdit1.Value; // GeneratorStartValue;
end;

function TfmNewGen.GetTableName :string;
begin
  Result := cbTables.Text;
end;

procedure TfmNewGen.SetFieldName(aValue :string);
begin
  cbFields.Text := aValue;
end;

procedure TfmNewGen.SetGenName(aValue :String);
begin
  edGenName.Text := aValue;
end;

procedure TfmNewGen.SetInTrigger(aValue :Boolean);
begin
  cxTrigger.Checked := aValue;
end;

procedure TfmNewGen.SetStartValue(aValue :Int64);
begin
  SpinEdit1.Value := aValue;
end;

procedure TfmNewGen.SetTableName(aValue :string);
begin
  cbTables.Text := aValue;
end;

procedure TfmNewGen.ToScreen;
var
  vDB:IEvsDatabaseInfo;
  vCntr :Integer;
begin
  Name := FGenerator.GeneratorName;
  GeneratorStartValue := FGenerator.CurrentValue;
  vDB := GetDatabase(FGenerator);
  if Assigned(vDB) then begin
    cbTables.Items.BeginUpdate;
    try
      cbTables.Items.Clear;
      for vCntr := 0 to vDB.TableCount -1 do begin
        cbTables.Items.Add{Object}(vDB.Table[vCntr].TableName{, vDB.Table[vCntr]});
      end;
    finally
      cbTables.Items.EndUpdate;
    end;

  end;
end;

procedure TfmNewGen.FromScreen;
begin
  FGenerator.GeneratorName := GeneratorName;
  FGenerator.CurrentValue  := GeneratorStartValue;
end;

procedure TfmNewGen.PopulateFields(const aTableName :String);
var
  vDB  :IEvsDatabaseInfo;
  vTbl :IEvsTableInfo;
  function FindTable(const aName:String):IEvsTableInfo;
  var
    vCntr :Integer;
  begin
    Result := Nil;
    for vCntr := 0 to vDB.TableCount -1 do begin
      if uEvsWideString.WideCompareText(aTableName,vDB.Table[vcntr].TableName) = 0 then Exit(vDB.Table[vCntr]);
    end;
  end;
var
  vCntr :Integer;
begin
  vDB := GetDatabase(FGenerator);
  if Assigned(vDB) then begin
    vTbl := FindTable(aTableName);
    if Assigned(vTbl) then begin
      for vCntr := 0 to vTbl.FieldCount -1 do begin
        cbFields.Items.Add(vTbl.Field[vCntr].FieldName);
      end;
    end;
  end;
end;

procedure TfmNewGen.Init(dbIndex: Integer); {$MESSAGE WARN 'deprecated'}
var
  TableNames :string;
  Count      :Integer;
begin
  //raise NotImplementedException; {$MESSAGE WARN 'Needs to be removed'}
  FDBIndex   := dbIndex;
  //TableNames := dmSysTables.GetDBObjectNames(fmMain.RegisteredDatabases[dbIndex], otTables, Count);

  fmNewGen.cbTables.Items.CommaText:= TableNames;

  cxTrigger.Checked:= False;
end;

procedure TfmNewGen.Init(aGenerator :IEvsGeneratorInfo);
begin
  FGenerator := aGenerator;
  ToScreen;
end;

//initialization
//  {$I newgen.lrs}

end.


unit uMain;

{$mode objfpc}{$H+}

interface
{$Include ../EvsDefs.inc}

uses
  Classes, SysUtils, IBConnection, sqldb, FileUtil, SynEdit, SynHighlighterSQL, SynMemo, Forms, Controls, Graphics, Dialogs, ActnList,
  StdCtrls, ComCtrls, Reg, uEvsDBSchema, uTBFirebird, uobjInsp;
type

  { TEvsObj }
  IEvsTesting = interface(IInterface) ['{58145698-3FD0-457F-B023-F7163B32F885}']
    procedure Test;{$IFDEF WINDOWS} stdcall {$Else} cdecl {$ENDIF};
  end;

  TEvsObj=class(TInterfacedObject, IEvsTesting)
  public
    function _Release :longint; extdecl;
    destructor Destroy; override;
    procedure Test; extdecl; //{$IFDEF WINDOWS} STDCALL {$Else} cdecl {$ENDIF};
  end;

  { TEvsTest2 }

  TEvsTest2 = class(TEvsDBInfo)
  public
    Destructor Destroy; override;
  end;

  { TForm1 }

  TMetaMethod = procedure (const aDB:IEvsDatabaseInfo) of object;stdcall;

  TForm1 = class(TForm)
    actDBReverse  :TAction;
    actDBRegister :TAction;
    actDBConnect  :TAction;
    actDBPrint    :TAction;
    actSQLExecute :TAction;
    ActionList1   :TActionList;
    Button1       :TButton;
    Button2       :TButton;
    btnDBPrint    :TButton;
    btnSQLExecute :TButton;
    IBConnection1 :TIBConnection;
    Memo1         :TMemo;
    PageControl1  :TPageControl;
    SQLQuery1     :TSQLQuery;
    SynEdit1      :TSynEdit;
    SynMemo1      :TSynMemo;
    SynSQLSyn1    :TSynSQLSyn;
    TabSheet1     :TTabSheet;
    TabSheet2     :TTabSheet;
    TabSheet3     :TTabSheet;
    ToolBar1      :TToolBar;
    procedure actDBPrintExecute   (Sender :TObject);
    Procedure actDBRegisterExecute(Sender :TObject);
    procedure actDBReverseExecute (Sender :TObject);
    procedure actSQLExecuteExecute(Sender :TObject);
    procedure actSQLExecuteUpdate (Sender :TObject);
    procedure PageControl1Change  (Sender :TObject);
  private
    { private declarations }
    FDBIntf :IEvsDatabaseInfo;
    FDBCNN  :IEvsConnection;
    FDBMEta :IEvsMetaData;
  protected
    Procedure LoadMetadata;
    procedure PopulateMetaData;//populate the highlighter with the known metadata.
    Function DoMetadataLoad(const aMethod :TMetaMethod):Boolean;
    function FormatFieldValueDef(const aField :IEvsField; const aDefault:string):String;
    procedure PopulateObjectInspector;
  public
    { public declarations }
    constructor Create(TheOwner :TComponent); override;
    Destructor Destroy; override;

    Procedure DoWrite(constref aStr:String);
    Procedure Print  (constref aDB        :IEvsDatabaseInfo;  const aIndent :string='');
    Procedure Print  (constref aTable     :IEvsTableInfo;     const aIndent :String='');
    Procedure Print  (constref aField     :IEvsFieldInfo;     const aIndent :String='');
    Procedure Print  (constref aIndex     :IEvsIndexInfo;     const aIndent :String='');
    Procedure Print  (constref aTrigger   :IEvsTriggerInfo;   const aIndent :String='');
    Procedure Print  (constref aSequence  :IEvsSequenceInfo;  const aIndent :string='');
    Procedure Print  (constref aException :IEvsExceptionInfo; const aIndent :string='');
    Procedure Print  (constref aView      :IEvsViewInfo;      const aIndent :string='');
    Procedure Print  (constref aStored    :IEvsStoredInfo;    const aIndent :string='');
    Procedure Print  (constref aDomain    :IEvsDomainInfo;    const aIndent :string='');
    Procedure Print  (constref aUdf       :IEvsUDFInfo;       const aIndent :string='');
    Procedure Print  (constref aRole      :IEvsRoleInfo;      const aIndent :string='');
    procedure Print  (constref aDataset   :IEvsDataset;       const aIndent :String='');
  end;

var
  Form1 : TForm1;

implementation

{$R *.lfm}
uses uTBTypes;
const
  cTab = '  ';

{ TEvsTest2 }

Destructor TEvsTest2.Destroy;
begin
  inherited Destroy;
end;

{ TEvsObj }

function TEvsObj._Release :longint; {$IFDEF WINDOWS} STDCALL {$Else} cdecl {$ENDIF};
begin
  Result := inherited _Release;
end;

destructor TEvsObj.Destroy;
begin
  inherited Destroy;
end;

procedure TEvsObj.Test; {$IFDEF WINDOWS} STDCALL {$Else} cdecl {$ENDIF};
begin
  //nada
end;

{ TForm1 }

Procedure TForm1.actDBRegisterExecute(Sender :TObject);
var
  vFrm  : TfmReg;
  vCntr : Integer;
begin
  vFrm := TfmReg.Create(Nil);
  try
    vFrm.NewReg := True;
    if vFrm.ShowModal = mrOK then begin
      FDBIntf := NewDatabase(stFirebird, vFrm.Host, vFrm.DatabaseName, vFrm.UserName, vFrm.Password, vFrm.Role, vFrm.Charset);
      FDBIntf.ServerKind := stFirebird;
      FDBCNN  := uEvsDBSchema.Connect(FDBIntf, stFirebird);
    end;
  finally
    vFrm.Free;
  end;
end;

procedure TForm1.actDBPrintExecute(Sender :TObject);
begin
  Print(FDBIntf);
end;

procedure TForm1.actDBReverseExecute(Sender :TObject);
begin
  LoadMetadata;
end;

procedure TForm1.actSQLExecuteExecute(Sender :TObject);
var
  vSQL  :string;
  vStr, vLine :string;
  vDts  :IEvsDataset;
  vCntr :Integer;
begin
  if SynEdit1.SelAvail then vSQL := SynEdit1.SelText
  else vSQL := SynEdit1.Text;
  vDts := FDBCNN.Query(vSQL);
  vDts.First;
  Print(vDts);
end;

procedure TForm1.actSQLExecuteUpdate(Sender :TObject);
begin
  actSQLExecute.Enabled := (PageControl1.ActivePage = TabSheet2) and Assigned(FDBCNN);
end;

procedure TForm1.PageControl1Change(Sender :TObject);
begin
  btnSQLExecute.Visible := PageControl1.ActivePage = TabSheet2;
end;

Procedure TForm1.LoadMetadata;
var
  vCntr :Integer;
begin
  if Assigned(FDBCNN) then begin
    FDBCNN.MetaData.GetTables(FDBIntf);
    for vCntr := 0 to FDBIntf.TableCount -1 do begin
      FDBCNN.MetaData.GetFields  (FDBIntf.Table[vCntr]);
      FDBCNN.MetaData.GetIndices (FDBIntf.Table[vCntr]);
      FDBCNN.MetaData.GetTriggers(FDBIntf.Table[vCntr]);
    end;
    FDBCNN.MetaData.GetTriggers(FDBIntf);
    //if not DoMetadataLoad(@FDBCNN.MetaData.GetTriggers) then
    //  FDBIntf.ClearTriggers;
    FDBCNN.MetaData.GetStored(FDBIntf);
    //DoMetadataLoad(@FDBCNN.MetaData.GetStored);     // (FDBIntf);
    if not DoMetadataLoad(@FDBCNN.MetaData.GetSequences) then begin
      //FDBIntf.ClearSequences;
      DoWrite('GetSequences Failed');
    end;
    if not DoMetadataLoad(@FDBCNN.MetaData.GetViews) then begin
      //FDBIntf.ClearViews;
      DoWrite('GetViews Failed');
    end;      // (FDBIntf);
    //if not DoMetadataLoad(@FDBCNN.MetaData.GetSequences)then begin
    //  FDBIntf.ClearSequences;
    //  DoWrite('GetSequences Failed');
    //end;  // (FDBIntf);
    if not DoMetadataLoad(@FDBCNN.MetaData.GetExceptions) then begin
      //FDBIntf.ClearExceptions;
      DoWrite('GetExceptions Failed');
    end; // (FDBIntf);
    if not DoMetadataLoad(@FDBCNN.MetaData.GetUDFs) then begin
      //FDBIntf.ClearUDFs;
      DoWrite('GetUDFs Failed');
    end;       // (FDBIntf);
    if not DoMetadataLoad(@FDBCNN.MetaData.GetUsers) then begin
      FDBIntf.ClearUsers;
      DoWrite('GetUsers Failed');
    end;      // (FDBIntf);
    if not DoMetadataLoad(@FDBCNN.MetaData.GetRoles) then begin
      //FDBIntf.ClearRoles;
      DoWrite('GetRoles Failed');
    end;      // (FDBIntf);
    if not DoMetadataLoad(@FDBCNN.MetaData.GetDomains) then begin
      //FDBIntf.ClearDomains;
      DoWrite('GetDomains Failed');
    end;    // (FDBIntf);
  end;
  PopulateMetaData;
end;

procedure TForm1.PopulateMetaData;
var
  vCntr :Integer;
  vName :String;
begin
  SynEdit1.BeginUpdate;
  try
    SynEdit1.Highlighter := Nil;
    SynSQLSyn1.TableNames.Clear;
    for vCntr := 0 to FDBIntf.TableCount -1 do begin
      vName := FDBIntf.Table[vCntr].TableName;
      SynSQLSyn1.TableNames.Add(FDBIntf.Table[vCntr].TableName);
    end;
    for vCntr := 0 to FDBIntf.ViewCount -1 do begin
      SynSQLSyn1.TableNames.Add(FDBIntf.View[vCntr].Name);
    end;
  finally
    SynEdit1.EndUpdate;
    SynEdit1.Highlighter := SynSQLSyn1;
    vName := SynSQLSyn1.TableNames.Text;
  end;
end;

Function TForm1.DoMetadataLoad(const aMethod :TMetaMethod) :Boolean;
begin
  Result := False ;
  try
    aMethod(FDBIntf);
    Result := True;
  except
    on E:ETBNotImplemented do begin
      Result := False;
    end else raise;
  end;
end;

function TForm1.FormatFieldValueDef(const aField :IEvsField; const aDefault :string) :String;
begin
  //check that the size returned on floating point and bcd fields that can be
  //used or not ee a size of 8 for doubles is not useable.
  Result := aDefault;
  if not aField.IsNull then begin
    if aField.IsNumeric then begin
      if aField.Precision = 0 then begin
        WriteStr(Result, aField.AsInt32:aField.Length);
      end else begin
        WriteStr(Result, aField.AsDouble:aField.Length:aField.Precision);
      end;
    end else WriteStr(Result, aField.AsString:aField.Length);
  end;
end;

procedure TForm1.PopulateObjectInspector;
begin
  FrmObjectInspector.RootObject := Self;
end;

constructor TForm1.Create(TheOwner :TComponent);
begin
  inherited Create(TheOwner);
  FrmObjectInspector             := TFrmObjectInspector.Create(Application);
  FrmObjectInspector.FormStyle   := fsNormal;
  FrmObjectInspector.PopupMode   := pmExplicit;
  FrmObjectInspector.PopupParent := Self;
  FrmObjectInspector.RootObject  := Self;
  FrmObjectInspector.Show;
end;

Destructor TForm1.Destroy;
begin
  FDBIntf := Nil;
  FDBCNN  := Nil;
  FDBMEta := Nil;
  inherited Destroy;
end;

Procedure TForm1.DoWrite(constref aStr :String);
begin
  Memo1.Lines.Add(aStr);
end;

Procedure TForm1.Print(constref aTable :IEvsTableInfo; const aIndent :String);
var
  vLine : String;
  vCntr : Integer;
  vTot  : Integer;
begin
  WriteStr(vLine, aIndent, aTable.TableName, '(',aTable.CharSet, ':', aTable.Collation,')');
  DoWrite(vLine);
  DoWrite(aIndent+'  Fields');
  vTot := aTable.FieldCount;
  for vCntr := 0 to vTot -1 do begin
    Print(aTable.Field[vCntr], aIndent + cTab);
  end;
  DoWrite(aIndent+'  Indices');
  vTot := aTable.IndexCount;
  for vCntr := 0 to vTot -1 do begin
    Print(aTable.Index[vCntr], aIndent + cTab);
  end;
  DoWrite(aIndent+'  Triggers');
  vTot := aTable.TriggerCount;
  for vCntr := 0 to vTot -1 do begin
    Print(aTable.Trigger[vCntr], aIndent + cTab);
  end;
end;

Procedure TForm1.Print(constref aField :IEvsFieldInfo; const aIndent :String);
var
  vLine :String;
begin
  WriteStr(vLine, aIndent, cTab, trim(aField.FieldName), ' ', trim(aField.DataTypeName),'(',aField.FieldSize, ' , ',aField.FieldScale,')', ';charset ',
           trim(aField.Charset), '; collation ', trim(aField.Collation));
  DoWrite(vLine);
end;

Procedure TForm1.Print(constref aIndex :IEvsIndexInfo; const aIndent :String);
var
  vLine : String;
  vTot  : Integer;
  vCntr : Integer;
begin
  WriteStr(vLine, aIndent, cTab, Trim(aIndex.IndexName), ' ', aIndex.Order, '(',aIndex.FieldCount, ')');
  DoWrite(vLine);
  vTot := aIndex.FieldCount;
  for vCntr := 0 to vTot -1 do begin
    Print(aIndex.Field[vCntr], aIndent + cTab);
  end;
end;

Procedure TForm1.Print(constref aTrigger :IEvsTriggerInfo; const aIndent :String);
const
  cTrType : Array[TEvsTriggerType] of string = ('Before', 'After', 'Database Wide') ;
  function EventsToString(aEvent:TEvsTriggerEvents):string;
  begin
    Result:='';
    if teInsert in aEvent then Result := 'teInsert or ';
    if teUpdate in aEvent then Result := Result +'teUpdate or ';
    if teDelete in aEvent then Result := Result +'teDelete or ';
    if Length(Result)>0 then SetLength(Result,Length(Result)-3);
  end;
var
  vLine : String;
  vTot  : Integer;
  vCntr : Integer;
begin
  WriteStr(vLine, aIndent, cTab, aTrigger.Name, cTrType[aTrigger.TriggerType], ' ', EventsToString(aTrigger.Event), '(', aTrigger.SQL, ')');
  DoWrite(vLine);
end;

Procedure TForm1.Print(constref aSequence :IEvsSequenceInfo; const aIndent :string);
var
  vLine : String;
begin
  WriteStr(vLine, aIndent, aSequence.GeneratorName);
  DoWrite(vLine);
end;

Procedure TForm1.Print(constref aException :IEvsExceptionInfo; const aIndent :string);
var
  vLine : String;
begin
  WriteStr(vLine, aIndent, aException.Name, aException.Message);
  DoWrite(vLine);
end;

Procedure TForm1.Print(constref aDB :IEvsDatabaseInfo; const aIndent :string);
var
  vLine :String;
  vCntr :Integer;
begin
  WriteStr(vLine, aIndent, aDB.Database, aDB.DefaultCharset, aDB.PageSize,
                 ' Procedures : ', aDB.ProcedureCount,
                 ' Tables : '    , aDB.TableCount,
                 ' Views : '     , aDB.ViewCount,
                 ' Sequences : ' , aDB.SequenceCount,
                 ' Triggers : '  , aDB.TriggerCount,
                 ' Exceptions :' , aDB.ExceptionCount
          );

  DoWrite (vLine);
  WriteStr(vLine, 'Tables : ', aDB.TableCount);           //1
  DoWrite (vLine); vCntr := Length(vLine);
  FillChar(vLine[1], vCntr, '-');
  DoWrite (vLine);
    for vCntr := 0 to aDB.TableCount -1 do begin
    Print(aDB.Table[vCntr], cTab);
  end;

    WriteStr(vLine, 'Triggers : ', aDB.TriggerCount);       //2
  DoWrite(vLine);
  FillChar(vLine[1],Length(vLine) + 1, '-');
  DoWrite(vLine);
  for vCntr := 0 to aDB.TriggerCount -1 do begin
    Print(aDB.Trigger[vCntr], cTab);
  end;

  WriteStr(vLine, 'Exceptions : ', aDB.ExceptionCount);   //3
  DoWrite(vLine);
  FillChar(vLine[1],Length(vLine) + 1, '-');
  DoWrite(vLine);
  for vCntr := 0 to aDB.ExceptionCount -1 do begin
    Print(aDB.Exception[vCntr], cTab);
  end;

  WriteStr(vLine, 'Views : ', aDB.ViewCount);             //4
  DoWrite(vLine);
  FillChar(vLine[1],Length(vLine) + 1, '-');
  DoWrite(vLine);
  for vCntr := 0 to aDB.ViewCount -1 do begin
    Print(aDB.View[vCntr], cTab);
  end;

  WriteStr(vLine, 'Procedures : ', aDB.ProcedureCount);   //5
  DoWrite(vLine);
  FillChar(vLine[1],Length(vLine) + 1, '-');
  DoWrite(vLine);
  for vCntr := 0 to aDB.ProcedureCount -1 do begin
    Print(aDB.StoredProc[vCntr], cTab);
  end;

  WriteStr(vLine, 'Sequences : ', aDB.SequenceCount);     //6
  DoWrite(vLine);
  FillChar(vLine[1],Length(vLine) + 1, '-');
  DoWrite(vLine);
  for vCntr := 0 to aDB.SequenceCount -1 do begin
    Print(aDB.Sequence[vCntr], cTab);
  end;

  WriteStr(vLine, 'Domains : ', aDB.DomainCount);         //7
  DoWrite(vLine);
  FillChar(vLine[1],Length(vLine) + 1, '-');
  DoWrite(vLine);
  for vCntr := 0 to aDB.DomainCount -1 do begin
    Print(aDB.Domain[vCntr], cTab);
  end;

  WriteStr(vLine, 'User Functions : ', aDB.UDFCount);     //8
  DoWrite(vLine);
  FillChar(vLine[1], Length(vLine) + 1, '-');
  DoWrite(vLine);
  for vCntr := 0 to aDB.UdfCount -1 do begin
    Print(aDB.UDF[vCntr], cTab);
  end;

  WriteStr(vLine, 'Roles : ', aDB.RoleCount);             //9
  DoWrite(vLine);
  FillChar(vLine[1], Length(vLine) + 1, '-');
  DoWrite(vLine);
  for vCntr := 0 to aDB.RoleCount -1 do begin
    Print(aDB.Role[vCntr], cTab);
  end;
end;

Procedure TForm1.Print(constref aView :IEvsViewInfo; const aIndent :string);
var
  vStrList :TStringList;
  vLine    :String;
begin
  vStrList:= TStringList.Create;
  try
    vStrList.Text := aView.SQL;
    DoWrite(aIndent + aView.Name);
    for vLine in vStrList do
      DoWrite(aIndent+cTab+cTab+vLine);
  finally
    vStrList.Free;
  end;
end;

Procedure TForm1.Print(constref aStored :IEvsStoredInfo; const aIndent :string);
var
  vStrList :TStringList;
  vLine    :String;
begin
  vStrList := TStringList.Create;
  try
    vStrList.Text := aStored.SQL;
    DoWrite(aIndent + aStored.ProcedureName);
    for vLine in vStrList do
      DoWrite(aIndent+cTab+cTab+vLine);
  finally
    vStrList.Free;
  end;
end;

Procedure TForm1.Print(constref aDomain :IEvsDomainInfo; const aIndent :string);
var
  vLine    :String;
begin
  WriteStr(vLine, aDomain.Name, ',', aDomain.Datatype, ',', aDomain.CharSet, ',', aDomain.Collation, ',', aDomain.SQL);
  DoWrite(aIndent + vLine);
end;

Procedure TForm1.Print(constref aUdf :IEvsUDFInfo; const aIndent :string);
var
  vLine    :String;
begin
  WriteStr(vLine, aUdf.Name);
  DoWrite(aIndent + vLine);
end;

Procedure TForm1.Print(constref aRole :IEvsRoleInfo; const aIndent :string);
var
  vLine    :String;
begin
  WriteStr(vLine, aRole.Name);
  DoWrite(aIndent + vLine);
end;

procedure TForm1.Print(constref aDataset :IEvsDataset; const aIndent :String);
var
  vLine :String;
  vStr  :String;
  vCntr :Integer;
begin
  VLine := ''; vStr :='';
  for vCntr := 0 to aDataset.FieldCount -1 do begin;
    WriteStr(vStr, aDataset.Field[vCntr].FieldName:-aDataset.Field[vCntr].Length);//, FormatFieldValueDef(aDataset.Field[vCntr], '');
    VLine := VLine + vStr + ' '; vStr := '';
  end;
  SynMemo1.Lines.Add(aIndent + vLine);
  SetLength(vStr,Length(vLine));
  FillChar(vStr[1],Length(vLine),'-');
  SynMemo1.Lines.Add(aIndent + vStr);
  vLine := ''; vStr:='';
  While Not aDataset.EOF do begin
    for vCntr := 0 to aDataset.FieldCount -1 do begin;
      vStr  := FormatFieldValueDef(aDataset.Field[vCntr], '');
      vLine := vLine + vStr {FormatFieldValueDef(aDataset.Field[vCntr], '')} + ' ';
    end;
    SynMemo1.Lines.Add(aIndent + vLine);
    vLine := '';
    aDataset.Next;
  end;
end;

end.


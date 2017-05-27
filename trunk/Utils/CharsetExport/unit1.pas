unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn, IBDatabase, IBCustomDataSet, MDODatabase, MDOCustomDataSet;//, uCharSets;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1 :TButton;
    FileNameEdit1 :TFileNameEdit;
    Label1 :TLabel;
    Label2 :TLabel;
    MDODatabase1 :TMDODatabase;
    MDODataSet1 :TMDODataSet;
    MDOTransaction1 :TMDOTransaction;
    OpenDialog1 :TOpenDialog;
    procedure Button1Click(Sender :TObject);
  private
    { private declarations }
  public
    { public declarations }
    constructor Create(aOwner :TComponent); override;
    procedure Connect;
    procedure ExportArrays(const aFileName:String);
    //function GetConst(const aList:TStringList):string;
    function GetFunctions(const aList:TStringList):string;
  end;

var
  Form1 : TForm1;

implementation

{$R *.lfm}
type

  { TStreamHelper }

  TStreamHelper = class helper for TStream
    procedure StringWrite(const aString:String);overload;
  end;

{ TStreamHelper }

procedure TStreamHelper.StringWrite(const aString :String);
begin
  WriteBuffer(aString[1], Length(aString));
end;

{ TForm1 }

procedure TForm1.Button1Click(Sender :TObject);
begin
  Screen.Cursor := crSQLWait;
  try
    Connect;
    ExportArrays(FileNameEdit1.Text);
  finally
    Screen.Cursor := crDefault;
  end;
end;

constructor TForm1.Create(aOwner :TComponent);
begin
  inherited Create(aOwner);
  // the database provided is a firebird2.5 database it will not work with fb3
  // without backup and restore you can use ANY database it is provided as cortesy only
  MDODatabase1.DatabaseName := IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName))+'test.fdb';
  FileNameEdit1.Text := IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName))+'uCharSets.txt';
end;

procedure TForm1.Connect;
begin
  mdoDatabase1.Connected := True;
  mdoDataSet1.Active := False;
  mdoDataSet1.Active := True;
  mdoDataSet1.Last;//load everything.
  mdoDataSet1.First;
end;

procedure TForm1.ExportArrays(const aFileName :String);
var
  vLastCS   :String ='';
  vCharSets :TStringList =nil;
  vTmp      :TStringList;
  vStrm     :TFileStream;
  vCntr     :Integer;
  vChars    :String='';
  vCntr2    :Integer;
  vFnc      :String;
  procedure Cleanup;
  var
    vCntr:integer;
  begin
    for vCntr := 0 to vcharSets.Count -1 do
      vCharSets.Objects[vCntr].Free;
  end;

begin
  Connect;//connect to the db and retrieve the supported character sets.
  vcharSets := TStringList.Create;
  try
    vFnc := 'Function SupportedCollations(const aCharset:String):TStringArray;'+LineEnding
           +'begin'+LineEnding;
    vChars := 'Function SupportedCharacterSets : TStringArray;'+LineEnding
             +'begin'+LineEnding;
    vCntr := 0;
    while not mdoDataSet1.EOF do begin
      if CompareText(vLastCS, Trim(mdoDataSet1.Fields[1].AsString)) <> 0 then begin
        vTmp := TStringList.Create;
        vLastCS := Trim(mdoDataSet1.Fields[1].AsString);
        vChars := vChars + Format('  Result[%3D] := %S;'+LineEnding, [vCntr, QuotedStr(vLastCS)]);
        inc(vCntr);
        vCharSets.AddObject(Trim(mdoDataSet1.Fields[1].AsString), vTmp);
        vFnc := vFnc + Format('  if CompareText(aCharset,''%S'') = 0 then ' + LineEnding
                             +'    Result := cs%0:S_Collations;'+LineEnding
                             , [Trim(mdoDataSet1.Fields[1].AsString)]);
      end;
      vTmp.Add(Trim(mdoDataSet1.Fields[3].AsString));
      mdoDataSet1.Next;
    end;
    vChars := vChars + 'end;' + LineEnding + LineEnding;
    vStrm := TFileStream.Create(aFileName, fmCreate);
    try
      vStrm.StringWrite('Unit '+ExtractFileNameOnly(aFileName)+';'+LineEnding);
      vStrm.StringWrite('Interface '+LineEnding);
      vStrm.StringWrite('uses'+ LineEnding+'  uTBTypes, SysUtils;'+LineEnding);
      vFnc := vFnc + 'end;' + LineEnding;
      vStrm.StringWrite('Function SupportedCollations(const aCharset:String):TStringArray;' + LineEnding);
      vStrm.StringWrite('Function SupportedCharacterSets:TStringArray;' + LineEnding + LineEnding);
      vStrm.StringWrite('Implementation' + LineEnding + LineEnding);
      vStrm.StringWrite(vChars);
      vStrm.StringWrite(GetFunctions(vCharSets));
      vStrm.StringWrite(vFnc + LineEnding);
      vStrm.StringWrite('end.' + LineEnding);
    finally
      vStrm.Free;
    end;
  finally
    mdoDataSet1.Active := False;
    Cleanup;
    vcharSets.Free;
  end;
end;

//function TForm1.GetConst(const aList :TStringList) :string;
//var
//  vCntr  :Integer;
//  vTmp   :TStringList;
//  vCntr2 :Integer;
//begin
//  Result := '';
//  for vCntr := 0 to aList.Count -1 do begin
//    vTmp   := TStringList(aList.Objects[vCntr]);
//    Result := Result + '  '+aList[vCntr]+'_Collations : Array[1..'+IntToStr(vTmp.Count)+'] of string = (';
//    for vCntr2 := 0 to vTmp.Count -1 do begin
//      Result := Result + LineEnding+'              ' + QuotedStr(vTmp[vCntr2])+',';
//    end;
//    SetLength(Result, Length(Result)-1);
//    Result := Result + LineEnding+'                );'+LineEnding;
//  end;
//end;

function TForm1.GetFunctions(const aList :TStringList) :string;
var
  vCntr  :Integer;
  vTmp   :TStringList;
  vCntr2 :Integer;
begin
  Result := '';
  for vCntr := 0 to aList.Count -1 do begin
    vTmp   := TStringList(aList.Objects[vCntr]);
    Result := Result + 'function cs'+aList[vCntr]+'_Collations :TStringArray;inline;'+LineEnding+'begin'+LineEnding+
                       '  SetLength(Result,'+IntToStr(vTmp.Count)+');';
    for vCntr2 := 0 to vTmp.Count -1 do begin
      Result := Result + LineEnding+'  Result['+inttostr(vCntr2)+'] := ' + QuotedStr(vTmp[vCntr2])+';';
    end;
    Result := Result+LineEnding+'end;'+LineEnding+LineEnding;
  end;
end;

end.


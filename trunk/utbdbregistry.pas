{ Registered Database manager and data types.

}
{$DEFINE EVS_INTF}
unit utbDBRegistry;
{$mode objfpc}{$H+}
{$Include EvsDefs.inc}
interface

uses
  Classes, SysUtils, uTBTypes, utbcommon, utbConfig, uTBFirebird, MDODatabase, sqldb, syncobjs,
  uEvsDBSchema, uEvsWideString, uEvsGenIntf, uEvsIntfObjects;
type

  EDBRegistry = class(ETBException);
  //TEvsBackupRestoreOperation
  //TStream
  { TEVSLockableObject }

  TEvsStreamWriter = class(TWriter)

  end;

  TEVSLockableObject = class
  private
    FLock:TSynchroObject;
  protected
    procedure InitLock;
  public
    constructor Create;virtual;//override;
    destructor Destroy;override;
    procedure Lock;
    procedure UnLock;
  end;
  TDBEnumerator = class;
  { TDBRegistry }
  // manage the list of known database registrations in memory.
  TDBRegistry = class(TInterfacedPersistent, IEvsObservable, IEvsObjectRef)
  private
    class var FInstance :TObject;
    class var FInstCntr :Integer;
    //FEndianSwap  :Boolean;
    FDBList      :IEvsDatabaseList;
    FKnownHosts  :TEvsWideStringList;
    FUpdateCount :Integer;
    FObservers   :TEvsObserverList;
    //List management
    Function GetCount :Integer;
    function GetDBInfo(aIndex :Integer) :IEvsDatabaseInfo;
    function GetKnowHostCount :Integer;
    function GetKnownHost(aIndex :Integer) :Widestring;
    Procedure SetCapacity(aNewCapacity:Integer);

    Procedure CheckIndex(aIndex:Integer);inline;
    //persisting routines.
    Procedure SaveDBInfo(const aDBRec:TDBDetails; const aStream :TStream);virtual;experimental;//unimplemented;
    Procedure SaveDBInfo(const aDB:IEvsDatabaseInfo; const aStream:TStream);virtual;experimental;//unimplemented;
    Procedure LoadDBInfo(var aDBRec :TDBDetails; const aStream :TStream; aID :Word); virtual; experimental;// unimplemented;
    procedure LoadDBInfo(const aDB:IEvsDatabaseInfo; const aStream:TStream);virtual;experimental;
    procedure SetDBInfo(Index :Integer; aValue :IEvsDatabaseInfo);
  protected
    Procedure CleanupData;
  public
    Class procedure Error(const aMsg: string; aData: array of const);
    Class Function IsValidRegistryFile(const aFileName:String):Boolean;
    Constructor Create;
    Destructor Destroy; override;

    procedure BeginUpdate;
    procedure EndUpdate;
    procedure CancelUpdate;
    //IEVSObservable
    procedure AddObserver(Observer:IEvsObserver);                            extdecl;
    procedure DeleteObserver(Observer:IEvsObserver);                         extdecl;
    procedure ClearObservers;                                                extdecl;

    procedure Notify(const Action: TEVSGenAction; const aSubject:IEvsObjectRef; const aData:NativeUInt);extdecl;
    //IEvsCopyable;
    function CopyFrom(const aSource  :IEvsCopyable) :Integer; extdecl;
    function CopyTo  (const aDest    :IEvsCopyable) :Integer; extdecl;
    function EqualsTo(const aCompare :IEvsCopyable) :Boolean; extdecl;
    //IEvsOBjectRef
    Function ObjectRef:TObject; extdecl;

    Function IndexOf(const aDatabaseName:string):Integer;
    Function IndexOf(const aDBInfo:IEvsDatabaseInfo):Integer;
    Procedure SaveTo    (const aStream:TStream); virtual;unimplemented;
    Procedure SaveTo    (const aFileName:string);virtual;
    Procedure LoadFrom  (const aStream:TStream); virtual;experimental;
    Procedure LoadFrom  (const aFileName:string);virtual;
    Procedure Delete(aIndex:Integer);overload;EXPERIMENTAL;
    Function NewDatabase :IEvsDatabaseInfo;overload;
    Procedure RemoveDatabase(aDB:IEvsDatabaseInfo);
    function GetEnumerator : TDBEnumerator;
    procedure GetKnownServer(const aList:TStrings);
    function GetKnownServers:TStringArray;

    Procedure Append(aValue:IEvsDatabaseInfo);overload;
    Property Count                        :Integer          read GetCount;
    property Database     [Index:Integer] :IEvsDatabaseInfo read GetDBInfo         write SetDBInfo;default;
    property KnownHost    [Index:Integer] :Widestring       read GetKnownHost;
    Property KnownHostCount :Integer read GetKnowHostCount;
  end;

  { TDBEnumerator }

  TDBEnumerator = class(TObject)
  private
    FObj     :TDBRegistry;
    FCurrent :Integer;
    function GetCurrent :IEvsDatabaseInfo;
  public
    constructor Create(aList: TDBRegistry);
    function MoveNext: Boolean;
    property Current: IEvsDatabaseInfo read GetCurrent;
  end;

//function SaveRegistrations(var aDBArray :TDBInfoArray; const aFilename :string = ''):Boolean;
//function LoadRegistrations(var aDBArray :TDBInfoArray; const aFilename :string = ''):Boolean;
function DBRegistry:TDBRegistry;

resourcestring
  sListCapacity    = 'Capacity (%d) requirements not met.';//Minimum (%d) maximum (%d);
  rsotUsers        = 'Users';
  rsotExceptions   = 'Exceptions';
  rsotRoles        = 'Roles';
  rsotDomains      = 'Domains';
  rsotSystemTables = 'System Tables';
  rsotFunctions    = 'Functions';
  rsotStoredProced = 'Stored Procedures';
  rsotViews        = 'Views';
  rsotTriggers     = 'Triggers';
  rsotGenerators   = 'Generators';
  rsotTables       = 'Tables';
  rsotQueryWindow  = 'Query Window';

implementation

type
  TSign = array[0..3]of Byte;

const
  cHdrID   :Word  = $0201;//endian check. little endian =$102 big endian =201;
  cSign    :TSign = ($00, $45, $56, $73);
  cCharSet :Byte  = ord('A'); //ascii character set. the existing records use shortstrings.

  cDBInfoID :Word = $0EB0;
  cDBInfoEnd:Word = $B00E;
var
  vDBRegistry :TDBRegistry;

{$REGION ' Legacy '}
//procedure Sort(var aDBArray:Array of TDBInfo);
//var
//  vTempRec  : TDBDetails;
//  vDone     : Boolean;
//  vCntr     : Integer;
//  vIndex    : Integer;
//begin
//  raise NotImplementedException;
//  repeat
//    vDone:= True;
//    for vCntr:= low(aDBArray) to High(aDBArray) - 1 do
//    //with fmMain do
//      if aDBArray[vCntr].RegRec.LastOpened < aDBArray[vCntr + 1].RegRec.LastOpened then begin
//        vDone:= False;
//        vTempRec:= aDBArray[vCntr].OrigRegRec;
//        aDBArray[vCntr].OrigRegRec:= aDBArray[vCntr + 1].OrigRegRec;
//        aDBArray[vCntr].RegRec:= aDBArray[vCntr + 1].RegRec;
//        aDBArray[vCntr + 1].OrigRegRec:= vTempRec;
//        aDBArray[vCntr + 1].RegRec:= vTempRec;
//
//        vIndex:= aDBArray[vCntr].Index;
//        aDBArray[vCntr].Index := aDBArray[vCntr + 1].Index;
//        aDBArray[vCntr + 1].Index:= vIndex;
//      end;
//  until vDone;
//end;

//function SaveRegistrations(var aDBArray :TDBInfoArray; const aFilename :string) :Boolean;
//var
//  vFile    : file of TDBDetails;
//  vFileName: string;
//  vCntr    : Integer;
//  {$IFDEF EVS_INTF}
//  procedure IntfToDetails(const aDB:IEvsDatabaseInfo; var aRec:TDBDetails);
//  begin
//    aRec.Charset      := aDB.DefaultCharset;
//    aRec.DatabaseName := aDB.Host + ':' + aDB.Database;
//    aRec.Password     := aDB.Credentials.Password;
//    aRec.UserName     := aDB.Credentials.UserName;
//    aRec.Role         := aDB.Credentials.Role;
//    aRec.Title        := aDB.Title;
//  end;
//  {$ENDIF}
//begin
//  try
//    //Sort;               TDBInfo;
//    vFileName := aFilename;
//    if vFileName = '' then
//      vFileName:= utbConfig.GetConfigurationDirectory + 'turbobird.reg';
//
//    AssignFile(vFile, vFileName);
//    FileMode := 2;
//    Rewrite(vFile);
//
//    for vCntr := low(aDBArray) to High(aDBArray) do begin
//      {$IFDEF EVS_INTF}
//      IntfToDetails(aDBArray[vCntr].DataBase, aDBArray[vCntr].RegRec);
//      {$ENDIF}
//      Write(vFile, aDBArray[vCntr].OrigRegRec);
//    end;
//    CloseFile(vFile);
//    Result:= True;
//  except
//    on E: Exception do begin
//      Result:= False;
//    end;
//  end;
//end;

//function LoadRegistrations(var aDBArray :TDBInfoArray; const aFilename :string) :Boolean;
//var
//  vRec     : TDBDetails;
//  vFile    : file of TDBDetails;
//  vFileName: string;
//  {$IFDEF EVS_INTF}
//   function DetailsToIntf(aRec:TDBDetails):IEvsDatabaseInfo;
//   begin
//     Result := NewDatabase(stFirebird, ExtractHost(aRec.DatabaseName), ExtractDBName(aRec.DatabaseName),
//                           aRec.UserName, aRec.Password, aRec.Role, aRec.Charset);
//     Result.Title := aRec.Title;
//   end;
//  {$ENDIF}
//begin
//  vFileName := aFilename;
//  if vFileName = '' then
//    vFileName:= utbConfig.GetConfigurationDirectory + 'turbobird.reg';
//
//  AssignFile(vFile, vFileName);
//  if FileExists(vFileName) then begin
//    Reset(vFile);
//    try
//      while not system.Eof(vFile) do begin
//        Read(vFile, vRec);
//        if not vRec.Deleted then begin
//          SetLength(aDBArray, Length(aDBArray) + 1);
//          aDBArray[high(aDBArray)].RegRec     := vRec;
//          aDBArray[high(aDBArray)].OrigRegRec := vRec;
//          aDBArray[high(aDBArray)].Index      := FilePos(vFile) - 1;
//        {$IFDEF EVS_INTF}
//          aDBArray[high(aDBArray)].DataBase := DetailsToIntf(vRec);
//        {$ENDIF}
//
//          aDBArray[high(aDBArray)].Conn  := GetConnection(aDBArray[high(aDBArray)]);
//          aDBArray[high(aDBArray)].Trans := TMDOTransaction.Create(nil); //JKOZ pool?. //TSQLTransaction.Create(nil);
//
//          SetTransactionIsolation(aDBArray[high(aDBArray)].Trans.Params);
//          aDBArray[high(aDBArray)].Conn.DefaultTransaction := aDBArray[high(aDBArray)].Trans;
//          aDBArray[high(aDBArray)].Trans.DefaultDatabase   := aDBArray[high(aDBArray)].Conn;
//        end;
//      end;
//    finally
//      CloseFile(vFile);
//    end;
//  end;
//  Result:= True;
//end;
{$ENDREGION}

function DBRegistry :TDBRegistry;
begin
  if not Assigned(vDBRegistry) then vDBRegistry := TDBRegistry.Create;
  Result:= vDBRegistry;
end;

{ TDBEnumerator }

function TDBEnumerator.GetCurrent :IEvsDatabaseInfo;
begin
  Result := FObj.Database[FCurrent];
end;

constructor TDBEnumerator.Create(aList :TDBRegistry);
begin
  inherited Create;
  FObj := aList;
  FCurrent := -1;
end;

function TDBEnumerator.MoveNext :Boolean;
begin
  Inc(FCurrent);
  Result := FCurrent < FObj.Count;
end;

{$REGION ' TEVSLockableObject '}

procedure TEVSLockableObject.InitLock;
begin
  FLock := TCriticalSection.Create;
end;

constructor TEVSLockableObject.Create;
begin
  inherited Create;
  FLock := nil;//TCriticalSection.Create;
end;

destructor TEVSLockableObject.Destroy;
begin
  inherited;
  if Assigned(FLock) then FreeAndNil(FLock);
end;

procedure TEVSLockableObject.Lock;
begin
  if not Assigned(FLock)then InitLock;
  FLock.Acquire;
end;

procedure TEVSLockableObject.UnLock;
begin
  if Assigned(FLock) then FLock.Release;
end;
{$ENDREGION}

{$REGION ' TDBRegistry '}

Function TDBRegistry.GetCount :Integer;
begin
  Result := FDBList.Count;
end;

//Function TDBRegistry.GetDBConnection(aIndex :integer) :TMDODataBase;
//begin
//  CheckIndex(aIndex);
//  //Result := FDBData[aIndex].Conn;
//end;

function TDBRegistry.GetDBInfo(aIndex :Integer) :IEvsDatabaseInfo;
begin
  Result := Nil;
  Result := FDBList.Items[aIndex];
end;

//Function TDBRegistry.GetDBRec(aIndex :Integer) :TDBInfo;
//begin
//  CheckIndex(aIndex);
//  //Result := FDBData[aIndex];
//end;

//Function TDBRegistry.GetDBRegistration(aIndex :Integer) :TDBDetails;
//begin
//  CheckIndex(aIndex);
//  //Result := FDBData[aIndex].RegRec;
//end;

//Function TDBRegistry.GetDBTransaction(aIndex :Integer) :TMDOTransaction;
//begin
//  CheckIndex(aIndex);
//  //Result := FDBData[aIndex].Trans;
//end;

function TDBRegistry.GetKnowHostCount :Integer;
begin
  Result := FKnownHosts.Count;
end;

function TDBRegistry.GetKnownHost(aIndex :Integer) :Widestring;
begin
  Result := FKnownHosts[aIndex];
end;

//function TDBRegistry.GetRecords(aIndex :Integer) :TEvsDBSession;
//begin
//  //CheckIndex(Index);
//  Result := TEvsDBSession(FData[Index]);
//end;

Procedure TDBRegistry.SetCapacity(aNewCapacity :Integer);
begin
  //If (aNewCapacity < Count) or (aNewCapacity > MaxListSize) then Error(sListCapacity,aNewCapacity);
  //SetLength(FDBData, aNewCapacity);
  //FData.Capacity := aNewCapacity;
  //FCapacity := aNewCapacity;
  FDBList.Capacity := aNewCapacity;
end;

Procedure TDBRegistry.CheckIndex(aIndex :Integer);
begin
  if (aIndex<0) or (aIndex >= Count) then raise EDBRegistry.CreateFmt('Index is out of bounds %D',[aIndex]);
end;

Procedure TDBRegistry.SaveDBInfo(const aDBRec :TDBDetails; const aStream :TStream);
begin
  //make sure that the position of the stream is on the start of the record.
  aStream.Write(aDBRec, SizeOf(TDBDetails));//change it to a dynamic sized record.
end;

Procedure TDBRegistry.SaveDBInfo(const aDB :IEvsDatabaseInfo; const aStream :TStream);
  procedure WriteString(const aString:Widestring);
  var
    vLen :Int64;
    function blen:Int64;
    begin
      Result := @aString[Length(aString)+1] - @aString[1];
    end;

  begin
    vLen := blen;
    aStream.Write(vLen,SizeOf(vLen));
    aStream.Write(aString[1],vLen);
  end;
var
  vBl:LongBool;
  vInt:Integer;
begin
  aStream.Write(cDBInfoID,SizeOf(cDBInfoID));
  WriteString(aDB.Title);
  WriteString(aDB.Database);
  WriteString(aDB.Host);
  vInt := aDB.ServerKind;
  aStream.Write(vInt,SizeOf(Integer)); //WriteString();
  WriteString(aDB.DefaultCharset);
  WriteString(aDB.DefaultCollation);
  WriteString(aDB.Credentials.UserName);
  WriteString(aDB.Credentials.Role);
  vBl := aDB.Credentials.SavePassword;
  aStream.Write(vBl,SizeOf(vBl));
  if vBl then WriteString(aDB.Credentials.Password);
  aStream.Write(cDBInfoEnd,SizeOf(cDBInfoEnd));
end;

Procedure TDBRegistry.LoadDBInfo(var aDBRec :TDBDetails; const aStream :TStream; aID :Word);
begin
  aStream.Read(aDBRec, SizeOf(TDBDetails));
  // if endian is not correct then swap endian for the required fields, short string being ascii will not
  // need to swap, boolean is safe too, the datetime needs testing. If I could only find a big endian
  // VM for testing.
end;

procedure TDBRegistry.LoadDBInfo(const aDB :IEvsDatabaseInfo; const aStream :TStream);
  function ReadLong:LongInt;
  begin
    aStream.Read(Result, SizeOf(LongInt));
  end;
  function ReadBool:LongBool;
  begin
    aStream.Read(Result, SizeOf(LongBool));
  end;
  function ReadInt64:Int64;
  begin
    aStream.Read(Result, SizeOf(Int64));
  end;

  function ReadString:WideString;
  var
    vLen :Int64;
    vData:PWideChar;
  begin
    vLen  := ReadInt64;
    vData := AllocMem(vLen+4);// vData;
    try
      aStream.Read(vData^, vLen);
      Result := PWideChar(vData);
    finally
      Freemem(vData, vLen);
    end;
  end;
  function ReadWord:Word;
  begin
    aStream.Read(Result,SizeOf(word));
  end;
  function ReadInteger:Integer;
  begin
    aStream.Read(Result,SizeOf(Integer));
  end;

var
  vSign:Word;
begin
  vSign := ReadWord;
  if vSign <> cDBInfoID then
    raise ETBException.CreateFMT('Invalid signature on %D. expected %D found %D',[aStream.Position-SizeOf(Word),cDBInfoID,vSign]);
  aDB.Title                := ReadString;
  aDB.Database             := ReadString;
  aDB.Host                 := ReadString;
  aDB.ServerKind           := ReadInteger;
  aDB.DefaultCharset       := ReadString;
  aDB.DefaultCollation     := ReadString;
  aDB.Credentials.UserName := ReadString;
  aDB.Credentials.Role     := ReadString;
  aDB.Credentials.SavePassword := ReadBool;
  if aDB.Credentials.SavePassword then aDB.Credentials.Password := ReadString;
  vSign := ReadWord;
  if vSign <> cDBInfoEnd then
    raise ETBException.CreateFMT('missing end sign on %D. expected %D found %D',[aStream.Position-SizeOf(Word),cDBInfoEnd,vSign]);
end;

Procedure TDBRegistry.CleanupData;
begin
  FDBList.Clear;
end;

Class procedure TDBRegistry.Error(const aMsg :string; aData :array of const );
begin
  raise EDBRegistry.CreateFmt(aMsg,aData) at get_caller_addr(get_frame);
end;

Class Function TDBRegistry.IsValidRegistryFile(const aFileName :String) :Boolean;
var
  vHdrID :Word;
  vSign  :TSign;
  vStrm  :TFileStream;
begin
  vStrm := TFileStream.Create(aFileName, fmOpenReadWrite or fmShareExclusive);
  try
    vStrm.Read(vHdrID,SizeOf(cHdrID));
    vStrm.Read(vSign, SizeOf(TSign));
    Result := ((vHdrID = cHdrID) or (vHdrID = SwapEndian(cHdrID))) and CompareMem(@vSign, @cSign, SizeOf(TSign));
  finally
    vStrm.Free;
  end;
end;

Constructor TDBRegistry.Create;
begin
  inherited Create;;
  FDBList    := NewDatabaseList;//TList.Create;
  FObservers := TEvsObserverList.Create(True);
  FKnownHosts := TEvsWideStringList.Create;
end;

Destructor TDBRegistry.Destroy;
begin
  CleanupData;
  FDBList    := Nil;
  FObservers := nil;
  inherited Destroy;
end;

procedure TDBRegistry.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TDBRegistry.EndUpdate;
begin
  if InterLockedDecrement(FUpdateCount) = 0 then
    Notify(gaUpdate, Self as IEvsObjectRef, 0);
end;

procedure TDBRegistry.CancelUpdate;
begin
  InterLockedDecrement(FUpdateCount);
end;

procedure TDBRegistry.AddObserver(Observer :IEvsObserver); extdecl;
begin
  FObservers.Add(Observer);
end;

procedure TDBRegistry.DeleteObserver(Observer :IEvsObserver); extdecl;
begin
  FObservers.Remove(Observer);
end;

procedure TDBRegistry.ClearObservers; extdecl;
begin
  FObservers.Clear;
end;

procedure TDBRegistry.Notify(const Action :TEVSGenAction; const aSubject :IEvsObjectRef; const aData:NativeUInt); extdecl;
begin
  FObservers.Notify(Action, aSubject, aData);
end;

function TDBRegistry.CopyFrom(const aSource :IEvsCopyable) :Integer; extdecl;
begin
  raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

function TDBRegistry.CopyTo(const aDest :IEvsCopyable) :Integer; extdecl;
begin
  raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

function TDBRegistry.EqualsTo(const aCompare :IEvsCopyable) :Boolean; extdecl;
begin
  raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

Function TDBRegistry.ObjectRef :TObject; extdecl;
begin
  Result := Self;
end;

Function TDBRegistry.IndexOf(const aDatabaseName :string) :Integer;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to FDBList.Count -1 do
    if WideCompareText(WideString(aDatabaseName), FDBList[vCntr].Database) = 0 then Exit(vCntr);
end;

Function TDBRegistry.IndexOf(const aDBInfo :IEvsDatabaseInfo) :Integer;
begin
  Result := FDBList.IndexOf(aDBInfo);
end;

procedure TDBRegistry.SetDBInfo(Index :Integer; aValue :IEvsDatabaseInfo);
begin
  FDBList[Index] := aValue;
end;

Procedure TDBRegistry.SaveTo(const aStream :TStream);
  Procedure SaveHeader;
  begin
    aStream.Write(cHdrID,SizeOf(cHdrID));
    aStream.Write(cSign, SizeOf(TSign));
  end;
var
  vCnt :UInt64;
  vCntr :Integer;
begin
  aStream.Position := 0;
  SaveHeader;
  vCnt := FDBList.Count;
  aStream.Write(vCnt, SizeOf(UInt64));
  for vCntr := 0 to FDBList.Count -1 do begin
    //SaveDBInfo(PDBInfo(FData.Items[vCntr])^.RegRec, aStream);
    SaveDBInfo(FDBList[vCntr], aStream);
  end;
end;

Procedure TDBRegistry.LoadFrom(const aStream :TStream);
  var
    vHdrID :Word;
    vSign  :TSign;
    vEndianSwap : Boolean;
  function ValidHeader(anID:Word; aSign:TSign):Boolean;
  begin
    vEndianSwap := (anID = SwapEndian(cHdrID));
    Result := ((anID = cHdrID) or (vEndianSwap)) and CompareMem(@aSign, @cSign, SizeOf(TSign));
  end;

  procedure LoadHeader;
  begin
    aStream.Read(vHdrID,SizeOf(cHdrID));
    aStream.Read(vSign, SizeOf(TSign));
  end;

  //function PositionToIndex(aPos:Int64):Integer;
  //begin
  //  Result := (aPos - (sizeof(cHdrID)+SizeOf(TSign)+sizeof(UInt64))) div SizeOf(TDBDetails);
  //end;

var
  vCnt    : UInt64  = 0;
  vDbInfo : IEvsDatabaseInfo = nil;// PDBInfo = nil;
  //vIdx    : Int64   = -1;
begin
  BeginUpdate;
  try
    LoadHeader;
    if not ValidHeader(vHdrID, vSign) then begin
      raise ETBException.Create('Unknown File Format');
    end;
    aStream.Read(vCnt, SizeOf(UInt64));
    if (vCnt > 0) then repeat
      vDbInfo := NewDatabase;
      LoadDBInfo(vDbInfo, aStream);
      Dec(vCnt);
    until (vCnt <= 0) or EOF(aStream);
  finally
    EndUpdate;
  end;
end;

Procedure TDBRegistry.SaveTo(const aFileName :string);
var
  vStrm : TFileStream;
begin
  vStrm := TFileStream.Create(aFileName, fmCreate or fmShareExclusive);
  try
    SaveTo(vStrm);
  finally
    vStrm.Free;
  end;
end;

Procedure TDBRegistry.LoadFrom(const aFileName :string);
var
  vStrm : TFileStream;
  //FDBData     :TDBInfoArray;
  //vCntr :Integer;
begin

  vStrm := TFileStream.Create(aFileName,fmOpenReadWrite or fmShareExclusive);
  BeginUpdate;
  try
    //try
      LoadFrom(vStrm);
    // Simplify things out add an import file menu.
    //except
    //  on e:Exception do begin
    //    LoadRegistrations(FDBData, aFileName);
    //    for vCntr:= Low(FDBData) to High(FDBData) do
    //      FDBList.Add(FDBData[vCntr].DataBase);
    //    SetLength(FDBData, 0);
    //  end;
    //end;
  finally
    vStrm.Free;
    EndUpdate;
  end;
end;

Procedure TDBRegistry.Delete(aIndex :Integer);
begin
  if Assigned(FDBList) and Between(0, FDBList.Count - 1, aIndex) then
    FDBList.Delete(aIndex);
end;

Function TDBRegistry.NewDatabase :IEvsDatabaseInfo;
begin
  Result := FDBList.New;
end;

Procedure TDBRegistry.RemoveDatabase(aDB :IEvsDatabaseInfo);
begin
  FDBList.Remove(aDB);
end;

function TDBRegistry.GetEnumerator :TDBEnumerator;
begin
  Result := TDBEnumerator.Create(Self);
end;

procedure TDBRegistry.GetKnownServer(const aList :TStrings);
var
  vCntr :Integer;
  vList :TStringList;
begin
  vList := TStringList.Create;
  try
    vList.Sorted := true;
    vList.Duplicates := dupIgnore;
    for vCntr := 0 to Count -1 do begin
      vList.Add(Database[vCntr].Host);
    end;
    aList.Assign(vList);
  finally
    vList.Free;
  end;
end;

function TDBRegistry.GetKnownServers :TStringArray;
var
  vCntr :Integer;
  vTotal:Integer;

  function InArray(const aStr:string; const aArray:Array of string):Boolean;
  var
    vStr :String;
  begin
    if Length(aArray)<=0 then Exit(False);
    for vStr in aArray do begin
      Result := AnsiSameText(aStr, vStr);
      if Result then Exit;
    end;
  end;

  procedure AppendHost(const aValue:String);inline;
  begin
    GetKnownServers[vTotal] := aValue;
    Inc(vTotal);
  end;

begin
  vTotal := 0;
  if Count > 1 then begin;
    SetLength(Result, Count);//assume all database are in different servers no duplicates
    Result[vTotal] := Database[vTotal].Host;
    inc(vTotal);
    for vCntr := 1 to Count -1 do begin
      if not inArray(Database[vCntr].Host, Result) then
        AppendHost(Database[vCntr].Host);
    end;
    SetLength(Result, vTotal);//return only what we have found.;
  end;
end;

Procedure TDBRegistry.Append(aValue :IEvsDatabaseInfo);
begin
  FDBList.Add(aValue);
  FKnownHosts.Add(aValue.Host);
end;

{$ENDREGION}

{$REGION 'Testing'}
type

  { TSingleton }

  TSingleton = class abstract
  protected
    //class var FInstance  : TSingleton;
    class var CreationCounter: Integer;
    class constructor CreateSingleton;
    class function NeedsNew:Boolean;virtual;
    class procedure SetInstance(aInstance:TSingleton);virtual;
    class function GetInstance:TSingleton;virtual;
    class procedure Lock;virtual;
    class procedure Unlock;virtual;

    procedure Initialize;virtual;
  public
    class function NewInstance: TObject; override;
    procedure FreeInstance; override;
  end;

  { TEvsDBApplication }

  TEvsDBApplication = class(TSingleton)
  private
    class var FInstance  : TSingleton;
    class var FDataTypes : TStringList;
    class var FLock      : TCriticalSection;
    class function GetDataTypes  (Index : Integer; Group : String) : TObject;static;
    class procedure SetDataTypes (Index : Integer; Group : String; aValue : TObject);static;
  protected
    class constructor AppInit;
    class destructor  AppDone;
    //the three methods below are required for the singleton to work.
    class function NeedsNew    : Boolean;      override;
    class function GetInstance : TSingleton;   override;
    class procedure SetInstance(aInstance:TSingleton);override;
    //the two below are here to make sure that this class is thread safe if you
    // do not want to use any sync object then simple delete them and the flock var.
    class procedure Lock;    override;
    class procedure Unlock;  override;
  public
    class property DataTypes[Index:Integer;Group:String]:TObject read GetDataTypes write SetDataTypes;
  end;

{$REGION ' TSingleton '}

class constructor TSingleton.CreateSingleton;
begin
  CreationCounter := 0;
end;

procedure TSingleton.Initialize;
begin

end;

class function TSingleton.NeedsNew : Boolean;
begin
  Result := True;
end;

class procedure TSingleton.SetInstance(aInstance : TSingleton);
begin

end;

class function TSingleton.GetInstance : TSingleton;
begin

end;

class procedure TSingleton.Lock;
begin

end;

class procedure TSingleton.Unlock;
begin

end;

procedure TSingleton.FreeInstance;
begin
  Lock;
  try
    InterLockedDecrement(CreationCounter);
    if CreationCounter = 0 then begin
      SetInstance(nil);
      inherited FreeInstance;
    end;
  finally
    Unlock;
  end;
end;

class function TSingleton.NewInstance: TObject;
begin
  Lock;
  try
    if CompareText(ClassName, 'TSingleton') = 0 then
      raise Exception.Create('TSingleton is an Abstract class. Please use one of the descendants');
    if NeedsNew then begin
      SetInstance(TSingleton(inherited NewInstance));
      GetInstance.Initialize;
    end;
    InterLockedIncrement(CreationCounter);
    Result := GetInstance;
  finally
    Unlock;
  end;
end;

{$ENDREGION}

{ TEvsDBApplication }

class function TEvsDBApplication.GetDataTypes(Index : Integer; Group : String) : TObject;
begin

end;

class procedure TEvsDBApplication.SetDataTypes(Index : Integer; Group : String;
  aValue : TObject);
begin

end;

class constructor TEvsDBApplication.AppInit;
begin
  FDataTypes := TStringList.Create;
  FLock      := TCriticalSection.Create;
end;

class destructor TEvsDBApplication.AppDone;
begin
  FDataTypes.Free;
  FLock.Free;
end;

class function TEvsDBApplication.NeedsNew : Boolean;
begin
  Result := not Assigned(FInstance);
end;

class procedure TEvsDBApplication.SetInstance(aInstance : TSingleton);
begin
  FInstance := aInstance;
end;

class function TEvsDBApplication.GetInstance : TSingleton;
begin
  Result := FInstance;
end;

class procedure TEvsDBApplication.Lock;
begin
  FLock.Enter;
end;

class procedure TEvsDBApplication.Unlock;
begin
  FLock.Leave;
end;

{$ENDREGION}
initialization
  vDBRegistry := TDBRegistry.Create;
finalization
  vDBRegistry.Free;
end.





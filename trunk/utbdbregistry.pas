{ Registered Database manager and data types.

}
{$DEFINE EVS_INTF}
unit utbDBRegistry;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uTBTypes, utbcommon, utbConfig, uEvsDBSchema, uTBFirebird, uEvsWideString, MDODatabase, sqldb, syncobjs;
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
  TDBRegistry = class(TInterfacedPersistent)
  private
    class var FInstance   :TObject;
    class var FInstCntr   :Integer;
    FDBData     :TDBInfoArray;
    FData       :TList;
    FEndianSwap :Boolean;
    FCount      :Integer;
    FCapacity   :Integer;
    FDBList     :IEvsDatabaseList;
    FKnownHosts :TEvsWideStringList;
    //List management
    Function GetCount :Integer;
    Function GetDBConnection(aIndex :integer) :TMDODataBase;
    function GetDBInfo(Index :Integer) :IEvsDatabaseInfo;
    Function GetDBRec(aIndex :Integer) :TDBInfo;
    Function GetDBRegistration(aIndex :Integer) :TDBDetails;
    Function GetDBTransaction(aIndex :Integer) :TMDOTransaction;
    function GetKnowHostCount :Integer;
    function GetKnownHost(Index :Integer) :Widestring;
    Function GetSession(aIndex :Integer) :PDBInfo;
    Procedure SetCapacity(aNewCapacity:Integer);

    Procedure CheckIndex(aIndex:Integer);inline;
    //persisting routines.
    Procedure SaveDBInfo(const aDBRec:TDBDetails; const aStream :TStream);virtual;experimental;//unimplemented;
    Procedure LoadDBInfo(var aDBRec :TDBDetails; const aStream :TStream; aID :Word); virtual; experimental;// unimplemented;
    Procedure SetDBConnection(aIndex :integer; aValue :TMDODataBase);
    procedure SetDBInfo(Index :Integer; aValue :IEvsDatabaseInfo);
    Procedure SetDBRec(const aIndex :Integer; const aValue :TDBInfo);
    Procedure SetDBRegistration(aIndex :Integer; aValue :TDBDetails);
    Procedure SetDBTransaction(aIndex :Integer; aValue :TMDOTransaction);
    Procedure SetSession(aIndex :Integer; aValue :PDBInfo);
  protected
    Procedure CleanupData;
    //Procedure SaveString(const aString:string; aStream:TStream);virtual;abstract;
    //Function LoadString(aStream:TStream):string;virtual;abstract;
  public
    Class function NewInstance :TObject; override;
    Class procedure Error(const Msg: string; Data: PtrInt);
    Class Function IsValidRegistryFile(const aFileName:String):Boolean;
    Constructor Create;
    Destructor Destroy; override;
    Function IndexOf(const aDatabaseName:string):Integer;
    Function IndexOf(const aDBInfo:TDBInfo):Integer;EXPERIMENTAL;
    Procedure SaveTo    (const aStream:TStream); virtual;unimplemented;
    Procedure SaveTo    (const aFileName:string);virtual;
    Procedure LoadFrom  (const aStream:TStream); virtual;experimental;
    Procedure LoadFrom  (const aFileName:string);virtual;
    Procedure Append(aValue:TDBinfo);overload;EXPERIMENTAL;
    Procedure Delete(aIndex:Integer);overload;EXPERIMENTAL;
    Function NewDatabase :IEvsDatabaseInfo;overload;
    function GetEnumerator : TDBEnumerator;
    Procedure Append(aValue:IEvsDatabaseInfo);overload;
    Property Count                        :Integer          read GetCount;
    //Property DatabaseInfo [Index:Integer] :TDBInfo          read GetDBRec          write SetDBRec;experimental;
    //Property DBRecord     [Index:Integer] :TDBDetails       read GetDBRegistration write SetDBRegistration;
    property Database     [Index:Integer] :IEvsDatabaseInfo read GetDBInfo         write SetDBInfo;default;
    //Property DBConnection [Index:integer] :TMDODataBase     read GetDBConnection   write SetDBConnection;
    //Property DBTransaction[Index:Integer] :TMDOTransaction  read GetDBTransaction  write SetDBTransaction;
    //Property Session      [Index:Integer] :PDBInfo          read GetSession        write SetSession;
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

function SaveRegistrations(var aDBArray :TDBInfoArray; const aFilename :string = ''):Boolean;
function LoadRegistrations(var aDBArray :TDBInfoArray; const aFilename :string = ''):Boolean;
function Registry:TDBRegistry;

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
var
  DBRegistry :TDBRegistry;

{$REGION ' Legacy '}
procedure Sort(var aDBArray:Array of TDBInfo);
var
  vTempRec  : TDBDetails;
  vDone     : Boolean;
  vCntr     : Integer;
  vIndex    : Integer;
begin
  raise NotImplementedException;
  repeat
    vDone:= True;
    for vCntr:= low(aDBArray) to High(aDBArray) - 1 do
    //with fmMain do
      if aDBArray[vCntr].RegRec.LastOpened < aDBArray[vCntr + 1].RegRec.LastOpened then begin
        vDone:= False;
        vTempRec:= aDBArray[vCntr].OrigRegRec;
        aDBArray[vCntr].OrigRegRec:= aDBArray[vCntr + 1].OrigRegRec;
        aDBArray[vCntr].RegRec:= aDBArray[vCntr + 1].RegRec;
        aDBArray[vCntr + 1].OrigRegRec:= vTempRec;
        aDBArray[vCntr + 1].RegRec:= vTempRec;

        vIndex:= aDBArray[vCntr].Index;
        aDBArray[vCntr].Index := aDBArray[vCntr + 1].Index;
        aDBArray[vCntr + 1].Index:= vIndex;
      end;
  until vDone;
end;

function SaveRegistrations(var aDBArray :TDBInfoArray; const aFilename :string) :Boolean;
var
  vFile    : file of TDBDetails;
  vFileName: string;
  vCntr    : Integer;
  {$IFDEF EVS_INTF}
  procedure IntfToDetails(const aDB:IEvsDatabaseInfo; var aRec:TDBDetails);
  begin
    aRec.Charset      := aDB.DefaultCharset;
    aRec.DatabaseName := aDB.Host + ':' + aDB.Database;
    aRec.Password     := aDB.Credentials.Password;
    aRec.UserName     := aDB.Credentials.UserName;
    aRec.Role         := aDB.Credentials.Role;
    aRec.Title        := aDB.Title;
  end;
  {$ENDIF}
begin
  try
    //Sort;               TDBInfo;
    vFileName := aFilename;
    if vFileName = '' then
      vFileName:= utbConfig.GetConfigurationDirectory + 'turbobird.reg';

    AssignFile(vFile, vFileName);
    FileMode := 2;
    Rewrite(vFile);

    for vCntr := low(aDBArray) to High(aDBArray) do begin
      {$IFDEF EVS_INTF}
      IntfToDetails(aDBArray[vCntr].DataBase, aDBArray[vCntr].RegRec);
      {$ENDIF}
      Write(vFile, aDBArray[vCntr].OrigRegRec);
    end;
    CloseFile(vFile);
    Result:= True;
  except
    on E: Exception do begin
      Result:= False;
    end;
  end;
end;

function LoadRegistrations(var aDBArray :TDBInfoArray; const aFilename :string) :Boolean;
var
  vRec     : TDBDetails;
  vFile    : file of TDBDetails;
  vFileName: string;
  {$IFDEF EVS_INTF}
   function DetailsToIntf(aRec:TDBDetails):IEvsDatabaseInfo;
   begin
     Result := NewDatabase(stFirebird, ExtractHost(aRec.DatabaseName), ExtractDBName(aRec.DatabaseName),
                           aRec.UserName, aRec.Password, aRec.Role, aRec.Charset);
     Result.Title := aRec.Title;
   end;
  {$ENDIF}
begin
  vFileName := aFilename;
  if vFileName = '' then
    vFileName:= utbConfig.GetConfigurationDirectory + 'turbobird.reg';

  AssignFile(vFile, vFileName);
  if FileExists(vFileName) then begin
    Reset(vFile);
    try
      while not system.Eof(vFile) do begin
        Read(vFile, vRec);
        if not vRec.Deleted then begin
          SetLength(aDBArray, Length(aDBArray) + 1);
          aDBArray[high(aDBArray)].RegRec     := vRec;
          aDBArray[high(aDBArray)].OrigRegRec := vRec;
          aDBArray[high(aDBArray)].Index      := FilePos(vFile) - 1;
        {$IFDEF EVS_INTF}
          aDBArray[high(aDBArray)].DataBase := DetailsToIntf(vRec);
        {$ENDIF}

          aDBArray[high(aDBArray)].Conn  := GetConnection(aDBArray[high(aDBArray)]);
          aDBArray[high(aDBArray)].Trans := TMDOTransaction.Create(nil); //JKOZ pool?. //TSQLTransaction.Create(nil);

          SetTransactionIsolation(aDBArray[high(aDBArray)].Trans.Params);
          aDBArray[high(aDBArray)].Conn.DefaultTransaction := aDBArray[high(aDBArray)].Trans;
          aDBArray[high(aDBArray)].Trans.DefaultDatabase   := aDBArray[high(aDBArray)].Conn;
        end;
      end;
    finally
      CloseFile(vFile);
    end;
  end;
  Result:= True;
end;
{$ENDREGION}

function Registry :TDBRegistry;
begin
  if not Assigned(DBRegistry) then DBRegistry := TDBRegistry.Create;
  Result:= DBRegistry;
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

Function TDBRegistry.GetDBConnection(aIndex :integer) :TMDODataBase;
begin
  CheckIndex(aIndex);
  Result := FDBData[aIndex].Conn;
end;

function TDBRegistry.GetDBInfo(Index :Integer) :IEvsDatabaseInfo;
begin
  Result := FDBList[Index];
end;

Function TDBRegistry.GetDBRec(aIndex :Integer) :TDBInfo;
begin
  CheckIndex(aIndex);
  Result := FDBData[aIndex];
end;

Function TDBRegistry.GetDBRegistration(aIndex :Integer) :TDBDetails;
begin
  CheckIndex(aIndex);
  Result := FDBData[aIndex].RegRec;
end;

Function TDBRegistry.GetDBTransaction(aIndex :Integer) :TMDOTransaction;
begin
  CheckIndex(aIndex);
  Result := FDBData[aIndex].Trans;
end;

function TDBRegistry.GetKnowHostCount :Integer;
begin
  Result := FKnownHosts.Count;
end;

function TDBRegistry.GetKnownHost(Index :Integer) :Widestring;
begin
  Result := FKnownHosts[Index];
end;

//function TDBRegistry.GetRecords(aIndex :Integer) :TEvsDBSession;
//begin
//  //CheckIndex(Index);
//  Result := TEvsDBSession(FData[Index]);
//end;

Procedure TDBRegistry.SetCapacity(aNewCapacity :Integer);
begin
  If (aNewCapacity < Count) or (aNewCapacity > MaxListSize) then Error(sListCapacity,aNewCapacity);
  SetLength(FDBData, aNewCapacity);
  FData.Capacity := aNewCapacity;
  FCapacity := aNewCapacity;
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

Procedure TDBRegistry.LoadDBInfo(var aDBRec :TDBDetails; const aStream :TStream; aID :Word);
begin
  aStream.Read(aDBRec, SizeOf(TDBDetails));
  // if endian is not correct then swap endian for the required fields, short string being ascii will not
  // need to swap, boolean is safe too, the datetime needs testing. If I could only find a big endian
  // VM for testing.
end;

Procedure TDBRegistry.CleanupData;
var
  vCntr :Integer;
  vDB   :PDBInfo;
begin
  for vCntr := 0 to FData.Count -1 do begin
    vDB := FData[vCntr];
    FData[vCntr] := Nil;
    Freemem(vDB);
  end;
  FData.Clear;
end;

Class function TDBRegistry.NewInstance :TObject;
begin
  if not Assigned(FInstance) then begin
    Result    := inherited NewInstance;
    FInstance := Result;
  end;
  InterLockedIncrement(FInstCntr);
end;

Class procedure TDBRegistry.Error(const Msg :string; Data :PtrInt);
begin
  raise EDBRegistry.CreateFmt(Msg,[Data]) at get_caller_addr(get_frame);
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
  FDBList := NewDatabaseList;//TList.Create;
end;

Destructor TDBRegistry.Destroy;
begin
  CleanupData;
  FData.Free;
  inherited Destroy;
end;

Function TDBRegistry.IndexOf(const aDatabaseName :string) :Integer;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to FDBList.Count -1 do
    if WideCompareText(WideString(aDatabaseName), FDBList[vCntr].Database) = 0 then Exit(vCntr);
end;

Function TDBRegistry.IndexOf(const aDBInfo :TDBInfo) :Integer;
var
  vCntr :Integer;
begin
  Result := -1;
  //for vCntr := 0 to Count -1 do
  //  if ((Session[vCntr]^.Conn = aDBInfo.Conn) and (Session[vCntr]^.Trans = aDBInfo.Trans)) then exit(vCntr);
end;

Function TDBRegistry.GetSession(aIndex :Integer) :PDBInfo;
begin
  Result := PDBInfo(FData[aIndex]);
end;

Procedure TDBRegistry.SetDBRegistration(aIndex :Integer; aValue :TDBDetails);
begin
  CheckIndex(aIndex);
  FDBData[aIndex].RegRec := aValue;
end;

Procedure TDBRegistry.SetDBConnection(aIndex :integer; aValue :TMDODataBase);
begin
  FDBData[aIndex].Conn := aValue;
end;

procedure TDBRegistry.SetDBInfo(Index :Integer; aValue :IEvsDatabaseInfo);
begin
  FDBList[Index]:= aValue;
end;

Procedure TDBRegistry.SetDBRec(const aIndex :Integer; const aValue :TDBInfo);
begin
  //CheckIndex(aIndex);
  PDBInfo(FData[aIndex])^ := aValue;
end;

Procedure TDBRegistry.SetDBTransaction(aIndex :Integer; aValue :TMDOTransaction);
begin
  CheckIndex(aIndex);
  FDBData[aIndex].Trans := aValue;
end;

Procedure TDBRegistry.SetSession(aIndex :Integer; aValue :PDBInfo);
begin
  FData[aIndex] := aValue;
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
  vCnt := FData.Count;
  aStream.Write(vCnt, SizeOf(UInt64));
  for vCntr := 0 to FData.Count -1 do begin
    SaveDBInfo(PDBInfo(FData.Items[vCntr])^.RegRec, aStream);
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

  function PositionToIndex(aPos:Int64):Integer;
  begin
    Result := (aPos - (sizeof(cHdrID)+SizeOf(TSign)+sizeof(UInt64))) div SizeOf(TDBDetails);
  end;

var
  vCnt    : UInt64  = 0;
  vDbInfo : PDBInfo = nil;
  vIdx    : Int64   = -1;
  vHost, vPort, vDB:Widestring;
begin
  LoadHeader;
  if not ValidHeader(vHdrID, vSign) then begin
    raise ETBException.Create('Unknown File Format');
  end;
  aStream.Read(vCnt, SizeOf(UInt64));
  repeat
    vDbInfo := NewDBInfo;//(PDBInfo);
    //vIdx := PositionToIndex(aStream.Position);
    vIdx := aStream.Position; // do not convert to index, the file format will be changed to support dynamic sized data and encryption of the passwords.
    LoadDBInfo(vDbInfo^.RegRec, aStream, vHdrID);
    uEvsWideString.ParseCombDBName(vDbInfo^.RegRec.DatabaseName, vHost, vPort, vDB);

    if not vDbInfo^.RegRec.Deleted then begin
      vDbInfo^.OrigRegRec := vDbInfo^.RegRec;
      vDbInfo^.Index := vIdx;
      FData.Add(vDbInfo);
      vDbInfo := Nil;
    end;
    Dec(vCnt);
  until (vCnt <= 0) or  EOF(aStream);
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
begin
  vStrm := TFileStream.Create(aFileName,fmOpenReadWrite or fmShareExclusive);
  try
    try
      LoadFrom(vStrm);
    except
      on e:Exception do begin
        LoadRegistrations(FDBData, aFileName);
      end;
    end;
  finally
    vStrm.Free;
  end;
end;

Procedure TDBRegistry.Append(aValue :TDBinfo);
var
  vDBInfo :PDBInfo;
begin
  vDBInfo := New(PDBInfo);
  vDBInfo^ := aValue;
  FData.Add(vDBInfo);
end;

Procedure TDBRegistry.Delete(aIndex :Integer);
begin
  if Assigned(FDBList) and Between(0, FDBList.Count - 1, aIndex) then begin
    FDBList.Delete(aIndex);
    Exit;
  end;

  if Assigned(FData) and Between(0, FData.Count - 1, aIndex) then begin// >= 0 and aIndex < FData.Count ;
    FData.Delete(aIndex);
    Exit;
  end;
end;

Function TDBRegistry.NewDatabase :IEvsDatabaseInfo;
begin
  Result := FDBList.New;
end;

function TDBRegistry.GetEnumerator :TDBEnumerator;
begin
  Result := TDBEnumerator.Create(Self);
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
  DBRegistry := TDBRegistry.Create;
finalization
  DBRegistry.Free;
end.





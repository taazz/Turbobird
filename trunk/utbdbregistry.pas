{ Registered Database manager and data types.

}
{$DEFINE EVS_INTF}
unit utbDBRegistry;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uTBTypes, utbcommon, utbConfig, uEvsDBSchema, uTBFirebird, MDODatabase, sqldb, syncobjs;
type

  EDBRegistry = class(ETBException);
  //TEvsBackupRestoreOperation
  //TStream
  { TEVSLockableObject }

  TevsStreamWriter = class(TWriter)

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

  { TDBRegistry }
  // manage the list of known database registrations in memory.
  TDBRegistry = class
  private
    FDBData     : TDBInfoArray;
    FData       : TList;
    FEndianSwap : Boolean;
    FCount      : Integer;
    FCapacity   : Integer;
    //List management
    function GetCount :Integer;
    function GetDBConnection(aIndex :integer) :TMDODataBase;
    function GetDBRec(aIndex :Integer) :TDBInfo;
    function GetDBRegistration(aIndex :Integer) :TDBDetails;
    function GetDBTransaction(aIndex :Integer) :TMDOTransaction;
    function GetSession(aIndex :Integer) :PDBInfo;
    procedure SetCapacity(aNewCapacity:Integer);

    procedure CheckIndex(aIndex:Integer);inline;
    //persisting routines.
    procedure SaveDBInfo(const aDBRec:TDBDetails; const aStream :TStream);virtual;experimental;//unimplemented;
    procedure LoadDBInfo(var aDBRec :TDBDetails; const aStream :TStream; aID :Word); virtual; experimental;// unimplemented;
    procedure SetDBConnection(aIndex :integer; aValue :TMDODataBase);
    procedure SetDBRec(const aIndex :Integer; const aValue :TDBInfo);
    procedure SetDBRegistration(aIndex :Integer; aValue :TDBDetails);
    procedure SetDBTransaction(aIndex :Integer; aValue :TMDOTransaction);
    procedure SetSession(aIndex :Integer; aValue :PDBInfo);
  protected
    procedure CleanupData;
    procedure SaveString(const aString:string; aStream:TStream);virtual;abstract;
    function LoadString(aStream:TStream):string;virtual;abstract;
  public
    class procedure Error(const Msg: string; Data: PtrInt);
    class Function IsValidRegistryFile(const aFileName:String):Boolean;
    constructor Create;
    destructor Destroy; override;
    function IndexOf(const aDatabaseName:string):Integer;
    function IndexOf(const aDBInfo:TDBInfo):Integer;
    procedure SaveTo    (const aStream:TStream); virtual;unimplemented;
    procedure SaveTo    (const aFileName:string);virtual;
    procedure LoadFrom  (const aStream:TStream); virtual;experimental;
    procedure LoadFrom  (const aFileName:string);virtual;
    procedure Append(aValue:TDBinfo);experimental;
    procedure Delete(aIndex:Integer);EXPERIMENTAL;
    property Count                        :Integer         read GetCount;
    property DatabaseInfo [Index:Integer] :TDBInfo         read GetDBRec          write SetDBRec;
    property DBRecord     [Index:Integer] :TDBDetails      read GetDBRegistration write SetDBRegistration;
    property DBConnection [Index:integer] :TMDODataBase    read GetDBConnection   write SetDBConnection;
    property DBTransaction[Index:Integer] :TMDOTransaction read GetDBTransaction  write SetDBTransaction;
    property Session      [Index:Integer] :PDBInfo         read GetSession        write SetSession;
  end;

  //move to the classes below when time permits.
  { TEVSDatabaseRecord }
  //Data for a database registration.
  TEVSDatabaseRecord = class(TEVSLockableObject)
  private
    FCharset      :string;
    FDatabaseName :String;
    FDeleted      :Boolean;
    FLastOpened   :TDatetime;
    FPassword     :string;
    FRole         :string;
    FSavePassword :Boolean;
    FUserName     :string;
    function GetCharset :string;
    function GetDatabaseName :String;
    function GetDeleted :Boolean;
    function GetHostName :String;
    function GetLastOpened :TDatetime;
    function GetPassword :string;
    function GetRole :string;
    function GetSavePassword :Boolean;
    function GetUserName :string;
    procedure SetCharset(aValue :string);
    procedure SetDatabaseName(aValue :String);
    procedure SetDeleted(aValue :Boolean);
    procedure SetHostName(aValue :String);
    procedure SetLastOpened(aValue :TDatetime);
    procedure SetPassword(aValue :string);
    procedure SetRole(aValue :string);
    procedure SetSavePassword(aValue :Boolean);
    procedure SetUserName(aValue :string);
  protected
    FID : TGuid; //internal ID used to encrypt sensitive information created once at creation.
    function AsDBDetails:TDBDetails; //this returns a copy of the data.
  public
    constructor Create;override;//virtual;
  published
    property HostName    :String    read GetHostName     write SetHostName;
    property DatabaseName:String    read GetDatabaseName write SetDatabaseName;
    property UserName    :string    read GetUserName     write SetUserName;
    property Password    :string    read GetPassword     write SetPassword;
    property Role        :string    read GetRole         write SetRole;
    property Charset     :string    read GetCharset      write SetCharset;
    property LastOpened  :TDatetime read GetLastOpened   write SetLastOpened;
    property Deleted     :Boolean   read GetDeleted      write SetDeleted;
    property SavePassword:Boolean   read GetSavePassword write SetSavePassword;
  end;
  {TEvsDBSession}
  // session data like transaction and connection or what ever else I might need.
  TEvsDBSession = class(TEVSDatabaseRecord)
  private
    FBackupData  :TDBDetails;
    FIndex       :Int64;
    FConnection  :TMDODataBase;
    FTransaction :TMDOTransaction;
    function GetConnection :TMDODataBase;
    function GetTransaction :TMDOTransaction;
    procedure SetConnection(aValue :TMDODataBase);
    procedure SetTransaction(aValue :TMDOTransaction);
  protected
    function AsDBInfo:TDBInfo;
    function Original:TDBDetails;
  public
    //constructor Create;
    procedure Backup;
    property Connection :TMDODataBase    read GetConnection  write SetConnection;
    property Transaction:TMDOTransaction read GetTransaction write SetTransaction;
  end;

function SaveRegistrations(var aDBArray :TDBInfoArray; const aFilename:string = ''): Boolean;
function LoadRegistrations(var aDBArray :TDBInfoArray; const aFilename:string=''): Boolean;
function Registry:TDBRegistry;

resourcestring
  sListCapacity = 'Capacity (%d) requirements not met.';//Minimum (%d) maximum (%d);
  rsotUsers = 'Users';
  rsotExceptions = 'Exceptions';
  rsotRoles = 'Roles';
  rsotDomains = 'Domains';
  rsotSystemTables = 'System Tables';
  rsotFunctions = 'Functions';
  rsotStoredProced = 'Stored Procedures';
  rsotViews = 'Views';
  rsotTriggers = 'Triggers';
  rsotGenerators = 'Generators';
  rsotTables = 'Tables';
  rsotQueryWindow = 'Query Window';

implementation

type
  TSign = array[0..3]of Byte;

const
  cHdrID  :word  = $0201;//endian check. little endian =$102 big endian =201;
  cSign   :TSign = ($00, $45, $56, $73);
  cCharSet:Byte  = ord('A'); //ascii character set. the existing records use shortstrings.
var
  DatabaseRegistry:TDBRegistry;

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
  if not Assigned(DatabaseRegistry) then DatabaseRegistry := TDBRegistry.Create;
  Result:= DatabaseRegistry;
end;

{$REGION ' TEVSDatabaseRecord '}

procedure TEVSDatabaseRecord.SetCharset(aValue :string);
begin
  if Assigned(FLock) then Lock;
  try
    if FCharset=aValue then Exit;
    FCharset:=aValue;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.GetCharset :string;
begin
  if Assigned(FLock) then Lock;
  try
    Result := FCharset;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.GetDatabaseName :String;
begin
  if Assigned(FLock) then Lock;
  try
    Result := FDatabaseName;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.GetDeleted :Boolean;
begin
  if Assigned(FLock) then Lock;
  try
    Result := FDeleted;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.GetHostName :String;
begin
  if Assigned(FLock) then Lock;
  try
    Result := GetServerName(FDatabaseName);
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.GetLastOpened :TDatetime;
begin
  if Assigned(FLock) then Lock;
  try
    Result := FLastOpened;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.GetPassword :string;
begin
  if Assigned(FLock) then Lock;
  try
    Result := FPassword;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.GetRole :string;
begin
  if Assigned(FLock) then Lock;
  try
    Result := FRole;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.GetSavePassword :Boolean;
begin
  if Assigned(FLock) then Lock;
  try
    Result := FSavePassword;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.GetUserName :string;
begin
  if Assigned(FLock) then Lock;
  try
    Result := FUserName;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

procedure TEVSDatabaseRecord.SetDatabaseName(aValue :String);
begin
  if Assigned(FLock) then Lock;
  try
    if FDatabaseName=aValue then Exit;
    FDatabaseName:=aValue;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

procedure TEVSDatabaseRecord.SetDeleted(aValue :Boolean);
begin
  if FDeleted=aValue then Exit;
  FDeleted:=aValue;
end;

procedure TEVSDatabaseRecord.SetHostName(aValue :String);
var
  vHost:string;
begin
  if Assigned(FLock)  then Lock;
  try
    vHost := GetServerName(FDatabaseName);
    if vHost <> '' then FDatabaseName :=  StringReplace(FDatabaseName,vHost,aValue,[rfReplaceAll])
    else FDatabaseName := aValue+':'+FDatabaseName;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

procedure TEVSDatabaseRecord.SetLastOpened(aValue :TDatetime);
begin
  if FLastOpened=aValue then Exit;
  FLastOpened:=aValue;
end;

procedure TEVSDatabaseRecord.SetPassword(aValue :string);
begin
  if Assigned(FLock)  then Lock;
  try
    FPassword := aValue;
  finally
    if Assigned(FLock)  then UnLock;
  end;
end;

procedure TEVSDatabaseRecord.SetRole(aValue :string);
begin
  if Assigned(FLock)  then Lock;
  try
    if FRole=aValue then Exit;
    FRole:=aValue;
  finally
    if Assigned(FLock)  then UnLock;
  end;
end;

procedure TEVSDatabaseRecord.SetSavePassword(aValue :Boolean);
begin
  if FSavePassword=aValue then Exit;
  FSavePassword:=aValue;
end;

procedure TEVSDatabaseRecord.SetUserName(aValue :string);
begin
  if Assigned(FLock)  then Lock;
  try
    if FUserName=aValue then Exit;
    FUserName:=aValue;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEVSDatabaseRecord.AsDBDetails :TDBDetails;
begin
  Result.UserName     := UserName;
  Result.DatabaseName := DatabaseName;
  Result.Charset      := Charset;
  Result.Password     := Password;
  Result.Role         := Role;
  Result.LastOpened   := LastOpened;
  Result.Deleted      := Deleted;
  Result.SavePassword := SavePassword;
end;

constructor TEVSDatabaseRecord.Create;
begin
  inherited Create;
  CreateGUID(FID);
end;
{$ENDREGION}

{$REGION ' TDBSession '}

procedure TEvsDBSession.SetConnection(aValue :TMDODataBase);
begin
  if Assigned(FLock) then Lock;
  try
    if FConnection = aValue then Exit;
    FConnection := aValue;
  finally
    if Assigned(FLock) then UnLock;
  end;
end;

function TEvsDBSession.GetConnection :TMDODataBase;
begin

end;

function TEvsDBSession.GetTransaction :TMDOTransaction;
begin

end;

procedure TEvsDBSession.SetTransaction(aValue :TMDOTransaction);
begin
  if FTransaction=aValue then Exit;
  FTransaction:=aValue;
end;

function TEvsDBSession.AsDBInfo :TDBInfo;
begin
  Result.Conn       := FConnection;
  Result.Trans      := FTransaction;
  Result.Index      := FIndex;
  Result.RegRec     := AsDBDetails;
  Result.OrigRegRec := FBackupData;
end;

function TEvsDBSession.Original :TDBDetails;
begin
  Result := FBackupData;
end;

procedure TEvsDBSession.Backup;
begin
  FBackupData := AsDBDetails;
end;

{$ENDREGION}

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

function TDBRegistry.GetCount :Integer;
begin
  Result := FData.Count;
end;

function TDBRegistry.GetDBConnection(aIndex :integer) :TMDODataBase;
begin
  CheckIndex(aIndex);
  Result := FDBData[aIndex].Conn;
end;

function TDBRegistry.GetDBRec(aIndex :Integer) :TDBInfo;
begin
  CheckIndex(aIndex);
  Result := FDBData[aIndex];
end;

function TDBRegistry.GetDBRegistration(aIndex :Integer) :TDBDetails;
begin
  CheckIndex(aIndex);
  Result := FDBData[aIndex].RegRec;
end;

function TDBRegistry.GetDBTransaction(aIndex :Integer) :TMDOTransaction;
begin
  CheckIndex(aIndex);
  Result := FDBData[aIndex].Trans;
end;

//function TDBRegistry.GetRecords(aIndex :Integer) :TEvsDBSession;
//begin
//  //CheckIndex(Index);
//  Result := TEvsDBSession(FData[Index]);
//end;

procedure TDBRegistry.SetCapacity(aNewCapacity :Integer);
begin
  If (aNewCapacity < Count) or (aNewCapacity > MaxListSize) then Error(sListCapacity,aNewCapacity);
  SetLength(FDBData, aNewCapacity);
  FData.Capacity := aNewCapacity;
  FCapacity := aNewCapacity;
end;

procedure TDBRegistry.CheckIndex(aIndex :Integer);
begin
  if (aIndex<0) or (aIndex >= Count) then raise EDBRegistry.CreateFmt('Index is out of bounds %D',[aIndex]);
end;

procedure TDBRegistry.SaveDBInfo(const aDBRec :TDBDetails; const aStream :TStream);
begin
  //make sure that the position of the stream is on the start of the record.
  aStream.Write(aDBRec, SizeOf(TDBDetails));//change it to a dynamic sized record.
end;

procedure TDBRegistry.LoadDBInfo(var aDBRec :TDBDetails; const aStream :TStream; aID:Word);
begin
  aStream.Read(aDBRec, SizeOf(TDBDetails));
  // if endian is not correct then swap endian for the required fields, short string being ascii will not
  // need to swap, boolean is safe too, the datetime needs testing. If I could only find a big endian
  // VM for testing.
end;

procedure TDBRegistry.CleanupData;
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

class procedure TDBRegistry.Error(const Msg :string; Data :PtrInt);
begin
  raise EDBRegistry.CreateFmt(Msg,[Data]) at get_caller_addr(get_frame);
end;

class Function TDBRegistry.IsValidRegistryFile(const aFileName :String) :Boolean;
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

constructor TDBRegistry.Create;
begin
  inherited Create;;
  FData := TList.Create;
end;

destructor TDBRegistry.Destroy;
begin
  CleanupData;
  FData.Free;
  inherited Destroy;
end;

function TDBRegistry.IndexOf(const aDatabaseName :string) :Integer;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to Count -1 do
    if CompareText(Session[vCntr]^.RegRec.DatabaseName,aDatabaseName) = 0 then exit(vCntr);
end;

function TDBRegistry.IndexOf(const aDBInfo :TDBInfo) :Integer;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to Count -1 do
    if ((Session[vCntr]^.Conn = aDBInfo.Conn) and (Session[vCntr]^.Trans = aDBInfo.Trans)) then exit(vCntr);
end;

function TDBRegistry.GetSession(aIndex :Integer) :PDBInfo;
begin
  Result := PDBInfo(FData[aIndex]);
end;

procedure TDBRegistry.SetDBRegistration(aIndex :Integer; aValue :TDBDetails);
begin
  CheckIndex(aIndex);
  FDBData[aIndex].RegRec := aValue;
end;

procedure TDBRegistry.SetDBConnection(aIndex :integer; aValue :TMDODataBase);
begin
  FDBData[aIndex].Conn := aValue;
end;

procedure TDBRegistry.SetDBRec(const aIndex :Integer; const aValue :TDBInfo);
begin
  //CheckIndex(aIndex);
  PDBInfo(FData[aIndex])^ := aValue;
end;

procedure TDBRegistry.SetDBTransaction(aIndex :Integer; aValue :TMDOTransaction);
begin
  CheckIndex(aIndex);
  FDBData[aIndex].Trans := aValue;
end;

procedure TDBRegistry.SetSession(aIndex :Integer; aValue :PDBInfo);
begin
  FData[aIndex] := aValue;
end;

procedure TDBRegistry.SaveTo(const aStream :TStream);
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

procedure TDBRegistry.LoadFrom(const aStream :TStream);
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
    if not vDbInfo^.RegRec.Deleted then begin
      vDbInfo^.OrigRegRec := vDbInfo^.RegRec;
      vDbInfo^.Index := vIdx;
      FData.Add(vDbInfo);
      vDbInfo := Nil;
    end;
    Dec(vCnt);
  until (vCnt <= 0) or  EOF(aStream);
end;

procedure TDBRegistry.SaveTo(const aFileName :string);
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

procedure TDBRegistry.LoadFrom(const aFileName :string);
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

procedure TDBRegistry.Append(aValue :TDBinfo);
var
  vDBInfo :PDBInfo;
begin
  vDBInfo := New(PDBInfo);
  vDBInfo^ := aValue;
  FData.Add(vDBInfo);
  //if FCapacity <= FCount then SetCapacity(FCapacity+10);
  //FDBData[FCount] := aValue;
  //Inc(FCount);
end;

procedure TDBRegistry.Delete(aIndex :Integer);
//var
//  vCntr :Integer;
begin
  //CheckIndex(aIndex);
  //for vCntr := FCount -2 downto aIndex do begin
  //  FDBData[vCntr] := FDBData[vCntr+1];
  //end;
  //Dec(FCount);
  FData.Delete(aIndex);
end;

{$ENDREGION}

initialization
  DatabaseRegistry := TDBRegistry.Create;
finalization
  DatabaseRegistry.Free;
end.


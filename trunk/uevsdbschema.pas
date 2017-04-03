unit uEvsDBSchema;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uTBTypes, turbocommon;
type
  TEvsDBState  = (dbsChanged, dbsData, dbsMetadata);
  TEvsDBStates = set of TEvsDBState;
  TEvsSortOrder = (orUnSupported, orAscending, orDescending);
  TEvsTriggerType = (trBefore, trAfter);
  TEvsTriggerEvent = (teInsert, teUpdate, teDelete);

  IEvsTableInfo = interface;//forward declaration.

  { TEvsDBInfo }

  IEvsObjectRef = interface(IInterface) ['{06704B77-F3A4-4CAA-9E8A-6E13AD70EA07}']
    function ObjectRef:TObject;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
  end;

  IEvsObjectState = interface(IInterface)
    function GetStates :TEvsDBStates;
    Property ObjectState:TEvsDBStates read GetStates;// write SetStates;
  end;
  TEvsDBInfo = class(TPersistent, IInterface, IEvsObjectRef, IEvsObjectState)
  private
    FOwner        : TEvsDBInfo;
    FRefCount     : Integer;
    FRefCounted   : Boolean;
    FUpdateCount  : Integer;
    FUpdateStates : TEvsDBStates;
    function GetStates :TEvsDBStates;
  protected
    function ObjectRef:TObject;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure IncludeUpdateFlags(const aState:TEvsDBStates);
    procedure UpdateFlags;
    property UpdateStates:TEvsDBStates read FUpdateStates;
  public
    constructor Create(aOwner:TEvsDBInfo; aRefCounted:Boolean{=True});virtual;
    function QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    function _AddRef: Integer; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    function _Release: Integer; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    class function NewInstance: TObject; override;

    property ObjectState:TEvsDBStates read GetStates;
  end;

  { IEvsObjectState }

  { IEvsUDFInfo }

  IEvsUDFInfo = interface(IInterface){$MESSAGE WARN 'Needs implementation'}
    ['{729DBB89-2B77-48CA-82F3-888591B8E47A}']
    function GetName :WideString;
    procedure SetName(aValue :WideString);
    property Name:WideString read GetName write SetName;
  end;

  { IEvsFieldInfo }
  IEvsFieldInfo = interface(IInterface) ['{1D1C2E18-593E-44D4-8020-DA88FE3C8E60}']
    function GetAllowNull :ByteBool;
    function GetAutoNumber :ByteBool;
    function GetCalculated :widestring;
    function GetCanAutoInc :WordBool;
    function GetCharset :widestring;
    function GetCheck :widestring;
    function GetColation :widestring;
    function GetDataTypeName :widestring;
    function GetDefaultValue :Variant;
    procedure SetDefaultValue(aValue :Variant);
    function GetFieldDescription :widestring;
    function GetFieldName :widestring;
    function GetFieldScale :Integer;
    procedure SetFieldScale(aValue :Integer);
    function GetFieldSize :Integer;
    procedure SetFieldSize(aValue :Integer);
    procedure SetAllowNull(aValue :ByteBool);
    procedure SetAutoNumber(aValue :ByteBool);
    procedure SetCalculated(aValue :widestring);
    procedure SetCharset(aValue :widestring);
    procedure SetCheck(aValue :widestring);
    procedure SetColation(aValue :widestring);
    procedure SetDataTypeName(aValue :widestring);
    procedure SetFieldDescription(aValue :widestring);
    procedure SetFieldName(aValue :widestring);
    property AllowNulls   : ByteBool   read GetAllowNull        write SetAllowNull  default True;
    property AutoNumber   : ByteBool   read GetAutoNumber       write SetAutoNumber default False;
    property Calculated   : widestring read GetCalculated       write SetCalculated;
    property Collation    : widestring read GetColation         write SetColation;
    property DataTypeName : widestring read GetDataTypeName     write SetDataTypeName;
    property DefaultValue : Variant    read GetDefaultValue     write SetDefaultValue;
    property Description  : widestring read GetFieldDescription write SetFieldDescription;
    property FieldName    : widestring read GetFieldName        write SetFieldName;
    property FieldScale   : Integer    read GetFieldScale       write SetFieldScale;
    property FieldSize    : Integer    read GetFieldSize        write SetFieldSize;
    property Charset      : widestring read GetCharset          write SetCharset;
    property Check        : widestring read GetCheck            write SetCheck;
  end;


  //IEvsConstrainInfo = interface(IInterface)
  //  ['{F938D5FC-A6CC-4EDC-9D84-0184B743C119}']
  //end;

  { IEvsTriggerInfo }

  IEvsTriggerInfo = interface(IInterface)
    ['{79248B35-ECC2-4746-8C17-5EC93E990081}']
    function GetEvent :TEvsTriggerEvent;
    function GetEventType :TEvsTriggerType;
    function GetSQL :WideString;
    function GetTriggerDescription :WideString;
    function GetTriggerName :WideString;
    procedure SetEvent(aValue :TEvsTriggerEvent);
    procedure SetEventType(aValue :TEvsTriggerType);
    procedure SetSQL(aValue :WideString);
    procedure SetTriggerDscription(aValue :WideString);
    procedure SetTriggerName(aValue :WideString);

    property Name:WideString read GetTriggerName write SetTriggerName;
    property Description:WideString read GetTriggerDescription write SetTriggerDscription;
    property SQL : WideString read GetSQL write SetSQL; //the DDL command no partial commands here.
    property Event: TEvsTriggerEvent read GetEvent write SetEvent;
    property TriggerType:TEvsTriggerType read GetEventType write SetEventType;
  end;

  { IEvsIndexInfo }

  IEvsIndexInfo = interface(IInterface)
    ['{FEA79D55-B1CF-4A24-8CE6-A9EBEB769C3C}']
    function GetField(aIndex :Integer) :IEvsFieldInfo;
    function GetIndexName : WideString;
    function GetOrder :TEvsSortOrder;
    function GetFieldOrder(aIndex :Integer) :TEvsSortOrder;
    function GetPrimary :ByteBool;
    function GetTable :IEvsTableInfo;
    function GetUnique :ByteBool;
    procedure SetIndexName(const aValue: WideString);
    procedure SetOrder(const aValue: TEvsSortOrder);
    procedure SetPrimary(aValue :ByteBool);
    procedure SetTable(aValue :IEvsTableInfo);
    procedure SetUnique(aValue :ByteBool);

    procedure SwapFields(const aIndex1,aIndex2:Integer);
    procedure AppendField(const aField:IEvsFieldInfo; const aOrder: TEvsSortOrder);
    procedure DeleteField(const aIndex : Integer);overload;
    procedure DeleteField(const aField : IEvsFieldInfo);overload;
    procedure ClearFields;
    function GetFieldCount:Integer;

    property IndexName:WideString read GetIndexName write SetIndexName;
    property Unique:ByteBool read GetUnique write SetUnique;
    property Primary:ByteBool read GetPrimary write SetPrimary;
    property Order : TEvsSortOrder read GetOrder write SetOrder default orUnsupported;
    property FieldCount:Integer read GetfieldCount;
    property Field[aIndex:Integer]:IEvsFieldInfo read GetField;
    property FieldOrder[aIndex:Integer]:TEvsSortOrder read GetFieldOrder;
    property Table :IEvsTableInfo read GetTable write SetTable;
  end;

  { IEvsTableInfo }

  IEvsTableInfo = interface(IInterface) ['{35EA6385-3C4F-4EAA-ACB8-CCF92227BAD0}']
    function GetCharset :WideString;
    function GetCollation :WideString;
    function GetDescription :wideString;
    function GetField(aIndex :Integer) :IEvsFieldInfo;
    function GetFieldCount :Integer;
    function GetIndex(aIndex :Integer) :IEvsIndexInfo;
    function GetIndexCount :integer;
    function GetTableName :WideString;
    procedure SetCharSet(aValue :WideString);
    procedure SetCollation(aValue :WideString);
    procedure SetDescription(aValue :wideString);
    procedure SetField(aIndex :Integer; aValue :IEvsFieldInfo);
    procedure SetIndex(aIndex :Integer; aValue :IEvsIndexInfo);
    procedure SetTableName(aValue :WideString);

    //property SchemaName           :WideString          read GetSchemaName       write SetSchemaName;
    //property FullTableName        :WideString          read GetFullName;
    function AddField(constref aFieldName, aDataType:WideString; constref aFieldsIze,aFieldScale:Integer;
                      constref aCharset, aCollation :WideString; constref AllowNulls, AutoNumber:ByteBool):IEvsFieldInfo;
    Function AddIndex(constref aName:widestring; constref aFields:Array of IEvsFieldInfo; constref aFieldOrders:array of TEvsSortOrder):IEvsIndexInfo;
    Function AddIndex(constref aName:widestring; constref aFieldNamess:Array of WideString; constref aFieldOrders:array of TEvsSortOrder):IEvsIndexInfo;
    property TableName  : WideString read GetTableName   write SetTableName;
    property Description: WideString read GetDescription write SetDescription;
    property CharSet    : WideString read GetCharset     write SetCharSet;
    property Collation  : WideString read GetCollation   write SetCollation; // probably will not keep it.

    property FieldCount :Integer     read GetFieldCount;
    property IndexCount :integer     read GetIndexCount;
    property Index[aIndex:Integer]:IEvsIndexInfo read GetIndex write SetIndex;
    property Field[aIndex:Integer]:IEvsFieldInfo read GetField write SetField;
  end;

  { IEvsStoredInfo }

  IEvsStoredInfo = interface(IInterface) ['{71B2F8CE-35C9-4139-BFF5-9EDE5DD8C1D7}']
    function GetField(aIndex :Integer) :IEvsFieldInfo;
    function GetFieldCount :integer;
    function GetSPName :WideString;
    function GetSql :WideString;
    procedure SetField(aIndex :Integer; aValue :IEvsFieldInfo);
    procedure SetSPName(aValue :WideString);
    procedure SetSql(aValue :WideString);

    property ProcedureName:WideString read GetSPName write SetSPName;
    property Fields[aIndex:Integer]:IEvsFieldInfo read GetField write SetField; // the fields returned by the stored procedure. do i need then?
    property FieldCount:integer read GetFieldCount;
    property SQL:WideString read GetSql write SetSql;
  end;

  { IEvsGeneratorInfo }

  IEvsGeneratorInfo = interface(IInterface)
    function GetCurrentValue :Int64;
    function GetGeneratorName :widestring;
    procedure SetCurrentValue(aValue :Int64);
    procedure SetGeneratorName(aValue :widestring);
    property GeneratorName:widestring read GetGeneratorName write SetGeneratorName;
    property CurrentValue:Int64 read GetCurrentValue write SetCurrentValue;
  end;
  { IEvsExceptionInfo }

  IEvsExceptionInfo = interface(IInterface)
    ['{673B1042-D702-4899-B8E9-3AA779087E72}']
    function GetDescription :widestring;
    function GetMessage :WideString;
    function GetName :WideString;
    function GetNumber :WideString;
    function GetSystem :ByteBool;
    procedure SetDescription(aValue :widestring);
    procedure SetMessage(aValue :WideString);
    procedure SetName(aValue :WideString);
    procedure SetNumber(aValue :WideString);
    procedure SetSystem(aValue :ByteBool);

    property Name:WideString read GetName write SetName;
    property Description:widestring read GetDescription write SetDescription;
    property Number:WideString read GetNumber write SetNumber;
    property Message:WideString read GetMessage write SetMessage;
    property System:ByteBool read GetSystem write SetSystem;
  end;

  { IEvsSequenceInfo }

  IEvsSequenceInfo = interface(IInterface)
    ['{C9FDA097-C9E3-4A1C-ADB0-89936B83C601}']
    function GetID :Integer;
    function GetName :String;
    procedure SetID(aValue :Integer);
    procedure SetName(aValue :String);
    property Name:String read GetName write SetName;
    property ID:Integer read GetID write SetID;
  end;

  { IEvsDatabaseInfo }

  IEvsDatabaseInfo = interface(IInterface) ['{29AE2670-E75A-4DBB-B7A8-7C0742A9457C}']
    function GetExceptionCount :Integer;
    function GetExceptions(aIndex :Integer) :IEvsExceptionInfo;
    function GetProcedureCount :Integer;
    function GetSequenceCount :Integer;
    function GetSequences(Aindex :Integer) :IEvsSequenceInfo;
    function GetStored(aIndex :Integer) :IEvsStoredInfo;
    function GetTable(aIndex :Integer) :IEvsTableInfo;
    function GetTableCount :Integer;
    procedure SetExceptionCount(aValue :Integer);
    procedure SetExceptions(aIndex :Integer; aValue :IEvsExceptionInfo);
    procedure SetSequenceCount(aValue :Integer);
    procedure SetSequences(Aindex :Integer; aValue :IEvsSequenceInfo);
    procedure SetStored(aIndex :Integer; aValue :IEvsStoredInfo);
    procedure SetTable(aIndex :Integer; aValue :IEvsTableInfo);

    property Table[aIndex:Integer]:IEvsTableInfo read GetTable write SetTable;
    property TableCount:Integer read GetTableCount;
    property Procedures[aIndex:Integer]:IEvsStoredInfo read GetStored write SetStored;
    property ProcedureCount:Integer read GetProcedureCount;
    property Exceptions[aIndex:Integer]:IEvsExceptionInfo read GetExceptions write SetExceptions;
    property ExceptionCount:Integer read GetExceptionCount write SetExceptionCount;
    property Sequences[Aindex:Integer]:IEvsSequenceInfo read GetSequences write SetSequences;
    property SequenceCount:Integer read GetSequenceCount write SetSequenceCount;
  end;

function NewField(constref aOwner:TEvsDBInfo; constref aName:widestring=''; constref aDatatype:Widestring='';
                  constref aSize:integer = 0) : IEvsFieldInfo;
function NewTable(Constref aOwner:TEvsDBInfo; constref aTableName:widestring; constref aDescription:widestring = ''):IEvsTableInfo;

implementation
type

  { TEvsFieldInfo }

  TEvsFieldInfo = class(TEvsDBInfo, IEvsFieldInfo)
  private
    FFieldName    : widestring;
    FDescription  : widestring;
    FAllowNulls   : ByteBool;
    FDataTypeName : widestring;
    FDefaultValue : Variant;
    FAutoNumber   : ByteBool;
    FFieldSize    : integer;
    FFieldScale   : Integer;
    FCollation    : widestring;
    FCharset      : widestring;
    FCheck        : widestring;
    FCalculated   : widestring;
    function GetAllowNull :ByteBool;
    function GetAutoNumber :ByteBool;
    function GetCalculated :widestring;
    function GetCanAutoInc :WordBool;
    function GetCharset :widestring;
    function GetCheck :widestring;
    function GetColation :widestring;
    function GetDataTypeName :widestring;
    function GetDefaultValue :Variant;
    function GetFieldDescription :widestring;
    function GetFieldName :widestring;
    function GetFieldScale :Integer;
    function GetFieldSize :integer;
    procedure SetAllowNull(aValue :ByteBool);
    procedure SetAutoNumber(aValue :ByteBool);
    procedure SetCalculated(aValue :widestring);
    procedure SetCharset(aValue :widestring);
    procedure SetCheck(aValue :widestring);
    procedure SetColation(aValue :widestring);
    //procedure SetDataType(aValue :widestring);
    procedure SetDataTypeName(aValue :widestring);
    procedure SetDefaultValue(aValue :Variant);
    procedure SetFieldDescription(aValue :widestring);
    procedure SetFieldName(aValue :widestring);
    procedure SetFieldScale(aValue :Integer);
    procedure SetFieldSize(aValue :integer);
  published
    property FieldName    : widestring read GetFieldName write SetFieldName;
    property Description  : widestring read GetFieldDescription write SetFieldDescription;
    property AllowNulls   : ByteBool           read GetAllowNull    write SetAllowNull default True;
    property DataTypeName : widestring         read GetDataTypeName write SetDataTypeName;
    property DefaultValue : Variant            read GetDefaultValue write SetDefaultValue;
    property AutoNumber   : ByteBool           read GetAutoNumber   write SetAutoNumber default False;
    property FieldSize    : integer            read GetFieldSize    write SetFieldSize;
    property FieldScale   : Integer            read GetFieldScale   write SetFieldScale;
    property Collation    : widestring         read GetColation     write SetColation;
    property Charset      : widestring         read GetCharset      write SetCharset;
    property Check        : widestring         read GetCheck        write SetCheck;
    property Calculated   : widestring         read GetCalculated   write SetCalculated;
  end;

  { IEvsIndexFieldInfo }

  IEvsIndexFieldInfo = Interface(IInterface)
    ['{92E4FCFA-8199-4476-869F-2F3D007AE9DE}']
    function GetField :IEvsFieldInfo;
    function GetOrder :TEvsSortOrder;
    procedure SetField(aValue :IEvsFieldInfo);
    procedure SetOrder(aValue :TEvsSortOrder);
    property Field: IEvsFieldInfo read GetField write SetField;
    property Order: TEvsSortOrder read GetOrder write SetOrder;
  end;

  { TEvsIndexFieldInfo }

  TEvsIndexFieldInfo = class(TEvsDBInfo, IEvsIndexFieldInfo)
  private
    FField :IEvsFieldInfo;
    FOrder :TEvsSortOrder;
    function GetField :IEvsFieldInfo;
    function GetOrder :TEvsSortOrder;
    procedure SetField(aValue :IEvsFieldInfo);
    procedure SetOrder(aValue :TEvsSortOrder);
  published
    property Field :IEvsFieldInfo read GetField write SetField;
    property Order :TEvsSortOrder read GetOrder write SetOrder;
  end;

  { TEvsIndexInfo }

  TEvsIndexInfo = class(TEvsDBInfo, IEvsIndexInfo)
  private
    //FTable      : TEVSDBTableInfo;
    FList       : TInterfaceList;
    FUnique     : Boolean;
    FPrimary    : Boolean;
    FOrder      : TEvsSortOrder;
    FIndexName  : Widestring;
    FDescription: WideString;
    function GetDescription :widestring;
    function GetField(aIndex: Integer): IEvsFieldInfo;
    function GetFieldCount: Integer;
    function GetFieldOrder(aIndex: Integer): TEvsSortOrder;
    function GetIndexName : WideString;
    function GetOrder :TEvsSortOrder;
    function GetPrimary :ByteBool;
    function GetTable :IEvsTableInfo;
    function GetUnique :ByteBool;
    procedure SetDescription(aValue :widestring);
    procedure SetField(Index: Integer; const Value: IEvsFieldInfo);
    procedure SetFieldOrder(Index: Integer; const Value: TEvsSortOrder);
    procedure SetIndexName(const aValue: WideString);
    procedure SetOrder(const aValue: TEvsSortOrder);
    procedure SetPrimary(aValue: ByteBool);
    procedure SetTable(aValue :IEvsTableInfo);
    procedure SetUnique(aValue: ByteBool);

    //function GetTable: TEVSDBTableInfo;
    //procedure SetTable(const Value: TEVSDBTableInfo);
  protected
    //property Table : IEVSDBTableInfo read GetTable write SetTable;
    //procedure LinkFields(const aTable:TEVSDBTableInfo);
    //procedure Initialize;override;

    //procedure DefineProperties(Filer:TFiler);override;
    //procedure ReadIndexName(Reader:TReader);
    //procedure WriteIndexName(Writer:TWriter);
    //procedure ReadPrimary(Reader:TReader);
    //procedure WritePrimary(Writer:TWriter);
    //procedure ReadUnique(Reader:TReader);
    //procedure WriteUnique(Writer:TWriter);
    //procedure ReadIndexOrder(Reader:TReader);
    //procedure WriteIndexOrder(Writer:TWriter);
    //procedure ReadCount(Reader:TReader);
    //procedure WriteCount(Writer:TWriter);

    //procedure ReadFieldList(Reader:TReader);
    //procedure WriteFieldList(Writer:TWriter);
    function IndexOf(const aField:IEvsFieldInfo):integer;
    function IndexOf(const aFieldName:string):Integer;overload;
    //function IndexOf(const FieldID:TGUID):Integer;overload;
  public
    constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    function TableName :string;
    //function GetEnumerator: TEVSDBIndexInfoEnumerator;
    //function IterateFields: TEVSDBIndexFieldEnumerator;

    //procedure AssignProperties(Source : TEVSDBBaseInfo); override;
    //procedure Assign(Source : TPersistent); override;
    //procedure SaveToStream(const aStream:TStream);override;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    //procedure LoadFromStream(const aStream:TStream);override;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};

    procedure SwapFields(const Index1,Index2:Integer);
    procedure AppendField(const aField:IEVSFieldInfo; const aOrder: TEvsSortOrder);
    procedure DeleteField(const aIndex : Integer);overload;
    procedure DeleteField(const aField:IEvsFieldInfo);overload;
    procedure ClearFields;
    //function FieldByName(const FieldName:string):TEVSDBFieldInfo;

    property IndexName:widestring read GetIndexName write SetIndexName;
    property Description:widestring read GetDescription write SetDescription;
    property Unique:ByteBool read GetUnique write SetUnique;
    property Primary:ByteBool read GetPrimary write SetPrimary;
    property Order : TEvsSortOrder read GetOrder write SetOrder default orUnsupported;

    property FieldCount : Integer read GetFieldCount;
    property Field[Index:Integer] : IEvsFieldInfo read GetField write SetField;
    property FieldOrder[Index:Integer]:TEvsSortOrder read GetFieldOrder write SetFieldOrder;
    property Table :IEvsTableInfo read GetTable write SetTable;
  end;

  { TEvsTableInfo }

  TEvsTableInfo = class(TEvsDBInfo, IEvsTableInfo)
  private
    FCharset :WideString;
    FCollation :WideString;
    FDescription :WideString;
    FFieldList : TInterfaceList;
    FIndexList : TInterfaceList;
    FTriggerList:TInterfaceList;
    FTableName :WideString;
    function GetCharset :WideString;
    function GetCollation :WideString;
    function GetDescription :wideString;
    function GetField(aIndex :Integer) :IEvsFieldInfo;
    function GetFieldCount :Integer;
    function GetIndex(aIndex :Integer) :IEvsIndexInfo;
    function GetIndexCount :integer;
    function GetTableName :WideString;
    procedure SetCharSet(aValue :WideString);
    procedure SetCollation(aValue :WideString);
    procedure SetDescription(aValue :wideString);
    procedure SetField(aIndex :Integer; aValue :IEvsFieldInfo);
    procedure SetIndex(aIndex :Integer; aValue :IEvsIndexInfo);
    procedure SetTableName(aValue :WideString);
    //what other data does a table have.
    //triggers?
    //property SchemaName           :WideString          read GetSchemaName       write SetSchemaName;
    //property FullTableName        :WideString          read GetFullName;
  protected
    function FieldIndexOf(constref aName:Widestring):Integer;
    function FieldIndexOf(constref aField:IEvsFieldInfo):Integer;
    function FieldByName(Const aFieldName:WideString):IEvsFieldInfo;
  public
    function AddField(constref aFieldName, aDataType :WideString; constref aFieldsIze, aFieldScale :Integer; constref aCharset, aCollation :WideString;
      constref AllowNulls, AutoNumber :ByteBool) :IEvsFieldInfo;
    Function AddIndex(constref aName:widestring; constref aFields:Array of IEvsFieldInfo; constref aFieldOrders:array of TEvsSortOrder):IEvsIndexInfo;
    Function AddIndex(constref aName:widestring; constref aFieldNames:Array of WideString; constref aFieldOrders:array of TEvsSortOrder):IEvsIndexInfo;

    property TableName  : WideString read GetTableName   write SetTableName;
    property Description: WideString read GetDescription write SetDescription;
    property CharSet    : WideString read GetCharset     write SetCharSet;
    property Collation  : WideString read GetCollation   write SetCollation; // default collation for the table it will be used when creating string fields with no collation information.

    property FieldCount :Integer read GetFieldCount;
    property IndexCount :integer read GetIndexCount;
    property Index[aIndex:Integer]:IEvsIndexInfo read GetIndex write SetIndex;
    property Field[aIndex:Integer]:IEvsFieldInfo read GetField write SetField; default;
  end;


  { TEvsDabaseInfo }

  TEvsDabaseInfo = class(TevsDBInfo, IEvsDatabaseInfo)
  private
    FStoredProcs : TInterfaceList;
    FTables      : TInterfaceList;
  protected
    function GetStored(aIndex :Integer) :IEvsStoredInfo;
    function GetTable(aIndex :Integer) :IEvsTableInfo;
    function GetTableCount :Integer;
    procedure SetStored(aIndex :Integer; aValue :IEvsStoredInfo);
    procedure SetTable(aIndex :Integer; aValue :IEvsTableInfo);
  public
    constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;

    function GetProcedureCount :Integer;
    property Table[aIndex:Integer]:IEvsTableInfo read GetTable write SetTable;
    property TableCount:Integer read GetTableCount;
    property Procedures[aIndex:Integer]:IEvsStoredInfo read GetStored write SetSTored;
  end;

function NewField(constref aOwner:TEvsDBInfo; constref aName:widestring=''; constref aDatatype:Widestring='';
                  constref aSize:integer = 0) : IEvsFieldInfo;
begin
  Result := TEvsFieldInfo.Create(aOwner, True);
  Result.FieldName := aName;
  Result.DataTypeName := aDatatype;
  Result.FieldSize := aSize;
end;

function NewTable(Constref aOwner :TEvsDBInfo; constref aTableName :widestring; constref aDescription :widestring) :IEvsTableInfo;
begin
  Result := TEvsTableInfo.Create(aOwner,True);
  Result.TableName := aTableName;
  Result.Description := aDescription;
end;

function NewIndexField(constref aOwner:TEvsDBInfo; aField:IEvsFieldInfo; aOrder:TEvsSortOrder):IEvsIndexFieldInfo;
begin
  Result := TEvsIndexFieldInfo.Create(aOwner, True);
  Result.Field := aField;
  Result.Order := aOrder;
end;

{$Region ' TEvsDabaseInfo '}

function TEvsDabaseInfo.GetStored(aIndex :Integer) :IEvsStoredInfo;
begin
  Result := (FStoredProcs[aIndex] as IEvsStoredInfo);
end;

function TEvsDabaseInfo.GetTable(aIndex :Integer) :IEvsTableInfo;
begin
  Result := (FTables[aIndex] as IEvsTableInfo);
end;

function TEvsDabaseInfo.GetTableCount :Integer;
begin
  Result := FTables.Count;
end;

procedure TEvsDabaseInfo.SetStored(aIndex :Integer; aValue :IEvsStoredInfo);
begin
  FStoredProcs[aIndex] := aValue;
end;

procedure TEvsDabaseInfo.SetTable(aIndex :Integer; aValue :IEvsTableInfo);
begin
  FTables[aIndex] := aValue;
end;

constructor TEvsDabaseInfo.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FStoredProcs := TInterfaceList.Create;
  FTables      := TInterfaceList.Create;
end;

function TEvsDabaseInfo.GetProcedureCount :Integer;
begin
  Result := FStoredProcs.Count;
end;


{$ENDREGION}

{$Region ' TEvsTableInfo '}
function TEvsTableInfo.GetCharset :WideString;
begin
  Result := FCharset;
end;

function TEvsTableInfo.GetCollation :WideString;
begin
  Result := FCollation;
end;

function TEvsTableInfo.GetDescription :wideString;
begin
  Result := FDescription;
end;

function TEvsTableInfo.GetField(aIndex :Integer) :IEvsFieldInfo;
begin
  Result := (FFieldList[aIndex] as IEvsFieldInfo);
end;

function TEvsTableInfo.GetFieldCount :Integer;
begin
  Result := FFieldList.Count;
end;

function TEvsTableInfo.GetIndex(aIndex :Integer) :IEvsIndexInfo;
begin
  Result:= FIndexList[aIndex] as IEvsIndexInfo;
end;

function TEvsTableInfo.GetIndexCount :integer;
begin
  Result := FIndexList.Count;
end;

function TEvsTableInfo.GetTableName :WideString;
begin
  Result := FTableName;
end;

procedure TEvsTableInfo.SetCharSet(aValue :WideString);
begin
  if CompareText(FCharset,aValue)<>0 then begin
    FCharset := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetaData]);
  end;
end;

procedure TEvsTableInfo.SetCollation(aValue :WideString);
begin
  if CompareText(FCollation,aValue)<>0 then begin
    FCollation := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetaData]);
  end;
end;

procedure TEvsTableInfo.SetDescription(aValue :wideString);
begin
  if CompareText(FDescription,aValue)<>0 then begin
    FDescription := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetaData]);
  end;
end;

procedure TEvsTableInfo.SetField(aIndex :Integer; aValue :IEvsFieldInfo);
begin
  if FFieldList[aIndex] <> aValue then begin
    FFieldList[aIndex] := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

procedure TEvsTableInfo.SetIndex(aIndex :Integer; aValue :IEvsIndexInfo);
begin
  if (FIndexList[aIndex] <> aValue) then begin
    FIndexList[aIndex] :=  aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetaData]);
  end;
end;

procedure TEvsTableInfo.SetTableName(aValue :WideString);
begin
  if CompareText(FTableName,aValue)<>0 then begin
    FTableName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

function TEvsTableInfo.FieldIndexOf(constref aName :Widestring) :Integer;
var
  vCntr:Integer;
begin
  Result := -1;
  for vCntr := 0 to FFieldList.Count -1 do begin
    if CompareText(aName,(FFieldList[vCntr] as IEvsFieldInfo).FieldName) = 0 then Exit(vCntr);
  end;
end;

function TEvsTableInfo.FieldIndexOf(constref aField :IEvsFieldInfo) :Integer;
var
  vCntr:Integer;
begin
  Result := -1;
  for vCntr := 0 to FFieldList.Count -1 do begin
    if aField = (FFieldList[vCntr] as IEvsFieldInfo) then Exit(vCntr);
  end;
end;

function TEvsTableInfo.FieldByName(Const aFieldName :WideString) :IEvsFieldInfo;
var
  vIdx:Integer;
begin
  Result:=Nil;
  vIdx := FieldIndexOf(aFieldName);
  if vIdx > -1 then Result := FFieldList[vIdx] as IEvsFieldInfo;
end;

function TEvsTableInfo.AddField(constref aFieldName,aDataType :WideString; constref aFieldsIze, aFieldScale :Integer; constref aCharset,
  aCollation :WideString; constref AllowNulls, AutoNumber :ByteBool) :IEvsFieldInfo;
begin
  Result := NewField(Self, aFieldName, aDataType, aFieldsIze);
  Result.FieldScale := aFieldScale;
  Result.Charset := aCharset;
  Result.Collation := aCollation;
  Result.AllowNulls := AllowNulls;
  Result.AutoNumber := AutoNumber;
end;

Function TEvsTableInfo.AddIndex(constref aName :widestring; constref aFields :Array of IEvsFieldInfo;
                                constref aFieldOrders :array of TEvsSortOrder) :IEvsIndexInfo;
var
  vCntr :Integer;
begin
  Result := TEvsIndexInfo.Create(Self, True);
  Result.IndexName := aName;
  for vCntr := Low(aFields) to High(aFields) do begin
    if FieldIndexOf(aFields[vCntr]) > -1 then
      Result.AppendField(aFields[vCntr],aFieldOrders[vCntr])
    else raise ETBException.CreateFmt('Field %S not found in the table.', [aFields[vCntr].FieldName]);
  end;
end;

Function TEvsTableInfo.AddIndex(constref aName :widestring; constref aFieldNames :Array of WideString;
                                constref aFieldOrders :array of TEvsSortOrder) :IEvsIndexInfo;
var
  vFld:IEvsFieldInfo;
  vCntr :Integer;
begin
  Result := TEvsIndexInfo.Create(Self, True);
  Result.IndexName := aName;
  for vCntr := Low(aFieldNames) to High(aFieldNames) do begin
    if FieldIndexOf(aFieldNames[vCntr]) < 0 then
      Result.AppendField(FieldByName(aFieldNames[vCntr]),aFieldOrders[vCntr]);
  end;
end;
{$ENDREGION}

{$region ' TEvsIndexInfo '}

function TEvsIndexInfo.GetField(aIndex :Integer) :IEvsFieldInfo;
begin
  Result := (FList[aIndex] as IEvsIndexFieldInfo).Field;
end;

function TEvsIndexInfo.GetDescription :widestring;
begin
  Result := FDescription;
end;

function TEvsIndexInfo.GetFieldCount :Integer;
begin
  Result := FList.Count;
end;

function TEvsIndexInfo.GetFieldOrder(aIndex :Integer) :TEvsSortOrder;
begin
  Result := (FList[aIndex] as IEvsIndexFieldInfo).Order;
end;

function TEvsIndexInfo.GetIndexName :WideString;
begin
  Result := FIndexName;
end;

function TEvsIndexInfo.GetOrder :TEvsSortOrder;
begin
  Result := FOrder;
end;

function TEvsIndexInfo.GetPrimary :ByteBool;
begin
  Result := FPrimary;
end;

function TEvsIndexInfo.GetTable :IEvsTableInfo;
begin
  raise NotImplementedException;
end;

function TEvsIndexInfo.GetUnique :ByteBool;
begin
  Result := FUnique or FPrimary;
end;

procedure TEvsIndexInfo.SetDescription(aValue :widestring);
begin
  BeginUpdate;
  try
    FDescription := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.SetField(Index :Integer; const Value :IEvsFieldInfo);
begin
  BeginUpdate;
  try
    (FList[Index] as IEvsIndexFieldInfo).Field := Value;
    IncludeUpdateFlags([dbsChanged,dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.SetFieldOrder(Index :Integer; const Value :TEvsSortOrder);
begin
  BeginUpdate;
  try
    (FList[Index] as IEvsIndexFieldInfo).Order := Value;
    IncludeUpdateFlags([dbsChanged,dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.SetIndexName(const aValue :WideString);
begin
  if aValue <> FIndexName then begin
    FIndexName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

procedure TEvsIndexInfo.SetOrder(const aValue :TEvsSortOrder);
begin
  if aValue <> FOrder then begin
    FOrder := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

procedure TEvsIndexInfo.SetPrimary(aValue :ByteBool);
begin
  if aValue <> FPrimary then begin
    FPrimary := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

procedure TEvsIndexInfo.SetTable(aValue :IEvsTableInfo);
begin
  raise NotImplementedException;
end;

procedure TEvsIndexInfo.SetUnique(aValue :ByteBool);
begin
  if aValue <> FUnique then begin
    FUnique := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

function TEvsIndexInfo.IndexOf(const aField :IEvsFieldInfo) :integer;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to FList.Count -1 do begin
    if (FList[vCntr] as IEvsIndexFieldInfo).Field = aField then Exit(vCntr);
  end;
end;

function TEvsIndexInfo.IndexOf(const aFieldName :string) :Integer;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to FList.Count -1 do begin
    if CompareText((FList[vCntr] as IEvsIndexFieldInfo).Field.FieldName,aFieldName) = 0 then Exit(vCntr);
  end;
end;

constructor TEvsIndexInfo.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

function TEvsIndexInfo.TableName :string;
begin
  Result := '';
  //if FOwner is tevsTableInfo then Result:= tevstableinfo(fowner).TableName;
end;

procedure TEvsIndexInfo.SwapFields(const Index1, Index2 :Integer);
begin
  FList.Exchange(Index1,Index2);
end;

procedure TEvsIndexInfo.AppendField(const aField :IEVSFieldInfo; const aOrder :TEvsSortOrder);
begin
  BeginUpdate;
  try
    if IndexOf(aField.FieldName) <> -1 then raise ETBException.CreateFmt('Field %S already exists in the List.',[aField.FieldName]);
    FList.Add(NewIndexField(Self, aField, aOrder));
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.DeleteField(const aIndex :Integer);
begin
  BeginUpdate;
  try
    FList.Delete(aIndex);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.DeleteField(const aField :IEvsFieldInfo);
begin
  BeginUpdate;
  try
    FList.Delete(IndexOf(aField));
    IncludeUpdateFlags([dbschanged,dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.ClearFields;
begin
  BeginUpdate;
  try
    FList.Clear;
    IncludeUpdateFlags([dbsChanged,dbsData]);
  finally
    EndUpdate;
  end;
end;

{$ENDREGION}

{$REGION ' TEvsIndexFieldInfo '}

procedure TEvsIndexFieldInfo.SetField(aValue :IEvsFieldInfo);
begin
  if FField<>aValue then begin
    FField:=aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

function TEvsIndexFieldInfo.GetField :IEvsFieldInfo;
begin
  Result := FField;
end;

function TEvsIndexFieldInfo.GetOrder :TEvsSortOrder;
begin
  Result := FOrder;
end;

procedure TEvsIndexFieldInfo.SetOrder(aValue :TEvsSortOrder);
begin
  if FOrder=aValue then Exit;
  FOrder:=aValue;
end;

{$ENDREGION}

{$Region '  TEvsDBInfo '}

function TEvsDBInfo.GetStates :TEvsDBStates;
begin
  Result := FUpdateStates;
end;

function TEvsDBInfo.ObjectRef :TObject; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  Result := Self;
end;

procedure TEvsDBInfo.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TEvsDBInfo.EndUpdate;
begin
  Dec(FUpdateCount);
end;

procedure TEvsDBInfo.IncludeUpdateFlags(const aState :TEvsDBStates);
begin
  FUpdateStates :=  FUpdateStates + aState;
end;

procedure TEvsDBInfo.UpdateFlags;
begin
  FUpdateStates := [];
end;

constructor TEvsDBInfo.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean = False);
begin
  FRefCounted := aRefCounted;
  inherited Create;
  fOwner := aOWner;
  FUpdateCount := 0;
  FUpdateStates := [];
  FRefCounted := aRefCounted;
end;

function TEvsDBInfo.QueryInterface(constref IID: TGUID; out Obj): HResult; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TEvsDBInfo._AddRef :Integer; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  if FRefCounted  then
    Result := InterlockedIncrement(FRefCount)
  else
    Result := -1; //FRefCount;
end;

function TEvsDBInfo._Release :Integer; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  Result := -1;
  if FRefCounted then
  begin
    Result := InterlockedDecrement(FRefCount);
    if Result = 0 then
      Destroy;
  end;
end;

procedure TEvsDBInfo.AfterConstruction;
begin
  inherited AfterConstruction;
  if FRefCounted then InterlockedDecrement(FRefCount);
end;

procedure TEvsDBInfo.BeforeDestruction;
begin
  if FRefCounted and (FRefCount <> 0) then
    System.Error(reInvalidOp);
  inherited BeforeDestruction;
end;

class function TEvsDBInfo.NewInstance :TObject;
begin
  Result := inherited NewInstance;
  TEvsDBInfo(Result).FRefCount := 1;
end;


{$ENDREGION}

{$Region ' TEvsFieldInfo '}

function TEvsFieldInfo.GetAllowNull :ByteBool;
begin
  Result := FAllowNulls;
end;

function TEvsFieldInfo.GetAutoNumber :ByteBool;
begin
  Result := FAutoNumber;
end;

function TEvsFieldInfo.GetCalculated :widestring;
begin
  Result := FCalculated;
end;

function TEvsFieldInfo.GetCanAutoInc :WordBool;
begin
  Result := FAutoNumber;
end;

function TEvsFieldInfo.GetCharset :widestring;
begin
  Result := FCharset;
end;

function TEvsFieldInfo.GetCheck :widestring;
begin
  Result := FCheck;
end;

function TEvsFieldInfo.GetColation :widestring;
begin
  Result := FCollation;
end;

function TEvsFieldInfo.GetDataTypeName :widestring;
begin
  Result := FDataTypeName;
end;

function TEvsFieldInfo.GetDefaultValue :Variant;
begin
  Result := FDefaultValue;
end;

function TEvsFieldInfo.GetFieldDescription :widestring;
begin
  Result := FDescription;
end;

function TEvsFieldInfo.GetFieldName :widestring;
begin
  Result:=FFieldName;
end;

function TEvsFieldInfo.GetFieldScale :Integer;
begin
  Result:=FFieldScale;
end;

function TEvsFieldInfo.GetFieldSize :integer;
begin
  Result := FFieldSize;
end;

procedure TEvsFieldInfo.SetAllowNull(aValue :ByteBool);
begin
  if FAllowNulls <> aValue then begin
    FAllowNulls := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetAutoNumber(aValue :ByteBool);
begin
  if aValue <> FAutoNumber then begin
    FAutoNumber := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetCalculated(aValue :widestring);
begin
  if FCalculated <> aValue then begin;
    FCalculated := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetCharset(aValue :widestring);
begin
  if FCharset<>aValue then begin
    FCharset:=aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetCheck(aValue :widestring);
begin
  if FCheck<>aValue then begin
    FCheck:=aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetColation(aValue :widestring);
begin
  if FCollation<>aValue then begin
    FCollation := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetDataTypeName(aValue :widestring);
begin
  if aValue<>FDataTypeName then begin
    FDataTypeName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsdata]);
  end;
end;

procedure TEvsFieldInfo.SetDefaultValue(aValue :Variant);
begin
  if FDefaultValue <> aValue then begin
    FDefaultValue := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetFieldDescription(aValue :widestring);
begin
  if comparetext(fDescription, aValue) <> 0 then begin
    FDescription := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetFieldName(aValue :widestring);
begin
  if FFieldName <>aValue then begin
    FFieldName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

procedure TEvsFieldInfo.SetFieldScale(aValue :Integer);
begin
  if FFieldScale <> aValue then begin
    FFieldScale := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetFieldSize(aValue :integer);
begin
  if FieldScale <> aValue then begin
    FFieldSize := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

{$ENDREGION}

end.


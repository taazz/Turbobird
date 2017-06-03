//╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
//║                                        Copyright© 2017 EVOSI® all rights reserved                                  ║
//╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
//║                                                                                                                    ║
//║                        ▄▄▄▄▄▄▄▄▄▄▄  ▄               ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄                       ║
//║                       ▐░░░░░░░░░░░▌▐░▌             ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌                      ║
//║                       ▐░█▀▀▀▀▀▀▀▀▀  ▐░▌           ▐░▌ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀                       ║
//║                       ▐░▌            ▐░▌         ▐░▌  ▐░▌       ▐░▌▐░▌               ▐░▌                           ║
//║                       ▐░█▄▄▄▄▄▄▄▄▄    ▐░▌       ▐░▌   ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄      ▐░▌                           ║
//║                       ▐░░░░░░░░░░░▌    ▐░▌     ▐░▌    ▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌                           ║
//║                       ▐░█▀▀▀▀▀▀▀▀▀      ▐░▌   ▐░▌     ▐░▌       ▐░▌ ▀▀▀▀▀▀▀▀▀█░▌     ▐░▌                           ║
//║                       ▐░▌                ▐░▌ ▐░▌      ▐░▌       ▐░▌          ▐░▌     ▐░▌                           ║
//║                       ▐░█▄▄▄▄▄▄▄▄▄        ▐░▐░▌       ▐░█▄▄▄▄▄▄▄█░▌ ▄▄▄▄▄▄▄▄▄█░▌ ▄▄▄▄█░█▄▄▄▄                       ║
//║                       ▐░░░░░░░░░░░▌        ▐░▌        ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌                      ║
//║                        ▀▀▀▀▀▀▀▀▀▀▀          ▀          ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀                       ║
//║                                                                                                                    ║
//╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

unit uEvsDBSchema;

{$mode delphi}{$H+}
{$Include EvsDefs.inc}

interface

uses
  Classes, SysUtils, variants, db, contnrs, Graphics, uEvsGenIntf, uEvsWideString, uEvsIntfObjects;

const  //negative numbers are for internal use only positive are for 3rd party support, either assinged by range or single ID.
  stUnknown    =  0;
  stFirebird   = -1;
  stMySQL      = -2;
  stPostgreSQL = -3;
  stMSSQL      = -4;
  stInterbase  = -5;
  stOracle     = -6;
  //negative IDs are reserved for internal use.

type

  TEvsDBState  = (dbsChanged, //coold be removed
                  dbsData,    // no ddl statement exists you need to create the object with the new properties
                  dbsMetadata // you can alter the existing object.
                 );
  TEvsDataGroup =(dtgAlpha, dtgInteger, dtgNumeric, dtgDateTime, dtgBlob, dtgBinary, dtgCustomType);

  TEvsDBStates = set of TEvsDBState;
  TEvsSortOrder = (orUnSupported, orAscending, orDescending);
  TEvsTriggerType = (trBefore, trAfter, trDatabase);
  TEvsTriggerEvent = (teInsert,       teUpdate,     teDelete,      teOnConnect,
                      teOnDisconnect, teTransStart, teTransCommit, teTransRollback);

  TEvsTriggerEvents = set of TEvsTriggerEvent;

  IEvsTableInfo   = interface;//forward declaration.
  IEvsConnection  = interface;//forward declaration.
  IEvsCredentials = interface;//forward declaration.
  IEvsFieldInfo   = interface;//forward declaration.

  TIFieldarray = array of IEvsFieldInfo;
  TITableArray = array of IEvsTableInfo;

  TConnectProc   = Function (aHost,aDatabase,aUser,aPwd,aRole,aCharset:Widestring):IEvsConnection;
  TConnectMethod = Function (aHost,aDatabase,aUser,aPwd,aRole,aCharset:Widestring):IEvsConnection of object;

  { TEvsDBInfo }
  IEvsObjectState = interface(IEvsCopyable)
    function GetStates :TEvsDBStates;
    Property ObjectState:TEvsDBStates read GetStates;// write SetStates;
  end;

  TEvsDBInfo = class(TPersistent, IInterface,   IEvsObjectRef,  IEvsObjectState,
                                  IEvsParented, IEvsObservable, IEvsObserver,
                                  IEvsCopyable)
  private
    FOwner        : TEvsDBInfo;
    //FOwned        : TObjectList;
    FRefCount     : Integer;
    FRefCounted   : Boolean;
    FUpdateCount  : Integer;
    FUpdateStates : TEvsDBStates;
    FParent       : IEvsParented;
    FObservers    : IEvsObserverList;
    function GetStates :TEvsDBStates;
  protected
    function ObjectRef:TObject;      extdecl;
    procedure AddOwned(aObj:TEvsDBInfo);
    procedure ExtractOwned(aObj:TEvsDBInfo);
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure IncludeUpdateFlags(const aState:TEvsDBStates);
    procedure ClearStateFlags;
    property UpdateStates:TEvsDBStates read FUpdateStates;
    function GetParent :IEvsParented; extdecl;
    procedure SetParent(aValue :IEvsParented);extdecl;
    property Owner:TEvsDBInfo read FOwner;
  public
    Constructor Create(aOwner:TEvsDBInfo; aRefCounted:Boolean{=True});virtual;
    Destructor Destroy; override;

    //IEvsCopyable Support;
    function CopyFrom(const aSource  :IEvsCopyable) :Integer; extdecl;
    function CopyTo  (const aDest    :IEvsCopyable) :Integer; extdecl;
    Function EqualsTo(const aCompare :IEvsCopyable) :Boolean; virtual;extdecl;

    //IEVSObservable Support;
    Procedure AddObserver(Observer:IEvsObserver);extdecl;
    Procedure DeleteObserver(Observer:IEvsObserver);extdecl;
    Procedure ClearObservers;extdecl;
    Procedure Notify(const Action: TEVSGenAction; const aSubject:IEvsObjectRef);extdecl;
    //IEvsObserver support;
    Procedure Update(aSubject:IEvsObjectRef; Action:TEVSGenAction);extdecl;
    Procedure ClearState; extdecl;
    //IInterface Support.
    Function QueryInterface(constref IID: TGUID; out Obj): HResult;extdecl;
    Function _AddRef: Integer;extdecl;
    Function _Release: Integer;extdecl;
    Procedure AfterConstruction; override;
    Procedure BeforeDestruction; override;
    class Function NewInstance: TObject; override;

    Property ObjectState:TEvsDBStates read GetStates;
    Property Parent:IEvsParented read GetParent write SetParent;
  end;

  { IEvsUDFInfo }
  IEvsUDFInfo = interface(IEvsParented){$MESSAGE WARN 'Needs implementation'}
    ['{729DBB89-2B77-48CA-82F3-888591B8E47A}']
    function GetEntryPoint :WideString;         extdecl;
    function GetModuleName :WideString;         extdecl;
    Function GetName :WideString;               extdecl;
    procedure SetEntryPoint(aValue :WideString);extdecl;
    procedure SetModuleName(aValue :WideString);extdecl;
    Procedure SetName(aValue :WideString);      extdecl;

    Property Name:WideString read GetName write SetName;
    Property ModuleName:WideString read GetModuleName write SetModuleName;
    Property EntryPoint:WideString read GetEntryPoint write SetEntryPoint;
  end;

  IEvsUDFList = interface //OK
    ['{24DADF5E-DA0D-405F-830E-31E447C15D3C}']
    Function Get(aIdx : Integer) : IEvsUDFInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;item : IEvsUDFInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsUDFInfo;extdecl;
    Function First : IEvsUDFInfo;extdecl;
    Function IndexOf(item : IEvsUDFInfo) : Integer;extdecl;
    Function Add(item : IEvsUDFInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;item : IEvsUDFInfo);extdecl;
    Function Last : IEvsUDFInfo;extdecl;
    Function Remove(item : IEvsUDFInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;

    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsUDFInfo read Get write Put;default;
  end;

  { IEvsFieldInfo }
  IEvsFieldInfo = interface(IEvsParented) //OK
    ['{1D1C2E18-593E-44D4-8020-DA88FE3C8E60}']
    Function GetAllowNull :ByteBool;extdecl;
    Function GetAutoNumber :ByteBool;extdecl;
    Function GetCalculated :widestring;extdecl;
    Function GetCanAutoInc :WordBool;extdecl;
    Function GetCharset :widestring;extdecl;
    Function GetCheck :widestring;extdecl;
    Function GetColation :widestring;extdecl;
    function GetDataGroup :TEvsDataGroup;extdecl;
    Function GetDataTypeName :widestring;extdecl;
    Function GetDefaultValue :OLEVariant;extdecl;
    procedure SetDataGroup(aValue :TEvsDataGroup);extdecl;
    Procedure SetDefaultValue(aValue :OLEVariant);extdecl;
    Function GetFieldDescription :widestring;extdecl;
    Function GetFieldName :widestring;extdecl;
    Function GetFieldScale :Integer;extdecl;
    Procedure SetFieldScale(aValue :Integer);extdecl;
    Function GetFieldSize :Integer;extdecl;
    Procedure SetFieldSize(aValue :Integer);extdecl;
    Procedure SetAllowNull(aValue :ByteBool);extdecl;
    Procedure SetAutoNumber(aValue :ByteBool);extdecl;
    Procedure SetCalculated(aValue :widestring);extdecl;
    Procedure SetCharset(aValue :widestring);extdecl;
    Procedure SetCheck(aValue :widestring);extdecl;
    Procedure SetColation(aValue :widestring);extdecl;
    Procedure SetDataTypeName(aValue :widestring);extdecl;
    Procedure SetFieldDescription(aValue :widestring);extdecl;
    Procedure SetFieldName(aValue :widestring);extdecl;

    Property AllowNulls   : ByteBool       read GetAllowNull        write SetAllowNull  default True;
    Property AutoNumber   : ByteBool       read GetAutoNumber       write SetAutoNumber default False;
    Property Calculated   : widestring     read GetCalculated       write SetCalculated;
    Property Collation    : widestring     read GetColation         write SetColation;
    Property DataTypeName : widestring     read GetDataTypeName     write SetDataTypeName;
    Property DefaultValue : OLEVariant     read GetDefaultValue     write SetDefaultValue;
    Property Description  : widestring     read GetFieldDescription write SetFieldDescription;
    Property FieldName    : widestring     read GetFieldName        write SetFieldName;
    Property FieldScale   : Integer        read GetFieldScale       write SetFieldScale;
    Property FieldSize    : Integer        read GetFieldSize        write SetFieldSize;
    Property Charset      : widestring     read GetCharset          write SetCharset;
    Property Check        : widestring     read GetCheck            write SetCheck;
    Property DataGroup    : TEvsDataGroup  read GetDataGroup        write SetDataGroup;
    //Property DataType     : TEvsDataType   Read GetDataType         Write SetDataType;
  end;

  IEvsFieldList = interface(IEvsCopyable) //OK
    ['{57298EBB-63B1-4332-ADBE-BCB3221CFA16}']
    Function Get(aIndex : Integer) : IEvsFieldInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIndex : Integer;aItem : IEvsFieldInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsFieldInfo;extdecl;
    Function First : IEvsFieldInfo;extdecl;
    Function IndexOf(aItem : IEvsFieldInfo) : Integer;extdecl;
    Function Add(aItem : IEvsFieldInfo) : Integer;extdecl;
    Procedure Insert(aIndex : Integer;aItem : IEvsFieldInfo);extdecl;
    Function Last : IEvsFieldInfo;extdecl;
    Function Remove(aItem : IEvsFieldInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;

    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIndex : Integer] : IEvsFieldInfo read Get write Put;default;
  end;

  { IEvsTriggerInfo }
  IEvsTriggerInfo = interface(IEvsParented) {$MESSAGE WARN 'Needs Implementation'}
    ['{79248B35-ECC2-4746-8C17-5EC93E990081}']
    function GetActive :ByteBool; extdecl;
    function GetEvent :TEvsTriggerEvents;extdecl;
    function GetEventType :TEvsTriggerType;extdecl;
    function GetSQL :WideString;extdecl;
    function GetTriggerDescription :WideString;extdecl;
    function GetTriggerName :WideString;extdecl;
    procedure SetActive(aValue :ByteBool);extdecl;
    procedure SetEvent(aValue :TEvsTriggerEvents);extdecl;
    procedure SetEventType(aValue :TEvsTriggerType);extdecl;
    procedure SetSQL(aValue :WideString);extdecl;
    procedure SetTriggerDscription(aValue :WideString);extdecl;
    procedure SetTriggerName(aValue :WideString);extdecl;

    property Name        :WideString        read GetTriggerName        write SetTriggerName;
    property Description :WideString        read GetTriggerDescription write SetTriggerDscription;
    property SQL         :WideString        read GetSQL                write SetSQL; //the DDL command no partial commands here.
    property Event       :TEvsTriggerEvents read GetEvent              write SetEvent;
    property TriggerType :TEvsTriggerType   read GetEventType          write SetEventType;
    PRoperty Active      :ByteBool          read GetActive             write SetActive;
  end;

  IEvsTriggerList = interface(IEvsCopyable) //OK
    ['{9C2970C3-7AFC-43F8-9D39-9F4C1AEDF3C4}']
    function Get(aIdx : Integer) : IEvsTriggerInfo;extdecl;
    function GetCapacity : Integer;extdecl;
    function GetCount : Integer;extdecl;
    procedure Put(i : Integer;item : IEvsTriggerInfo);extdecl;
    procedure SetCapacity(NewCapacity : Integer);extdecl;
    procedure SetCount(NewCount : Integer);extdecl;
    procedure Clear;extdecl;
    procedure Delete(index : Integer);extdecl;
    procedure Exchange(index1,index2 : Integer);extdecl;
    function New:IEvsTriggerInfo;extdecl;
    function First : IEvsTriggerInfo;extdecl;
    function IndexOf(item : IEvsTriggerInfo) : Integer;extdecl;
    function Add(item : IEvsTriggerInfo) : Integer;extdecl;
    procedure Insert(i : Integer;item : IEvsTriggerInfo);extdecl;
    function Last : IEvsTriggerInfo;extdecl;
    function Remove(item : IEvsTriggerInfo): Integer;extdecl;
    procedure Lock;extdecl;
    procedure Unlock;extdecl;
    property Capacity : Integer read GetCapacity write SetCapacity;
    property Count : Integer read GetCount write SetCount;
    property Items[aIdx : Integer] : IEvsTriggerInfo read Get write Put;default;
  end;

  { IEvsIndexInfo }
  IEvsIndexInfo = interface(IEvsParented)  //OK
    ['{FEA79D55-B1CF-4A24-8CE6-A9EBEB769C3C}']
    Function GetField(aIndex :Integer) :IEvsFieldInfo;extdecl;
    Function GetIndexName : WideString;extdecl;
    Function GetOrder :TEvsSortOrder;extdecl;
    Function GetFieldOrder(aIndex :Integer) :TEvsSortOrder;extdecl;
    Function GetPrimary :ByteBool;extdecl;
    Function GetTable :IEvsTableInfo;extdecl;
    Function GetUnique :ByteBool;extdecl;
    Procedure SetIndexName(const aValue: WideString);extdecl;
    Procedure SetOrder(const aValue: TEvsSortOrder);extdecl;
    Procedure SetPrimary(aValue :ByteBool);extdecl;
    Procedure SetTable(aValue :IEvsTableInfo);extdecl;
    Procedure SetUnique(aValue :ByteBool);extdecl;

    Procedure SwapFields(const aIndex1,aIndex2:Integer);extdecl;
    Procedure AppendField(const aField:IEvsFieldInfo; const aOrder: TEvsSortOrder);extdecl;
    Procedure DeleteField(const aIndex : Integer);overload;extdecl;
    Procedure DeleteField(const aField : IEvsFieldInfo);overload;extdecl;
    Procedure ClearFields;extdecl;
    Function GetFieldCount:Integer;extdecl;

    Property IndexName:WideString read GetIndexName write SetIndexName;
    Property Unique:ByteBool read GetUnique write SetUnique;
    Property Primary:ByteBool read GetPrimary write SetPrimary;
    Property Order : TEvsSortOrder read GetOrder write SetOrder default orUnsupported;
    Property FieldCount:Integer read GetfieldCount;
    Property Field[aIndex:Integer]:IEvsFieldInfo read GetField;
    Property FieldOrder[aIndex:Integer]:TEvsSortOrder read GetFieldOrder;
    Property Table :IEvsTableInfo read GetTable write SetTable;
  end;
  IEvsIndexList = interface(IEvsCopyable) //OK
    ['{1BD50931-B0E9-404E-B575-D31BA2FA8B37}']
    Function Get(aIdx : Integer) : IEvsIndexInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;item : IEvsIndexInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsIndexInfo;extdecl;
    Function First : IEvsIndexInfo;extdecl;
    Function IndexOf(item : IEvsIndexInfo) : Integer;extdecl;
    Function Add(item : IEvsIndexInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;item : IEvsIndexInfo);extdecl;
    Function Last : IEvsIndexInfo;extdecl;
    Function Remove(item : IEvsIndexInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsIndexInfo read Get write Put;default;
  end;

  { IEvsTableInfo }
  IEvsTableInfo = interface(IEvsParented) //OK
    ['{35EA6385-3C4F-4EAA-ACB8-CCF92227BAD0}']
    Function GetCharset     : WideString;extdecl;
    Function GetCollation   : WideString;extdecl;
    Function GetDescription : WideString;extdecl;
    Function GetField(aIndex :Integer) :IEvsFieldInfo;extdecl;
    function GetSystemTable :LongBool; extdecl;
    Function GetTrigger(aIndex :Integer) :IEvsTriggerInfo;extdecl;
    Function GetFieldCount :Integer;extdecl;
    Function GetIndex(aIndex :Integer) :IEvsIndexInfo;extdecl;
    Function GetIndexCount   :integer;extdecl;
    Function GetTriggerCount :integer;extdecl;
    Function GetTableName :WideString;extdecl;
    Procedure SetCharSet(aValue :WideString);extdecl;
    Procedure SetCollation(aValue :WideString);extdecl;
    Procedure SetDescription(aValue :wideString);extdecl;
    Procedure SetField(aIndex :Integer; aValue :IEvsFieldInfo);extdecl;
    Procedure SetIndex(aIndex :Integer; aValue :IEvsIndexInfo);extdecl;
    procedure SetSystemTable(aValue :LongBool); extdecl;
    Procedure SetTrigger(aIndex :Integer; aValue :IEvsTriggerInfo);extdecl;
    Procedure SetTableName(aValue :WideString);extdecl;

    //property SchemaName           :WideString          read GetSchemaName       write SetSchemaName;
    //property FullTableName        :WideString          read GetFullName;
    Function AddField(const aFieldName, aDataType:WideString; const aFieldsIze,aFieldScale:Integer;
                      const aCharset, aCollation :WideString;
                      const AllowNulls, AutoNumber:ByteBool):IEvsFieldInfo;extdecl;
    Function NewField:IEvsFieldInfo;     extdecl;
    Function NewIndex:IEvsIndexInfo;     extdecl;
    Function NewTrigger:IEvsTriggerInfo; extdecl;
    Function AddIndex(const aName:widestring; const aFields:Array of IEvsFieldInfo;
                      const aFieldOrders:array of TEvsSortOrder):IEvsIndexInfo;overload;    extdecl;
    Function AddIndex(const aName:widestring; const aFieldNamess:Array of WideString;
                      const aFieldOrders:array of TEvsSortOrder):IEvsIndexInfo;overload;    extdecl;
    Function AddIndex(const aName:widestring; aOrder:TEvsSortOrder):IEvsIndexInfo;overload; extdecl;
    Function FieldByName(const aName:Widestring):IEvsFieldInfo;                             extdecl;

    Procedure Remove(const aObject:IEvsFieldInfo);  overload; extdecl;
    Procedure Remove(const aObject:IEvsIndexInfo);  overload; extdecl;
    Procedure Remove(const aObject:IEvsTriggerInfo);overload; extdecl;

    Property TableName   :WideString read GetTableName   write SetTableName;
    Property Description :WideString read GetDescription write SetDescription;
    Property CharSet     :WideString read GetCharset     write SetCharSet;
    Property Collation   :WideString read GetCollation   write SetCollation; // probably will not keep it.
    Property SystemTable :LongBool   read GetSystemTable write SetSystemTable;

    Property FieldCount   :Integer read GetFieldCount;
    Property IndexCount   :Integer read GetIndexCount;
    Property TriggerCount :Integer read GetTriggerCount;
    Property Index[aIndex:Integer]   :IEvsIndexInfo   read GetIndex       write SetIndex;
    Property Field[aIndex:Integer]   :IEvsFieldInfo   read GetField       write SetField;   default;
    Property Trigger[aIndex:Integer] :IEvsTriggerInfo read GetTrigger     write SetTrigger;
  end;
  { IEvsTableList }
  IEvsTableList = interface(IInterface) //OK
    ['{9F2649C8-7446-4917-8EB0-DAEBDF4BB251}']
    Function Get(aIdx : Integer) : IEvsTableInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;item : IEvsTableInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsTableInfo;extdecl;
    Function First : IEvsTableInfo;extdecl;
    Function IndexOf(item : IEvsTableInfo) : Integer;extdecl;
    Function Add(item : IEvsTableInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;item : IEvsTableInfo);extdecl;
    Function Last : IEvsTableInfo;extdecl;
    Function Remove(item : IEvsTableInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count    : Integer read GetCount    write SetCount;
    Property Items[aIdx : Integer] : IEvsTableInfo read Get write Put;default;
  end;
  { IEvsViewInfo }
  IEvsViewInfo  = Interface(IEvsParented) {$MESSAGE WARN 'Needs Testing'}
    ['{C86DB8A8-7C86-4561-9C80-381488E544EA}']
    Function GetDescription : WideString;extdecl;
    Function GetField(aIndex : Integer) : IEvsFieldInfo;extdecl;
    Function GetFieldList : IEvsFieldList;extdecl;
    Function GetName : WideString;extdecl;
    Function GetSQL : WideString; extdecl;
    Procedure SetDescription(aValue :WideString);extdecl;
    Procedure SetField(aIndex :Integer; aValue :IEvsFieldInfo);extdecl;
    Procedure SetFieldList(aValue :IEvsFieldList);extdecl;
    Procedure SetName(aValue :WideString);extdecl;
    Procedure SetSQL(aValue :WideString); extdecl;
    Function FieldCount:integer;extdecl;

    Property SQL:WideString  read GetSQL  write SetSQL;
    Property Name:WideString read GetName write SetName;
    Property FieldList:IEvsFieldList read GetFieldList write SetFieldList;
    Property Field[aIndex:Integer]:IEvsFieldInfo read GetField write SetField;
    Property Description:WideString read GetDescription write SetDescription;
  end;
  IEvsViewList = interface(IInterface)  {$MESSAGE WARN 'Needs Implementation'}
    ['{03415624-CDE0-4015-AAA6-DE629D05ED1B}']
    Function Get(aIndex : Integer) : IEvsViewInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;aItem : IEvsViewInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsViewInfo;extdecl;
    Function First : IEvsViewInfo;extdecl;
    Function IndexOf(aItem : IEvsViewInfo) : Integer;extdecl;
    Function Add(aItem : IEvsViewInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;aItem : IEvsViewInfo);extdecl;
    Function Last : IEvsViewInfo;extdecl;
    Function Remove(aItem : IEvsViewInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIndex : Integer] : IEvsViewInfo read Get write Put;default;
  end;

  { IEvsStoredInfo }
  IEvsStoredInfo = interface(IEvsParented) {$MESSAGE WARN 'Needs Implementation'}
    ['{71B2F8CE-35C9-4139-BFF5-9EDE5DD8C1D7}']
    Function GetDescription :Widestring;               extdecl;
    Function GetField(aIndex :Integer) :IEvsFieldInfo; extdecl;
    Function GetFieldCount :integer;                   extdecl;
    Function GetSPName :WideString;                    extdecl;
    Function GetSql :WideString;                       extdecl;
    Procedure SetDescription(aValue :Widestring);       extdecl;
    Procedure SetField(aIndex :Integer; aValue :IEvsFieldInfo);extdecl;
    Procedure SetSPName(aValue :WideString);                   extdecl;
    Procedure SetSql(aValue :WideString);                      extdecl;
    Procedure AddField(const aField:IEvsFieldInfo);            extdecl;
    Function NewField(const aName:WideString):IEvsFieldInfo;   extdecl;

    Property Name:WideString read GetSPName write SetSPName;
    Property Description:Widestring read GetDescription write SetDescription;
    Property Fields[aIndex:Integer]:IEvsFieldInfo read GetField;// write SetField; // the fields returned by the stored procedure.
    Property FieldCount:integer read GetFieldCount;
    Property SQL:WideString read GetSql write SetSql;
  end;
  IEvsStoredList = interface(IInterface) //OK
    ['{7DEF59C1-04D2-4B67-A10C-A7D16800DEBF}']
    Function Get(aIndex : Integer) : IEvsStoredInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIndex : Integer;aItem : IEvsStoredInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsStoredInfo;extdecl;
    Function First : IEvsStoredInfo;extdecl;
    Function IndexOf(aItem : IEvsStoredInfo) : Integer;extdecl;
    Function Add(aItem : IEvsStoredInfo) : Integer;extdecl;
    Procedure Insert(aIndex : Integer;aItem : IEvsStoredInfo);extdecl;
    Function Last : IEvsStoredInfo;extdecl;
    Function Remove(aItem : IEvsStoredInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIndex : Integer] : IEvsStoredInfo read Get write Put;default;
  end;

  { IEvsGeneratorInfo }
  IEvsSequenceInfo = interface(IEvsParented)  //OK
    ['{8C36E1FF-FB18-4FEB-A220-0739D038C5B6}']
    Function GetCurrentValue :Int64;extdecl;
    Function GetName :widestring;extdecl;
    Procedure SetCurrentValue(aValue :Int64);extdecl;
    Procedure SetName(aValue :widestring);extdecl;
    Property Name:WideString read GetName write SetName;
    Property CurrentValue:Int64 read GetCurrentValue write SetCurrentValue;
  end;
  IEvsSequenceList = interface(IInterface)  //OK
    ['{B34CFF97-DD77-4AC8-9FA1-04E612F5D107}']
    Function Get(aIdx : Integer) : IEvsSequenceInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;item : IEvsSequenceInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsSequenceInfo;extdecl;
    Function First : IEvsSequenceInfo;extdecl;
    Function IndexOf(item : IEvsSequenceInfo) : Integer;extdecl;
    Function Add(item : IEvsSequenceInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;item : IEvsSequenceInfo);extdecl;
    Function Last : IEvsSequenceInfo;extdecl;
    Function Remove(item : IEvsSequenceInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsSequenceInfo read Get write Put;default;
  end;
  IEvsGeneratorInfo = IEvsSequenceInfo;
  IEvsGeneratorList = IEvsSequenceList;
  { IEvsExceptionInfo }

  IEvsExceptionInfo = interface(IEvsParented) //OK
    ['{673B1042-D702-4899-B8E9-3AA779087E72}']
    Function GetDescription :widestring;extdecl;
    Function GetMessage :WideString;extdecl;
    Function GetName :WideString;extdecl;
    Function GetNumber :WideString;extdecl;
    Function GetSystem :ByteBool;extdecl;
    Procedure SetDescription(aValue :widestring);extdecl;
    Procedure SetMessage(aValue :WideString);extdecl;
    Procedure SetName(aValue :WideString);extdecl;
    Procedure SetNumber(aValue :WideString);extdecl;
    Procedure SetSystem(aValue :ByteBool);extdecl;

    Property Name        : WideString read GetName        write SetName;
    Property Description : widestring read GetDescription write SetDescription;
    Property Number      : WideString read GetNumber      write SetNumber;
    Property Message     : WideString read GetMessage     write SetMessage;
    Property System      : ByteBool   read GetSystem      write SetSystem;
  end;
  IEvsExceptionList = interface(IInterface) {$MESSAGE WARN 'Needs Implementation'}
    ['{F662397E-C9DC-41B2-98B3-468A8BE12445}']
    Function Get(aIdx : Integer) : IEvsExceptionInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;item : IEvsExceptionInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsExceptionInfo;extdecl;
    Function First : IEvsExceptionInfo;extdecl;
    Function IndexOf(item : IEvsExceptionInfo) : Integer;extdecl;
    Function Add(item : IEvsExceptionInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;item : IEvsExceptionInfo);extdecl;
    Function Last : IEvsExceptionInfo;extdecl;
    Function Remove(item : IEvsExceptionInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsExceptionInfo read Get write Put;default;
  end;

  { IEvsUserInfo }
  IEvsUserInfo = interface(IEvsParented)  //OK
    ['{EA26A95B-5988-48A2-8849-46A593A6BBCE}']
    Function GetFirstName :widestring;extdecl;
    Function GetLastName :widestring;extdecl;
    Function GetMiddleName :widestring;extdecl;
    Function GetPassword :widestring;extdecl;
    Function GetUserName :widestring;extdecl;
    Procedure SetFirstName(aValue :widestring);extdecl;
    Procedure SetLastName(aValue :widestring);extdecl;
    Procedure SetMiddleName(aValue :widestring);extdecl;
    Procedure SetPassword(aValue :widestring);extdecl;
    Procedure SetUserName(aValue :widestring);extdecl;
    //mandatory data.
    Property UserName :WideString read GetUserName write SetUserName;
    Property Password :WideString read GetPassword write SetPassword;
    //optional data
    Property FirstName  :WideString read GetFirstName  write SetFirstName;
    Property MiddleName :WideString read GetMiddleName write SetMiddleName;
    Property LastName   :WideString read GetLastName   write SetLastName;
  end;
  IEvsUserList = interface(IInterface) //OK
    ['{F72C50C4-73E8-42CF-A107-6BAE5FC77E47}']
    Function Get(aIdx : Integer) : IEvsUserInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;item : IEvsUserInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsUserInfo;extdecl;
    Function First : IEvsUserInfo;extdecl;
    Function IndexOf(item : IEvsUserInfo) : Integer;extdecl;
    Function Add(item : IEvsUserInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;item : IEvsUserInfo);extdecl;
    Function Last : IEvsUserInfo;extdecl;
    Function Remove(item : IEvsUserInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsUserInfo read Get write Put;default;
  end;

  { IEvsRoleInfo }
  IEvsRoleInfo = interface(IEvsParented) {$MESSAGE WARN 'Incomplete'}
    ['{5EAE5A27-1CA6-4B49-87BE-770069FB09E4}']
    Function GetName :WideString;extdecl;
    Function GetUser(aIndex :Integer) :IEvsUserInfo;extdecl;
    Function GetUserCount :Integer;extdecl;
    Procedure SetName(aValue :WideString);extdecl;
    Procedure SetUser(aIndex :Integer; aValue :IEvsUserInfo);extdecl;

    Property Name:WideString read GetName write SetName;
    Property User[aIndex:Integer]:IEvsUserInfo read GetUser write SetUser;
    Property UserCount:Integer read GetUserCount;
  end;

  IEvsRoleList = interface {$MESSAGE WARN 'Needs Implementation'}
    ['{24ACEAB6-772D-4F21-8C1D-E8B2EEBAE539}']
    Function Get(aIdx : Integer) : IEvsRoleInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;item : IEvsRoleInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsRoleInfo;extdecl;
    Function First : IEvsRoleInfo;extdecl;
    Function IndexOf(item : IEvsRoleInfo) : Integer;extdecl;
    Function Add(item : IEvsRoleInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;item : IEvsRoleInfo);extdecl;
    Function Last : IEvsRoleInfo;extdecl;
    Function Remove(item : IEvsRoleInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsRoleInfo read Get write Put;default;
  end;

  { IEvsDomainInfo }
  IEvsDomainInfo = interface(IEvsParented) {$MESSAGE WARN 'Needs Implementation'}
    ['{EAE11017-3203-4B7F-A0CC-14AD5F64BF4D}']
    Function GetCharSet :WideString;         extdecl;
    Function GetCheckConstraint :WideString; extdecl;
    Function GetCollation :Widestring;       extdecl;
    Function GetDatatype :widestring;        extdecl;
    Function GetDefaultValue :OLEVariant;    extdecl;
    Function GetName :widestring;            extdecl;
    function GetSize :Integer;               extdecl;
    Function GetSQL :widestring;             extdecl;
    Procedure SetCharSet(aValue :widestring);extdecl;
    Procedure SetCheckConstraint(aValue :WideString);extdecl;
    Procedure SetCollation(aValue :Widestring);      extdecl;
    Procedure SetDatatype(aValue :widestring);       extdecl;
    Procedure SetDefaultValue(aValue :OLEVariant);   extdecl;
    Procedure SetName(aValue :widestring);           extdecl;
    procedure SetSize(aValue :Integer);              extdecl;
    Procedure SetSQL(aValue :widestring);            extdecl;

    Property DataType        : WideString read GetDatatype        write SetDatatype;
    Property DefaultValue    : OLEVariant read GetDefaultValue    write SetDefaultValue;
    Property CheckConstraint : WideString read GetCheckConstraint write SetCheckConstraint;
    Property CharSet         : WideString read GetCharSet         write SetCharSet;
    Property Collation       : WideString read GetCollation       write SetCollation;
    Property Name            : WideString read GetName            write SetName;
    Property SQL             : WideString read GetSQL             write SetSQL;
    Property Size            : Integer    read GetSize            write SetSize;
  end;
  IEvsDomainList = interface(IInterface) {$MESSAGE WARN 'Needs Implementation'}
    ['{53E6BA7E-1F76-48B5-9F88-C72430748C9A}']
    Function Get(aIdx : Integer) : IEvsDomainInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;item : IEvsDomainInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsDomainInfo;extdecl;
    Function First : IEvsDomainInfo;extdecl;
    Function IndexOf(item : IEvsDomainInfo) : Integer;extdecl;
    Function Add(item : IEvsDomainInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;item : IEvsDomainInfo);extdecl;
    Function Last : IEvsDomainInfo;extdecl;
    Function Remove(item : IEvsDomainInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsDomainInfo read Get write Put;default;
  end;

  { IEvsDatabaseInfo }
  IEvsDatabaseInfo = interface(IEvsParented) //OK
    ['{29AE2670-E75A-4DBB-B7A8-7C0742A9457C}']
    Function GetConnection  :IEvsConnection;  extdecl;
    Function GetCredentials :IEvsCredentials; extdecl;
    Function GetDatabase    :WideString;      extdecl;
    Function GetDefaultCharSet :Widestring;   extdecl;
    function GetDefCollation   :Widestring;   extdecl;
    function GetDomainCount    :Integer;      extdecl;
    Function GetExceptionCount :Integer;      extdecl;
    Function GetExceptions(aIndex :Integer) :IEvsExceptionInfo; extdecl;
    Function GetDomain(aIndex :Integer):IEvsDomainInfo;         extdecl;
    Function GetHost :WideString;                               extdecl;
    //function GetIndex(aIndex :Integer):IEvsIndexInfo;           extdecl;
    //function GetIndexCount :Integer;                            extdecl;
    Function GetPageSize :Integer;                              extdecl;
    Function GetProcedureCount :Integer;                        extdecl;
    Function GetRole(aIndex :Integer) :IEvsRoleInfo;            extdecl;
    Function GetRoleCount :Integer;                             extdecl;
    Function GetSequenceCount :Integer;                         extdecl;
    Function GetSequences(Aindex :Integer) : IEvsGeneratorInfo; extdecl;
    Function GetServerID :Integer;                              extdecl;
    Function GetStored(aIndex :Integer) :IEvsStoredInfo;        extdecl;
    Function GetTable (aIndex :Integer) :IEvsTableInfo;         extdecl;
    Function GetTableCount :Integer;                            extdecl;
    function GetTitle :Widestring;                              extdecl;
    Function GetTrigger(aIndex :Integer) :IEvsTriggerInfo;      extdecl;
    Function GetTriggerCount :Integer;                          extdecl;
    Function GetUDF(aIndex :Integer) : IEvsUDFInfo;             extdecl;
    Function GetUdfCount :Integer;                              extdecl;
    Function GetUser(aIndex :Integer) :IEvsUSerInfo;            extdecl;
    Function GetUserCount :Integer;                             extdecl;
    Function GetView(aIndex :Integer) : IEvsViewInfo;           extdecl;
    Function GetViewCount :Integer;                             extdecl;
    Procedure SetConnection(aValue :IEvsConnection);            extdecl;
    Procedure SetDatabase(aValue :WideString);                  extdecl;
    Procedure SetDefaultCharSet(aValue :Widestring);            extdecl;
    procedure SetDefCollation(aValue :Widestring);              extdecl;
    Procedure SetHost(aValue :WideString);                      extdecl;
    Procedure SetPageSize(aValue :Integer);                     extdecl;
    Procedure SetTitle(aValue :Widestring);                     extdecl;

    Function NewTable(const aTableName :WideString):IEvsTableInfo; extdecl;
    Function NewDomain(const aDomainName :WideString; const aDataType :WideString; const aSize:integer;
                       const aCheck :WideString=''; aCharset :WideString=''; aCollation :WideString=''):IEvsDomainInfo;      extdecl;
    Function NewIndex(const aName :WideString; const aORder :TEvsSortOrder; aFieldList :array of IEvsFieldInfo):IEvsIndexInfo; extdecl;
    Function NewStored(const aName :WideString; const aSql :WideString):IEvsStoredInfo;           extdecl;
    Function NewView(const aName :WideString; const aSql :WideString):IEvsViewInfo;               extdecl;
    Function NewException(const aName :WideString; const aMessage :WideString):IEvsExceptionInfo; extdecl;
    Function NewUDF (const aName :WideString):IEvsUDFInfo;              extdecl;
    Function NewUser(const aUserName:WideString):IEvsUserInfo; overload;extdecl;
    Function NewRole(const aRoleName:Widestring):IEvsRoleInfo; overload;extdecl;
    Function NewTrigger  :IEvsTriggerInfo;                              extdecl;
    Function NewSequence :IEvsSequenceInfo;                             extdecl;
    Function NewUser     :IEvsUserInfo;                        overload;extdecl;
    Function NewRole     :IEvsRoleInfo;                        overload;extdecl;
    Procedure SetServerID(aValue :Integer);                             extdecl;

    Procedure Remove(const aObject :IEvsTriggerInfo);  overload;extdecl;
    Procedure Remove(const aObject :IEvsTableInfo);    overload;extdecl;
    Procedure Remove(const aObject :IEvsFieldInfo);    overload;extdecl;
    Procedure Remove(const aObject :IEvsIndexInfo);    overload;extdecl;
    Procedure Remove(const aObject :IEvsStoredInfo);   overload;extdecl;
    Procedure Remove(const aObject :IEvsSequenceInfo); overload;extdecl;
    Procedure Remove(const aObject :IEvsExceptionInfo);overload;extdecl;
    Procedure Remove(const aObject :IEvsUDFInfo);      overload;extdecl;
    Procedure Remove(const aObject :IEvsViewInfo);     overload;extdecl;

    Procedure ClearTables;     extdecl;
    Procedure ClearStored;     extdecl;
    Procedure ClearExceptions; extdecl;
    Procedure ClearSequences;  extdecl;
    Procedure ClearViews;      extdecl;
    Procedure ClearTriggers;   extdecl;
    Procedure ClearUDFs;       extdecl;
    Procedure ClearDomains;     extdecl;
    Procedure ClearRoles;      extdecl;
    Procedure ClearUsers;      extdecl;

    Property Host           :WideString     read GetHost           write SetHost; //computer where this database resides
    Property Database       :WideString     read Getdatabase       write SetDatabase; //the database name
    Property PageSize       :Integer        read GetPageSize       write SetPageSize; //The db page size.
    Property DefaultCharset :WideString     read GetDefaultCharSet write SetDefaultCharSet;
    Property DefaultCollation:Widestring    read GetDefCollation   write SetDefCollation;
    Property Connection     :IEvsConnection read GetConnection     write SetConnection;
    Property ServerKind     :Integer        read GetServerID       write SetServerID;
    Property Title          :Widestring     read GetTitle          write SetTitle;
    //property Owner:WideString read GetOwner write SetOwner;//user that created the database.
    Property Credentials                :IEvsCredentials   read GetCredentials;   // username,pssword & role used to login.

    Property Table     [aIndex :Integer]:IEvsTableInfo     read GetTable;      //FTables      := Nil; // indexed access to the database's tables.
    Property StoredProc[aIndex :Integer]:IEvsStoredInfo    read GetStored;     //FStoredProcs := Nil; // indexed access to the Sored procedures.
    Property Exception [aIndex :Integer]:IEvsExceptionInfo read GetExceptions; //FExceptions  := Nil; // indexed access to the exceptions
    Property Sequence  [aIndex :Integer]:IEvsGeneratorInfo read GetSequences;  //FSequences   := Nil; // indexed access to the generators
    Property View      [aIndex :Integer]:IEvsViewInfo      read GetView;       //FViews       := Nil; // write SetView;
    Property Trigger   [aIndex :Integer]:IEvsTriggerInfo   read GetTrigger;    //FTriggers    := Nil; // Database triggers only
    Property UDF       [aIndex :Integer]:IEvsUDFInfo       read GetUDF;        //FUdfs        := Nil;
    Property Domain    [aIndex :Integer]:IEvsDomainInfo    read GetDomain;     //FDomains     := Nil;
    //Property Index     [aIndex :Integer]:IEvsIndexInfo     read GetIndex;      //FIndices     := Nil;
    Property Role      [aIndex :Integer]:IEvsRoleInfo      read GetRole;       //FRole        := Nil;
    Property User      [aIndex :Integer]:IEvsUSerInfo      read GetUser;       //FUser        := Nil;

    Property ProcedureCount :Integer read GetProcedureCount;// how many procedures are there.
    Property TableCount     :Integer read GetTableCount;    // how many tables are there? system tables are not included.
    Property ExceptionCount :Integer read GetExceptionCount;// how many exceptions are there.
    Property SequenceCount  :Integer read GetSequenceCount; // how many exceptions are there.
    Property TriggerCount   :Integer read GetTriggerCount;  // Database triggers only (onconnect on transactionstart etc).
    Property ViewCount      :Integer read GetViewCount;
    //Property IndexCount     :Integer read GetIndexCount;
    Property UdfCount       :Integer read GetUdfCount;
    Property DomainCount    :Integer read GetDomainCount;
    Property UserCount      :Integer read GetUserCount;
    Property RoleCount      :Integer read GetRoleCount;
  end;
  IEvsDatabaseList = interface //OK
    ['{197B5117-0D3F-4FBE-A61C-105F0870B94A}']
    Function Get(aIdx : Integer) : IEvsDatabaseInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(i : Integer;item : IEvsDatabaseInfo);extdecl;
    Procedure SetCapacity(NewCapacity : Integer);extdecl;
    Procedure SetCount(NewCount : Integer);extdecl;
    Procedure Clear;extdecl;
    Procedure Delete(index : Integer);extdecl;
    Procedure Exchange(index1,index2 : Integer);extdecl;
    Function New:IEvsDatabaseInfo;extdecl;
    Function First : IEvsDatabaseInfo;extdecl;
    Function IndexOf(item : IEvsDatabaseInfo) : Integer;extdecl;
    Function Add(item : IEvsDatabaseInfo) : Integer;extdecl;
    Procedure Insert(i : Integer;item : IEvsDatabaseInfo);extdecl;
    Function Last : IEvsDatabaseInfo;extdecl;
    Function Remove(item : IEvsDatabaseInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsDatabaseInfo read Get write Put;default;
  end;

  //IEvsDBStatistics = interface(IInterface) //generic info on the database pages used active transactions etc.
  //end;

  { IEvsCredentials }
  IEvsCredentials = interface(IEvsCopyable)  //OK
    ['{461C62B7-58AD-42D6-9059-1F82E1C485C7}']
    function GetCharSet :WideString;            extdecl;
    function GetLastChanged :TDateTime;         extdecl;
    Function GetPassword :WideString;           extdecl;
    Function GetRole     :WideString;           extdecl;
    function GetSavePwd :LongBool;              extdecl;
    Function GetUserName :WideString;           extdecl;
    procedure SetCharset(aValue :WideString);   extdecl;
    procedure SetLastChanged(aValue :TDateTime);extdecl;
    Procedure SetPassword(aValue :WideString);  extdecl;
    Procedure SetRole(aValue :WideString);      extdecl;
    procedure SetSavePwd(aValue :LongBool);     extdecl;
    Procedure SetUserName(aValue :WideString);  extdecl;

    Property UserName     :WideString read GetUserName    write SetUserName;
    Property Password     :WideString read GetPassword    write SetPassword;
    Property Role         :WideString read GetRole        write SetRole;
    Property Charset      :WideString read GetCharSet     write SetCharset;
    Property SavePassword :LongBool   read GetSavePwd     write SetSavePwd;
    Property LastChanged  :TDateTime  read GetLastChanged write SetLastChanged;
  end;


//-------------------------------------------------------------------------------------------------------------
//database Access interfaces
//simplified interfaces to be used in the database interface
//-------------------------------------------------------------------------------------------------------------

  IEvsDataset = interface;

  { IEvsField }
  IEvsField = interface(IInterface)
    ['{33E146B2-91A2-4627-9C3C-720DBD7D623A}']
    Function GetAsBoolean :LongBool;  extdecl;
    Function GetFieldName :WideString;extdecl;
    function GetIsNumeric :LongBool;  extdecl;
    function GetLength    :Integer;   extdecl;
    function GetPrecision :Integer;   extdecl;
    Function GetReadOnly :Boolean;    extdecl;
    Function GetRequired :Boolean;    extdecl;
    Function GetAsVariant :OLEVariant;extdecl;
    Function GetCalculated :Boolean;  extdecl;
    Function GetCanModify :Boolean;   extdecl;
    Function GetEditText :widestring; extdecl;
    Function GetFullName :WideString; extdecl;
    Function GetIsNull :Boolean;      extdecl;
    function GetSize :Integer;        extdecl;
    Procedure SetAsBoolean(aValue :LongBool);  extdecl;
    Procedure SetAsVariant(aValue :OLEVariant);extdecl;
    Procedure SetCalculated(aValue :Boolean);  extdecl;
    Procedure SetEditText(aValue :widestring); extdecl;
    Procedure SetFieldName(aValue :WideString);extdecl;
    Procedure SetReadOnly(aValue :Boolean);    extdecl;

    Function AsString:Widestring;extdecl;
    Function AsInt32:Int32;extdecl;

    Function AsByte:Byte;extdecl;
    Function AsDouble:Double;extdecl;
    Function AsDateTime:TDateTime;extdecl;

    Property Calculated :Boolean     read GetCalculated  write SetCalculated;
    Property CanModify  :Boolean     read GetCanModify;
    Property FullName   :WideString  read GetFullName;
    Property IsNull     :Boolean     read GetIsNull;
    Property Text       :widestring  read GetEditText    write SetEditText;
    Property Value      :OLEVariant  read GetAsVariant   write SetAsVariant;
    Property FieldName  :WideString  read GetFieldName   write SetFieldName;
    Property ReadOnly   :Boolean     read GetReadOnly    write SetReadOnly;
    Property Required   :Boolean     read GetRequired;//    write SetRequired;
    Property AsBoolean  :LongBool    read GetAsBoolean   write SetAsBoolean;
    property IsNumeric  :LongBool    read GetIsNumeric;
    Property Size       :Integer     read GetSize;
    Property Precision  :Integer     read GetPrecision;
    Property Length     :Integer     read GetLength;
    //property AutoTrim   :ByteBool    read GetAutoTrim write SetAutoTrim;
  end;

  { IEvsMetaData }
  IEvsMetaData = interface(IInterface) {$MESSAGE WARN 'Under construction'}
    ['{6358D2B3-7042-46B3-BC0B-C930A0A5C2D0}']
    Function GetConnection :IEvsConnection;                         extdecl;
    Procedure SetConnection(aValue :IEvsConnection);                extdecl;
    Procedure GetTables(const aObject:IEvsDatabaseInfo;const IncludeSystem:ByteBool = False);   overload;extdecl;   //get tables for the database passed.
    PRocedure GetTableInfo(const aTable:IEvsTableInfo); extdecl; //loads all the details for a table;
    Procedure GetFields(const aObject:IEvsTableInfo);      overload;extdecl;   //get fields for the table passed.
    Procedure GetTriggers(const aObject:IEvsTableInfo; const System:ByteBool = False);          overload;extdecl;   //triggers for the table passed
    Procedure GetTriggers(const aObject:IEvsDatabaseInfo); overload;extdecl;   //database triggers only.
    Procedure GetStored(const aObject:IEvsDatabaseInfo);   overload;extdecl;   //stored procedures in the database.
    //Procedure GetViews(const aObject:IEvsViewList);       overload;extdecl;  //
    Procedure GetViews(const aObject:IEvsDatabaseInfo);    overload;extdecl;  //get views for the database passed.
    Procedure GetViewInfo(const aObject:IEvsViewInfo);     overload;extdecl;  //get view details (fields mostly).
    Procedure GetUDFs (const aObject:IEvsDatabaseInfo);             extdecl;  //get UDFs for the database passed
    Procedure GetUsers(const aDB:IEvsDatabaseInfo);                 extdecl;  //Get users for the  database passed.
    Procedure GetExceptions(const aDB:IEvsDatabaseInfo);            extdecl;  //Get exceptions for the database passed.
    Procedure GetSequences(const aDB:IEvsDatabaseInfo);             extdecl;  //Get Generators for the database passed.
    Procedure GetRoles(const aDB:IEvsDatabaseInfo);                 extdecl;  //Get Generators for the database passed.

    //constraints
    //PRIMARY KEY;
    //procedure GetPrimaryKey(const aTable:IEvsTableInfo);
    //UNIQUE KEY;
    //procedure GerUniqueKeys(const aTable:IEvsTableInfo);
    //FOREIGN KEY
    //procedure GetForeignKeys(const aTable:IEvsTableInfo);
    //CHECK
    //Procedure GetChecks(Const aTable:IEvsTableInfo);
    //the aTableName can be empty in which case it should either
    //return all the indices in the database or raise an exception.
    //Procedure GetIndices(const aObject:IEvsIndexList);   overload;extdecl;
    Procedure GetIndices(const aObject:IEvsDatabaseInfo);  overload;extdecl; //get all indices for all the tables in the database passed.
    Procedure GetIndices(const aObject:IEvsTableInfo);     overload;extdecl; //get all indices for the table passed.
    Procedure GetDomains(const aObject:IEvsDatabaseInfo);  overload;extdecl; //get all the domains for the database passed.
    Function GetFieldDDL(Const aObject:IEvsFieldInfo):widestring;  overload;extdecl;
    Function GetTableDDL(Const aObject:IEvsTableInfo):widestring; overload;extdecl;
    Function GetCharsets:pvararray; extdecl;
    Property Connection:IEvsConnection read GetConnection write SetConnection;
  end;

  { IEvsConnection }
  IEvsConnection = interface(IEvsCopyable)
    ['{9C2BB1DC-027A-457F-A436-1DA23D154FAB}']
    Function GetCharSet :WideString;extdecl;
    Function GetConnected :Boolean;extdecl;
    Function GetMetaData :IEvsMetaData;extdecl;
    Function GetPassword :widestring;extdecl;
    Function GetRole :widestring;extdecl;
    Function GetUserName :widestring;extdecl;
    Function Query(aSQL:wideString):IEvsDataset;extdecl;
    Function Execute(aSQL:WideString):ByteBool;extdecl;
    Procedure SetCharSet(aValue :WideString);extdecl;
    Procedure SetConnected(aValue :Boolean);extdecl;
    Procedure SetPassword(aValue :widestring);extdecl;
    Procedure SetRole(aValue :widestring);extdecl;
    Procedure SetUserName(aValue :widestring);extdecl;

    Property MetaData:IEvsMetaData read GetMetaData;
    Property UserName:widestring read GetUserName write SetUserName;
    Property Password:widestring read GetPassword write SetPassword;
    Property Role:widestring read GetRole write SetRole;
    Property CharSet:WideString read GetCharSet write SetCharSet;
    Property Connected:Boolean read GetConnected write SetConnected;
  end;

  { IEvsDataset }
  IEvsDataset = interface(IInterface)
    ['{41F0B671-25C5-4AAF-89FE-BDDB5DD3A826}']
    function GetInTrans:ByteBool;                  extdecl;
    function GetAutoTrim :ByteBool;                extdecl;
    Function GetEOF :ByteBool;                     extdecl;
    Function GetField(aIndex :Integer) :IEvsField; extdecl;
    Function GetFieldCount :Int32;                 extdecl;
    Procedure First;                               extdecl;
    function GetSQL :WideString;                   extdecl;
    Procedure Next;                                extdecl;
    Procedure Previous;                            extdecl;
    procedure SetAutoTrim(aValue :ByteBool);       extdecl;
    procedure SetSQL(aValue :WideString);          extdecl;

    procedure Commit;                              extdecl;
    procedure Rollback;                            extdecl;
    Property EOF        :ByteBool   read GetEOF;
    Property FieldCount :Int32      read GetFieldCount;
    Property SQL        :WideString read GetSQL         write SetSQL;

    Property Field[aIndex:Integer] :IEvsField read GetField;
    Property AutoTrimStrings :ByteBool read GetAutoTrim write SetAutoTrim;
    Property InTransaction   :Bytebool read GetInTrans;
  end;

  { TEvsFieldProxy }
  TEvsFieldProxy = Class(TEvsInterfacedPersistent,IEvsField)
  private
    FField     :TField;
    FDts       :IEvsDataset;

    Function GetAsBoolean :LongBool;extdecl;
    Procedure SetAsBoolean(aValue :LongBool);extdecl;
  protected
    Function GetFieldName :WideString;extdecl;
    //function GetNewValue :OLEVariant;extdecl;
    //function GetOldValue :OLEVariant;extdecl;
    Function GetReadOnly :Boolean;extdecl;
    //procedure SetNewValue(aValue :OLEVariant);extdecl;
    //procedure SetRequired(aValue :Boolean);extdecl;
    Function GetRequired :Boolean;extdecl;
    Function GetAsVariant :OLEVariant;extdecl;
    Function GetCalculated :Boolean;extdecl;
    Function GetCanModify :Boolean;extdecl;
    Function GetEditText :widestring;extdecl;
    Function GetFullName :WideString;extdecl;
    //function GetIsIndexField :Boolean;extdecl;
    Function GetIsNull :Boolean;extdecl;
    Procedure SetAsVariant(aValue :OLEVariant);extdecl;
    Procedure SetCalculated(aValue :Boolean);extdecl;
    Procedure SetEditText(aValue :widestring);extdecl;
    Procedure SetFieldName(aValue :WideString);extdecl;
    Procedure SetReadOnly(aValue :Boolean);extdecl;
    function GetIsNumeric :LongBool; extdecl;
    function GetSize:Integer;extdecl;
    function GetPrecision:Integer;extdecl;
    function GetLength:Integer;extdecl;
  public
    Constructor Create(aField:TField; aDataSet:IEvsDataset = nil);
    Destructor Destroy; override;

    Function AsString:Widestring;extdecl;
    Function AsInt32:Int32;extdecl;
    Function AsByte:Byte;extdecl;
    Function AsDouble:Double;extdecl;
    Function AsDateTime:TDateTime;extdecl;

    Property Calculated  : Boolean    read GetCalculated   write SetCalculated;
    Property CanModify   : Boolean    read GetCanModify;
    Property FullName    : WideString read GetFullName;
    Property IsNull      : Boolean    read GetIsNull;
    Property Text        : widestring read GetEditText     write SetEditText;
    Property Value       : OLEVariant read GetAsVariant    write SetAsVariant;
    Property FieldName   : WideString read GetFieldName    write SetFieldName;
    Property ReadOnly    : Boolean    read GetReadOnly     write SetReadOnly;
    Property Required    : Boolean    read GetRequired;//     write SetRequired;
    Property AsBoolean   : LongBool   read GetAsBoolean    write SetAsBoolean;
    Property IsNumeric   : LongBool   read GetIsNumeric;
    Property Size        : Integer    read GetSize;
    Property Precision   : Integer    read GetPrecision;
    PRoperty Length      : Integer    read GetLength;
  end;

  { TEvsDatasetProxy }
  TEvsDatasetProxy = class(TEvsInterfacedPersistent, IEvsDataset)
  private
    function GetSQL :Widestring; extdecl;
    procedure SetSQL(aValue :Widestring);extdecl;{$MESSAGE WARN 'Needs Implementation'}
  protected
    FDS       :TDataSet;
    FAutoTrim :Boolean;
    FOwnsDataset:Boolean;
    function GetInTrans :ByteBool;virtual;extdecl;
    Function GetBOF :ByteBool;                     extdecl;
    Function GetEOF :ByteBool;                     extdecl;
    Function GetField(aIndex :Integer) :IEvsField; extdecl;
    Function GetFieldCount :Int32;                 extdecl;
    function GetAutoTrim :ByteBool;                extdecl;
    procedure SetAutoTrim(aValue :ByteBool);       extdecl;
  public
    Constructor Create(aDataset:TDataset; OwnsDataset:Boolean = False);
    destructor Destroy; override;
    Procedure Next;extdecl;
    Procedure Previous;extdecl;
    Procedure First;extdecl;
    Procedure Commit;virtual;extdecl;
    Procedure RollBack;virtual;extdecl;
    //procedure Edit;
    //procedure Post;
    //procedure Cancel;
    Property EOF :ByteBool read GetEOF;
    Property BOF :ByteBool read GetBOF;
    Property FieldCount :Int32 read GetFieldCount;
    Property Field[aIndex:Integer]:IEvsField read GetField;
    Property SQL :Widestring read GetSQL write SetSQL;
    property AutoTrimStrings :ByteBool read GetAutoTrim write SetAutoTrim;
    property InTransaction   :ByteBool read GetInTrans;
  end;

  { TEvsAbstractConnectionProxy }
  TEvsAbstractConnectionProxy = class(TEvsInterfacedPersistent, IEvsConnection)
  private
  protected
    FCnn : TCustomConnection;
    FCnnOwner:Boolean;
    Function GetMetaData :IEvsMetaData;virtual;abstract;extdecl;
    Function InternalGetCharSet:widestring;virtual;abstract;extdecl;
    Procedure InternalSetCharSet(aValue :WideString);virtual;abstract;extdecl;

    Function InternalGetConnected :Boolean;              virtual;extdecl;
    Function InternalGetPassword :widestring;            virtual;Abstract;extdecl;
    Function InternalGetRole :widestring;                virtual;Abstract;extdecl;
    Function InternalGetUserName :widestring;            virtual;Abstract;extdecl;
    Function InternalQuery(aSQL:wideString):IEvsDataset; virtual;Abstract;extdecl;
    Function InternalExecute(aSQL:WideString):ByteBool;  virtual;Abstract;extdecl;
    Procedure InternalSetConnected(aValue :Boolean);     virtual;extdecl;
    Procedure InternalSetPassword(aValue :widestring);   virtual;Abstract;extdecl;
    Procedure InternalSetRole(aValue :widestring);       virtual;Abstract;extdecl;
    Procedure InternalSetUserName(aValue :widestring);   virtual;Abstract;extdecl;

    Function GetCharSet :WideString;extdecl;
    Procedure SetCharSet(aValue :WideString);extdecl;
    Function GetConnected :Boolean;extdecl;
    Function GetPassword :widestring;extdecl;
    Function GetRole :widestring;extdecl;
    Function GetUserName :widestring;extdecl;
    Procedure SetConnected(aValue :Boolean);extdecl;
    Procedure SetPassword(aValue :widestring);extdecl;
    Procedure SetRole(aValue :widestring);extdecl;
    Procedure SetUserName(aValue :widestring);extdecl;
  public
    Constructor Create(const aConnection:TCustomConnection; const aOwnsConnection:Boolean = True);
    destructor Destroy; override;
    Function Query(aSQL:wideString):IEvsDataset;extdecl;
    Function Execute(aSQL:WideString):ByteBool;extdecl;
    function CopyTo(const aDest :IEvsCopyable):Integer; extdecl;
    function CopyFrom(const aSource :IEvsCopyable):Integer; extdecl;
    function EqualsTo(const aCompare :IEvsCopyable) :Boolean; virtual; extdecl;
    Property MetaData:IEvsMetaData read GetMetaData;
    Property UserName  :widestring read GetUserName  write SetUserName;
    Property Password  :widestring read GetPassword  write SetPassword;
    Property Role      :widestring read GetRole      write SetRole;
    Property Connected :Boolean    read GetConnected write SetConnected;
    Property CharSet   :WideString read GetCharSet   write SetCharSet;
  end;

  { TEvsDBInfoFactory }
  TEvsDBInfoFactory = class
    class Function NewDatabaseList (const aParent:IEvsParented=nil) :IEvsDatabaseList;
    class Function NewDatabase     (const aParent:IEvsParented=nil) :IEvsDatabaseInfo;
    class Function NewTable        (const aParent:IEvsParented=nil) :IEvsTableInfo;
    class Function NewTableList    (const aParent:IEvsParented=nil) :IEvsTableList;
    class Function NewField        (const aParent:IEvsParented=nil) :IEvsFieldInfo;
    class Function NewFieldList    (const aParent:IEvsParented=nil) :IEvsFieldList;
    class Function NewTrigger      (const aParent:IEvsParented=nil) :IEvsTriggerInfo;
    class Function NewTriggerList  (const aParent:IEvsParented=nil) :IEvsTriggerList;
    class Function NewSequence     (const aParent:IEvsParented=nil) :IEvsSequenceInfo;
    class Function NewSequenceList (const aParent:IEvsParented=nil) :IEvsSequenceList;
    class Function NewIndex        (const aParent:IEvsParented=nil) :IEvsIndexInfo;
    class Function NewIndexList    (const aParent:IEvsParented=nil) :IEvsIndexList;
    class Function NewException    (const aParent:IEvsParented=nil) :IEvsExceptionInfo;
    class Function NewExceptionList(const aParent:IEvsParented=nil) :IEvsExceptionList;
    class Function NewStoredProc   (const aParent:IEvsParented=nil) :IEvsStoredInfo;
    class Function NewStoredList   (const aParent:IEvsParented=nil) :IEvsStoredList;
    class Function NewDomain       (const aParent:IEvsParented=nil) :IEvsDomainInfo;
    class Function NewDomainList   (const aParent:IEvsParented=nil) :IEvsDomainList;
    class Function NewView         (const aParent:IEvsParented=nil) :IEvsViewInfo;
    class Function NewViewList     (const aParent:IEvsParented=nil) :IEvsViewList;
    class Function NewUser         (const aParent:IEvsParented=nil) :IEvsUserInfo;
    class Function NewUserList     (const aParent:IEvsParented=nil) :IEvsUserList;
    class Function NewRole         (const aParent:IEvsParented=nil) :IEvsRoleInfo;
    class function NewRoleList     (Const aParent:IEvsParented=nil) :IEvsRoleList;
  end;

Procedure RegisterDBType(const aID:Integer; aTitle:string; aConnectProc:TConnectProc; aConnectMethod:TConnectMethod = nil; aIcon:TIcon = nil);

Function NewDatabase(const aType :Int32; const aHost, aDatabase, aUser, aPassword, aRole, aCharset :widestring) :IEvsDatabaseInfo;overload;
Function NewDatabase(const aType :Int32) :IEvsDatabaseInfo;overload;
Function Connect(const aDB:IEvsDatabaseInfo; aServerType : Integer = 0):IEvsConnection;
Function Query(const aDB:IEvsDatabaseInfo; aSQL:widestring; ExclusiveConnection:Boolean = False):IEvsDataset;{$MESSAGE WARN 'Needs Implementation'}
Function NewDatabaseList:IEvsDatabaseList;
Function GetDatabase(const aObject:IEvsParented):IEvsDatabaseInfo;
Function DatabaseList:IEvsDatabaseList;
function EqualFields(const Field1, Field2:IEvsFieldInfo):Boolean;

function FieldArray(const aList:IEvsFieldList):TIFieldArray;
function TableArray(const aList:IEvsTableList):TITableArray;

function CompareByFieldName(const Field1, Field2: IEvsFieldInfo):Integer;
function CompareByDataTypeName(const Field1, Field2 :IEvsFieldInfo):Integer;

implementation

uses uTBCommon, uTBTypes;

resourcestring
  SErrorListIndex = 'List index out of bounds (%d)';

{$REGION ' Internal Types '}
type
  THackTrans = class(TDBTransaction)
  public
    //procedure EndTransaction; override;
  end;


  { TEvsObserverList }
  TEvsObserverList = class(TEvsInterfacedPersistent, IEvsObserverList)
  private
    FList: TThreadList;
  protected
    function Get(Index: Integer): IEvsObserver;                 extdecl;
    function GetCapacity: Integer;                              extdecl;
    function GetCount: Integer;                                 extdecl;
    procedure Put(Index: Integer; const Item: IEvsObserver);    extdecl;
    procedure SetCapacity(NewCapacity: Integer);                extdecl;
    procedure SetCount(NewCount: Integer);                      extdecl;
  public
    Constructor Create;
    destructor Destroy; override;
    procedure Clear;                                            extdecl;
    function ObjectRef :TObject;                                extdecl;
    procedure Delete(Index: Integer);                           extdecl;
    procedure Exchange(Index1, Index2: Integer);                extdecl;
    function Expand: TEvsObserverList;                          extdecl;
    function First: IEvsObserver;                               extdecl;
    //function GetEnumerator: TEvsObserverListEnumerator;         extdecl;
    function IndexOf(const Item: IEvsObserver): Integer;        extdecl;
    function Add(const Item: IEvsObserver): Integer;            extdecl;
    procedure Insert(Index: Integer; const Item: IEvsObserver); extdecl;
    function Last: IEvsObserver;                                extdecl;
    function Remove(const Item: IEvsObserver): Integer;         extdecl;
    procedure Lock;                                             extdecl;
    procedure Unlock;                                           extdecl;

    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
    property Items[Index: Integer]: IEvsObserver read Get write Put; default;
  end;

  { TEvsFieldInfo }
  TEvsFieldInfo = class(TEvsDBInfo, IEvsFieldInfo)
  private
    FFieldName    :widestring;
    FDescription  :widestring;
    FAllowNulls   :ByteBool;
    FDataTypeName :widestring;
    FDefaultValue :Variant;
    FAutoNumber   :ByteBool;
    FFieldSize    :integer;
    FFieldScale   :Integer;
    FCollation    :widestring;
    FCharset      :widestring;
    FCheck        :widestring;
    FCalculated   :widestring;
    FDataGroup    :TEvsDataGroup;
    Function GetAllowNull  :ByteBool;extdecl;
    Function GetAutoNumber :ByteBool;extdecl;
    Function GetCalculated :widestring;extdecl;
    Function GetCanAutoInc :WordBool;extdecl;
    Function GetCharset :widestring;extdecl;
    Function GetCheck :widestring;extdecl;
    Function GetColation :widestring;extdecl;
    function GetDataGroup :TEvsDataGroup;extdecl;
    Function GetDataTypeName :widestring;extdecl;
    Function GetDefaultValue :OLEVariant;extdecl;
    Function GetFieldDescription :widestring;extdecl;
    Function GetFieldName :widestring;extdecl;
    Function GetFieldScale :Integer;extdecl;
    Function GetFieldSize :integer;extdecl;
    Procedure SetAllowNull(aValue :ByteBool);extdecl;
    Procedure SetAutoNumber(aValue :ByteBool);extdecl;
    Procedure SetCalculated(aValue :widestring);extdecl;
    Procedure SetCharset(aValue :widestring);extdecl;
    Procedure SetCheck(aValue :widestring);extdecl;
    Procedure SetColation(aValue :widestring);extdecl;
    procedure SetDataGroup(aValue :TEvsDataGroup);extdecl;
    //procedure SetDataType(aValue :widestring);extdecl;
    Procedure SetDataTypeName(aValue :widestring);extdecl;
    Procedure SetDefaultValue(aValue :OLEVariant);extdecl;
    Procedure SetFieldDescription(aValue :widestring);extdecl;
    Procedure SetFieldName(aValue :widestring);extdecl;
    Procedure SetFieldScale(aValue :Integer);extdecl;
    Procedure SetFieldSize(aValue :integer);extdecl;
  public
    Function EqualsTo(const aCompare :IEvsCopyable) :Boolean; override; extdecl;
    procedure Assign(Source :TPersistent); override;
  published
    Property FieldName    : widestring read GetFieldName write SetFieldName;
    Property Description  : widestring read GetFieldDescription write SetFieldDescription;
    Property AllowNulls   : ByteBool           read GetAllowNull    write SetAllowNull default True;
    Property DataTypeName : widestring         read GetDataTypeName write SetDataTypeName;
    Property DefaultValue : OLEVariant         read GetDefaultValue write SetDefaultValue;
    Property AutoNumber   : ByteBool           read GetAutoNumber   write SetAutoNumber default False;
    Property FieldSize    : integer            read GetFieldSize    write SetFieldSize;
    Property FieldScale   : Integer            read GetFieldScale   write SetFieldScale;
    Property Collation    : widestring         read GetColation     write SetColation;
    Property Charset      : widestring         read GetCharset      write SetCharset;
    Property Check        : widestring         read GetCheck        write SetCheck;
    Property Calculated   : widestring         read GetCalculated   write SetCalculated;
    Property DataGroup    : TEvsDataGroup      Read GetDataGroup    write SetDataGroup;
  end;
  { IEvsIndexFieldInfo }
  IEvsIndexFieldInfo = Interface(IInterface)
    ['{92E4FCFA-8199-4476-869F-2F3D007AE9DE}']
    function GetField :IEvsFieldInfo;extdecl;
    function GetOrder :TEvsSortOrder;extdecl;
    procedure SetField(aValue :IEvsFieldInfo);extdecl;
    procedure SetOrder(aValue :TEvsSortOrder);extdecl;
    property Field: IEvsFieldInfo read GetField write SetField;
    property Order: TEvsSortOrder read GetOrder write SetOrder;
  end;
  { TEvsIndexFieldInfo }
  TEvsIndexFieldInfo = class(TEvsDBInfo, IEvsIndexFieldInfo)
  private
    FField :IEvsFieldInfo; // this is a reference not a value.
    FOrder :TEvsSortOrder; // value not reference
    Function GetField :IEvsFieldInfo;extdecl;
    Function GetOrder :TEvsSortOrder;extdecl;
    Procedure SetField(aValue :IEvsFieldInfo);extdecl;
    Procedure SetOrder(aValue :TEvsSortOrder);extdecl;
  public
    Function EqualsTo(const aCompare :IEvsCopyable) :Boolean; override; extdecl;
    procedure Assign(aSource :TPersistent); override;
  public
    Property Field :IEvsFieldInfo read GetField write SetField;
    Property Order :TEvsSortOrder read GetOrder write SetOrder;
  end;
  { TEvsIndexInfo }
  TEvsIndexInfo = class(TEvsDBInfo, IEvsIndexInfo)
  private
    //FTable      : TEVSDBTableInfo;
    FList       : IInterfaceList;  // value : a list of IEvsIndexFieldInfo.
    FUnique     : Boolean;         // value
    FPrimary    : Boolean;         // value
    FOrder      : TEvsSortOrder;   // value
    FIndexName  : Widestring;      // value
    FDescription: WideString;      // value
    function GetDescription :widestring;extdecl;
    function GetField(aIndex: Integer): IEvsFieldInfo;extdecl;
    function GetFieldCount: Integer;extdecl;
    function GetFieldOrder(aIndex: Integer): TEvsSortOrder;extdecl;
    function GetIndexName : WideString;extdecl;
    function GetOrder :TEvsSortOrder;extdecl;
    function GetPrimary :ByteBool;extdecl;
    function GetTable :IEvsTableInfo;extdecl;
    function GetUnique :ByteBool;extdecl;
    procedure SetDescription(aValue :widestring);extdecl;
    procedure SetField(Index: Integer; const Value: IEvsFieldInfo);extdecl;
    procedure SetFieldOrder(Index: Integer; const Value: TEvsSortOrder);extdecl;
    procedure SetIndexName(const aValue: WideString);extdecl;
    procedure SetOrder(const aValue: TEvsSortOrder);extdecl;
    procedure SetPrimary(aValue: ByteBool);extdecl;
    procedure SetTable(aValue :IEvsTableInfo);extdecl;
    procedure SetUnique(aValue: ByteBool);extdecl;

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
    function IndexOf(const aField:IEvsFieldInfo):integer;overload;extdecl;
    function IndexOf(const aFieldName:string):Integer;overload;extdecl;
    //function IndexOf(const FieldID:TGUID):Integer;overload;
  public
    constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    function TableName :string;extdecl;
    //function GetEnumerator: TEVSDBIndexInfoEnumerator;
    //function IterateFields: TEVSDBIndexFieldEnumerator;

    //procedure AssignProperties(Source : TEVSDBBaseInfo); override;
    //procedure Assign(Source : TPersistent); override;
    //procedure SaveToStream(const aStream:TStream);override;extdecl;
    //procedure LoadFromStream(const aStream:TStream);override;extdecl;
    procedure Assign(Source :TPersistent); override;
    procedure SwapFields(const Index1,Index2:Integer);extdecl;
    procedure AppendField(const aField:IEVSFieldInfo; const aOrder: TEvsSortOrder);extdecl;
    procedure DeleteField(const aIndex : Integer);overload;extdecl;
    procedure DeleteField(const aField:IEvsFieldInfo);overload;extdecl;
    procedure ClearFields;extdecl;
    //function FieldByName(const FieldName:string):TEVSDBFieldInfo;extdecl;

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
    FCharset     :WideString;
    FCollation   :WideString;
    FDescription :WideString;
    FFieldList   :IEvsFieldList;
    FIndexList   :IEvsIndexList;
    FTriggerList :IEvsTriggerList;
    FTableName   :WideString;
    FSysTable    :LongBool;
    Function GetCharset :WideString;extdecl;
    Function GetCollation :WideString;extdecl;
    Function GetDescription :wideString;extdecl;
    Function GetField(aIndex :Integer) :IEvsFieldInfo;extdecl;
    Function GetFieldCount :Integer;extdecl;
    Function GetIndex(aIndex :Integer) :IEvsIndexInfo;extdecl;
    Function GetIndexCount :Integer;extdecl;
    function GetSystemTable :LongBool;extdecl;
    Function GetTriggerCount :Integer;extdecl;
    Function GetTableName :WideString;extdecl;
    Function GetTrigger(aIndex :Integer) :IEvsTriggerInfo; extdecl;
    Procedure SetCharSet(aValue :WideString);extdecl;
    Procedure SetCollation(aValue :WideString);extdecl;
    Procedure SetDescription(aValue :wideString);extdecl;
    Procedure SetField(aIndex :Integer; aValue :IEvsFieldInfo);extdecl;
    Procedure SetIndex(aIndex :Integer; aValue :IEvsIndexInfo);extdecl;
    procedure SetSystemTable(aValue :LongBool);extdecl;
    Procedure SetTableName(aValue :WideString);extdecl;
    Procedure SetTrigger(aIndex :Integer; aValue :IEvsTriggerInfo); extdecl;
    //what other data does a table have.
    //triggers?
    //property SchemaName           :WideString          read GetSchemaName       write SetSchemaName;
    //property FullTableName        :WideString          read GetFullName;
  protected
    Function FieldIndexOf(const aName:Widestring):Integer;overload;extdecl;
    Function FieldIndexOf(const aField:IEvsFieldInfo):Integer;overload;extdecl;
  public
    //Function FieldByName(Const aFieldName:WideString):IEvsFieldInfo;extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    procedure Assign(aSource :TPersistent); override;

    Function AddField(const aFieldName, aDataType :WideString;
                      const aFieldsIze, aFieldScale :Integer;
                      const aCharset, aCollation :WideString;
                      const AllowNulls, AutoNumber :ByteBool) :IEvsFieldInfo;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Function AddIndex(const aName:widestring; const aFields:Array of IEvsFieldInfo;
                      const aFieldOrders:array of TEvsSortOrder):IEvsIndexInfo;overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Function AddIndex(const aName:widestring; const aFieldNames:Array of WideString;
                      const aFieldOrders:array of TEvsSortOrder):IEvsIndexInfo;overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
    Function AddIndex(const aName:widestring; aOrder:TEvsSortOrder):IEvsIndexInfo;overload;extdecl;
    Function NewField :IEvsFieldInfo; extdecl;{$MESSAGE WARN 'Needs Testing'}
    Function NewIndex :IEvsIndexInfo; extdecl;{$MESSAGE WARN 'Needs Testing'}
    Function NewTrigger :IEvsTriggerInfo; extdecl;{$MESSAGE WARN 'Needs Testing'}
    Function FieldByName(const aFieldName:WideString):IEvsFieldInfo;extdecl;{$MESSAGE WARN 'Needs Testing'}

    Procedure Remove(const aObject :IEvsTriggerInfo); overload;extdecl;
    Procedure Remove(const aObject :IEvsFieldInfo); overload;extdecl;
    Procedure Remove(const aObject :IEvsIndexInfo); overload;extdecl;

    Property TableName   :WideString read GetTableName   write SetTableName;
    Property Description :WideString read GetDescription write SetDescription;
    Property CharSet     :WideString read GetCharset     write SetCharSet;
    Property Collation   :WideString read GetCollation   write SetCollation; // default collation for the table it will be used when creating string fields with no collation information.

    Property FieldCount   :Integer read GetFieldCount;
    Property IndexCount   :Integer read GetIndexCount;
    property TriggerCount :Integer read GetTriggerCount;
    Property Index  [aIndex :Integer] :IEvsIndexInfo   read GetIndex       write SetIndex;
    Property Field  [aIndex :Integer] :IEvsFieldInfo   read GetField       write SetField;        default;
    Property Trigger[aIndex :Integer] :IEvsTriggerInfo read GetTrigger     write SetTrigger;
    Property SystemTable              :LongBool        read GetSystemTable write SetSystemTable;
  end;
  { TEvsCredentials }
  TEvsCredentials = class(TEvsDBInfo, IEvsCredentials){$MESSAGE WARN 'Needs Testing'}
  private
    FPassword    :WideString;
    FRole        :WideString;
    FUserName    :WideString;
    FCharset     :WideString;
    FSavePwd     :LongBool;
    FLastChanged :TDateTime;
    Function GetCharSet  :WideString;            extdecl;
    Function GetPassword :WideString;            extdecl;
    Function GetRole     :WideString;            extdecl;
    Function GetSavePwd  :LongBool;              extdecl;
    Function GetUserName :WideString;            extdecl;
    function GetLastChanged :TDateTime;          extdecl;
    Procedure SetCharset (aValue :WideString);   extdecl;
    Procedure SetPassword(aValue :WideString);   extdecl;
    Procedure SetRole    (aValue :WideString);   extdecl;
    Procedure SetSavePwd (aValue :LongBool);     extdecl;
    Procedure SetUserName(aValue :WideString);   extdecl;
    Procedure SetLastChanged(aValue :TDateTime); extdecl;
  public
    procedure Assign(Source :TPersistent); override;
  published
    Property UserName     :WideString read GetUserName    write SetUserName;
    Property Password     :WideString read GetPassword    write SetPassword;
    Property Role         :WideString read GetRole        write SetRole;
    Property Charset      :WideString read GetCharSet     write SetCharset;
    Property SavePassword :LongBool   read GetSavePwd     write SetSavePwd;
    property LastChanged  :TDateTime  read GetLastChanged write SetLastChanged;
  end;

  { TEvsDatabaseInfo }
  TEvsDatabaseInfo = class(TEvsDBInfo, IEvsDatabaseInfo)
  private
    FDefaultCollation :WideString;
    FDefaultCharset   :WideString;
    FCredentials      :IEvsCredentials;
    FDatabase         :WideString;
    FHost             :WideString;
    FPageSize         :Integer;
    FServerID         :Integer;
    FCnn              :IEvsConnection;
    FTables           :IEvsTableList;      //1
    FIndices          :IEvsIndexList;      //not used at this time all indices are owned by tables so far.
    FTriggers         :IEvsTriggerList;    //database level triggers only eg on connect on disconnect etc.
    FViews            :IEvsViewList;       //4
    FStoredProcs      :IEvsStoredList;
    FSequences        :IEvsSequenceList;   //6
    FExceptions       :IEvsExceptionList;
    FUdfs             :IEvsUDFList;        //8
    FDomains          :IEvsDomainList;
    FUsers            :IEvsUserList;       //10
    FRoles            :IEvsRoleList;       //11
    FTitle            :WideString;

    Function GetConnection  :IEvsConnection;                   extdecl;
    Function GetCredentials :IEvsCredentials;                  extdecl;
    Function GetDatabase :WideString;                          extdecl;
    Function GetDefaultCharSet :WideString;                    extdecl;
    function IEvsDatabaseInfo.GetDefCollation = GetDefaultColation;
    Function GetDefaultColation :WideString;                   extdecl;
    function GetDomain(aIndex :Integer):IEvsDomainInfo;        extdecl;
    Function GetExceptionCount :Integer;                       extdecl;
    Function GetExceptions(aIndex :Integer):IEvsExceptionInfo; extdecl;
    Function GetHost : WideString;                             extdecl;
    Function GetIndex(aIndex :Integer):IEvsIndexInfo;          extdecl;
    Function GetRole(aIndex :Integer):IEvsRoleInfo;            extdecl;
    Function GetIndexCount :Integer;                           extdecl;
    Function GetPageSize : Integer;                            extdecl;
    Function GetRoleCount :Integer;                            extdecl;
    Function GetSequences(aIndex :Integer):IEvsGeneratorInfo;  extdecl;
    Function GetSequenceCount :Integer;                        extdecl;
    Function GetServerID :Integer;                             extdecl;
    Function GetUDF(aIndex :Integer):IEvsUDFInfo;              extdecl;
    Function GetUdfCount :Integer;                             extdecl;
    Function GetDomainCount :Integer;                          extdecl;
    Function GetUser(aIndex :Integer):IEvsUserInfo;            extdecl;
    Function GetUserCount :Integer;                            extdecl;
    Function GetTitle:WideString;                              extdecl;
    Procedure SetConnection(aValue :IEvsConnection);           extdecl;
    Procedure SetDatabase(aValue :WideString);                 extdecl;
    Procedure SetDefaultCharSet(aValue :Widestring);           extdecl;
    function IEvsDatabaseInfo.SetDefCollation = SetDefaultColation;
    Procedure SetDefaultColation(aValue :WideString);          extdecl;
    Procedure SetHost(aValue :WideString);                     extdecl;
    Procedure SetPageSize(aValue :Integer);                    extdecl;
    Procedure SetServerID(aValue :Integer);                    extdecl;
    Procedure SetTitle(aValue :WideString);                   extdecl;
  protected
    Function GetStored(aIndex :Integer):IEvsStoredInfo;   extdecl;
    Function GetTable(aIndex :Integer) :IEvsTableInfo;    extdecl;
    Function GetTableCount :Integer;                      extdecl;
    Function GetProcedureCount :Integer;                  extdecl;
    Function GetViewCount :Integer;                       extdecl;
    Function GetView(aIndex :Integer):IEvsViewInfo;       extdecl;
    Function GetTriggerCount :Integer;                    extdecl;
    Function GetTrigger(aIndex :Integer):IEvsTriggerInfo; extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    procedure Assign(Source :TPersistent); override;

    Function TableList     :IEvsTableList;     extdecl; //FTables      := Nil;
    Function StoredList    :IEvsStoredList;    extdecl; //FStoredProcs := Nil;
    Function ViewList      :IEvsViewList;      extdecl; //FViews       := Nil;
    Function SequenceList  :IEvsSequenceList;  extdecl; //FSequences   := Nil;
    Function TriggerList   :IEvsTriggerList;   extdecl; //FTriggers    := Nil;
    Function UDFList       :IEvsUDFList;       extdecl; //FUdfs        := Nil;
    Function IndexList     :IEvsIndexList;     extdecl; //FIndices     := Nil;
    Function ExceptionList :IEvsExceptionList; extdecl; //FExceptions  := Nil;
    Function DomainList    :IEvsDomainList;    extdecl; //FDomains     := Nil;

    Function NewTable(const aTableName:WideString):IEvsTableInfo; extdecl;                                                            {$MESSAGE WARN 'Needs Testing'}

    Function NewDomain(const aDomainName:WideString; const aDataType:WideString; const aSize:integer;
                       const aCheck :WideString=''; aCharset : WideString=''; aCollation:WideString='') : IEvsDomainInfo;    extdecl; {$MESSAGE WARN 'Needs Testing'}
    Function NewIndex(const aName:WideString; const aORder: TEvsSortOrder; aFieldList:array of IEvsFieldInfo):IEvsIndexInfo; extdecl; {$MESSAGE WARN 'Needs Testing'}
    Function NewStored(const aName:WideString; const aSql:WideString):IEvsStoredInfo;           extdecl;                              {$MESSAGE WARN 'Needs Testing'}
    Function NewView(const aName:WideString; const aSql:WideString):IEvsViewInfo;               extdecl;                              {$MESSAGE WARN 'Needs Testing'}
    Function NewException(const aName:WideString; const aMessage:WideString):IEvsExceptionInfo; extdecl;                              {$MESSAGE WARN 'Needs Testing'}
    Function NewUDF(const aName:WideString):IEvsUDFInfo;                                        extdecl;                              {$MESSAGE WARN 'Needs Testing'}
    Function NewTrigger  :IEvsTriggerInfo;                                                      extdecl;                              {$MESSAGE WARN 'Needs Testing'}
    Function NewSequence :IEvsSequenceInfo;                                                     extdecl;                              {$MESSAGE WARN 'Needs Testing'}
    Function NewUser(const aUserName:WideString=''):IEvsUserInfo;                      overload;extdecl;                              {$MESSAGE WARN 'Needs Testing'}
    Function NewUser:IEvsUserInfo;                                                     overload;extdecl;                              {$MESSAGE WARN 'Needs Testing'}
    Function NewRole(const aRoleName:WideString=''):IEvsRoleInfo;                      overload;extdecl;                              {$MESSAGE WARN 'Needs Testing'}
    Function NewRole:IEvsRoleInfo;                                                     overload;extdecl;                              {$MESSAGE WARN 'Needs Testing'}

    Procedure Remove(const aObject :IEvsTableInfo);    overload;extdecl;
    Procedure Remove(const aObject :IEvsIndexInfo);    overload;extdecl;
    Procedure Remove(const aObject :IEvsTriggerInfo);  overload;extdecl;
    Procedure Remove(const aObject :IEvsFieldInfo);    overload;extdecl;
    Procedure Remove(const aObject :IEvsStoredInfo);   overload;extdecl;
    Procedure Remove(const aObject :IEvsSequenceInfo); overload;extdecl;
    Procedure Remove(const aObject :IEvsExceptionInfo);overload;extdecl;
    Procedure Remove(const aObject :IEvsUDFInfo);      overload;extdecl;
    Procedure Remove(const aObject :IEvsViewInfo);     overload;extdecl;
    Procedure Remove(const aObject :IEvsUserInfo);     overload;extdecl;

    Procedure ClearTables;    extdecl;
    Procedure ClearStored;    extdecl;
    Procedure ClearExceptions;extdecl;
    Procedure ClearSequences; extdecl;
    Procedure ClearViews;     extdecl;
    Procedure ClearTriggers;  extdecl;
    Procedure ClearUDFs;      extdecl;
    Procedure ClearDomains;    extdecl;
    Procedure ClearRoles;     extdecl;
    Procedure ClearUsers;     extdecl;

    Property Credentials     :IEvsCredentials read GetCredentials;// write SetCredentials;
    Property DefaultCharset  :Widestring      read GetDefaultCharSet  write SetDefaultCharSet;
    Property DefaultColation :widestring      read GetDefaultColation write SetDefaultColation;
    Property Database        :WideString      read GetDatabase        write SetDatabase;
    Property Host            :WideString      read GetHost            write SetHost;
    Property PageSize        :Integer         read GetPageSize        write SetPageSize;
    Property Connection      :IEvsConnection  read GetConnection      write SetConnection;
    Property Title           :WideString      read GetTitle           write SetTitle;
    Property ServerKind      :Integer         read GetServerID        write SetServerID;

    Property Table      [aIndex :Integer] :IEvsTableInfo     read GetTable;      /// Tables      //FTables     :=Nil;
    Property StoredProcs[aIndex :Integer] :IEvsStoredInfo    read GetStored;     /// StoredProc  //FStoredProcs:=Nil;
    Property Exception  [aIndex :Integer] :IEvsExceptionInfo read GetExceptions; /// Exceptions  //FExceptions :=Nil;
    Property Sequence   [aIndex :Integer] :IEvsGeneratorInfo read GetSequences;  /// Sequences   //FSequences  :=Nil;
    Property Trigger    [aIndex :Integer] :IEvsTriggerInfo   read GetTrigger;    /// Triggers    //FTriggers   :=Nil;
    Property View       [aIndex :Integer] :IEvsViewInfo      read GetView;       /// Views       //FViews      :=Nil;
    Property UDF        [aIndex :Integer] :IEvsUDFInfo       read GetUDF;        /// UDFs        //FUdfs       :=Nil;
    Property Domain     [aIndex :Integer] :IEvsDomainInfo    read GetDomain;     /// Domains     //FDomains    :=Nil;
    Property Index      [aIndex :Integer] :IEvsIndexInfo     read GetIndex;      /// Indices     //FIndices    :=Nil;
    Property User       [aIndex :Integer] :IEvsUserInfo      read GetUser;       /// Users
    Property Role       [aIndex :Integer] :IEvsRoleInfo      read GetRole;       /// Roles
                                                                                 /// Rights ??
                                                                                 /// FChecks??
    Property TableCount     :Integer read GetTableCount;
    Property ExceptionCount :Integer read GetExceptionCount;
    Property ProcedureCount :Integer read GetProcedureCount;
    Property SequenceCount  :Integer read GetSequenceCount;
    Property TriggerCount   :Integer read GetTriggerCount;
    Property ViewCount      :Integer read GetViewCount;
    Property IndexCount     :Integer read GetIndexCount;  //????
    Property UserCount      :Integer read GetUserCount;
    Property UdfCount       :Integer read GetUdfCount;
    Property DomainCount    :Integer read GetDomainCount;
    Property RoleCount      :Integer read GetRoleCount;
  end;
  { TEvsExceptionInfo }
  TEvsExceptionInfo = class(TEvsDBInfo, IEvsExceptionInfo)
  private
    FDescription :WideString;
    FMessage     :WideString;
    FName        :WideString;
    FNumber      :WideString;
    FSystem      :ByteBool;
  public
    procedure Assign(Source :TPersistent); override;
  published
    function GetDescription :WideString;extdecl;
    function GetMessage     :WideString;extdecl;
    function GetName        :WideString;extdecl;
    function GetNumber      :WideString;extdecl;
    function GetSystem      :ByteBool;  extdecl;
    procedure SetDescription(aValue :WideString);extdecl;
    procedure SetMessage(aValue :WideString);extdecl;
    procedure SetName(aValue :WideString);extdecl;
    procedure SetNumber(aValue :WideString);extdecl;
    procedure SetSystem(aValue :ByteBool);extdecl;

    property Name        : WideString read FName        write SetName;
    property Description : widestring read FDescription write SetDescription;
    property Number      : WideString read FNumber      write SetNumber;
    property Message     : WideString read FMessage     write SetMessage;
    property System      : ByteBool   read FSystem      write SetSystem;
  end;
  { TEvsSequenceInfo }
  TEvsSequenceInfo = class(TEvsDBInfo, IEvsGeneratorInfo)
  private
    FName :WideString;
    FStep :Int64; //is it possible to have fractional steps? // not applicable on firebird.
  public
    procedure Assign(Source :TPersistent); override;
    function  GetCurrentValue :Int64;extdecl; {$MESSAGE WARN 'Needs Implementation'}
    function  GetName :WideString;extdecl;
    procedure SetCurrentValue(aValue :Int64);extdecl;
    procedure SetName(aValue :widestring);extdecl;

    property Name :WideString read GetName write SetName;
    property CurrentValue  :Int64      read GetCurrentValue  write SetCurrentValue;
  end;
  { TEvsStoredInfo }
  TEvsStoredInfo = class(TEvsDBInfo, IEvsStoredInfo) {$MESSAGE INFO 'One more method for the next version!'}
    //there is one more method missing, a way to pass an existing field as a reference
    //point for a new result field aka create a copy from an existing field, after all, those return
    //fields are based on existing table or view columns.
    {$MESSAGE WARN 'Update flags Need fine tunning'}
  private
    FList        :TInterfaceList;
    FDescription :Widestring;
    FSQL         :WideString;
    FName        :WideString;
  protected
    Function GetField(aIndex :Integer) :IEvsFieldInfo; extdecl;
    Function GetDescription :Widestring;               extdecl;
    Function GetFieldCount :integer;                   extdecl;
    Function GetSPName :WideString;                    extdecl;
    Function GetSql :WideString;                       extdecl;
    Procedure SetField(aIndex :Integer; aValue :IEvsFieldInfo);extdecl;
    Procedure SetSPName(aValue :WideString);                   extdecl;
    Procedure SetSql(aValue :WideString);                      extdecl;
    Procedure SetDescription(aValue :Widestring);               extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    procedure Assign(Source :TPersistent); override;
    //the following two methods are used exclusively from the drivers to add the
    //return fields of stored procedure.
    Procedure AddField(const aField:IEvsFieldInfo);extdecl;//adds the passed field in the list.
    Function NewField(const aName:WideString):IEvsFieldInfo;extdecl;//creates a new field adds it in the list and returns it for farther initialization.

    Property Name:WideString read GetSPName write SetSPName;
    Property Description:Widestring read GetDescription write SetDescription;
    Property Fields[aIndex:Integer]:IEvsFieldInfo read GetField write SetField; // the fields returned by the stored procedure. do i need then?
    Property FieldCount:Integer read GetFieldCount;
    Property SQL:WideString read GetSql write SetSql;
  end;
  { TEvsUserInfo }
  TEvsUserInfo = class(TEvsDBInfo, IEvsUserInfo)
  private
    FFirstName  :WideString;
    FLastName   :WideString;
    FMiddleName :WideString;
    FPassword   :WideString;
    FUserName   :WideString;
  protected
    Function GetFirstName :WideString;extdecl;
    Function GetLastName :WideString;extdecl;
    Function GetMiddleName :WideString;extdecl;
    Function GetPassword :WideString;extdecl;
    Function GetUserName :WideString;extdecl;
    Procedure SetFirstName(aValue :WideString);extdecl;
    Procedure SetLastName(aValue :WideString);extdecl;
    Procedure SetMiddleName(aValue :WideString);extdecl;
    Procedure SetPassword(aValue :WideString);extdecl;
    Procedure SetUserName(aValue :WideString);extdecl;
  public
    procedure Assign(Source :TPersistent); override;
  published
    Property UserName   :WideString read GetUserName   write SetUserName;
    Property Password   :WideString read GetPassword   write SetPassword;
    //optional data
    Property FirstName  :WideString read GetFirstName  write SetFirstName;
    Property MiddleName :WideString read GetMiddleName write SetMiddleName;
    Property LastName   :WideString read GetLastName   write SetLastName;
  end;
  { TEvsDomainInfo }
  TEvsDomainInfo = class(TEvsDBInfo, IEvsDomainInfo)
  private
    FDataType   :WideString;
    FDefault    :OLEVariant;
    FCheck      :WideString;
    FCharset    :WideString;
    FCollation  :WideString;
    FName       :WideString;
    FSql        :WideString;
    FSize       :Integer;
    Function GetCharSet :WideString;                  extdecl;
    Function GetCheckConstraint :WideString;          extdecl;
    Function GetCollation :WideString;                extdecl;
    Function GetDatatype :WideString;                 extdecl;
    Function GetDefaultValue :OLEVariant;             extdecl;
    Function GetName :WideString;                     extdecl;
    Function GetSQL :WideString;                      extdecl;
    Function GetSize :Integer;                        extdecl;
    Procedure SetCharSet(aValue :WideString);         extdecl;
    Procedure SetCheckConstraint(aValue :WideString); extdecl;
    Procedure SetCollation(aValue :WideString);       extdecl;
    Procedure SetDatatype(aValue :WideString);        extdecl;
    Procedure SetDefaultValue(aValue :OLEVariant);    extdecl;
    Procedure SetName(aValue :WideString);            extdecl;
    Procedure SetSQL(aValue :WideString);             extdecl;
    Procedure SetSize(aValue :Integer);               extdecl;
  public
    procedure Assign(Source :TPersistent); override;
  published
    Property Datatype        :WideString read GetDatatype        write SetDatatype;
    Property DefaultValue    :OLEVariant read GetDefaultValue    write SetDefaultValue;
    Property CheckConstraint :WideString read GetCheckConstraint write SetCheckConstraint;
    Property CharSet         :WideString read GetCharSet         write SetCharSet;
    Property Collation       :WideString read GetCollation       write SetCollation;
    Property Name            :WideString read GetName            write SetName;
    Property SQL             :WideString read GetSQL             write SetSQL;
    Property Size            :Integer    read GetSize            write SetSize;
  end;

  { TEvsTriggerInfo }
  TEvsTriggerInfo = class(TEvsDBInfo, IEvsTriggerInfo){$MESSAGE WARN 'Needs EqualsTo implementation'}
  private                                             {$MESSAGE WARN 'Copyable implementation'}
    FEvent     :TEvsTriggerEvents;  //value types
    FEventType :TEvsTriggerType;
    FSQL       :WideString;
    FDescr     :Widestring;
    FName      :Widestring;
    FActive    :Boolean;
  protected
    Function GetActive :ByteBool;                      extdecl;
    Function GetEvent :TEvsTriggerEvents;              extdecl;
    Function GetEventType :TEvsTriggerType;            extdecl;
    Function GetSQL :WideString;                       extdecl;
    Function GetTriggerDescription :WideString;        extdecl;
    Function GetTriggerName :WideString;               extdecl;
    Procedure SetActive(aValue :ByteBool);             extdecl;
    Procedure SetEvent(aValue :TEvsTriggerEvents);     extdecl;
    Procedure SetEventType(aValue :TEvsTriggerType);   extdecl;
    Procedure SetSQL(aValue :WideString);              extdecl;
    Procedure SetTriggerDscription(aValue :WideString);extdecl;
    Procedure SetTriggerName(aValue :WideString);      extdecl;
  public
    procedure Assign(Source :TPersistent); override;
    Property Name        :WideString        read GetTriggerName        write SetTriggerName;
    Property Description :WideString        read GetTriggerDescription write SetTriggerDscription;
    Property SQL         :WideString        read GetSQL                write SetSQL; //the DDL command no partial commands here.
    Property Event       :TEvsTriggerEvents read GetEvent              write SetEvent;
    Property TriggerType :TEvsTriggerType   read GetEventType          write SetEventType;
    Property Active      :ByteBool          read GetActive             write SetActive;
  end;

  { TEvsViewInfo }
  TEvsViewInfo = class(TEvsDBInfo, IEvsViewInfo)
  private
    FDescription :WideString;
    FName        :WideString;
    FSql         :WideString;
    FFieldList   :IEvsFieldList;
    Procedure SetDescription(aValue :WideString);extdecl;
    Procedure SetFieldList(aValue :IEvsFieldList);extdecl;
    Function GetDescription:WideString;extdecl;
    Function GetFieldList :IEvsFieldList;extdecl;
  protected
    Function GetField(aIndex :Integer) :IEvsFieldInfo;extdecl;
    Function GetName :WideString;extdecl;
    Function GetSQL :WideString;extdecl;
    Procedure SetField(aIndex :Integer; aValue :IEvsFieldInfo);extdecl;
    Procedure SetName(aValue :WideString);extdecl;
    Procedure SetSQL(aValue :WideString);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    procedure Assign(Source :TPersistent); override;

    Function FieldCount:integer;extdecl;
    Property SQL:WideString read GetSQL write SetSQL;
    Property Name:WideString read GetName write SetName;
    Property FieldList:IEvsFieldList read FFieldList write SetFieldList;
    Property Field[aIndex:Integer]:IEvsFieldInfo read GetField write SetField;
    property Description:WideString read GetDescription write SetDescription;
  end;

  { TEvsRoleInfo }

  TEvsRoleInfo = class(TEvsDBInfo, IEvsRoleInfo){$MESSAGE WARN 'Incomplete'}
  private
    FName  : WideString;
    FUsers : IEvsUserList;
  protected
    Function GetName :WideString;                             extdecl;
    Function GetUser(aIndex :Integer) :IEvsUserInfo;          extdecl;
    Function GetUserCount :Integer;                           extdecl;
    Procedure SetName(aValue :WideString);                    extdecl;
    Procedure SetUser(aIndex :Integer; aValue :IEvsUserInfo); extdecl;
  public
    Property Name:WideString read GetName write SetName;
    Property User[aIndex:Integer]:IEvsUserInfo read GetUser write SetUser;
    Property UserCount:Integer read GetUserCount;
  end;

  //------------------------------------------------------
  //-- L  I  S  T  s  --
  //------------------------------------------------------
  { TEvsTableList }
  TEvsTableList = class(TEvsDBInfo, IEvsTableList)
  private
    //FList:TInterfaceList;
    FList:IInterfaceList;
    //procedure Put(aIDx : Integer; aValue :IUnknown);extdecl;
  protected
    Function Get(aIdx : Integer) : IEvsTableInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsTableInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    procedure Assign(Source :TPersistent); override;
    Procedure Clear;extdecl;
    Procedure Delete(aIndex : Integer);extdecl;
    Procedure Exchange(aIndex1,aIndex2 : Integer);extdecl;
    Function New :IEvsTableInfo;extdecl;
    Function First : IEvsTableInfo;extdecl;
    Function IndexOf(aItem : IEvsTableInfo) : Integer;extdecl;
    Function Add(aItem : IEvsTableInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aItem : IEvsTableInfo);extdecl;
    Function Last : IEvsTableInfo;extdecl;
    Function Remove(aItem : IEvsTableInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;

    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[index : Integer] : IEvsTableInfo read Get write Put;default;
  end;
  { TEvsFieldList }
  TEvsFieldList = class(TEvsDBInfo, IEvsFieldList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsFieldInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsFieldInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    procedure Assign(aSource :TPersistent); override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New :IEvsFieldInfo;extdecl;
    Function First : IEvsFieldInfo;extdecl;
    Function IndexOf(aValue : IEvsFieldInfo) : Integer;extdecl;
    Function Add(aValue : IEvsFieldInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsFieldInfo);extdecl;
    Function Last : IEvsFieldInfo;extdecl;
    Function Remove(aValue : IEvsFieldInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;

    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count    : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsFieldInfo read Get write Put;default;
  end;
  { TEvsIndexList }
  TEvsIndexList = class(TEvsDBInfo, IEvsIndexList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsIndexInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsIndexInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    procedure Assign(aSource :TPersistent); override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New :IEvsIndexInfo;extdecl;
    Function First : IEvsIndexInfo;extdecl;
    Function IndexOf(aValue : IEvsIndexInfo) : Integer;extdecl;
    Function Add(aValue : IEvsIndexInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsIndexInfo);extdecl;
    Function Last : IEvsIndexInfo;extdecl;
    Function Remove(aValue : IEvsIndexInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;

    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsIndexInfo read Get write Put;default;
  end;
  { TEvsStoredList }
  TEvsStoredList = class(TEvsDBInfo, IEvsStoredList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsStoredInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsStoredInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New : IEvsStoredInfo;extdecl;
    Function First : IEvsStoredInfo;extdecl;
    Function IndexOf(aValue : IEvsStoredInfo) : Integer;extdecl;
    Function Add(aValue : IEvsStoredInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsStoredInfo);extdecl;
    Function Last : IEvsStoredInfo;extdecl;
    Function Remove(aValue : IEvsStoredInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;

    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count    : Integer read GetCount    write SetCount;
    Property Items[aIdx : Integer] : IEvsStoredInfo read Get write Put;default;
  end;
  { TEvsSequenceList }
  TEvsSequenceList = class(TEvsDBInfo, IEvsSequenceList)
  private
    FList : IInterfaceList;
  protected
    function Get(aIdx : Integer) : IEvsGeneratorInfo;extdecl;
    function GetCapacity : Integer;extdecl;
    function GetCount : Integer;extdecl;
    procedure Put(aIdx : Integer;aValue : IEvsGeneratorInfo);extdecl;
    procedure SetCapacity(aValue : Integer);extdecl;
    procedure SetCount(aValue : Integer);extdecl;
  public
    constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    procedure Clear;extdecl;
    procedure Delete(aIdx : Integer);extdecl;
    procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    function New :IEvsGeneratorInfo;extdecl;
    function First : IEvsGeneratorInfo;extdecl;
    function IndexOf(aValue : IEvsGeneratorInfo) : Integer;extdecl;
    function Add(aValue : IEvsGeneratorInfo) : Integer;extdecl;
    procedure Insert(aIdx : Integer;aValue : IEvsGeneratorInfo);extdecl;
    function Last : IEvsGeneratorInfo;extdecl;
    function Remove(aValue : IEvsGeneratorInfo): Integer;extdecl;
    procedure Lock;extdecl;
    procedure Unlock;extdecl;
    property Capacity : Integer read GetCapacity write SetCapacity;
    property Count : Integer read GetCount write SetCount;
    property Items[aIdx : Integer] : IEvsGeneratorInfo read Get write Put;default;
  end;
  { TEvsUDFList }
  TEvsUDFList = class(TEvsDBInfo, IEvsUDFList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsUDFInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsUDFInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New :IEvsUDFInfo;extdecl; {$MESSAGE WARN 'Needs Implementation'}
    Function First : IEvsUDFInfo;extdecl;
    Function IndexOf(aValue : IEvsUDFInfo) : Integer;extdecl;
    Function Add(aValue : IEvsUDFInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsUDFInfo);extdecl;
    Function Last : IEvsUDFInfo;extdecl;
    Function Remove(aValue : IEvsUDFInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsUDFInfo read Get write Put;default;
  end;
  { TEvsUserList }
  TEvsUserList = class(TEvsDBInfo, IEvsUserList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsUserInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsUserInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New :IEvsUserInfo;extdecl;
    Function First : IEvsUserInfo;extdecl;
    Function IndexOf(aValue : IEvsUserInfo) : Integer;extdecl;
    Function Add(aValue : IEvsUserInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsUserInfo);extdecl;
    Function Last : IEvsUserInfo;extdecl;
    Function Remove(aValue : IEvsUserInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsUserInfo read Get write Put;default;
  end;
  { TEvsDatabaseList }
  TEvsDatabaseList = class(TEvsDBInfo, IEvsDatabaseList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsDatabaseInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsDatabaseInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New : IEvsDatabaseInfo;extdecl;
    Function First : IEvsDatabaseInfo;extdecl;
    Function IndexOf(aValue : IEvsDatabaseInfo) : Integer;extdecl;
    Function Add(aValue : IEvsDatabaseInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsDatabaseInfo);extdecl;
    Function Last : IEvsDatabaseInfo;extdecl;
    Function Remove(aValue : IEvsDatabaseInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsDatabaseInfo read Get write Put;default;
  end;
   { TEvsTriggerList }
  TEvsTriggerList = class(TEvsDBInfo, IEvsTriggerList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsTriggerInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsTriggerInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    procedure Assign(aSource :TPersistent); override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New :IEvsTriggerInfo;extdecl;
    Function First : IEvsTriggerInfo;extdecl;
    Function IndexOf(aValue : IEvsTriggerInfo) : Integer;extdecl;
    Function Add(aValue : IEvsTriggerInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsTriggerInfo);extdecl;
    Function Last : IEvsTriggerInfo;extdecl;
    Function Remove(aValue : IEvsTriggerInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsTriggerInfo read Get write Put;default;
  end;
  { TEvsExceptionList }
  TEvsExceptionList = class(TEvsDBInfo, IEvsExceptionList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsExceptionInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsExceptionInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New :IEvsExceptionInfo;extdecl;
    Function First : IEvsExceptionInfo;extdecl;
    Function IndexOf(aValue : IEvsExceptionInfo) : Integer;extdecl;
    Function Add(aValue : IEvsExceptionInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsExceptionInfo);extdecl;
    Function Last : IEvsExceptionInfo;extdecl;
    Function Remove(aValue : IEvsExceptionInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsExceptionInfo read Get write Put;default;
  end;
  { TEvsDomainList }
  TEvsDomainList = class(TEvsDBInfo, IEvsDomainList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsDomainInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsDomainInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New :IEvsDomainInfo;extdecl;
    Function First : IEvsDomainInfo;extdecl;
    Function IndexOf(aValue : IEvsDomainInfo) : Integer;extdecl;
    Function Add(aValue : IEvsDomainInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsDomainInfo);extdecl;
    Function Last : IEvsDomainInfo;extdecl;
    Function Remove(aValue : IEvsDomainInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsDomainInfo read Get write Put;default;
  end;
  { TEvsViewList }
  TEvsViewList = class(TEvsDBInfo, IEvsViewList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx : Integer) : IEvsViewInfo;extdecl;
    Function GetCapacity : Integer;extdecl;
    Function GetCount : Integer;extdecl;
    Procedure Put(aIdx : Integer;aValue : IEvsViewInfo);extdecl;
    Procedure SetCapacity(aValue : Integer);extdecl;
    Procedure SetCount(aValue : Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    Procedure Clear;extdecl;
    Procedure Delete(aIdx : Integer);extdecl;
    Procedure Exchange(aIdx1,aIdx2 : Integer);extdecl;
    Function New :IEvsViewInfo;extdecl;
    Function First : IEvsViewInfo;extdecl;
    Function IndexOf(aValue : IEvsViewInfo) : Integer;extdecl;
    Function Add(aValue : IEvsViewInfo) : Integer;extdecl;
    Procedure Insert(aIdx : Integer;aValue : IEvsViewInfo);extdecl;
    Function Last : IEvsViewInfo;extdecl;
    Function Remove(aValue : IEvsViewInfo): Integer;extdecl;
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity : Integer read GetCapacity write SetCapacity;
    Property Count : Integer read GetCount write SetCount;
    Property Items[aIdx : Integer] : IEvsViewInfo read Get write Put;default;
  end;
  { TEvsRoleList }
  TEvsRoleList = class(TEvsDBInfo, IEvsRoleList)
  private
    FList :IInterfaceList;
  protected
    Function Get(aIdx :Integer) : IEvsRoleInfo; extdecl;
    Function GetCapacity :Integer; extdecl;
    Function GetCount :Integer;extdecl;
    Procedure Put(aIdx :Integer; aValue :IEvsRoleInfo);extdecl;
    Procedure SetCapacity(aValue :Integer);extdecl;
    Procedure SetCount(aValue :Integer);extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    Procedure Clear; extdecl;
    Procedure Delete(aIdx :Integer);extdecl;
    Procedure Exchange(aIdx1, aIdx2 :Integer);extdecl;
    Function First :IEvsRoleInfo;extdecl;
    Function IndexOf(aValue :IEvsRoleInfo) : Integer;extdecl;
    Function Add(aValue :IEvsRoleInfo) : Integer;extdecl;
    Procedure Insert(aIdx :Integer; aValue :IEvsRoleInfo);extdecl;
    Function Last :IEvsRoleInfo;extdecl;
    Function Remove(aValue :IEvsRoleInfo): Integer;extdecl;
    Function New:IEvsRoleInfo;extdecl;{$MESSAGE WARN 'Needs Implementation'}
    Procedure Lock;extdecl;
    Procedure Unlock;extdecl;
    Property Capacity :Integer read GetCapacity write SetCapacity;
    Property Count    :Integer read GetCount    write SetCount;
    Property Items[aIdx :Integer] :IEvsRoleInfo read Get write Put;default;
  end;

  PDBKindReg = ^TDBKindReg;
  TDBKindReg = packed Record
    ID        :Integer;
    Title     :String;
    aIcon     :TIcon;
    CnnProc   :TConnectProc;
    CnnMethod :TConnectMethod;
  end;

{$ENDREGION}

var
  KnownDBTypes : TList;

{$REGION ' Utilities '}

Function CompareByFieldName(const Field1, Field2: IEvsFieldInfo):Integer;
begin
  Result := WideCompareText(Field1.FieldName, Field2.FieldName);
end;

Function CompareByDataTypeName(const Field1, Field2 :IEvsFieldInfo):Integer;
begin
  Result := WideCompareText(Field1.DataTypeName, field2.DataTypeName);
end;

Function EqualFields(const Field1, Field2:IEvsFieldInfo):Boolean;
begin
  Result := Field1.EqualsTo(Field2);
end;

Function FieldArray(const aList:IEvsFieldList):TIFieldArray;
var
  vCntr :Integer;
begin
  SetLength(Result, aList.Count);
  for vCntr := 0 to aList.Count -1 do
    Result[vCntr] := aList[vCntr];
end;

Function TableArray(const aList:IEvsTableList):TITableArray;
var
  vCntr :Integer;
begin
  SetLength(Result, aList.Count);
  for vCntr := 0 to aList.Count -1 do
    Result[vCntr] := aList[vCntr];
end;

Function Query(const aDB:IEvsDatabaseInfo; aSQL:WideString; ExclusiveConnection:Boolean = False):IEvsDataset;
var
  vCnn : IEvsConnection;
begin
  if ExclusiveConnection then
    vCnn := Connect(aDB, adb.ServerKind)
  else
    vCnn := aDB.Connection;
  Result := vCnn.Query(aSQL);
end;

Function NewDatabaseList :IEvsDatabaseList;
begin
  Result := TEvsDBInfoFactory.NewDatabaseList;
end;

Function NewDBKind:PDBKindReg;
begin
  Result := New(PDBKindReg);
  FillByte(Result^, SizeOf(TDBKindReg), 0);
end;

Function NewField(const aOwner:TEvsDBInfo; const aName:widestring=''; const aDatatype:Widestring='';
                  const aSize:integer = 0) : IEvsFieldInfo;
begin
  Result := TEvsFieldInfo.Create(aOwner, True);
  Result.FieldName := aName;
  Result.DataTypeName := aDatatype;
  Result.FieldSize := aSize;
end;

Function NewTable(const aOwner :TEvsDBInfo; const aTableName :widestring; const aDescription :widestring) :IEvsTableInfo;
begin
  Result := TEvsTableInfo.Create(aOwner,True);
  Result.TableName := aTableName;
  Result.Description := aDescription;
end;

Function NewDatabase(const aType :Int32; const aHost, aDatabase, aUser, aPassword, aRole, aCharset :widestring) :IEvsDatabaseInfo;overload;
begin
  Result := TEvsDBInfoFactory.NewDatabase;
  Result.ServerKind           := aType;
  Result.Host                 := aHost;
  Result.Database             := aDatabase;
  Result.DefaultCharset       := aCharset;
  Result.Credentials.UserName := aUser;
  Result.Credentials.Password := aPassword;
  Result.Credentials.Role     := aRole;
end;

Function NewDatabase(const aType :Int32) :IEvsDatabaseInfo;overload;
begin
  Result := TEvsDBInfoFactory.NewDatabase;
  Result.ServerKind := aType;
end;

Function NewDatabase(aOwner :TEvsDBInfo) :IEvsDatabaseInfo;overload;extdecl;
begin
  Result := TEvsDatabaseInfo.Create(aOwner, True);
end;

Function IndexOf(aDBTitle:String):Integer;overload;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to KnownDBTypes.Count -1 do begin
     if CompareText(PDBKindReg(KnownDBTypes[vCntr])^.Title,aDBTitle)=0 then Exit(vCntr);
  end;
end;

Function IndexOf(aID:Integer):Integer;overload;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to KnownDBTypes.Count -1 do begin
     if PDBKindReg(KnownDBTypes[vCntr])^.ID = aID then Exit(vCntr);
  end;
end;

Function Connect(const aDB :IEvsDatabaseInfo; aServerType :Integer) :IEvsConnection;
var
  vCnn : PDBKindReg;
  vIDx : Integer;
begin
  Result := Nil;
  vIDx := IndexOf(aServerType);
  if vIDx = -1 then
    vIDx := IndexOf(aDB.ServerKind);
  if vIDX > -1 then begin
    vCnn := PDBKindReg(KnownDBTypes[vIDx]);
    if Assigned(vCnn^.CnnProc) then
      Result := vCnn^.CnnProc(aDB.Host, aDB.Database, aDB.Credentials.UserName,
                              aDB.Credentials.Password, ADB.Credentials.Role,
                              adb.DefaultCharset)
    else if Assigned(vCnn^.CnnMethod) then
      Result := vCnn^.CnnMethod(aDB.Host, aDB.Database, aDB.Credentials.UserName,
                              aDB.Credentials.Password, ADB.Credentials.Role,
                              adb.DefaultCharset)
    else raise ETBException.Create('No connection possible');
  end;
end;

Procedure RegisterDBType(const aID :Integer; aTitle :string; aConnectProc :TConnectProc; aConnectMethod :TConnectMethod=nil; aIcon :TIcon=nil);
var
  vReg:PDBKindReg;
begin
  if (IndexOf(aTitle)= -1) and (IndexOf(aID) = -1) then begin
    vReg            := NewDBKind;
    vReg^.ID        := aID;
    vReg^.Title     := aTitle;
    vReg^.CnnProc   := aConnectProc;
    vReg^.CnnMethod := aConnectMethod;
    KnownDBTypes.Add(vReg);
  end else raise ETBException.CreateFmt('Server Type <%S> with ID <%D> is alredy registered,',[aTitle,aID]);
end;

Function NewIndexField(const aOwner:TEvsDBInfo; aField:IEvsFieldInfo; aOrder:TEvsSortOrder):IEvsIndexFieldInfo;
begin
  Result := TEvsIndexFieldInfo.Create(aOwner, True);
  Result.Field := aField;
  Result.Order := aOrder;
end;

Function GetDatabase(const aObject:IEvsParented):IEvsDatabaseInfo;
var
  vRes :IEvsParented;
begin
  Result := Nil;
  vRes   := aObject;
  while not Supports(vRes, IEvsDatabaseInfo, Result) do
    vRes := vRes.Parent;
end;

Function DatabaseList :IEvsDatabaseList;
begin
  Result := TEvsDatabaseList.Create(Nil, True);
end;

{ TEvsRoleInfo }

Function TEvsRoleInfo.GetName :WideString; stdcall;
begin
  Result := FName;
end;

Function TEvsRoleInfo.GetUser(aIndex :Integer) :IEvsUserInfo; stdcall;
begin
  Result := FUsers[aIndex];
end;

Function TEvsRoleInfo.GetUserCount :Integer; stdcall;
begin
  Result := FUsers.Count;
end;

Procedure TEvsRoleInfo.SetName(aValue :WideString); stdcall;
begin
  if aValue<>FName then begin
    FName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

Procedure TEvsRoleInfo.SetUser(aIndex :Integer; aValue :IEvsUserInfo); stdcall;
begin
  FUsers[aIndex] := aValue;
  IncludeUpdateFlags([dbsChanged, dbsData]);
end;

{$ENDREGION}

{$Region ' DATA CLASSES '}

{$REGION ' TEvsFieldProxy '}

Procedure TEvsFieldProxy.SetAsBoolean(aValue :LongBool); extdecl;
begin
  FField.AsBoolean := aValue;
end;

Function TEvsFieldProxy.GetAsBoolean :LongBool; extdecl;
begin
  Result := FField.AsBoolean;
end;

Function TEvsFieldProxy.GetFieldName :WideString; extdecl;
begin
  Result := FField.FieldName;
end;

Function TEvsFieldProxy.GetReadOnly :Boolean; extdecl;
begin
  Result := FField.ReadOnly;
end;

Function TEvsFieldProxy.GetRequired :Boolean; extdecl;
begin
  Result := FField.Required;
end;

Function TEvsFieldProxy.GetAsVariant :OLEVariant; extdecl;
begin
  Result := FField.AsVariant;
end;

Function TEvsFieldProxy.GetCalculated :Boolean; extdecl;
begin
  Result := FField.Calculated;
end;

Function TEvsFieldProxy.GetCanModify :Boolean; extdecl;
begin
  Result := FField.CanModify;
end;

Function TEvsFieldProxy.GetEditText :widestring; extdecl;
begin
  Result := FField.Text;
end;

Function TEvsFieldProxy.GetFullName :WideString; extdecl;
begin
  Result := FField.FieldName;
end;

Function TEvsFieldProxy.GetIsNull :Boolean; extdecl;
begin
  Result := FField.IsNull;
end;

function TEvsFieldProxy.GetIsNumeric :LongBool;extdecl;
begin
  Result := FField.DataType in [ftCurrency, ftInteger, ftWord, ftSmallint, ftFloat, ftBCD, ftFMTBcd, ftLargeint];
end;

function TEvsFieldProxy.GetSize:Integer;extdecl;
begin
  Result := FField.Size;
end;

function TEvsFieldProxy.GetPrecision:Integer;extdecl;
begin
  Result := 0;
  case FField.DataType of
    ftCurrency : Result := TCurrencyField(FField).Precision;// Result := 4;
    ftBCD      : Result := TBCDField(FField).Precision;//.
    ftFMTBcd   : Result := TFMTBCDField(FField).Precision;//,
    ftFloat    : Result := TFloatField(FField).Precision; //8;
  end;
end;

function TEvsFieldProxy.GetLength :Integer;extdecl;
begin
  Result := FField.Size;
  case FField.DataType of
    ftSmallint : Result := 3;
    ftInteger  : Result := 10;
    ftWord     : Result := 5;
    ftBoolean  : Result := 4;
    ftFloat    : Result := 18;
    ftCurrency : Result := 20;
    ftBCD      : Result := 30;
    ftDate     : Result := 10;
    ftTime     : Result := 10;
    ftDateTime : Result := 20;
    ftBytes    : Result := -1;
    ftVarBytes: Result := -1;
    ftAutoInc  : Result := 20;
    ftBlob     : Result := -1;
    ftMemo     : Result := -1;
    ftGraphic  : Result := -1;
    ftFmtMemo  : Result := -1;
    ftParadoxOle : Result := -1;
    ftDBaseOle   : Result := -1;
    ftTypedBinary: Result := -1;
    ftCursor     : Result := -1;
    ftFixedChar  : Result := -1;
    //ftWideString : Result := Size div 2;
    ftLargeint   : Result := 22;
    ftADT        : Result := -1;
    //ftArray      : Result := -1; Size;
    ftReference  : Result := -1;
    ftDataSet    : Result := -1;
    ftOraBlob    : Result := -1;
    ftOraClob    : Result := -1;
    ftVariant    : Result := -1;
    ftInterface  : Result := -1;
    ftIDispatch  : Result := -1;
    ftGuid       : Result := 43;
    ftTimeStamp  : Result := 20;
    ftFMTBcd     : Result := 20;
    //ftFixedWideChar: Result := Size;
    //ftWideMemo     : Result := Size;
  end;
end;

Procedure TEvsFieldProxy.SetAsVariant(aValue :OLEVariant); extdecl;
begin
  FField.Value := aValue;
end;

Procedure TEvsFieldProxy.SetCalculated(aValue :Boolean); extdecl;
begin
  FField.Calculated := aValue;
end;

Procedure TEvsFieldProxy.SetEditText(aValue :widestring); extdecl;
begin
  FField.AsWideString := aValue;
end;

Procedure TEvsFieldProxy.SetFieldName(aValue :WideString); extdecl;
begin
  FField.FieldName := aValue;
end;

Procedure TEvsFieldProxy.SetReadOnly(aValue :Boolean); extdecl;
begin
  FField.ReadOnly := aValue;
end;

Constructor TEvsFieldProxy.Create(aField :TField; aDataSet :IEvsDataset);
begin
  inherited Create(True);
  FField := aField;
  FDts := aDataSet;
end;

Destructor TEvsFieldProxy.Destroy;
begin
  FDts := Nil;
  inherited Destroy;
end;

Function TEvsFieldProxy.AsString :Widestring; extdecl;
begin
  Result := FField.AsWideString;
  if FDts.AutoTrimStrings then Result := Trim(Result);
end;

Function TEvsFieldProxy.AsInt32 :Int32; extdecl;
begin
  Result := FField.AsInteger;
end;

Function TEvsFieldProxy.AsByte :Byte; extdecl;
begin
  Result := FField.AsInteger;
end;

Function TEvsFieldProxy.AsDouble :Double; extdecl;
begin
  Result := FField.AsFloat;
end;

Function TEvsFieldProxy.AsDateTime :TDateTime; extdecl;
begin
  Result := FField.AsDateTime;
end;

{$ENDREGION}

{$REGION ' TEvsDatasetProxy '}

function TEvsDatasetProxy.GetInTrans :ByteBool; stdcall;
begin
  Result := False;
  if (FDS is TDBDataset) then begin
    if Assigned(TDBDataset(FDS).Transaction) then
      Result := TDBDataset(FDS).Transaction.Active;
  end;
  Result := Result or (FDS.State in [dsEdit, dsInsert]) ;
end;

function TEvsDatasetProxy.GetSQL :Widestring;extdecl;
begin
  Result := '';
end;

procedure TEvsDatasetProxy.SetSQL(aValue :Widestring); stdcall;
begin
  raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

Function TEvsDatasetProxy.GetBOF :ByteBool; extdecl;
begin
  Result := FDS.BOF;
end;

Function TEvsDatasetProxy.GetEOF :ByteBool; extdecl;
begin
  Result := FDS.EOF;
end;

Function TEvsDatasetProxy.GetField(aIndex :Integer) :IEvsField; extdecl;
begin
  Result := TEvsFieldProxy.Create(FDS.Fields[aIndex], Self);
end;

Function TEvsDatasetProxy.GetFieldCount :Int32; extdecl;
begin
  Result := FDS.Fields.Count;
end;

Procedure TEvsDatasetProxy.Next; extdecl;
begin
  FDS.Next;
end;

Procedure TEvsDatasetProxy.Previous; extdecl;
begin
  FDS.Prior;
end;

Procedure TEvsDatasetProxy.First; extdecl;
begin
  FDS.First;
end;

Procedure TEvsDatasetProxy.Commit;extdecl;
begin
  if FDS is TDBDataset then THackTrans(TDBDataset(FDS).Transaction).EndTransaction;
end;

Procedure TEvsDatasetProxy.RollBack;extdecl;
begin
  if FDS is TDBDataset then THackTrans(TDBDataset(FDS).Transaction).EndTransaction;
end;

function TEvsDatasetProxy.GetAutoTrim:ByteBool; extdecl;
begin
  Result := FAutoTrim;
end;

procedure TEvsDatasetProxy.SetAutoTrim(aValue :ByteBool); extdecl;
begin
  FAutoTrim := aValue;
end;

Constructor TEvsDatasetProxy.Create(aDataset :TDataset; OwnsDataset :Boolean);
begin
  inherited Create;
  FDS := aDataset;
  FAutoTrim := False;
  FOwnsDataset := OwnsDataset;
end;

destructor TEvsDatasetProxy.Destroy;
begin
  inherited Destroy;
  if FOwnsDataset then FDS.Free;
end;

{$ENDREGION}

{$REGION ' TEvsAbstractConnectionProxy '}

Function TEvsAbstractConnectionProxy.InternalGetConnected :Boolean; extdecl;
begin
  Result := FCnn.Connected;
end;

Procedure TEvsAbstractConnectionProxy.InternalSetConnected(aValue :Boolean); extdecl;
begin
  FCnn.Connected := aValue;
end;

Function TEvsAbstractConnectionProxy.GetCharSet :WideString; extdecl;
begin
  Result := InternalGetCharSet;
end;

Procedure TEvsAbstractConnectionProxy.SetCharSet(aValue :WideString); extdecl;
begin
  InternalSetCharSet(aValue);
end;

Function TEvsAbstractConnectionProxy.GetConnected :Boolean; extdecl;
begin
  Result := FCnn.Connected;
end;

Function TEvsAbstractConnectionProxy.GetPassword :widestring; extdecl;
begin
  Result := InternalGetPassword;
end;

Function TEvsAbstractConnectionProxy.GetRole :widestring; extdecl;
begin
  Result := InternalGetRole;
end;

Function TEvsAbstractConnectionProxy.GetUserName :widestring; extdecl;
begin
  Result := InternalGetUserName;
end;

Function TEvsAbstractConnectionProxy.Query(aSQL :wideString) :IEvsDataset; extdecl;
begin
  Result := InternalQuery(aSQL);
end;

Function TEvsAbstractConnectionProxy.Execute(aSQL :WideString) :ByteBool; extdecl;
begin
  Result := InternalExecute(aSQL);
end;

function TEvsAbstractConnectionProxy.CopyTo(const aDest :IEvsCopyable):Integer; extdecl;
var
  vTmp :TPersistent;
begin
  if Supports(aDest, TPersistent, vTmp) then begin
    AssignTo(vTmp);
  end else Result := -1;//raise ETBException.Create('Unsuported Destination');
end;

function TEvsAbstractConnectionProxy.CopyFrom(const aSource :IEvsCopyable):Integer; extdecl;
var
  vTmp :TPersistent;
begin
  Result := 0; //everything is ok
  if Supports(aSource, TPersistent, vTmp) then
    Assign(vTmp)
  else Result := aSource.CopyTo(Self as IEvsCopyable);
end;

function TEvsAbstractConnectionProxy.EqualsTo(const aCompare :IEvsCopyable) :Boolean; extdecl;
begin
  Result := (aCompare = Self as IEvsCopyable);
end;

Procedure TEvsAbstractConnectionProxy.SetConnected(aValue :Boolean); extdecl;
begin
  InternalSetConnected(aValue);
end;

Procedure TEvsAbstractConnectionProxy.SetPassword(aValue :widestring); extdecl;
begin
  InternalSetPassword(aValue);
end;

Procedure TEvsAbstractConnectionProxy.SetRole(aValue :widestring); extdecl;
begin
  InternalSetRole(aValue);
end;

Procedure TEvsAbstractConnectionProxy.SetUserName(aValue :widestring); extdecl;
begin
  InternalSetUserName(aValue);
end;

Constructor TEvsAbstractConnectionProxy.Create(const aConnection :TCustomConnection; const aOwnsConnection :Boolean = True);
begin
  if aConnection = nil then
    raise ETBException.CreateFmt('You must pass a connection based object in %S.',[ClassName]);
  inherited Create(True);
  FCnnOwner := aOwnsConnection;
  FCnn := aConnection;
end;

destructor TEvsAbstractConnectionProxy.Destroy;
begin
  if FCnnOwner then FCnn.Free;
  inherited Destroy;
end;

{$ENDREGION}

{$ENDREGION}

{$REGION ' TEvsObserverList '}
Constructor TEvsObserverList.Create;
begin
  inherited Create(True);
  FList := TThreadList.Create;
end;

destructor TEvsObserverList.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TEvsObserverList.Clear;extdecl;
var
  I: Integer;
  Tmp:TList;
begin
  Tmp := FList.LockList ;
  try
    for I := 0 to Count - 1 do
      IInterface(Tmp.List^[I]) := nil;
    Tmp.Clear;
  finally
    FList.UnlockList;
  end;
end;

function TEvsObserverList.ObjectRef :TObject;extdecl;
begin
  Result := Self;
end;

procedure TEvsObserverList.Delete(Index: Integer);extdecl;
var
  Tmp :TList;
begin
  Tmp := FList.LockList;
  try
    IEvsObserver(Tmp.List^[Index]) := nil;
    Tmp.Delete(Index);
  finally
    FList.UnlockList;
  end;
end;

function TEvsObserverList.Expand: TEvsObserverList;extdecl;
var
  Tmp:TList;
begin
  Tmp := FList.LockList;
  try
    Tmp.Expand;
    Result := Self;
  finally
    FList.Unlocklist;
  end;
end;

function TEvsObserverList.First: IEvsObserver;extdecl;
begin
  Result := Get(0);
end;

function TEvsObserverList.Get(Index: Integer): IEvsObserver;extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    if (Index < 0) or (Index >= Count) then
      Tmp.Error(SErrorListIndex, Index);
    Result := IEvsObserver(Tmp.List^[Index]);
  finally
    FList.UnlockList;
  end;
end;

function TEvsObserverList.GetCapacity: Integer;extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    Result := Tmp.Capacity;
  finally
    FList.UnlockList;
  end;
end;

function TEvsObserverList.GetCount: Integer;extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    Result := Tmp.Count;
  finally
    FList.UnlockList;
  end;
end;

//function TEvsObserverList.GetEnumerator: TEvsObserverListEnumerator;extdecl;
//begin
//  Result := TEvsObserverListEnumerator.Create(Self);
//end;

function TEvsObserverList.IndexOf(const Item: IEvsObserver): Integer;extdecl;
var
  Tmp :TList;
begin
  Tmp := FList.LockList;
  try
    Result := Tmp.IndexOf(Pointer(Item));
  finally
    FList.UnlockList;
  end;
end;

function TEvsObserverList.Add(const Item: IEvsObserver): Integer;extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    Result := Tmp.Add(nil);
    IEvsObserver(Tmp.List^[Result]) := Item;
  finally
    FList.UnlockList;
  end;
end;

procedure TEvsObserverList.Insert(Index: Integer; const Item: IEvsObserver);extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    Tmp.Insert(Index, nil);
    IEvsObserver(Tmp.List^[Index]) := Item;
  finally
    FList.UnlockList;
  end;
end;

function TEvsObserverList.Last: IEvsObserver;extdecl;
begin
  Result := Self.Get(Count - 1);
end;

procedure TEvsObserverList.Put(Index: Integer; const Item: IEvsObserver);extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    if (Index < 0) or (Index >= Count) then
      Tmp.Error(SErrorListIndex, Index);
    IEvsObserver(Tmp.List^[Index]) := Item;
  finally
    FList.UnlockList;
  end;
end;

function TEvsObserverList.Remove(const Item: IEvsObserver): Integer;extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    Result := Tmp.IndexOf(Pointer(Item));
    if Result > -1 then
    begin
      IEvsObserver(Tmp.List^[Result]) := nil;
      Tmp.Delete(Result);
    end;
  finally
    FList.UnlockList;
  end;
end;

procedure TEvsObserverList.SetCapacity(NewCapacity: Integer);extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    Tmp.Capacity := NewCapacity;
  finally
    FList.UnlockList;
  end;
end;

procedure TEvsObserverList.SetCount(NewCount: Integer);extdecl;
var
  Tmp:TList;
begin
  Tmp := FList.LockList;
  try
    Tmp.Count := NewCount;
  finally
    FList.UnlockList;
  end;
end;

procedure TEvsObserverList.Exchange(Index1, Index2: Integer);extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    Tmp.Exchange(Index1, Index2);
  finally
    FList.UnlockList;
  end;
end;

procedure TEvsObserverList.Lock;extdecl;
begin
  FList.LockList;
end;

procedure TEvsObserverList.Unlock;extdecl;
begin
  FList.UnlockList;
end;
{$ENDREGION}

{$REGION ' TEvsViewInfo '}

Procedure TEvsViewInfo.SetFieldList(aValue :IEvsFieldList); extdecl;
begin
  if FFieldList=aValue then Exit;
  FFieldList:=aValue;
end;

Function TEvsViewInfo.GetDescription:WideString;extdecl;
begin
  Result := FDescription;
end;

Function TEvsViewInfo.GetFieldList :IEvsFieldList; extdecl;
begin
  Result := FFieldList;
end;

Procedure TEvsViewInfo.SetDescription(aValue :WideString); extdecl;
begin
  if WideCompareText(FDescription,aValue) <> 0 then begin
    FDescription := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;
procedure TEvsViewInfo.Assign(Source :TPersistent);
var
  vSrc : TEvsViewInfo absolute Source;
begin
  if source is TEvsViewInfo then begin
    FDescription := vSrc.FDescription;
    FName        := vSrc.FName;
    FSql         := vSrc.FSql;
    FFieldList.Clear;
    FFieldList.CopyFrom(vSrc.FFieldList);
  end else inherited Assign(Source);
end;

Constructor TEvsViewInfo.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FFieldList := TEvsFieldList.Create(Self, True);
end;

Function TEvsViewInfo.GetField(aIndex :Integer) :IEvsFieldInfo; extdecl;
begin
  Result := FFieldList[aIndex];
end;

Function TEvsViewInfo.GetName :WideString; extdecl;
begin
  Result := FName;
end;

Function TEvsViewInfo.GetSQL :WideString; extdecl;
begin
  Result := FSql;
end;

Procedure TEvsViewInfo.SetField(aIndex :Integer; aValue :IEvsFieldInfo); extdecl;
begin
  if FFieldList[aIndex] <> aValue then begin
    FFieldList[aIndex] := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

Procedure TEvsViewInfo.SetName(aValue :WideString); extdecl;
begin
  if FName <> aValue then begin
    FName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

Procedure TEvsViewInfo.SetSQL(aValue :WideString); extdecl;
begin
  if FSql <> aValue then begin
    FSql := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

Function TEvsViewInfo.FieldCount :integer; extdecl;
begin
  Result := FFieldList.Count;
end;
{$ENDREGION}

{$REGION ' TEvsDomainInfo '}

function TEvsDomainInfo.GetCharSet :widestring;extdecl;
begin
  Result := FCharset;
end;

function TEvsDomainInfo.GetCheckConstraint :widestring;extdecl;
begin
  Result := FCheck;
end;

function TEvsDomainInfo.GetCollation :Widestring;extdecl;
begin
  Result := FCollation;
end;

function TEvsDomainInfo.GetDatatype :widestring;extdecl;
begin
  Result := FDataType;
end;

function TEvsDomainInfo.GetDefaultValue :OLEVariant;extdecl;
begin
  Result := FDefault;
end;

function TEvsDomainInfo.GetName :widestring;extdecl;
begin
  Result := fName;
end;

function TEvsDomainInfo.GetSQL :widestring;extdecl;
begin
  Result := FSql;
end;
function TEvsDomainInfo.GetSize :Integer;extdecl;
begin
  Result := FSize;
end;

procedure TEvsDomainInfo.SetCharSet(aValue :WideString);extdecl;
begin
  if CompareText(FCharset,aValue)<>0 then begin
    FCharset := aValue;
    IncludeUpdateFlags([dbsChanged,dbsMetaData]);
  end;
end;

procedure TEvsDomainInfo.SetCheckConstraint(aValue :WideString);extdecl;
begin
  if (FCheck <> aValue) then begin
    FCharset := aValue;
    IncludeUpdateFlags([dbsChanged,dbsMetaData]);
  end;
end;

procedure TEvsDomainInfo.SetCollation(aValue :WideString);extdecl;
begin
  if (FCollation <> aValue) then begin
    FCollation := aValue;
    IncludeUpdateFlags([dbsChanged,dbsMetaData]);
  end;
end;

procedure TEvsDomainInfo.SetDatatype(aValue :WideString);extdecl;
begin
  if (FDataType <> aValue) then begin
    FDataType := aValue;
    IncludeUpdateFlags([dbsChanged,dbsMetaData]);
  end;
end;

procedure TEvsDomainInfo.SetDefaultValue(aValue :OLEVariant);extdecl;
begin
  if (FDefault <> aValue) then begin
    FDefault := aValue;
    IncludeUpdateFlags([dbsChanged,dbsMetaData]);
  end;
end;

procedure TEvsDomainInfo.SetName(aValue :WideString);extdecl;
begin
  if (fName <> aValue) then begin
    fName := aValue;
    IncludeUpdateFlags([dbsChanged,dbsMetaData]);
  end;
end;

procedure TEvsDomainInfo.SetSQL(aValue :widestring);extdecl;
begin
  if (FSql <> aValue) then begin
    FSql := aValue;
    IncludeUpdateFlags([dbsChanged,dbsData]);
    //parse the sql command and refresh the properties as needed.
    raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
  end;
end;

procedure TEvsDomainInfo.SetSize(aValue :Integer);extdecl;
begin
  if (FSize <> aValue) then begin
    FSize := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;
procedure TEvsDomainInfo.Assign(Source :TPersistent);
var
  vSrc : TEvsDomainInfo absolute Source;
begin
  if Source is TEvsDomainInfo then begin
    FDataType  := vSrc.FDataType;
    FDefault   := vSrc.FDefault;
    FCheck     := vSrc.FCheck;
    FCharset   := vSrc.FCharset;
    FCollation := vSrc.FCollation;
    FName      := vSrc.FName;
    FSql       := vSrc.FSql;
    FSize      := vSrc.FSize;
  end else inherited Assign(Source);
end;

{$ENDREGION}

{$REGION ' TEvsTriggerInfo '}

function TEvsTriggerInfo.GetEvent :TEvsTriggerEvents;extdecl;
begin
  Result := FEvent;
end;

function TEvsTriggerInfo.GetEventType :TEvsTriggerType;extdecl;
begin
  Result := FEventType;
end;

function TEvsTriggerInfo.GetSQL :WideString;extdecl;
begin
  Result := FSQL;
end;

function TEvsTriggerInfo.GetTriggerDescription :WideString;extdecl;
begin
  Result := FDescr;
end;

function TEvsTriggerInfo.GetTriggerName :WideString;extdecl;
begin
  Result := FName;
end;

procedure TEvsTriggerInfo.SetEvent(aValue :TEvsTriggerEvents);extdecl;
begin
  FEvent := aValue;
  IncludeUpdateFlags([dbsChanged,dbsData]);
end;

function TEvsTriggerInfo.GetActive :ByteBool; extdecl;
begin
  Result := FActive;
end;

procedure TEvsTriggerInfo.SetActive(aValue :ByteBool);extdecl;
begin
  FActive := aValue;
  IncludeUpdateFlags([dbsChanged,dbsData]);
end;

procedure TEvsTriggerInfo.SetEventType(aValue :TEvsTriggerType);extdecl;
begin
  FEventType := aValue;
  IncludeUpdateFlags([dbsChanged,dbsData]);
end;

procedure TEvsTriggerInfo.SetSQL(aValue :WideString);extdecl;
begin
  FSQL := aValue;
  IncludeUpdateFlags([dbsChanged,dbsData]);
end;

procedure TEvsTriggerInfo.SetTriggerDscription(aValue :WideString);extdecl;
begin
  FDescr := aValue;
  IncludeUpdateFlags([dbsChanged,dbsMetadata]);
end;

procedure TEvsTriggerInfo.SetTriggerName(aValue :WideString);extdecl;
begin
  FName := aValue;
  IncludeUpdateFlags([dbsChanged,dbsData]);
end;
procedure TEvsTriggerInfo.Assign(Source:TPersistent);
var
  vSrc :TEvsTriggerInfo absolute Source;
begin
  if Source is TEvsTriggerInfo then begin
    FEvent     := vSrc.FEvent;
    FEventType := vSrc.FEventType;
    FSQL       := vSrc.FSQL;
    FDescr     := vSrc.FDescr;
    FName      := vSrc.FName;
    FActive    := vSrc.FActive;
  end else inherited Assign(Source);
end;

{$ENDREGION}

{$REGION ' TEvsDBInfoFactory '}

class Function TEvsDBInfoFactory.NewDatabaseList(const aParent :IEvsParented) :IEvsDatabaseList;
begin
  Result := TEvsDatabaseList.Create(nil, True);
end;

class Function TEvsDBInfoFactory.NewDatabase(const aParent :IEvsParented) :IEvsDatabaseInfo;
begin
  Result := TEvsDatabaseInfo.Create(nil,True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewTable(const aParent :IEvsParented) :IEvsTableInfo;
begin
  Result := TEvsTableInfo.Create(nil, True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewTableList(const aParent :IEvsParented) :IEvsTableList;
begin
  Result := TEvsTableList.Create(Nil,True);
  if Assigned(aParent) then (Result as TEvsDBInfo).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewField(const aParent:IEvsParented=nil) :IEvsFieldInfo;
begin
  Result := TEvsFieldInfo.Create(Nil,True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewFieldList(const aParent :IEvsParented) :IEvsFieldList;
begin
  Result := TEvsFieldList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsFieldList).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewTrigger(const aParent :IEvsParented) :IEvsTriggerInfo;
begin
  Result := TEvsTriggerInfo.Create(Nil,True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewTriggerList(const aParent :IEvsParented) :IEvsTriggerList;
begin
  Result := TEvsTriggerList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsTriggerList).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewSequence(const aParent :IEvsParented) :IEvsSequenceInfo;
begin
  Result := TEvsSequenceInfo.Create(Nil, True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewSequenceList(const aParent :IEvsParented) :IEvsSequenceList;
begin
  Result := TEvsSequenceList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsSequenceList).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewIndex(const aParent :IEvsParented) :IEvsIndexInfo;
begin
  Result := TEvsIndexInfo.Create(Nil, True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewIndexList(const aParent :IEvsParented) :IEvsIndexList;
begin
  Result := TEvsIndexList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsIndexList).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewException(const aParent :IEvsParented) :IEvsExceptionInfo;
begin
  Result := TEvsExceptionInfo.Create(Nil, True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewExceptionList(const aParent :IEvsParented) :IEvsExceptionList;
begin
  Result := TEvsExceptionList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsExceptionList).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewStoredProc(const aParent :IEvsParented) :IEvsStoredInfo;
begin
  Result := TEvsStoredInfo.Create(Nil, True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewStoredList(const aParent :IEvsParented) :IEvsStoredList;
begin
  Result := TEvsStoredList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsStoredList).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewDomain(const aParent :IEvsParented) :IEvsDomainInfo;
begin
  Result := TEvsDomainInfo.Create(Nil, True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewDomainList(const aParent :IEvsParented) :IEvsDomainList;
begin
  Result := TEvsDomainList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsDomainList).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewView(const aParent :IEvsParented) :IEvsViewInfo;
begin
  Result := TEvsViewInfo.Create(nil, True);
  if Assigned(aParent) then Result.Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewViewList(const aParent :IEvsParented) :IEvsViewList;
begin
  Result := TEvsViewList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsViewList).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewUser(const aParent :IEvsParented) :IEvsUserInfo;
begin
  Result := TEvsUserInfo.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsUserInfo).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewUserList(const aParent :IEvsParented) :IEvsUserList;
begin
  Result := TEvsUserList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsUserList).Parent := aParent;
end;

class Function TEvsDBInfoFactory.NewRole(const aParent :IEvsParented) :IEvsRoleInfo;
begin
  Result := TEvsRoleInfo.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsRoleInfo).Parent := aParent;
end;

class function TEvsDBInfoFactory.NewRoleList(Const aParent :IEvsParented) :IEvsRoleList;
begin
  Result := TEvsRoleList.Create(nil, True);
  if Assigned(aParent) then (Result as TEvsRoleList).Parent := aParent;
end;

{$ENDREGION}

{$REGION ' TEvsStoredInfo '}

Function TEvsStoredInfo.GetField(aIndex :Integer) :IEvsFieldInfo;extdecl;
begin
  Result := FList[aIndex] as IEvsFieldInfo;
end;

Function TEvsStoredInfo.GetFieldCount :integer;extdecl;
begin
  Result := FList.Count;
end;

Function TEvsStoredInfo.GetSPName :WideString;extdecl;
begin
  Result := FName;
end;

Function TEvsStoredInfo.GetSql :WideString;extdecl;
begin
  Result := FSQL;
end;

Function TEvsStoredInfo.GetDescription:Widestring; extdecl;
begin
  Result := FDescription;
end;

Procedure TEvsStoredInfo.SetField(aIndex :Integer; aValue :IEvsFieldInfo);extdecl;
begin
  FList[aIndex] := aValue;
  IncludeUpdateFlags([dbsChanged, dbsMetaData]);
end;

Procedure TEvsStoredInfo.SetDescription(aValue:Widestring);extdecl;
begin
  if WideCompareText(aValue, FDescription) <> 0 then begin
    FDescription := aValue;
    IncludeUpdateFlags([dbsChanged,dbsMetadata]);
  end;
end;

Procedure TEvsStoredInfo.SetSPName(aValue :WideString);extdecl;
begin
  FName := aValue;
  IncludeUpdateFlags([dbsChanged, dbsData]);
end;

Procedure TEvsStoredInfo.SetSql(aValue :WideString);extdecl;
begin
  FSQL := aValue;
  IncludeUpdateFlags([dbsChanged, dbsData]);
end;

Constructor TEvsStoredInfo.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

procedure TEvsStoredInfo.Assign(Source :TPersistent);
var
  vSrc : TEvsStoredInfo absolute Source;
begin
  if Source is TEvsStoredInfo then begin
    FDescription := vSrc.FDescription;
    FSQL         := vSrc.FSQL;
    FName        := vSrc.FName;
    //FList        :TInterfaceList;
  end else inherited Assign(Source);
end;

Destructor TEvsStoredInfo.Destroy;
begin
  FList := Nil;
  inherited Destroy;
end;

Procedure TEvsStoredInfo.AddField(const aField :IEvsFieldInfo);extdecl;
begin
  FList.Add(aField);
end;

Function TEvsStoredInfo.NewField(const aName :WideString) :IEvsFieldInfo;extdecl;
begin
  Result := TEvsFieldInfo.Create(Self, True);
  Result.FieldName := aName;
  AddField(Result);
end;
{$ENDREGION}

{$REGION ' TEvsGeneratorInfo '}
procedure TEvsSequenceInfo.Assign(Source :TPersistent);
var
  vSrc : TEvsSequenceInfo absolute Source;
begin
  if Source is TEvsSequenceInfo then begin
    FName := vSrc.FName;
    FStep := vSrc.FStep;
  end else inherited Assign(Source);
end;

function TEvsSequenceInfo.GetCurrentValue :Int64;extdecl;
//var
//  vDB:TEvsDatabaseInfo;
begin
  raise NotImplementedException; {$MESSAGE WARN 'NOT IMPLEMENTED'}
  //vDB := GetDB;
end;

function TEvsSequenceInfo.GetName :widestring;extdecl;
begin
  Result := FName;
end;

procedure TEvsSequenceInfo.SetCurrentValue(aValue :Int64);extdecl;
begin
  raise NotImplementedException;
end;

procedure TEvsSequenceInfo.SetName(aValue :widestring);extdecl;
begin
  FName := aValue;
  IncludeUpdateFlags([dbsChanged,dbsMetadata]);
end;

{$ENDREGION}

{$REGION ' TEvsExceptionInfo '}

procedure TEvsExceptionInfo.Assign(Source :TPersistent);
var
  vSrc : TEvsExceptionInfo absolute Source;
begin
  if Source is TEvsExceptionInfo then begin
    FDescription := vSrc.FDescription;
    FMessage     := vSrc.FMessage;
    FName        := vSrc.FName;
    FNumber      := vSrc.FNumber;
    FSystem      := vSrc.FSystem;
  end else inherited Assign(Source);
end;

function TEvsExceptionInfo.GetDescription :widestring;extdecl;
begin
  Result := FDescription;
  IncludeUpdateFlags([dbsChanged, {dbsData,} dbsMetadata]);
end;

function TEvsExceptionInfo.GetMessage :WideString;extdecl;
begin
  Result := FMessage;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]);
end;

function TEvsExceptionInfo.GetName :WideString;extdecl;
begin
  Result := FName;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]);
end;

function TEvsExceptionInfo.GetNumber :WideString;extdecl;
begin
  Result := FNumber;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]);
end;

function TEvsExceptionInfo.GetSystem :ByteBool;extdecl;
begin
  Result := FSystem;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]);
end;

procedure TEvsExceptionInfo.SetDescription(aValue :widestring);extdecl;
begin
  FDescription := aValue;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]);
end;

procedure TEvsExceptionInfo.SetMessage(aValue :WideString);extdecl;
begin
  FMessage := aValue;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]);
end;

procedure TEvsExceptionInfo.SetName(aValue :WideString);extdecl;
begin
  FName := aValue;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]);
end;

procedure TEvsExceptionInfo.SetNumber(aValue :WideString);extdecl;
begin
  FNumber := aValue;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]);
end;

procedure TEvsExceptionInfo.SetSystem(aValue :ByteBool);extdecl;
begin
  FSystem := aValue;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]);
end;

{$ENDREGION}

{$REGION ' TEvsUserInfo '}

function TEvsUserInfo.GetFirstName :widestring;extdecl;
begin
  Result := FFirstName;
end;

function TEvsUserInfo.GetLastName :widestring;extdecl;
begin
  Result := FLastName;
end;

function TEvsUserInfo.GetMiddleName :widestring;extdecl;
begin
  Result := FMiddleName;
end;

function TEvsUserInfo.GetPassword :widestring;extdecl;
begin
  Result := FPassword;
end;

function TEvsUserInfo.GetUserName :widestring;extdecl;
begin
  Result := FUserName;
end;

procedure TEvsUserInfo.SetFirstName(aValue :widestring);extdecl;
begin
  FFirstName := aValue;
  IncludeUpdateFlags([dbsChanged, {dbsData, }dbsMetadata]);
end;

procedure TEvsUserInfo.SetLastName(aValue :widestring);extdecl;
begin
  FLastName := aValue;
  IncludeUpdateFlags([dbsChanged, {dbsData, }dbsMetadata]);
end;

procedure TEvsUserInfo.SetMiddleName(aValue :widestring);extdecl;
begin
  FMiddleName := aValue;
  IncludeUpdateFlags([dbsChanged, {dbsData, }dbsMetadata]);
end;

procedure TEvsUserInfo.SetPassword(aValue :widestring);extdecl;
begin
  FPassword := aValue;
  IncludeUpdateFlags([dbsChanged, {dbsData, }dbsMetadata]);
end;

procedure TEvsUserInfo.SetUserName(aValue :widestring);extdecl;
begin
  FUserName := aValue;
  IncludeUpdateFlags([dbsChanged, dbsData{, dbsMetadata}]); // user names are not allowed to be changed this requires a new user to be created and the old droped.
end;
procedure TEvsUserInfo.Assign(Source :TPersistent);
var
  vSrc : TEvsUserInfo absolute Source;
begin
  if Source is TEvsUserInfo then begin
    FFirstName  := vSrc.FFirstName;
    FLastName   := vSrc.FLastName;
    FMiddleName := vSrc.FMiddleName;
    FPassword   := vSrc.FPassword;
    FUserName   := vSrc.FUserName;
  end else inherited Assign(Source);
end;

{$ENDREGION}

{$REGION ' TEvsViewList '}

function TEvsViewList.Get(aIdx :Integer) :IEvsViewInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsViewInfo;
end;

function TEvsViewList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsViewList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsViewList.Put(aIdx :Integer; aValue :IEvsViewInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsViewList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsViewList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsViewList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsViewList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsViewList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsViewList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsViewList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsViewList.New :IEvsViewInfo;extdecl;
begin
  Result := TEvsViewInfo.Create(FOwner,True);
  Add(Result);
end;

function TEvsViewList.First :IEvsViewInfo;extdecl;
begin
  Result := FList.First as IEvsViewInfo;
end;

function TEvsViewList.IndexOf(aValue :IEvsViewInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsViewList.Add(aValue :IEvsViewInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsViewList.Insert(aIdx :Integer; aValue :IEvsViewInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsViewList.Last :IEvsViewInfo;extdecl;
begin
  Result := FList.Last as IEvsViewInfo;
end;

function TEvsViewList.Remove(aValue :IEvsViewInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsViewList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsViewList.Unlock;extdecl;
begin
  FList.Unlock;
end;
{$ENDREGION}

{$REGION ' TEvsDomainList '}

function TEvsDomainList.Get(aIdx :Integer) :IEvsDomainInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsDomainInfo;
end;

function TEvsDomainList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsDomainList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsDomainList.Put(aIdx :Integer; aValue :IEvsDomainInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsDomainList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsDomainList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsDomainList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsDomainList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsDomainList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsDomainList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsDomainList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsDomainList.New :IEvsDomainInfo;extdecl;
begin
  Result := TEvsDomainInfo.Create(FOwner,True);
  Add(Result);
end;

function TEvsDomainList.First :IEvsDomainInfo;extdecl;
begin
  Result := FList.First as IEvsDomainInfo;
end;

function TEvsDomainList.IndexOf(aValue :IEvsDomainInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsDomainList.Add(aValue :IEvsDomainInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsDomainList.Insert(aIdx :Integer; aValue :IEvsDomainInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsDomainList.Last :IEvsDomainInfo;extdecl;
begin
  Result := FList.Last as IEvsDomainInfo;
end;

function TEvsDomainList.Remove(aValue :IEvsDomainInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsDomainList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsDomainList.Unlock;extdecl;
begin
  FList.Unlock;
end;
{$ENDREGION}

{$REGION ' TEvsExceptionList '}

function TEvsExceptionList.Get(aIdx :Integer) :IEvsExceptionInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsExceptionInfo;
end;

function TEvsExceptionList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsExceptionList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsExceptionList.Put(aIdx :Integer; aValue :IEvsExceptionInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsExceptionList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsExceptionList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsExceptionList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsExceptionList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsExceptionList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsExceptionList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsExceptionList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsExceptionList.New :IEvsExceptionInfo;extdecl;
begin
  Result := TEvsExceptionInfo.Create(FOwner,True);
  Add(Result);
end;

function TEvsExceptionList.First :IEvsExceptionInfo;extdecl;
begin
  Result := FList.First as IEvsExceptionInfo;
end;

function TEvsExceptionList.IndexOf(aValue :IEvsExceptionInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsExceptionList.Add(aValue :IEvsExceptionInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsExceptionList.Insert(aIdx :Integer; aValue :IEvsExceptionInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsExceptionList.Last :IEvsExceptionInfo;extdecl;
begin
  Result := FList.Last as IEvsExceptionInfo;
end;

function TEvsExceptionList.Remove(aValue :IEvsExceptionInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsExceptionList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsExceptionList.Unlock;extdecl;
begin
  FList.Unlock;
end;
{$ENDREGION}

{$REGION ' TEvsTriggerList '}

Function TEvsTriggerList.Get(aIdx :Integer) :IEvsTriggerInfo; extdecl;
begin
  Result := FList.Get(aIdx) as IEvsTriggerInfo;
end;

Function TEvsTriggerList.GetCapacity :Integer; extdecl;
begin
  Result := FList.GetCapacity;
end;

Function TEvsTriggerList.GetCount :Integer; extdecl;
begin
  Result := FList.GetCount;
end;

Procedure TEvsTriggerList.Put(aIdx :Integer; aValue :IEvsTriggerInfo); extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

Procedure TEvsTriggerList.SetCapacity(aValue :Integer); extdecl;
begin
  FList.SetCapacity(aValue);
end;

Procedure TEvsTriggerList.SetCount(aValue :Integer); extdecl;
begin
  FList.SetCount(aValue);
end;

Constructor TEvsTriggerList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsTriggerList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsTriggerList.Assign(aSource :TPersistent);
var
  vSrc  :TEvsTriggerList absolute aSource;
  vCntr :Integer;
begin
  if (aSource is TEvsTriggerList) then begin
    for vCntr := 0 to vSrc.Count -1 do begin
      New.CopyFrom(vSrc[vCntr]);
    end;
  end else inherited Assign(aSource);
end;

Procedure TEvsTriggerList.Clear; extdecl;
begin
  FList.Clear;
end;

Procedure TEvsTriggerList.Delete(aIdx :Integer); extdecl;
begin
  FList.Delete(aIdx);
end;

Procedure TEvsTriggerList.Exchange(aIdx1, aIdx2 :Integer); extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

Function TEvsTriggerList.New :IEvsTriggerInfo; extdecl;
begin
  Result := TEvsTriggerInfo.Create(FOwner,True);
  Add(Result);
end;

Function TEvsTriggerList.First :IEvsTriggerInfo; extdecl;
begin
  Result := FList.First as IEvsTriggerInfo;
end;

Function TEvsTriggerList.IndexOf(aValue :IEvsTriggerInfo) :Integer; extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

Function TEvsTriggerList.Add(aValue :IEvsTriggerInfo) :Integer; extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

Procedure TEvsTriggerList.Insert(aIdx :Integer; aValue :IEvsTriggerInfo); extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

Function TEvsTriggerList.Last :IEvsTriggerInfo; extdecl;
begin
  Result := FList.Last as IEvsTriggerInfo;
end;

Function TEvsTriggerList.Remove(aValue :IEvsTriggerInfo) :Integer; extdecl;
begin
  Result := FList.Remove(aValue);
end;

Procedure TEvsTriggerList.Lock; extdecl;
begin
  FList.Lock;
end;

Procedure TEvsTriggerList.Unlock; extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsDatabaseList '}

function TEvsDatabaseList.Get(aIdx :Integer) :IEvsDatabaseInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsDatabaseInfo;
end;

function TEvsDatabaseList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsDatabaseList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsDatabaseList.Put(aIdx :Integer; aValue :IEvsDatabaseInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsDatabaseList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsDatabaseList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsDatabaseList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsDatabaseList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsDatabaseList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsDatabaseList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsDatabaseList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsDatabaseList.New :IEvsDatabaseInfo;extdecl;
begin
  Result := TEvsDatabaseInfo.Create(FOwner, True);
  Add(Result);
end;

function TEvsDatabaseList.First :IEvsDatabaseInfo;extdecl;
begin
  Result := FList.First as IEvsDatabaseInfo;
end;

function TEvsDatabaseList.IndexOf(aValue :IEvsDatabaseInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsDatabaseList.Add(aValue :IEvsDatabaseInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsDatabaseList.Insert(aIdx :Integer; aValue :IEvsDatabaseInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsDatabaseList.Last :IEvsDatabaseInfo;extdecl;
begin
  Result := FList.Last as IEvsDatabaseInfo;
end;

function TEvsDatabaseList.Remove(aValue :IEvsDatabaseInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsDatabaseList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsDatabaseList.Unlock;extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsUserList '}

function TEvsUserList.Get(aIdx :Integer) :IEvsUserInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsUserInfo;
end;

function TEvsUserList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsUserList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsUserList.Put(aIdx :Integer; aValue :IEvsUserInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsUserList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsUserList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsUserList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsUserList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsUserList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsUserList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsUserList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsUserList.New :IEvsUserInfo;extdecl;
begin
  Result := TEvsUserInfo.Create(FOwner,True);
  Add(Result);
end;

function TEvsUserList.First :IEvsUserInfo;extdecl;
begin
  Result := FList.First as IEvsUserInfo;
end;

function TEvsUserList.IndexOf(aValue :IEvsUserInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsUserList.Add(aValue :IEvsUserInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsUserList.Insert(aIdx :Integer; aValue :IEvsUserInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsUserList.Last :IEvsUserInfo;extdecl;
begin
  Result := FList.Last as IEvsUserInfo;
end;

function TEvsUserList.Remove(aValue :IEvsUserInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsUserList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsUserList.Unlock;extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsUDFList '}

function TEvsUDFList.Get(aIdx :Integer) :IEvsUDFInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsUDFInfo;
end;

function TEvsUDFList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsUDFList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsUDFList.Put(aIdx :Integer; aValue :IEvsUDFInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsUDFList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsUDFList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsUDFList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsUDFList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsUDFList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsUDFList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsUDFList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsUDFList.New :IEvsUDFInfo;extdecl;
begin
  raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

function TEvsUDFList.First :IEvsUDFInfo;extdecl;
begin
  Result := FList.First as IEvsUDFInfo;
end;

function TEvsUDFList.IndexOf(aValue :IEvsUDFInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsUDFList.Add(aValue :IEvsUDFInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsUDFList.Insert(aIdx :Integer; aValue :IEvsUDFInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsUDFList.Last :IEvsUDFInfo;extdecl;
begin
  Result := FList.Last as IEvsUDFInfo;
end;

function TEvsUDFList.Remove(aValue :IEvsUDFInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsUDFList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsUDFList.Unlock;extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsGeneratorList '}

function TEvsSequenceList.Get(aIdx :Integer) :IEvsGeneratorInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsGeneratorInfo;
end;

function TEvsSequenceList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsSequenceList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsSequenceList.Put(aIdx :Integer; aValue :IEvsGeneratorInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsSequenceList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsSequenceList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsSequenceList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsSequenceList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsSequenceList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsSequenceList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsSequenceList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsSequenceList.New :IEvsGeneratorInfo;extdecl;
begin
  Result := TEvsSequenceInfo.Create(FOwner, True);
  Add(Result);
end;

function TEvsSequenceList.First :IEvsGeneratorInfo;extdecl;
begin
  Result := FList.First as IEvsGeneratorInfo;
end;

function TEvsSequenceList.IndexOf(aValue :IEvsGeneratorInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsSequenceList.Add(aValue :IEvsGeneratorInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsSequenceList.Insert(aIdx :Integer; aValue :IEvsGeneratorInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsSequenceList.Last :IEvsGeneratorInfo;extdecl;
begin
  Result := FList.Last as IEvsGeneratorInfo;
end;

function TEvsSequenceList.Remove(aValue :IEvsGeneratorInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsSequenceList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsSequenceList.Unlock;extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsStoredList '}

function TEvsStoredList.Get(aIdx :Integer) :IEvsStoredInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsStoredInfo;
end;

function TEvsStoredList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsStoredList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsStoredList.Put(aIdx :Integer; aValue :IEvsStoredInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsStoredList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsStoredList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsStoredList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsStoredList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsStoredList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsStoredList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsStoredList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsStoredList.New :IEvsStoredInfo;extdecl;
begin
  Result := TEvsStoredInfo.Create(FOwner, True);
  Add(Result);
end;

function TEvsStoredList.First :IEvsStoredInfo;extdecl;
begin
  Result := FList.First as IEvsStoredInfo;
end;

function TEvsStoredList.IndexOf(aValue :IEvsStoredInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsStoredList.Add(aValue :IEvsStoredInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsStoredList.Insert(aIdx :Integer; aValue :IEvsStoredInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsStoredList.Last :IEvsStoredInfo;extdecl;
begin
  Result := FList.Last as IEvsStoredInfo;
end;

function TEvsStoredList.Remove(aValue :IEvsStoredInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsStoredList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsStoredList.Unlock;extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsIndexList '}

function TEvsIndexList.Get(aIdx :Integer) :IEvsIndexInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsIndexInfo;
end;

function TEvsIndexList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsIndexList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsIndexList.Put(aIdx :Integer; aValue :IEvsIndexInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsIndexList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsIndexList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsIndexList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsIndexList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsIndexList.Clear;extdecl;
begin
  FList.Clear;
end;
procedure TEvsIndexList.Assign(aSource :TPersistent);
var
  vSrc :TEvsIndexList absolute aSource;
  vCntr :Integer;
begin
  if aSource is TEvsIndexList then begin
    Clear;
    for vCntr := 0 to vSrc.Count -1 do begin
      New.CopyFrom(vSrc[vCntr]);
    end;
  end else inherited Assign(aSource);
end;

procedure TEvsIndexList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsIndexList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsIndexList.New :IEvsIndexInfo;extdecl;
begin
  Result := TEvsIndexInfo.Create(FOwner, True);
  Add(Result);
end;

function TEvsIndexList.First :IEvsIndexInfo;extdecl;
begin
  Result := FList.First as IEvsIndexInfo;
end;

function TEvsIndexList.IndexOf(aValue :IEvsIndexInfo) :Integer;extdecl;
begin
  Result := FList.IndexOf(aValue);
end;

function TEvsIndexList.Add(aValue :IEvsIndexInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsIndexList.Insert(aIdx :Integer; aValue :IEvsIndexInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsIndexList.Last :IEvsIndexInfo;extdecl;
begin
  Result := FList.Last as IEvsIndexInfo;
end;

function TEvsIndexList.Remove(aValue :IEvsIndexInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsIndexList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsIndexList.Unlock;extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsFieldList '}

function TEvsFieldList.Get(aIdx :Integer) :IEvsFieldInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsFieldInfo;
end;

function TEvsFieldList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsFieldList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsFieldList.Put(aIdx :Integer; aValue :IEvsFieldInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsFieldList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsFieldList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsFieldList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsFieldList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsFieldList.Assign(aSource :TPersistent);
var
  vSrc  :TEvsFieldList absolute aSource;
  vCntr :Integer;
begin
  if aSource is TEvsFieldList then begin
    Clear;
    for vCntr := 0 to vSrc.Count -1 do begin
      New.CopyFrom(vSrc[vCntr]);
    end;
  end else inherited Assign(aSource);
end;

procedure TEvsFieldList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsFieldList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsFieldList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

function TEvsFieldList.New :IEvsFieldInfo;extdecl;
begin
  Result := TEvsFieldInfo.Create(FOwner, True);
  Add(Result);
end;

function TEvsFieldList.First :IEvsFieldInfo;extdecl;
begin
  Result := FList.First as IEvsFieldInfo;
end;

function TEvsFieldList.IndexOf(aValue :IEvsFieldInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsFieldList.Add(aValue :IEvsFieldInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsFieldList.Insert(aIdx :Integer; aValue :IEvsFieldInfo);extdecl;
begin
  FList.Insert(aIdx,aValue);
end;

function TEvsFieldList.Last :IEvsFieldInfo;extdecl;
begin
  Result := FList.Last as IEvsFieldInfo;
end;

function TEvsFieldList.Remove(aValue :IEvsFieldInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsFieldList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsFieldList.Unlock;extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsTableList '}

Function TEvsTableList.Get(aIdx :Integer) :IEvsTableInfo; extdecl;
begin
  Result := FList.Get(aIdx) as IEvsTableInfo;
end;

Function TEvsTableList.GetCapacity :Integer; extdecl;
begin
  Result := FList.Capacity;
end;

Function TEvsTableList.GetCount :Integer; extdecl;
begin
  Result := FList.Count;
end;

Procedure TEvsTableList.Put(aIdx :Integer; aValue :IEvsTableInfo); extdecl;
begin
  FList.Put(aIdx,aValue);
end;

Procedure TEvsTableList.SetCapacity(aValue :Integer); extdecl;
begin
  FList.SetCapacity(aValue);
end;

Procedure TEvsTableList.SetCount(aValue :Integer); extdecl;
begin
  FList.SetCount(aValue);
end;

Constructor TEvsTableList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsTableList.Destroy;
begin
  FList.Clear;
  FList := nil;//.Free;
  inherited Destroy;
end;

procedure TEvsTableList.Assign(Source :TPersistent);
var
  vSrc  :TEvsTableList absolute Source;
  vCntr :Integer;
begin
  if Source is TEvsTableList then begin
    Clear;
    for vCntr := 0 to vSrc.Count -1 do begin
      New.CopyFrom(vSrc[vCntr]);
    end;
  end else inherited Assign(Source);
end;

Procedure TEvsTableList.Clear; extdecl;
var
  vCntr :Integer;
begin
  FList.Clear;
  for vCntr := 0 to FList.Count -1 do begin
    FList[vCntr] := nil;
  end;
end;

Procedure TEvsTableList.Delete(aIndex :Integer); extdecl;
begin
  FList.Delete(aIndex);
end;

Procedure TEvsTableList.Exchange(aIndex1, aIndex2 :Integer); extdecl;
begin
  FList.Exchange(aIndex1,aIndex2);
end;

Function TEvsTableList.New :IEvsTableInfo; extdecl;
begin
  Result := TEvsTableInfo.Create(FOwner, True);
  Add(Result);
end;

Function TEvsTableList.First :IEvsTableInfo; extdecl;
begin
  Result := FList.First as IEvsTableInfo;
end;

Function TEvsTableList.IndexOf(aItem :IEvsTableInfo) :Integer; extdecl;
begin
  Result := FList.IndexOf(aItem);
end;

Function TEvsTableList.Add(aItem :IEvsTableInfo) :Integer; extdecl;
begin
  if FList.IndexOf(aItem) = -1 then
    Result := FList.Add(aItem);
end;

Procedure TEvsTableList.Insert(aIdx :Integer; aItem :IEvsTableInfo); extdecl;
begin
  if FList.IndexOf(aItem) = -1 then
    FList.Insert(aIdx,aItem);
end;

Function TEvsTableList.Last :IEvsTableInfo; extdecl;
begin
  Result := FList.Last as IEvsTableInfo;
end;

Function TEvsTableList.Remove(aItem :IEvsTableInfo) :Integer; extdecl;
begin
  Result := FList.Remove(aItem);
end;

Procedure TEvsTableList.Lock; extdecl;
begin
  FList.Lock;
end;

Procedure TEvsTableList.Unlock; extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsRoleList '}

function TEvsRoleList.Get(aIdx :Integer) :IEvsRoleInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsRoleInfo;
end;

function TEvsRoleList.GetCapacity :Integer;extdecl;
begin
  Result := FList.GetCapacity;
end;

function TEvsRoleList.GetCount :Integer;extdecl;
begin
  Result := FList.GetCount;
end;

procedure TEvsRoleList.Put(aIdx :Integer; aValue :IEvsRoleInfo);extdecl;
begin
  FList.Put(aIdx,aValue) ;
end;

procedure TEvsRoleList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsRoleList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsRoleList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FList := TInterfaceList.Create;
end;

Destructor TEvsRoleList.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

procedure TEvsRoleList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsRoleList.Delete(aIdx :Integer);extdecl;
begin
  FList.Delete(aIdx);
end;

procedure TEvsRoleList.Exchange(aIdx1, aIdx2 :Integer);extdecl;
begin
  FList.Exchange(aIdx1, aIdx2);
end;

Function TEvsRoleList.New :IEvsRoleInfo;extdecl;
begin
  Result := TEvsRoleInfo.Create(FOwner, True);
  Add(Result);
  //raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

function TEvsRoleList.First :IEvsRoleInfo;extdecl;
begin
  Result := FList.First as IEvsRoleInfo;
end;

function TEvsRoleList.IndexOf(aValue :IEvsRoleInfo) :Integer;extdecl;
begin
  Result:=FList.IndexOf(aValue);
end;

function TEvsRoleList.Add(aValue :IEvsRoleInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    Result := FList.Add(aValue);
end;

procedure TEvsRoleList.Insert(aIdx :Integer; aValue :IEvsRoleInfo);extdecl;
begin
  if FList.IndexOf(aValue) = -1 then
    FList.Insert(aIdx,aValue);
end;

function TEvsRoleList.Last :IEvsRoleInfo;extdecl;
begin
  Result := FList.Last as IEvsRoleInfo;
end;

function TEvsRoleList.Remove(aValue :IEvsRoleInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aValue);
end;

procedure TEvsRoleList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsRoleList.Unlock;extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

{$REGION ' TEvsCredentials '}

Procedure TEvsCredentials.SetUserName(aValue :WideString); extdecl;
begin
  if FUserName=aValue then Exit;
  FUserName:=aValue;
end;

procedure TEvsCredentials.SetLastChanged(aValue :TDateTime); extdecl;
begin
  FLastChanged := aValue;
end;

Function TEvsCredentials.GetUserName :WideString; extdecl;
begin
  Result := FUserName;
end;

function TEvsCredentials.GetLastChanged :TDateTime; extdecl;
begin
  Result := FLastChanged;
end;

Procedure TEvsCredentials.SetCharset(aValue :WideString); extdecl;
begin
  FCharset := aValue;
end;

Function TEvsCredentials.GetPassword :WideString; extdecl;
begin
  Result := FPassword;
end;

Function TEvsCredentials.GetCharSet :WideString;extdecl;
begin
  Result := FCharset;
end;

Function TEvsCredentials.GetRole :WideString; extdecl;
begin
  Result := FRole;
end;

Function TEvsCredentials.GetSavePwd :LongBool; extdecl;
begin
  Result := FSavePwd
end;

Procedure TEvsCredentials.SetPassword(aValue :WideString); extdecl;
begin
  if FPassword=aValue then Exit;
  FPassword:=aValue;
end;

Procedure TEvsCredentials.SetRole(aValue :WideString); extdecl;
begin
  if FRole=aValue then Exit;
  FRole:=aValue;
end;

Procedure TEvsCredentials.SetSavePwd(aValue :LongBool); extdecl;
begin
  FSavePwd := aValue;
end;

procedure TEvsCredentials.Assign(Source :TPersistent);
var
  vSrc : TEvsCredentials absolute Source;
begin
  if Source is TEvsCredentials then begin
    FPassword    := vSrc.FPassword;
    FRole        := vSrc.FRole;
    FUserName    := vSrc.FUserName;
    FCharset     := vSrc.FCharset;
    FSavePwd     := vSrc.FSavePwd;
    FLastChanged := vSrc.FLastChanged;
  end else inherited Assign(Source);
end;

{$ENDREGION}

{$REGION ' TEvsDabaseInfo '}

Function TEvsDatabaseInfo.GetExceptions(aIndex :Integer) :IEvsExceptionInfo; extdecl;
begin
  Result := (FExceptions[aIndex] as IEvsExceptionInfo);
end;

Function TEvsDatabaseInfo.GetHost :WideString; extdecl;
begin
  Result := FHost;
end;

Function TEvsDatabaseInfo.GetIndex(aIndex :Integer) :IEvsIndexInfo; extdecl;
begin
  Result := FIndices[aIndex];
end;

Function TEvsDatabaseInfo.GetRole(aIndex :Integer) :IEvsRoleInfo; extdecl;
begin
  Result := FRoles[aIndex];
end;

Function TEvsDatabaseInfo.GetIndexCount :Integer; extdecl;
begin
  Result := FIndices.Count;
end;

Function TEvsDatabaseInfo.GetPageSize :Integer; extdecl;
begin
  Result:=FPageSize;
end;

Function TEvsDatabaseInfo.GetRoleCount :Integer; extdecl;
begin
  Result := FRoles.Count
end;

Function TEvsDatabaseInfo.GetSequences(aIndex :Integer) :IEvsGeneratorInfo; extdecl;
begin
  Result := FSequences[aIndex] as IEvsGeneratorInfo;
end;

Function TEvsDatabaseInfo.GetSequenceCount :Integer; extdecl;
begin
  Result := FSequences.Count;
end;

Function TEvsDatabaseInfo.GetServerID :Integer; extdecl;
begin
  Result := FServerID;
end;

Function TEvsDatabaseInfo.GetUDF(aIndex :Integer) :IEvsUDFInfo; extdecl;
begin
  Result := FUdfs[aIndex];
end;

Function TEvsDatabaseInfo.GetUdfCount :Integer; extdecl;
begin
  Result:= FUdfs.Count;
end;
Function TEvsDatabaseInfo.GetDomainCount :Integer; extdecl;
begin
  Result:= FDomains.Count;
end;

Function TEvsDatabaseInfo.GetUser(aIndex :Integer) :IEvsUserInfo; extdecl;
begin
  Result := FUsers[aIndex];
end;

Function TEvsDatabaseInfo.GetUserCount :Integer; extdecl;
begin
  Result := FUsers.Count;
end;

Function TEvsDatabaseInfo.GetTitle :WideString; extdecl;
begin
  Result := FTitle;
end;

Procedure TEvsDatabaseInfo.SetConnection(aValue :IEvsConnection); extdecl;
begin
  if FCnn <> aValue then FCnn := aValue;
end;

Procedure TEvsDatabaseInfo.SetDatabase(aValue :WideString); extdecl;
begin
  if WideCompareText(FDatabase, aValue) = 0 then Exit;
  BeginUpdate;
  try
    FDatabase := aValue;
    IncludeUpdateFlags([dbsData,dbsChanged]);
    Notify(gaDataChange, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.SetTitle(aValue :WideString); extdecl;
begin
  if WideCompareText(FTitle, aValue) = 0 then Exit;
  BeginUpdate;
  try
    FTitle := aValue;
    //IncludeUpdateFlags([dbsData, dbsChanged]); //no meta data changed only visible data
    Notify(gaDataChange, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.SetDefaultCharSet(aValue :Widestring); extdecl;
begin
  if FDefaultCharset=aValue then Exit;

  BeginUpdate;
  try
    FDefaultCharset:=aValue;
    IncludeUpdateFlags([dbsChanged,dbsData]);
    Notify(gaDataChange, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.SetDefaultColation(aValue :WideString); extdecl;
begin
  if FDefaultCollation = aValue then Exit;
  BeginUpdate;
  try
    FDefaultCollation := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaDataChange, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.SetHost(aValue :WideString); extdecl;
begin
  if FHost=aValue then Exit;
  BeginUpdate;
  try
    FHost := aValue;
    Notify(gaDataChange, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.SetPageSize(aValue :Integer); extdecl;
begin
  if FPageSize=aValue then Exit;
  BeginUpdate;
  try
    FPageSize:=aValue;
    IncludeUpdateFlags([dbsChanged,dbsData]);
    Notify(gaDataChange, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.SetServerID(aValue :Integer); extdecl;
begin
  if FServerID = aValue then Exit;
  BeginUpdate;
  try
    FServerID := aValue; //no update for this
    Notify(gaDataChange, Self);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.GetExceptionCount :Integer; extdecl;
begin
  Result := FExceptions.Count;
end;

Function TEvsDatabaseInfo.GetCredentials :IEvsCredentials; extdecl;
begin
  Result := FCredentials;
end;

Function TEvsDatabaseInfo.GetConnection :IEvsConnection; extdecl;
begin
  Result := FCnn;
end;

Function TEvsDatabaseInfo.GetDatabase :WideString; extdecl;
begin
  Result := FDatabase;
end;

Function TEvsDatabaseInfo.GetDefaultCharSet :WideString; extdecl;
begin
  Result := FDefaultCharset;
end;

Function TEvsDatabaseInfo.GetDefaultColation :WideString; extdecl;
begin
  Result := FDefaultCollation;
end;

function TEvsDatabaseInfo.GetDomain(aIndex :Integer) :IEvsDomainInfo; extdecl;
begin
  Result := FDomains[aIndex];
end;

Function TEvsDatabaseInfo.GetStored(aIndex :Integer) :IEvsStoredInfo; extdecl;
begin
  Result := (FStoredProcs[aIndex] as IEvsStoredInfo);
end;

Function TEvsDatabaseInfo.GetTable(aIndex :Integer) :IEvsTableInfo; extdecl;
begin
  Result := FTables[aIndex];
end;

Function TEvsDatabaseInfo.GetTableCount :Integer; extdecl;
begin
  Result := FTables.Count;
end;

Constructor TEvsDatabaseInfo.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FCredentials := TEvsCredentials.Create(Self, True);

  FTables      := TEvsTableList.Create    (Self, True);
  FExceptions  := TEvsExceptionList.Create(Self, True);  //{$MESSAGE WARN 'Needs Implementation'}
  FViews       := TEvsViewList.Create     (Self, True);  //{$MESSAGE WARN 'Needs Implementation'}
  FTriggers    := TEvsTriggerList.Create  (Self, True);
  FUdfs        := TEvsUDFList.Create      (Self, True);
  FStoredProcs := TEvsStoredList.Create   (Self, True);
  FSequences   := TEvsSequenceList.Create(Self, True);
  FIndices     := TEvsIndexList.Create    (Self, True);         //database indices? there is nothing like that.
  FDomains     := TEvsDomainList.Create   (Self, True);  //{$MESSAGE WARN 'Needs Testing'}
  FUsers       := TEvsUserList.Create     (Self, True);  //{$MESSAGE WARN 'Needs Testing'} //10
  FRoles       := TEvsRoleList.Create     (Self, True);
end;

Destructor TEvsDatabaseInfo.Destroy;
begin
  FCredentials := Nil;
  FCnn         := Nil;
  FCredentials := Nil;

  FTables      := Nil;
  FExceptions  := Nil;
  FViews       := Nil;
  FTriggers    := Nil;
  FUdfs        := Nil;
  FStoredProcs := Nil;
  FSequences   := Nil;
  FIndices     := Nil;
  FDomains     := Nil;
  FUsers       := nil;

  inherited Destroy;
end;

procedure TEvsDatabaseInfo.Assign(Source :TPersistent);
begin
  inherited Assign(Source);
  if Source is TEvsDatabaseInfo then begin
    FDefaultCollation := TEvsDatabaseInfo(Source).DefaultColation;
    FDefaultCharset   := TEvsDatabaseInfo(source).DefaultCharset;
    FDatabase         := TEvsDatabaseInfo(source).Database;
    FHost             := TEvsDatabaseInfo(source).Host;
    FPageSize         := TEvsDatabaseInfo(source).PageSize;
    FServerID         := TEvsDatabaseInfo(source).ServerKind;
    FTitle            := TEvsDatabaseInfo(source).Title;
    FCnn              := Connect(Self, FServerID);
    FCredentials.UserName := TEvsDatabaseInfo(Source).Credentials.UserName;
    FCredentials.Password := TEvsDatabaseInfo(Source).Credentials.Password;
    FCredentials.Role     := TEvsDatabaseInfo(Source).Credentials.Role;
  end;
end;

Function TEvsDatabaseInfo.TableList :IEvsTableList; extdecl;
begin
  Result := FTables;
end;

Function TEvsDatabaseInfo.StoredList :IEvsStoredList; extdecl;
begin
  Result := FStoredProcs;//.New;
end;

Function TEvsDatabaseInfo.ViewList :IEvsViewList; extdecl;
begin
  Result := FViews;
  //raise NotImplementedException; {$MESSAGE WARN 'Needs Implementation'}
end;

Function TEvsDatabaseInfo.SequenceList :IEvsSequenceList; extdecl;
begin
  Result := FSequences;
end;

Function TEvsDatabaseInfo.TriggerList :IEvsTriggerList; extdecl;
begin
  Result := FTriggers;
end;

Function TEvsDatabaseInfo.UDFList :IEvsUDFList; extdecl;
begin
  Result := FUdfs;
end;

Function TEvsDatabaseInfo.IndexList :IEvsIndexList; extdecl;
begin
  Result := FIndices;
end;

Function TEvsDatabaseInfo.ExceptionList :IEvsExceptionList; extdecl;
begin
  Result := FExceptions;
end;

Function TEvsDatabaseInfo.DomainList :IEvsDomainList; extdecl;
begin
  Result := FDomains;
end;

Function TEvsDatabaseInfo.NewTable(const aTableName :WideString) :IEvsTableInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := FTables.New;
    Result.TableName := aTableName;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewDomain(const aDomainName :WideString; const aDataType :WideString; const aSize :integer; const aCheck :WideString;
  aCharset :WideString; aCollation :WideString) :IEvsDomainInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := FDomains.New;
    Result.Name      := aDomainName;
    Result.DataType  := aDataType;
    Result.Size      := aSize;
    Result.CheckConstraint := aCheck;
    Result.CharSet         := aCharset;
    Result.Collation       := aCollation;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewIndex(const aName :WideString; const aORder :TEvsSortOrder; aFieldList :array of IEvsFieldInfo) :IEvsIndexInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := FIndices.New;
    Result.Parent := Self;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewStored(const aName :WideString; const aSql :WideString) :IEvsStoredInfo; extdecl;
var
  vCntr : Integer;
begin
  BeginUpdate;
  try
    Result := TEvsDBInfoFactory.NewStoredProc;
    Result.Name := aName;
    FStoredProcs.Add(Result);
    Result.Parent := Self;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewView(const aName :WideString; const aSql :WideString) :IEvsViewInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := TEvsViewInfo.Create(Self, True);
    Result.Name := aName;
    Result.SQL  := aSql;
    FViews.Add(Result);
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result as IEvsObjectRef);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewException(const aName :WideString; const aMessage :WideString) :IEvsExceptionInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := TEvsExceptionInfo.Create(Self, True);
    Result.Name    := aName;
    Result.Message := aMessage;
    FExceptions.Add(Result);
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewUDF(const aName :WideString) :IEvsUDFInfo; extdecl; {$MESSAGE WARN 'Needs Testing'}
begin
  BeginUpdate;
  try
    Result      := UDFList.New;
    Result.Name := aName;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewTrigger :IEvsTriggerInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := TEvsTriggerInfo.Create(Self, True);
    FTriggers.Add(Result);
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewSequence :IEvsSequenceInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := FSequences.New;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewUser(const aUserName :WideString) :IEvsUserInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := FUsers.New;
    Result.UserName := aUserName;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewUser:IEvsUserInfo; overload;extdecl;
begin
  BeginUpdate;
  try
    Result := FUsers.New;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewRole(const aRoleName :WideString) :IEvsRoleInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := FRoles.New;
    Result.Name := aRoleName;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.NewRole :IEvsRoleInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := FRoles.New;
    IncludeUpdateFlags([dbsChanged, dbsData]);
    Notify(gaInsert, Result);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsTableInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    FTables.Remove(aObject);
    IncludeUpdateFlags([dbsChanged,dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsIndexInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    if aObject.Parent is IEvsTableInfo then IEvsTableInfo(aObject.Parent).Remove(aObject);
    IncludeUpdateFlags([dbsChanged,dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsTriggerInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    if aObject.Parent is IEvsTableInfo then
      IEvsTableInfo(aObject.Parent).Remove(aObject)
    else
      FTriggers.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;

end;

Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsFieldInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    if aObject.Parent is IEvsTableInfo then
      IEvsTableInfo(aObject.Parent).Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsStoredInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    FStoredProcs.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsSequenceInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    FSequences.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;
end;
Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsExceptionInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    FExceptions.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;
end;
Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsUDFInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    FUdfs.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsViewInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    FViews.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.Remove(const aObject :IEvsUserInfo); overload;extdecl;
begin
  BeginUpdate;
  try
    FUsers.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaExtracting, aObject);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearTables;    extdecl;
begin
  BeginUpdate;
  try
    FTables.Clear;// Users.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearStored;    extdecl;
begin
  BeginUpdate;
  try
    FStoredProcs.Clear;//.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearExceptions;extdecl;
begin
  BeginUpdate;
  try
    FExceptions.Clear;//.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearSequences; extdecl;
begin
  BeginUpdate;
  try
    FSequences.Clear;// .Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearViews;     extdecl;
begin
  BeginUpdate;
  try
    FViews.Clear;///.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearTriggers;  extdecl;
begin
  BeginUpdate;
  try
    FTriggers.Clear;//.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearUDFs;      extdecl;
begin
  BeginUpdate;
  try
    FUdfs.Clear;//.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearDomains;    extdecl;
begin
  BeginUpdate;
  try
    FDomains.Clear;//.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearRoles;     extdecl;
begin
  BeginUpdate;
  try
    FRoles.Clear; //Users.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsDatabaseInfo.ClearUsers;     extdecl;
begin
  BeginUpdate;
  try
    FUsers.Clear;//Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
    Notify(gaUpdate, Self);
  finally
    EndUpdate;
  end;
end;

Function TEvsDatabaseInfo.GetProcedureCount :Integer; extdecl;
begin
  Result := FStoredProcs.Count;
end;

Function TEvsDatabaseInfo.GetViewCount :Integer; extdecl;
begin
  Result := FViews.Count;
end;

Function TEvsDatabaseInfo.GetView(aIndex :Integer) :IEvsViewInfo; extdecl;
begin
  Result := FViews[aIndex];
end;

Function TEvsDatabaseInfo.GetTriggerCount :Integer; extdecl;
begin
  Result := FTriggers.Count;
end;

Function TEvsDatabaseInfo.GetTrigger(aIndex :Integer) :IEvsTriggerInfo; extdecl;
begin
  Result := FTriggers[aIndex];
end;

{$ENDREGION}

{$REGION ' TEvsTableInfo '}

Function TEvsTableInfo.GetCharset :WideString; extdecl;
begin
  Result := FCharset;
end;

Function TEvsTableInfo.GetCollation :WideString; extdecl;
begin
  Result := FCollation;
end;

Function TEvsTableInfo.GetDescription :wideString; extdecl;
begin
  Result := FDescription;
end;

Function TEvsTableInfo.GetField(aIndex :Integer) :IEvsFieldInfo; extdecl;
begin
  Result := (FFieldList[aIndex] as IEvsFieldInfo);
end;

Function TEvsTableInfo.GetFieldCount :Integer; extdecl;
begin
  Result := FFieldList.Count;
end;

Function TEvsTableInfo.GetIndex(aIndex :Integer) :IEvsIndexInfo; extdecl;
begin
  Result:= FIndexList[aIndex] as IEvsIndexInfo;
end;

Function TEvsTableInfo.GetIndexCount :Integer; extdecl;
begin
  Result := FIndexList.Count;
end;

function TEvsTableInfo.GetSystemTable :LongBool; stdcall;
begin
  Result := FSysTable;
end;

Function TEvsTableInfo.GetTriggerCount :Integer; extdecl;
begin
  Result := FTriggerList.Count;
end;

Function TEvsTableInfo.GetTableName :WideString; extdecl;
begin
  Result := FTableName;
end;

Function TEvsTableInfo.GetTrigger(aIndex :Integer) :IEvsTriggerInfo; extdecl;
begin
  Result := FTriggerList[aIndex];
end;

Procedure TEvsTableInfo.SetCharSet(aValue :WideString); extdecl;
begin
  if CompareText(FCharset,aValue)<>0 then begin
    FCharset := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetaData]);
  end;
end;

Procedure TEvsTableInfo.SetCollation(aValue :WideString); extdecl;
begin
  if CompareText(FCollation,aValue)<>0 then begin
    FCollation := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetaData]);
  end;
end;

Procedure TEvsTableInfo.SetDescription(aValue :wideString); extdecl;
begin
  if CompareText(FDescription,aValue)<>0 then begin
    FDescription := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetaData]);
  end;
end;

Procedure TEvsTableInfo.SetField(aIndex :Integer; aValue :IEvsFieldInfo); extdecl;
begin
  if FFieldList[aIndex] <> aValue then begin
    FFieldList[aIndex] := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

Procedure TEvsTableInfo.SetIndex(aIndex :Integer; aValue :IEvsIndexInfo); extdecl;
begin
  if (FIndexList[aIndex] <> aValue) then begin
    FIndexList[aIndex] :=  aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetaData]);
  end;
end;

procedure TEvsTableInfo.SetSystemTable(aValue :LongBool);extdecl;
begin
  if (FSysTable <> aValue) then begin
    BeginUpdate;
    try
      FSysTable := aValue;
      IncludeUpdateFlags([dbsChanged, dbsData]);
    finally
      EndUpdate;
    end;
  end;
end;

Procedure TEvsTableInfo.SetTableName(aValue :WideString); extdecl;
begin
  if CompareText(FTableName,aValue)<>0 then begin
    FTableName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;
Procedure TEvsTableInfo.SetTrigger(aIndex :Integer; aValue :IEvsTriggerInfo); extdecl;
begin
  if FTriggerList[aIndex] <> aValue then begin
    FTriggerList[aIndex] := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

Function TEvsTableInfo.FieldIndexOf(const aName :Widestring) :Integer; extdecl;
var
  vCntr:Integer;
  vFld : widestring;
begin
  Result := -1;
  for vCntr := 0 to FFieldList.Count -1 do begin
    vFld := FFieldList[vCntr].FieldName;
    if WideCompareText(aName,FFieldList[vCntr].FieldName) = 0 then
      Exit(vCntr);
  end;
end;

Function TEvsTableInfo.FieldIndexOf(const aField :IEvsFieldInfo) :Integer; extdecl;
var
  vCntr:Integer;
begin
  Result := -1;
  for vCntr := 0 to FFieldList.Count -1 do begin
    if aField = (FFieldList[vCntr] as IEvsFieldInfo) then Exit(vCntr);
  end;
end;

Function TEvsTableInfo.FieldByName(const aFieldName :WideString) :IEvsFieldInfo; extdecl;
var
  vIdx:Integer;
begin
  Result:=Nil;
  vIdx := FieldIndexOf(aFieldName);
  if vIdx > -1 then Result := FFieldList[vIdx] as IEvsFieldInfo;
end;

Procedure TEvsTableInfo.Remove(const aObject :IEvsTriggerInfo); extdecl;
begin
  BeginUpdate;
  try
    FTriggerList.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsTableInfo.Remove(const aObject :IEvsFieldInfo); extdecl;
begin
  BeginUpdate;
  try
    FFieldList.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

Procedure TEvsTableInfo.Remove(const aObject :IEvsIndexInfo); extdecl;
begin
  BeginUpdate;
  try
    FIndexList.Remove(aObject);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

Constructor TEvsTableInfo.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  inherited Create(aOwner, aRefCounted);
  FFieldList   := TEvsFieldList.Create(Self, True);
  FIndexList   := TEvsIndexList.Create(Self, True);
  FTriggerList := TEvsTriggerList.Create(Self, True);
end;

Destructor TEvsTableInfo.Destroy;
begin
  FFieldList   := Nil;
  FIndexList   := Nil;
  FTriggerList := Nil;
  inherited Destroy;
end;

procedure TEvsTableInfo.Assign(aSource :TPersistent);
var
  vSrc : TEvsTableInfo absolute aSource;
begin
  if aSource is TEvsTableInfo then begin
    FCharset     := vSrc.CharSet;
    FCollation   := vSrc.Collation;
    FDescription := vSrc.Description;
    FTableName   := vSrc.TableName;
    FSysTable    := vSrc.FSysTable;
    FFieldList.CopyFrom(vSrc.FFieldList);
    //FFieldList := aSource.FieldList;
    FIndexList.CopyFrom(vSrc.FIndexList);
    //FIndexList := aSource.IndexList;
    FTriggerList.CopyFrom(vSrc.FTriggerList);
    //FTriggerList := aSource.TriggerList;
  end else inherited Assign(aSource);
end;

Function TEvsTableInfo.AddField(const aFieldName, aDataType :WideString; const aFieldsIze, aFieldScale :Integer; const aCharset,
  aCollation :WideString; const AllowNulls, AutoNumber :ByteBool) :IEvsFieldInfo; extdecl;{$MESSAGE WARN 'Needs Testing'}
begin
  BeginUpdate;
  try
    Result := uEvsDBSchema.NewField(Self, aFieldName, aDataType, aFieldsIze);
    Result.FieldScale := aFieldScale;
    Result.Charset    := aCharset;
    Result.Collation  := aCollation;
    Result.AllowNulls := AllowNulls;
    Result.AutoNumber := AutoNumber;
    FFieldList.Add(Result);
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  finally
    EndUpdate;
  end;
end;

Function TEvsTableInfo.AddIndex(const aName :widestring; const aFields :Array of IEvsFieldInfo;
                                const aFieldOrders :array of TEvsSortOrder) :IEvsIndexInfo;overload;extdecl;{$MESSAGE WARN 'Needs Testing'}
var
  vCntr :Integer;
begin
  BeginUpdate;
  try
    Result := AddIndex(aName, aFieldOrders[0]); //TEvsIndexInfo.Create(Self, True);
    for vCntr := Low(aFields) to High(aFields) do begin
      if FieldIndexOf(aFields[vCntr]) > -1 then
        Result.AppendField(aFields[vCntr],aFieldOrders[vCntr])
      else raise ETBException.CreateFmt('Field %S not found in the table.', [aFields[vCntr].FieldName]);
    end;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  finally
    EndUpdate;
  end;
end;

Function TEvsTableInfo.AddIndex(const aName:widestring; aOrder:TEvsSortOrder):IEvsIndexInfo;overload;extdecl;
begin
  BeginUpdate;
  try
    Result := TEvsIndexInfo.Create(Self, True);
    Result.IndexName := aName;
    Result.Order := aOrder;
    FIndexList.Add(Result);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;

end;

Function TEvsTableInfo.AddIndex(const aName :widestring; const aFieldNames :Array of WideString; const aFieldOrders :array of TEvsSortOrder) :IEvsIndexInfo; extdecl;
var
  vCntr :Integer;
begin
  BeginUpdate;
  try
    Result := TEvsIndexInfo.Create(Self, True);
    Result.IndexName := aName;
    for vCntr := Low(aFieldNames) to High(aFieldNames) do begin
      if FieldIndexOf(aFieldNames[vCntr]) < 0 then
        Result.AppendField(FieldByName(aFieldNames[vCntr]),aFieldOrders[vCntr]);
    end;
    FIndexList.Add(Result);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

Function TEvsTableInfo.NewField :IEvsFieldInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := TEvsFieldInfo.Create(Self,True);
    FFieldList.Add(Result);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;

end;

Function TEvsTableInfo.NewIndex :IEvsIndexInfo; extdecl;
begin
  BeginUpdate;
  try
    Result := TEvsIndexInfo.Create(Self,True);
    FIndexList.Add(Result);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

Function TEvsTableInfo.NewTrigger :IEvsTriggerInfo;extdecl;
begin
  BeginUpdate;
  try
    Result := TEvsTriggerInfo.Create(Self,True);
    FTriggerList.Add(Result);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

{$ENDREGION}

{$REGION ' TEvsIndexInfo '}

function TEvsIndexInfo.GetField(aIndex :Integer) :IEvsFieldInfo;extdecl;
begin
  Result := (FList[aIndex] as IEvsIndexFieldInfo).Field;
end;

function TEvsIndexInfo.GetDescription :widestring;extdecl;
begin
  Result := FDescription;
end;

function TEvsIndexInfo.GetFieldCount :Integer;extdecl;
begin
  Result := FList.Count;
end;

function TEvsIndexInfo.GetFieldOrder(aIndex :Integer) :TEvsSortOrder;extdecl;
begin
  Result := (FList[aIndex] as IEvsIndexFieldInfo).Order;
end;

function TEvsIndexInfo.GetIndexName :WideString;extdecl;
begin
  Result := FIndexName;
end;

function TEvsIndexInfo.GetOrder :TEvsSortOrder;extdecl;
begin
  Result := FOrder;
end;

function TEvsIndexInfo.GetPrimary :ByteBool;extdecl;
begin
  Result := FPrimary;
end;

function TEvsIndexInfo.GetTable :IEvsTableInfo;extdecl;
begin
  raise NotImplementedException;
end;

function TEvsIndexInfo.GetUnique :ByteBool;extdecl;
begin
  Result := FUnique or FPrimary;
end;

procedure TEvsIndexInfo.SetDescription(aValue :widestring);extdecl;
begin
  BeginUpdate;
  try
    FDescription := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.SetField(Index :Integer; const Value :IEvsFieldInfo);extdecl;
begin
  BeginUpdate;
  try
    (FList[Index] as IEvsIndexFieldInfo).Field := Value;
    IncludeUpdateFlags([dbsChanged,dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.SetFieldOrder(Index :Integer; const Value :TEvsSortOrder);extdecl;
begin
  BeginUpdate;
  try
    (FList[Index] as IEvsIndexFieldInfo).Order := Value;
    IncludeUpdateFlags([dbsChanged,dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.SetIndexName(const aValue :WideString);extdecl;
begin
  if aValue <> FIndexName then begin
    FIndexName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

procedure TEvsIndexInfo.SetOrder(const aValue :TEvsSortOrder);extdecl;
begin
  if aValue <> FOrder then begin
    FOrder := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

procedure TEvsIndexInfo.SetPrimary(aValue :ByteBool);extdecl;
begin
  if aValue <> FPrimary then begin
    FPrimary := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

procedure TEvsIndexInfo.SetTable(aValue :IEvsTableInfo);extdecl;
begin
  raise NotImplementedException;
end;

procedure TEvsIndexInfo.SetUnique(aValue :ByteBool);extdecl;
begin
  if aValue <> FUnique then begin
    FUnique := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

function TEvsIndexInfo.IndexOf(const aField :IEvsFieldInfo) :integer;overload;extdecl;
var
  vCntr :Integer;
begin
  Result := -1;
  for vCntr := 0 to FList.Count -1 do begin
    if (FList[vCntr] as IEvsIndexFieldInfo).Field = aField then Exit(vCntr);
  end;
end;

function TEvsIndexInfo.IndexOf(const aFieldName :string) :Integer;overload;extdecl;
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

Destructor TEvsIndexInfo.Destroy;
begin
  FList.Clear;
  FList := Nil;
  inherited Destroy;
end;

function TEvsIndexInfo.TableName :string;extdecl;
begin
  Result := '';     {$MESSAGE WARN 'Needs Implementation'}
  //if FOwner is tevsTableInfo then Result:= tevstableinfo(fowner).TableName;
end;

procedure TEvsIndexInfo.Assign(Source :TPersistent);
var
  vSrc : TEvsIndexInfo absolute Source;
begin
  if Source is TEvsIndexInfo then begin
    FUnique      := vSrc.FUnique     ;
    FPrimary     := vSrc.FPrimary    ;
    FOrder       := vSrc.FOrder      ;
    FIndexName   := vSrc.FIndexName  ;
    FDescription := vSrc.FDescription;
    raise SilentException('Needs more work.');
  end else inherited Assign(Source);
end;

procedure TEvsIndexInfo.SwapFields(const Index1, Index2 :Integer);extdecl;
begin
  FList.Exchange(Index1,Index2);
end;

procedure TEvsIndexInfo.AppendField(const aField :IEVSFieldInfo; const aOrder :TEvsSortOrder);extdecl;
begin
  BeginUpdate;
  try
    if not Assigned(aField) then raise ETBException.Create('Null fields are not allowed.');
    if IndexOf(aField.FieldName) <> -1 then raise ETBException.CreateFmt('Field %S already exists in the List.',[aField.FieldName]);
    FList.Add(NewIndexField(Self, aField, aOrder));
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.DeleteField(const aIndex :Integer);extdecl;
begin
  BeginUpdate;
  try
    FList.Delete(aIndex);
    IncludeUpdateFlags([dbsChanged, dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.DeleteField(const aField :IEvsFieldInfo);extdecl;
begin
  BeginUpdate;
  try
    FList.Delete(IndexOf(aField));
    IncludeUpdateFlags([dbschanged,dbsData]);
  finally
    EndUpdate;
  end;
end;

procedure TEvsIndexInfo.ClearFields;extdecl;
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

procedure TEvsIndexFieldInfo.SetField(aValue :IEvsFieldInfo);extdecl;
begin
  if FField<>aValue then begin
    FField:=aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

function TEvsIndexFieldInfo.GetField :IEvsFieldInfo;extdecl;
begin
  Result := FField;
end;

function TEvsIndexFieldInfo.GetOrder :TEvsSortOrder;extdecl;
begin
  Result := FOrder;
end;

procedure TEvsIndexFieldInfo.SetOrder(aValue :TEvsSortOrder);extdecl;
begin
  if FOrder=aValue then Exit;
  FOrder:=aValue;
end;

procedure TEvsIndexFieldInfo.Assign(aSource:TPersistent);
var
  vSrc : TEvsIndexFieldInfo absolute aSource;
begin
  if aSource is TEvsIndexFieldInfo then begin
    FField := vSrc.FField;
    FOrder := vSrc.FOrder;
  end else inherited Assign(aSource);
end;

Function TEvsIndexFieldInfo.EqualsTo(const aCompare :IEvsCopyable) :Boolean; extdecl;
var
  vTmp :IEvsIndexFieldInfo;
begin
  Result := inherited EqualsTo(aCompare);
  if Supports(aCompare, IEvsIndexFieldInfo, vTmp) and (not Result) then begin
    Result := Result or ((FOrder = vTmp.order)
                     and (FField.EqualsTo(vTmp.Field)));
  end;
end;

{$ENDREGION}

{$REGION ' TEvsDBInfo '}

function TEvsDBInfo.GetStates :TEvsDBStates;
begin
  Result := FUpdateStates;
end;

function TEvsDBInfo.ObjectRef :TObject; extdecl;
begin
  Result := Self;
end;

procedure TEvsDBInfo.AddOwned(aObj :TEvsDBInfo);
var
  vIdx:Integer=-1;
begin
  //if Assigned(FOwned) then vIdx := FOwned.IndexOf(aObj) else begin
  //  FOwned := TObjectList.Create(False);
  //  vIdx := -1;
  //end;
  if vIdx > -1 then raise ETBException.Create('Dublicates are not allowed.');
  //FOwned.Add(aObj);
  //aObj.FOwner := Self;
end;

procedure TEvsDBInfo.ExtractOwned(aObj :TEvsDBInfo);
//var
//  vIdx:Integer;
begin
  //vIdx := FOwned.IndexOf(aObj);
  //if vIdx > -1 then FOwned.Extract(aObj);
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

procedure TEvsDBInfo.ClearStateFlags;
begin
  FUpdateStates := [];
end;

function TEvsDBInfo.GetParent :IEvsParented;extdecl;
begin
  if Assigned(FOwner) then Result := FOwner
  else Result := FParent;
end;

procedure TEvsDBInfo.SetParent(aValue :IEvsParented);extdecl;
var
  vObj : TEvsDBInfo;
begin
  if Supports(aValue, TEvsDBInfo, vObj) then begin
    if Assigned(FOwner) then FOwner.ExtractOwned(self);
    vObj.AddOwned(Self);
    FParent := Nil;
  end else begin
    if Assigned(FOwner) then FOwner.ExtractOwned(Self);
    FParent := aValue;
  end;
end;

Constructor TEvsDBInfo.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
begin
  FRefCounted := aRefCounted;
  inherited Create;
  if Assigned(aOwner) then aOwner.AddOwned(Self);
  FUpdateCount := 0;
  FUpdateStates := [];
  FObservers := TEvsObserverList.Create;
end;

Destructor TEvsDBInfo.Destroy;
begin
  FObservers := Nil;
  //if Assigned(FOwned) then begin
  //  FOwned.OwnsObjects := True;
  //  FOwned.Clear;
  //  FOwned.Free;
  //end;
  inherited Destroy;
end;

function TEvsDBInfo.CopyFrom(const aSource :IEvsCopyable) :Integer; extdecl;
var
  vTmp:TPersistent;
begin
  Result := 0 ;
  if Supports(aSource,TPersistent, vTmp) then Assign(vTmp)
  else Result := aSource.CopyTo(Self as IEvsCopyable);// raise ETBException.Create('Unsupported Source');
end;

function TEvsDBInfo.CopyTo(const aDest :IEvsCopyable):Integer; extdecl;
var
  vTmp:TPersistent;
begin
  if Supports(aDest,TPersistent, vTmp) then AssignTo(vTmp)
  else Result := -1; //raise ETBException.Create('Unsupported Destination');
end;

Function TEvsDBInfo.EqualsTo(const aCompare :IEvsCopyable) :Boolean; extdecl;
begin
  Result := (aCompare = Self as IEvsCopyable);
end;

Procedure TEvsDBInfo.AddObserver(Observer :IEvsObserver); extdecl;
begin
  if not Assigned(FObservers) then FObservers := TEvsObserverList.Create;
  FObservers.Add(Observer);
end;

Procedure TEvsDBInfo.DeleteObserver(Observer :IEvsObserver); extdecl;
var
  vIdx:Integer;
begin
  if not Assigned(FObservers) then Exit;
  vIdx := FObservers.IndexOf(Observer);
  if vIdx > -1 then FObservers.Delete(vIdx);
end;

Procedure TEvsDBInfo.ClearObservers; extdecl;
begin
  if Assigned(FObservers) then
    FObservers.Clear;
end;

Procedure TEvsDBInfo.Notify(const Action :TEVSGenAction; const aSubject :IEvsObjectRef); extdecl;
var
  vCntr :Integer;
begin
  if Assigned(FObservers) then begin
    for vCntr := 0 to FObservers.Count -1 do begin
      FObservers[vCntr].Update(aSubject, Action);
    end;
  end;
end;

Procedure TEvsDBInfo.Update(aSubject :IEvsObjectRef; Action :TEVSGenAction); extdecl;
begin
  //if (Action = gaDestroy) and ((aSubject.ObjectRef is TEvsDBInfo) and (TEvsDBInfo(aSubject.ObjectRef).FOwner = Self)) then
  //  FOwned.Remove(aSubject.ObjectRef);
end;

Procedure TEvsDBInfo.ClearState; extdecl;
begin
  FUpdateStates := [];
end;

Function TEvsDBInfo.QueryInterface(constref IID :TGUID; out Obj) :HResult; extdecl;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

Function TEvsDBInfo._AddRef :Integer; extdecl;
begin
  if Assigned(FOwner) then Result := FOwner._AddRef
  else begin
    if FRefCounted  then
      Result := InterlockedIncrement(FRefCount)
    else
      Result := -1; //FRefCount;
  end;
end;

Function TEvsDBInfo._Release :Integer; extdecl;
begin
  if Assigned(FOwner) then Result := FOwner._Release
  else begin
    Result := -1;
    if FRefCounted then begin
      Result := InterlockedDecrement(FRefCount);
      if Result = 0 then
        Destroy;
    end;
  end;
end;

Procedure TEvsDBInfo.AfterConstruction;
begin
  inherited AfterConstruction;
  if FRefCounted then InterlockedDecrement(FRefCount);
end;

Procedure TEvsDBInfo.BeforeDestruction;
begin
  if FRefCounted and (FRefCount <> 0) then
    System.Error(reInvalidOp);
  inherited BeforeDestruction;
end;

class Function TEvsDBInfo.NewInstance :TObject;
begin
  Result := inherited NewInstance;
  if Result <> nil then TEvsDBInfo(Result).FRefCount := 1;
end;


{$ENDREGION}

{$REGION ' TEvsFieldInfo '}

Function TEvsFieldInfo.GetAllowNull :ByteBool; extdecl;
begin
  Result := FAllowNulls;
end;

Function TEvsFieldInfo.GetAutoNumber :ByteBool; extdecl;
begin
  Result := FAutoNumber;
end;

Function TEvsFieldInfo.GetCalculated :widestring; extdecl;
begin
  Result := FCalculated;
end;

Function TEvsFieldInfo.GetCanAutoInc :WordBool; extdecl;
begin
  Result := FAutoNumber;
end;

Function TEvsFieldInfo.GetCharset :widestring; extdecl;
begin
  Result := FCharset;
end;

Function TEvsFieldInfo.GetCheck :widestring; extdecl;
begin
  Result := FCheck;
end;

Function TEvsFieldInfo.GetColation :widestring; extdecl;
begin
  Result := FCollation;
end;

function TEvsFieldInfo.GetDataGroup :TEvsDataGroup;
begin
  Result := FDataGroup;
end;

Function TEvsFieldInfo.GetDataTypeName :widestring; extdecl;
begin
  Result := FDataTypeName;
end;

Function TEvsFieldInfo.GetDefaultValue :OLEVariant; extdecl;
begin
  Result := FDefaultValue;
end;

Function TEvsFieldInfo.GetFieldDescription :widestring; extdecl;
begin
  Result := FDescription;
end;

Function TEvsFieldInfo.GetFieldName :widestring; extdecl;
begin
  Result:=FFieldName;
end;

Function TEvsFieldInfo.GetFieldScale :Integer; extdecl;
begin
  Result:=FFieldScale;
end;

Function TEvsFieldInfo.GetFieldSize :integer; extdecl;
begin
  Result := FFieldSize;
end;

Procedure TEvsFieldInfo.SetAllowNull(aValue :ByteBool); extdecl;
begin
  if FAllowNulls <> aValue then begin
    FAllowNulls := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

Procedure TEvsFieldInfo.SetAutoNumber(aValue :ByteBool); extdecl;
begin
  if aValue <> FAutoNumber then begin
    FAutoNumber := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

Procedure TEvsFieldInfo.SetCalculated(aValue :widestring); extdecl;
begin
  if FCalculated <> aValue then begin;
    FCalculated := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

Procedure TEvsFieldInfo.SetCharset(aValue :widestring); extdecl;
begin
  if FCharset<>aValue then begin
    FCharset:=aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

Procedure TEvsFieldInfo.SetCheck(aValue :widestring); extdecl;
begin
  if FCheck<>aValue then begin
    FCheck:=aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

Procedure TEvsFieldInfo.SetColation(aValue :widestring); extdecl;
begin
  if FCollation<>aValue then begin
    FCollation := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.SetDataGroup(aValue :TEvsDataGroup);extdecl;
begin
  if FDataGroup <> aValue then begin
    FDataGroup := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

Procedure TEvsFieldInfo.SetDataTypeName(aValue :widestring); extdecl;
begin
  if aValue<>FDataTypeName then begin
    FDataTypeName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsdata]);
  end;
end;

Procedure TEvsFieldInfo.SetDefaultValue(aValue :OLEVariant); extdecl;
begin
  if FDefaultValue <> aValue then begin
    FDefaultValue := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

Procedure TEvsFieldInfo.SetFieldDescription(aValue :widestring); extdecl;
begin
  if comparetext(fDescription, aValue) <> 0 then begin
    FDescription := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

Procedure TEvsFieldInfo.SetFieldName(aValue :widestring); extdecl;
begin
  if FFieldName <>aValue then begin
    FFieldName := aValue;
    IncludeUpdateFlags([dbsChanged, dbsData]);
  end;
end;

Procedure TEvsFieldInfo.SetFieldScale(aValue :Integer); extdecl;
begin
  if FFieldScale <> aValue then begin
    FFieldScale := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

Procedure TEvsFieldInfo.SetFieldSize(aValue :integer); extdecl;
begin
  if FieldScale <> aValue then begin
    FFieldSize := aValue;
    IncludeUpdateFlags([dbsChanged, dbsMetadata]);
  end;
end;

procedure TEvsFieldInfo.Assign(Source:TPersistent);
var
  vSrc  :TEvsFieldInfo absolute Source;
begin
  if Source is TEvsFieldInfo then begin
    FFieldName    := vSrc.FFieldName;
    FDescription  := vSrc.FDescription;
    FAllowNulls   := vSrc.FAllowNulls;
    FDataTypeName := vSrc.FDataTypeName;
    FDefaultValue := vSrc.FDefaultValue;
    FAutoNumber   := vSrc.FAutoNumber;
    FFieldSize    := vSrc.FFieldSize;
    FFieldScale   := vSrc.FFieldScale;
    FCollation    := vSrc.FCollation;
    FCharset      := vSrc.FCharset;
    FCheck        := vSrc.FCheck;
    FCalculated   := vSrc.FCalculated;
    FDataGroup    := vSrc.FDataGroup;
  end else inherited Assign(Source);
end;

Function TEvsFieldInfo.EqualsTo(const aCompare :IEvsCopyable) :Boolean; extdecl;
var
  vTmp  :IEvsFieldInfo;
begin
  Result := inherited EqualsTo(aCompare);
  if Supports(aCompare, IEvsFieldInfo, vTmp) and (not Result) then begin
    Result := Result or(  (WideCompareText(FFieldName,    vTmp.FieldName)    = 0)
                      and (WideCompareText(FDescription,  vTmp.Description)  = 0)
                      and (WideCompareText(FCollation,    vTmp.Collation)    = 0)
                      and (WideCompareText(FCharset,      vTmp.Charset)      = 0)
                      and (WideCompareText(FCheck,        vTmp.Check)        = 0)
                      and (WideCompareText(FCalculated,   vTmp.Calculated)   = 0)
                      and (WideCompareText(FDataTypeName, vTmp.DataTypeName) = 0)
                      and (FAllowNulls   = vTmp.AllowNulls  )
                      and (FDefaultValue = vTmp.DefaultValue)
                      and (FAutoNumber   = vTmp.AutoNumber  )
                      and (FFieldSize    = vTmp.FieldSize   )
                      and (FFieldScale   = vTmp.FieldScale  )
                      and (FDataGroup    = vTmp.DataGroup   )
                       );
  end;
end;
{$ENDREGION}

procedure ClearKnownDBTypes;
var
  vCntr :Integer;
  vTmp  :PDBKindReg;
begin
  for vCntr := KnownDBTypes.Count -1 downto 0 do begin
    vTmp := PDBKindReg(KnownDBTypes[vCntr]);
    KnownDBTypes[vCntr] := nil;
    Dispose(vTmp);
  end;
  KnownDBTypes.Free;
end;

initialization
  KnownDBTypes := TList.Create;

finalization
  ClearKnownDBTypes;

end.


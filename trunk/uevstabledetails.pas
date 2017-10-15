unit uEvsTableDetails;

{$mode DELPHI}{$H+}

{$I EvsDefs.inc}

interface

uses
  Classes, SysUtils, uEvsDBSchema, uEvsGenIntf;

type
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

    Property FieldCount   :Integer read GetFieldCount;
    Property IndexCount   :Integer read GetIndexCount;
    Property TriggerCount :Integer read GetTriggerCount;
    Property Index[aIndex:Integer]   :IEvsIndexInfo   read GetIndex       write SetIndex;
    Property Field[aIndex:Integer]   :IEvsFieldInfo   read GetField       write SetField;   default;
    Property Trigger[aIndex:Integer] :IEvsTriggerInfo read GetTrigger     write SetTrigger;
    Property SystemTable             :LongBool        read GetSystemTable write SetSystemTable;
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

implementation

uses uEvsFields;

type
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
  FFieldList   := NewFieldList(Self, True); //TEvsFieldList.Create(Self, True);
  FIndexList   := TEvsIndexList.Create(Self, True);
  FTriggerList := TEvsTriggerList.Create(Self, True);
end;

Destructor TEvsTableInfo.Destroy;
begin
  FFieldList := Nil;
  FIndexList := Nil;
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

{$REGION ' TEvsTableList '}

function TEvsTableList.Get(aIdx :Integer) :IEvsTableInfo;extdecl;
begin
  Result := FList.Get(aIdx) as IEvsTableInfo;
end;

function TEvsTableList.GetCapacity :Integer;extdecl;
begin
  Result := FList.Capacity;
end;

function TEvsTableList.GetCount :Integer;extdecl;
begin
  Result := FList.Count;
end;

procedure TEvsTableList.Put(aIdx :Integer; aValue :IEvsTableInfo);extdecl;
begin
  FList.Put(aIdx,aValue);
end;

procedure TEvsTableList.SetCapacity(aValue :Integer);extdecl;
begin
  FList.SetCapacity(aValue);
end;

procedure TEvsTableList.SetCount(aValue :Integer);extdecl;
begin
  FList.SetCount(aValue);
end;

constructor TEvsTableList.Create(aOwner :TEvsDBInfo; aRefCounted :Boolean);
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

procedure TEvsTableList.Clear;extdecl;
begin
  FList.Clear;
end;

procedure TEvsTableList.Delete(aIndex :Integer);extdecl;
begin
  FList.Delete(aIndex);
end;

procedure TEvsTableList.Exchange(aIndex1, aIndex2 :Integer);extdecl;
begin
  FList.Exchange(aIndex1,aIndex2);
end;

function TEvsTableList.New :IEvsTableInfo;extdecl;
begin
  Result := TEvsTableInfo.Create(FOwner, True);
  Add(Result);
end;

function TEvsTableList.First :IEvsTableInfo;extdecl;
begin
  Result := FList.First as IEvsTableInfo;
end;

function TEvsTableList.IndexOf(aItem :IEvsTableInfo) :Integer;extdecl;
begin
  Result := FList.IndexOf(aItem);
end;

function TEvsTableList.Add(aItem :IEvsTableInfo) :Integer;extdecl;
begin
  if FList.IndexOf(aItem) = -1 then
    Result := FList.Add(aItem);
end;

procedure TEvsTableList.Insert(aIdx :Integer; aItem :IEvsTableInfo);extdecl;
begin
  if FList.IndexOf(aItem) = -1 then
    FList.Insert(aIdx,aItem);
end;

function TEvsTableList.Last :IEvsTableInfo;extdecl;
begin
  Result := FList.Last as IEvsTableInfo;
end;

function TEvsTableList.Remove(aItem :IEvsTableInfo) :Integer;extdecl;
begin
  Result := FList.Remove(aItem);
end;

procedure TEvsTableList.Lock;extdecl;
begin
  FList.Lock;
end;

procedure TEvsTableList.Unlock;extdecl;
begin
  FList.Unlock;
end;

{$ENDREGION}

end.


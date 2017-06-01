unit uEvsFields;

{$MODE DELPHI}{$H+}

{$I ..\..\EvsDefs.inc}

interface

uses
  Classes, SysUtils, uEvsDBSchema, uEvsGenIntf;

type

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

  {$IFDEF USE_GENERICINTF}
  IEvsFieldList = interface(IEvsInterfaceList<IEvsFieldInfo>)
    ['{57298EBB-63B1-4332-ADBE-BCB3221CFA16}']
    //['{816BBC49-9585-43D9-A7F8-5F61DAEF95A1}']
  end;

  {$ELSE USE_GenericIntf}
  IEvsFieldList = interface(IEvsCopyable) //OK
    ['{57298EBB-63B1-4332-ADBE-BCB3221CFA16}']
    Function  Get(aIndex : Integer) : IEvsFieldInfo;          extdecl;
    Function  GetCapacity : Integer;                          extdecl;
    Function  GetCount : Integer;                             extdecl;
    Procedure Put(aIndex : Integer;aItem : IEvsFieldInfo);    extdecl;
    Procedure SetCapacity(NewCapacity : Integer);             extdecl;
    Procedure SetCount(NewCount : Integer);                   extdecl;
    Procedure Clear;                                          extdecl;
    Procedure Delete(index : Integer);                        extdecl;
    Procedure Exchange(index1,index2 : Integer);              extdecl;
    Function  New:IEvsFieldInfo;                              extdecl;
    Function  First : IEvsFieldInfo;                          extdecl;
    Function  IndexOf(aItem : IEvsFieldInfo) : Integer;       extdecl;
    Function  Add(aItem : IEvsFieldInfo) : Integer;           extdecl;
    Procedure Insert(aIndex : Integer;aItem : IEvsFieldInfo); extdecl;
    Function  Last :IEvsFieldInfo;                            extdecl;
    Function  Remove(aItem : IEvsFieldInfo): Integer;         extdecl;
    Procedure Lock;                                           extdecl;
    Procedure Unlock;                                         extdecl;

    Property Capacity :Integer read GetCapacity write SetCapacity;
    Property Count    :Integer read GetCount    write SetCount;
    Property Items[aIndex :Integer] :IEvsFieldInfo read Get write Put; default;
  end;
  {$ENDIF}

function NewField(aOwner:TEvsDBInfo):IEvsFieldInfo;
function NewFieldList(aOwner:TEvsDBInfo):IEvsFieldList;

implementation

function NewField(aOwner:TEvsDBInfo):IEvsFieldInfo;
begin
  Result := Nil;
end;

function NewFieldList(aOwner :TEvsDBInfo) :IEvsFieldList;
begin
  Result := nil;
end;

type

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
  published
    Property FieldName    :WideString    read GetFieldName        write SetFieldName;
    Property Description  :WideString    read GetFieldDescription write SetFieldDescription;
    Property AllowNulls   :ByteBool      read GetAllowNull        write SetAllowNull          default True;
    Property DataTypeName :WideString    read GetDataTypeName     write SetDataTypeName;
    Property DefaultValue :OLEVariant    read GetDefaultValue     write SetDefaultValue;
    Property AutoNumber   :ByteBool      read GetAutoNumber       write SetAutoNumber         default False;
    Property FieldSize    :Integer       read GetFieldSize        write SetFieldSize;
    Property FieldScale   :Integer       read GetFieldScale       write SetFieldScale;
    Property Collation    :WideString    read GetColation         write SetColation;
    Property Charset      :WideString    read GetCharset          write SetCharset;
    Property Check        :WideString    read GetCheck            write SetCheck;
    Property Calculated   :WideString    read GetCalculated       write SetCalculated;
    Property DataGroup    :TEvsDataGroup read GetDataGroup        write SetDataGroup;
  end;

  { TEvsFieldList }
  TEvsFieldList = class(TEvsDBInfo, IEvsFieldList)
  private
    FList : IInterfaceList;
  protected
    Function Get(aIdx :Integer) :IEvsFieldInfo; extdecl;
    Function GetCapacity        :Integer;       extdecl;
    Function GetCount           :Integer;       extdecl;

    Procedure Put(aIdx :Integer; aValue :IEvsFieldInfo);extdecl;
    Procedure SetCapacity(aValue :Integer);             extdecl;
    Procedure SetCount(aValue :Integer);                extdecl;
  public
    Constructor Create(aOwner :TEvsDBInfo; aRefCounted :Boolean); override;
    Destructor Destroy; override;
    procedure Assign(aSource :TPersistent); override;
    Procedure Clear;extdecl;
    Procedure Delete  (aIdx :Integer);extdecl;
    Procedure Exchange(aIdx1, aIdx2 :Integer);extdecl;
    Procedure Insert  (aIdx :Integer; aValue : IEvsFieldInfo);extdecl;
    Procedure Lock;   extdecl;
    Procedure Unlock; extdecl;
    Function New   : IEvsFieldInfo;extdecl;
    Function First : IEvsFieldInfo;extdecl;
    Function IndexOf(aValue : IEvsFieldInfo) : Integer;extdecl;
    Function Add(aValue : IEvsFieldInfo) : Integer;extdecl;
    Function Last : IEvsFieldInfo;extdecl;
    Function Remove(aValue : IEvsFieldInfo): Integer;extdecl;

    Property Capacity :Integer read GetCapacity write SetCapacity;
    Property Count    :Integer read GetCount    write SetCount;
    Property Items[aIdx : Integer] : IEvsFieldInfo read Get write Put;default;
  end;

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

function TEvsFieldInfo.GetDataGroup :TEvsDataGroup; extdecl;
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

Function TEvsFieldInfo.EqualsTo(const aCompare :IEvsCopyable) :Boolean; extdecl;
var
  vTmp  :IEvsFieldInfo;
begin
  Result := inherited EqualsTo(aCompare);
  if Supports(aCompare, IEvsFieldInfo, vTmp) and (not Result) then begin
    Result := Result or (WideCompareText(FFieldName,    vTmp.FieldName)    = 0)
                     or (WideCompareText(FDescription,  vTmp.Description)  = 0)
                     or (WideCompareText(FCollation,    vTmp.Collation)    = 0)
                     or (WideCompareText(FCharset,      vTmp.Charset)      = 0)
                     or (WideCompareText(FCheck,        vTmp.Check)        = 0)
                     or (WideCompareText(FCalculated,   vTmp.Calculated)   = 0)
                     or (WideCompareText(FDataTypeName, vTmp.DataTypeName) = 0)
                     or (FAllowNulls   = vTmp.AllowNulls  )
                     or (FDefaultValue = vTmp.DefaultValue)
                     or (FAutoNumber   = vTmp.AutoNumber  )
                     or (FFieldSize    = vTmp.FieldSize   )
                     or (FFieldScale   = vTmp.FieldScale  )
                     or (FDataGroup    = vTmp.DataGroup   );
  end;
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

function TEvsFieldList.New :IEvsFieldInfo; extdecl;
begin
  Result := TEvsFieldInfo.Create(Owner, True);
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


end.


unit uEvsIntfObjects;

{$mode DELPHI}{$H+}
{$I EVSDEFS.inc}

interface

uses
  Classes, SysUtils, uEvsGenIntf;

type

// Back ported those two to solve a number of memory leaks with the TInterfaceperistent.
// It was different from my own implementation and it behaved as a contained
// interface instead of a stand alone one.
// In the future I'll have to rewrite the TEvsDBInfo base class to use the interfaced object
// in here instead of re implementing the iunknown interface. (post V 1 release).

  { TEvsInterfacedObject }

  TEvsInterfacedObject = class(TObject,IUnknown)
  protected
    FRefCount   :Integer;
    FRefCounted :Boolean;
    { implement methods of IUnknown }
    function QueryInterface(constref aIID : TGuid; out aObj) : longint;extdecl;
    function _AddRef : longint;extdecl;
    function _Release : longint;extdecl;
  public
    constructor Create(aRefCounted:Boolean);
    procedure   AfterConstruction;override;
    procedure   BeforeDestruction;override;
    class function NewInstance : TObject;override;

    property RefCount : longint read frefcount;
  end;

  { TEvsInterfacedPersistent }

  TEvsInterfacedPersistent = class(TPersistent, IEvsObjectRef) //TODO Extend the code to allow it to function as contained too
  protected
    FRefCount   :Integer;
    FRefCounted :Boolean;

    function QueryInterface(constref aIID : TGuid; out aObj) : LongInt; extdecl;
    function _AddRef : LongInt;                                         extdecl;
    function _Release : LongInt;                                        extdecl;
  public
    constructor    Create(const aRefCounted:Boolean = False);
    destructor     Destroy;               override;
    procedure      AfterConstruction;     override;
    procedure      BeforeDestruction;     override;
    class function NewInstance : TObject; override;

    Function ObjectRef :TObject; extdecl;
    property RefCount : LongInt read FRefCount;
  end;
  { TEvsObserverList }

  TEvsObserverListEnumerator = class;

  TEvsObserverList = class(TEvsInterfacedObject, IEvsObserverList)
  private
    FList: TThreadList;
  protected
    function Get(Index: Integer): IEvsObserver;                  extdecl;
    function GetCapacity: Integer;                               extdecl;
    function GetCount: Integer;                                  extdecl;
    procedure Put(Index: Integer; const Item: IEvsObserver);     extdecl;
    procedure SetCapacity(NewCapacity: Integer);                 extdecl;
    procedure SetCount(NewCount: Integer);                       extdecl;
  public
    constructor Create(aRefCounted :Boolean=False);
    destructor Destroy; override;
    procedure Clear;                                             extdecl;
    procedure Delete(Index: Integer);                            extdecl;
    procedure Exchange(Index1, Index2: Integer);                 extdecl;
    function Expand: TEvsObserverList;                           extdecl;
    function First: IEvsObserver;                                extdecl;
    function GetEnumerator: TEvsObserverListEnumerator;          extdecl;
    function IndexOf(const Item: IEvsObserver): Integer;         extdecl;
    function Add(const Item: IEvsObserver): Integer;             extdecl;
    procedure Insert(Index: Integer; const Item: IEvsObserver);  extdecl;
    function Last: IEvsObserver;                                 extdecl;
    function Remove(const Item: IEvsObserver): Integer;          extdecl;
    procedure Lock;                                              extdecl;
    procedure Unlock;                                            extdecl;
    Procedure Notify(aAction :TEvsGenAction; const aSubject :IEvsObjectRef; const aData:NativeUInt);extdecl;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
    property Items[Index: Integer]: IEvsObserver read Get write Put; default;
  end;
  TEvsObserverListEnumerator = class
  private
    FIndex: Integer;
    FObserverList: uEvsIntfObjects.TEvsObserverList;
  public
    constructor Create(AObserverList: TEvsObserverList);
    function GetCurrent: IEvsObserver;
    function MoveNext: Boolean;
    property Current: IEvsObserver read GetCurrent;
  end;



implementation

{$REGION ' TEvsInterfacedPersistent '}
function TEvsInterfacedPersistent.QueryInterface(constref aIID :TGuid; out aObj) :LongInt; extdecl;
begin
  if GetInterface(aIID, aObj) then Result := S_OK
  else Result := LongInt(E_NOINTERFACE);
end;

function TEvsInterfacedPersistent._AddRef :LongInt;extdecl;
begin
  if FRefCounted then begin
    Result := InterLockedIncrement(FRefCount);
  end else Result := -1;
end;

function TEvsInterfacedPersistent._Release :LongInt;extdecl;
begin
  if FRefCounted then begin
    Result :=interlockeddecrement(FRefCount);
    if Result <= 0 then Free;
  end;
end;

constructor TEvsInterfacedPersistent.Create(const aRefCounted :Boolean);
begin
  inherited Create;
  FRefCounted := aRefCounted;
end;

destructor TEvsInterfacedPersistent.Destroy;
begin
  inherited Destroy;
end;

procedure TEvsInterfacedPersistent.AfterConstruction;
begin
  InterLockedDecrement(FRefCount);
end;

procedure TEvsInterfacedPersistent.BeforeDestruction;
begin
  if FRefCounted  and (FRefCount>0) then
    raise Exception.Create('Premature destruction of reference counted object.') at get_caller_addr(get_frame);
end;

class function TEvsInterfacedPersistent.NewInstance : TObject;
begin
  Result := inherited NewInstance;
  if Result <> nil then TEvsInterfacedPersistent(Result).FRefCount:=1;
end;
Function TEvsInterfacedPersistent.ObjectRef :TObject; extdecl;
begin
  Result := Self;;
end;

{$ENDREGION}

{$REGION ' TEvsInterfacedObject '}
function TEvsInterfacedObject.QueryInterface(constref aIID :TGuid; out aObj) :longint;extdecl;
begin
  if GetInterface(aIID, aObj) then Result := S_OK
  else Result := LongInt(E_NOINTERFACE);
end;

function TEvsInterfacedObject._AddRef : longint;extdecl;
begin
  if FRefCounted then begin
    Result := InterLockedIncrement(FRefCount);
  end else Result := -1;
end;

function TEvsInterfacedObject._Release : longint;extdecl;
begin
  if FRefCounted then begin
    Result :=InterLockedDecrement(FRefCount);
    if Result <= 0 then Destroy;
  end;
end;

constructor TEvsInterfacedObject.Create(aRefCounted :Boolean);
begin
  inherited Create;
  FRefCounted := aRefCounted;
end;

procedure TEvsInterfacedObject.AfterConstruction;
begin
  InterLockedDecrement(FRefCount);
end;

procedure TEvsInterfacedObject.BeforeDestruction;
begin
  if FRefCounted  and (FRefCount>0) then
    raise Exception.Create('Premature destruction of reference counted object.') at get_caller_addr(get_frame);
end;

class function TEvsInterfacedObject.NewInstance : TObject;
begin
  Result := inherited NewInstance;
  if Result <> nil then TEvsInterfacedObject(Result).FRefCount := 1;
end;
{$ENDREGION}

{$REGION ' TEvsObserverList '}
constructor TEvsObserverList.Create(aRefCounted :Boolean);
begin
  inherited Create(aRefCounted);
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
      IEvsObserver(Tmp.List^[I]) := nil;
    Tmp.Clear;
  finally
    FList.UnlockList;
  end;
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

function TEvsObserverList.Get(Index: Integer): IEvsObserver; extdecl;
var
  Tmp : TList;
begin
  Tmp := FList.LockList;
  try
    if (Index < 0) or (Index >= Count) then
      Tmp.Error('List index <%D> out of bounds', Index);
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

function TEvsObserverList.GetEnumerator: TEvsObserverListEnumerator;extdecl;
begin
  Result := TEvsObserverListEnumerator.Create(Self);
end;

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
      Tmp.Error('List index <%D> out of bounds', Index);
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

Procedure TEvsObserverList.Notify(aAction :TEvsGenAction; const aSubject :IEvsObjectRef; const aData :NativeUInt); extdecl;
var
  vObserver :IEvsObserver;
begin
  for vObserver in Self do
    vObserver.Update(aSubject, aAction, aData);
end;

{$ENDREGION}

{$REGION ' TEvsObserverListEnumerator ' }
constructor TEvsObserverListEnumerator.Create(AObserverList: TEvsObserverList);
begin
  inherited Create;
  FIndex := -1;
  FObserverList := AObserverList;
end;

function TEvsObserverListEnumerator.GetCurrent: IEvsObserver;
begin
  Result := FObserverList[FIndex];
end;

function TEvsObserverListEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < FObserverList.Count - 1;
  if Result then
    Inc(FIndex);
end;
{$ENDREGION}


end.


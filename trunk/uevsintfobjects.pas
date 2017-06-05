unit uEvsIntfObjects;

{$mode DELPHI}{$H+}
{$I EVSDEFS.inc}

interface

uses
  Classes, SysUtils;

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

  TEvsInterfacedPersistent = class(TPersistent, IInterface) //TODO Extend the code to allow it to function as contained too
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

    property RefCount : LongInt read FRefCount;
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

end.


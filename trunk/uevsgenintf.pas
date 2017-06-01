unit uEvsGenIntf;

{$mode delphi}{$H+}
{$Include EvsDefs.inc}

interface

uses
  Classes, SysUtils;//, uTBTypes;

type
  TEvsGenAction =(gaUnknown, gaInsert, gaDelete, gaUpdate, gaDestroy, gaExtracting, gaDataChange);

  IEvsCopyPaste = Interface(IInterface)//
    ['{85BF366A-A410-4D16-8D8B-5298143CBABD}']
    function CanCopy  :LongBool; extdecl;
    function CanPaste :Longbool; extdecl;
    function Cut      :LongBool; extdecl;
    function Copy     :longbool; extdecl;
    function Paste    :LongBool; extdecl;

    // Move it to its own interface
    function CanUndo  :LongBool; extdecl;
    function CanRedo  :LongBool; extdecl;
    function Undo     :LongBool; extdecl;
    function Redo     :LongBool; extdecl;
  end;

  { IEvsTreeNode }
  IEvsTreeNode = interface(IInterface)
    ['{A900E764-EF8C-4052-A967-A8255C7575ED}']
    Function GetChildCount :integer;       extdecl;
    Function GetDisplayText :String;       extdecl;
    Function GetFirstChild :IEvsTreeNode;  extdecl;
    Function GetNextSibling :IEvsTreeNode; extdecl;

    Property DisplayText :String       read GetDisplayText;
    Property ChildCount  :Integer      read GetChildCount;
    Property FirstChild  :IEvsTreeNode read GetFirstChild;
    Property NextSibling :IEvsTreeNode read GetNextSibling;
  end;

  { IEvsCopyable }
  IEvsCopyable = interface(IInterface)
    ['{6E27BDDF-6A40-4E69-9252-8FF7CA0A4FE3}']
    function CopyFrom(const aSource  :IEvsCopyable) :Integer; extdecl;
    function CopyTo  (const aDest    :IEvsCopyable) :Integer; extdecl;
    function EqualsTo(const aCompare :IEvsCopyable) :Boolean; extdecl;
  end;

  IEvsObjectRef = interface(IEvsCopyable)
    ['{06704B77-F3A4-4CAA-9E8A-6E13AD70EA07}']
    Function ObjectRef:TObject;extdecl;
  end;

  { IEvsParented }
  IEvsParented = interface(IEvsObjectRef)
    ['{916AA6A8-EFE4-4360-AC14-35D9E15FAD28}']
    Function GetParent :IEvsParented;             extdecl;
    Procedure SetParent(aValue :IEvsParented);    extdecl;
    Procedure ClearState;                         extdecl;
    Property Parent :IEvsParented read GetParent write SetParent;
  end;

  //IObservable = interface;
  {This is the interface to be implemented for any object that needs to be notified
   about changes in any observable object.
  }
  IEvsObserver = interface(IEvsObjectRef)
    ['{CBB67A46-C5A2-4507-A39F-C8AFC44540A5}']
    // Gets notified for changes of an observable. It can observe only a single observable.
    procedure Update(aSubject:IEvsObjectRef; Action:TEVSGenAction);extdecl;
  end;

  {This is the interface that an observable object must have to be able to notify
   observers about changes in its data or metadata}
  IEvsObservable = interface(IEvsObjectRef)
    ['{D3A8D212-094E-4F17-BB3D-21D151CC8559}']
    procedure AddObserver(Observer:IEvsObserver);    extdecl;
    procedure DeleteObserver(Observer:IEvsObserver); extdecl;
    procedure ClearObservers;                        extdecl;
    procedure Notify(const Action: TEVSGenAction; const aSubject:IEvsObjectRef); extdecl;
  end;

  IEvsObserverList = interface(IInterface)
     ['{19E3A48C-E857-4EF3-A1DE-3726C5A23AB7}']
    function Get(Index: Integer): IEvsObserver; extdecl;
    function GetCapacity: Integer;              extdecl;
    function GetCount: Integer;                 extdecl;
    procedure Put(Index: Integer; const Item: IEvsObserver);   extdecl;
    procedure SetCapacity(NewCapacity: Integer);               extdecl;
    procedure SetCount(NewCount: Integer);                     extdecl;
    procedure Clear;                                           extdecl;
    procedure Delete(Index: Integer);                          extdecl;
    procedure Exchange(Index1, Index2: Integer);               extdecl;
    function First: IEvsObserver;                              extdecl;
    function IndexOf(const Item: IEvsObserver): Integer;       extdecl;
    function Add(const Item: IEvsObserver): Integer;           extdecl;
    procedure Insert(Index: Integer; const Item: IEvsObserver);extdecl;
    function Last: IEvsObserver;                               extdecl;
    function Remove(const Item: IEvsObserver): Integer;        extdecl;
    procedure Lock;                                            extdecl;
    procedure Unlock;                                          extdecl;

    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
    property Items[Index: Integer]: IEvsObserver read Get write Put; default;
  end;

  IEvsInterfaceList<T> = interface(IEvsCopyable) //OK
    Function  Get(aIndex : Integer) : T;          extdecl;
    Function  GetCapacity : Integer;              extdecl;
    Function  GetCount : Integer;                 extdecl;
    Procedure Put(aIndex : Integer;aItem : T);    extdecl;
    Procedure SetCapacity(NewCapacity : Integer); extdecl;
    Procedure SetCount(NewCount : Integer);       extdecl;
    Procedure Clear;                              extdecl;
    Procedure Delete(index : Integer);            extdecl;
    Procedure Exchange(index1,index2 : Integer);  extdecl;
    Function  New   :T;                           extdecl;
    Function  First :T;                           extdecl;
    Function  IndexOf(aItem : T) : Integer;       extdecl;
    Function  Add(aItem : T) : Integer;           extdecl;
    Procedure Insert(aIndex : Integer;aItem : T); extdecl;
    Function  Last :T;                            extdecl;
    Function  Remove(aItem : T): Integer;         extdecl;
    Procedure Lock;                               extdecl;
    Procedure Unlock;                             extdecl;

    Property Capacity :Integer read GetCapacity write SetCapacity;
    Property Count    :Integer read GetCount    write SetCount;
    Property Items[aIndex :Integer] :T read Get write Put; default;
  end;

implementation

end.


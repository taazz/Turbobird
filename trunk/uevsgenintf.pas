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
    Function CanCopy  :LongBool; extdecl;
    Function CanPaste :Longbool; extdecl;
    Function Cut      :LongBool; extdecl;
    Function Copy     :longbool; extdecl;
    Function Paste    :LongBool; extdecl;

    // Move it to its own interface
    Function CanUndo  :LongBool; extdecl;
    Function CanRedo  :LongBool; extdecl;
    Function Undo     :LongBool; extdecl;
    Function Redo     :LongBool; extdecl;
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

  IEvsObjectRef = interface(IInterface)
    ['{06704B77-F3A4-4CAA-9E8A-6E13AD70EA07}']
    Function ObjectRef:TObject;extdecl;
  end;
  { IEvsCopyable }
  IEvsCopyable = interface(IEvsObjectRef) // this is backwards copyable should inherit from objectref.
    ['{6E27BDDF-6A40-4E69-9252-8FF7CA0A4FE3}']
    Function CopyFrom(const aSource  :IEvsCopyable) :Integer; extdecl;
    Function CopyTo  (const aDest    :IEvsCopyable) :Integer; extdecl;
    Function EqualsTo(const aCompare :IEvsCopyable) :Boolean; extdecl;
  end;
  { IEvsParented }
  IEvsParented = interface(IEvsCopyable)
    ['{916AA6A8-EFE4-4360-AC14-35D9E15FAD28}']
    Function GetParent :IEvsParented;             extdecl;
    Procedure SetParent(aValue :IEvsParented);    extdecl;
    Property Parent :IEvsParented read GetParent write SetParent;
  end;

  {This is the interface to be implemented for any object that needs to be notified
   about changes in any observable object.  }

  IEvsObserver = interface(IEvsObjectRef)
    ['{CBB67A46-C5A2-4507-A39F-C8AFC44540A5}']
    // Gets notified for changes of an observable. It can observe only a single observable.
    Procedure Update(aSubject:IEvsObjectRef; Action:TEVSGenAction; const Data:NativeUInt);extdecl;
  end;

  {This is the interface that an observable object must have to be able to notify
   observers about changes in its data or metadata}
  IEvsObservable = interface(IEvsObjectRef)
    ['{D3A8D212-094E-4F17-BB3D-21D151CC8559}']
    Procedure AddObserver(Observer:IEvsObserver);    extdecl;
    Procedure DeleteObserver(Observer:IEvsObserver); extdecl;
    Procedure ClearObservers;                        extdecl;
    Procedure Notify(const Action: TEVSGenAction; const aSubject:IEvsObjectRef;const aData:NativeUInt); extdecl;
  end;

  { IEvsObserverList }

  IEvsObserverList = interface(IInterface)
    ['{19E3A48C-E857-4EF3-A1DE-3726C5A23AB7}']
    Function Get(Index: Integer): IEvsObserver; extdecl;
    Function GetCapacity: Integer;              extdecl;
    Function GetCount: Integer;                 extdecl;
    Procedure Put(Index: Integer; const Item: IEvsObserver);   extdecl;
    Procedure SetCapacity(NewCapacity: Integer);               extdecl;
    Procedure SetCount(NewCount: Integer);                     extdecl;
    Procedure Clear;                                           extdecl;
    Procedure Delete(Index: Integer);                          extdecl;
    Procedure Exchange(Index1, Index2: Integer);               extdecl;
    Function First: IEvsObserver;                              extdecl;
    Function IndexOf(const Item: IEvsObserver): Integer;       extdecl;
    Function Add(const Item: IEvsObserver): Integer;           extdecl;
    Procedure Insert(Index: Integer; const Item: IEvsObserver);extdecl;
    Function Last: IEvsObserver;                               extdecl;
    Function Remove(const Item: IEvsObserver): Integer;        extdecl;
    Procedure Lock;                                            extdecl;
    Procedure Unlock;                                          extdecl;

    Procedure Notify(aAction:TEvsGenAction; const aSubject:IEvsObjectRef; const aData:NativeUInt);extdecl;

    Property Capacity: Integer read GetCapacity write SetCapacity;
    Property Count: Integer read GetCount write SetCount;
    Property Items[Index: Integer]: IEvsObserver read Get write Put; default;

  end;

  //IEvsInterfaceList<T> = interface(IEvsCopyable) //OK
  //  Function  Get(aIndex : Integer) : T;          extdecl;
  //  Function  GetCapacity : Integer;              extdecl;
  //  Function  GetCount : Integer;                 extdecl;
  //  Procedure Put(aIndex : Integer;aItem : T);    extdecl;
  //  Procedure SetCapacity(NewCapacity : Integer); extdecl;
  //  Procedure SetCount(NewCount : Integer);       extdecl;
  //  Procedure Clear;                              extdecl;
  //  Procedure Delete(index : Integer);            extdecl;
  //  Procedure Exchange(index1,index2 : Integer);  extdecl;
  //  Function  New   :T;                           extdecl;
  //  Function  First :T;                           extdecl;
  //  Function  IndexOf(aItem : T) : Integer;       extdecl;
  //  Function  Add(aItem : T) : Integer;           extdecl;
  //  Procedure Insert(aIndex : Integer;aItem : T); extdecl;
  //  Function  Last :T;                            extdecl;
  //  Function  Remove(aItem : T): Integer;         extdecl;
  //  Procedure Lock;                               extdecl;
  //  Procedure Unlock;                             extdecl;
  //
  //  Property Capacity :Integer read GetCapacity write SetCapacity;
  //  Property Count    :Integer read GetCount    write SetCount;
  //  Property Items[aIndex :Integer] :T read Get write Put; default;
  //end;

implementation

end.


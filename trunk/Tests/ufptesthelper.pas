unit ufptestHelper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TestFramework, TestFrameworkIfaces;
type
  { TEvsTestCaseHelper }
  //ignore it please
  TEvsTestCaseHelper = class helper for TTestCase
    procedure Fail(const ErrorMsg: string; MessageParams : array of const;
                   const ErrorAddress: Pointer = nil);                                          overload;
    procedure FailEquals(const expected, actual: WideString;
                         const ErrorMsg: string = ''; MessageParams : array of const;
                         ErrorAddrs: Pointer = nil);                                            overload;
    procedure FailNotEquals(const expected, actual: WideString;
                            const ErrorMsg: string = ''; MessageParams : array of const;
                            ErrorAddrs: Pointer = nil);                                         overload;
    procedure FailNotSame(const expected, actual: WideString;
                          const ErrorMsg: string = ''; MessageParams : array of const;
                          ErrorAddrs: Pointer = nil);                                           overload;
    procedure EarlyExitCheck(const condition: boolean; const ErrorMsg: string = '';MessageParams : array of const);overload;
    procedure CheckFalse(const condition: boolean; const ErrorMsg: string = '';MessageParams : array of const);overload;
    procedure CheckNotEquals(const expected, actual: boolean;
                             const ErrorMsg: string = '';MessageParams : array of const); overload;
    procedure CheckEquals(const expected, actual: integer;
                          const ErrorMsg: string = '';MessageParams : array of const); overload;
    procedure CheckNotEquals(const expected, actual: integer;
                             const ErrorMsg: string = '';MessageParams : array of const); overload;
    procedure CheckEquals(const expected, actual: int64;
                          const ErrorMsg: string= '';MessageParams : array of const); overload;
    procedure CheckNotEquals(const expected, actual: int64;
                             const ErrorMsg: string= '';MessageParams : array of const); overload;
    procedure CheckNotEquals(const expected, actual: extended;
                             const ErrorMsg: string= '';MessageParams : array of const); overload;
    procedure CheckNotEquals(const expected, actual: extended;
                             const delta: extended;
                             const ErrorMsg: string= '';MessageParams : array of const); overload;
    procedure CheckEquals(const expected, actual: string;
                          const ErrorMsg: string= '';MessageParams : array of const); overload;
    procedure CheckNotEquals(const expected, actual: string;
                             const ErrorMsg: string = '';MessageParams : array of const); overload;
    procedure CheckEqualsString(const expected, actual: string;
                                const ErrorMsg: string = '';MessageParams : array of const);
    procedure CheckNotEqualsString(const expected, actual: string;
                                   const ErrorMsg: string;MessageParams : array of const);
  {$IFNDEF UNICODE}
    procedure CheckEquals(const expected, actual: WideString;
                          const ErrorMsg: string;MessageParams : array of const); overload;
    procedure CheckNotEquals(const expected, actual: WideString;
                             const ErrorMsg: string;MessageParams : array of const); overload;
    procedure CheckEqualsMem(const expected, actual: pointer;
                             const size:longword;
                             const ErrorMsg: string;MessageParams : array of const);overload;
    procedure CheckNotEqualsMem(const expected, actual: pointer;
                                const size:longword;
                                const ErrorMsg:string;MessageParams : array of const);overload;
  {$ENDIF}
    procedure CheckEqualsWideString(const expected, actual: WideString;
                                    const ErrorMsg: string;MessageParams : array of const);overload;
    procedure CheckNotEqualsWideString(const expected, actual: WideString;
                                       const ErrorMsg: string ;MessageParams : array of const);overload;
    procedure CheckEqualsBin(const expected, actual: longword;
                             const ErrorMsg: string;MessageParams : array of const;
                             const digits: Integer=32);overload;
    procedure CheckNotEqualsBin(const expected, actual: longword;
                                const ErrorMsg: string ;MessageParams : array of const;
                                const digits: Integer=32);overload;
    procedure CheckEqualsHex(const expected, actual: longword;
                             const ErrorMsg: string;MessageParams : array of const;
                             const digits: Integer=8);overload;
    procedure CheckNotEqualsHex(const expected, actual: longword;
                                const ErrorMsg: string ;MessageParams : array of const;
                                const digits: Integer=8);overload;
    procedure CheckNotNull(const obj :IInterface;
                           const ErrorMsg :string ;MessageParams : array of const); overload;
    procedure CheckNull(const obj: IInterface;
                        const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckNotNull(const obj: TObject;
                           const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckNull(const obj: TObject;
                        const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckNotSame(const expected, actual: IInterface;
                           const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckSame(const expected, actual: TObject;
                        const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckNotSame(const expected, actual: TObject;
                           const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckException(const AMethod: TExceptTestMethod;
                             const AExceptionClass: TClass;
                             const ErrorMsg :string ;MessageParams : array of const);overload;
    procedure CheckEquals(const expected, actual: TClass;
                          const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckNotEquals(const expected, actual: TClass;
                             const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckInherits(const expected, actual: TClass;
                            const ErrorMsg: string ;MessageParams : array of const);overload;
    procedure Check(const condition: boolean; const ErrorMsg: string;MessageParams : array of const); overload;
    procedure CheckEquals(const expected, actual: extended;
                          const ErrorMsg: string;MessageParams : array of const); overload;
    procedure CheckTrue(const condition: boolean; const ErrorMsg: string ;MessageParams : array of const);overload;
    procedure CheckEquals(const expected, actual: boolean;
                          const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckSame(const expected, actual: IInterface;
                        const ErrorMsg: string ;MessageParams : array of const); overload;
    procedure CheckIs(const AObject :TObject;
                      const AClass: TClass;
                      const ErrorMsg: string ;MessageParams : array of const);overload;
    procedure CheckEquals(const expected, actual: extended;
                          const delta: extended;
                          const ErrorMsg: string;MessageParams : array of const); overload;
  end;

implementation

{$Region ' TEvsTestHelper '}
{Is not working as expected test and grind before even considering adapting the idea}
procedure TEvsTestCaseHelper.Fail(const ErrorMsg :string; MessageParams :array of const; const ErrorAddress :Pointer);
begin
  inherited Fail(Format(ErrorMsg, MessageParams), ErrorAddress);
end;

procedure TEvsTestCaseHelper.FailEquals(const Expected, Actual :WideString; const ErrorMsg :string; MessageParams :array of const; ErrorAddrs :Pointer);
begin
  inherited FailEquals(Expected,Actual,Format(ErrorMsg, MessageParams),ErrorAddrs);
end;

procedure TEvsTestCaseHelper.FailNotEquals(const Expected, Actual :WideString; const ErrorMsg :string; MessageParams :array of const; ErrorAddrs :Pointer);
begin
 inherited FailNotEquals(Expected, Actual, Format(ErrorMsg, MessageParams), ErrorAddrs);
end;

procedure TEvsTestCaseHelper.FailNotSame(const expected, actual :WideString; const ErrorMsg :string; MessageParams :array of const; ErrorAddrs :Pointer);
begin
  inherited FailNotSame(Expected, Actual, Format(ErrorMsg,MessageParams), ErrorAddrs);
end;

procedure TEvsTestCaseHelper.EarlyExitCheck(const condition :boolean; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited EarlyExitCheck(condition,Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckFalse(const condition :boolean; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckFalse(Condition, Format(ErrorMsg,MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEquals(const expected, actual :boolean; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEquals(const expected, actual :integer; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEquals(const expected, actual :integer; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEquals(const expected, actual :int64; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEquals(const expected, actual :int64; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEquals(const expected, actual :extended; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEquals(const expected, actual :extended;
           const delta :extended; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEquals(Expected, Actual, delta, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEquals(const expected, actual :string;
           const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEquals(const expected, actual :string;
           const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEqualsString(const expected, actual :string;
           const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEqualsString(const expected, actual :string;
           const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEqualsString(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEquals(const expected, actual :WideString; const ErrorMsg :string;
           MessageParams :array of const);
begin
  inherited CheckEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEquals(const expected, actual :WideString;
           const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEqualsMem(const expected, actual :pointer; const size :longword;
           const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckEqualsMem(Expected, Actual, size, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEqualsMem(const expected, actual :pointer; const size :longword;
           const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEqualsMem(Expected, Actual, size, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEqualsWideString(const expected, actual :WideString;
           const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckEqualsWideString(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEqualsWideString(const expected, actual :WideString;
           const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotEqualsWideString(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEqualsBin(const expected, actual :longword;
           const ErrorMsg :string; MessageParams :array of const; const digits :Integer);
begin
  inherited CheckEqualsBin(Expected, Actual, Format(ErrorMsg, MessageParams), digits);
end;

procedure TEvsTestCaseHelper.CheckNotEqualsBin(const expected, actual :longword;
           const ErrorMsg :string; MessageParams :array of const; const digits :Integer);
begin
  inherited CheckNotEqualsBin(Expected, Actual, Format(ErrorMsg, MessageParams), digits);
end;

procedure TEvsTestCaseHelper.CheckEqualsHex(const expected, actual :longword;
           const ErrorMsg :string; MessageParams :array of const; const digits :Integer);
begin
  inherited CheckEqualsHex(Expected, Actual, Format(ErrorMsg, MessageParams), digits);
end;

procedure TEvsTestCaseHelper.CheckNotEqualsHex(const expected, actual :longword;
           const ErrorMsg :string; MessageParams :array of const; const digits :Integer);
begin
  inherited CheckNotEqualsHex(Expected, Actual, Format(ErrorMsg, MessageParams), digits);
end;

procedure TEvsTestCaseHelper.CheckNotNull(const obj :IInterface; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotNull(obj, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNull(const obj :IInterface; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNull(obj, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotNull(const obj :TObject; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNotNull(obj, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNull(const obj :TObject; const ErrorMsg :string; MessageParams :array of const);
begin
  inherited CheckNull(obj, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotSame(const expected, actual :IInterface; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckNotSame(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckSame(const expected, actual :TObject; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckSame(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotSame(const expected, actual :TObject; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckNotSame(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckException(const AMethod :TExceptTestMethod; const AExceptionClass :TClass; const ErrorMsg :string;
  MessageParams :array of const);
begin
 inherited CheckException(AMethod, AExceptionClass, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEquals(const expected, actual :TClass; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckNotEquals(const expected, actual :TClass; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckNotEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckInherits(const expected, actual :TClass; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckInherits(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.Check(const condition :boolean; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited Check(condition, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEquals(const expected, actual :extended; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckTrue(const condition :boolean; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckTrue(condition, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEquals(const expected, actual :boolean; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckEquals(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckSame(const expected, actual :IInterface; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckSame(Expected, Actual, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckIs(const AObject :TObject; const AClass :TClass; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckIs(AObject, AClass, Format(ErrorMsg, MessageParams));
end;

procedure TEvsTestCaseHelper.CheckEquals(const expected, actual :extended; const delta :extended; const ErrorMsg :string; MessageParams :array of const);
begin
 inherited CheckEquals(Expected, Actual, delta, Format(ErrorMsg, MessageParams));
end;

{$ENDREGION}

end.


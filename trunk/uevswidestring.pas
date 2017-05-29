unit uEvsWideString;

{$mode objfpc}{$H+}

interface
{ TODO -ojkoz -cMinor enhancements : uwidestrings is the jcl unit for widestings. Merge it in a single. }
uses
  Classes, SysUtils {$IFDEF MSWINDOWS}, windows{$ENDIF}, uWideStrings;

type
  TEvsWideStringList = class(uWideStrings.TWideStringList)
  end;

function WideCompareText(const S1, S2: WideString): Integer;
//firebird specific needs to be moved outside this unit.
procedure ParseCombDBName(const aCnn:WideString; var aHost, aPort, aDBName : WideString);{$MESSAGE WARN 'Needs Testing on linux and none intel targets'}

implementation

const
  CSTR_LESS_THAN    = 1;
  CSTR_EQUAL        = 2;
  CSTR_GREATER_THAN = 3;

function WideCompareText(const S1, S2: WideString): Integer;
{$IFDEF MSWINDOWS}
begin
  Result := CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PWideChar(S1),
    Length(S1), PWideChar(S2), Length(S2)); //- CSTR_EQUAL;
  if Result = 0 then
    RaiseLastOSError;
  Result := Result - CSTR_EQUAL;
end;
{$ELSE}
begin
  //use ICU on linux if present. on macos I need to provide the library as part of the application.
  Result := SysUtils.WideCompareText(s1, s2);
end;
{$ENDIF}

procedure ParseCombDBName(const aCnn:WideString; var aHost, aPort, aDBName : WideString);{$MESSAGE WARN 'Needs Testing on linux and none intel targets'}
var
  vPos    :Integer;
begin
  vPos := WidePos(':', aCnn);
  if (vPos > 2) then begin // in windows the drive letter is x:\
    SetLength(aDBName, Length(aCnn)-vPos);
    StrMoveW(@aDBName[1], @aCnn[vPos+1], Length(aCnn)-vPos);
    SetLength(aHost, vPos-1);
    StrMoveW(@aHost[1], @aCnn[1], vPos-1);
    vPos    := WidePos(WideChar('/'), aHost);
    if (vPos > 0) then begin
      SetLength(aPort, Length(aHost) - vPos);
      StrMoveW(@aPort[1], @aHost[vPos+1], Length(aHost)-vPos);
      SetLength(aHost, vPos-1);
    end else
      aPort := '3050';
  end else begin
    aHost   :='LocalHost';
    aPort   :='3050';
    aDBName :=aCnn;
  end;
end;

end.


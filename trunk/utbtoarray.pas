unit uTbToArray;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uTBTypes;
type
  TColItemArray = array of TCollectionItem;
Function ToArray(const aStrings:TStrings):TStringArray;
//function ToArray(const aCollection:TCollection):TColItemArray;
implementation

Function ToArray(const aStrings :TStrings) :TStringArray;
var
  vCntr :Integer;
begin
  SetLength(Result,0);
  if Assigned(aStrings) then begin
    SetLength(Result,aStrings.Count);
    for vCntr := 0 to aStrings.Count do begin
      Result[vCntr] := aStrings[vCntr];
    end;
  end;
end;

end.


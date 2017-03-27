unit uEvsOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, variants, {$IFDEF EVS_Containers} UEvsMisc, {$ENDIF} IniFiles, TypInfo;

type
  EEvsOptionsException = Exception;
  TEvsOptionAttribute = (opReadonly, opVisible, opPersistent);
                      {ReadOnly = locked in the editor if visible can't be changed by the end user}
                      {Visible = If set the editor will show the option on screen}
                      {Persistent if set the stream will save the option on disk}
  TEvsOptionAttributes = set of TEvsOptionAttribute;
const
  cDefaultAttributes = [opVisible, opPersistent];
type
  TEvsDataType = (dtUnknown, dtInt8,    dtUInt8,   dtInt16,       dtUInt16,  dtInt32,  dtUInt32,
                  dtInt64,   dtUInt64,  dtChar,    dtEnumeration, dtFloat,   dtSet,    dtMethod,
                  dtSString, dtAString, dtWString, dtUString,     dtVariant, dtArray,  dtRecord,
                  dtClass,   dtObject,  dtWChar,   dtInterface,   dtQWord,   dtBool,   dtDynArray,
                  dtUChar);
  // each option is used to create the proper editors in the treeview.
  // each category is a section in the ini.
  // the first section aka the root is not to be saved or have any options in it.
  //
  { TEvsOption }
  TEvsOption = class(TCollectionItem)
  private
    FDataType     : TTypeKind;
    FDefaultValue : variant;
    FName         : string;
    FStrictValues : Boolean;
    FTitle        : string;
    FValue        : Variant;
    FAttributes   : TEvsOptionAttributes;
    FValues       : Variant;
    function GetCategory : string;
    function GetDataType : TTypeKind;
    function GetPersist  : Boolean;
    function GetReadOnly : Boolean;
    function GetVisible  : Boolean;
    procedure SetDataType(aValue : TTypeKind);
    procedure SetDefaultValue (aValue : variant);
    procedure SetName         (aValue : string);
    procedure SetPersist      (aValue : Boolean);
    procedure SetReadOnly     (aValue : Boolean);
    procedure SetStrictValues (aValue : Boolean);
    procedure SetTitle        (aValue : string);
    procedure SetValue        (aValue : Variant);
    procedure SetValues       (aValue : Variant);
    procedure SetVisible      (aValue : Boolean);
  public
    constructor Create      (ACollection : TCollection); override;
    procedure SetAttributes (aAttrib     : TEvsOptionAttributes);
    procedure Assign        (Source      : TPersistent); override;
    property Values       : Variant read FValues write SetValues; //used on boolean types to show text other than true false.
    property StrictValues : Boolean read FStrictValues write SetStrictValues;
  published
    property Name         : string  read FName write SetName; //option name as shown in the options dialog.
    property Title        : string  read FTitle write SetTitle;
    property Value        : Variant read FValue write SetValue; //option's current value
    property DefaultValue : variant read FDefaultValue write SetDefaultValue;
    property Category     : string  read GetCategory;
    property DataType     : TTypeKind read GetDataType write SetDataType;
    // Editing properties
    property Visible      : Boolean read GetVisible  write SetVisible; //if true it is visible in the options editor
    property ReadOnly     : Boolean read GetReadOnly write SetReadOnly; //if true it is locked in the editor
    property Persistent   : Boolean read GetPersist  write SetPersist; // if True it can be saved otherwise is never saved.
  end;

  { TEvsOptionCategory }
  TEvsOptionCategory = class(TOwnedCollection)
  private
    FName : String;
    FTitle : string;
    function GetOption  (aIndex : Integer) : TEvsOption;
    procedure SetName   (aValue : String);
    procedure SetOption (aIndex : Integer; aValue : TEvsOption);
    procedure SetTitle  (aValue : string);
  public
    constructor Create  (aOwner : TPersistent);
    function IndexOf    (aOptionName:String):Integer;
    function Add        (aName, aTitle:string; aValue, aDefault:Variant):TEvsOption;overload;
    function Add        (aName, aTitle:string; aDataType:TTypeKind; aValue, aDefault:Variant):TEvsOption;overload;
    function VisibleCount:integer;
    property Items[Index: Integer]: TEvsOption read GetOption write SetOption;
  published
    property Name  : string read FName write SetName;
    property Title : string read FTitle write SetTitle;
  end;

  { TEvsOptions }
  TEvsOptions = class(TComponent)
  private
    FFilename : string;
    FOptions  : TList;
    function GetCategory(Index : integer) : TEvsOptionCategory;
    function GetOption(Index : Integer) : TEvsOption;
    procedure SetCategory(Index : integer; aValue : TEvsOptionCategory);
    procedure SetFilename(aValue : string);
  protected
    procedure DoClear;
  public
    constructor Create(aOwner:TComponent);override;
    destructor Destroy;override;
    procedure Assign(Source : TPersistent); override;
    function OptionCount : Integer;
    function CategoryCount : Integer;
    function CategoryOptionCount(const aCategory:string) : integer;
    function NewCategory(const aName, aTitle:string):TEvsOptionCategory;
    function IndexOfCategory(aCategoryName:string):integer;overload;
    function IndexOfCategory(aCategory:TEvsOptionCategory):Integer;overload;
    function IndexOfOption(aName:string):Integer;
    function FindOption(aName:String):TEvsOption;
    function NewOption(aName, aTitle:string; aValue, aDefault:Variant; aCategory:string=''; aCategoryTitle:string =''):TEvsOption;
    procedure Clear;
    procedure DeleteCategory(aIndex:integer);overload;
    procedure DeleteCategory(aName:String);overload;
    function Get(aOptionName:string):Variant;
    procedure &Set(aOptionName:string);
    class procedure Error(const Msg: string; Data: PtrUInt);

    property Filename : string read FFilename write SetFilename; //use it to autosave on destroy
    property Option[Index:Integer]:TEvsOption read GetOption;
    property Category[Index:integer]:TEvsOptionCategory read GetCategory;// write SetCategory;
  end;

  TOptionInitProc = procedure (aOptions:TEvsOptions);

Procedure OptionsSaveToIni(aFile :TIniFile; aOptions:TEvsOptions);

procedure RegisterInitProc(aProc : TOptionInitProc);
procedure UnregisterInitProc(aProc : TOptionInitProc);

procedure Initialize(const aOptions:TEvsOptions);

resourcestring
  rsIndexError       = '%S index %D out of bounds';
  rsCategoryNotFound = 'Category not found';
  rsOptionNotFound   = 'Option <%S> not found';

const
  cCategoryGeneral  = 'General';

implementation

var
  gList : TList = Nil;
{$IFNDEF EVS_Containers}
function VarToTypeKind(const aValue : variant) : TTypeKind;
begin
  case VarType(aValue) and varTypeMask of
    varempty      : Result := tkUnknown;
    varnull       : Result := tkUnknown;
    varsmallint   : Result := tkInteger;
    varinteger    : Result := tkInteger;
    varsingle     : Result := tkFloat;
    vardouble     : Result := tkFloat;
    vardate       : Result := tkFloat;
    varcurrency   : Result := tkFloat;
    varolestr     : Result := tkWString;
    vardispatch   : Result := tkInterface;
    varerror      : Result := tkUnknown;
    varboolean    : Result := tkBool;
    varvariant    : Result := tkVariant;
    varunknown    : Result := tkUnknown;
    vardecimal    : Result := tkFloat;
    varshortint   : Result := tkInteger;
    varbyte       : Result := tkInteger;
    varword       : Result := tkInteger;
    varlongword   : Result := tkInteger;
    varint64      : Result := tkInt64;
    varqword      : Result := tkQWord;
    varrecord     : Result := tkRecord;
  end;
end;
{$ENDIF}

Procedure OptionsSaveToIni(aFile : TIniFile; aOptions : TEvsOptions);
var
  vCntr : Integer;
  vOpt  : TEvsOption;
begin
  for vCntr := 0 to aOptions.OptionCount -1 do begin
    vOpt := aOptions.Option[vCntr];
    if not vOpt.Persistent then Continue;
    if VarIsType(vOpt.Value, [varsmallint, varinteger ,varshortint, varbyte,
                           varword, varlongword, varint64, varqword,varword64,varuint64]) then begin
      aFile.WriteInteger(vOpt.Category, vOpt.Name, vOpt.Value);
    end else if VarIsType(vOpt.Value, [varsingle, vardouble, vardecimal, varcurrency]) then begin
      aFile.WriteFloat(vOpt.Category, vOpt.Name, vOpt.Value);
    end else if VarIsType(vOpt.Value, [varolestr, varstring, varustring]) then begin
      aFile.WriteString(vOpt.Category, vOpt.Name, vOpt.Value);
    end else if VarIsType(vOpt.Value, [vardate]) then begin
      aFile.WriteDate(vOpt.Category, vOpt.Name, vOpt.Value);
    end else if VarIsType(vOpt.Value, [varboolean]) then begin
      aFile.WriteBool(vOpt.Category, vOpt.Name, vOpt.Value);
    //else if VarIsType(aValue, [varvariant]) then ?????? LoadIniValue();
    end else raise Exception.Create('Unsupported DataType');
      // aValue := VarAsType(aDefault,varerror);// unsupported datatype.
  end;
end;

procedure RegisterInitProc(aProc : TOptionInitProc);
begin
  if not Assigned(gList) then gList := TList.Create;
  gList.Add(aProc);
end;

procedure UnregisterInitProc(aProc : TOptionInitProc);
var
  vCntr : Integer;
begin
  if Assigned(gList) then begin
    for vCntr := 0 to gList.Count -1 do begin
      if gList.Items[vCntr] = @aProc then begin
        gList.Delete(vCntr);
        Exit;
      end;
    end;
  end;
end;

procedure Initialize(const aOptions:TEvsOptions);
var
  vCntr : Integer;
begin
  if Assigned(gList) then begin
    for vCntr := 0 to gList.Count -1 do
      TOptionInitProc(gList.Items[vCntr])(aOptions);
  end;
end;

{ TEvsOptionCategory }

procedure TEvsOptionCategory.SetName(aValue : String);
begin
  if FName = aValue then Exit;
  FName := aValue;
end;

function TEvsOptionCategory.GetOption(aIndex : Integer) : TEvsOption;
begin
  Result := TEvsOption(GetItem(aIndex));
end;

procedure TEvsOptionCategory.SetOption(aIndex : Integer; aValue : TEvsOption);
begin
  SetItem(aIndex, aValue);
end;

procedure TEvsOptionCategory.SetTitle(aValue : string);
begin
  if FTitle = aValue then Exit;
  FTitle := aValue;
end;

constructor TEvsOptionCategory.Create(aOwner : TPersistent);
begin
  inherited Create(aOwner, TEvsOption);
end;

function TEvsOptionCategory.IndexOf(aOptionName : String) : Integer;
var
  vCntr : Integer;
begin
  Result := -1;
  for vCntr := 0 to Count -1 do begin
    if CompareText(TevsOption(Items[vCntr]).Name, aOptionName) = 0 then begin
      Result := vCntr;
      Exit;
    end;
  end;
end;

function TEvsOptionCategory.Add(aName, aTitle : string; aValue,
  aDefault : Variant) : TEvsOption;
begin
  Result := TevsOption(inherited Add);
  Result.Name := aName; Result.Value := aValue; Result.Title := aTitle; Result.DefaultValue := aDefault;
end;

function TEvsOptionCategory.Add(aName, aTitle : string; aDataType : TTypeKind;
  aValue, aDefault : Variant) : TEvsOption;
begin
  Result := Add(aName, aTitle, aValue, aDefault);
  Result.DataType := aDataType;
end;

function TEvsOptionCategory.VisibleCount : integer;
var
  vCntr : Integer;
begin
  Result := 0;
  for vCntr := 0 to Count -1 do
    if Items[vCntr].Visible then Inc(Result);
end;

{ TEvsOptions }

procedure TEvsOptions.SetFilename(aValue : string);
begin
  if FFilename = aValue then Exit;
  FFilename := aValue;
  {TODO Load from the file}
end;

procedure TEvsOptions.DoClear;
var
  vCntr :Integer;
begin
  for vCntr := FOptions.Count -1 downto 0 do begin
    TEvsOptionCategory(FOptions[vCntr]).Free;
    FOptions[vCntr] := Nil;
  end;
  FOptions.Free;
end;

function TEvsOptions.GetCategory(Index : integer) : TEvsOptionCategory;
begin
  result := TEvsOptionCategory(FOptions[Index]);
end;

function TEvsOptions.GetOption(Index : Integer) : TEvsOption;
var
  vOptIndex   : Integer =0;
  vAcumulator : Integer =0;
  vCntr       : Integer;
begin
  Result := nil;
  for vCntr := 0 to FOptions.Count -1 do begin
    if (vAcumulator + Category[vCntr].Count) > Index then begin
      vOptIndex :=  Index - vAcumulator;
      Result := TEvsOption(Category[vCntr].Items[vOptIndex]);
      Exit;
    end;
    vAcumulator := vAcumulator + Category[vCntr].Count;
  end;
end;

procedure TEvsOptions.SetCategory(Index : integer; aValue : TEvsOptionCategory);
begin
  TEvsOptionCategory(FOptions[Index]).Assign(aValue);
end;

constructor TEvsOptions.Create(aOwner :TComponent);
begin
  inherited Create(aOWner);
  FOptions  := TList.Create;
  NewCategory(cCategoryGeneral, cCategoryGeneral);
end;

destructor TEvsOptions.Destroy;
begin
  DoClear;
  inherited Destroy;
end;

procedure TEvsOptions.Assign(Source : TPersistent);
var
  vCntr : Integer;
  vCat  : TEvsOptionCategory;
begin
  if Source is TEvsOptions then begin
    Clear;
    for vCntr := 0 to TEvsOptions(Source).CategoryCount -1 do begin
      vCat := TEvsOptionCategory.Create(Self);
      vCat.Assign(TEvsOptions(Source).Category[vCntr]);
      FOptions.Add(vCat);
    end;
  end else inherited Assign(Source);
end;

function TEvsOptions.OptionCount : Integer;
var
  vCntr : Integer;
begin
  Result := 0;
  for vCntr := 0 to FOptions.Count -1 do
    Result := Result + TEvsOptionCategory(FOptions.Items[vCntr]).Count;
end;

function TEvsOptions.CategoryCount : Integer;
begin
  Result := FOptions.Count;
end;

function TEvsOptions.CategoryOptionCount(const aCategory : string) : integer;
var
  vIndex : Integer;
begin
  Result := IndexOfCategory(aCategory);
  if Result < 0 then Error(rsCategoryNotFound, 0);
end;

function TEvsOptions.NewCategory(const aName, aTitle : string
  ) : TEvsOptionCategory;
begin
  Result := TEvsOptionCategory.Create(Self);
  FOptions.Add(Result);
  Result.Name := aName;
  Result.Title := aTitle;
end;

function TEvsOptions.IndexOfCategory(aCategoryName : string) : integer;
var
  vCntr : Integer;
begin
  Result := -1;
  for vCntr := 0 to FOptions.Count-1 do
    if CompareText(aCategoryName, Category[vCntr].Name) = 0 then begin
      Result := vCntr;
      Exit;
    end;
end;

function TEvsOptions.IndexOfCategory(aCategory : TEvsOptionCategory) : Integer;
begin
  Result := FOptions.IndexOf(aCategory);
end;

function TEvsOptions.IndexOfOption(aName : string) : Integer;
var
  vAcumulator : Integer = 0;
  vOptIndex   : Integer = -1;
  vCntr       : Integer;
begin
  Result := -1;
  for vCntr := 0 to FOptions.Count do begin
    vOptIndex := Category[vCntr].IndexOf(aName);
    if vOptIndex < 0 then Inc(vAcumulator, Category[vCntr].Count)
    else begin
      Result := vAcumulator + vOptIndex;
    end;
  end;
end;

function TEvsOptions.FindOption(aName : String) : TEvsOption;
var
  vOptIndex   : Integer = -1;
  vCntr       : Integer;
begin
  Result := nil;
  for vCntr := 0 to FOptions.Count do begin
    vOptIndex := Category[vCntr].IndexOf(aName);
    if vOptIndex > -1 then begin
      Result := TEvsOption(Category[vCntr].Items[vOptIndex]);
      Exit;
    end;
  end;
end;

function TEvsOptions.NewOption(aName, aTitle : string; aValue,
  aDefault : Variant; aCategory : string; aCategoryTitle : string) : TEvsOption;
var
  vCatIndex : Integer;
begin
  if aCategory <> '' then vCatIndex := IndexOfCategory(aCategory) else vCatIndex := 0;
  if vCatIndex < 0 then
    Result := NewCategory(aCategory, aCategoryTitle).Add(aName, aTitle, aValue, aDefault)
  else
    Result := Category[vCatIndex].Add(aName, aTitle, aValue, aDefault);
end;

procedure TEvsOptions.Clear;
var
  vCntr : Integer;
begin
  for vCntr := 0 to CategoryCount -1 do begin
    Category[vCntr].Free;
    FOptions[vCntr] := Nil;
  end;
  FOptions.Clear;
end;

procedure TEvsOptions.DeleteCategory(aIndex : integer);
var
  vTmp : TEvsOptionCategory;
begin
  vTmp:= Category[aIndex];
  FOptions.Delete(aIndex);
  vTmp.Free;
end;

procedure TEvsOptions.DeleteCategory(aName : String);
var
  vIndex : Integer;
begin
  vIndex := IndexOfCategory(aName);
  if vIndex < 0 then Error(rsCategoryNotFound,0);
  DeleteCategory(vIndex);
end;

function TEvsOptions.Get(aOptionName : string) : Variant;
var
  vOpt : TEvsOption;
begin
  Result := Null;
  vOpt := FindOption(aOptionName);
  if Assigned(vOpt) then Result := vOpt.Value
  else Error(Format(rsOptionNotFound, [aOptionName]), 0);
end;

procedure TEvsOptions.&Set(aOptionName : string);
var
  vIndex : Integer;
begin
  vIndex := IndexOfOption(aOptionName);
  if vIndex < 0 then Error(Format(rsOptionNotFound, [aOptionName]), 0);
end;

class procedure TEvsOptions.Error(const Msg : string; Data : PtrUInt);
begin
  Raise EEvsOptionsException.Create(Msg) at get_caller_addr(get_frame);
end;

procedure TEvsOption.SetName(aValue : string);
begin
  if FName = aValue then Exit;
  FName := aValue;
end;

procedure TEvsOption.SetPersist(aValue : Boolean);
begin
  if aValue then Include(FAttributes, opPersistent)
  else Exclude(FAttributes, opPersistent);
end;

procedure TEvsOption.SetReadOnly(aValue : Boolean);
begin
  if aValue then Include(FAttributes, opReadonly)
  else Exclude(FAttributes, opReadonly);
end;

procedure TEvsOption.SetStrictValues(aValue : Boolean);
begin
  if FStrictValues = aValue then Exit;
  FStrictValues := aValue;
end;

procedure TEvsOption.SetTitle(aValue : string);
begin
  if FTitle = aValue then Exit;
  FTitle := aValue;
end;

function TEvsOption.GetCategory : string;
begin
  Result := '';
  if Assigned(Collection) and (Collection is TEvsOptionCategory) then
    Result := TEvsOptionCategory(Collection).Name;
end;

function TEvsOption.GetDataType : TTypeKind;
begin
  Result := FDataType;
  if Result = tkUnknown then Result := VarToTypeKind(FValue);
end;

function TEvsOption.GetPersist : Boolean;
begin
  Result := opPersistent in FAttributes;
end;

function TEvsOption.GetReadOnly : Boolean;
begin
  Result := opReadonly in FAttributes;
end;

function TEvsOption.GetVisible : Boolean;
begin
  Result := opVisible in FAttributes;
end;

procedure TEvsOption.SetDataType(aValue : TTypeKind);
begin
  if FDataType = aValue then Exit;
  FDataType := aValue;
end;

procedure TEvsOption.SetDefaultValue(aValue : variant);
begin
  if FDefaultValue = aValue then Exit;
  FDefaultValue := aValue;
end;

procedure TEvsOption.SetValue(aValue : Variant);
begin
  if FValue = aValue then Exit;
  FValue := aValue;
end;

procedure TEvsOption.SetValues(aValue : Variant);
begin
  if FValues = aValue then Exit;
  FValues := aValue;
end;

procedure TEvsOption.SetVisible(aValue : Boolean);
begin
  if aValue then Include(FAttributes, opVisible)
  else Exclude(FAttributes, opVisible);
end;

constructor TEvsOption.Create(ACollection : TCollection);
begin
  inherited Create(ACollection);
  FAttributes   := cDefaultAttributes;
  FValues       := Null;
  FStrictValues := False;
  FDataType     := tkUnknown;
end;

procedure TEvsOption.SetAttributes(aAttrib : TEvsOptionAttributes);
begin
  FAttributes := aAttrib;
end;

procedure TEvsOption.Assign(Source : TPersistent);
begin
  if Source is TEvsOption then begin
    FDefaultValue := TevsOption(Source).FDefaultValue;
    FName         := TevsOption(Source).FName;
    FStrictValues := TevsOption(Source).FStrictValues;
    FTitle        := TevsOption(Source).FTitle;
    FValue        := TevsOption(Source).FValue;
    FAttributes   := TevsOption(Source).FAttributes;
    FValues       := TevsOption(Source).FValues;
  end else inherited Assign(Source);
end;

finalization
  if Assigned(gList) then gList.Free;
end.


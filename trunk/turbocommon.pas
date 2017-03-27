unit turbocommon;

{ Non-GUI common code for TurboBird that do not depend on a database connection.
SysTables covers functionality for which a db connection is required. }
{$mode objfpc}{$H+}

interface
{.$DEFINE EVS_Internal}
{$DEFINE EVS_NEW}
uses
  Classes, SysUtils, variants, sqldb, uTBTypes {$IFDEF EVS_Internal}, uEvsLinkedLists{$ELSE},contnrs{$ENDIF}, syncobjs,
  Forms, Controls, StdCtrls, MDODatabase, MDOQuery, IBConnection;

// Common definitions for TurboBird
const //consts from turbocommon.inc copied here to avoid duplications.
  {$IFDEF LINUX}
  Target = 'Linux';
  IsWindows : Boolean = False;
  IsLinux   : Boolean = True;
  IsMac     : Boolean = False;
  IsBSD     : Boolean = False;
  {$ENDIF}

  {$IFDEF WINDOWS}
  Target = 'Win';
  IsWindows : Boolean = True;
  IsLinux   : Boolean = False;
  IsMac     : Boolean = False;
  IsBSD     : Boolean = False;
  {$ENDIF}

  {$IFDEF BSD}
  {$IFDEF DARWIN}
  Target = 'Mac'; //Mac OSX
  IsWindows : Boolean = False;
  IsLinux   : Boolean = False;
  IsMac     : Boolean = True;
  IsBSD     : Boolean = False;
  {$ELSE}
  Target = 'BSD'; //FreeBSD, OpenBSD, NetBSD,...
  IsWindows : Boolean = False;
  IsLinux   : Boolean = False;
  IsMac     : Boolean = False;
  IsBSD     : Boolean = True;
  {$ENDIF}
  {$ENDIF}

  {$ifDEF CPU32}
  Arch = '32';
  Is32Bit = True;
  Is64Bit = False;
  {$ENDIF}

  {$ifDEF CPU64}
  Arch = '64';
  Is64Bit = True;
  Is32Bit = False;
  {$ENDIF}

const
  // Some field types used in e.g. RDB$FIELDS
  // todo: (low priority) perhaps move to enumeration with fixed constant values
  BlobType    = 261;
  CharType    = 14;
  CStringType = 40; // probably null-terminated string used for UDFs
  VarCharType = 37;

  // Available character set encodings for Firebird.
  // Update this whenever Firebird supports new character sets
  DefaultFBCharacterSet = 42; //Used for GUI controls etc. UTF8 in CharacterSets below.
  // Available character sets as per Firebird 2.5
   ///Hate, hate, hate tall pieces of code.
  FBCharacterSets: array[0..51] of string = //Make an external to avoid recompilation, or an addin.
    ('NONE',      'ASCII',    'BIG_5',     'CP943C',    'CYRL',      'DOS437',   'DOS737',    'DOS775',    'DOS850',
     'DOS852',    'DOS857',   'DOS858',    'DOS860',    'DOS861',    'DOS862',   'DOS863',    'DOS864',    'DOS865',
     'DOS866',    'DOS869',   'EUCJ_0208', 'GB18030',   'GBK',       'GB_2312',  'ISO8859_1', 'ISO8859_13','ISO8859_2',
     'ISO8859_3', 'ISO8859_4','ISO8859_5', 'ISO8859_6', 'ISO8859_7', 'ISO8859_8','ISO8859_9', 'KOI8R',     'KOI8U',
     'KSC_5601',  'NEXT',     'OCTETS',    'SJIS_0208', 'TIS620',
     'UNICODE_FSS', {//obsolete}
     'UTF8',        {//good default}
     'WIN1250',   'WIN1251',  'WIN1252',  'WIN1253',   'WIN1254',   'WIN1255',  'WIN1256',   'WIN1257',   'WIN1258');
  // Available collations as per Firebird 2.5
  // Pairs of collation names and the character set name
  // that must be used to support this collation
  FBReservedWords : array[0..166] of string = ( //JKOZ: make it an external source and dynamically chaneged (no need for recompilation).
                                           'ADD',                'ADMIN',  'ALL',      'ALTER',     'AND',        'ANY',      'AS',      'AT',
                                           'BETWEEN',            'BIGINT', 'BLOB',     'BOTH',      'BY',         'CASE',     'CAST',    'CHAR',
                                           'CHARACTER',          'CHECK',  'CLOSE',    'COLLATE',   'COLUMN',     'COMMIT',   'CONNECT', 'AVG',
                                           'BIT_LENGTH',         'CURSOR', 'DATE',     'DAY',       'DEC',        'DECIMAL',  'DECLARE', 'DEFAULT',
                                           'CHARACTER_LENGTH',   'THEN',   'TIME',     'TO',        'TRIGGER',    'TRIM',     'UNION',   'UNIQUE',
                                           'MAXIMUM_SEGMENT',    'UPDATE', 'UPPER',    'USER',      'USING',      'VALUE',    'VALUES',  'VARCHAR',
                                           'CONSTRAINT',         'COUNT',  'CREATE',   'CROSS',     'CURRENT',    'DISTINCT', 'ELSE',    'END',
                                           'CURRENT_CONNECTION', 'DOUBLE', 'DROP',     'EXECUTE',   'EXISTS',     'EXTERNAL', 'NO',      'LIKE',
                                           'CURRENT_DATE',       'EXTRACT','FETCH',    'FILTER',    'FLOAT',      'FOR',      'FOREIGN', 'FROM',
                                           'CURRENT_ROLE',       'GDSCODE','GRANT',    'FUNCTION',  'HOUR',       'IN',       'INDEX',   'INNER',
                                           'CURRENT_TIME',       'GLOBAL', 'GROUP',    'HAVING',    'LONG',       'LOWER',    'MAX',     'INSERT',
                                           'CURRENT_USER',       'INT',    'INTO',     'INTEGER',   'IS',         'JOIN',     'LEADING', 'LEFT',
                                           'CURRENT_TIMESTAMP',  'MERGE',  'MIN',      'MINUTE',    'MONTH',      'NATIONAL', 'NATURAL', 'NCHAR',
                                           'CURRENT_TRANSACTION','NOT',    'NULL',     'NUMERIC',   'OF',         'ON',       'ONLY',    'OPEN',
                                           'OCTET_LENGTH',       'ORDER',  'OUTER',    'POSITION',  'PLAN',       'PRECISION','PRIMARY', 'PROCEDURE',
                                           'RDB$DB_KEY',         'REAL',   'RECREATE', 'RECURSIVE', 'REFERENCES', 'RELEASE',  'OR',      'INSENSITIVE',
                                           'PARAMETER',          'RETURNS','REVOKE',   'RIGHT',     'ROLLBACK',   'ROW_COUNT','ROWS',    'SAVEPOINT',
                                           'POST_EVENT',         'SECOND', 'SELECT',   'SENSITIVE', 'SET',        'SIMILAR',  'SMALLINT','SOME',
                                           'RECORD_VERSION',     'SQLCODE','START',    'SUM',       'TABLE',      'TIMESTAMP','WITH',    'YEAR',
                                           'SQLSTATE (2.5.1)',   'VIEW',   'TRAILING', 'VARYING',   'WHEN',       'WHILE',    'WHERE',   'CHAR_LENGTH',
                                           'RETURNING_VALUES',   'BEGIN',  'DELETE',   'VARIABLE',  'ESCAPE',     'FULL',     'DISCONNECT'
                                           );
  FBCollations: array[0..147, 0..1] of string = (
    ('ASCII',      'ASCII'),    ('BIG_5',       'BIG_5'),    ('BS_BA',      'WIN1250'),    ('CP943C',   'CP943C'),          ('CP943C_UNICODE','CP943C'),     ('CS_CZ',    'ISO8859_2'),
    ('CYRL',       'CYRL'),     ('DA_DA',       'ISO8859_1'),('DB_CSY',     'DOS852'),     ('DB_DAN865','DOS865'),          ('DB_DEU437',     'DOS437'),     ('DB_DEU850','DOS850'),
    ('DB_ESP437',  'DOS437'),   ('DB_ESP850',   'DOS850'),   ('DB_FIN437',  'DOS437'),     ('DB_FRA437','DOS437'),          ('DB_FRA850',     'DOS850'),     ('DB_FRC850','DOS850'),
    ('DB_FRC863',  'DOS863'),   ('DB_ITA437',   'DOS437'),   ('DB_ITA850',  'DOS850'),     ('DB_NLD437','DOS437'),          ('DB_NLD850',     'DOS850'),     ('DB_NOR865','DOS865'),
    ('DB_PLK',     'DOS852'),   ('DB_PTB850',   'DOS850'),   ('DB_PTG860',  'DOS860'),     ('DB_RUS',   'CYRL'),            ('DB_SLO',        'DOS852'),     ('DB_SVE437','DOS437'),
    ('DB_SVE850',  'DOS850'),   ('DB_TRK',      'DOS857'),   ('DB_UK437',   'DOS437'),     ('DB_UK850', 'DOS850'),          ('DB_US437',      'DOS437'),     ('DB_US850', 'DOS850'),
    ('DE_DE',      'ISO8859_1'),('DOS437',      'DOS437'),   ('DOS737',     'DOS737'),     ('DOS775',   'DOS775'),          ('DOS850',        'DOS850'),     ('DOS852',   'DOS852'),
    ('DOS857',     'DOS857'),   ('DOS858',      'DOS858'),   ('DOS860',     'DOS860'),     ('DOS861',   'DOS861'),          ('DOS862',        'DOS862'),     ('DOS863',   'DOS863'),
    ('DOS864',     'DOS864'),   ('DOS865',      'DOS865'),   ('DOS866',     'DOS866'),     ('DOS869',   'DOS869'),          ('DU_NL',         'ISO8859_1'),  ('EN_UK',    'ISO8859_1'),
    ('EN_US',      'ISO8859_1'),('ES_ES',       'ISO8859_1'),('ES_ES_CI_AI','ISO8859_1'),  ('EUCJ_0208','EUCJ_0208'),       ('FI_FI',         'ISO8859_1'),  ('FR_CA',    'ISO8859_1'),
    ('FR_FR',      'ISO8859_1'),('FR_FR_CI_AI', 'ISO8859_1'),('GB18030',    'GB18030'),    ('GB18030_UNICODE','GB18030'),   ('GBK',           'GBK'),        ('GBK_UNICODE','GBK'),
    ('GB_2312',    'GB_2312'),  ('ISO8859_1',   'ISO8859_1'),('ISO8859_13', 'ISO8859_13'), ('ISO8859_2',      'ISO8859_2'), ('ISO8859_3',     'ISO8859_3'),  ('ISO8859_4',  'ISO8859_4'),
    ('ISO8859_5',  'ISO8859_5'),('ISO8859_6',   'ISO8859_6'),('ISO8859_7',  'ISO8859_7'),  ('ISO8859_8',      'ISO8859_8'), ('ISO8859_9',     'ISO8859_9'),  ('ISO_HUN',    'ISO8859_2'),
    ('ISO_PLK',    'ISO8859_2'),('IS_IS',       'ISO8859_1'),('IT_IT',      'ISO8859_1'),  ('KOI8R',          'KOI8R'),     ('KOI8R_RU',      'KOI8R'),      ('KOI8U',      'KOI8U'),
    ('KOI8U_UA',   'KOI8U'),    ('KSC_5601',    'KSC_5601'), ('KSC_DICTIONARY','KSC_5601'),('LT_LT',          'ISO8859_13'),('NEXT',          'NEXT'),       ('NONE',       'NONE'),
    ('NO_NO',      'ISO8859_1'),('NXT_DEU',     'NEXT'),     ('NXT_ESP',     'NEXT'),      ('NXT_FRA',        'NEXT'),      ('NXT_ITA',       'NEXT'),       ('NXT_US',     'NEXT'),
    ('OCTETS',     'OCTETS'),   ('PDOX_ASCII',  'DOS437'),   ('PDOX_CSY',    'DOS852'),    ('PDOX_CYRL',      'CYRL'),      ('PDOX_HUN',      'DOS852'),     ('PDOX_INTL',  'DOS437'),
    ('PDOX_ISL',   'DOS861'),   ('PDOX_NORDAN4','DOS865'),   ('PDOX_PLK',    'DOS852'),    ('PDOX_SLO',       'DOS852'),    ('PDOX_SWEDFIN',  'DOS437'),     ('PT_BR',      'ISO8859_1'),
    ('PT_PT',      'ISO8859_1'),('PXW_CSY',     'WIN1250'),  ('PXW_CYRL',    'WIN1251'),   ('PXW_GREEK',      'WIN1253'),   ('PXW_HUN',       'WIN1250'),    ('PXW_HUNDC',  'WIN1250'),
    ('PXW_INTL',   'WIN1252'),  ('PXW_INTL850', 'WIN1252'),  ('PXW_NORDAN4', 'WIN1252'),   ('PXW_PLK',        'WIN1250'),   ('PXW_SLOV',      'WIN1250'),    ('PXW_SPAN',   'WIN1252'),
    ('PXW_SWEDFIN','WIN1252'),  ('PXW_TURK',    'WIN1254'),  ('SJIS_0208',   'SJIS_0208'), ('SV_SV',          'ISO8859_1'), ('TIS620',        'TIS620'),     ('TIS620_UNICODE','TIS620'),
    ('UCS_BASIC',  'UTF8'),     ('UNICODE',     'UTF8'),     ('UNICODE_CI',  'UTF8'),      ('UNICODE_CI_AI',  'UTF8'),      ('UNICODE_FSS',   'UNICODE_FSS'),('UTF8',          'UTF8'),
    ('WIN1250',    'WIN1250'),  ('WIN1251',     'WIN1251'),  ('WIN1251_UA',  'WIN1251'),   ('WIN1252',        'WIN1252'),   ('WIN1253',       'WIN1253'),    ('WIN1254',       'WIN1254'),
    ('WIN1255',    'WIN1255'),  ('WIN1256',     'WIN1256'),  ('WIN1257',     'WIN1257'),   ('WIN1257_EE',     'WIN1257'),   ('WIN1257_LT',    'WIN1257'),    ('WIN1257_LV',    'WIN1257'),
    ('WIN1258',    'WIN1258'),  ('WIN_CZ',      'WIN1250'),  ('WIN_CZ_CI_AI','WIN1250'),   ('WIN_PTBR',       'WIN1252')
  );

  //why I did this?
  cFldName        = 'field_name';
  cFldDescription = 'field_description';
  cFldDefSource   = 'field_default_source';
  cFldNullFlag    = 'field_not_null_constraint';
  cFldLength      = 'field_length';
  cFldPrecision   = 'field_precision';
  cFldScale       = 'field_scale';
  cFldType        = 'field_type_int';
  cFldSubType     = 'field_sub_type';
  cFldCollation   = 'field_collation';
  cFldCharset     = 'field_charset';
  cFldComputedSrc = 'computed_source';
  cArrUpBound     = 'array_upper_bound';
  cFldSource      = 'field_source';
  cFldCharLength  = 'characterlength';

  cTmplFields     = 'SELECT r.RDB$FIELD_NAME AS '     + cFldName        + ', ' +
                    'r.RDB$DESCRIPTION AS '           + cFldDescription + ', ' +
                    'r.RDB$DEFAULT_SOURCE AS '        + cFldDefSource   + ', ' + {SQL source for default value}
                    'r.RDB$NULL_FLAG AS '             + cFldNullFlag    + ', ' +
                    'f.RDB$FIELD_LENGTH AS '          + cFldLength      + ', ' +
                    'f.RDB$CHARACTER_LENGTH AS '      + cFldCharLength  + ', ' + {character_length seems a reserved word}
                    'f.RDB$FIELD_PRECISION AS '       + cFldPrecision   + ', ' +
                    'f.RDB$FIELD_SCALE AS '           + cFldScale       + ', ' +
                    'f.RDB$FIELD_TYPE AS '            + cfldType        + ', ' +
                    'f.RDB$FIELD_SUB_TYPE AS '        + cFldSubType     + ', ' +
                    'coll.RDB$COLLATION_NAME AS '     + cFldCollation   + ', ' +
                    'cset.RDB$CHARACTER_SET_NAME AS ' + cFldCharset     + ', ' +
                    'f.RDB$computed_source AS '       + cFldComputedSrc + ', ' +
                    'dim.RDB$UPPER_BOUND AS '         + cArrUpBound     + ', ' +
                    'r.RDB$FIELD_SOURCE AS '          + cFldSource      +  {domain if field based on domain}
                    ' FROM RDB$RELATION_FIELDS r '    +
                    'LEFT JOIN RDB$FIELDS f             ON r.RDB$FIELD_SOURCE     = f.RDB$FIELD_NAME '             +
                    'LEFT JOIN RDB$COLLATIONS coll      ON f.RDB$COLLATION_ID     = coll.RDB$COLLATION_ID ' +
                    'LEFT JOIN RDB$CHARACTER_SETS cset  ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID ' +
                    'LEFT JOIN RDB$FIELD_DIMENSIONS dim ON f.RDB$FIELD_NAME       = dim.RDB$FIELD_NAME '+
                    'WHERE r.RDB$RELATION_NAME= ''%S'' '+
                    'ORDER BY r.RDB$FIELD_POSITION;';

  //JKOZ : convert to external source for multilingual support, after I remove the dependency on the title in the code.
  NumObjects = 13; //number of different objects in dbObjects array below
  dbObjectsEN: array[TObjectType] of string = ('Unknown', 'Tables', 'Generators', 'Triggers', 'Views', 'Stored Procedures', 'UDFs','Sys Tables',
     'Domains', 'Roles',  'Exceptions', 'Users', 'Indices', 'Constraints');
//     'Table', 'Generator', 'Trigger', 'View',  'StoredProcedure',
//     'UDF', 'SystemTable', 'Domain', 'Role',  'Exception', 'User', 'Index', 'Constraint',
//     'Field'// should I distinguish between fields in a table and fields in a view? for now no.
//);

type

  { TEvsCustomComponentPool }

  { A pool of Tcomponents, tracks how many objects it has created.
    When the SoftMax is true then MaxCount becomes the maximum number of inactive components in the pool
    otherwise it is the maximum number of components that the pool is allowed to create.
    the user call the aquire method to get a component from the pool and when he no longer needs it calls
    the return method to release the component back to the pool.


    should I convert it to a generic pool to avoid type casting?
  }

  TEvsCustomComponentPool = class(TObject)
  private
    FContainer  :{$IFDEF EVS_CONTAINERS} TEvsStack {$ELSE} TStack {$ENDIF};
    FLazyCreate :Boolean; //default false
    FMaxCount   :Integer; //default 10
    FSoftMax    :Boolean; //default true;
    {$IFDEF EVS_CONTAINERS}
    FCount      :Integer;
    {$ENDIF}
    FAquired :Integer;  //init 0
    FClass   :TComponentClass; //default TComponent
    function GetCount :Integer;virtual;
    procedure SetLazyCreate(aValue :Boolean);virtual;
  protected
    procedure Put(const aItem:TComponent);virtual;
    function  Get :TComponent;virtual;
    function CreateNew:TComponent;virtual;
    procedure FillPool;virtual;
    procedure EmptyPool;
  public
    constructor Create(const aMaxCount :Integer = 10; const aLazyCreate :Boolean = False; const aClass :TComponentClass=nil);virtual;
    destructor Destroy; override;
    function Aquire :TComponent;overload;
    procedure Return(const aComponent :TComponent);

    property MaxCount   :Integer read FMaxCount;
    property Count      :Integer read GetCount;
    property LazyCreate :Boolean read FLazyCreate write SetLazyCreate;
    property SoftMax    :Boolean read FSoftMax write FSoftMax;
  end;

  { TEvsConnectionPool }

  TEvsConnectionPool = class(TEvsCustomComponentPool)
  public
    function Aquire : TSQLConnection;overload;
  end;

  { TEvsQueryPool }

  TEvsQueryPool = class(TEvsCustomComponentPool)
    function Aquire:TSQLQuery;overload;
  end;

  { TEvsThreadedComponentPool }
  //needs testing, do not use.
  // the base methods of creating have been overriden and wrapped in a locking mechanism to
  // allow multiple threads to aquire and release components. The count and softmax are shared
  // from all threads.
  TEvsThreadedComponentPool = Class(TEvsCustomComponentPool)
  private
    FLock :TCriticalSection;
    procedure SetLazyCreate(aValue :Boolean); override;
  protected
    procedure Lock;
    procedure Unlock;
    procedure Put(const aItem:TComponent);override;
    function  Get :TComponent;            override;
    function CreateNew :TComponent;       override;
    function GetCount  :Integer;          override;
    procedure FillPool;                   override;
  public
    constructor Create(const aMaxCount :Integer = 10; const aLazyCreate :Boolean = False; const aClass :TComponentClass=nil);override;
    destructor Destroy; override;
  end;


  { TFormEnumerator }

  TFormEnumerator = class
  private
    FList   : TScreen;
    FClass  : TFormClass;
    FCurrent: Integer;
    function GetCurrent :TForm;
  public
    constructor Create(aScreen: TScreen; aBaseClass: TFormClass);
    function MoveNext: Boolean;
    function GetEnumerator: TFormEnumerator;
    property Current: TForm read GetCurrent;
  end;

  { TScreenHelper }

  TScreenHelper = class helper for TScreen
    function FormByClass(const aClass:TFormClass):TFormEnumerator;
  end;

  function IsReservedWord(const aName:String):boolean;


// Retrieve available collations for specified Characterset into Collations
function GetCollations(const Characterset: string; var Collations: TStringList): boolean;

// Given field retrieval query in FieldQuery, return field type and size.
// Includes support for field types that are domains and arrays
procedure GetFieldType(FieldQuery: TMDOQuery; var FieldType: string; var FieldSize: integer);

// Returns field type DDL given a RDB$FIELD_TYPE value as well
// as subtype/length/scale (use -1 for empty/unknown values)
function GetFBTypeName(Index: Integer; SubType: integer=-1; FieldLength: integer=-1;
                       Precision: integer=-1; Scale: integer=-1): string;

// Tries to guess if an RDB$RELATION_FIELDS.RDB$FIELD_SOURCE domain name for a column is system-generated.
function IsFieldDomainSystemGenerated(FieldSource: string): boolean;

// Tries to guess if an index name is a system generated primary key index
function IsPrimaryIndexSystemGenerated(IndexName: string): boolean;

// Given TIBConnection parameters, sets transaction isolation level
procedure SetTransactionIsolation(Params: TStrings);

{ Using a pool Manager return an existing query or create a new and return it.
  The procedure initializes the transaction to the one passed or creates a new only
  for the new query. }
//function GetQuery(const aConnection : TSQLConnection; const aTransaction:TSQLTransaction=nil):TSQLQuery;overload;
//function GetQuery(const aConnection : TSQLConnection; const aSQLCmd :string; const aParams:Array of const; const aTransaction:TSQLTransaction=nil):TSQLQuery;

//
function GetQuery(const aConnection :TMDODataBase; const aTransaction :TMDOTransaction=nil) :TMDOQuery;
function GetQuery(const aConnection :TMDODataBase; const aSQLCmd :string; const aParams :Array of const; const aTransaction :TMDOTransaction=Nil) :TMDOQuery;

//the connection passed is used to initialize the new connection.
//function GetConnection(const aConnection:TIBConnection=nil):TIBConnection;
//function GetConnection(const aDB:TDBInfo):TIBConnection;

//function GetConnection(const aConnection:TMDODataBase=nil):TIBConnection;
//function GetConnection(const aDB:TDBInfo):TIBConnection;

function GetConnection(const aConnection:TMDODataBase):TMDODataBase;
function GetConnection(const aDB:TDBInfo):TMDODataBase;

{
 If there is empty space in the pool the query is returned there if not the returned item is destroyed
 including the transaction that might own.}
procedure ReleaseQuery(const aQuery : TSQLQuery);deprecated 'use the MDO Query instead';
procedure ReleaseQuery(const aQuery : TMDOQuery);
procedure ReleaseConnection(const aConnection:TIBConnection);deprecated 'use the MDO Database instead';

procedure Connect(const aCnn:TIBConnection; aDatabase,aUser,aPassword:String; aCharset:string = ''; aRole:String='');deprecated 'use the MDO Database instead';
procedure Connect(const aCnn:TIBConnection; const aDatabase:TDBDetails);overload;deprecated 'use the MDO Database instead';
procedure Connect(const aCnn:TIBConnection; const aDatabase:TDBInfo);overload;deprecated 'use the MDO Database instead';
//MDO Jump;
procedure Connect(const aCnn:TMDODataBase; const aDatabase:TDBInfo);overload;
procedure Connect(const aCnn:TMDODatabase;const aDatabase:TDBDetails);overload;

function IsConnectedTo(const aCnn:TMDODataBase; const aDB:TDBInfo):Boolean;overload;
function IsConnectedTo(const aCnn:TMDODataBase; const aDB:TDBDetails):Boolean;overload;

//function SQLExecute(const aDB :TDBInfo; const aCommand:string; aParams:Array of const;const aTransaction:TSQLTransaction=nil) :Boolean;

function SQLExecute(const aDB :TDBInfo; const aCommand:string; aParams:Array of const;const aTransaction:TMDOTransaction=nil) :Boolean;
function SQLExecute(const aConn :TMDODataBase; const aCommand:string; aParams:Array of const; const aTransaction:TMDOTransaction=nil) :Boolean;

function FindCustomForm(aCaption: string; aClass: TFormClass): TForm;

//initialization routines
procedure InitDBInfo(var aDBInfo:TDBInfo);
procedure InitDBRec(var aRec:TDBDetails);
function  NewDBInfo:PDBinfo;

//generic call to clear on controls that support it.
procedure ClearControls(const aParent:TWinControl);experimental;
function WhereStr(const aFieldNames: array of string; const aFieldValues:array of const; const aLinkStatement:string='and'; Enclose:Boolean = False ):string;

function GetServerName(const aDBName: string): string;

function NotImplementedException:ETBException;
function DeprecatedException:ETBException;
function EOF(const aStream:TStream):Boolean;inline;
function CharCount(const aChar : Char; const aString:string):Integer;
function Split(const aSource:String; aDelimeter:Char):TStringArray;//mind the sie of the string that are passed it might raise an out of memory exception if too big.

implementation

type
  { TEvsQuery }

  // allows to own transactions.
  TEvsQuery = class(TSQLQuery)
  public
    destructor Destroy; override;
  end;


  { TEVSIBConn }
  //copy data from an MDODatabase
  TEVSIBConn = class(TIBConnection)
    procedure Assign(Source :TPersistent); override;
  end;

  { TEvsMDOConnection }
  //Copy Data from an IBConnection.
  TEvsMDOConnection = class(TMDODataBase)
    procedure Assign(Source :TPersistent); override;
  end;

  { TEvsMDOQuery }

  TEvsMDOQuery = class(TMDOQuery)
  private
    FOwnTransaction :Boolean;
  public
    destructor Destroy; override;
    property OwnsTransaction :Boolean read FOwnTransaction write FOwnTransaction;
  end;

const
  TransactionOwned    = -1;
  TransactionNotOwned =  0; //JK: refactor those?

var
  QueryPool      :TEvsCustomComponentPool;
  ConnectionPool :TEvsCustomComponentPool;

function NotImplementedException:ETBException;
begin
  Result := ETBException.Create('Not Implemented');
end;

function DeprecatedException :ETBException;
begin
  Result := ETBException.Create('Method is deprecated');
end;

function EOF(const aStream :TStream) :Boolean;inline;
begin
  Result := aStream.Position = aStream.Size;
end;

function CharCount(const aChar :Char; const aString :string) :Integer;
var
  vChr:Char;
begin
  Result := 0;
  for vChr in aString do
    if CompareText(aChar, vChr) = 0 then Inc(Result);
end;

function Split(const aSource :String; aDelimeter :Char) :TStringArray;
var
  vCntr,
  vIndex: integer;
begin
  vIndex := 0;
  SetLength(Result, (Length(aSource) div 2) + 1); //worst case senario every other letter is a delimeter.
  for vCntr := 1 to Length(aSource) do begin
    if aSource[vCntr] = aDelimeter then
      if Result[vIndex] <> '' then Inc(vIndex)
    else
      Result[vIndex] := Result[vIndex] + aSource[vCntr];
  end;
  if Result[vIndex + 1] <> '' then
    SetLength(Result, vIndex + 1)
  else SetLength(Result, vIndex);
end;

function VarArrayOf(aValues: array of const): Variant;
var
  vCntr: integer;
begin
  Result := VarArrayCreate([Low(aValues), High(aValues)], varVariant);
  for vCntr := Low(aValues) to High(aValues) do begin
    with aValues[vCntr] do begin
      case VType of
        vtInteger:    Result[vCntr] := VInteger;
        vtBoolean:    Result[vCntr] := VBoolean;
        vtChar:       Result[vCntr] := VChar;
        vtExtended:   Result[vCntr] := VExtended^;
        vtString:     Result[vCntr] := VString^;
        vtPointer:    Result[vCntr] := integer(VPointer);
        vtPChar:      Result[vCntr] := StrPas(VPChar);
        vtAnsiString: Result[vCntr] := string(VAnsiString);
        vtCurrency:   Result[vCntr] := VCurrency^;
        vtVariant:    Result[vCntr] := VVariant^;
        vtObject:     Result[vCntr] := integer(VObject);
        vtInterface:  Result[vCntr] := integer(VInterface);
        vtWideString: Result[vCntr] := WideString(VWideString);
        vtInt64:      Result[vCntr] := VInt64^;
      else
        raise Exception.Create ('OpenArrayToVarArray: invalid data type')
      end;
    end;
  end;
end;

{
 function returns a string of conditions for a where SQL statement.
 Limited use, tdatetime is not recognized, pass it as a variant or as a string.
 aFieldNames is an open array parameter that accepts the names of the fields you want to use
 aFieldValues is an untyped open array parameter that accepts the value to check for each fieldname
 aLinkStatement holds the statement for linking the conditions together and/or
 There are 2 static behaviors
   1) if the value for a field is string then like is used.
   2) all string and datetime values will be properly quoted
   3) all other values types will be checked using =
   4) You can pass a variant array as a value in which case an "in" condition will be used.
}
function WhereStr(const aFieldNames: array of string; const aFieldValues:array of const; const aLinkStatement:string='and'; Enclose:Boolean = False ):string;
  function evsVarToStr(const aValue:Variant):string;forward;
  function VarArrayToCSV(const aValue:Variant):String;inline;
  var
    vDimCntr : Integer;
    vCntr :LongInt;
  begin
    Result := '';
    for vDimCntr := 1 to VarArrayDimCount(aValue) do begin
      for vCntr := VarArrayLowBound(aValue, vDimCntr) to VarArrayHighBound(aValue, vDimCntr) do begin
        Result  := Result + evsVarToStr(aValue[vCntr])+',';
      end;
    end;
  end;
  function evsVarToStr(const aValue:Variant):string;inline;
  begin
    if VarIsArray(aValue) then // only one dimension is read for now ;
       Result := VarArrayToCSV(aValue)
    else
      Result := VarToStr(aValue);
    case VarType(aValue) of
      varstring ,varustring, vardate : Result := QuotedStr(Result);
    end;
  end;
  function ValueString(aIndex:Integer):string; inline;
  begin
    case aFieldValues[aIndex].VType of
      vtInteger       : Result := IntToStr( aFieldValues[aIndex].VInteger);
      vtBoolean       : Result := BoolToStr(aFieldValues[aIndex].VBoolean);
      vtChar          : Result := QuotedStr(aFieldValues[aIndex].VChar);
      vtWideChar      : Result := aFieldValues[aIndex].VWideChar;
      vtExtended      : Result := FloatToStr(aFieldValues[aIndex].VExtended^);
      vtString        : Result := aFieldValues[aIndex].VString^;
      vtPChar         : Result := aFieldValues[aIndex].VPChar;
      vtPWideChar     : Result := QuotedStr(aFieldValues[aIndex].VPWideChar^);
      vtAnsiString    : Result := QuotedStr(String(aFieldValues[aIndex].VAnsiString));
      vtCurrency      : Result := CurrToStr(aFieldValues[aIndex].VCurrency^);
      vtWideString    : Result := QuotedStr(WideString(aFieldValues[aIndex].VWideString));
      vtInt64         : Result := IntToStr(aFieldValues[aIndex].VInt64^);
      vtUnicodeString : Result := QuotedStr(UnicodeString(aFieldValues[aIndex].VUnicodeString));
      vtQWord         : Result := IntToStr(aFieldValues[aIndex].VQWord^);
      vtVariant       : Result := evsVarToStr(aFieldValues[aIndex].VVariant^);
      //vtPointer       : Result := IntToHex(PtrInt(aFieldValues[aIndex].VPointer),SizeOf(Pointer));
      //vtObject        : Result := aFieldValues[aIndex].VObject.ToString;
      //vtClass         : Result := aFieldValues[aIndex].VClass.ClassName;
      //vtInterface     : ;
    else
      raise Exception.Create('WhereStr : Unsupported Data type <'+IntToStr(aFieldValues[aIndex].VType)+'>');
    end;
  end;
  function IsVarArray(const aValue:TVarRec):Boolean;inline;
  begin
    Result := (aValue.VType = vtVariant) and (VarIsArray(aValue.VVariant^));
  end;
var
  vFldCntr :Integer;
begin
  if Length(aFieldNames)>Length(aFieldValues) then ETBException.Create('WhereStr: Not enough values.');
  Result := '';
  for vFldCntr := Low(aFieldNames) to High(aFieldNames) do begin
    Result := Result + aFieldNames[vFldCntr];
    if isVarArray(aFieldValues[vFldCntr]) then begin
      Result := Result +' in ('+ValueString(vFldCntr)+')'+' ' +aLinkStatement+' ';
    end else begin
      if aFieldValues[vFldCntr].VType in [vtAnsiString, vtChar, vtWideChar, vtWideString, vtUnicodeString] then
        Result := Result + ' like '
      else if aFieldValues[vFldCntr].VType = vtVariant then begin
      end else
        Result := Result +' = ';
      Result := Result + ValueString(vFldCntr) +' '+ aLinkStatement+' ';
    end;
  end;//every link has two spaces added.
  if ( Length(Result) > (Length(aLinkStatement) + 2)) then
    SetLength(Result,Length(Result)-Length(aLinkStatement)-2);
  if Enclose then Result := '('+Result+')';;
end;


function IsReservedWord(const aName :String) :boolean;
var
  vCntr : Integer;
begin
  for vCntr := 0 to High(FBReservedWords) do begin
    Result := CompareText(aName,FBReservedWords[vCntr]) = 0;
    if Result then Break;
  end;
end;

function GetCollations(const Characterset: string; var Collations: TStringList): boolean;
var
  i: integer;
begin
  result := false;
  Collations.Clear;
  Collations.BeginUpdate;
  for i := low(FBCollations) to high(FBCollations) do begin
    if FBCollations[i,1]=Characterset then begin
      Collations.Add(FBCollations[i,0]);
    end;
  end;
  Collations.EndUpdate;
  result:= true;
end;

procedure SetTransactionIsolation(Params: TStrings);
begin
  Params.Clear;
  //Params.Add('isc_tpb_read_committed');
  //Params.Add('isc_tpb_concurrency');
  //Params.Add('isc_tpb_nowait');

  Params.Add('read_committed');
  Params.Add('rec_version');
  Params.Add('nowait');
  //read_committed
  //concurrency
  //nowait

end;

//function GetQuery(const aConnection :TSQLConnection; const aTransaction :TSQLTransaction) :TSQLQuery;
//begin
//  Result := TSQLQuery(QueryPool.Aquire);
//  Result.DataBase := aConnection;
//  Result.Transaction := aTransaction;
//  if not Assigned(Result.Transaction) then begin
//    Result.Transaction := TSQLTransaction.Create(Result);
//    SetTransactionIsolation(TSQLTransaction(Result.Transaction).Params);
//    Result.Transaction.DataBase := aConnection;
//    Result.Tag := TransactionOwned; //jk: make it an embedded property or something and leave the tag free for other usage.
//  end;
//end;

function GetQuery(const aConnection :TMDODataBase; const aTransaction :TMDOTransaction=nil) :TMDOQuery;
begin
  Result := TMDOQuery(QueryPool.Aquire);
  Result.DataBase := aConnection;
  Result.Transaction := aTransaction;
  if not Assigned(aTransaction) then begin
    Result.Transaction := TMDOTransaction.Create(Result);
    SetTransactionIsolation(TMDOTransaction(Result.Transaction).Params);
    Result.Transaction.DefaultDatabase := aConnection;
    TEvsMDOQuery(Result).OwnsTransaction := True;
  end;
end;

//function GetQuery(const aConnection :TSQLConnection; const aSQLCmd :string; const aParams :Array of const; const aTransaction :TSQLTransaction) :TSQLQuery;
//begin
//  Result := GetQuery(aConnection, aTransaction);
//  try
//    if aSQLCmd <> '' then begin
//      Result.sql.Text := Format(aSQLCmd, aParams);
//      Result.Open;
//      Result.First;
//    end;
//  except
//    On E:Exception do begin //make sure no memory leak in case of an exception.
//      ReleaseQuery(Result);
//      Result := nil;
//      raise E;
//    end;
//  end;
//end;

function GetQuery(const aConnection :TMDODataBase; const aSQLCmd :string; const aParams :Array of const; const aTransaction :TMDOTransaction=Nil) :TMDOQuery;
begin
  Result := GetQuery(aConnection, aTransaction);
  try
    if aSQLCmd <> '' then begin
      Result.sql.Text := Format(aSQLCmd, aParams);
      Result.Open;
      Result.First;
    end;
  except
    On E:Exception do begin //make sure no memory leak, in case of an exception.
      ReleaseQuery(Result);
      Result := nil;
      raise E;
    end;
  end;
end;

function GetConnection(const aDB :TDBInfo) :TMDODataBase;
begin
  Result := GetConnection(Nil);
  Result.DatabaseName := aDB.RegRec.DatabaseName;
  Result.UserName     := aDB.RegRec.UserName;
  Result.Password     := aDB.RegRec.Password;
  Result.Role         := aDB.RegRec.Role;
  Result.CharSet      := aDB.RegRec.Charset;
end;

function GetServerName(const aDBName: string): string;
begin
  if Pos(':', aDBName) > 2 then
    Result:= Copy(aDBName, 1, Pos(':', aDBName) - 1)
  else
    Result:= 'localhost';
end;

function GetConnection(const aConnection :TMDODataBase) :TMDODataBase;
var
  vCmp :TComponent;
begin
  vCmp := ConnectionPool.Aquire;
  if vCmp is TMDODataBase then
    Result := TMDODataBase(vCmp)
  else
    raise ETBException.Create('Invalid Connection Pool Class <'+vCmp.ClassName+'>'+LineEnding+
                              'It was expected to be <'+TIBConnection.ClassName+'>');
  if Assigned(aConnection) then
    Result.Assign(aConnection);
end;

//function GetConnection(const aDB :TDBInfo) :TMDODataBase;
//begin
//  {$IFDEF EVS_New}
//  Result := GetConnection(aDB.Conn);
//  {$ENDIF}
//  {$IFDEF EVS_OLD}
//  Result := GetConnection(aDB.IBConnection,False);
//  {$ENDIF}
//end;

procedure ReleaseQuery(const aQuery :TSQLQuery);
var
  vTmp :TSQLTransaction;
begin
  if aQuery.Active then aQuery.Close;
  if aQuery.Transaction.Active then TSQLTransaction(aQuery.Transaction).Rollback;//if the transaction is active then it should roll back.
  if aQuery.Tag = TransactionOwned then begin
    vTmp := TSQLTransaction(aQuery.Transaction);
    aQuery.Transaction := Nil;
    aQuery.Tag := 0;
    vTmp.Free;
  end;
  QueryPool.Return(aQuery);
end;

procedure ReleaseQuery(const aQuery :TMDOQuery);
var
  vTmp :TMDOTransaction;
begin
  if aQuery.Active then aQuery.Close;
  if aQuery.Transaction.Active then aQuery.Transaction.Rollback;
  if TEvsMDOQuery(aQuery).OwnsTransaction then begin
    vTmp := TMDOTransaction(aQuery.Transaction);
    aQuery.Transaction := Nil;
    TEvsMDOQuery(aQuery).OwnsTransaction := False;
    vTmp.Free;
  end;
  QueryPool.Return(aQuery);
end;

procedure ReleaseConnection(const aConnection :TIBConnection);
begin
  if Assigned(aConnection.Transaction) and aConnection.Transaction.Active then aConnection.Transaction.EndTransaction;
  ConnectionPool.Return(aConnection);
end;

procedure Connect(const aCnn :TIBConnection; aDatabase, aUser, aPassword :String; aCharset :string; aRole :String);
begin
  aCnn.DatabaseName := aDatabase;
  aCnn.UserName     := aUser;
  aCnn.Password     := aPassword;
  aCnn.Role         := aRole;
  aCnn.CharSet      := aCharset;
  aCnn.Connected    := True;
end;

procedure Connect(const aCnn :TIBConnection; const aDatabase :TDBDetails);
begin
  aCnn.DatabaseName := aDatabase.DatabaseName;
  aCnn.UserName     := aDatabase.UserName;
  aCnn.Password     := aDatabase.Password;
  aCnn.Role         := aDatabase.Role;
  aCnn.CharSet      := aDatabase.Charset;
  aCnn.Connected    := True;
end;

procedure Connect(const aCnn :TIBConnection; const aDatabase :TDBInfo);
begin
  Connect(aCnn, aDatabase.RegRec);
end;

procedure Connect(const aCnn :TMDODataBase; const aDatabase :TDBInfo);
begin
  Connect(aCnn,aDatabase.RegRec);
end;

procedure Connect(const aCnn :TMDODatabase; const aDatabase :TDBDetails);
begin
  if (aCnn.Connected) and ((CompareText(aCnn.UserName,aDatabase.UserName)=0) and (CompareText(aCnn.Password, aDatabase.Password)=0) and
     (CompareText(aCnn.DatabaseName, aDatabase.DatabaseName)=0)) then Exit
  else aCnn.Connected := False;
  aCnn.DatabaseName := aDatabase.DatabaseName;
  aCnn.UserName     := aDatabase.UserName;
  aCnn.Password     := aDatabase.Password;
  aCnn.CharSet      := aDatabase.Charset;
  //aCnn.Params.Values['sql_role_name']:= aDatabase.Role;
  aCnn.Role         := aDatabase.Role;
  aCnn.Connected    := True;
end;

function IsConnectedTo(const aCnn :TMDODataBase; const aDB :TDBInfo):Boolean;
begin
  result := IsConnectedTo(aCnn, aDB.RegRec);
end;

function IsConnectedTo(const aCnn :TMDODataBase; const aDB :TDBDetails):Boolean;
begin
  Result := (CompareText(aCnn.DatabaseName,adb.DatabaseName)=0) and
            (CompareText(aCnn.UserName,aDB.UserName)=0) and
            (CompareText(aCnn.CharSet, aDB.Charset)=0);
end;

//function SQLExecute(const aDB :TDBInfo; const aCommand :string; aParams :Array of const; const aTransaction :TSQLTransaction) :Boolean;
//var
//  vQry : TSQLQuery;
//begin
//  Result := False;
//  vQry := GetQuery(aDB.IBConnection,aCommand,aParams, aTransaction);
//  try
//    vQry.SQL.Text := Format(aCommand, aParams);
//    vQry.ExecSQL;
//    if not Assigned(aTransaction) then vQry.Transaction.Commit;
//  finally
//    ReleaseQuery(vQry);
//  end;
//  Result := True;
//end;

function EqualTexts(S1,S2:String):Boolean; inline;
begin
  Result := CompareText(S1, s2) = 0;
end;

function SQLExecute(const aDB :TDBInfo; const aCommand :string; aParams :Array of const; const aTransaction :TMDOTransaction) :Boolean;
var
  vQry:TMDOQuery;
begin
  vQry := GetQuery(aDB.Conn,aCommand,aParams, aTransaction);
  try
    vQry.SQL.Text := Format(aCommand, aParams);
    vQry.ExecSQL;
    if not Assigned(aTransaction) then vQry.Transaction.Commit;
  finally
    ReleaseQuery(vQry);
  end;
  Result := True;
end;

function SQLExecute(const aConn :TMDODataBase; const aCommand :string; aParams :Array of const; const aTransaction :TMDOTransaction) :Boolean;
var
  vQry:TMDOQuery;
begin
  vQry := GetQuery(aConn,aCommand,aParams, aTransaction);
  try
    vQry.SQL.Text := Format(aCommand, aParams);
    vQry.ExecSQL;
    if not Assigned(aTransaction) then vQry.Transaction.Commit;
  finally
    ReleaseQuery(vQry);
  end;
  Result := True;
end;

function FindCustomForm(aCaption :string; aClass :TFormClass) :TForm;
var
  vCntr: Integer;
begin
  Result:= nil;
  for vCntr:= 0 to Screen.FormCount - 1 do begin
    if Screen.Forms[vCntr] is aClass then
      if CompareText(Screen.Forms[vCntr].Caption, aCaption) = 0 then begin
        Result:= Screen.Forms[vCntr];
        Break;
      end;
  end;
end;

procedure GetFieldType(FieldQuery :TMDOQuery; var FieldType :string; var FieldSize :integer);
// Requires FieldQuery to be the correct field retrieval query.
// todo: migrate field retrieval query to systables if not already done
begin
  FieldType:= '';
  FieldSize:= 0;

  if (FieldQuery.FieldByName('field_source').IsNull) or
    (trim(FieldQuery.FieldByName('field_source').AsString)='') or
    (IsFieldDomainSystemGenerated(trim(FieldQuery.FieldByname('field_source').AsString))) then
  begin
    // Field type is not based on a domain but a standard SQL type
    FieldType:= GetFBTypeName(FieldQuery.FieldByName('field_type_int').AsInteger,
      FieldQuery.FieldByName('field_sub_type').AsInteger,
      FieldQuery.FieldByName('field_length').AsInteger,
      FieldQuery.FieldByName('field_precision').AsInteger,
      FieldQuery.FieldByName('field_scale').AsInteger);
    // Array should really be [lowerbound:upperbound] (if dimension is 0)
    // but for now don't bother as arrays are not supported anyway
    // Assume 0 dimension, 1 lower bound; just fill in upper bound
    if not(FieldQuery.FieldByName('array_upper_bound').IsNull) then
      FieldType := FieldType +
        ' [' +
        FieldQuery.FieldByName('array_upper_bound').AsString +
        ']';
    if FieldQuery.FieldByName('field_type_int').AsInteger = VarCharType then
      FieldSize := FieldQuery.FieldByName('characterlength').AsInteger
    else
      FieldSize := FieldQuery.FieldByName('field_length').AsInteger;
  end else begin
    // Field is based on a domain
    FieldType:= Trim(FieldQuery.FieldByName('field_source').AsString);
  end;
end;

(**************  Get Firebird Type name  *****************)

function GetFBTypeName(Index    : Integer;    SubType: integer=-1; FieldLength: integer=-1;
                       Precision: integer=-1; Scale  : integer=-1): string;
begin
  //todo: (low priority) add Firebird 3.0 beta BOOLEAN datatype number
  case Index of
    // See also
    // http://firebirdsql.org/manual/migration-mssql-data-types.html
    // http://stackoverflow.com/questions/12070162/how-can-i-get-the-table-description-fields-and-types-from-firebird-with-dbexpr
    BlobType    : Result := 'BLOB';
    14          : Result := 'CHAR';
    CStringType : Result := 'CSTRING'; // probably null-terminated string used for UDFs
    12          : Result := 'DATE';
    11          : Result := 'D_FLOAT';
    16          : Result := 'BIGINT'; // Further processed below
    27          : Result := 'DOUBLE PRECISION';
    10          : Result := 'FLOAT';
    8           : Result := 'INTEGER'; // further processed below
    9           : Result := 'QUAD'; // ancient VMS 64 bit datatype; see also IB6 Language Reference RDB$FIELD_TYPE
    7           : Result := 'SMALLINT'; // further processed below
    13          : Result := 'TIME';
    35          : Result := 'TIMESTAMP';
    VarCharType : Result := 'VARCHAR';
  else
    Result := 'Unknown Type';
  end;
  // Subtypes for numeric types
  if Index in [7, 8, 16] then
  begin
    if SubType = 0 then {integer}
    begin
      case Index of
        7: Result  := 'SMALLINT';
        8: Result  := 'INTEGER';
        16: Result := 'BIGINT';
      end;
    end
    else
    begin
      // Numeric/decimal: use precision/scale
      if SubType = 1 then
        Result:= 'Numeric('
      else
      if SubType = 2 then
        Result:= 'Decimal(';

      if Precision=-1 then {sensible default}
        Result:= Result + '2,'
      else
        Result:= Result + IntToStr(Precision)+',';
      Result:= Result + IntToStr(Abs(Scale)) + ') ';
    end;
  end;
end;

function IsFieldDomainSystemGenerated(FieldSource: string): boolean;
begin
  // Unfortunately there does not seem to be a way to search the system tables to find out
  // if the constraint name is system-generated
  result:= (pos('RDB$',uppercase(Trim(FieldSource)))=1);
end;

function IsPrimaryIndexSystemGenerated(IndexName: string): boolean;
begin
  result:= (pos('RDB$PRIMARY',uppercase(Trim(IndexName)))=1);
end;

{ TFormEnumerator }

function TFormEnumerator.GetCurrent :TForm;
begin
  Result := Screen.Forms[FCurrent];
end;

constructor TFormEnumerator.Create(aScreen :TScreen; aBaseClass :TFormClass);
begin
  inherited Create;
  FList := aScreen;
  FClass := aBaseClass;
  FCurrent := -1;
end;

function TFormEnumerator.MoveNext :Boolean;
begin
  Inc(FCurrent); //get the next
  while (FCurrent < Screen.FormCount) and (not Screen.Forms[FCurrent].InheritsFrom(FClass)) do
    Inc(FCurrent);
  Result := FCurrent < Screen.FormCount;
end;

function TFormEnumerator.GetEnumerator :TFormEnumerator;
begin
  Result := Self;
end;

{ TScreenHelper }

function TScreenHelper.FormByClass(const aClass :TFormClass) :TFormEnumerator;
begin
  Result := TFormEnumerator.Create(Self, aClass);
end;

{ TEvsMDOQuery }

destructor TEvsMDOQuery.Destroy;
begin
  if (Transaction <> nil) and ((Tag = TransactionOwned) or FOwnTransaction) then Transaction.Free;
  inherited Destroy;
end;

{ TEvsMDOConnection }

procedure TEvsMDOConnection.Assign(Source :TPersistent);
begin
  if Source is TIBConnection then begin;
    DatabaseName := TIBConnection(Source).DatabaseName;
    UserName     := TIBConnection(Source).UserName;
    Password     := TIBConnection(Source).Password;
    CharSet      := TIBConnection(Source).CharSet;
    if Trim(TIBConnection(Source).Role) <> '' then
      Params.Values['sql_role_name'] := TIBConnection(Source).Role;
  end else
    inherited Assign(Source);
end;

{ TEVSIBConn }

procedure TEVSIBConn.Assign(Source :TPersistent);
begin
  if source is TMDODataBase then begin
    DatabaseName := TMDODataBase(Source).DatabaseName;
    UserName     := TMDODataBase(Source).UserName;
    Password     := TMDODataBase(Source).Password;
    CharSet      := TMDODataBase(Source).CharSet;
    Role         := TMDODataBase(Source).Params.Values['sql_role_name'];
  end else
    inherited Assign(Source);
end;

{ TEvsQueryPool }

function TEvsQueryPool.Aquire :TSQLQuery;
begin
  Result := TSQLQuery(inherited Aquire);
end;

{ TEvsConnectionPool }

function TEvsConnectionPool.Aquire :TSQLConnection;
begin
  Result := TSQLConnection(inherited Aquire);
end;

{ TEvsQuery }

destructor TEvsQuery.Destroy;
begin
  if (Transaction <> nil) and (Tag = TransactionOwned) then Transaction.Free;
  inherited Destroy;
end;

{$REGION ' TEvsThreadedComponentPool '}

procedure TEvsThreadedComponentPool.SetLazyCreate(aValue :Boolean);
begin
  Lock;
  try
    inherited SetLazyCreate(aValue);
  finally
    Unlock;
  end;
end;

procedure TEvsThreadedComponentPool.Lock;
begin
  FLock.Enter;
end;

procedure TEvsThreadedComponentPool.Unlock;
begin
  FLock.Leave;
end;

procedure TEvsThreadedComponentPool.Put(const aItem :TComponent);
begin
  Lock;
  try
    inherited Put(aItem);
  finally
    Unlock;
  end;
end;

function TEvsThreadedComponentPool.Get :TComponent;
begin
  Lock;
  try
    Result := inherited Get;
  finally
    Unlock;
  end;
end;

function TEvsThreadedComponentPool.CreateNew :TComponent;
begin
  Lock;
  try
    Result := inherited CreateNew;
  finally
    Unlock;
  end;
end;

function TEvsThreadedComponentPool.GetCount :Integer;
begin
  Lock;
  try
    Result := FContainer.Count;
  finally
    Unlock;
  end;
end;

procedure TEvsThreadedComponentPool.FillPool;
begin
  Lock;
  try
    inherited FillPool;
  finally
    Unlock;
  end;
end;

constructor TEvsThreadedComponentPool.Create(const aMaxCount :Integer; const aLazyCreate :Boolean; const aClass :TComponentClass);
begin
  inherited Create(aMaxCount, aLazyCreate, aClass);
  FLock := TCriticalSection.Create;
end;

destructor TEvsThreadedComponentPool.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;


{$ENDREGION}

{$REGION ' TEvsCustomComponentPool '}

function TEvsCustomComponentPool.GetCount :Integer;
begin
  Result := FContainer.Count;
end;

procedure TEvsCustomComponentPool.SetLazyCreate(aValue :Boolean);
begin
  FLazyCreate := aValue;
end;

procedure TEvsCustomComponentPool.Put(const aItem :TComponent);
begin
  if Count >= FMaxCount then aItem.Free
  else FContainer.Push(aItem);
  Dec(FAquired);
end;

function TEvsCustomComponentPool.Get :TComponent;
begin
  Result := TComponent(FContainer.Pop);
  //if FDestroying then Exit;
  if (not Assigned(Result)) and ((FAquired < FMaxCount) or FSoftMax) then
    Result := CreateNew;
  if Assigned(Result) then Inc(FAquired);
end;

function TEvsCustomComponentPool.CreateNew :TComponent;
begin
  Result := FClass.Create(Nil);
end;

procedure TEvsCustomComponentPool.FillPool;
var
  vCntr :Integer;
begin
  for vCntr := 1 to FMaxCount do Put(CreateNew);
end;

procedure TEvsCustomComponentPool.EmptyPool;
var
  vRes : TComponent;
begin
  repeat
    vRes := TComponent(FContainer.Pop);
    if Assigned(vRes) then vRes.Free;
  until vRes = nil;
end;

constructor TEvsCustomComponentPool.Create(const aMaxCount :Integer; const aLazyCreate :Boolean; const aClass :TComponentClass);
begin
  inherited Create;
  FMaxCount   := aMaxCount;
  FLazyCreate := aLazyCreate;
  FSoftMax    := True;
  FClass      := aClass;
  FContainer  := {$IFDEF EVS_CONTAINERS} TEvsStack.Create {$ELSE} TStack.Create {$ENDIF};
  if not FLazyCreate then FillPool;
end;

destructor TEvsCustomComponentPool.Destroy;
begin
  EmptyPool;
  FContainer.Free;
  inherited Destroy;
end;

function TEvsCustomComponentPool.Aquire :TComponent;
begin
  Result := Get;
end;

procedure TEvsCustomComponentPool.Return(const aComponent :TComponent);
begin
  Put(aComponent);
end;

{$ENDREGION}
{$REGION Initialization Routines}
procedure InitDBRec(var aRec:TDBDetails);
begin
  FillByte(aRec, SizeOf(TDBDetails), 0);
  //in fpc booleans have a value of 0 for false and <>0 for true. In case of error uncomment the lines below.
  //aRec.Deleted      := False;
  //aRec.SavePassword := False;
end;

function NewDBInfo :PDBinfo;
begin
  Result := New(PDBInfo);
  InitDBInfo(Result^);
end;

procedure ClearControls(const aParent :TWinControl);
var
  vCntr :Integer;
begin //only text editing controls are cleared for now.
  for vCntr := 0 to aParent.ControlCount -1 do begin
    if aParent.Controls[vCntr] is TCustomEdit then TCustomEdit(aParent.Controls[vCntr]).Clear
    else if aParent.Controls[vCntr] is TCustomComboBox then TCustomComboBox(aParent.Controls[vCntr]).Text := ''
    else if aParent.Controls[vCntr] is TCustomListBox then TCustomListBox(aParent.Controls[vCntr]).ItemIndex := -1
  end;
end;

//function PoolAquire(const aConnection :TSQLConnection; const aSQLCmd :string; const aParams :Array of const; const aTransaction :TSQLTransaction) :TSQLQuery;
//begin
//  Result := GetQuery(aConnection, aSQLCmd, aParams, aTransaction);
//end;

function PoolAquire(const aDB :TDBInfo) :TMDODataBase;
begin
  Result := GetConnection(aDB);
end;

procedure InitDBInfo(var aDBInfo :TDBInfo);
begin
  //fillbyte will do a faster job. I prefere the luxury of choice.
  InitDBRec(aDBInfo.RegRec);
  InitDBRec(aDBInfo.OrigRegRec);
  //aDBInfo.IBConnection := nil;
  //aDBInfo.SQLTrans     := nil;
  aDBInfo.Conn  := Nil;
  aDBInfo.Trans := Nil;
  aDBInfo.Index := -1; //-1 not saved yet.
end;
{$ENDREGION}

initialization
  QueryPool := TEvsCustomComponentPool.Create(10, True, TEvsMDOQuery);
  QueryPool.SoftMax := True; //create as many controls as requested only keep alive fmaxCount controls.
  //ConnectionPool := TEvsCustomComponentPool.Create(10, True, TEVSIBConn);
  //ConnectionPool.SoftMax := True; //create as many controls as requested, only keep alive fmaxCount controls.
  ConnectionPool := TEvsCustomComponentPool.Create(10, True, TEvsMDOConnection);
  ConnectionPool.SoftMax := True; //create as many controls as requested, only keep alive fmaxCount controls.
finalization
  QueryPool.Free;//no access is possible at this point.
end.


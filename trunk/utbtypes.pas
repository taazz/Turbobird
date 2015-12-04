unit uTBTypes;

{$mode objfpc}{$H+}

interface
//Generic unit to hold all the custom data types of the application to help with the deletion of public/published
//variables and avoid circular reference
uses
  Classes, SysUtils, sqldb, IBConnection;

type
  //JKOZ: moved here from Reg.pas
  TRegisteredDatabase = packed record
    Title: string[30];
    DatabaseName: string[200];
    UserName: string[100];
    Password: string[100];
    Charset: string[40];
    Deleted: Boolean;
    SavePassword: Boolean;
    Role: string[100];
    LastOpened: TDateTime;
    Reserved: array [0 .. 40] of Byte;
  end;

  //JKOZ: moved here from main.pas
  PDatabaseRec = ^TDatabaseRec;
  TDatabaseRec = record
    Index        :Integer;
    RegRec       :TRegisteredDatabase;
    OrigRegRec   :TRegisteredDatabase;
    IBConnection :TIBConnection;
    SQLTrans     :TSQLTransaction;
  end;

  //JKOZ: moved here from systables.pas
  // e.g. used for composite foreign key constraints
  TConstraintCount = record
    Name  :string; // name of constraint
    Count :integer; // count of occurrences
  end;
  TConstraintCounts = array of TConstraintCount;


implementation

end.


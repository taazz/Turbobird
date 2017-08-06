unit uBaseFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, uEvsDBSchema;

type

  { TfrBase }

  TfrBase = class(TFrame)
  private
  protected
    FDatabase :IEvsDatabaseInfo;
    procedure SetDatabase(aValue :IEvsDatabaseInfo);virtual;
  public
    { public declarations }
    destructor Destroy; override;
    property Database:IEvsDatabaseInfo read FDatabase write SetDatabase;
  end;

implementation

{.$R *.lfm}

{ TfrBase }

procedure TfrBase.SetDatabase(aValue :IEvsDatabaseInfo);
begin
  if FDatabase=aValue then Exit;
  FDatabase:=aValue;
end;

destructor TfrBase.Destroy;
begin
  FDatabase := nil;
  inherited Destroy;
end;

end.


unit uTBActions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdActns, StdCtrls, uTBTypes, SynEdit;
type

  { TEvsCopyAction }

  TEvsCopyAction = class(TEditCopy)
  protected
    //function HasSelection(const aTarget:TObject):Boolean;
  public
    function HandlesTarget (Target  :TObject) :Boolean; override;
    procedure UpdateTarget (Target  :TObject); override;
    procedure ExecuteTarget(Target :TObject); override;
  end;

  { TEvsCutAction }

  TEvsCutAction = class(TEditCut)
  public
    function HandlesTarget(Target  :TObject) :Boolean; override;
    procedure UpdateTarget(Target  :TObject); override;
    procedure ExecuteTarget(Target :TObject); override;
  end;

  TEvsPasteAction = class(TEditPaste)
    function HandlesTarget(Target  :TObject) :Boolean; override;
    procedure UpdateTarget(Target  :TObject); override;
    procedure ExecuteTarget(Target :TObject); override;
  end;

  TEvsToggleCommentAction = class(TEditAction)
    function HandlesTarget(Target  :TObject) :Boolean; override;
    procedure UpdateTarget(Target  :TObject); override;
    procedure ExecuteTarget(Target :TObject); override;
  end;

implementation

{$REGION ' TEvsCutAction '}

function TEvsCutAction.HandlesTarget(Target :TObject) :Boolean;
begin
  Result:=inherited HandlesTarget(Target);
  Result := Result or ((Target is TCustomSynEdit) and ((Target = Control)or (Control = nil)));
end;

procedure TEvsCutAction.UpdateTarget(Target :TObject);
begin
  if Target is TCustomSynEdit then Enabled := TCustomSynEdit(Target).SelAvail
  else inherited UpdateTarget(Target);//future proofing.
end;

procedure TEvsCutAction.ExecuteTarget(Target :TObject);
begin
  if Target is TCustomSynEdit then TCustomSynEdit(Target).CutToClipboard
  else inherited ExecuteTarget(Target);
end;
{$ENDREGION}

{$REGION ' TEvsPasteAction '}

function TEvsPasteAction.HandlesTarget(Target :TObject) :Boolean;
begin
  Result:=inherited HandlesTarget(Target);
  Result := Result or ((Target is TCustomSynEdit) and ((Target = Control)or (Control = nil)));
end;

procedure TEvsPasteAction.UpdateTarget(Target :TObject);
begin
  if Target is TCustomSynEdit then Enabled := TCustomSynEdit(Target).CanPaste
  else inherited UpdateTarget(Target);//future proofing.
end;

procedure TEvsPasteAction.ExecuteTarget(Target :TObject);
begin
  if Target is TCustomSynEdit then TCustomSynEdit(Target).PasteFromClipboard
  else inherited ExecuteTarget(Target);
end;
{$ENDREGION}

{$REGION ' TEvsCopyAction '}

//function TEvsCopyAction.HasSelection(const aTarget :TObject) :Boolean;
//begin
//  Result := False;
//  if aTarget is TCustomEdit then Result := (TCustomEdit(aTarget).SelLength > 0);
//  else if aTarget is TCustomSynEdit then Result := TCustomSynEdit(aTarget).SelAvail;
//end;

function TEvsCopyAction.HandlesTarget(Target :TObject) :Boolean;
begin
  Result := inherited HandlesTarget(Target);
  Result := Result or ((Target is TCustomSynEdit) and ((Target = Control) or (Control = nil)));
end;

procedure TEvsCopyAction.UpdateTarget(Target :TObject);
begin
  if Target is TCustomSynEdit then Enabled := TCustomSynEdit(Target).SelAvail
  else inherited UpdateTarget(Target);//future proofing.
end;

procedure TEvsCopyAction.ExecuteTarget(Target :TObject);
begin
  if Target is TCustomSynEdit then TCustomSynEdit(Target).CopyToClipboard
  else inherited ExecuteTarget(Target);
end;
{$ENDREGION}

{$REGION ' TEvsToggleCommentAction '}

function TEvsToggleCommentAction.HandlesTarget(Target :TObject) :Boolean;
begin
  //Result:=inherited HandlesTarget(Target);
  Result := ((Target is TCustomSynEdit) and ((Target = Control) or (Control = nil)));
end;

procedure TEvsToggleCommentAction.UpdateTarget(Target :TObject);
begin
  if Target is TCustomSynEdit then Enabled := TCustomSynEdit(Target).SelAvail
  else inherited UpdateTarget(Target);//future proofing.
end;

procedure TEvsToggleCommentAction.ExecuteTarget(Target :TObject);
begin
  if Target is TCustomSynEdit then raise ETBException.Create('under contruction') //TCustomSynEdit(Target).CommandProcessor()
  else inherited ExecuteTarget(Target);
end;
{$ENDREGION}

end.


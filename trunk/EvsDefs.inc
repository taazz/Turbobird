{$MACRO ON}

{$IFDEF WINDOWS}
  {$define extdecl:=stdcall}
{$ENDIF}
{$IFDEF POSIX}
  {$define extdecl := cdecl}
{$ENDIF}

{$DEFINE EVS_New}
{$DEFINE EVS_INTF}


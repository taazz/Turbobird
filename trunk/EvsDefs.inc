{$MACRO ON}

{$IFDEF WINDOWS}
  {$define extdecl:=stdcall}
{$ENDIF}
{$IFDEF POSIX}
  {$define extdecl := cdecl}
{$ENDIF}

//{$IFDEF FPC}
//  {$Define const:=constref}
//{$ELSE}
//{$ENDIF}

{$DEFINE EVS_New}
{$DEFINE EVS_INTF}
{$DEFINE MEMORY_TRACE}

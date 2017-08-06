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
{.$DEFINE POOL_QRY}//Used in the unit utbFirebird to enable or disable the pooling mechanism for connection and queries. Keep disabled until memory leaks are fixed and pools are tested.

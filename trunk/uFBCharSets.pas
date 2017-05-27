Unit uFBCharSets;
Interface 
uses
  uTBTypes, SysUtils;
Function SupportedCollations(const aCharset:String):TStringArray;
Function SupportedCharacterSets:TStringArray;

Implementation

Function SupportedCharacterSets : TStringArray;
begin
  Result[  0] := 'NONE';
  Result[  1] := 'OCTETS';
  Result[  2] := 'ASCII';
  Result[  3] := 'UNICODE_FSS';
  Result[  4] := 'UTF8';
  Result[  5] := 'SJIS_0208';
  Result[  6] := 'EUCJ_0208';
  Result[  7] := 'DOS437';
  Result[  8] := 'DOS850';
  Result[  9] := 'DOS865';
  Result[ 10] := 'ISO8859_1';
  Result[ 11] := 'ISO8859_2';
  Result[ 12] := 'ISO8859_3';
  Result[ 13] := 'ISO8859_4';
  Result[ 14] := 'ISO8859_5';
  Result[ 15] := 'ISO8859_6';
  Result[ 16] := 'ISO8859_7';
  Result[ 17] := 'ISO8859_8';
  Result[ 18] := 'ISO8859_9';
  Result[ 19] := 'ISO8859_13';
  Result[ 20] := 'DOS852';
  Result[ 21] := 'DOS857';
  Result[ 22] := 'DOS860';
  Result[ 23] := 'DOS861';
  Result[ 24] := 'DOS863';
  Result[ 25] := 'CYRL';
  Result[ 26] := 'DOS737';
  Result[ 27] := 'DOS775';
  Result[ 28] := 'DOS858';
  Result[ 29] := 'DOS862';
  Result[ 30] := 'DOS864';
  Result[ 31] := 'DOS866';
  Result[ 32] := 'DOS869';
  Result[ 33] := 'WIN1250';
  Result[ 34] := 'WIN1251';
  Result[ 35] := 'WIN1252';
  Result[ 36] := 'WIN1253';
  Result[ 37] := 'WIN1254';
  Result[ 38] := 'NEXT';
  Result[ 39] := 'WIN1255';
  Result[ 40] := 'WIN1256';
  Result[ 41] := 'WIN1257';
  Result[ 42] := 'KSC_5601';
  Result[ 43] := 'BIG_5';
  Result[ 44] := 'GB_2312';
  Result[ 45] := 'KOI8R';
  Result[ 46] := 'KOI8U';
  Result[ 47] := 'WIN1258';
  Result[ 48] := 'TIS620';
  Result[ 49] := 'GBK';
  Result[ 50] := 'CP943C';
  Result[ 51] := 'GB18030';
end;

function csNONE_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'NONE';
end;

function csOCTETS_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'OCTETS';
end;

function csASCII_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'ASCII';
end;

function csUNICODE_FSS_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'UNICODE_FSS';
end;

function csUTF8_Collations :TStringArray;inline;
begin
  SetLength(Result,5);
  Result[0] := 'UTF8';
  Result[1] := 'UCS_BASIC';
  Result[2] := 'UNICODE';
  Result[3] := 'UNICODE_CI';
  Result[4] := 'UNICODE_CI_AI';
end;

function csSJIS_0208_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'SJIS_0208';
end;

function csEUCJ_0208_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'EUCJ_0208';
end;

function csDOS437_Collations :TStringArray;inline;
begin
  SetLength(Result,13);
  Result[0] := 'DOS437';
  Result[1] := 'PDOX_ASCII';
  Result[2] := 'PDOX_INTL';
  Result[3] := 'PDOX_SWEDFIN';
  Result[4] := 'DB_DEU437';
  Result[5] := 'DB_ESP437';
  Result[6] := 'DB_FIN437';
  Result[7] := 'DB_FRA437';
  Result[8] := 'DB_ITA437';
  Result[9] := 'DB_NLD437';
  Result[10] := 'DB_SVE437';
  Result[11] := 'DB_UK437';
  Result[12] := 'DB_US437';
end;

function csDOS850_Collations :TStringArray;inline;
begin
  SetLength(Result,11);
  Result[0] := 'DOS850';
  Result[1] := 'DB_FRC850';
  Result[2] := 'DB_DEU850';
  Result[3] := 'DB_ESP850';
  Result[4] := 'DB_FRA850';
  Result[5] := 'DB_ITA850';
  Result[6] := 'DB_NLD850';
  Result[7] := 'DB_PTB850';
  Result[8] := 'DB_SVE850';
  Result[9] := 'DB_UK850';
  Result[10] := 'DB_US850';
end;

function csDOS865_Collations :TStringArray;inline;
begin
  SetLength(Result,4);
  Result[0] := 'DOS865';
  Result[1] := 'PDOX_NORDAN4';
  Result[2] := 'DB_DAN865';
  Result[3] := 'DB_NOR865';
end;

function csISO8859_1_Collations :TStringArray;inline;
begin
  SetLength(Result,18);
  Result[0] := 'ISO8859_1';
  Result[1] := 'DA_DA';
  Result[2] := 'DU_NL';
  Result[3] := 'FI_FI';
  Result[4] := 'FR_FR';
  Result[5] := 'FR_CA';
  Result[6] := 'DE_DE';
  Result[7] := 'IS_IS';
  Result[8] := 'IT_IT';
  Result[9] := 'NO_NO';
  Result[10] := 'ES_ES';
  Result[11] := 'SV_SV';
  Result[12] := 'EN_UK';
  Result[13] := 'EN_US';
  Result[14] := 'PT_PT';
  Result[15] := 'PT_BR';
  Result[16] := 'ES_ES_CI_AI';
  Result[17] := 'FR_FR_CI_AI';
end;

function csISO8859_2_Collations :TStringArray;inline;
begin
  SetLength(Result,4);
  Result[0] := 'ISO8859_2';
  Result[1] := 'CS_CZ';
  Result[2] := 'ISO_HUN';
  Result[3] := 'ISO_PLK';
end;

function csISO8859_3_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'ISO8859_3';
end;

function csISO8859_4_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'ISO8859_4';
end;

function csISO8859_5_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'ISO8859_5';
end;

function csISO8859_6_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'ISO8859_6';
end;

function csISO8859_7_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'ISO8859_7';
end;

function csISO8859_8_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'ISO8859_8';
end;

function csISO8859_9_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'ISO8859_9';
end;

function csISO8859_13_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'ISO8859_13';
  Result[1] := 'LT_LT';
end;

function csDOS852_Collations :TStringArray;inline;
begin
  SetLength(Result,8);
  Result[0] := 'DOS852';
  Result[1] := 'DB_CSY';
  Result[2] := 'DB_PLK';
  Result[3] := 'DB_SLO';
  Result[4] := 'PDOX_CSY';
  Result[5] := 'PDOX_PLK';
  Result[6] := 'PDOX_HUN';
  Result[7] := 'PDOX_SLO';
end;

function csDOS857_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'DOS857';
  Result[1] := 'DB_TRK';
end;

function csDOS860_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'DOS860';
  Result[1] := 'DB_PTG860';
end;

function csDOS861_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'DOS861';
  Result[1] := 'PDOX_ISL';
end;

function csDOS863_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'DOS863';
  Result[1] := 'DB_FRC863';
end;

function csCYRL_Collations :TStringArray;inline;
begin
  SetLength(Result,3);
  Result[0] := 'CYRL';
  Result[1] := 'DB_RUS';
  Result[2] := 'PDOX_CYRL';
end;

function csDOS737_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'DOS737';
end;

function csDOS775_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'DOS775';
end;

function csDOS858_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'DOS858';
end;

function csDOS862_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'DOS862';
end;

function csDOS864_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'DOS864';
end;

function csDOS866_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'DOS866';
end;

function csDOS869_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'DOS869';
end;

function csWIN1250_Collations :TStringArray;inline;
begin
  SetLength(Result,9);
  Result[0] := 'WIN1250';
  Result[1] := 'PXW_CSY';
  Result[2] := 'PXW_HUNDC';
  Result[3] := 'PXW_PLK';
  Result[4] := 'PXW_SLOV';
  Result[5] := 'PXW_HUN';
  Result[6] := 'BS_BA';
  Result[7] := 'WIN_CZ';
  Result[8] := 'WIN_CZ_CI_AI';
end;

function csWIN1251_Collations :TStringArray;inline;
begin
  SetLength(Result,3);
  Result[0] := 'WIN1251';
  Result[1] := 'PXW_CYRL';
  Result[2] := 'WIN1251_UA';
end;

function csWIN1252_Collations :TStringArray;inline;
begin
  SetLength(Result,7);
  Result[0] := 'WIN1252';
  Result[1] := 'PXW_INTL';
  Result[2] := 'PXW_INTL850';
  Result[3] := 'PXW_NORDAN4';
  Result[4] := 'PXW_SPAN';
  Result[5] := 'PXW_SWEDFIN';
  Result[6] := 'WIN_PTBR';
end;

function csWIN1253_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'WIN1253';
  Result[1] := 'PXW_GREEK';
end;

function csWIN1254_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'WIN1254';
  Result[1] := 'PXW_TURK';
end;

function csNEXT_Collations :TStringArray;inline;
begin
  SetLength(Result,6);
  Result[0] := 'NEXT';
  Result[1] := 'NXT_US';
  Result[2] := 'NXT_DEU';
  Result[3] := 'NXT_FRA';
  Result[4] := 'NXT_ITA';
  Result[5] := 'NXT_ESP';
end;

function csWIN1255_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'WIN1255';
end;

function csWIN1256_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'WIN1256';
end;

function csWIN1257_Collations :TStringArray;inline;
begin
  SetLength(Result,4);
  Result[0] := 'WIN1257';
  Result[1] := 'WIN1257_EE';
  Result[2] := 'WIN1257_LT';
  Result[3] := 'WIN1257_LV';
end;

function csKSC_5601_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'KSC_5601';
  Result[1] := 'KSC_DICTIONARY';
end;

function csBIG_5_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'BIG_5';
end;

function csGB_2312_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'GB_2312';
end;

function csKOI8R_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'KOI8R';
  Result[1] := 'KOI8R_RU';
end;

function csKOI8U_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'KOI8U';
  Result[1] := 'KOI8U_UA';
end;

function csWIN1258_Collations :TStringArray;inline;
begin
  SetLength(Result,1);
  Result[0] := 'WIN1258';
end;

function csTIS620_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'TIS620';
  Result[1] := 'TIS620_UNICODE';
end;

function csGBK_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'GBK';
  Result[1] := 'GBK_UNICODE';
end;

function csCP943C_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'CP943C';
  Result[1] := 'CP943C_UNICODE';
end;

function csGB18030_Collations :TStringArray;inline;
begin
  SetLength(Result,2);
  Result[0] := 'GB18030';
  Result[1] := 'GB18030_UNICODE';
end;

Function SupportedCollations(const aCharset:String):TStringArray;
begin
  if CompareText(aCharset,'NONE') = 0 then 
    Result := csNONE_Collations;
  if CompareText(aCharset,'OCTETS') = 0 then 
    Result := csOCTETS_Collations;
  if CompareText(aCharset,'ASCII') = 0 then 
    Result := csASCII_Collations;
  if CompareText(aCharset,'UNICODE_FSS') = 0 then 
    Result := csUNICODE_FSS_Collations;
  if CompareText(aCharset,'UTF8') = 0 then 
    Result := csUTF8_Collations;
  if CompareText(aCharset,'SJIS_0208') = 0 then 
    Result := csSJIS_0208_Collations;
  if CompareText(aCharset,'EUCJ_0208') = 0 then 
    Result := csEUCJ_0208_Collations;
  if CompareText(aCharset,'DOS437') = 0 then 
    Result := csDOS437_Collations;
  if CompareText(aCharset,'DOS850') = 0 then 
    Result := csDOS850_Collations;
  if CompareText(aCharset,'DOS865') = 0 then 
    Result := csDOS865_Collations;
  if CompareText(aCharset,'ISO8859_1') = 0 then 
    Result := csISO8859_1_Collations;
  if CompareText(aCharset,'ISO8859_2') = 0 then 
    Result := csISO8859_2_Collations;
  if CompareText(aCharset,'ISO8859_3') = 0 then 
    Result := csISO8859_3_Collations;
  if CompareText(aCharset,'ISO8859_4') = 0 then 
    Result := csISO8859_4_Collations;
  if CompareText(aCharset,'ISO8859_5') = 0 then 
    Result := csISO8859_5_Collations;
  if CompareText(aCharset,'ISO8859_6') = 0 then 
    Result := csISO8859_6_Collations;
  if CompareText(aCharset,'ISO8859_7') = 0 then 
    Result := csISO8859_7_Collations;
  if CompareText(aCharset,'ISO8859_8') = 0 then 
    Result := csISO8859_8_Collations;
  if CompareText(aCharset,'ISO8859_9') = 0 then 
    Result := csISO8859_9_Collations;
  if CompareText(aCharset,'ISO8859_13') = 0 then 
    Result := csISO8859_13_Collations;
  if CompareText(aCharset,'DOS852') = 0 then 
    Result := csDOS852_Collations;
  if CompareText(aCharset,'DOS857') = 0 then 
    Result := csDOS857_Collations;
  if CompareText(aCharset,'DOS860') = 0 then 
    Result := csDOS860_Collations;
  if CompareText(aCharset,'DOS861') = 0 then 
    Result := csDOS861_Collations;
  if CompareText(aCharset,'DOS863') = 0 then 
    Result := csDOS863_Collations;
  if CompareText(aCharset,'CYRL') = 0 then 
    Result := csCYRL_Collations;
  if CompareText(aCharset,'DOS737') = 0 then 
    Result := csDOS737_Collations;
  if CompareText(aCharset,'DOS775') = 0 then 
    Result := csDOS775_Collations;
  if CompareText(aCharset,'DOS858') = 0 then 
    Result := csDOS858_Collations;
  if CompareText(aCharset,'DOS862') = 0 then 
    Result := csDOS862_Collations;
  if CompareText(aCharset,'DOS864') = 0 then 
    Result := csDOS864_Collations;
  if CompareText(aCharset,'DOS866') = 0 then 
    Result := csDOS866_Collations;
  if CompareText(aCharset,'DOS869') = 0 then 
    Result := csDOS869_Collations;
  if CompareText(aCharset,'WIN1250') = 0 then 
    Result := csWIN1250_Collations;
  if CompareText(aCharset,'WIN1251') = 0 then 
    Result := csWIN1251_Collations;
  if CompareText(aCharset,'WIN1252') = 0 then 
    Result := csWIN1252_Collations;
  if CompareText(aCharset,'WIN1253') = 0 then 
    Result := csWIN1253_Collations;
  if CompareText(aCharset,'WIN1254') = 0 then 
    Result := csWIN1254_Collations;
  if CompareText(aCharset,'NEXT') = 0 then 
    Result := csNEXT_Collations;
  if CompareText(aCharset,'WIN1255') = 0 then 
    Result := csWIN1255_Collations;
  if CompareText(aCharset,'WIN1256') = 0 then 
    Result := csWIN1256_Collations;
  if CompareText(aCharset,'WIN1257') = 0 then 
    Result := csWIN1257_Collations;
  if CompareText(aCharset,'KSC_5601') = 0 then 
    Result := csKSC_5601_Collations;
  if CompareText(aCharset,'BIG_5') = 0 then 
    Result := csBIG_5_Collations;
  if CompareText(aCharset,'GB_2312') = 0 then 
    Result := csGB_2312_Collations;
  if CompareText(aCharset,'KOI8R') = 0 then 
    Result := csKOI8R_Collations;
  if CompareText(aCharset,'KOI8U') = 0 then 
    Result := csKOI8U_Collations;
  if CompareText(aCharset,'WIN1258') = 0 then 
    Result := csWIN1258_Collations;
  if CompareText(aCharset,'TIS620') = 0 then 
    Result := csTIS620_Collations;
  if CompareText(aCharset,'GBK') = 0 then 
    Result := csGBK_Collations;
  if CompareText(aCharset,'CP943C') = 0 then 
    Result := csCP943C_Collations;
  if CompareText(aCharset,'GB18030') = 0 then 
    Result := csGB18030_Collations;
end;

end.

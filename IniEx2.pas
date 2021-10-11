///////////////////////////////////////////////
// IniEx2 - ����������� INI-�����            //
//     � �������������� ��������� ������     //
///////////////////////////////////////////////
//  ______   Copyright � 2007 Vovan-VE       //
//  \ \  _|  Vovan-VE � Visible Efficiency   //
//   \ \ _|  mailto:Vovan-VE@yandex.ru       //
//    \___|  http://vovan-ve.fatal.ru/       //
//                                           //
///////////////////////////////////////////////
// version: 2.2 beta (07.08.2007) //
////////////////////////////////////

// ���������� � �������� � ������� ����������

unit IniEx2;

{.$DEFINE FILE_COMMENT_MULTILINE} //����������-��������� ������������� ������������� �����������
    //���� ��������, ���������-���������� ����� �������� � /* � */
    //� ���� ���������, �� � ������ ������ ��������� //
{$DEFINE TRACK_SYNTAX_ERROR} //����������� ������ ������ ���������� ��� �������� ����� (+4 KB EXE)
    //���� ���������, �� ��� �������������� ������ ��� ��������
    //  ������� TIni.LoadFile() ������ ��������� false
    //� ���� ��������, �� ����� ����� ����� �������� �� ���� �������
    //  �������� TIni.ErrorMsg ����� ��������� ��������� �� ������ ���
    //  ������ ������
{.$DEFINE COMPACT_SAVE} //��������� ��������� ��� ����������
    //���� ���������, �� ��� ���������� ����� ����������� ������� � �������,
    //  ��� ����� ������� �� ������� ��� ������������ ����
    //� ���� ��������, �� ��� ���������� �� ����� ��������� �� ������ �������
    //  ����������� �������. ������� ��������� ������ ������ �����.
    //  ���� ������ ���������� ������������ �� 10%-40% (� ���������� �� ������
    //  ������ � ������� �����������). ����� �������� ������� ������
    //  ����������� � ���� ��� ���� ������� ��� (����� ��, � ����������
    //  �� ������ ������ � ������� �����������).

interface

uses
    Windows,
    SysUtils,
    Classes,
    ShlWAPI;

const
    l_MAX_NAME_LENGTH=64;   //������������ ����� ����
    l_MAX_KEYS_COUNT=$FFFF; //������������ ���������� ������ � ������ (�������:word)
    l_MAX_SECS_COUNT=$FFFF; //������������ ���������� ������ � ��������� (�������:word)
    l_MAX_CONSTS_COUNT=$FFFF; //������������ ���������� �������� � ������ (�������:word)
{$IFDEF TRACK_SYNTAX_ERROR}
    l_MAX_TRACK_LENGTH=32; //������������ ����� ������� ��� ����������� �����
                           //(����� ������� ���������� � ... � �����)
{$ENDIF}

    //Value Type   -  ���� ��������
    l_VT_INTEGER = 1; //��������� pValue ���� PInteger => PInteger(pValue)^ = �����  (��� �������� � ������� ������������ PInteger)
    l_VT_STRING = 2;  //��������� pValue ���� PString => PString(pValue)^ = ������   (��� �������� � ������� ������������ ��� String:  Pointer(����������))

    ch_NAME_CHARS:set of char = //�������, ���������� � ������
    ['0'..'9','A'..'Z','_','a'..'z']; //�����������, ����� �� ����� ���� ������ � �����

    s_INDENT    :string = #9;     //��������� ������ (��� �/��� �������)
    s_SEC_LT    {:string} = '[';  //����� �� ����� ������
    s_SEC_RT    {:string} = ']';  //������ �� ����� ������
    s_SEC_BEGIN {:string} = '{';  //������ ������
    s_SEC_END   {:string} = '}';  //����� ������
    s_COMMENT   {:string} = '/';{//} //���������� (������ ������ �����, ������ ������ ����� �������)
    s_EQUAL     {:string} = '=';  //<����> = <��������>
    s_STR       {:string} = '"';  //(!���� ������!) ������������ ��������� �������� (������ ���� ������� � ch_UNPRINTABLE_CHARS)
    s_PATH_D    {:string} = '\';  //����������� � ���� ������
    s_KV_TERM   {:string} = ';';  //key=value ;
    s_COM_START {:string} = '/*';{/*} //   ������ � �����            \_ ������������ ������
    s_COM_END   {:string} = '*/';{*/} //   �������������� ���������� /  � TIni.SaveFile
    s_GET_KEY   {:string} = '!';  //key= !.key1;
    s_GET_KEY_SEP{:string}= '.';  //key= !section1.subsection2.key4;
    s_GET_KEY_PAR{:string}= '^';  //key= !.^.key4;
    s_CMD       {:string} = '#';  //#command
    //  [ Section ] {
    //    //content
    //  }

    ch_ESCAPE = '`'; //������-������ ������ ��� ����� ��������  `XX
    //���������� ������� - ������� �������������� � ���� `XX
    //����������� ������ ���� ������������ ����� s_STR � ��� ���� `
    ch_UNPRINTABLE_CHARS:set of char = [#0..#31,'"','`'];

type
    TStrArray = array of string;

    TKey = packed record  //���� ����
        sName:string;     //���
        pValue:Pointer;   //��������� �� �������� (PInteger ��� PString)
        lType:Cardinal;   //��� ��������
        wIndex:word;      //������ �����
        wReserved:word;   //(���������������) �� ������������
    end; //size=16
    PKey = ^TKey;            //��������� �� ����
    PKeyArr = array of PKey; //������ ���������� �� �����

    TKeys = class      // ��������� ������
    private
        zKeys:PKeyArr;   //������ ���������� �� �����
        wCount:word;     //���������� ������
        pkLastKey:PKey;  //��������� �� ����, ��������� ��������� ������� IndexOfKey()
        function GetKey(Index:word):PKey;
    public
        constructor Create();
        destructor Destroy(); override;
        function IsValidIndex(Index:Integer):boolean;
        property Count:word read wCount;
        property Keys[Index:word]:PKey read GetKey; default;
        function GetValue(Index:word;pDefault:Pointer=nil):pointer;
        function SetValue(Index:word; pValue:pointer; lType:Cardinal):boolean;
        function GetValueOf(sName:string;pDefault:Pointer=nil):pointer;
        function SetValueOf(sName:string; pValue:pointer; lType:Cardinal):boolean;
        function IndexOfKey(sKey:string):Integer;
        function Add(sName:string;pValue:Pointer; lType:Cardinal):Integer;
        function Remove(Index:word):boolean;
        procedure Clear();
        function GetFormatedValue(Index:word):string;
        function GetFormatedValueOf(sName,sDefault:string):string;
        function GetString(sName,sDefault:string):string;
        function GetInteger(sName:string;lDefault:Integer):Integer;
    end;

    TSections = class;

    TSection = class  //������
    private
        sName:string;        //���
        kKeys:TKeys;         //��������� ������
        lIndex:Cardinal;     //������ ������ � ��������� ������
        zSections:TSections; //��������� ���������
        zParentSec:TSection; //������ �� ������������ TSection (��� nil ���� ��� ����� �������)
        procedure SetName(Value:string);
    public
        constructor Create(AName:string);
        destructor Destroy(); override;
        property Parent:TSection read zParentSec write zParentSec;
        property Name:string read sName write SetName;
        property Keys:TKeys read kKeys;
        property Sections:TSections read zSections;
        function EnumAll(bLevel:byte):string;
    end;

    TSections = class  //��������� ������
    private
        Secs   :array of TSection; //������ ������
        wCount :word;              //���-��
        zParentSec:TSection;       //������ �� ������������ TSection (��� nil ���� ��� � ����� TIni)
        zLastSec:TSection;         //������, ��������� ��������� ������� IndexOfSection()
        function IsValidIndex(Index:Integer):boolean;
        function GetSec(Index:word):TSection;
    public
        constructor Create();
        destructor Destroy(); override;
        property Parent:TSection read zParentSec write zParentSec;
        property Count:word read wCount;
        property Sections[Index:word]:TSection read GetSec; default;
        function IndexOfSection(sSec:string):Integer;
        function Add(AName:string):Integer;
        function Remove(Index:word):boolean;
        procedure Clear();
        function EnumAll(bLevel:byte):string;
    end;

    TIni = class  //Ini'����   (�������� ��������� ������)
    private
        sFileName :string;    //��� �����
        zSections :TSections; //��������� ������
{$IFDEF TRACK_SYNTAX_ERROR}
        sParseError:string;   //��������� �� ������
{$ENDIF}
        procedure SetFileName(AFileName:string);
    public
        FileComment :string;  //���������-����������.
          //������������ ��� ���������� � ������. (���� ������, �� ������ �� ������������)
          //��� ��������������� ������� ��  DEFINE FILE_COMMENT_MULTILINE (��. ������)
        constructor Create(AFileName:string);
        destructor Destroy(); override;
        property Sections:TSections read zSections;
        property FileName:string read sFileName write SetFileName;
        function LoadFile():boolean;
        function SaveFile():boolean;
        function SectionOfPath(sPath:string):TSection;
        function ValueOfPath(sPath,sKey:string;sDefault:pointer):pointer;
        function ValueOfPathFormated(sPath,sKey,sDefault:string):string;
        function GetStringOfPath(sPath,sKey,sDefault:string):string;
        function GetIntegerOfPath(sPath,sKey:string;lDefault:Integer):Integer;
{$IFDEF TRACK_SYNTAX_ERROR}
        procedure ClearError();
        property ErrorMsg:string read sParseError;
{$ENDIF}
    end;

    TConst = packed record  //���������
        Name,Value:string;  //���, ��������
        Type_,Index:word;   //���, ������
    end;
    PConst = ^TConst;

    TConstList = class   //������� ��������
    private
        consts_:array of PConst;
        wCount:word;
        zLastConst:PConst;
        function GetConst(lIndex:word):PConst;
    public
        constructor Create();
        destructor Destroy(); override;
        property Consts[Index:word]:PConst read GetConst; default;
        procedure Clear();
        function Add(sName,sValue:string; lType:cardinal):boolean;
        function Remove(Index:word):boolean;
        function IndexOf(sName:string):Integer;
        function ValueOf(Index:Integer; var sValue:string; var lType:cardinal):boolean;
    end;

const
    //������������ ������� ����� (������������ ��� ����� ������� � ����� ��������� ������)
    l_STACK_MAX_COUNT = $4000; //$4000 * 4{SizeOf(Integer)} = $10000
type
    TStack = class  //���� (������������ ��� ������������ ������� ��������)
    private
        wCount:word;  //���-�� ���������
        values:array of Integer; //���������� ��������
    public
        constructor Create();
        destructor Destroy(); override;
        function Push(L:Integer):boolean;
        function Pop():Integer;
        function Top():Integer;
        procedure Clear();
    end; //����� ��������� �� ����� ���������� �� ��� ������

const
    //Token Type  -  ��� ������
    l_TT_ERROR  = 0;  //error
    l_TT_BR_L   = 1;  // [
    l_TT_BR_R   = 2;  // ]
    l_TT_SC_L   = 3;  // {
    l_TT_SC_R   = 4;  // }
    l_TT_NAME   = 5;  // name
    l_TT_CM_L   = 6;  // /* //
    l_TT_CM_R   = 7;  // */ crlf
    l_TT_EQV    = 8;  // =
    l_TT_NUM    = 9;  // 0
    l_TT_STR    = 10; // "
    l_TT_TERM   = 11; // ;
    l_TT_GK     = 12; // !
    l_TT_GK_DEL = 13; // .
    l_TT_GK_PAR = 14; // ^
    l_TT_CMD    = 15; // #
    l_TT_EOF    = 16; // eof


    //Parse Mode  -  ����� ��������
    l_PM_ERROR    = 0;  //error
    l_PM_ROOT     = 1;  // ����� ������� ������� - ��� ������
    l_PM_SEC_NAME = 2;  // �� [ �� ]
    l_PM_SEC_IN   = 3;  // �� { �� }
    //l_PM_NUMBER   = 4;  //
    //l_PM_STRING   = 5;  // �� " �� "
    l_PM_GET_K    = 6;  // �� ! �� ;
    l_PM_CMD      = 7;  // �� # �� ;
    l_PM_GET_CONST= 8;  // =name;
    l_PM_BACK_MASK= $100;  //���� ������� ���� ��������� � ����������� ���������
    //l_PM_BACK2_MASK=$200;  //���� ������� ���� ��� ���� ��������� � ����������� ���������

    //Commands  -  �������
    l_CMD_NO    = 0; //���� ��� �������: ������ ��� ����� # ����� ���������� ��������
                     //               ��� �����������: ��� ����� �������
    l_CMD_SET     = 1; // #set NAME=value;
    l_CMD_UNSET   = 2; // #unset NAME;
    l_CMD_INCLUDE = 3; // #include "file";

    s_CMD_SET     = 'SET';     // #set NAME=value;
    s_CMD_UNSET   = 'UNSET';   // #unset NAME;
    s_CMD_INCLUDE = 'INCLUDE'; // #include "file";


type
    TToken = packed record  //�����
        Type_:Integer;      //��� l_TT_
        content:string;     //����������
        offset:PChar;       //��� ���������� (����������� ��� ���������� ������ ������)
    end;
    PToken = ^TToken;

    TIncFile = packed record //��������� ����
        FileName:string;       //���
        Content :string;       //����������
        Start   :PChar;        //��������� �� ������� �������
    end;
    PIncFile = ^TIncFile;

    TIncStack = class  //���� ��������� ������
    private
        wCount:word;  //���-�� ���������
        values:array of PIncFile; //���������� ��������
    public
        constructor Create();
        destructor Destroy(); override;
        function Push(pIF:PIncFile):boolean;
        function Pop():PIncFile;
        function Top():PIncFile;
        procedure Clear();
        function IsIncluded(sFile:string):boolean;
        function IsEmpty:boolean;
    end;

procedure DisposePKey(var pk:PKey);
function IndentStr(bLevel:byte):string;
function IsValidName(sName:string):boolean;
function SaveToFile(const sFileName:string; var sText:string):boolean;
function LoadFromFile(const sFileName:string; var sText:string):boolean;
function SplitStr(sSrc,sDelimiter:string; bWithEmpty:boolean=true; lLimit:integer=-1):TStrArray;
function IsValidInt(sInt:string; var lResult:Integer):boolean;
procedure EscapeStr(var s:string);
procedure UnEscapeStr(var s:string);
function SetValueToVar(var X; pSrc:Pointer; lType:Cardinal):boolean;
function PosRev(S,SubStr:string):Integer;
function AddPath(sDir,sPathAdd:string):string;
procedure SwapStr(var S1,S2:string);
function NewIncFile(sFileName:string):PIncFile;
procedure DisposeIncFile(pIF:PIncFile);

function IsTokenExpected(pt1,pt2:PToken; lParseMode:Integer; var lNewMode:Integer):boolean;
function GetToken(var sStart:PChar; ptToken:PToken):boolean;
function CanTokenBeFirst(pt:PToken):boolean;
{$IFDEF TRACK_SYNTAX_ERROR}
function TokenToUser(pt:PToken):string;
function GetLineNumber(pStart,pPos:Pchar):Cardinal;
function WhatExpected(pt:PToken; lMode:Cardinal):string;
{$ENDIF}


////////////////////////////////
implementation
////////////////////////////////
var lCurCmd:Integer;  //������� �������

function SetCurCmd(sCmd:string): boolean;
//���� sCmd - ���������� �������, ��
//  ������������� lCurCmd � ��������������� ��������
//  ���������� true
//�����
//  ���������� false
begin
    sCmd := UpperCase(sCmd);
    if sCmd=s_CMD_SET then
        lCurCmd := l_CMD_SET
    else if sCmd=s_CMD_UNSET then
        lCurCmd := l_CMD_UNSET
    else if sCmd=s_CMD_INCLUDE then
        lCurCmd := l_CMD_INCLUDE
    else
        lCurCmd := l_CMD_NO
    ;
    result := lCurCmd<>l_CMD_NO;
end;

procedure DisposePKey(var pk:PKey);
//���������� PKey, ����������� ��� ������, ������� �� ��������
var ps:^string;
begin
    if pk=nil then exit;
    pk^.sName := '';
    case pk^.lType of
        l_VT_INTEGER: begin
            FreeMem(pk^.pValue,SizeOf(Integer));
        end;
        l_VT_STRING: begin
            ps := pk^.pValue;
            ps^ := '';
            dispose(ps);
            //FreeMem(pk^.pValue,SizeOf(Pointer));
        end;
    end;
    dispose(pk);
    pk := nil;
end;

function IndentStr(bLevel:byte):string;
//���������� ������ ������ bLevel
var i:byte;
begin
    result := '';
    if bLevel>0 then
        for i := 1 to bLevel do
            result := result+s_INDENT;
end;

function IsValidName(sName:string):boolean;
//�������� �� sName ���������� ������
var i,L:integer;
begin
    result := false;
    L := Length(sName);
    if (L=0)or(L>l_MAX_NAME_LENGTH) then exit;
    for i := 1 to L do begin
        if not(sName[i] in ch_NAME_CHARS) then
            exit;
    end;
    result := true;
end;

function SaveToFile(const sFileName:string; var sText:string):boolean;
//��������� sText � ���� sFileName � ���������� true
//����� ���������� false
var Stream: TStream;
begin
    Stream := nil;
    try
        Stream := TFileStream.Create(sFileName, fmCreate);
        result := true;
    except
        result := false;
    end;
    if not result then exit;
    try
        Stream.WriteBuffer(Pointer(sText)^, Length(sText));
        result := true;
    finally
        Stream.Free;
    end;
end;

function LoadFromFile(const sFileName:string; var sText:string):boolean;
//��������� � sText ���������� ����� sFileName � ���������� true
//����� ���������� false
var Stream: TStream;
    Size: Integer;
    S: string;
begin
    Stream := nil;
    try
        Stream := TFileStream.Create(sFileName, fmOpenRead or fmShareDenyWrite);
        result := true;
    except
        result := false;
    end;
    if not result then exit;
    try
        try
            Size := Stream.Size - Stream.Position;
            SetString(S, nil, Size);
            Stream.Read(Pointer(S)^, Size);
            sText := S;
            result := true;
        finally
            //
        end;
    finally
        Stream.Free;
    end;
end;

function SplitStr(sSrc,sDelimiter:string; bWithEmpty:boolean=true; lLimit:integer=-1):TStrArray;
//��������� ������ sSrc � ������ �� ����������� sDelimiter
//bWithEmpty - ��������� ������ ������
//lLimit - ������ ����� ������� (-1 - ��� �������)
var i,cnt,dl:integer;
begin
    dl := Length(sDelimiter);
    SetLength(result,0);
    cnt := 0;
    repeat
        inc(cnt);
        SetLength(result,cnt);
        i := Pos(sDelimiter,sSrc);
        if (i=0)or(cnt=lLimit) then begin
            result[cnt-1] := sSrc;
            sSrc := '';
        end else begin
            if (i=1)and not bWithEmpty then begin
                dec(cnt);
                SetLength(result,cnt);
            end else begin
                result[cnt-1] := Copy(sSrc,1,i-1);
            end;
            sSrc := Copy(sSrc,i+dl,Length(sSrc)-i-dl+1);
        end;
    until Length(sSrc)=0;
end;

function IsValidInt(sInt:string; var lResult:Integer):boolean;
//���� sInt - ��������� ������������� Integer'�, ��
//  � lResult ���������� ���������� ����� � ���������� true
//�����
//  ���������� false
var er:Integer;
    f:boolean;
begin
    if sInt='' then
        result := false
    else begin
        f := sInt[1]='-';
        if f then Delete(sInt,1,1);
        Val(sInt,lResult,er);
        result := er=0;
        if result and f then lResult := -lResult;
    end;
end;

procedure EscapeStr(var s:string);
//� ������ �������� ��� ���������� ������� ch_UNPRINTABLE_CHARS
//�� ������������������ `HH  - Hex-��� �������
// _ -> `HH
var i,L:Integer;
    ch:char;
    sRet:string;
begin
    sRet := '';
    L := Length(s);
    for i := 1 to L do begin
        ch := s[i];
        if (ch in ch_UNPRINTABLE_CHARS) then
            sRet := sRet+ch_ESCAPE+IntToHex(Integer(ch),2)
        else
            sRet := sRet+ch;
    end;
    s := sRet;
end;

procedure UnEscapeStr(var s:string);
//� ������ �������� ��� `HH �� ��������������� ������
//(������ ���� HH - Hex-���; ���� ���, �� ��������� ��� ����) 
// `HH -> _
var ch:char;
    pch,pch2:PChar;
begin
    s := StringReplace(s,#0,' ',[rfReplaceAll])+#0;
    pch := Pointer(s);
    pch2 := pch;

    while(true)do begin
        while(pch[0]<>#0)and(pch[0]<>ch_ESCAPE)do begin
            pch2[0] := pch[0];
            inc(pch);
            inc(pch2);
        end;
        if (pch[0]=#0) then begin    pch2[0] := pch[0]; break;    end;
        // founded `
        if (pch[1]=#0) then begin    pch2[1] := pch[1]; break;    end;
        if (pch[2]=#0) then begin    pch2[2] := pch[2]; break;    end;
        if (pch[1] in ['0'..'9','A'..'F'])and(pch[2] in ['0'..'9','A'..'F']) then begin
            ch := Char(StrToInt('$'+pch[1]+pch[2]));
            pch2[0] := ch;
            inc(pch,3);
            inc(pch2);
        end else begin
            pch2[0] := pch[0];
            pch2[1] := pch[1];
            pch2[2] := pch[2];
            inc(pch,3);
            inc(pch2,3);
        end;
    end;
    SetLength(s,pch2-Pointer(s));
end;

function SetValueToVar(var X; pSrc:Pointer; lType:Cardinal):boolean;
//�������� �������� ���� lType �� ������ pSrc � ���������� X
begin
    case lType of
        l_VT_INTEGER: begin
            Integer(X) := PInteger(pSrc)^;
            result := true;
        end;
        l_VT_STRING: begin
            string(X) := PString(pSrc)^;
            result := true;
        end;
        else result := false;
    end;
end;

function PosRev(S,SubStr:string):Integer;
//����� ��������� � ������ � �����
var i,n:Integer;
begin
    i := Length(S);
    n := Length(SubStr);
    if (S='')or(SubStr='')or
       (i<n) then
        result := 0
    else begin
        dec(i,n-1);
        S := UpperCase(S);
        SubStr := UpperCase(SubStr);
        while(i>0)do begin
            if StrLComp(@S[i],@SubStr[1],n)=0 then begin
                result := i;
                exit;
            end;
            dec(i);
        end;
        result := 0;
    end;
end;

function AddPath(sDir,sPathAdd:string):string;
//� ���� sDir (�� �� �����) ��������� ������������� ���� sPathAdd
//� ��������� ������� ��� '\subdir\..'
//sDir - ������ ���� � ����� (����� � ..)
//sPathAdd - ������������� ���� �� sDir (����� � ..)
//           ���� ���������� � '\' �� ��������� ��� ��� ���� �� ����� sDir
var i:Integer;
begin
    if (Length(sPathAdd)>0)and(sPathAdd[1]='\') then begin
        result := Copy(sDir,1,2)+sPathAdd;
    end else begin
        i := Length(sDir);
        if (i>0)and(sDir[i]='\') then
            sDir[i] := #0;
        SetLength(sDir,MAX_PATH+1);
        sDir[i+1] := #0;
        sDir[MAX_PATH+1] := #0;
        if PathAppend(PChar(sDir),PChar(sPathAdd))=0 then
            result := ''
        else
            result := Copy(sDir,1,Pos(#0,sDir)-1)
        ;
    end;
end;

procedure SwapStr(var S1,S2:string);
//����� ���� string'��
var p:pointer;
begin
    p := Pointer(S1);
    Pointer(S1) := Pointer(S2);
    Pointer(S2) := p;
end;

function NewIncFile(sFileName:string):PIncFile;
//��������� ���� sFileName
//���� �����, ��
//  ���������� nil
//����� (���������)
//  ������� ��������� PIncFile
//  ��������� ��
//  ���������� ��������� �� ���
var s:string;
begin
    if not LoadFromFile(sFileName,s) then begin
        result := nil;
        exit;
    end;
    s := StringReplace(s,#0,#32,[rfReplaceAll])+#0;
    new(result);
    result^.FileName := sFileName;
    result^.Content := '';
    SwapStr(result^.Content, s);
    result^.Start := @result^.Content[1];
end;

procedure DisposeIncFile(pIF:PIncFile);
//������� ������, ���������� ���������� PIncFile
begin
    if pIF<>nil then begin
        pIF^.FileName := '';
        pIF^.Content := '';
        dispose(pIF);
    end;
end;


function IsTokenExpected(pt1,pt2:PToken; lParseMode:Integer; var lNewMode:Integer):boolean;
//���� ������ ����� pt2 ��������� ����� ������� pt1 � ������ lParseMode, ��
//  ��������� ������ ���������� � lNewMode
//  ���������� true
//�����
//  ���������� false
begin
    lNewMode := 0;
    if (pt1=nil)or(pt2=nil) then
        result := false
    else begin
        case pt1^.Type_ of
            l_TT_BR_L: begin   // [ -> name]
                result := ((lParseMode=l_PM_ROOT)or(lParseMode=l_PM_SEC_IN))
                       and(pt2^.Type_=l_TT_NAME);
                if result then lNewMode := l_PM_SEC_NAME;
            end;
            l_TT_BR_R: begin   // ] -> {
                result := (lParseMode=l_PM_SEC_NAME)
                       and(pt2^.Type_=l_TT_SC_L);
                if result then lNewMode := l_PM_BACK_MASK;
            end;
            l_TT_SC_L: begin   // { -> [ name } ; #
                result := ((lParseMode=l_PM_SEC_IN)or(lParseMode=l_PM_ROOT))
                       and((pt2^.Type_=l_TT_BR_L)or
                           (pt2^.Type_=l_TT_NAME)or
                           (pt2^.Type_=l_TT_SC_R)or
                           (pt2^.Type_=l_TT_TERM)or
                           (pt2^.Type_=l_TT_CMD));
                if result then lNewMode := l_PM_SEC_IN;
            end;
            l_TT_SC_R: begin   // } -> [ eof name } ; #
                result := (lParseMode=l_PM_SEC_IN)
                       and((pt2^.Type_=l_TT_BR_L)or
                           (pt2^.Type_=l_TT_NAME)or
                           (pt2^.Type_=l_TT_SC_R)or
                           (pt2^.Type_=l_TT_TERM)or
                           (pt2^.Type_=l_TT_CMD)or
                           (pt2^.Type_=l_TT_EOF));
                if result then lNewMode := l_PM_BACK_MASK; //���������������� EOF 
            end;
            l_TT_NAME: begin   // name -> ] = . ;
                case lParseMode of
                    l_PM_SEC_NAME:  result := (pt2^.Type_=l_TT_BR_R);
                    l_PM_SEC_IN:    result := (pt2^.Type_=l_TT_EQV);
                    l_PM_GET_K: begin
                        result := (pt2^.Type_=l_TT_GK_DEL)or(pt2^.Type_=l_TT_TERM);
                        if pt2^.Type_=l_TT_TERM then lNewMode := l_PM_BACK_MASK;
                    end;
                    l_PM_CMD: begin
                        //����� �������
                        case lCurCmd of
                            l_CMD_NO: begin
                                if (pt1^.content=s_CMD_SET)or
                                   (pt1^.content=s_CMD_UNSET) then
                                    result := (pt2^.Type_=l_TT_NAME)
                                else if (pt1^.content=s_CMD_INCLUDE) then
                                    result := (pt2^.Type_=l_TT_STR)
                                else
                                    result := false;
                            end;
                            l_CMD_SET:   result := (pt2^.Type_=l_TT_EQV);
                            l_CMD_UNSET: result := (pt2^.Type_=l_TT_TERM);
                            else result := false;
                        end;
                    end;
                    l_PM_GET_CONST: begin
                        result := (pt2^.Type_=l_TT_TERM);
                        lNewMode := l_PM_BACK_MASK;
                    end;
                    else result := false;
                end;
            end;
            l_TT_CM_L: begin   //  /* //
                result := true;
            end;
            {l_TT_CM_R: begin   //  */ crlf
                not allowed here
            end;}
            l_TT_EQV: begin    // = -> 0 " !
                result := (lParseMode=l_PM_SEC_IN)
                       and((pt2^.Type_=l_TT_NUM)or
                           (pt2^.Type_=l_TT_STR)or
                           (pt2^.Type_=l_TT_GK)or
                           (pt2^.Type_=l_TT_NAME))
                       or
                          (lParseMode=l_PM_CMD)and(lCurCmd=l_CMD_SET)
                       and((pt2^.Type_=l_TT_NUM)or
                           (pt2^.Type_=l_TT_STR)or
                           (pt2^.Type_=l_TT_NAME));
                if result and (pt2^.Type_=l_TT_NAME) then
                    lNewMode := l_PM_GET_CONST;
            end;
            l_TT_NUM: begin    //
                result := ((lParseMode=l_PM_SEC_IN)or
                           (lParseMode=l_PM_CMD)and(lCurCmd=l_CMD_SET))
                       and(pt2^.Type_=l_TT_TERM);
                if result and(lParseMode=l_PM_CMD) then lNewMode := l_PM_BACK_MASK;
            end;
            l_TT_STR: begin    //
                result := ((lParseMode=l_PM_SEC_IN)or
                           (lParseMode=l_PM_CMD)and
                            ((lCurCmd=l_CMD_SET)or(lCurCmd=l_CMD_INCLUDE)))
                       and(pt2^.Type_=l_TT_TERM);
                if result and(lParseMode=l_PM_CMD) then lNewMode := l_PM_BACK_MASK;
            end;
            l_TT_TERM: begin   // ; -> [ name } ;
                result := (lParseMode=l_PM_SEC_IN)
                       and((pt2^.Type_=l_TT_BR_L)or
                           (pt2^.Type_=l_TT_NAME)or
                           (pt2^.Type_=l_TT_SC_R)or
                           (pt2^.Type_=l_TT_TERM)or
                           (pt2^.Type_=l_TT_CMD)or
                           (pt2^.Type_=l_TT_EOF))
                       or
                           (lParseMode=l_PM_ROOT)
                       and((pt2^.Type_=l_TT_BR_L)or
                           (pt2^.Type_=l_TT_TERM)or
                           (pt2^.Type_=l_TT_CMD)or
                           (pt2^.Type_=l_TT_EOF))
                       {or
                           (lParseMode=l_PM_CMD)
                       and ((pt2^.Type_=l_TT_BR_L)or
                           (pt2^.Type_=l_TT_NAME)or
                           (pt2^.Type_=l_TT_SC_R)or
                           (pt2^.Type_=l_TT_TERM)or
                           (pt2^.Type_=l_TT_CMD)or
                           (pt2^.Type_=l_TT_EOF))};
                {if result and (lParseMode=l_PM_CMD) then
                    lNewMode := l_PM_BACK_MASK;}
            end;
            l_TT_GK: begin     // ! -> . name
                result := (lParseMode=l_PM_SEC_IN)
                       and((pt2^.Type_=l_TT_NAME)or
                           (pt2^.Type_=l_TT_GK_DEL));
                if result then lNewMode := l_PM_GET_K;
            end;
            l_TT_GK_DEL: begin // . -> ^ name
                result := (lParseMode=l_PM_GET_K)
                       and((pt2^.Type_=l_TT_NAME)or
                           (pt2^.Type_=l_TT_GK_PAR));
            end;
            l_TT_GK_PAR: begin // ^ -> .
                result := (lParseMode=l_PM_GET_K)
                       and(pt2^.Type_=l_TT_GK_DEL);
            end;
            l_TT_CMD: begin    // # -> name
                result := ((lParseMode=l_PM_ROOT)or(lParseMode=l_PM_SEC_IN))
                       and(pt2^.Type_=l_TT_NAME);
                if result then lNewMode := l_PM_CMD;
            end;
            l_TT_EOF: begin    // eof
                result := (pt2^.Type_=l_TT_EOF);
            end;
            else result := false;
        end;
    end;
end;

function GetToken(var sStart:PChar; ptToken:PToken):boolean;
//�� ������ sStart ��������� �����, ���������� ��� � ptToken
//� �������� ��������� sStart �� ����� ������
//���������� ������������.
//���� ����� ����������
//  ���������� false
//����� (����� ���������)
//  ���� ��������� ����������
//    ���������� true
//  ����� (��������� ������������)
//    ���������� true � � ptToken ���������� ���: ������
var s:string;
    flag1{,flag2}:boolean;
    pch,pch2:PChar;
label Re1;
begin
    if (sStart<>nil)and(ptToken<>nil) then begin
Re1:
        while(sStart[0] in [#1..#32]) do
            inc(sStart);
        result := true;
        s := '';
        flag1 := false;
        //flag2 := false;
        ptToken^.offset := sStart;
        case sStart[0] of
            #0: begin
                ptToken^.Type_ := l_TT_EOF;
                ptToken^.content := sStart[0];
            end;
            '-','0'..'9': begin
                if sStart[0]='-' then begin
                    inc(sStart);
                    flag1 := true; //negative
                end;
                if (sStart[0]='0')and(sStart[1] in ['X','x']) then begin
                    inc(sStart,2);
                    //flag2 := true; //hexadecimal
                    while(sStart[0] in ['0'..'9','A'..'F','a'..'f']) do begin
                        s := s + sStart[0];
                        inc(sStart);
                    end;
                    ptToken^.Type_ := l_TT_NUM;
                    if flag1 then
                        ptToken^.content := '-$'+s
                    else
                        ptToken^.content := '$'+s;
                end else begin
                    while(sStart[0] in ['0'..'9']) do begin
                        s := s + sStart[0];
                        inc(sStart);
                    end;
                    ptToken^.Type_ := l_TT_NUM;
                    if flag1 then
                        ptToken^.content := '-'+s
                    else
                        ptToken^.content := s;
                end;
            end;
            'A'..'Z','_','a'..'z': begin
                s := sStart[0];
                inc(sStart);
                while(sStart[0] in ['0'..'9','A'..'Z','_','a'..'z']) do begin
                    s := s + sStart[0];
                    inc(sStart);
                end;
                ptToken^.Type_ := l_TT_NAME;
                ptToken^.content := s;
            end;
            s_SEC_LT: begin
                ptToken^.Type_ := l_TT_BR_L;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            s_SEC_RT: begin
                ptToken^.Type_ := l_TT_BR_R;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            s_SEC_BEGIN: begin
                ptToken^.Type_ := l_TT_SC_L;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            s_SEC_END: begin
                ptToken^.Type_ := l_TT_SC_R;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            s_COMMENT: begin
                if (sStart[1]='/') then begin
                    inc(sStart,2);
                    pch := StrPos(sStart,#13);
                    pch2 := StrPos(sStart,#10);
                    if (pch<>nil)or(pch2<>nil) then begin
                        if (pch<>nil)and(pch2<>nil) then begin
                            if pch<pch2 then
                                sStart := pch
                            else
                                sStart := pch2;
                        end else if (pch=nil) then
                            sStart := pch2
                        else
                            sStart := pch;
                        inc(sStart,1);
                        goto Re1;
                    end else begin
                        sStart := StrEnd(sStart);
                        ptToken^.Type_ := l_TT_EOF;
                        ptToken^.content := sStart[0];
                    end;
                end else if (sStart[1]='*') then begin
                    inc(sStart,2);
                    pch := StrPos(sStart,'*/');
                    if pch<>nil then begin
                        sStart := pch;
                        inc(sStart,2);
                        goto Re1;
                    end else begin
                        sStart := StrEnd(sStart);
                        ptToken^.Type_ := l_TT_EOF;
                        ptToken^.content := sStart[0];
                    end;
                end else begin
                    ptToken^.Type_ := l_TT_ERROR;
                    ptToken^.content := sStart[0];
                    result := false;
                end;
            end;
            s_EQUAL: begin
                ptToken^.Type_ := l_TT_EQV;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            s_STR: begin
                inc(sStart);
                pch := StrPos(sStart,s_STR);
                if pch<>nil then begin
                    SetString(ptToken^.content,sStart,pch-sStart);
                    sStart := pch;
                    inc(sStart);
                    ptToken^.Type_ := l_TT_STR;
                    UnEscapeStr(ptToken^.content);
                end else begin
                    ptToken^.Type_ := l_TT_ERROR;
                    dec(sStart);
                    SetString(ptToken^.content,sStart,StrLen(sStart));
                    sStart := StrEnd(sStart);
                    result := true;
                end;
            end;
            s_KV_TERM: begin
                ptToken^.Type_ := l_TT_TERM;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            s_GET_KEY: begin
                ptToken^.Type_ := l_TT_GK;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            s_GET_KEY_SEP: begin
                ptToken^.Type_ := l_TT_GK_DEL;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            s_GET_KEY_PAR: begin
                ptToken^.Type_ := l_TT_GK_PAR;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            s_CMD: begin
                ptToken^.Type_ := l_TT_CMD;
                ptToken^.content := sStart[0];
                inc(sStart);
            end;
            else begin
                ptToken^.Type_ := l_TT_ERROR;
                ptToken^.content := sStart[0];
                inc(sStart);
                result := false;
            end;
        end;
    end else
        result := false;
end;

function CanTokenBeFirst(pt:PToken):boolean;
//��������� �� ����� � ����� ������ (�� ������ ����������)
begin
    if pt=nil then
        result := false
    else
        result := (pt^.Type_=l_TT_BR_L)or
                  (pt^.Type_=l_TT_CMD)or
                  (pt^.Type_=l_TT_EOF);
end;

{$IFDEF TRACK_SYNTAX_ERROR}
function TokenToUser(pt:PToken):string;
//������ ��������� ������������ ������ (��� ����������� �����)
var l:Cardinal;
begin
    if pt=nil then
        result := ''
    else
        case pt^.Type_ of
            l_TT_ERROR,
            l_TT_NAME,
            l_TT_NUM: begin
                l := Length(pt^.content);
                if (l>0)and(pt^.content[1]=s_STR) then begin
                    if l>l_MAX_TRACK_LENGTH then
                        result := Copy(pt^.content,1,l_MAX_TRACK_LENGTH)+'...'
                    else
                        result := pt^.content;
                    if (l>1)and(pt^.content[l]<>s_STR) or (l=1) then
                        result := 'Unclosed '+s_STR+' in '+result;
                end else begin
                    result := pt^.content;
                end;
            end;
            l_TT_STR: begin
                if Length(pt^.content)>l_MAX_TRACK_LENGTH then
                    result := s_STR+Copy(pt^.content,1,l_MAX_TRACK_LENGTH)+'...'+s_STR
                else
                    result := s_STR+pt^.content+s_STR;
            end;
            l_TT_BR_L,
            l_TT_BR_R,
            l_TT_SC_L,
            l_TT_SC_R,
            l_TT_CM_L,
            l_TT_CM_R,
            l_TT_EQV,
            l_TT_TERM,
            l_TT_GK,
            l_TT_GK_DEL,
            l_TT_GK_PAR,
            l_TT_CMD: result := pt^.content;
            l_TT_EOF: result := '(EndOfFile)';
            else result := '(unknown)';
        end
    ;
end;
function GetLineNumber(pStart,pPos:Pchar):Cardinal;
//������������ ���������� �������� ����� ������ �� pStart �� pPos
//� ���������� ���������� ����� ������
var p,p2:PChar;
    ch:char;
begin
    if (pStart=nil)or(pPos=nil) then begin
        result := 0;
        exit;
    end;
    //��� ������?
    p := StrScan(pStart,#13);
    p2 := StrScan(pStart,#10);
    if (p=nil) then begin       
        if (p2=nil) then begin  //��� �� #10, �� #13
            result := 1;
            exit;
        end else                //���� ������ #10
            ch := #10;
    end else begin
        if (p2=nil) then        //���� ������ #13
            ch := #13
        else                    //���� ��� #10 � #13
            if p>p2 then        //  ��� ������
                ch := #13
            else
                ch := #10
        ;
    end;

    p := pStart;
    result := 1;
    if p[0]=ch then inc(result);

    while true do begin
        p := StrScan(p+1,ch);
        if p<>nil then begin
            if p>=pPos then
                exit
            else
                inc(result);
        end else begin
            exit;
        end;
    end;
end;
function WhatExpected(pt:PToken; lMode:Cardinal):string;
//��� ��������� ����� ������ pt � ������ lMode
//��� ����������� �����
begin
    if pt=nil then begin
        //what expected first in file
        result := '''[''';
    end else begin
        case pt^.Type_ of
            l_TT_BR_L,
            l_TT_CMD:    result := 'Identifier';
            l_TT_BR_R:   result := '''{''';
            l_TT_SC_L,
            l_TT_TERM:   result := 'Identifier, ''['', ''}'', '';'' or ''#''';
            l_TT_SC_R:   result := 'Identifier, ''['', ''}'', '';'', ''#'' or (EndOfFile)';
            l_TT_NAME: begin
                case lMode of
                    l_PM_SEC_NAME:  result := ''']''';
                    l_PM_SEC_IN:    result := '''=''';
                    l_PM_GET_K:     result := '''.'' or '';''';
                    l_PM_CMD: begin
                        //result := ''';'' or command specialized symbol';
                        case lCurCmd of
                            l_CMD_NO: begin
                                if pt^.content=S_CMD_INCLUDE then
                                    result := '"'
                                else if (pt^.content=s_CMD_SET)or
                                        (pt^.content=s_CMD_UNSET) then
                                    result := 'Identifier'
                                else
                                    result := '';
                            end;
                            l_CMD_SET,
                            l_CMD_UNSET: result := 'Identifier';
                            l_CMD_INCLUDE: result := '"';
                            else result := '';
                        end;
                    end;
                    l_PM_GET_CONST: result := ''';''';
                    else result := '';
                end;
            end;
            l_TT_EQV: begin
                case lMode of
                    l_PM_CMD:       result := 'Number, " or identifier';
                    l_PM_SEC_IN:    result := 'Number, ", ''!'' or identifier';
                    else result := '';
                end;
            end;
            l_TT_NUM,
            l_TT_STR:    result := ''';''';
            l_TT_GK:     result := 'Identifier or ''.''';
            l_TT_GK_DEL: result := 'Identifier or ''^''';
            l_TT_GK_PAR: result := '''.''';
            else result := '';
        end;
        //if result<>'' then result := +result;
    end;
end;
{$ENDIF}

////////////////////////////////////////
// TKeys
////////////////////////////////////////

constructor TKeys.Create;
begin
    inherited;
    SetLength(zKeys,0);
    wCount := 0;
    pkLastKey := nil;
end;

destructor TKeys.Destroy;
begin
    Clear();
    inherited;
end;

function TKeys.Add(sName:string;pValue:Pointer; lType:Cardinal):Integer;
//���������
//��� Integer:  pValue = @IntVar
//��� String:   pValue = Pointer(StrVar)
var ps:^string;
begin
    result := -1;
    if (wCount=l_MAX_KEYS_COUNT)or(not IsValidName(sName)) then    exit;
    if (lType<>l_VT_INTEGER)and(lType<>l_VT_STRING) then           exit;
    //name exists?
    if IndexOfKey(sName)>=0 then exit;
    //so, add...
    SetLength(zKeys,wCount+1);
    try
        new(zKeys[wCount]);
    except
        exit;
    end;

    zKeys[wCount]^.sName := sName;

    zKeys[wCount]^.lType := lType;
    case lType of
        l_VT_INTEGER: begin
            try
                GetMem(zKeys[wCount]^.pValue,SizeOf(Integer));
            except
                exit;
            end;
            PInteger(zKeys[wCount]^.pValue)^ := PInteger(pValue)^;
        end;
        l_VT_STRING: begin
            try
                new(ps);
                //GetMem(zKeys[wCount]^.pValue,SizeOf(Pointer));
            except
                exit;
            end;
            //zKeys[wCount]^.pValue := ps;
            //PString(zKeys[wCount]^.pValue)^ := string(pValue);
            ps^ := string(pValue);
            zKeys[wCount]^.pValue := ps;
        end;
    end;
    zKeys[wCount]^.wIndex := wCount;
    result := wCount;
    inc(wCount);
end;

procedure TKeys.Clear;
begin
    pkLastKey := nil;
    while(wCount>0) do begin
        dec(wCount);
        DisposePKey(zKeys[wCount]);
    end;
end;

function TKeys.GetFormatedValue(Index: word): string;
//���������� ��������������� �������� � ���������
//���� (������� ��� ������ � ����)
var s:string;
begin
    if Index<wCount then begin
        case zKeys[Index]^.lType of
            l_VT_INTEGER:   result := IntToStr(PInteger(zKeys[Index]^.pValue)^);
            l_VT_STRING: begin
                s := Pstring(zKeys[Index]^.pValue)^;
                EscapeStr(s);
                result := s_STR+s+s_STR;
            end;
            else  result := '0';
        end;
    end else begin
        result := '0';
    end;
end;

function TKeys.GetFormatedValueOf(sName,sDefault:string):string;
//���������� ��������������� �������� � ���������
//���� (������� ��� ������ � ����)
var i:Integer;
begin
    i := IndexOfKey(sName);
    if i=-1 then
        result := sDefault
    else
        result := GetFormatedValue(i);
end;

function TKeys.GetKey(Index: word): PKey;
//���������� ���� ��� nil
begin
    if Index<wCount then
        result := zKeys[Index]
    else
        result := nil;
end;

function TKeys.GetValue(Index:word;pDefault:Pointer=nil):pointer;
//���������� ��������� �� �������� ��� ������
begin
    if Index<wCount then
        result := zKeys[Index]^.pValue
    else
        result := pDefault;
end;

function TKeys.GetValueOf(sName: string;pDefault:Pointer=nil): pointer;
//���������� ��������� �� �������� ��� ������
var i:Integer;
begin
    i := IndexOfKey(sName);
    if i>=0 then
        result := GetValue(i,pDefault)
    else
        result := pDefault;
end;

function TKeys.IndexOfKey(sKey:string):Integer;
//���������� ������ ����� ��� -1 ���� ������ ���
//���� ���� ������, �� ���������� ���
var i:Integer;
begin
    sKey := UpperCase(sKey);
    if pkLastKey<>nil then //���� ��������
        if UpperCase(pkLastKey^.sName)=sKey then begin //���� ��� ��� ��
            i := pkLastKey^.wIndex;                    //���������
            if IsValidIndex(i) then begin              //�� �������
                if UpperCase(zKeys[i]^.sName)=sKey then begin //�� �� ���
                    result := i;                       //��. ������.
                    exit;
                end else
                    pkLastKey := nil;    //�-�-�, �������� ��������
            end else begin
                pkLastKey := nil;  //�-�-�, �������� ��������
            end;
        end //else �������� ������. �����.
    ;
    i := 0;
    result := -1;
    while(i<wCount) do begin
        if UpperCase(zKeys[i]^.sName)=sKey then begin //������
            pkLastKey := zKeys[i];             //����������
            result := i;
            exit;
        end;
        inc(i);
    end;
    //� ���� �� ������, �� � �� ������� ����������
end;

function TKeys.IsValidIndex(Index: Integer): boolean;
//��������� ������ �� ������������
begin
    result := (Index>=0)and(Index<wCount);
end;

function TKeys.Remove(Index: word): boolean;
//������� ����. ���� �� ��������, �� ������ ���������� �����
var i,L:word;
    tmpKey:PKey;
begin
    if Index>=wCount then begin
        result := false;
        exit;
    end;
    if pkLastKey<>nil then
        if pkLastKey^.wIndex=Index then
            pkLastKey := nil;
    L := wCount-1;  //last
    tmpKey := zKeys[Index];
    if (Index<L) then begin  //if not last  then shift
        for i := Index to L-1 do begin
            zKeys[i] := zKeys[i+1];
            zKeys[i]^.wIndex := i;
        end;
        zKeys[L] := nil;
    end; //else Index==L
    {if pkLastKey<>nil then begin
        if pkLastKey^.wIndex>Index then
            dec(pkLastKey^.wIndex);
    end;}
    DisposePKey(tmpKey);
    dec(wCount);
    SetLength(zKeys,wCount);
    result := true;
end;

function TKeys.SetValue(Index: word; pValue: pointer; lType:Cardinal):boolean;
//������������� ����� ����� ��������
var ps:^string;
    f:boolean;
begin
    result := false;
    if (Index>=wCount)or
       (lType<>l_VT_INTEGER)and(lType<>l_VT_STRING) then begin
        exit;
    end;
    f := zKeys[Index]^.lType<>lType;
    //if types different then reallocate memory
    if f then begin
        case zKeys[Index]^.lType of
            l_VT_INTEGER: begin
                FreeMem(zKeys[Index]^.pValue,SizeOf(Integer));
            end;
            l_VT_STRING: begin
                ps := zKeys[Index]^.pValue;
                ps^ := '';
                dispose(ps);
                //FreeMem(zKeys[Index]^.pValue,SizeOf(Pointer));
            end;
        end;
    end;
    case lType of
        l_VT_INTEGER: begin
            if f then begin
                try
                    GetMem(zKeys[Index]^.pValue,SizeOf(Integer));
                except
                    exit;
                end;
            end;
            PInteger(zKeys[Index]^.pValue)^ := PInteger(pValue)^;
        end;
        l_VT_STRING: begin
            if f then begin
                try
                    new(ps);
                    //GetMem(zKeys[Index]^.pValue,SizeOf(Pointer));
                except
                    exit;
                end;
                zKeys[Index]^.pValue := ps;
            end;
            PString(zKeys[Index]^.pValue)^ := string(pValue);
        end;
    end;
    if f then  zKeys[Index]^.lType := lType;
    result := true;
end;

function TKeys.SetValueOf(sName:string; pValue:pointer; lType:Cardinal):boolean;
//������������� ����� ����� ��������
var i:Integer;
begin
    i := IndexOfKey(sName);
    if i>=0 then
        result := SetValue(i,pValue,lType)
    else
        result := false;
end;
////////////////////////////////////////
// End TKeys
////////////////////////////////////////


////////////////////////////////////////
// TSection
////////////////////////////////////////
constructor TSection.Create(AName: string);
begin
    inherited Create();
    SetName(AName);
    zSections := TSections.Create();
    zSections.Parent := self;
    kKeys := TKeys.Create();
end;

destructor TSection.Destroy;
begin
    //zSections.Clear();
    zSections.Parent := nil;
    zSections.Free();
    zSections := nil;
    //kKeys.Clear();
    kKeys.Free();
    kKeys := nil;
    inherited;
end;

function TSection.EnumAll(bLevel: byte): string;
//����������� ���� ���, ������, ��� ����� �� ���������� � �����
//� �������� bLevel 
var
{$IFNDEF COMPACT_SAVE}
    sI0,sI1:string;
{$ENDIF}
    i:word;
begin
{$IFDEF COMPACT_SAVE}
    result := s_SEC_LT+sName+s_SEC_RT+s_SEC_BEGIN
            + zSections.EnumAll(bLevel+1);
    if kKeys.Count>0 then
        for i := 0 to kKeys.Count-1 do begin
            result := result+kKeys[i].sName+s_EQUAL+kKeys.GetFormatedValue(i)+s_KV_TERM;
        end
    ;
    result := result+s_SEC_END;
{$ELSE}
    sI0 := IndentStr(bLevel); //  [Section]
    sI1 := sI0+s_INDENT;      //    Key=Value
    result := sI0+s_SEC_LT+ sName +s_SEC_RT+s_SEC_BEGIN+#13#10
            + zSections.EnumAll(bLevel+1);
    if kKeys.Count>0 then
        for i := 0 to kKeys.Count-1 do begin
            result := result+sI1+kKeys[i].sName+' '+s_EQUAL+' '+kKeys.GetFormatedValue(i)+s_KV_TERM+#13#10;
        end
    ;
    result := result+sI0+s_SEC_END+#13#10;
{$ENDIF}
end;

procedure TSection.SetName(Value: string);
//������������� ����� ���
//!!! ��� �������� �� ������� ������ �� ����� � ������������ TSections
begin
    if not IsValidName(Value) then exit;
    sName := Value; //UpperCase(Value);
end;

////////////////////////////////////////
// End TSection
////////////////////////////////////////


////////////////////////////////////////
// TSections
////////////////////////////////////////
constructor TSections.Create;
begin
    inherited;
    //Clear();
    wCount := 0;
    SetLength(Secs,0);
    zParentSec := nil;
    zLastSec := nil;
end;

destructor TSections.Destroy;
begin
    Clear();
    inherited;
end;

function TSections.Add(AName: string): Integer;
//��������� ������ � ���������� �� ������
//���� �� ������� ��������, �� ���������� (-1)
begin
    result := -1;
    if wCount=l_MAX_SECS_COUNT then exit;
    //AName := UpperCase(AName);
    if not IsValidName(AName) then exit;
    if IndexOfSection(AName)>=0 then exit;
    inc(wCount);
    SetLength(Secs,wCount);
    Secs[wCount-1] := TSection.Create(AName);
    Secs[wCount-1].Parent := self.Parent;
    result := wCount-1;
end;

procedure TSections.Clear;
//������� ��� ������ 
begin
    while wCount>0 do begin
        dec(wCount);
        Secs[wCount].Free();
        Secs[wCount] := nil;
    end;
    SetLength(Secs,0);
    zLastSec := nil;
end;

function TSections.EnumAll(bLevel: byte): string;
//����������� ��� ������ � �������� bLevel
var i:word;
begin
    result := '';
    if wCount>0 then begin
        for i := 0 to wCount-1 do begin
            result := result+Secs[i].EnumAll(bLevel);
        end;
    end;
end;

function TSections.GetSec(Index: word): TSection;
//���������� ������ �� �������
begin
    result := nil;
    if not IsValidIndex(Index) then exit;
    result := Secs[Index];
end;

function TSections.IndexOfSection(sSec: string): Integer;
//���������� ������ ������ �� �����
//���� ��� �����, �� (-1)
var i:word;
begin
    result := -1;
    if not IsValidName(sSec) then exit;
    if wCount=0 then exit;
    sSec := UpperCase(sSec);

    if assigned(zLastSec) then begin
        if UpperCase(zLastSec.sName)=sSec then begin
            if IsValidIndex(zLastSec.lIndex) then begin
                if UpperCase(Secs[zLastSec.lIndex].Name)=sSec then begin
                    result := zLastSec.lIndex;
                    exit;
                end else begin
                    zLastSec := nil;
                end;
            end else begin
                zLastSec := nil;
            end;
        end;
    end;

    i := 0;
    while i<wCount do begin
        if UpperCase(Secs[i].sName)=sSec then begin
            result := i;
            zLastSec := Secs[i];
            break;
        end;
        inc(i);
    end;
end;

function TSections.IsValidIndex(Index: Integer): boolean;
//���������� �� ������ Index
begin
    result := (Index>=0)and(Index<wCount);
end;

function TSections.Remove(Index: word): boolean;
//������� ������ �� ������� � ��������� true
//���� �� �������, �� ���������� ����� false
var i,L:Word;
begin
    result := true;
    if not IsValidIndex(Index) then exit;
    Secs[Index].Free();
    Secs[Index] := nil;

    if (zLastSec<>nil)and(zLastSec.lIndex=Index) then begin
        zLastSec := nil;
    end;

    L := wCount-1;
    if Index<L then begin
        {Secs[Index] := Secs[wCount-1];
        Secs[wCount-1] := nil;
        if lLastSec=bCount-1 then begin
            lLastSec := Index;
        end;}
        for i := Index to L-1 do begin
            Secs[i] := Secs[i+1];
            Secs[i].lIndex := i;
        end;
        Secs[L] := nil;
        {if (zLastSec<>nil)and(zLastSec.lIndex>Index) then
            dec(zLastSec.lIndex);}
    end;
    dec(wCount);
    SetLength(Secs,wCount);
    result := true;
end;

////////////////////////////////////////
// End TSections
////////////////////////////////////////


////////////////////////////////////////
// TIni
////////////////////////////////////////
{$IFDEF TRACK_SYNTAX_ERROR}
procedure TIni.ClearError;
begin
    sParseError := '';
end;
{$ENDIF}

constructor TIni.Create(AFileName: string);
begin
    inherited Create();
    SetFileName(AFileName);
    zSections := TSections.Create();
    zSections.Parent := nil; //�.�. ��� �������� TIni
    FileComment := '';
end;

destructor TIni.Destroy;
begin
    zSections.Free(); //� ������������� ������� ����� �����������
    zSections := nil;
    inherited;
end;

function TIni.GetIntegerOfPath(sPath,sKey:string;lDefault:Integer):Integer;
//���� � ���� sPath ��������� ���� sName, ��
//  ���������� ��� ��������
//�����
//  ���������� lDefault
var sec:TSection;
begin
    sec := SectionOfPath(sPath);
    if sec=nil then
        result := lDefault
    else
        result := sec.Keys.GetInteger(sKey,lDefault);
end;

function TIni.GetStringOfPath(sPath, sKey, sDefault: string): string;
//���� � ���� sPath ��������� ���� sName, ��
//  ���������� ��� ��������
//�����
//  ���������� sDefault
var sec:TSection;
begin
    sec := SectionOfPath(sPath);
    if sec=nil then
        result := sDefault
    else
        result := sec.Keys.GetString(sKey,sDefault);
end;

function TIni.LoadFile: boolean;
//��������� ���� � ���������� true
//����� false
var zModeStack:TStack;
    lCurMode,lNewMode:Integer;
    tk1,tk2:PToken;
    sName,sValue:string;
    zCurSec,gkSection:TSection;
    zSecs :TSections;
    lIndex:Integer;
    zConsts:TConstList;
    zIncs:TIncStack;
    pIF :PIncFile;
begin
    zSections.Clear();
    result := false;
    sName := '';
    sValue := '';
    zCurSec := nil; //TIni
    gkSection := nil;
    zIncs := TIncStack.Create;
    pIF := NewIncFile(sFileName);
    if pIF=nil then begin  //if not LoadFromFile(sFileName,sTmp) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
        sParseError := 'Unable to read file';
{$ENDIF}
        exit;
    end;
    //zIncs.Push(pIF);
    //sTmp := StringReplace(sTmp, #0, ' ', [rfReplaceAll])+#0;
    //sStart := @sTmp[1];
    zConsts := TConstList.Create;
    zModeStack := TStack.Create;
    zModeStack.Push(l_PM_ROOT);
    new(tk1);
    new(tk2);
{$IFDEF TRACK_SYNTAX_ERROR}
    sParseError := '';
{$ENDIF}
    try //for using Abort;
        if not GetToken(pIF^.Start,tk1) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
            sParseError := 'Unknown symbol: '''+TokenToUser(tk1)+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
            Abort;
        end;
        if not CanTokenBeFirst(tk1) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
            sParseError := WhatExpected(nil,0)+' extected but '''+TokenToUser(tk1)+''' found (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
            Abort;
        end;
        if tk1^.Type_=l_TT_EOF then begin
            DisposeIncFile(pIF);
            pIF := zIncs.Pop();
            result := true;
            Abort;
        end;
        //parsing...
        repeat
            if not GetToken(pIF^.Start,tk2) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                sParseError := 'Unknown symbol: '''+TokenToUser(tk2)+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk2^.offset))+')';
{$ENDIF}
                Abort;
            end;
            if tk2^.Type_=l_TT_ERROR then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                sParseError := 'Syntax error: '''+TokenToUser(tk2)+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk2^.offset))+')';
{$ENDIF}
                Abort;
            end;
            lCurMode := zModeStack.Top;
            if not IsTokenExpected(tk1,tk2,lCurMode,lNewMode) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                sParseError := WhatExpected(tk1,lCurMode)+' expected but '''+TokenToUser(tk2)+''' found (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk2^.offset))+')';
{$ENDIF}
                Abort;
            end;
            case tk1^.Type_ of
                l_TT_BR_L: begin // [ -> name
                    //����������� ������ ->SectionName
                end;
                l_TT_BR_R: begin // ] -> {
                    //����������� ������ <-back
                end;
                l_TT_SC_L: begin // { -> [ name } ; #
                    if zCurSec=nil then
                        zSecs := self.Sections
                    else
                        zSecs := zCurSec.Sections;
                    lIndex := zSecs.Add(sName);
                    if lIndex=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                        sParseError := 'Unable to add section '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                        Abort;
                    end;
                    zCurSec := zSecs[lIndex];
                    //zSecs := nil;
                    sName := '';
                    //����������� ������ ->SectionIn
                end;
                l_TT_SC_R: begin // } -> [ eof name } ; #
                    zCurSec := zCurSec.Parent;
                    //����������� ������ <-back
                end;
                l_TT_NAME: begin // name
                    case lCurMode of
                        l_PM_SEC_NAME: begin  // �� [ �� ]
                            sName := tk1^.content; //SecName
                            if not IsValidName(sName) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                sParseError := 'Invalid name: '''+TokenToUser(tk1)+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                Abort;
                            end;
                        end;
                        l_PM_SEC_IN: begin  // �� { �� }
                            sName := tk1^.content; //KeyName
                            if not IsValidName(sName) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                sParseError := 'Invalid name: '''+TokenToUser(tk1)+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                Abort;
                            end;
                        end;
                        l_PM_GET_K: begin  // �� ! �� ;
                            if tk2^.Type_=l_TT_TERM then begin
                                lIndex := gkSection.Keys.IndexOfKey(tk1^.content);
                                if lIndex=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Key not found: '''+TokenToUser(tk1)+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                                //...
                                if zCurSec=nil then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Internal error in @1 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort; //���� �� �����
                                end;
                                case gkSection.Keys[lIndex].lType of
                                    l_VT_INTEGER: begin
                                        if zCurSec.Keys.Add(sName,gkSection.Keys[lIndex].pValue,gkSection.Keys[lIndex].lType)=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                            sParseError := 'Unable to add key: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                            Abort;
                                        end;
                                    end;
                                    l_VT_STRING: begin
                                        if zCurSec.Keys.Add(sName,PPointer(gkSection.Keys[lIndex].pValue)^,gkSection.Keys[lIndex].lType)=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                            sParseError := 'Unable to add key: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                            Abort;
                                        end;
                                    end;
                                end;
                                sName := '';
                                sValue := '';
                                gkSection := nil;
                                //����������� ������ <-back
                            end else begin
                                if gkSection=nil then begin
                                    lIndex := zSections.IndexOfSection(tk1^.content);
                                    if lIndex=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                        sParseError := 'Section not founded: '''+TokenToUser(tk1)+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                        Abort;
                                    end;
                                    gkSection := zSections[lIndex];
                                end else begin
                                    lIndex := gkSection.Sections.IndexOfSection(tk1^.content);
                                    if lIndex=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                        sParseError := 'Section not founded: '''+TokenToUser(tk1)+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                        Abort;
                                    end;
                                    gkSection := gkSection.Sections[lIndex];
                                end;
                                if gkSection=nil then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Internal error in @2 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                            end;
                        end;
                        l_PM_CMD: begin
                            case lCurCmd of
                                l_CMD_NO: begin
                                    if not IniEx2.SetCurCmd(tk1^.content) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                        sParseError := 'Unknown command '''+tk1^.content+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                        Abort;
                                    end;
                                    {case lCurCmd of
                                        l_CMD_SET,
                                        l_CMD_UNSET: begin
                                            ����� ������
                                        end;  � ��� ������ ������ ���� ����������
                                    end;}
                                end;
                                l_CMD_SET: begin // {set} name =
                                    sName := UpperCase(tk1^.content);
                                    if not(IsValidName(sName)) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                        sParseError := 'Invalid identifier: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                        Abort;
                                    end;
                                    //� ���
                                end;
                                l_CMD_UNSET: begin // {unset} name ;
                                    sName := UpperCase(tk1^.content);
                                    if not(IsValidName(sName)) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                        sParseError := 'Invalid identifier: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                        Abort;
                                    end;
                                    //������� sName
                                    lIndex := zConsts.IndexOf(sName);
                                    if lIndex=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                        sParseError := 'Const '''+sName+''' does not exists (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                        Abort;
                                    end;
                                    if not zConsts.Remove(lIndex) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                        sParseError := 'Unable to delete const: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                        Abort;
                                    end;
                                end;
                                (*l_CMD_INCLUDE: begin //{include} name _  - invalid syntax
                                    never will be here
                                end;*)
                                else begin // {_unknown_} name ...
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Unknown command '''+tk1^.content+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                            end;
                        end;
                        l_PM_GET_CONST: begin
                            lIndex := zConsts.IndexOf(tk1^.content);
                            if not zConsts.ValueOf(lIndex,sValue,Cardinal(lIndex)) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                sParseError := 'Const '''+tk1^.content+''' not found (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                Abort;
                            end;
                            if (lNewMode and l_PM_BACK_MASK)<>0 then begin
                                if zModeStack.Pop=0 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Internal error in @3 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                                lNewMode := lNewMode and not l_PM_BACK_MASK;
                                lCurMode := zModeStack.Top;
                            end;
                            case lIndex of
                                l_VT_INTEGER: begin
                                    if lCurMode=l_PM_CMD then begin
                                        if not zConsts.Add(sName,sValue,lIndex) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                            sParseError := 'Unable to add key: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                            Abort;
                                        end;
                                    end else {if lCurMode=l_PM_SEC_IN then} begin
                                        lIndex := StrToInt(sValue);
                                        if zCurSec.Keys.Add(sName,@lIndex,l_VT_INTEGER)=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                            sParseError := 'Unable to add key: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                            Abort;
                                        end;
                                    end;
                                end;
                                l_VT_STRING: begin
                                    if lCurMode=l_PM_CMD then begin
                                        if not zConsts.Add(sName,sValue,lIndex) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                            sParseError := 'Unable to add key: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                            Abort;
                                        end;
                                    end else {if lCurMode=l_PM_SEC_IN then} begin
                                        if zCurSec.Keys.Add(sName,Pointer(sValue),lIndex)=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                            sParseError := 'Unable to add key: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                            Abort;
                                        end;
                                    end;
                                end;
                            end;
                            if lCurMode=l_PM_CMD then begin
                                if zModeStack.Pop=0 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Internal error in @3 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                                //lCurMode := zModeStack.Top;
                            end;
                            sName := '';
                            sValue := '';
                        end;
                        else begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Unexpected name '''+TokenToUser(tk1)+''' in mode '''+IntToStr(lCurMode)+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort;
                        end;
                    end;
                end;
                {l_TT_CM_L: begin // /*
                end;
                l_TT_CM_R: begin //
                end;}
                l_TT_EQV: begin  // =
                    //������
                end;
                l_TT_NUM: begin  // 0 -> ;
                    sValue := tk1^.content;
                    if not IsValidInt(sValue,lIndex) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                        sParseError := 'Invalid integer: '''+sValue+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                        Abort;
                    end;
                    if (lCurMode=l_PM_SEC_IN) then begin
                        if zCurSec=nil then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Internal error in @4 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort; //���� �� �����
                        end;
                        if zCurSec.Keys.Add(sName,@lIndex,l_VT_INTEGER)=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Unable to add key: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort;
                        end;
                        sName := '';
                        sValue := '';
                    end else if (lCurMode=l_PM_CMD)and(lCurCmd=l_CMD_SET) then begin
                        sValue := IntToStr(lIndex);
                        //add const sName=sValue
                        if zConsts.IndexOf(sName)>=0 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Const '''+sName+''' already exists (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort;
                        end;
                        if not zConsts.Add(sName,sValue,l_VT_INTEGER) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Unable to add const: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort;
                        end;
                        sName := '';
                        sValue := '';
                    end else begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Internal error in @5 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort;
                    end;
                end;
                l_TT_STR: begin  // "..."
                    sValue := tk1^.content;
                    if (lCurMode=l_PM_SEC_IN) then begin
                        if zCurSec=nil then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Internal error in @6 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort; //���� �� �����
                        end;
                        if zCurSec.Keys.Add(sName,pointer(sValue),l_VT_STRING)=-1 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Unable to add key: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort;
                        end;
                        sName := '';
                        sValue := '';
                    end else if (lCurMode=l_PM_CMD) then begin
                        case lCurCmd of
                            l_CMD_SET: begin
                                //add const sName=sValue
                                if zConsts.IndexOf(sName)>=0 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Const '''+sName+''' already exists (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                                if not zConsts.Add(sName,sValue,l_VT_STRING) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Unable to add const: '''+sName+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                                sName := '';
                                sValue := '';
                            end;
                            l_CMD_INCLUDE: begin  //{include} "str" ;
                                sValue := AddPath(ExtractFileDir(pIF^.FileName),sValue);
                                if (sValue='')or
                                    not FileExists(sValue) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Unable to include file (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                                if zIncs.IsIncluded(sValue) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Include recursion detected (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                                if not zIncs.Push(pIF) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Too many include level (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                                pIF := NewIncFile(sValue);
                                if pIF=nil then begin
                                    pIF := zIncs.Pop();
{$IFDEF TRACK_SYNTAX_ERROR}
                                    sParseError := 'Unable to include file (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                    Abort;
                                end;
                            end;
                            else begin
{$IFDEF TRACK_SYNTAX_ERROR}
                                sParseError := 'Internal error in @7 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                                Abort;
                            end;
                        end;
                    end else begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Internal error in @8 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort;
                    end;
                end;
                l_TT_TERM: begin // ; #
                    //���� ����� Command, �� <-back
                end;
                l_TT_GK: begin   // !
                    gkSection := nil;
                    //������������ ������ ->GetKey
                end;
                l_TT_GK_DEL: begin // .
                    if gkSection=nil then
                        gkSection := zCurSec;
                end;
                l_TT_GK_PAR: begin // ^
                    gkSection := gkSection.Parent;
                    if gkSection=nil then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                        sParseError := 'Section has no parent (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                        Abort; //����� ���� �����
                    end;
                end;
                l_TT_CMD: begin // # -> name
                    //������������ � ����� -> Command
                    lCurCmd := l_CMD_NO;
                    if tk2^.Type_=l_TT_NAME then begin
                        tk2^.content := UpperCase(tk2^.content);
                        if (tk2^.content<>s_CMD_SET)and
                           (tk2^.content<>s_CMD_UNSET)and
                           (tk2^.content<>s_CMD_INCLUDE) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Unknown command '''+tk2^.content+''' (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort;
                        end;
                    end else begin; //else �� ������ ����
{$IFDEF TRACK_SYNTAX_ERROR}
                        sParseError := 'Internal error in @9 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                        Abort;
                    end;
                end;
                l_TT_EOF: begin // eof
                    if zIncs.IsEmpty then begin
                        if lCurMode=l_PM_ROOT then begin
                            //end.
                            result := true;
                        end else begin  //����������� ����� ����� �� ����� ������� ������
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Unextected EndOfFile (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                        end;
                        DisposeIncFile(pIF);
                        Abort;
                    end else begin
                        DisposeIncFile(pIF);
                        pIF := zIncs.Pop();
                        if pIF=nil then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                            sParseError := 'Internal error in @10 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                            Abort;
                        end;
                        tk2^.Type_ := l_TT_TERM;
                        tk2^.content := ';';
                    end;
                end;
            end;
            if (lNewMode and l_PM_BACK_MASK)<>0 then begin
                if zModeStack.Pop=0 then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                    sParseError := 'Internal error in @11 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                    Abort;
                end;
                lNewMode := lNewMode and not l_PM_BACK_MASK;
            end;
           (* if (lNewMode and l_PM_BACK2_MASK)<>0 then begin
                if (zModeStack.Pop()=0)or(zModeStack.Pop()=0) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                    sParseError := 'Internal error in @12 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                    Abort;
                end;
                lNewMode := lNewMode and not l_PM_BACK2_MASK;
            end;                  *)
            if lNewMode<>0 then
                if not zModeStack.Push(lNewMode) then begin
{$IFDEF TRACK_SYNTAX_ERROR}
                    sParseError := 'Internal error in @13 (file: "'+pIF^.FileName+'" at line: '+IntToStr(GetLineNumber(@pIF^.Content[1],tk1^.offset))+')';
{$ENDIF}
                    Abort;
                end
            ;
            lIndex := Integer(tk1);
            tk1 := tk2;
            tk2 := Pointer(lIndex);
        until false; //exit by Abort
    except
        //
    end;
    dispose(tk2);
    dispose(tk1);
    zIncs.Free;
    zConsts.Free;
    zModeStack.Free;
    if not result then zSections.Clear;
end;

function TIni.SaveFile: boolean;
//�������������� � ���� ��� ���������� � ���������� true
//����� false
var sTmp:string;
begin
    sTmp := zSections.EnumAll(0);
    if FileComment<>'' then      //StringReplace(AText, AFromText, AToText, [rfReplaceAll]);
        sTmp :=
{$IFDEF FILE_COMMENT_MULTILINE}
                s_COM_START+' '
                +StringReplace(FileComment,s_COM_END,s_COMMENT, [rfReplaceAll])+' '+s_COM_END
{$ELSE}
                s_COMMENT+s_COMMENT
                +StringReplace(FileComment,#13#10,#13#10+s_COMMENT+s_COMMENT, [rfReplaceAll])
{$ENDIF}
                +#13#10+sTmp;
    result := SaveToFile(sFileName,sTmp);
end;

function TIni.SectionOfPath(sPath: string): TSection;
//���������� ������ �� ���������� ����
//��� nil
var sArr:TStrArray;
    L:Integer;
    i,k:Integer;
    zCurSecs:TSections;
begin
    sArr := SplitStr(sPath,s_PATH_D);
    L := High(sArr);
    zCurSecs := zSections;
    for i := 0 to L do begin
        k := zCurSecs.IndexOfSection(sArr[i]);
        if k=-1 then begin //���� �� ������
            result := nil;
            exit;
        end;
        zCurSecs := zCurSecs[k].Sections;
    end;
    result := zCurSecs.Parent;
end;

procedure TIni.SetFileName(AFileName: string);
//������������� ����� ��� �����
//!!!������ �� ���������!
begin
    sFileName := AFileName;
end;

function TIni.ValueOfPath(sPath, sKey:string; sDefault: pointer): pointer;
//���� ���������� ���� sPath � � ��� ���� sKey, ��
//  ���������� ��� ��������
//�����
//  ���������� sDefault
var zSec:TSection;
begin
    zSec := SectionOfPath(sPath);
    if zSec<>nil then begin
        result := zSec.Keys.GetValueOf(sKey,sDefault);
    end else begin
        result := sDefault;
    end;
end;

function TIni.ValueOfPathFormated(sPath,sKey,sDefault:string):string;
//���� ���������� ���� sPath � � ��� ���� sKey, ��
//  ���������� ��� ��������
//�����
//  ���������� sDefault
var zSec:TSection;
begin
    zSec := SectionOfPath(sPath);
    if zSec<>nil then begin
        result := zSec.Keys.GetFormatedValueOf(sKey,sDefault);
    end else begin
        result := sDefault;
    end;
end;
////////////////////////////////////////
// End TIni
////////////////////////////////////////


////////////////////////////////////////
// TStack
////////////////////////////////////////
procedure TStack.Clear;
//������� �����
begin
    SetLength(values,0);
    wCount := 0;
end;

constructor TStack.Create;
begin
    inherited;
    Clear();
end;

destructor TStack.Destroy;
begin
    Clear();
    inherited;
end;

function TStack.Pop: Integer;
//���������� � ������� � �������� (���� ���� �����, �� 0)
begin
    if wCount>0 then begin
        dec(wCount);
        result := values[wCount];
        SetLength(values,wCount);
    end else begin
        result := 0;
    end;
end;

function TStack.Push(L: Integer):boolean;
//������ � ����
//���� ���������� �� false � ���� ��������� �� true
begin
    result := wCount<l_STACK_MAX_COUNT;
    if result then begin
        inc(wCount);
        SetLength(values,wCount);
        values[wCount-1] := L;
    end;
end;

function TStack.Top: Integer;
//������ �������� � ������� (��� 0 ���� �����)
begin
    if (wCount>0) then
        result := values[wCount-1]
    else
        result := 0;
end;
////////////////////////////////////////
// End TStack
////////////////////////////////////////


////////////////////////////////////////
// TConstList
////////////////////////////////////////
constructor TConstList.Create;
begin
    inherited;
    SetLength(consts_,0);
    wCount := 0;
    zLastConst := nil;
end;

destructor TConstList.Destroy;
begin
    Clear();
    inherited;
end;

function TConstList.Add(sName, sValue: string; lType:cardinal): boolean;
//���������� ��������� � ������ sName ���� lType � ��������� sValue
begin
    result := false;
    if wCount=l_MAX_CONSTS_COUNT then exit;
    if (lType<>l_VT_INTEGER)and(lType<>l_VT_STRING) then exit;
    if sName='' then exit;
    sName := UpperCase(sName);
    if IndexOf(sName)>=0 then exit;

    SetLength(consts_,wCount+1);
    new(consts_[wCount]);
    consts_[wCount].Name := sName;
    consts_[wCount].Value := sValue;
    consts_[wCount].Type_ := lType;
    consts_[wCount].Index := wCount;
    result := true;
    inc(wCount);
end;

procedure TConstList.Clear;
//������� ������
begin
    while(wCount>0)do begin
        dec(wCount);
        consts_[wCount]^.Name := '';
        consts_[wCount]^.Value := '';
        dispose(consts_[wCount]);
    end;
    SetLength(consts_,0);
    zLastConst := nil;
end;

function TConstList.GetConst(lIndex: word): PConst;
//���� ������ ����������,
//  ���������� ��������� �� ���������
//�����
//  ���������� nil
begin
    if(lIndex<wCount) then
        result := consts_[lIndex]
    else
        result := nil;
end;

function TConstList.IndexOf(sName:string): Integer;
//���������� ������ ��������� � ������ sName ��� -1, ���� ����� ���
var i:word;
begin
    if sName='' then begin
        result := -1;
        exit;
    end;
    sName := UpperCase(sName);
    if zLastConst<>nil then begin
        if zLastConst^.Name=sName then begin
            if (zLastConst^.Index<wCount) then begin
                if consts_[zLastConst^.Index]^.Name=sName then begin
                    //��������� ���������
                    result := zLastConst^.Index;
                    exit;
                end else begin
                    //��������� ��� �����������
                    zLastConst := nil;
                end;
            end else begin
                //������ ��� ������������
                zLastConst := nil;
            end;
        end; //����� ��������� ������
    end;

    i := 0;
    while(i<wCount) do begin
        if(consts_[i]^.Name=sName)then begin
            result := i;
            zLastConst := consts_[i];
            exit;
        end;
        inc(i);
    end;
    result := -1;
end;

function TConstList.Remove(Index: word): boolean;
//�������� ��������� �� �� �������
var i:Integer;
begin
    result := false;
    if Index>=wCount then exit;
    //L := wCount-1;
    dec(wCount);
    if zLastConst<>nil then
        if zLastConst^.Index=Index then
            zLastConst := nil;
    consts_[Index].Name := '';
    consts_[Index].Value := '';
    dispose(consts_[Index]);
    if Index<wCount then begin
        for i := Index to wCount-1 do begin
            consts_[i] := consts_[i+1];
            consts_[i].Index := i;
        end;
        consts_[wCount] := nil;
    end;
    result := true;
end;

function TConstList.ValueOf(Index: Integer; var sValue: string; var lType:cardinal): boolean;
//���� ������ ����������, ��
//  � ���������� sValue ���������� ��������
//  � ���������� lType ���������� ���
//  ���������� true
//�����
//  ���������� false
begin
    result := (Index>=0)and(Index<wCount);
    if result then begin
        sValue := consts_[Index].Value;
        lType := consts_[Index].Type_;
    end;
end;
////////////////////////////////////////
// End TConstList
////////////////////////////////////////

////////////////////////////////////////
// TIncStack
////////////////////////////////////////
procedure TIncStack.Clear;
//������� �����
begin
    while(wCount>0)do begin
        dec(wCount);
        DisposeIncFile(values[wCount]);
    end;
    SetLength(values,0);
end;

constructor TIncStack.Create;
begin
    inherited;
    Clear();
end;

destructor TIncStack.Destroy;
begin
    Clear();
    inherited;
end;

function TIncStack.IsEmpty: boolean;
//��������� ���� �� ����
begin
    result := wCount=0;
end;

function TIncStack.IsIncluded(sFile: string): boolean;
//���� ���� � ������ sFile ��� ���� � �����, ��
//  ���������� true
//�����
//  ���������� false
var i:word;
begin
    sFile := UpperCase(sFile);
    result := false;
    if wCount>0 then begin
        for i := 0 to wCount-1 do begin
            if values[i]<>nil then begin
                if UpperCase(values[i]^.FileName)=sFile then begin
                    result := true;
                    exit;
                end;
            end;
        end;
    end;
end;

function TIncStack.Pop: PIncFile;
//���������� � ������� � �������� (���� ���� �����, �� nil)
begin
    if wCount>0 then begin
        dec(wCount);
        result := values[wCount];
        SetLength(values,wCount);
    end else begin
        result := nil;
    end;
end;

function TIncStack.Push(pIF:PIncFile):boolean;
//������ � ����
//���� ���������� �� false � ���� ��������� �� true
begin
    result := wCount<l_STACK_MAX_COUNT;
    if result then begin
        inc(wCount);
        SetLength(values,wCount);
        values[wCount-1] := pIF;
    end;
end;

function TIncStack.Top: PIncFile;
//������ �������� � ������� (��� 0 ���� �����)
begin
    if (wCount>0) then
        result := values[wCount-1]
    else
        result := nil;
end;
////////////////////////////////////////
// End TIncStack
////////////////////////////////////////

function TKeys.GetInteger(sName: string; lDefault: Integer): Integer;
//���� ���� sName ���������, ��
//  ���������� ��� ��������
//�����
//  ���������� lDefault
var s:string;
    i,L:integer;
    k:PKey;
begin
    i := IndexOfKey(sName);
    if i=-1 then
        result := lDefault
    else begin
        k := zKeys[i];
        case k^.lType of
            l_VT_INTEGER:
                if SetValueToVar(L,k^.pValue,k^.lType) then
                    result := L
                else
                    result := lDefault;
            l_VT_STRING:
                if SetValueToVar(s,k^.pValue,k^.lType) then begin
                    if not IsValidInt(s,result) then
                        result := lDefault;
                end else
                    result := lDefault;
            else result := lDefault;
        end;
    end;
end;

function TKeys.GetString(sName, sDefault: string): string;
//���� ���� sName ���������, ��
//  ���������� ��� ��������
//�����
//  ���������� sDefault
var s:string;
    i,L:integer;
    k:PKey;
begin
    i := IndexOfKey(sName);
    if i=-1 then
        result := sDefault
    else begin
        k := zKeys[i];
        case k^.lType of
            l_VT_INTEGER:
                if SetValueToVar(L,k^.pValue,k^.lType) then
                    result := IntToStr(L)
                else
                    result := sDefault;
            l_VT_STRING:
                if SetValueToVar(s,k^.pValue,k^.lType) then
                    SwapStr(result,s)
                else
                    result := sDefault;
            else result := sDefault;
        end;
    end;
end;

end.

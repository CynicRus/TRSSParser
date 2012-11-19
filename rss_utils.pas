unit rss_utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,DateUtils, HttpSend;

function NormalizeString( S:string): string;

function Eq(aValue1, aValue2: string): boolean;

function GetFile(URL: String): string;

function ReplaceStr(const S, Srch, Replace: string): string;

function convert(s:string): string;

function GetFeedFileName(s: string): string;

implementation

function NormalizeString( S:string): string;
begin
  result:=UTF8Decode(S);
end;

function Eq(aValue1, aValue2: string): boolean;
//--------------------------------------------------------
begin
  Result := AnsiCompareText(Trim(aValue1),Trim(aValue2))=0;
end;

function GetFile(URL: String): string;
var
  HTTP : THTTPSend;
begin;
  HTTP := THTTPSend.Create;

  HTTP.UserAgent := 'Mozilla 4.0/ (Synapse)';

  Result := '';
  try
    if HTTP.HTTPMethod('GET', URL) then
    begin
      SetLength(result,HTTP.Document.Size);
      HTTP.Document.Read(result[1],length(result));
    end;
  finally
    HTTP.Free;
  end;
end;

function ReplaceStr(const S, Srch, Replace: string): string;
var
  i: Integer;
  Source: string;
begin
  Source := S;
  Result := '';
  repeat
    i := Pos(UpperCase(Srch), UpperCase(Source));
    if i > 0 then
    begin
      Result := Result + Copy(Source, 1, i - 1) + Replace;
      Source := Copy(Source, i + Length(Srch), MaxInt);
    end
    else
      Result := Result + Source;
  until i <= 0;
end;

function convert(s:string): string;
var i:integer;
    s1: string;
begin
s1:='';
for i:=1 to length(s) do
  begin
   case s[i] of
    #128 : s1:=s1+#208#130;
    #129 : s1:=s1+#208#131;
    #130 : s1:=s1+#226#128#154;
    #131 : s1:=s1+#209#147;
    #132 : s1:=s1+#226#128#158;
    #133 : s1:=s1+#226#128#166;
    #134 : s1:=s1+#226#128#160;
    #135 : s1:=s1+#226#128#161;
    #136 : s1:=s1+#226#130#172;
    #137 : s1:=s1+#226#128#176;
    #138 : s1:=s1+#208#137;
    #139 : s1:=s1+#226#128#185;
    #140 : s1:=s1+#208#138;
    #141 : s1:=s1+#208#140;
    #142 : s1:=s1+#208#139;
    #143 : s1:=s1+#208#143;
    #144 : s1:=s1+#209#146;
    #145 : s1:=s1+#226#128#152;
    #146 : s1:=s1+#226#128#153;
    #147 : s1:=s1+#226#128#156;
    #148 : s1:=s1+#226#128#157;
    #149 : s1:=s1+#226#128#162;
    #150 : s1:=s1+#226#128#147;
    #151 : s1:=s1+#226#128#148;
    #152 : s1:=s1+'';
    #153 : s1:=s1+#226#132#162;
    #154 : s1:=s1+#209#153;
    #155 : s1:=s1+#226#128#186;
    #156 : s1:=s1+#209#154;
    #157 : s1:=s1+#209#156;
    #158 : s1:=s1+#209#155;
    #159 : s1:=s1+#209#159;
    #160 : s1:=s1+#194#160;
    #161 : s1:=s1+#208#142;
    #162 : s1:=s1+#209#158;
    #163 : s1:=s1+#208#136;
    #164 : s1:=s1+#194#164;
    #165 : s1:=s1+#210#144;
    #166 : s1:=s1+#194#166;
    #167 : s1:=s1+#194#167;
    #168 : s1:=s1+#208#129;
    #169,#171..#174,#176,#177,#181..#183,#187 : s1:=s1+#194+s[i];
    #170 : s1:=s1+#208#132;
    #175 : s1:=s1+#208#135;
    #178 : s1:=s1+#208#134;
    #179 : s1:=s1+#209#150;
    #180 : s1:=s1+#210#145;
    #184 : s1:=s1+#209#145;
    #185 : s1:=s1+#226#132#150;
    #186 : s1:=s1+#209#148;
    #188 : s1:=s1+#209#152;
    #189 : s1:=s1+#208#133;
    #190 : s1:=s1+#209#149;
    #191 : s1:=s1+#209#151;
    #192..#239 : s1:=s1+#208+chr(ord(s[i])-48);
    #240..#255 : s1:=s1+#209+chr(ord(s[i])-112);
   else s1:=s1+s[i];
  end;
end;
convert:=s1;
end;

function GetFeedFileName(s: string): string;
var
  c: char;
  i, k: Integer;
begin
  k := 0;
  SetLength(Result, Length(s));
  for i := 0 to Length(s) - 1 do
  begin
    c := s[i + 1];
    if c in [ 'a'..'z', 'A'..'Z' ] then
    begin
      Inc(k);
      Result[k] := c;
    end;
  end;
  SetLength(Result, k);
  result:=lowercase('\'+result+TimeToStr(Now)+'.rss');
end;

end.


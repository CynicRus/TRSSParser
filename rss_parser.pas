unit rss_parser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,Variants,FileUtil, DateUtils,HTTPDefs, XMLRead,XMLWrite,Dom, rss_types,rss_utils;

type

{ TRSSParser }

 TRSSParser = class(TRSSStorage)
  private
    function FetchNextToken(var s: string; space: string = ' '): string;
    function MonthToInt(MonthStr: string): Integer;
    function ParseRSSDate(DateStr: string): TDateTime;
    function GetNodeValue(aNode:TDOMNode;aTag: string):string;
    function DateTimeToGMT(const ADateTime: TDateTime): string;
  public
    procedure ParseRSSChannel(const RSSData: string);
    procedure SaveRSSChannels(const aPath: string);
    end;

implementation

{ TRSSParser }

function TRSSParser.FetchNextToken(var s: string; space: string): string;
var
  SpacePos: Integer;
begin
  SpacePos := Pos(space, s);
  if SpacePos = 0 then
  begin
    Result := s;
    s := '';
  end
  else
  begin
    Result := System.Copy(s, 1, SpacePos - 1);
    System.Delete(s, 1, SpacePos);
  end;
end;

function TRSSParser.MonthToInt(MonthStr: string): Integer;
const
  Months: array [1..12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
    'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
var
  M: Integer;
begin
  for M := 1 to 12 do
    if Months[M] = MonthStr then
      Exit(M);
  raise Exception.CreateFmt('Unknown month: %s', [MonthStr]);
end;

function TRSSParser.ParseRSSDate(DateStr: string): TDateTime;
var
  df: TFormatSettings;
  s: string;
  Day, Month, Year, Hour, Minute, Second: Integer;
begin
  s := DateStr;
  // Parsing date in this format: Mon, 11 Nov 2012 16:45:00 +0000
  try
    FetchNextToken(s);                          // Ignore "Mon, "
    Day := StrToInt(FetchNextToken(s));         // "11"
    Month := MonthToInt(FetchNextToken(s));     // "Nov"
    Year := StrToInt(FetchNextToken(s));        // "2012"
    Hour := StrToInt(FetchNextToken(s, ':'));   // "16"
    Minute := StrToInt(FetchNextToken(s, ':')); // "45"
    Second := StrToInt(FetchNextToken(s));      // "00"
    Result := EncodeDate(Year, Month, Day) + EncodeTime(Hour, Minute, Second, 0);
  except
    on E: Exception do
      raise Exception.CreateFmt('Can''t parse date "%s": %s',
        [DateStr, E.Message]);
  end;
end;

function TRSSParser.GetNodeValue(aNode: TDOMNode; aTag: string): string;
  var
  oNode: TDOMNode;
begin
  Result := '';
  if Assigned(ANode) then
  begin
    oNode := ANode.FindNode(DOMString(ATag));
    if Assigned(oNode) then
    begin
        Result := Convert(oNode.TextContent);
    end;
  end;
end;

function TRSSParser.DateTimeToGMT(const ADateTime: TDateTime): string;
var
  VYear, VMonth, VDay, VHour, VMinute, VSecond, M: Word;
begin
  DecodeDate(ADateTime, VYear, VMonth, VDay);
  DecodeTime(ADateTime, VHour, VMinute, VSecond, M);
  Result := Format('%s, %.2d %s %d %.2d:%.2d:%.2d GMT',
    [HTTPDays[DayOfWeek(ADateTime)], VDay, HTTPMonths[VMonth], VYear, VHour,
    VMinute, VSecond]);
end;

procedure TRSSParser.ParseRSSChannel(const RSSData: string);
      procedure DoLoadItems(aParentNode: TDOMNode; aRSSChannel: TRSSChannel);
           var
             oRSSItem: TRSSItem;
             oNode: TDOMNode;
             RSSItems: TDOMNodeList;
             i: integer;
           begin
              RssItems:=aParentNode.GetChildNodes;
              for i:=0 to RSSItems.Count-1 do
               begin
               oNode:=RssItems[i];
               if CompareStr(oNode.NodeName,'item') = 0 then
               begin
               oRSSItem:=aRSSChannel.RSSList.AddItem;
               oRSSItem.Title := GetNodeValue(oNode,'title');
               oRSSItem.Link  := GetNodeValue(oNode,'link');
               oRSSItem.Description   := GetNodeValue(oNode,'description');
               oRSSItem.PubDate   := ParseRssDate(GetNodeValue(oNode,'pubDate'));
               oRSSItem.Author := GetNodeValue(oNode,'author');
               oRSSItem.Category := GetNodeValue(oNode,'category');
               oRssItem.Guid := GetNodeValue(oNode,'guid');
               oRSSItem.Comments:= GetNodeValue(oNode,'comments');
               end;
            end;
           end;

           procedure DoLoadChannels(aNode: TDOMNode);
           var
             oNode: TDOMNode;
             oRSSChannel: TRSSChannel;
           begin
               oRSSChannel:=AddItem;
               oNode:=aNode;
               oRSSChannel.Title:=GetNodeValue(oNode,'title');
                oRSSChannel.Link:=GetNodeValue(oNode,'link');
               oRSSChannel.Description:=GetNodeValue(oNode,'description');
               oRSSChannel.Category:=GetNodeValue(oNode,'category');
               oRSSChannel.Copyright:=GetNodeValue(oNode,'copyright');
               oRSSChannel.LastBuildDate:=GetNodeValue(oNode,'lastBuildDate');
               oRSSChannel.Language:=GetNodeValue(oNode,'language'); ;
               DoLoadItems(oNode, oRSSChannel);
           end;
         var
           oXmlDocument: TXmlDocument;
            RSS: TStringStream;
             s,RssStr: string;
         begin
           oXMLDocument:=TXMLDocument.Create;
           RssStr:=RSSData;
           if not (pos('windows-1251',RssStr )=0) then
             begin
               s:=ReplaceStr(RssStr,'windows-1251','UTF-8');
               RssStr:=AnsiToUtf8(s);
             end;
           RSS:=TStringStream.Create(RssStr);
           RSS.Position:=0;
           ReadXMLFile(oXmlDocument,RSS);
           DoLoadChannels (oXmlDocument.DocumentElement.FindNode('channel'));
           FreeAndNil(oXmlDocument);
         end;

procedure TRSSParser.SaveRSSChannels(const aPath: string);
  procedure SaveChannel(Channel: TRSSChannel;aFilePath: string);
   var
     oXmlDocument: TXmlDocument;
     oRSS: TRSSItem;
      i: integer;
      vRoot,vFeed,vChannel,vRSSItem,vItem,vValue: TDomNode;
      RSSChannels: TDOMNodeList;
    begin

      oXmlDocument:=TXMLDocument.Create;
      vRoot:=oXmlDocument.CreateElement('rss');
      TDOMElement(vRoot).SetAttribute('version', '2.0');
      vFeed:=oXmlDocument.CreateElement('channel');
      if not eq(Channel.Title,'') then
         begin
           vChannel:=oXmlDocument.CreateElement('title');
           vValue:=oXmlDocument.CreateTextNode(SysToUTF8(Channel.Title));
           vChannel.AppendChild(vValue);
           vFeed.AppendChild(vChannel);
         end;
      if not eq(Channel.Link,'') then
         begin
           vChannel:=oXmlDocument.CreateElement('link');
           vValue:=oXmlDocument.CreateTextNode(SysToUTF8(Channel.Link));
           vChannel.AppendChild(vValue);
           vFeed.AppendChild(vChannel);
         end;
      if not eq(Channel.Description,'') then
         begin
           vChannel:=oXmlDocument.CreateElement('description');
           vValue:=oXmlDocument.CreateTextNode(SysToUTF8(Channel.Description));
           vChannel.AppendChild(vValue);
           vFeed.AppendChild(vChannel);
         end;
       if not eq(Channel.Category,'') then
         begin
           vChannel:=oXmlDocument.CreateElement('category');
           vValue:=oXmlDocument.CreateTextNode(SysToUTF8(Channel.Category));
           vChannel.AppendChild(vValue);
           vFeed.AppendChild(vChannel);
         end;
       if not eq(Channel.Language,'') then
         begin
           vChannel:=oXmlDocument.CreateElement('language');
           vValue:=oXmlDocument.CreateTextNode(SysToUTF8(Channel.Language));
           vChannel.AppendChild(vValue);
           vFeed.AppendChild(vChannel);
         end;
       if not eq(Channel.Docs,'') then
         begin
           vChannel:=oXmlDocument.CreateElement('docs');
           vValue:=oXmlDocument.CreateTextNode(SysToUTF8(Channel.Docs));
           vChannel.AppendChild(vValue);
           vFeed.AppendChild(vChannel);
         end;
       if not eq(Channel.Copyright,'') then
         begin
           vChannel:=oXmlDocument.CreateElement('copyright');
           vValue:=oXmlDocument.CreateTextNode(SysToUTF8(Channel.Copyright));
           vChannel.AppendChild(vValue);
           vFeed.AppendChild(vChannel);
         end;
       if not eq(Channel.Webmaster,'') then
         begin
           vChannel:=oXmlDocument.CreateElement('webmaster');
           vValue:=oXmlDocument.CreateTextNode(SysToUTF8(Channel.Webmaster));
           vChannel.AppendChild(vValue);
           vFeed.AppendChild(vChannel);
         end;
        vChannel:=oXmlDocument.CreateElement('lastBuildDate');
        vValue:=oXmlDocument.CreateTextNode(DateTimeToGMT(Now));
        vChannel.AppendChild(vValue);
        vFeed.AppendChild(vChannel);
       for i:=0 to Channel.RSSList.Count-1 do
         begin
          oRSS:=Channel.RSSList[i];
           vRSSItem:=oXmlDocument.CreateElement('item');
           if not eq(oRSS.Title,'') then
             begin
               vItem:=oXmlDocument.CreateElement('title');
               vValue:=oXmlDocument.CreateTextNode(oRSS.Title);
               vItem.AppendChild(vValue);
               vRSSItem.AppendChild(vItem);
             end;
           if not eq(oRSS.Link,'') then
             begin
               vItem:=oXmlDocument.CreateElement('link');
               vValue:=oXmlDocument.CreateTextNode(oRSS.Link);
               vItem.AppendChild(vValue);
               vRSSItem.AppendChild(vItem);
             end;
           if not eq(oRSS.Description,'') then
             begin
               vItem:=oXmlDocument.CreateElement('description');
               vValue:=oXmlDocument.CreateTextNode(oRSS.Description);
               vItem.AppendChild(vValue);
               vRSSItem.AppendChild(vItem);
             end;
           if not eq(oRSS.Category,'') then
             begin
               vItem:=oXmlDocument.CreateElement('category');
               vValue:=oXmlDocument.CreateTextNode(oRSS.Category);
               vItem.AppendChild(vValue);
               vRSSItem.AppendChild(vItem);
             end;
           if not eq(oRSS.Author,'') then
             begin
               vItem:=oXmlDocument.CreateElement('author');
               vValue:=oXmlDocument.CreateTextNode(oRSS.Author);
               vItem.AppendChild(vValue);
               vRSSItem.AppendChild(vItem);
             end;
           if not eq(oRSS.Guid,'') then
             begin
               vItem:=oXmlDocument.CreateElement('guid');
               vValue:=oXmlDocument.CreateTextNode(oRSS.Guid);
               vItem.AppendChild(vValue);
               vRSSItem.AppendChild(vItem);
             end;
             vItem:=oXmlDocument.CreateElement('pubDate');
             vValue:=oXmlDocument.CreateTextNode(DateTimeToGMT(now));
             vItem.AppendChild(vValue);
             vRSSItem.AppendChild(vItem);
           vFeed.AppendChild(vRSSItem);
         end;
        vRoot.AppendChild(vFeed);
        oXmlDocument.AppendChild(vRoot);
        writeXMLFile(oXMLDocument,aPath+GetFeedFileName(Channel.Title+DateTimeToStr(now)));
      end;
var
   i: integer;
begin
   for i:=0 to Count -1 do
     begin
       SaveChannel(Items[i],aPath);
     end;
end;



end.


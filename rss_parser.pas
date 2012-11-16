unit rss_parser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,Variants, DateUtils, XMLRead,XMLWrite,Dom, rss_types;

type

{ TRSSParser }

 TRSSParser = class(TRSSStorage)
  private
    function FetchNextToken(var s: string; space: string = ' '): string;
    function MonthToInt(MonthStr: string): Integer;
    function ParseRSSDate(DateStr: string): TDateTime;
  public
    procedure ParseRSSChannel(const RSSData: TStream);
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

procedure TRSSParser.ParseRSSChannel(const RSSData: TStream);
      procedure DoLoadItems(aParentNode: TDOMNode; aRSSChannel: TRSSChannel);
           var
             I,j: Integer;
             oRSSItem: TRSSItem;
             oNode: TDOMNode;
             RSSItems: TDOMNodeList;
             s: string;
           begin
              RssItems:=aParentNode.GetChildNodes;
              j:=RSSItems.Count;
              for i:=0 to RSSItems.Count-1 do
               begin
               oNode:=RssItems[i];
               if CompareStr(oNode.NodeName,'item') = 0 then
               begin
               oRSSItem:=aRSSChannel.RSSList.AddItem;
               oRSSItem.Title:= VarToStr(oNode.FindNode('title').FirstChild.NodeValue);
               oRSSItem.Link  := VarToStr(oNode.findnode('link').FirstChild.NodeValue);
               oRSSItem.Description   := VarToStr(oNode.findnode('description').FirstChild.NodeValue);
               oRSSItem.PubDate   := ParseRSSDate(VarToStr(oNode.findnode('pubDate').FirstChild.NodeValue));
               end;
            end;
           end;

           procedure DoLoadChannels(aNode: TDOMNode);
           var
             I: Integer;
             oNode: TDOMNode;
             oRSSChannel: TRSSChannel;
           begin
               oRSSChannel:=AddItem;
               oNode:=aNode;
               oRSSChannel.Title:= oNode.FindNode('title').FirstChild.NodeValue;
               oRSSChannel.Link:= oNode.FindNode('link').FirstChild.NodeValue;
               oRSSChannel.Description:=oNode.FindNode('description').FirstChild.NodeValue;
               DoLoadItems(oNode, oRSSChannel);
           end;
         var
           oXmlDocument: TXmlDocument;
         begin
           oXMLDocument:=TXMLDocument.Create;
           ReadXMLFile(oXmlDocument,RSSData);
           DoLoadChannels (oXmlDocument.DocumentElement.FindNode('channel'));
           FreeAndNil(oXmlDocument);
         end;



end.


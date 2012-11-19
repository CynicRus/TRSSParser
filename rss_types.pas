unit rss_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,rss_utils;

type

 { TRSSImage }

 TRSSImage = class
 public
    Link: string;
    Title: string;
    Url: string;
    constructor Create();
    destructor Destroy;
 end;

{ TRSSItem }

 TRSSItem = class(TCollectionItem)
  public
    PubDate: TDateTime;
    Link: String;
    Title: String;
    Description: String;
    Category: String;
    Guid: String;
    IsPermaLink: Boolean;
    Comments: String;
    Author: String;
    Image: TRssImage;
    constructor Create(Col: TCollection); override;
    destructor Destroy; override;
    end;

  { TRSSItemList }

  TRSSItemList = class(TCollection)
     function GetItems(Index: Integer): TRSSItem;
  public
    function AddItem: TRSSItem;
    function FindByTitle(aTitle: string): TRSSItem;
    constructor Create;

    property Items[Index: Integer]: TRSSItem read GetItems; default;
  end;

  {  TRSSChannel }

  TRSSChannel = class(TCollectionItem)
    public
    Description: String;
    Title:String;
    Link: String;
    Category: String;
    Copyright: String;
    Docs: String;
    Language: String;
    LastBuildDate: String;
    Webmaster: String;
    Image: TRSSImage;
    RSSList: TRSSItemList;
    constructor Create(Col: TCollection); override;
    destructor Destroy; override;
  end;

  { TRSSStorage }

  TRSSStorage = class(TCollection)
  private
  function GetItems(Index: Integer):  TRSSChannel;
  public
    function AddItem:  TRSSChannel;

    constructor Create;

    property Items[Index: Integer]:  TRSSChannel read GetItems; default;
  end;


implementation

{ TRSSImage }

constructor TRSSImage.Create;
begin

end;

destructor TRSSImage.Destroy;
begin

end;

{ TRSSStorage }

function TRSSStorage.GetItems(Index: Integer): TRSSChannel;
begin
  Result := TRSSChannel(inherited Items[Index]);
end;

function TRSSStorage.AddItem: TRSSChannel;
begin
   Result := TRSSChannel(inherited Add());
end;

constructor TRSSStorage.Create;
begin
   inherited Create(TRSSChannel);
end;

{ TRSSItemList }

function TRSSItemList.GetItems(Index: Integer): TRSSItem;
begin
   Result := TRSSItem(inherited Items[Index]);
end;

function TRSSItemList.AddItem: TRSSItem;
begin
   Result := TRSSItem(inherited Add());
end;

function TRSSItemList.FindByTitle(aTitle: string): TRSSItem;
var
  I: Integer;
begin
 Result := nil;
  for I := 0 to Count - 1 do
    if Eq(Items[i].Title, aTitle) then
    begin
      Result := Items[i];
      Break;
    end;
end;

constructor TRSSItemList.Create;
begin
   inherited Create(TRSSItem);
end;

{ TRSSItem }

constructor TRSSItem.Create(Col: TCollection);
begin
  inherited Create(Col);
end;

destructor TRSSItem.Destroy;
begin
  inherited Destroy;
end;

{ TRSSFeed }

constructor TRSSChannel.Create(Col: TCollection);
begin
  inherited Create(Col);
  RSSList:=TRSSItemList.Create;
end;

destructor TRSSChannel.Destroy;
begin
  inherited Destroy;
end;

end.


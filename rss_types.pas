unit rss_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,rss_utils;

type

{ TRSSItem }

 TRSSItem = class(TCollectionItem)
  public
    PubDate: TDateTime;
    Link: string;
    Title: string;
    Description: string;
    Category: string;
    Guid: string;
    IsPermaLink: Boolean;
    Comments: string;
    Author: string;
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
    Description: string;
    Title: string;
    Link: string;
    Category: string;
    Copyright: string;
    Docs: string;
    Language: string;
    LastBuildDate: string;
    Webmaster: string;
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


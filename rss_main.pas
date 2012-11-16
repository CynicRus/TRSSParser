unit rss_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  StdCtrls, ComCtrls,rss_parser,rss_types,rss_utils;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ListView1: TListView;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    TreeView1: TTreeView;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Click(Sender: TObject);
  private
    { private declarations }
  public
    procedure LoadChannelToListView(aChannel: TRSSChannel);
    procedure LoadToTreeView;
    { public declarations }
  end;

var
  Form1: TForm1;
  index: integer = 0;
  RSS: TRSSParser;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  RSS:=TRSSParser.Create;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  url: string;
  aRss: TStringStream;
  s,ss: string;
begin
 if InputQuery('Load RSS:', 'Insert RSS Feed address', url)
  then s:=GetFile(url) else exit;
//   ss:=ReplaceStr(s,'windows-1251','UTF-8');
  s:=convert(s);
  // m.SaveToFile('1.txt');
  aRss:=TStringStream.Create(s);
  aRss.Position:=0;
  RSS.ParseRSSChannel(aRss);
  LoadToTreeView();
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 if not assigned(RSS) then exit;
 if not (RSS.Count>0) then exit;
 RSS.Delete(index);
 if not (RSS.Count>0) then
  begin
    TreeView1.Items.Clear;
    ListView1.Items.Clear;
  end else LoadToTreeView;
end;

procedure TForm1.TreeView1Click(Sender: TObject);
begin
  if not (RSS.Count>0) then exit;
  if not assigned(TreeView1.Selected) then exit;
   // TreeView1.Items.Clear;
    index:=TreeView1.Selected.Index;
    LoadChannelToListView(RSS.Items[index]);
end;

procedure TForm1.LoadChannelToListView(aChannel: TRSSChannel);
var
  I: Integer;
  oListItem: TListItem;
begin
  ListView1.Items.Clear;
  for I := 0 to aChannel.RSSList.Count - 1 do
  begin
    oListItem:= ListView1.Items.Add;
    oListItem.Caption:=aChannel.RSSList[i].Title;
    oListItem.SubItems.Add(aChannel.RSSList[i].Link);
    oListItem.SubItems.Add(aChannel.RSSList[i].Description);
    oListItem.SubItems.Add(DateToStr(aChannel.RSSList[i].PubDate));
  end;
end;

procedure TForm1.LoadToTreeView;
var
  I: Integer;
begin
  TreeView1.Items.Clear;
  for I := 0 to RSS.Count - 1 do
  begin
    TreeView1.Items.Add(nil,RSS.Items[i].Title);
  end;
  LoadChannelToListView(RSS.Items[index]);
end;

end.


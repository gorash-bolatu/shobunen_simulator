unit Inventory;

interface

type
    Item = record
        name: string;
    end;// record end

procedure Save;
procedure Load;
procedure Reset;
procedure Cleanup;
function IsEmpty: boolean;
function Count: integer;
function Has(const it: Item): boolean;
function Find(itemname: string): Item;
procedure SilentObtain(const it: Item);
procedure Obtain(const it: Item);
procedure SilentUse(const it: Item);
procedure Use(const it: Item);
function GetNames: array of string;
procedure Output;

implementation

uses Procs, Tutorial;

var
    activeList: List<Item> := new List<Item>;
    savedList: List<Item>;

procedure Save() := if (activeList <> nil) then savedList := new List<Item>(activeList);

procedure Load() := if (savedList <> nil) then activeList := new List<Item>(savedList);

procedure Reset() := if (activeList <> nil) then activeList.Clear;

procedure Cleanup;
begin
    if (activeList <> nil) then
    begin
        activeList.Clear;
        activeList := nil;
    end;
    if (savedList <> nil) then
    begin
        savedList.Clear;
        savedList := nil;
    end
end;

function IsEmpty: boolean := (activeList.Count = 0);

function Count: integer := activeList.Count;

function Has(const it: Item): boolean := activeList.Contains(it);

function Find(itemname: string): Item := activeList.Find(it -> it.name = itemname);

procedure SilentObtain(const it: Item) := activeList.Add(it);

procedure Obtain(const it: Item);
begin
    activeList.Add(it);
    TxtClr(Color.Yellow);
    writeln($'ПОЛУЧЕНО: {it.name}.');
    BeepAsync(700, 220);
    sleep(400);
    if not Tutorial.InventoryH.Shown then
    begin
        Tutorial.Comment('список полученных предметов - по команде "проверить инвентарь"');
        Tutorial.InventoryH.Show;
    end;
    TxtClr(Color.White);
end;

procedure SilentUse(const it: Item) := activeList.Remove(it);

procedure Use(const it: Item);
begin
    activeList.Remove(it);
    TxtClr(Color.Yellow);
    writeln($'ИСПОЛЬЗОВАНО: {it.name}.');
    BeepAsync(500, 220);
    sleep(400);
    TxtClr(Color.White);
end;

function GetNames: array of string;
begin
    SetLength(Result, activeList.Count);
    for var r: integer := 0 to (activeList.Count - 1) do
        Result[r] := activeList[r].name;
end;

procedure Output;
begin
    TxtClr(Color.Yellow);
    if IsEmpty then writeln('Предметов нет.')
    else foreach s: string in GetNames do writeln('=== ' + s);
end;

initialization

finalization
    Cleanup;

end.
unit Inventory;

interface

uses Items;

/// сохранить состояние инвентаря
procedure Save;
/// загрузить последнее сохраненное состояние инвентаря
procedure Load;
/// очистить инвентарь
procedure Reset;
/// количество предметов в инвентаре
function ItemCount: integer;
/// ноль ли предметов в инвентаре
function IsEmpty: boolean;
/// есть ли предмет it в инвентаре
function Has(const it: Item): boolean;
/// добавить в инвентарь без вывода сообщения
procedure SilentObtain(const it: Item);
/// получить предмет, добавить в инвентарь и вывести об этом сообщение
procedure Obtain(const it: Item);
/// удалить из инвентаря без вывода сообщения
procedure SilentUse(const it: Item);
/// использовать предмет, удалить из инвентаря и вывести об этом сообщение
procedure Use(const it: Item);
/// последовательной названий предметов в инвентаре
function GetItems: sequence of Item;
/// вывести список предметов в инвентаре
procedure Output;

implementation

uses Procs, Tutorial;

var
    current, saved: HashSet<Item>;

procedure Save := saved := new HashSet<Item>(current);

procedure Load := current := new HashSet<Item>(saved);

procedure Reset := current.Clear;

function ItemCount: integer := current.Count;

function IsEmpty: boolean := (current.Count = 0);

function Has(const it: Item): boolean := current.Contains(it);

procedure SilentObtain(const it: Item) := current.Add(it);

procedure Obtain(const it: Item);
begin
    current.Add(it);
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

procedure SilentUse(const it: Item) := current.Remove(it);

procedure Use(const it: Item);
begin
    current.Remove(it);
    TxtClr(Color.Yellow);
    writeln($'ИСПОЛЬЗОВАНО: {it.name}.');
    BeepAsync(500, 220);
    sleep(400);
    TxtClr(Color.White);
end;

function GetItems: sequence of Item := current.AsEnumerable;

procedure Output;
begin
    TxtClr(Color.Yellow);
    if IsEmpty then writeln('Предметов нет.')
    else foreach s: string in current.Select(q -> q.name) do println('===', s);
end;

initialization
    current := new HashSet<Item>;
    saved := new HashSet<Item>(0);

finalization
    if (current <> nil) then
    begin
        current.Clear;
        current := nil;
    end;
    if (saved <> nil) then
    begin
        saved.Clear;
        saved := nil;
    end;

end. 
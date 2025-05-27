unit Inventories;

interface

type
    Item = record
        name: string;
    end;// record end
    
    Inventory = class
    private
        current: HashSet<Item> := new HashSet<Item>;
        saved: HashSet<Item>;
    public
        /// инициализировать инвентарь как текущий
        procedure Use;
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
        function GetNames: sequence of string;
        /// вывести список предметов в инвентаре
        procedure Output;
        constructor Create;
        destructor Destroy;
    end;
// type end

var
    Active: Inventory := new Inventory;

implementation

uses Procs, Tutorial;

var
    ListOfAllInvs: List<Inventory> := new List<Inventory>;

procedure Inventory.Use := Active := self;

procedure Inventory.Save := if (self.current <> nil) then self.saved := new HashSet<Item>(self.current);

procedure Inventory.Load := if (self.saved <> nil) then self.current := new HashSet<Item>(self.saved);

procedure Inventory.Reset := if (self.current <> nil) then self.current.Clear;

function Inventory.ItemCount: integer := self.current.Count;

function Inventory.IsEmpty: boolean := (self.current.Count = 0);

function Inventory.Has(const it: Item): boolean := self.current.Contains(it);

procedure Inventory.SilentObtain(const it: Item) := self.current.Add(it);

procedure Inventory.Obtain(const it: Item);
begin
    self.current.Add(it);
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

procedure Inventory.SilentUse(const it: Item) := self.current.Remove(it);

procedure Inventory.Use(const it: Item);
begin
    self.current.Remove(it);
    TxtClr(Color.Yellow);
    writeln($'ИСПОЛЬЗОВАНО: {it.name}.');
    BeepAsync(500, 220);
    sleep(400);
    TxtClr(Color.White);
end;

function Inventory.GetNames: sequence of String := self.current.Select(q -> q.name);

procedure Inventory.Output;
begin
    TxtClr(Color.Yellow);
    if IsEmpty then writeln('Предметов нет.')
    else foreach s: string in self.GetNames do writeln('=== ' + s);
end;

constructor Inventory.Create := ListOfAllInvs.Add(self);

destructor Inventory.Destroy;
begin
    if (self.current <> nil) then
    begin
        self.current.Clear;
        self.current := nil;
    end;
    if (self.saved <> nil) then
    begin
        self.saved.Clear;
        self.saved := nil;
    end;
end;

initialization

finalization
    if (Active <> nil) then
    begin
        Active.Destroy;
        Active := nil;
    end;
    if (ListOfAllInvs = nil) then exit;
    foreach i: Inventory in ListOfAllInvs do i.Destroy;
    ListOfAllInvs.Clear;
    ListOfAllInvs := nil;

end. 
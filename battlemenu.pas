unit BattleMenu;

interface

uses Items;

type
    ActionEnum = (ATK, DEF, INV);

procedure Choose;
function LastChoice: ActionEnum;
function ChosenItem: Item?;



implementation

uses Cursor, Procs, Inventory, Menu;

var
    selectres: ActionEnum;
    itemres: Item?;

procedure ChooseItem;
const
    BACKARROW: string = '<--';
begin
    var opts := Inventory.GetItems.Select(q -> q.name).Prepend(BACKARROW);
    Menu.FastSelectSubmenu(opts.ToArray);    
    if (Menu.LastResult.Equals(BACKARROW)) then
        itemres := nil
    else
        itemres := Inventory.GetItems.First(q -> q.name.ToLower.Equals(Menu.LastResult));
end;

procedure Choose;
var
    loaded: boolean;
begin
    repeat
        Menu.Load('атаковать');
        Menu.Load('защищаться');
        if not Inventory.IsEmpty then Menu.Load('использовать предмет');
        Menu.UnloadSelect(loaded);
        case Menu.LastResult of
            'атаковать': selectres := ATK;
            'защищаться': selectres := DEF;
        else selectres := INV;
        end; // case end
        if (selectres = INV) then 
        begin
            ClearLines(4, True);
            ChooseItem;
            if not itemres.HasValue then
            begin
                Cursor.GoTop(-6);
                ClearLines(5, True);
                if not loaded then loaded := True;
                continue;
            end;
        end
        else itemres := nil;
    until True;
end;

function LastChoice: ActionEnum := selectres;

function ChosenItem: Item? := itemres;

end.
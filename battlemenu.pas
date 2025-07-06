unit BattleMenu;

interface

uses Items;

type
    ActionEnum = (ATK, DEF, SPE, INV);

procedure Choose(special_action: string := nil);
function LastChoice: ActionEnum;
function ChosenItem: Item?;



implementation

uses Procs, Cursor, Inventory, Draw;
uses _Log;

const
    ATTACK: string = 'атаковать';
    DEFEND: string = 'защищаться';
    USEITEM: string = 'использовать предмет';
    BACKARROW: string = '<--';
var
    selectres: ActionEnum;
    itemres: Item?;

function BuildCommands(const special: string): array of string;
var
    l: List<string>;
begin
    try
        l := new List<string>;
        l.Add(ATTACK);
        l.Add(DEFEND);
        if not NilOrEmpty(special) then l.Add(special);
        if not Inventory.IsEmpty then l.Add(USEITEM);
        Result := l.ToArray;
    finally
        if (l <> nil) then
        begin
            l.Clear;
            l := nil;
        end;
    end;
end;

function SubmenuSeq: sequence of string := Inventory.GetItems.Select(q -> q.name).Prepend(BACKARROW);

function Select(const special_action: string): ActionEnum;
const
    PROMPT: string = '>>> ';
var
    submenu: boolean := False;
    point: shortint;
    k: Key;
    o_p: string;
    _CMDS: array of string := BuildCommands(special_action);
    _ITMS: array of string := SubmenuSeq.ToArray;
begin
    writeln;
    repeat
        point := 0;
        TxtClr(Color.Gray);
        var options := submenu ? _ITMS : _CMDS;
        var cur_prompt := submenu ? (TAB + PROMPT) : PROMPT;
        UpdScr;
        foreach st: string in options do writeln(cur_prompt, st);
        Cursor.GoTop(-options.Length);
        repeat
            o_p := cur_prompt + options[point];
            Cursor.GoTop(+point);
            TxtClr(Color.Yellow);
            Draw.Text(o_p);
            ClrKeyBuffer;
            k := ReadKey;
            UpdScr;
            TxtClr(Color.Gray);
            Draw.Text(o_p);
            Cursor.GoTop(-point);
            case k of
                Key.Enter, Key.Tab, Key.Select, Key.Spacebar, Key.NumPad5: break;
                Key.UpArrow, Key.NumPad8, Key.W, Key.LeftArrow, Key.NumPad4, Key.A, Key.OemMinus: point -= 1;
                Key.DownArrow, Key.NumPad2, Key.S, Key.RightArrow, Key.NumPad6, Key.D, Key.OemPlus: point += 1;
            end; // case end
            if (point < 0) then point := (options.Length - 1) // underflow
            else if (point + 1 > options.Length) then point := 0; // overflow
        until False;
        if (submenu and (point = 0)) // "<--"
        or (not submenu and (point = options.Length - 1)) // "использовать предмет"
        then
        begin
            if submenu then
            begin
                ClearLines((options.Length + 1), True);
                Cursor.GoTop(-_CMDS.Length);
            end
            else Cursor.GoTop(+_CMDS.Length);
            submenu := not submenu;
            continue;
        end
        else ClearLines((options.Length + 1), True);
        TxtClr(Color.Gray);
        _Log.Log($'= меню: [{point}] {options[point]}');
        if not submenu then
        begin
            case options[point] of
                ATTACK: Result := ATK;
                DEFEND: Result := DEF;
            else Result := SPE;
            end; // case end
            write(o_p, NewLine);
            itemres := nil;
        end
        else if (point <> 0) then
        begin
            Result := INV;
            Cursor.GoTop(-_CMDS.Length);
            ClearLines((_CMDS.Length + 1), True);
            write(PROMPT, USEITEM, ': ');
            TxtClr(Color.DarkYellow);
            writeln('[', options[point], ']');
            itemres := Inventory.GetItems.First(q -> q.Name.Equals(options[point]));
        end;
    until True;
    writeln;
    TxtClr(Color.White);
end;

procedure Choose(special_action: string);
begin
    selectres := ComputeWithoutUpdScr(() -> Select(special_action));
end;

function LastChoice: ActionEnum := selectres;

function ChosenItem: Item? := itemres;

end.
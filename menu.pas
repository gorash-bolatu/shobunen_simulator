unit Menu;

interface

/// загрузить элемент в будущее меню выбора
procedure Load(element: string);
/// выгрузить элементы и выбрать строку из меню
procedure UnloadSelect;
/// выбрать строку из меню выбора из вариантов options
procedure FastSelect(params options: array of string);
/// последний сохранённый результат успешного выбора в меню
function LastResult: string;


implementation

uses Procs, Tutorial, Cursor, Draw, Inventory, Anim, _Settings;
uses _Log;

var
    menures: string;
    opt: List<string>;

function Select(const options: array of string): string;
const
    PROMPT: string = '>>> ';
var
    point: shortint;
    k: Key;
    o_c: byte;
    o_p: string;
begin
    o_c := options.Count;
    if DEBUGMODE then
        if o_c > 32 then
            raise new Exception('СЛИШКОМ МНОГО ОПЦИЙ ВЫБОРА')
        else if o_c = 0 then
            raise new Exception('НЕТ ПУНКТОВ ВЫБОРА ДЛЯ МЕНЮ');
    repeat
        point := 0;
        TxtClr(Color.Gray);
        UpdScr;
        foreach st: string in options do writeln(PROMPT, st);
        if not Tutorial.MenuH.Shown then
        begin
            Tutorial.Comment('перемещение стрелками или W/S, выбор на Enter или пробел');
            ClrKeyBuffer;
            ReadKey;
            ClearLine(True);
            Tutorial.MenuH.Show;
        end;
        Cursor.GoTop(-o_c);
        repeat
            o_p := PROMPT + options[point];
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
            if (point < 0) then point := (o_c - 1) // underflow
            else if (point + 1 > o_c) then point := 0; // overflow
        until False;
        ClearLines((o_c + 1), True);
        TxtClr(Color.Gray);
        writeln(o_p, NewLine);
        Result := options[point].ToLower;
        _Log.Log($'= меню: [{point}] {Result}');
        if Result.Equals('проверить инвентарь') then
        begin
            Inventory.Output;
            Anim.Next1;
            writeln;
            continue;
        end;
    until True;
    TxtClr(Color.White);
end;

procedure Load(element: string) := opt.Add(element);

procedure UnloadSelect;
begin
    Anim.Next3;
    menures := ComputeWithoutUpdScr(() -> Select(opt.ToArray));
    for var i: integer := 0 to (opt.Count - 1) do opt[i] := nil;
    opt.Clear;
end;

procedure FastSelect(params options: array of string);
begin
    Anim.Next3;
    menures := ComputeWithoutUpdScr(() -> Select(options));
end;

function LastResult: string := menures;

initialization
    opt := new List<string>;

finalization
    opt.Clear;
    opt := nil;

end.
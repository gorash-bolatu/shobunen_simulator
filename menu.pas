unit Menu;

interface

/// загрузить элемент в будущее меню выбора
procedure Load(element: string);
/// выгрузить элементы и выбрать строку из меню
procedure UnloadSelect(no_anim: boolean := False);
/// выбрать строку из меню выбора из вариантов options
procedure FastSelect(params options: array of string);
/// выбрать строку из меню выбора (в виде под-меню) из вариантов options
procedure FastSelectSubmenu(params options: array of string);
/// последний сохранённый результат успешного выбора в меню
function LastResult: string;



implementation

uses Procs, Tutorial, Cursor, Draw, Inventory, Anim, _Settings;
uses _Log;

var
    menures: string;
    opts: List<string>;

function Select(const options: LinkedList<string>; submenu: boolean): string;
var
    original_cur_top := Cursor.Top;
    prompt: string := submenu ? '> ' : '>>> ';
    k: Key;
    current: LinkedListNode<string> := options.First;
begin
    repeat
        if DEBUGMODE then
            if options.Count > 32 then
                raise new Exception('СЛИШКОМ МНОГО ОПЦИЙ ВЫБОРА')
            else if options.Count = 0 then
                raise new Exception('НЕТ ПУНКТОВ ВЫБОРА ДЛЯ МЕНЮ');
        TxtClr(Color.Gray);
        foreach st: string in options do writeln(PROMPT + st);
        if not Tutorial.MenuH.Shown then
        begin
            Tutorial.Comment('перемещение стрелками или W/S, выбор на Enter или пробел');
            ClrKeyBuffer;
            ReadKey;
            ClearLine(True);
            Tutorial.MenuH.Show;
        end;
        Cursor.GoTop(-options.Count);
        repeat
            UpdScr;
            var curstr := PROMPT + current.&Value;
            TxtClr(Color.Yellow);
            Draw.Text(curstr);
            ClrKeyBuffer;
            k := ReadKey;
            TxtClr(Color.Gray);
            Draw.Text(curstr);
            case k of
                {-} Key.Enter, Key.Tab, Key.Select, Key.Spacebar, Key.NumPad5: break;
                {-} Key.UpArrow, Key.NumPad8, Key.W, Key.LeftArrow, Key.NumPad4, Key.A, Key.OemMinus:
                    begin
                        if (current = options.First) // catch underflow
                        then begin
                            current := options.Last;
                            Cursor.GoTop(+options.Count - 1);
                        end
                        else begin
                            current := current.Previous;
                            Cursor.GoTop(-1);
                        end;
                    end;
                {-} Key.DownArrow, Key.NumPad2, Key.S, Key.RightArrow, Key.NumPad6, Key.D, Key.OemPlus:
                    begin
                        if (current = options.Last) // catch overflow
                        then begin
                            current := options.First;
                            Cursor.GoTop(-options.Count + 1);
                        end
                        else begin
                            current := current.Next;
                            Cursor.GoTop(+1);
                        end;
                    end;
            end; // case end
        until False;
        Cursor.SetTop(original_cur_top);
        ClearLines((options.Count + 1), True);
        TxtClr(Color.Gray);
        writeln(PROMPT, current.&Value, NewLine);
        Result := current.&Value.ToLower;
        _Log.Log($'= меню: [{options.ToArray.IndexOf(Result)}] {Result}');
        if Result.Equals('проверить инвентарь') then
        begin
            Inventory.Output;
            Anim.Next1;
            writeln;
            continue;
        end;
    until True;
    TxtClr(Color.White);
    current := nil;
end;

procedure Load(element: string) := opts.Add(element);

procedure UnloadSelect(no_anim: boolean);
begin
    if not no_anim then Anim.Next3;
    menures := ComputeWithoutUpdScr(() -> Select(opts.ToLinkedList, False));
    for var i: integer := 0 to (opts.Count - 1) do opts[i] := nil;
    opts.Clear;
end;

procedure FastSelect(params options: array of string);
begin
    Anim.Next3;
    menures := ComputeWithoutUpdScr(() -> Select(options.ToLinkedList, False));
end;

procedure FastSelectSubmenu(params options: array of string);
begin
    menures := ComputeWithoutUpdScr(() -> Select(options.ToLinkedList, True));
end;

function LastResult: string := menures;



initialization
    opts := new List<string>;

finalization
    opts.Clear;
    opts := nil;

end.
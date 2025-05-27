{$DEFINE DOOBUG} // todo
unit Menu;

interface

procedure Load(element: string);
function UnloadSelect: string;
function FastSelect(params options: array of string): string;



implementation

uses Procs, Tutorial, Cursor, Draw, Inventory, Anim;
uses _Log;

const
    PROMPT: string = '>>> ';
    BACKARROW: string = '<--';

var
    opt: List<string> := new List<string>;

function Select(const options: array of string): string;
var
    point: shortint;
    k: Key;
    o_c: byte;
    o_p: string;
begin
    repeat
        o_c := options.Count;
        {$IFDEF DOOBUG}
        if o_c > 32 then raise new Exception('СЛИШКОМ МНОГО ОПЦИЙ ВЫБОРА')
        else if o_c = 0 then raise new Exception('НЕТ ПУНКТОВ ВЫБОРА ДЛЯ МЕНЮ');
        {$ENDIF}
        point := 0;
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
        Cursor.GoTop(-o_c);
        repeat
            o_p := PROMPT + options[point];
            Cursor.GoTop(+point);
            TxtClr(Color.Yellow);
            Draw.Text(o_p);
            ClrKeyBuffer;
            k := ReadKey;
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
        if (options[0] = BACKARROW) and (point > 0) then Cursor.GoTop(-1);
        TxtClr(Color.Gray);
        writeln(((options[0] = BACKARROW) ? PROMPT : '> '), options[point], NewLine);
        Result := options[point].ToLower;
        _Log.Log($'= меню: [{point}] {Result}');
        case Result of
            {-} 'использовать предмет':
                begin
                    var l: List<string> := new List<string>;
                    l.Add(BACKARROW);
                    l.AddRange(Inventory.GetNames);
                    Result := Select(l.ToArray);
                    l.Clear;
                    l := nil;
                    if NilOrEmpty(Result) then ClearLines(Inventory.Count + 3, True)
                    else if (Result = BACKARROW) then
                    begin
                        Cursor.GoTop(-2);
                        ClearLine(False)
                    end
                    else begin
                        Cursor.GoTop(-1);
                        ClearLine(False);
                        writeln;
                        break;
                    end;
                end;
            {-} 'проверить инвентарь':
                begin
                    Inventory.Output;
                    Anim.Next1;
                    writeln;
                end;
        else break; // case else
        end; // case end    
    until False;
    TxtClr(Color.White);
end;

procedure Load(element: string) := opt.Add(element);

function UnloadSelect: string;
begin
    Anim.Next3;
    Result := ComputeWithoutUpdScr(() -> Select(opt.ToArray));
    for var i: integer := 0 to (opt.Count - 1) do opt[i] := nil;
    opt.Clear;
end;

function FastSelect(params options: array of string): string;
begin
    Anim.Next3;
    Result := ComputeWithoutUpdScr(() -> Select(options));
end;

initialization

finalization
    opt.Clear;
    opt := nil;

end.
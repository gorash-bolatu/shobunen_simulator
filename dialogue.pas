{$DEFINE DOOBUG} // todo
unit Dialogue;

interface

uses Procs;

procedure Close;
procedure Say(speaker: actor_enum; params phrases: array of string);
function BulletTime(speaker: actor_enum; params phrases: array of string): string;
procedure OraMuda;
procedure Echo;

implementation

uses Anim, Draw, Cursor;

var
    DialogueOpened: boolean;
    DialogueWidth, NameWidth: byte;
    BulletTimeMode: boolean;
    BulletTimeCaught: string := nil;

procedure Open(const speaker: actor_enum);
begin
    if DialogueOpened then writeln
    else begin
        Anim.Next3;
        DialogueOpened := True;
    end;
    TxtClr(Color.White);
    if (speaker = anon) then NameWidth := 5
    else NameWidth := (speaker.ToString.Length + 2);
    Draw.Box(NameWidth, 1);
    Cursor.GoTop(-2);
    Cursor.SetLeft(2);
    case speaker of
        Саня: TxtClr(Color.Magenta);
        Костыль, Агент_Сергеев: TxtClr(Color.Red);
    else TxtClr(Color.Green);
    end; // case end
    writeln((speaker = anon) ? '???' : speaker.ToString.Replace('_', ' '));
end;

procedure Close;
begin
    {$IFDEF DOOBUG}
    if not DialogueOpened then raise new Exception('ПОВТОРНЫЙ DIALOGUE.CLOSE()');
    {$ENDIF}
    DialogueOpened := False;
    writelnx2;
    TxtClr(Color.White);
    ClrKeyBuffer;
end;

procedure Say(speaker: actor_enum; params phrases: array of string);
begin
    if (phrases.Length = 0) then phrases := Arr('...');
    Open(speaker);
    var longest_phrase: string := phrases.MaxBy(q -> q.Length);
    DialogueWidth := longest_phrase.Length + 3;
    if BulletTimeMode then DialogueWidth -= 2;
            {$IFDEF DOOBUG}
    if (DialogueWidth + 3) > MIN_WIDTH then raise new Exception(
        'СЛИШКОМ БОЛЬШАЯ СТРОКА ДИАЛОГА: "' + longest_phrase + '" [' + longest_phrase.Length + '].');
            {$ENDIF}
    TxtClr(Color.White);
    if (DialogueWidth = NameWidth) then writeln('├', '─' * NameWidth, '┤')
    else if (DialogueWidth < NameWidth) then writeln('├', '─' * DialogueWidth, '┬', '─' * (NameWidth - DialogueWidth - 1), '┘')
    else writeln('├', '─' * NameWidth, '┴', '─' * (DialogueWidth - NameWidth - 1), '┐');
    foreach n: string in phrases do
    begin
        writeln('│', ' ' * DialogueWidth, '│');
        writeln('└', '─' * DialogueWidth, '┘');
        Cursor.GoTop(-2);
        Cursor.SetLeft(2);
        TxtClr(Color.Yellow);
        ClrKeyBuffer;
        if BulletTimeMode then
        begin
                    {$IFDEF DOOBUG}
            if (n.Count(q -> q = '{') > 2) or (n.Count(q -> q = '}') > 2) then
                raise new Exception('СЛИШКОМ МНОГО ФИГУРНЫХ СКОБОК {}: "' + n + '"')
            else if (n.Count(q -> q = '{') <> n.Count(q -> q = '}')) then
                raise new Exception('НЕЗАКРЫТЫЕ ФИГУРНЫЕ СКОБКИ {}: "' + n + '"');
                    {$ENDIF}
            for var c: integer := 1 to n.Length do
            begin
                if (c = n.IndexOf('{') + 1) then TxtClr(Color.Cyan)
                else if (c = n.LastIndexOf('}') + 1) then TxtClr(Color.Yellow)
                else write(n[c]);
                var time: word := (c = n.Length) ? 1000 : 35;
                if System.Threading.SpinWait.SpinUntil(() ->
                (KeyAvail and (ReadKey in [Key.Enter, Key.Tab, Key.Select, Key.Spacebar])), time) then
                begin
                    var highlighted: string := n[n.IndexOf('{') + 2:n.LastIndexOf('}') + 1:1];
                    if (n.Contains('{')) and (c > n.IndexOf('{')) then begin
                        Cursor.SetLeft(2);
                        TxtClr(Color.Yellow);
                        write(n.Left(n.IndexOf('{')));
                        TxtClr(Color.DarkCyan);
                        BgClr(Color.White);
                        write(highlighted);
                        TxtClr(Color.Yellow);
                        BgClr(Color.Black);
                        write(n.Substring(n.LastIndexOf('}') + 1));
                        BulletTimeCaught := highlighted;
                    end
                    else BulletTimeCaught := '';
                    break;
                end;
            end;
            writeln;
            if (BulletTimeCaught <> nil) then break;
        end
        else begin
                    {$IFDEF DOOBUG}
            write(n);
                    {$ELSE}
            Anim.Text(n, 30);
            sleep(400);
                    {$ENDIF}
            TxtClr(Color.Cyan);
            write(' ');
            Anim.Next1;
            writeln;
        end;
        TxtClr(Color.White);
    end;
end;

function BulletTime(speaker: actor_enum; params phrases: array of string): string;
begin
    BulletTimeCaught := nil;
    BulletTimeMode := True;
    Say(speaker, phrases);
    BulletTimeMode := False;
    if (BulletTimeCaught <> nil) then
    begin
        writeln;
        Anim.Objection;
        ReadKey;
    end;
    TxtClr(Color.White);
    Result := BulletTimeCaught;
end;

procedure OraMuda;
begin
    DialogueOpened := True;
    DialogueWidth := 67;
    for var k: actor_enum := Саня to Костыль do
    begin
        Open(k);
        TxtClr(Color.White);
        writeln('├', '─' * NameWidth, '┴', '─' * (DialogueWidth - NameWidth - 1), '┐');
        writeln('│', ' ' * DialogueWidth, '│');
        writeln('└', '─' * DialogueWidth, '┘');
        Cursor.SetLeft(2);
        Cursor.GoTop(-1);
    end;
    Cursor.GoTop(-1);
    TxtClr(Color.Yellow);
    for var l: byte := 0 to 64 do
    begin
        if l > 59 then write('!') else write('ОРА'[(l mod 3) + 1]);
        Cursor.GoTop(-5);
        Cursor.GoLeft(-1);
        if l > 59 then write('!') else write('МУДАК'[(l mod 5) + 1]);
        Cursor.GoTop(+5);
        sleep(25);
    end;
    writeln;
    Close;
    ReadKey;
end;

procedure Echo;
const
    u_a: array of string = ('Грррр...', 'КОООСТЯЯЯЯЯЯЯЯЯЯЯЯЯЯЯЯ!!!');
    u_b: array of string = ('СССССАААНЯ!');
begin
    for var k := True downto False do
    begin
        DialogueOpened := True;
        var z_arr: array of string;
        z_arr := k ? u_a : u_b;
        Say((k ? Саня : Костыль), z_arr);
        Close;
        Cursor.GoTop(-6);
        DialogueOpened := True;
        TxtClr(Color.White);
        NameWidth := 5;
        Cursor.SetLeft(DialogueWidth + 3);
        writeln('┌', '─' * NameWidth, '┐');
        Cursor.SetLeft(DialogueWidth + 3);
        write('│', ' ' * NameWidth, '│');
        Cursor.SetLeft(DialogueWidth + 5);
        TxtClr(Color.DarkYellow);
        writeln('Эхо');
        TxtClr(Color.White);
        var z_arr_l := (z_arr.Max.Length + 3);
        for var m: byte := 0 to 2 do
        begin
            Cursor.SetLeft(DialogueWidth + 3);
            case m of
                0: writeln('├', '─' * NameWidth, '┴', '─' * (z_arr_l - NameWidth - 1), '┐');
                1: writeln('│', ' ' * z_arr_l, '│');
                2: writeln('└', '─' * z_arr_l, '┘');
            end;//case end
        end;
        Cursor.GoTop(-2);
        Cursor.SetLeft(DialogueWidth + 5);
        TxtClr(Color.DarkCyan);
        Anim.Text(z_arr.Max, 25);
        sleep(400);
        writeln;
        Anim.Next3;
        ClrKeyBuffer;
        Close;
        Cursor.GoTop(-3);
    end;
    writelnx2;
end;

initialization

finalization
    BulletTimeCaught := nil;

end.
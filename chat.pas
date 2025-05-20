unit Chat;

interface

var
    /// пропускать анимации в чате
    Skip: boolean;
    /// имя собеседника в чате
    Name: string;

/// подпрограмма для рисования верхней границы "чата"
procedure DrawTop;
/// подпрограмма для рисования нижней границы "чата"
procedure DrawBottom;
/// подпрограмма для рисования боковых границ и фона "чата"
procedure DrawSides;
/// подпрограмма для "ввода" сообщений в "чате"
procedure Enter(const chat_entry: string);
/// подпрограмма для вывода сообщений собеседника в "чате"
procedure Response(line1: string; line2: string := nil);




implementation

uses Cursor, Procs, Tutorial;

const
    chat_width = 50;

procedure DrawTop;
begin
    TxtClr(Color.DarkGray);
    BgClr(Color.Black);
    writeln('┌', '─' * chat_width, '┐');
end;

procedure DrawBottom;
begin
    TxtClr(Color.DarkGray);
    BgClr(Color.Black);
    writeln('└', '─' * chat_width, '┘');
end;

procedure DrawSides;
begin
    BgClr(Color.Black);
    Cursor.SetLeft(0);
    TxtClr(Color.DarkGray);
    write('│');
    BgClr(Color.DarkCyan);
    write(' ' * chat_width);
    BgClr(Color.Black);
    write('│');
    Cursor.SetLeft(2);
    TxtClr(Color.White);
    BgClr(Color.DarkCyan);
end;

procedure CleanUp;
begin
    DrawSides;
    BgClr(Color.Black);
    writeln;
    Chat.DrawBottom;
    TxtClr(Color.White);
    BgClr(Color.Black);
    writeln;
    Cursor.GoTop(-2);
end;

procedure Enter(const chat_entry: string);
begin
    writelnx2;
    Chat.DrawBottom;
    Cursor.GoTop(-3);
    DrawSides;
    TxtClr(Color.Blue);
    writeln('Вы');
    DrawSides;
    if Skip then write(chat_entry)
    else begin
        var chi: byte := 0;
        if not Tutorial.ChatH.Shown then
        begin
            writelnx2;
            BgClr(Color.Black);
            Tutorial.Comment('печатать разными клавишами на клавиатуре, enter для ввода');
            ReadKey;
            ClearLine(True);
            Cursor.GoTop(-2);
            DrawSides;
            write(chat_entry[1]);
            chi += 1;
            Tutorial.ChatH.Show;
        end;
        ClrKeyBuffer;
        Cursor.Show;
        var ch1, ch2: Key;
        while (chi < chat_entry.Length) do
        begin
            if (chi mod 2 = 0) then begin
                repeat ch1 := ReadKey until (ch1 <> ch2);
                ch2 := ch1;
            end;
            chi += 1;
            write(chat_entry[chi]);
        end;
        repeat until (ReadKey in [Key.Enter, Key.Tab, Key.Select, Key.Escape]);
    end;
    Cursor.Hide;
    writeln;
    CleanUp;
end;

procedure Response(line1: string; line2: string);
begin
    if not Skip then sleep(900);
    ClearLine(False);
    DrawSides;
    TxtClr(Color.Blue);
    writeln(Name);
    DrawSides;
    writeln(line1);
    if not NilOrEmpty(line2) then
    begin
        Chat.DrawBottom;
        if not Skip then sleep(800);
        Cursor.GoTop(-1);
        DrawSides;
        writeln(line2);
    end;
    CleanUp;
    if not Skip then sleep(600);
end;

end.
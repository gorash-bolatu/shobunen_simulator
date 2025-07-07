unit Draw;

interface

/// вывести горизонтальную строку и вернуть курсор назад
procedure Text(const strg: string);
/// вывести вертикальную строку и вернуть курсор назад
procedure TextVert(const strg: string);
/// вывести спрайт из массива строк и вернуть курсор назад
procedure Ascii(params arstrg: array of string);
/// вывести строку пробелов и вернуть курсор назад
procedure EraseLine(width: byte);
/// вывести спрайт из пробелов и вернуть курсор назад
procedure Erase(width, height: byte);
/// вывести прямоугольник из box-drawing символов
procedure Box(width, height: byte);
/// вывести сплэш а-ля "Objection!"
procedure ObjectionSplash(const message: string);

implementation

uses Procs, Cursor;

procedure Text(const strg: string);
begin
    if (Cursor.Left + strg.Length >= BufWidth) then Console.BufferWidth += strg.Length;
    write(strg);
    Cursor.GoLeft(-strg.Length);
end;

procedure TextVert(const strg: string);
begin
    foreach c: char in strg do
    begin
        write(c);
        Cursor.GoXY(-1, +1);
    end;
    Cursor.GoTop(-strg.Length);
end;

procedure Ascii(params arstrg: array of string);
begin
    foreach istrg: string in arstrg do
    begin
        Text(istrg);
        Cursor.GoTop(+1);
    end;
    Cursor.GoTop(-arstrg.Length);
end;

procedure EraseLine(width: byte) := Text(' ' * width);

procedure Erase(width, height: byte);
begin
    loop height do
    begin
        Text(' ' * width);
        Cursor.GoTop(+1);
    end;
    Cursor.GoTop(-height);
end;

procedure Box(width, height: byte);
begin
    writeln('┌', '─' * width, '┐');
    loop height do writeln('│', ' ' * width, '│');
    writeln('└', '─' * width, '┘');
end;

function LastChar(const self: StringBuilder): char; extensionmethod := self[self.Length - 1];

procedure ObjectionSplash(const message: string);
begin
    var maxwidth := 19 - message.Length mod 2;
    var top, mid, bot: StringBuilder;
    Console.ResetColor;
    try
        top := new StringBuilder;
        mid := new StringBuilder;
        bot := new StringBuilder;
        case Random(3) of
            0: 
                begin
                    mid.Append('\');
                    top.Append(FiftyFifty('/\', '_'.ToString));
                    bot.Append(' ');
                end;
            1: 
                begin
                    mid.Append('|');
                    top.Append(FiftyFifty('|\', ' _'));
                    bot.Append(FiftyFifty('|/', ' ‾'));
                end;
            2:
                begin
                    mid.Append('/');
                    top.Append(' ');
                    bot.Append(FiftyFifty('\/', '‾'.ToString));
                end;
        end; // case end
        repeat
            top.Append(FiftyFifty('/\', '_'.ToString));
        until top.Length > maxwidth;
        top.Length := maxwidth;
        repeat
            bot.Append(FiftyFifty('\/', '‾'.ToString));
        until bot.Length > maxwidth;
        bot.Length := maxwidth;
        mid.Append(' ' * (maxwidth - 1));
        case Random(3) of
            0: 
                begin
                    mid.Append('\');
                    if (top.LastChar = '/') then
                    begin
                        top.Length -= 1;
                        top.Append('_');
                    end;
                    if (bot.LastChar = '\') then bot.Append('/') else bot.Append('‾');
                end;
            1: 
                begin
                    mid.Append('|');
                    if (top.LastChar = '/') then top.Append('|');
                    if (bot.LastChar = '\') then bot.Append('|');
                end;
            2:
                begin
                    mid.Append('/');
                    if (top.LastChar = '/') then top.Append('\') else top.Append('_');
                    if (bot.LastChar = '\') then
                    begin
                        bot.Length -= 1;
                        bot.Append('‾');
                    end;
                end;
        end; // case end
        Draw.Ascii(top.ToString, mid.ToString, bot.ToString);
    finally
        if (top <> nil) then
        begin
            top.Clear;
            top := nil;
        end;
        if (mid <> nil) then
        begin
            mid.Clear;
            mid := nil;
        end;
        if (bot <> nil) then
        begin
            bot.Clear;
            bot := nil;
        end;
    end;
    Cursor.GoXY(+1, +1);
    BgClr(Color.White);
    TxtClr(Color.Red);
    var padding: string := ' ' * ((maxwidth - message.Length) div 2);
    Draw.Text(padding + message + padding);
    Console.ResetColor;
    Cursor.GoXY(-1, -1);
end;

end.
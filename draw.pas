unit Draw;

interface

procedure Text(const strg: string);
procedure TextVert(const strg: string);
procedure Ascii(const strg: string);
procedure Ascii(params arstrg: array of string);
procedure EraseLine(width: byte);
procedure Erase(width, height: byte);
procedure Box(width, height: byte);
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

procedure Ascii(const strg: string) := Text(strg);

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

procedure ObjectionSplash(const message: string);
begin
    var top: string := ' ' * message.Trim.Length;
    for var n: byte := 1 to top.Length do
        if (Random(4) > 0) then top[n] := '▓';
    top := top.PadLeft(message.Length + 2);
    top := top.Replace('▓ ▓ ▓', '▓ ▓▓ ').Replace('     ', '▓  ▓▓');
    var bot: string := top;
    top := top.Inverse;
    var left_offset: byte := message.Length - message.TrimEnd.Length + 1;
    var mid: string := ('▓' * Random(1, left_offset));
    mid := mid.PadLeft(left_offset);
    mid += (' ' * message.Trim.Length);
    for var z: byte := (1 + message.Trim.Length) to (mid.Length) do
        if top[z] = '▓' then mid += '▓' else break;
    while (top[1] = ' ') and (mid[1] = ' ') and (bot[1] = ' ') do
    begin
        top := top.Substring(1);
        mid := mid.Substring(1);
        bot := bot.Substring(1);
    end;
    TxtClr(Color.White);
    Ascii(top, mid, bot);
    BgClr(Color.White);
    TxtClr(Color.Red);
    Cursor.GoXY(+left_offset, +1);
    write(message.Trim);
    Cursor.GoXY(-message.Trim.Length - left_offset, -1);
    BgClr(Color.Black);
    TxtClr(Color.White);
end;

end.
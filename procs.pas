{$DEFINE DOOBUG} // todo
unit Procs;

interface

uses MyTimers;

type
    Color = System.ConsoleColor;
    Key = System.ConsoleKey;
    actor_enum = (anon, Саня, Костыль, Рома, Трип, Рита,
        {todo добавить actors}
        Тританити, Мотвеус, Агент_Сергеев, Меромавинген);

const
    TAB = #9;
    MIN_WIDTH: byte = 100;
    MIN_HEIGHT: byte = 20;
    NilOrEmpty = string.IsNullOrEmpty;

var
    /// Сюда загоняется полученное из ReadCmd
    CMDRES: string;
    /// Сюда загоняется полученное из Menu.Select или Menu.FastSelect
    MENURES: string;
    /// Использовать ли говорилку (text-to-speech)
    DO_TTS: boolean := False;

/// цвет текста
procedure TxtClr(clr: Color);
/// цвет фона
procedure BgClr(clr: Color);
/// текущий цвет текста
function CurClr: Color;
/// текущая ширина буфера консоли
function BufWidth: integer;
/// асихронный Console.Beep()
procedure BeepAsync(frequency: word; duration: integer);
/// ожидающий Console.Beep()
procedure BeepWait(frequency: word; duration: integer);
/// Milliseconds из стандартной библиотеки, но возвращает только положительные числа
function ElapsedMS: longword;
/// подогнать размер окна
procedure UpdScr;
/// очистка строки
procedure ClearLine(previous_line: boolean);
/// очистка нескольких строк подряд
procedure ClearLines(lines: integer; return_cursor: boolean);
/// нажата ли любая клавиша
function KeyAvail: boolean;
/// очистка экрана
procedure ClrScr;
/// считывание нажатой клавиши
function ReadKey: Key;
/// очищение очереди символов в консоли
procedure ClrKeyBuffer;
/// "нажмите Y/N"
function YN: boolean;
/// нарисовать линию из знаков равно
procedure WriteEqualsLine;
/// writeln дважды
procedure WritelnX2;
/// разбиение текста на строки чтобы он вписывался в доступную ширину
function WordWrap(str: string; width: integer; separator: string := NewLine): string;
/// случайный 50% шанс на возврат a или b
function FiftyFifty<T>(a, b: T): T;
/// сборка мусора вручную
procedure CollectGarbage;
/// ввод + парсинг команды
function ReadCmd(prompt: string := ''): string;
/// обработчик исключений
procedure Puke(ex: Exception);
/// успешна ли инициализация перед запуском программы
function STARTUP(prog_name: string; prog_version: string): boolean;


implementation

uses Cursor, MyTimers, Inventory, Parser, Anim;
uses _Log;

var
    /// Таймер для постоянного восстановления размеров окна
    UPD_SCR_TMR: MyTimers.Timer;

procedure TxtClr(clr: Color) := Console.ForegroundColor := clr;

procedure BgClr(clr: Color) := Console.BackgroundColor := clr;

function CurClr: Color := Console.ForegroundColor;

function BufWidth: integer := Console.BufferWidth;

procedure BeepAsync(frequency: word; duration: integer);
begin
    System.Threading.Tasks.Task.Run(() -> Console.Beep(frequency, duration));
end;

procedure BeepWait(frequency: word; duration: integer);
begin
    System.Threading.Tasks.Task.Run(() -> Console.Beep(frequency, duration)).Wait(duration);
    sleep(duration);
end;

function ElapsedMS: longword := longword(Milliseconds);

procedure UpdScr;
begin
    if (BufWidth < MIN_WIDTH) then
    begin
        Console.BufferWidth := MIN_WIDTH;
        Console.WindowWidth := BufWidth;
    end;
    if (Console.WindowHeight < MIN_HEIGHT) then Console.WindowHeight := MIN_HEIGHT;
    if (Cursor.Top + MaxByte >= Console.BufferHeight) then Console.BufferHeight += MaxByte;
    if Cursor.HIDE_ON_UPDSCR then Console.CursorVisible := False;
end;

procedure ClearLine(previous_line: boolean);
begin
    UpdScr;
    Cursor.SetLeft(0);
    if previous_line then Cursor.GoTop(-1);
    write(' ' * (BufWidth - 1));
    Cursor.SetLeft(0)
end;

procedure ClearLines(lines: integer; return_cursor: boolean);
begin
    UpdScr;
    var original_cursor_top: integer := Cursor.Top;
    Cursor.SetLeft(0);
    loop lines do writeln(' ' * (BufWidth - 1));
    Cursor.SetLeft(0);
    if return_cursor then Cursor.SetTop(original_cursor_top);
end;

function KeyAvail: boolean := Console.KeyAvailable;

procedure ClrScr := Console.Clear;

function ReadKey: Key := Console.ReadKey(True).Key;

procedure ClrKeyBuffer := while KeyAvail do ReadKey;

function YN: boolean;
begin
    ClrKeyBuffer;
    repeat
        case ReadKey of
            Key.Y: Result := True;
            Key.N: Result := False;
        else continue
        end;
    until True;
end;

procedure WriteEqualsLine;
begin
    var original_cur_top: integer := Cursor.Top;
    write('=' * BufWidth);
    if (Cursor.Top = original_cur_top) then writeln;
end;

procedure WritelnX2 := writeln(NewLine);

function WordWrap(str: string; width: integer; separator: string): string;
begin
    if NilOrEmpty(str) or (width <= 0) then
    begin
        Result := nil;
        exit;
    end;
    // разбить текст на строки
    var lines: array of string := Regex.Split(str, '\r\n|\r|\n');
    // для каждой строки:
    {$omp parallel for}
    for var i: integer := 0 to (lines.Length - 1) do
    begin
        // загоняем строку в line и работаем с line
        var line: string := lines[i].TrimEnd;
        // в изначальную ячейку массива будем загонять результат
        lines[i] := '';
        while (line.Length > width) do
        begin
            // точка разделения - изначально на точке предела
            var split_point: longword := width;
            // поиск пробелов влево от точки предела до начала строки
            for var j: longword := split_point downto 1 do
                // если пробел найден, ставим там точку разделения
                if char.IsWhiteSpace(line[j]) then
                begin
                    split_point := j;
                    break;
                end;
            // разбиваем по точке разделения на верхнюю и нижнюю строку, удаляем лишние пробелы
            var upper: string := line.Left(split_point).TrimEnd;
            var lower: string := line.Right(line.Length - split_point).TrimStart;
            // в итоговую строку загоняем верхнюю
            lines[i] += upper + separator;
            // c нижней строкой продолжаем работать
            line := lower;
        end;
        // line стала короче предела, загоняем в итоговую строку
        lines[i] += line;
    end;
    Result := string.Join(separator, lines);
end;

function FiftyFifty<T>(a, b: T): T := (Random(2) = 0) ? a : b;

procedure CollectGarbage;
begin
    System.GC.Collect(GC.MaxGeneration, System.GCCollectionMode.Forced, True);
    System.GC.WaitForPendingFinalizers;
    System.GC.Collect(GC.MaxGeneration, System.GCCollectionMode.Forced, True);
    System.GC.WaitForFullGCComplete
end;

function ReadCmd(prompt: string): string;
const
    nonalpha: array of char = ('!', '"', '#', '№', '$', '%', '&', '''', '(', ')', '*',
    '+', '-', ',', '.', ':', ';', '<', '=', '>', '?', '@', '^', '`', '{', '}', '~',
    '_', '[', ']', '/', '|', '\', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0');
begin
    repeat
        repeat
            writelnx2;
            TxtClr(Color.Gray);
            ClearLine(True);
            print('>');
            if not NilOrEmpty(prompt) then print(prompt);
            ClrKeyBuffer;
            Cursor.Show;
            Result := ReadLnString;
            Cursor.Hide;
            try
                Result := Result.TrimEnd(#10, #13);
            except
                on exc: Exception do
                begin
                    _Log.Log('!! ошибка: ' + exc.GetType.ToString);
                    TxtClr(Color.Red);
                    writeln('// Ошибка: ', exc.GetType, '.');
                    continue
                end
            end; // try end
            if Result.IsMatch('[\u0000-\u001F]') then
            begin
                TxtClr(Color.Red);
                writeln('// Недопустимый символ.');
                _Log.Log('!! ошибка: Недопустимый символ');
            end
            else if NilOrEmpty(Result.Trim) then
                Cursor.GoTop(-((Result.Length + prompt.Length + 2) div BufWidth) - 2)
            else break;
        until False;
        writeln;
        _Log.Log('> ' + Result);
        if not Result.IsMatch('[А-я]') then
        begin
            if NilOrEmpty(prompt) then _Log.Log('[] (нет кириллицы)')
            else _Log.Log($'(префикс:"{prompt}") [] (нет кириллицы)');
            Result := '';
            break
        end;
        for var r: integer := 1 to Result.Length do
            if nonalpha.Contains(Result[r]) then Result[r] := '';
        Result := Result.Replace('', '');
        Result := Result.Trim.ToLower;
        while (Result.Contains('  ')) do Result := Result.Replace('  ', ' ');
        Result := Result.Replace('ё', 'е').Replace('тся', 'ться');
        Result := Result.Replace('тьюб', 'туб');
        Result := Parser.ParseCmd(Result);
        if NilOrEmpty(prompt) then _Log.Log($'[{Result}]')
        else _Log.Log($'(префикс:"{prompt}") [{Result}]');
        if (Result = 'INV') or (Result = 'CHECK_INV') then Inventory.Output
        else break;
    until False;
    TxtClr(Color.White);
    prompt := nil;
end;

function STARTUP(prog_name, prog_version: string): boolean;
begin
    Result := False;
    if NilOrEmpty(prog_version) then prog_version := #8;
    if Console.IsOutputRedirected then
    begin
        println('[', prog_name, prog_version, ']');
        writeln('Программа запущена не в консольном окне. Shift+F9?');
        exit;
    end;
    writeln('Загрузка...');
    if IsUnix then
    begin
        TxtClr(Color.Red);
        writeln('Программа запущена не на операционной системе Windows.');
        TxtClr(Color.Cyan);
        writeln('Всё равно продолжить? (Y/N)');
        if not YN then exit;
        _Log.WarnedUnix := True;
    end;
    BgClr(Color.Black);
    Console.Title := prog_name + ' ' + prog_version.ToLower;
    try
        if not IsUnix then Console.InputEncoding := System.Text.Encoding.GetEncoding(1251);
        Console.OutputEncoding := System.Text.Encoding.UTF8;
    except
        {ignore}
    end;
    if not (System.Globalization.CultureInfo.CurrentUICulture.Name.IsMatch('RU|BY|KZ', RegexOptions.IgnoreCase)) then
    begin
        TxtClr(Color.Cyan);
        writeln('This program is available only in Russian. Continue anyway? (Y/N)');
        if not YN then exit;
        _Log.WarnedLanguage := True;
    end;
    while (Console.LargestWindowWidth <= MIN_WIDTH) do
    begin
        _Log.WarnedWindowSize := True;
        sleep(10);
        TxtClr(Color.Red);
        writeln('Ошибка: превышено максимальное значение размера окна.');
        writeln('Возможно, размер шрифта консоли слишком большой.');
        writeln('Кликните правой кнопкой мыши по заголовку окна, затем выберите "Свойства", перейдите на вкладку "Шрифт", уменьшите его размер и нажмите "ОК".');
        ClrKeyBuffer;
        ReadKey;
        ClrScr;
    end;
    UPD_SCR_TMR := new MyTimers.Timer(3, UpdScr);
    UPD_SCR_TMR.Enable;
    UpdScr;
    Randomize;
    Result := True;
end;

procedure Cleanup;
begin
    if not Console.IsOutputRedirected then _Log.Log('=== стоп');
    if (UPD_SCR_TMR <> nil) then
    begin
        UPD_SCR_TMR.Destroy;
        UPD_SCR_TMR := nil;
    end;
    CMDRES := nil;
    MENURES := nil;
    CollectGarbage;
end;

procedure Puke(ex: Exception);
begin
    _Log.Log('!! ОШИБКА:');
    _Log.Log(TAB + ex.ToString);
    if Console.IsOutputRedirected then writeln(ex.ToString)
    else begin
        BgClr(Color.Black);
        ClrScr;
        TxtClr(Color.Cyan);
        writeln(#7);
        writeln('// Ой! Произошла ошибка.');
        writeln('// Свяжитесь с разработчиком и предоставьте следующее сообщение:');
        TxtClr(Color.Red);
        writeln;
        writeln(ex.GetType);
        writeln(ex.Message);
        writeln(ex.StackTrace);
        TxtClr(Color.DarkRed);
        _Log.DumpThmera;
        Cursor.Show;
        sleep(1000);
        Anim.Next3;
    end;
    ex := nil;
end;

initialization

finalization
    Cleanup;

end.
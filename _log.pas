unit _Log;

interface

procedure Init(debug: boolean);
procedure Log(const strg: string);
procedure PushKey(k: System.ConsoleKey);
procedure DumpThmera;
procedure Cleanup;

var
    mInputs, mTime: int64;
    Val: List<int64> := new List<int64>;
    WarnedLanguage, WarnedWindowSize, WarnedUnix: boolean;

implementation

uses Procs, Achievements, Cursor, TextToSpeech, Versioning;

const
    ThmeraCooldown: word = MaxWord;

var
    Txt: Text;
    CurDrive: System.IO.DriveInfo;
    LastTimeOfThmeraCall: longword;
    CharList: List<string> := new List<string>;
    DEBUGMODE: boolean;
    DISABLED: boolean := True;

function NotEnoughSpace: boolean := (CurDrive.AvailableFreeSpace < 1000);

procedure DisableLog;
begin
    writeln('// Лог не будет сохранён.');
    DISABLED := True;
end;

function Header: string;
begin
    Result := 'симулятор шобунена ';
    if not NilOrEmpty(VERSION) then
        Result += $'[{VERSION.ToLower}] ';
    Result += DateTime.Now.ToString('yyyy-MM-dd HH\:mm\:ss');
    if DEBUGMODE then
        Result += NewLine + '--- DEBUG ---';
    Result += NewLine + System.Environment.CommandLine;
end;

function GetDriveFromPath(const c: string): System.IO.DriveInfo;
begin
    var fi := new System.IO.FileInfo(c);
    var drive := new System.IO.DriveInfo(fi.FullName);
    Result := drive;
    fi := nil;
    drive := nil;
end;

procedure WriteWarnings;
begin
    if WarnedUnix then writeln(Txt, '!! запущено на unix-системе');
    if WarnedLanguage then writeln(Txt, $'!! non-ru region: {System.Globalization.CultureInfo.CurrentUICulture.EnglishName}, {System.Globalization.CultureInfo.CurrentUICulture.Name}');
    if WarnedWindowSize then writeln(Txt, '!! превышение размера окна');
end;

procedure TryAppend;
begin
    try
        Append(Txt);
    except
        on System.IO.IOException do {nothing}
    end;
end;

procedure TryRewrite;
begin
    try
        Rewrite(Txt);
    except
        on System.IO.IOException do {nothing}
    end;
end;

procedure TryFlush;
begin
    try
        Flush(Txt);
    except
        on System.IO.IOException do {nothing}
    end;
end;

procedure PushKey(k: Key) := CharList.Add(k.ToString);

procedure DumpThmera;
const
    _sepstr: string = #9#9#9'``` ';
begin
    if (ElapsedMS < LastTimeOfThmeraCall + ThmeraCooldown) then exit;
    LastTimeOfThmeraCall := ElapsedMS;
    var s1: string := Achievements.DebugString;
    var s2: string := string.Join(' ',
        _sepstr, DateTime.Now.ToString('HH mm ss'), $'({ElapsedMS})', CurDrive.Name, CurDrive.AvailableFreeSpace.ToString, $'w{Console.WindowWidth}x{Console.WindowHeight}', $'b{BufWidth}x{Console.BufferHeight}');
    var s3: string := $'CMDRES [{CMDRES}] MENURES [{MENURES}] TTS {DO_TTS.ToString.First}';
    var ThmeraStr: string := s2 + NewLine + _sepstr + s3;
    if not NilOrEmpty(s1) then ThmeraStr += (NewLine + _sepstr + s1);
    writeln(Txt, ThmeraStr);
end;

procedure Log(const strg: string);
const
    max_char_cap: byte = 23;
begin
    if DISABLED then exit;
    var where_file: boolean := not FileExists(Txt.Name);
    try
        TryAppend;
        if NotEnoughSpace then
        begin
            writeln(Txt, '!! нет места на диске');
            DISABLED := True;
        end
        else begin
            if where_file then writeln(Txt, Header, NewLine, '!! файл был удалён?');
            if (CharList.Count > 0) then
            begin
                writeln(Txt, '-' * 45);
                while CharList.Count > max_char_cap do
                begin
                    writeln(Txt, string.Join(' ', CharList.Take(max_char_cap)));
                    CharList := CharList[max_char_cap:CharList.Count]; // срез
                end;
                writeln(Txt, string.Join(' ', CharList), NewLine, '-' * 45);
                CharList.Clear
            end;
            DumpThmera;
            writeln(Txt, strg);
            TryFlush;
        end
    except
        on _excp: Exception do
        begin
            if DEBUGMODE then 
                PABCSystem.Assert(False, $'"{strg}"{NewLine}{_excp.ToString}')
            else
                write(#7);
        end;
    end;
end;

procedure TryClose;
begin
    try
        Close(Txt);
    except
        {ignore}
    end;
end;

procedure Init(debug: boolean);
var
    sep: char := System.IO.Path.DirectorySeparatorChar;
    path: string;
    name: string := ('SHOBUSIM_' + DateTime.Now.ToString('yyMMdd-HHmmss') + '.log');
    old_file_exists: boolean;
begin
    DEBUGMODE := debug;
    if DEBUGMODE then
    begin
        writeln('лог? (Y/N)');
        DISABLED := not YN;
    end
    else DISABLED := False;
    CurDrive := GetDriveFromPath(GetEXEFileName);
    try
        if DISABLED then exit;
        if NotEnoughSpace then
        begin
            TxtClr(Color.Red);
            writelnx2;
            writeln('// Ошибка: недостаточно места на диске для записи лога.');
            DisableLog;
            exit;
        end;
        TxtClr(Color.Green);
        writeln;
        write('// Поиск существующего лога команд...');
        foreach q: string in EnumerateFiles(GetCurrentDir, 'SHOBUSIM*.log') do
        begin
            name := q.Substring(LastPos(sep, q));
            old_file_exists := True;
            break
        end;
        ClearLine(False);
        Assign(Txt, name);
        try
            if old_file_exists then
            begin
                writeln('// Дополнение существующего лога команд...');
                TryAppend;
                writeln(Txt, NewLine);
            end
            else begin
                writeln('// Создание нового лога команд...');
                TryRewrite;
            end;
            writeln(Txt, Header);
            WriteWarnings;
            TxtClr(Color.Green);
            writeln;
            println('// Файл', name, 'успешно', (old_file_exists ? 'обновлён.' : 'создан.'));
            writeln('// После игры отправьте его разработчику!!!');
        except
            on __EX: Exception do
            begin
                TxtClr(Color.Red);
                print('// Ошибка:');
                if (__EX is System.IO.DirectoryNotFoundException) or (__EX is System.IO.DriveNotFoundException)
                    or (__EX is System.AccessViolationException) or (__EX is System.OperationCanceledException)
                    or (__EX is System.IO.FileNotFoundException) or (__EX is System.ApplicationException) then
                    writeln('папка с игрой недоступна.')
                else if (__EX is System.IO.PathTooLongException) then
                    writeln('путь к папке с игрой слишком длинный.')
                else if (__EX is System.IO.InvalidDataException) then
                    writeln('недопустимый формат пути к папке с игрой.')
                else if NotEnoughSpace then writeln('недостаточно места на диске.')
                else writeln(__EX.Message);
                writeln('Попробовать сохранить лог в другую директорию? (Y/N)');
                if YN then
                    try
                        TxtClr(Color.Cyan);
                        Cursor.Show;
                        repeat
                            print('// Путь до папки сохранения:');
                            try
                                path := ReadLnString.Trim(sep, ' ', #13, #10);
                            except
                                path := '';
                            end;
                            if NilOrEmpty(path) then ClearLine(True) else break;
                        until True;
                        TxtClr(Color.White);
                        path += sep;
                        Assign(Txt, (path + name));
                        TryRewrite;
                        writeln(Txt, Header, '!! ' + __EX.GetType.ToString);
                        WriteWarnings;
                        TxtClr(Color.Green);
                        println('// Файл', name, 'успешно создан.');
                        writeln('// После игры отправьте его разработчику!!!');
                    except
                        on __EX__: Exception do
                        begin
                            TxtClr(Color.Red);
                            print('// Ошибка:');
                            if (__EX__ is System.IO.DirectoryNotFoundException) or (__EX__ is System.IO.DriveNotFoundException)
                                then writeln('папка не найдена.')
                            else if (__EX__ is System.AccessViolationException) or (__EX is System.OperationCanceledException)
                                then writeln('папка недоступна.')
                            else if (__EX__ is System.IO.PathTooLongException)
                                then writeln('путь к папке слишком длинный.')
                            else if (__EX__ is System.IO.InvalidDataException)
                                then writeln('недопустимый формат пути.')
                            else
                                try
                                    CurDrive := GetDriveFromPath(path);
                                    if NotEnoughSpace then write('недостаточно места на диске.')
                                    else writeln(__EX.Message);
                                except
                                    writeln(__EX.Message);
                                end;
                            DisableLog;
                        end;
                    end //try1 end
                else DisableLog; // if NOT yn
            end;
        end;// try2 end
    finally
        ClrKeyBuffer;
        ReadKey;
        path := nil;
        name := nil;
        TryFlush;
        CollectGarbage;
    end; // try3 end
    if not DISABLED then Log('');
    writeln;
end;

procedure Cleanup;
begin
    TryClose;
    CharList.Clear;
    CharList := nil;
    Val.Clear;
    Val := nil;
end;

end.
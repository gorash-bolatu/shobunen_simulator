{$DEFINE DOOBUG} // todo
unit SlashingMinigame;

interface

uses Procs;

/// # - строки правды, % - блокирующие
procedure Load(params lines: array of string);

function Game(opponent: actor_enum): boolean;



implementation

uses MyTimers, Cursor, Draw, Anim;
uses _Log;

type
    /// Cursor and Text Color State
    CATCS = static class
    private
        static l, t: integer;
        static c: Color;
    public
        /// загрузить сохранённую позицию курсора и цвет текста
        static procedure Restore;
        begin
            Cursor.SetLeft(l);
            Cursor.SetTop(t);
            TxtClr(c);
        end;
        /// сохранить текущую позицию курсора и цвет текста
        static procedure Save;
        begin
            l := Cursor.Left;
            t := Cursor.Top;
            c := CurClr;
        end;
    end;
// type end

const
    UPD_HP_INTERVAL: word = 500;
    ATTACK_COOLDOWN: word = 170;
    BOX_WIDTH: word = 53;
    BOX_HEIGHT: word = word(Round(BOX_WIDTH / 3.55));
    HORIZ_PADDING: byte = 4;
    LOW_HP_ZONE: byte = 9;

var
    health_cap: byte;
    loaded: List<array of string>;
    health: shortint;
    health_line: integer;
    time_for_attack: longword := ElapsedMS;
    upd_health_tmr: MyTimers.Timer;
    enemy: string;
    failed_attempts: word;
    interrupt: boolean := False;

function HealthInBounds: boolean := (health in 3..(health_cap - 1));

procedure UpdateHealth := if (health > health_cap) then health := health_cap else if (health > 0) then health -= 1;

procedure FlashHealthbar(won: boolean);
begin
    CATCS.Save;
    TxtClr(Color.Gray);
    Cursor.SetTop(health_line);
    Cursor.SetLeft(6);
    for var i: byte := 0 to 10 do
    begin
        if won then BgClr((i mod 2 = 0) ? Color.DarkGreen : Color.Green)
        else BgClr((i mod 2 = 0) ? Color.DarkRed : Color.Red);
        Draw.Text(' ' * health_cap);
        sleep(100);
    end;
    BgClr(Color.Black);
    CATCS.Restore;
end;

procedure DrawHealthbar;
begin
    if (health < 3) or (health > health_cap) then
    begin
        interrupt := True;
        exit;
    end;
    CATCS.Save;
    var h: shortint := health;
    Cursor.SetTop(health_line);
    Cursor.SetLeft(6);
    BgClr(Color.Gray);
    if (h > health_cap) then h += 1;
    write(' ' * (h - 3));
    if (h < LOW_HP_ZONE) then BgClr(Color.Red) else BgClr(Color.Yellow);
    write(' ' * 3);
    BgClr(Color.Gray);
    while (Cursor.Left < 6 + health_cap) do write(' ');
    BgClr(Color.Black);
    CATCS.Restore;
end;

procedure RedBorderDamage;
begin
    if (health < 2) then exit;
    BeepAsync(300, 100);
    CATCS.Save;
    loop 2 do
        for var g: boolean := False to True do
        begin
            TxtClr(g ? Color.Gray : Color.Red);
            Cursor.SetTop(health_line - BOX_HEIGHT - 1);
            Cursor.SetLeft(0);
            write('┌', '─' * BOX_WIDTH, '┐');
            Cursor.GoXY(-1, +1);
            Draw.TextVert('│' * BOX_HEIGHT);
            Cursor.SetLeft(0);
            Draw.TextVert('│' * BOX_HEIGHT);
            Cursor.SetTop(health_line - 1);
            write('├', '─' * BOX_WIDTH, '┤');
            writeln;
            write('│');
            Cursor.GoLeft(+BOX_WIDTH);
            writeln('│');
            writeln('└', '─' * (4 + health_cap + enemy.Length), '┘');
            loop (health <= LOW_HP_ZONE ? 1 : 3) do
            begin
                health -= 1;
                DrawHealthbar;
                sleep(20);
            end;
        end;
    CATCS.Restore;
    ClrKeyBuffer;
end;

function IsDirectionKey(k: Key): boolean :=
k in [Key.LeftArrow, Key.RightArrow, Key.UpArrow, Key.DownArrow,
    Key.W, Key.A, Key.S, Key.D,
    Key.NumPad2, Key.NumPad4, Key.NumPad6, Key.NumPad8];

function ConvertKeyToDirection(k: Key): direction;
begin
    case k of
        Key.UpArrow, Key.W, Key.NumPad8: Result := direction.up;
        Key.RightArrow, Key.D, Key.NumPad6: Result := direction.right;
        Key.DownArrow, Key.S, Key.NumPad2: Result := direction.down;
        Key.LeftArrow, Key.A, Key.NumPad4: Result := direction.left;
    end; // case end
end;

procedure SlashAt(left, top: integer; textdir, animdir: direction; hurt: boolean);
begin
    upd_health_tmr.Disable;
    ClrKeyBuffer;
    if hurt then
    begin
        loop (health_cap div 3) do
        begin
            health -= 1;
            DrawHealthbar;
            sleep(1);
        end;
        BeepAsync(260, 900);
    end
    else if (health > health_cap) then health := health_cap else
    begin
        loop 2 do
        begin
            health += 1;
            DrawHealthbar;
            sleep(1);
        end;
        if (health < LOW_HP_ZONE) then health += 1;
        DrawHealthbar;
        BeepAsync(500, 150);
    end;
    Anim.Slash(left, top, animdir);
    case textdir of
        direction.up, direction.down:
            begin
                Cursor.SetTop(health_line - BOX_HEIGHT);
                Cursor.GoLeft(-1);
                Draw.Erase(3, BOX_HEIGHT - 1);
            end;
        direction.right, direction.left:
            begin
                Cursor.SetLeft(1);
                Cursor.GoTop(-2);
                Draw.Erase(BOX_WIDTH, 5);
            end;
    end; // case end
    time_for_attack := ElapsedMS + ATTACK_COOLDOWN;
    upd_health_tmr.Enable;
end;

procedure PlayLine(s: string; d: direction);
const
    delay: byte = 25;
var
    timeout: word = 800 + (failed_attempts * 200);
    reverse: boolean := (d = direction.up) or (d = direction.left);
    is_rage: boolean := s.StartsWith('%');
    is_truth := s.StartsWith('#');
    midpoint: (integer, integer);
    already_written: byte := 1;
    offset: shortint := 0;
    k: Key;
begin
    s := s.TrimStart('#', '%');
    ClrKeyBuffer;
    UpdScr;
    TxtClr(is_rage ? Color.Red : Color.Yellow);
    foreach c: char in (reverse ? s.Inverse : s) do
    begin
        DrawHealthbar;
        if interrupt then break;
        offset := (already_written div 2);
        if reverse then offset := -offset;
        case d of
            direction.up, direction.down: midpoint := (Cursor.Left, Cursor.Top - offset);
            direction.left, direction.right: midpoint := (Cursor.Left - offset, Cursor.Top);
        end;
        write(c);
        already_written += 1;
        if KeyAvail and (already_written > 3) then
        begin
            k := ReadKey;
            _Log.PushKey(k);
        end;
        if IsDirectionKey(k) and (ElapsedMS > time_for_attack) then
            if is_rage then RedBorderDamage else break;
        if is_rage then k := Key.Escape; // Key нельзя присвоить дефолтное значение?! ну пусть будет Escape, хз
        case d of
            direction.up, direction.down: Cursor.GoXY(-1, (reverse ? -1 : +1));
            direction.left: Cursor.GoLeft(-2);
        end;
        case d of
            direction.up, direction.down: sleep(delay + delay div 2);
            direction.left, direction.right: sleep(delay);
        end;
        if interrupt or not HealthInBounds then exit;
    end;
    if IsDirectionKey(k) and (ElapsedMS > time_for_attack) then
        if is_rage then RedBorderDamage
        else SlashAt(midpoint.Item1, midPoint.Item2, d, ConvertKeyToDirection(k), is_truth)
    else begin
        var ti: longword := ElapsedMS;
        repeat
            DrawHealthbar;
            if not HealthInBounds then exit;
            if KeyAvail then
            begin
                k := ReadKey;
                _Log.PushKey(k);
                if IsDirectionKey(k) and (ElapsedMS > time_for_attack) then
                    if is_rage then RedBorderDamage
                    else begin
                        SlashAt(midpoint.Item1, midpoint.Item2, d, ConvertKeyToDirection(k), is_truth);
                        break;
                    end;
            end;
        until (ElapsedMS > time_for_attack) and (ElapsedMS > ti + timeout);
    end;
end;

procedure PlayBatch(const batch: array of string);
const
    UP_BOUNDARY: integer = Cursor.Top;
    DOWN_BOUNDARY: integer = UP_BOUNDARY + BOX_HEIGHT;
begin
    var curdir: direction;
    if (batch.Max(q -> q.Length) < BOX_HEIGHT - 4)
        then curdir := FiftyFifty(direction.up, direction.down)
    else curdir := FiftyFifty(direction.left, direction.right);
    var rnds: HashSet<integer>;
    var range: IntRange;
    try
        rnds := new HashSet<integer>;
        case curdir of
            direction.up, direction.down:
                begin
                    range := horiz_padding..(box_width - horiz_padding);
                    foreach i: integer in range do
                        if (i mod 4 = 0) then rnds.Add(i + 1);
                end;
            direction.left, direction.right:
                begin
                    range := (up_boundary + 3)..(down_boundary - 3);
                    foreach i: integer in range do
                        if (i mod 2 = 0) then rnds.Add(i);
                end;
        end;
        if (rnds.Count > batch.Length) then
            repeat
                rnds.Remove(rnds.ElementAt(Random(rnds.Count)))
            until (rnds.Count = batch.Length)
        else
            while (rnds.Count < batch.Length) do rnds.Add(Random(range.Low, range.High));
        for var j: byte := 0 to (batch.Length - 1) do
        begin
            var r: integer := rnds.ElementAt(Random(rnds.Count));
            case curdir of
                direction.up, direction.down: Cursor.SetLeft(r);
                direction.left, direction.right: Cursor.SetTop(r);
            end;
            rnds.Remove(r);
            var len: integer := batch[j].Length;
            case curdir of
                direction.up: Cursor.SetTop(Random(UP_BOUNDARY + 2 + len, DOWN_BOUNDARY - 3));
                direction.right: Cursor.SetLeft(Random(HORIZ_PADDING - 1, BOX_WIDTH - HORIZ_PADDING - len + 2));
                direction.down: Cursor.SetTop(Random(UP_BOUNDARY + 3, DOWN_BOUNDARY - len - 2));
                direction.left: Cursor.SetLeft(Random(HORIZ_PADDING + len, BOX_WIDTH - HORIZ_PADDING));
            end;
            PlayLine(batch[j], curdir);
            if not HealthInBounds then begin
                interrupt := True;
                break;
            end;
            DrawHealthbar;
            case curdir of
                direction.up: curdir := direction.down;
                direction.right: curdir := direction.left;
                direction.down: curdir := direction.up;
                direction.left: curdir := direction.right;
            end;
        end;
    finally
        if (rnds <> nil) then
        begin
            rnds.Clear;
            rnds := nil;
        end;
    end;
    Cursor.SetTop(health_line - BOX_HEIGHT);
    Cursor.SetLeft(1);
    if (HealthInBounds and not interrupt) then DrawHealthBar else FlashHealthbar(health > health_cap div 2);
    Draw.Erase(BOX_WIDTH - 1, BOX_HEIGHT - 1);
end;

procedure Load(params lines: array of string);
begin
    {$IFDEF DOOBUG}
    if (lines.Length = 0) then
        raise new Exception('НЕТ СТРОК В SLASHINGMINIGAME.LOAD()');
    if lines.Any(q -> q.Length = 0) then
        raise new Exception('ПУСТАЯ СТРОКА В SLASHINGMINIGAME.LOAD()');
    if (lines.Length * 4 >= BOX_WIDTH) then
        raise new Exception('SLASHINGMINIGAME.LOAD(): СЛИШКОМ МНОГО ВЕРТ. СТРОК В'
                                                + $' (МАКС {(BOX_WIDTH div 4) - 1} ПОЛУЧЕНО {lines.Length})');
    if (lines.Length * 2 >= BOX_HEIGHT) then
        raise new Exception('SLASHINGMINIGAME.LOAD(): СЛИШКОМ МНОГО ГОРИЗ. СТРОК'
                                                + $' (МАКС {(BOX_HEIGHT div 2) - 1} ПОЛУЧЕНО {lines.Length})');
    if (lines.Max(q -> q.Length) > BOX_WIDTH - 6) then
        raise new Exception('SLASHINGMINIGAME.LOAD(): СТРОКА "' + lines.MaxBy(q -> q.Length)
                                                + '" НЕ ВЛЕЗАЕТ ПРИ DIRECTION=left/right');
    {$ENDIF}
    if (loaded = nil) then loaded := new List<array of string>;
    loaded.Add(lines);
end;

function Game(opponent: actor_enum): boolean;
var
    ret: integer;
begin
    try
        upd_health_tmr := new MyTimers.Timer(UPD_HP_INTERVAL, UpdateHealth);
        {$IFDEF DOOBUG}
        if (loaded = nil) or (loaded.Count = 0) then
            raise new Exception('НЕ ЗАГРУЖЕНЫ ПАРАМЕТРЫ ДЛЯ SlashingMinigame.Game() ЧЕРЕЗ SlashingMinigame.Load()');
        {$ENDIF}
        enemy := opponent.ToString.Replace('_', ' ').ToUpper;
        health_cap := BOX_WIDTH - (6 + enemy.Length);
        health := health_cap div 2;
        interrupt := False;
        ret := Cursor.Top;
        Draw.Box(BOX_WIDTH, BOX_HEIGHT - 1);
        Cursor.GoTop(-1);
        Draw.Box((6 + health_cap + enemy.Length), 1);
        Cursor.GoTop(-3);
        writeln('├', '─' * (6 + health_cap + enemy.Length), '┤');
        health_line := Cursor.Top;
        DrawHealthbar;
        Cursor.SetLeft(1);
        TxtClr(Color.Gray);
        write('САНЯ ');
        BgClr(Color.Gray);
        write(' ' * health_cap);
        BgClr(Color.Black);
        writeln(' ', enemy);
        upd_health_tmr.Enable;
        foreach strarr: array of string in loaded do
        begin
            Cursor.SetTop(ret);
            PlayBatch(strarr);
            if interrupt or not HealthInBounds then break;
        end;
    finally
        if (loaded <> nil) then
        begin
            loaded.Clear;
            loaded := nil;
        end;
        if (upd_health_tmr <> nil) then
        begin
            upd_health_tmr.Destroy;
            upd_health_tmr := nil;
        end;
    end;
    Result := (health > 0);
    if Result then failed_attempts := 0 else failed_attempts += 1;
    Cursor.SetTop(ret);
    ClearLines(BOX_HEIGHT + 5, True);
end;

end.
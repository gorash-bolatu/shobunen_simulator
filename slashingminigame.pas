{$DEFINE DOOBUG} // todo
unit SlashingMinigame;

interface

uses Procs;

/// # - строки правды, % - блокирующие
procedure Load(params lines: array of string);

function Game(opponent: Procs.actor_enum): boolean;


implementation

uses MyTimers, Cursor, Draw, Anim;
uses _Log;

        const health_interval: word = 500;
        const attack_cooldown: word = 170;
        const box_width: byte = 53;
        const horiz_padding: byte = 4;
        const paniczone: byte = 9;
        
        var
         health_cap: byte;
         box_height: byte := Round(box_width / 3.55);
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
        
         procedure FlashHealthbar(win: boolean);
        begin
            var ret_t: (integer, integer, Color) := (Cursor.Left, Cursor.Top, CurClr);
            TxtClr(Color.Gray);
            Cursor.SetTop(health_line);
            Cursor.SetLeft(6);
            for var i: byte := 0 to 10 do
            begin
                if win then BgClr((i mod 2 = 0) ? Color.DarkGreen : Color.Green)
                else BgClr((i mod 2 = 0) ? Color.DarkRed : Color.Red);
                Draw.WriteAndRet(' ' * health_cap);
                sleep(100);
            end;
            BgClr(Color.Black);
            Cursor.SetLeft(ret_t.Item1);
            Cursor.SetTop(ret_t.Item2);
            TxtClr(ret_t.Item3);
        end;
        
         procedure DrawHealthbar;
        begin
            if (health < 3) or (health > health_cap) then
            begin
                interrupt := True;
                exit;
            end;
            var ret_t: (integer, integer, Color) := (Cursor.Left, Cursor.Top, CurClr);
            var h: shortint := health;
            Cursor.SetTop(health_line);
            Cursor.SetLeft(6);
            BgClr(Color.Gray);
            if (h > health_cap) then h += 1;
            write(' ' * (h - 3));
            if (h < paniczone) then BgClr(Color.Red) else BgClr(Color.Yellow);
            write(' ' * 3);
            BgClr(Color.Gray);
            while (Cursor.Left < 6 + health_cap) do write(' ');
            BgClr(Color.Black);
            Cursor.SetLeft(ret_t.Item1);
            Cursor.SetTop(ret_t.Item2);
            TxtClr(ret_t.Item3);
        end;
        
         procedure RedBorderDamage;
        begin
            if (health < 2) then exit;
            BeepAsync(300, 100);
            var ret_t: (integer, integer, Color) := (Cursor.Left, Cursor.Top, CurClr);
            loop 2 do
                for var g: boolean := False to True do
                begin
                    TxtClr(g ? Color.Gray : Color.Red);
                    Cursor.SetTop(health_line - box_height - 1);
                    Cursor.SetLeft(0);
                    write('┌', '─' * box_width, '┐');
                    Cursor.GoXY(-1, +1);
                    Draw.TextVert('│' * box_height);
                    Cursor.SetLeft(0);
                    Draw.TextVert('│' * box_height);
                    Cursor.SetTop(health_line - 1);
                    write('├', '─' * box_width, '┤');
                    writeln;
                    write('│');
                    Cursor.GoLeft(+box_width);
                    writeln('│');
                    writeln('└', '─' * (4 + health_cap + enemy.Length), '┘');
                    loop (health <= paniczone ? 1 : 3) do
                    begin
                        health -= 1;
                        DrawHealthbar;
                        sleep(20);
                    end;
                end;
            Cursor.SetLeft(ret_t.Item1);
            Cursor.SetTop(ret_t.Item2);
            TxtClr(ret_t.Item3);
            ClrKeyBuffer;
        end;
        
         function IsDirectionKey(k: Key): boolean := k in [Key.LeftArrow, Key.RightArrow,
        Key.UpArrow, Key.DownArrow, Key.W, Key.A, Key.S, Key.D, Key.NumPad2, Key.NumPad4, Key.NumPad6, Key.NumPad8];
        
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
                if (health < paniczone) then health += 1;
                DrawHealthbar;
                BeepAsync(500, 150);
            end;
            Anim.Slash(left, top, animdir);
            case textdir of
                direction.up, direction.down:
                    begin
                        Cursor.SetTop(health_line - box_height);
                        Cursor.GoLeft(-1);
                        Draw.Erase(3, box_height - 1);
                    end;
                direction.right, direction.left:
                    begin
                        Cursor.SetLeft(1);
                        Cursor.GoTop(-2);
                        Draw.Erase(box_width, 5);
                    end;
            end; // case end
            time_for_attack := ElapsedMS + attack_cooldown;
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
        var
            curdir: direction;
            rnds: HashSet<integer>;
        begin
            try
                if (batch.Max(q -> q.Length) < box_height - 4) then curdir := FiftyFifty(direction.up, direction.down)
                else curdir := FiftyFifty(direction.left, direction.right);
                var up_boundary: integer := Cursor.Top;
                var down_boundary: integer := up_boundary + box_height;
                rnds := new HashSet<integer>;
                rnds.Clear;
                var range: IntRange;
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
                    repeat rnds.Remove(rnds.ElementAt(Random(rnds.Count))) until (rnds.Count = batch.Length)
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
                        direction.up: Cursor.SetTop(Random(up_boundary + 2 + len, down_boundary - 3));
                        direction.right: Cursor.SetLeft(Random(horiz_padding - 1, box_width - horiz_padding - len + 2));
                        direction.down: Cursor.SetTop(Random(up_boundary + 3, down_boundary - len - 2));
                        direction.left: Cursor.SetLeft(Random(horiz_padding + len, box_width - horiz_padding));
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
                Cursor.SetTop(health_line - box_height);
                Cursor.SetLeft(1);
                if (HealthInBounds and not interrupt) then DrawHealthBar else FlashHealthbar(health > health_cap div 2);
                Draw.Erase(box_width - 1, box_height - 1);
            finally
                rnds.Clear;
                rnds := nil;
            end;
        end;
    
         procedure Load(params lines: array of string);
        begin
            {$IFDEF DOOBUG}
            if (lines.Length = 0) then
                raise new Exception('НЕТ СТРОК В SLASHINGMINIGAME.LOAD()');
            if lines.Any(q -> q.Length = 0) then
                raise new Exception('ПУСТАЯ СТРОКА В SLASHINGMINIGAME.LOAD()');
            if (lines.Length * 4 >= box_width) then
                raise new Exception('SLASHINGMINIGAME.LOAD(): СЛИШКОМ МНОГО ВЕРТ. СТРОК В'
                                                + $' (МАКС {(box_width div 4) - 1} ПОЛУЧЕНО {lines.Length})');
            if (lines.Length * 2 >= box_height) then
                raise new Exception('SLASHINGMINIGAME.LOAD(): СЛИШКОМ МНОГО ГОРИЗ. СТРОК'
                                                + $' (МАКС {(box_height div 2) - 1} ПОЛУЧЕНО {lines.Length})');
            if (lines.Max(q -> q.Length) > box_width - 6) then
                raise new Exception('SLASHINGMINIGAME.LOAD(): СТРОКА "' + lines.MaxBy(q -> q.Length)
                                                + '" НЕ ВЛЕЗАЕТ ПРИ DIRECTION=left/right');
            {$ENDIF}
            if (loaded = nil) then loaded := new List<array of string>;
            loaded.Add(lines);
        end;
        
         function Game(opponent: actor_enum): boolean;
        begin
            var ret: integer;
            try
                upd_health_tmr := new MyTimers.Timer(health_interval, UpdateHealth);
                {$IFDEF DOOBUG}
                if (loaded = nil) or (loaded.Count = 0) then
                    raise new Exception('НЕ ЗАГРУЖЕНЫ ПАРАМЕТРЫ ДЛЯ SlashingMinigame.Game() ЧЕРЕЗ SlashingMinigame.Load()');
                {$ENDIF}
                enemy := opponent.ToString.Replace('_', ' ').ToUpper;
                health_cap := box_width - (6 + enemy.Length);
                health := health_cap div 2;
                interrupt := False;
                ret := Cursor.Top;
                Draw.Box(box_width, box_height - 1);
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
                loaded := nil;
                upd_health_tmr.Destroy;
                upd_health_tmr := nil;
            end;
            Result := (health > 0);
            if Result then failed_attempts := 0 else failed_attempts += 1;
            Cursor.SetTop(ret);
            ClearLines(box_height + 5, True);
        end;
    
end.
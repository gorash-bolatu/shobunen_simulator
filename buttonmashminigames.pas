unit ButtonMashMinigames;

interface

procedure DoorBreaking;
function JojoSmall(difficulty_relief: byte): boolean;
function JojoBig: boolean;


implementation

uses Procs, Draw, Cursor;
uses _Log;

var
    failed_attempts_s, failed_attempts_b: word;

procedure DoorBreaking;
const
    goal: byte = 30;
    /// (goal * 2) + 2
    gx2p2: byte = 62;
var
    progress: byte;
    starttime: longword;
    period: integer;
    last_key_pressed_at: longword;
    k1, k2: Key;
    cycle: byte;
    switch_color: boolean;
begin
    TxtClr(Color.Gray);
    Draw.Box(gx2p2, 1);
    Cursor.GoXY(+2, -2);
    write('█' * (gx2p2 - 1));
    starttime := ElapsedMS;
    ClrKeyBuffer;
    repeat
        Cursor.SetLeft(64);
        TxtClr(switch_color ? Color.Magenta : Color.Yellow);
        write('ДОЛБИ ПО КНОПКАМ!');
        sleep(2);
        Cursor.SetLeft(1);
        while KeyAvail do
        begin
            k1 := ReadKey;
            if (k1 <> k2) or ((ElapsedMS - last_key_pressed_at) > 200) then
            begin
                last_key_pressed_at := ElapsedMS;
                k2 := k1;
                progress += ((progress > 2) ? 1 : 2);
            end;
            _Log.PushKey(k1);
        end;
        if (progress > 0) and (ElapsedMS > period) then
        begin
            period := ElapsedMS;
            period += 65 - (progress * 2);
            period += ((ElapsedMS - starttime) div 320); // система помощи если долго тупить
            progress -= 1;
        end;
        if (progress > goal) then
        begin
            TxtClr(Color.Yellow);
            write('█' * gx2p2);
        end
        else begin
            TxtClr(Color.Gray);
            write('█' * (goal - progress + 1));
            TxtClr(Color.Yellow);
            write('█' * (progress * 2));
            TxtClr(Color.Gray);
            write('█' * (goal - progress));
        end;
        cycle += 1; // overflow is ok
        if (cycle mod 3 = 0) then switch_color := not switch_color;
    until progress > goal;
    _Log.Log('door breaking time: ' + (ElapsedMS - starttime).ToString);
    Cursor.SetLeft(64);
    TxtClr(Color.Yellow);
    writeln('Двери открыты!    ');
    sleep(400);
    ClrKeyBuffer;
    ReadKey;
    Cursor.GoTop(-2);
    ClearLines(3, True);
    ClrKeyBuffer;
end;

function JojoSmall(difficulty_relief: byte): boolean;
const
    goal: byte = 61;
    offset: byte = 19;
    paniczone: byte = 14;
    initialperiod: word = 1500;
    ora: string = 'О Р А !';
    mudak: string = 'М У Д А К !';
var
    progress: shortint := goal div 2;
    starttime: longword;
    period: integer;
    last_key_pressed_at: longword;
    k1, k2: Key;
    cycle: word;
    S_last_cur_pos, S_before_cur_pos, K_last_cur_pos, K_before_cur_pos: (integer, integer);
    rnd_a, rnd_b: shortint;
begin
    BeepAsync(800, 1000);
    writeln;
    TxtClr(Color.Gray);
    writeln(' ' * (offset - 1), '┌', '─' * goal, '┐');
    writeln(' ' * (offset - 1), '│', ' ' * goal, '│');
    writeln(' ' * (offset - 1), '└', '─' * goal, '┘');
    Cursor.GoXY(+offset, -2);
    starttime := ElapsedMS;
    ClrKeyBuffer;
    repeat
        if (cycle mod 3 = 0) then
        begin
            if (cycle > 0) and (cycle mod 2 = 0) then
            begin
                Cursor.SetLeft(K_last_cur_pos.Item1);
                Cursor.SetTop(K_last_cur_pos.Item2);
                write(' ' * mudak.Length);
                if (cycle > 3) then
                begin
                    Cursor.SetLeft(K_before_cur_pos.Item1);
                    Cursor.SetTop(K_before_cur_pos.Item2);
                    write(' ' * mudak.Length);
                    Cursor.SetTop(K_last_cur_pos.Item2);
                end;
                Cursor.GoTop(-rnd_a);
                Cursor.SetLeft(S_last_cur_pos.Item1);
                Cursor.SetTop(S_last_cur_pos.Item2);
                write(' ' * ora.Length);
                if (cycle > 3) then
                begin
                    Cursor.SetLeft(S_before_cur_pos.Item1);
                    Cursor.SetTop(S_before_cur_pos.Item2);
                    write(' ' * ora.Length);
                    Cursor.SetTop(S_last_cur_pos.Item2);
                end;
                Cursor.GoTop(-rnd_b);
            end;
            TxtClr(Color.Yellow);
            if (cycle > 0) and (K_last_cur_pos.Item2 = Cursor.Top) then
                rnd_a := FiftyFifty(-2, +2)
            else rnd_a := Random(-1, +1) * 2;
            Cursor.GoTop(+rnd_a);
            Cursor.SetLeft(goal + offset + 1);
            if (rnd_a = 0) then Cursor.GoLeft(Random(+4))
            else Cursor.GoLeft(Random(-offset * 2, +3) + 3);
            K_before_cur_pos := K_last_cur_pos;
            K_last_cur_pos := (Cursor.Left, Cursor.Top);
            write(mudak);
            Cursor.GoTop(-rnd_a);
            TxtClr(Color.Magenta);
            if (cycle > 0) and (S_last_cur_pos.Item2 = Cursor.Top) then
                rnd_b := FiftyFifty(-2, +2)
            else rnd_b := Random(-1, +1) * 2;
            Cursor.GoTop(+rnd_b);
            Cursor.SetLeft(3);
            Cursor.GoLeft(Random(-3, +3 + offset * Abs(rnd_b)));
            if (rnd_b = 0) then Cursor.GoLeft(+Random(6))
            else if (Cursor.Left > offset) then Cursor.GoLeft(-3);
            S_before_cur_pos := S_last_cur_pos;
            S_last_cur_pos := (Cursor.Left, Cursor.Top);
            write(ora);
            Cursor.GoTop(-rnd_b);
        end;
        sleep(2);
        Cursor.SetLeft(offset);
        while KeyAvail do
        begin
            k1 := ReadKey;
            if (k1 <> k2) or ((ElapsedMS - last_key_pressed_at) > 150) then
            begin
                last_key_pressed_at := ElapsedMS;
                k2 := k1;
                progress += 1;
            end;
            _Log.PushKey(k1);
        end;
        if (progress > 0) and (ElapsedMS > period) then
        begin
            var diff: integer := (ElapsedMS - starttime);
            period := ElapsedMS;
            var parabolic_speedup: real := Abs((goal div 2) - progress) ** Sqrt(2);
            if (failed_attempts_s < 9) then
                parabolic_speedup /= (9 - failed_attempts_s)
            else period += (failed_attempts_s * 9);
            if (diff < initialperiod) then parabolic_speedup *= 2;
            period += Round(parabolic_speedup);
            period += (diff div 250); // система помощи если долго тупить
            period += (difficulty_relief * 10);
            if (period < 0) then period := 0;
            if (diff < initialperiod) then progress += (cycle mod 2)
            else progress -= (progress div (goal div 3)); // усилить каждую треть
            progress -= 1;
            if (progress > goal div 2) then progress -= (diff mod 2);
        end;
        if (progress < 0) then progress := 0;
        BgClr(((progress < paniczone) and (cycle mod 3 > 0)) ? Color.Yellow : Color.Green);
        if (progress > goal) then write(' ' * goal) else write(' ' * progress);
        BgClr(Color.Red);
        write(' ' * (goal - progress));
        if ((ElapsedMS - starttime) < initialperiod) or (Ord(k1) = 0) then
            if not (progress <= 0) then begin
                TxtClr(cycle mod 2 = 0 ? Color.Blue : Color.Yellow);
                Cursor.SetLeft(30);
                for var c := 1 to 39 do
                begin
                    BgClr((c + 11 > progress) ? Color.Red : Color.Green);
                    write('Д О Л Б И    П О    К Н О П К А М ! ! !'[c]);
                end;
            end;
        BgClr(Color.Black);
        cycle += 1; // no overflow!!!
        if (cycle > MaxSmallInt) then cycle := 6;
    until (progress >= goal) or (progress <= 0);
    _Log.Log('ora time: ' + (ElapsedMS - starttime).ToString);
    Cursor.SetLeft(offset + 12);
    BgClr((progress <= 0) ? Color.Red : Color.Green);
    if (progress <= 0) then
    begin
        TxtClr(Color.Yellow);
        write('МММУУУУУУУУДАААААААААААААААААААААААК!!!');
    end
    else begin
        TxtClr(Color.Magenta);
        write('ОООООРРРРРРРРРРРРААААААААААААААААААА!!!');
    end;
    BgClr(Color.Black);
    sleep(300);
    ClrKeyBuffer;
    ReadKey;
    Cursor.GoTop(-2);
    ClearLines(5, True);
    writeln;
    ClrKeyBuffer;
    TxtClr(Color.White);
    Result := (progress > 0);
    if not Result then failed_attempts_s += 1
    else if (failed_attempts_s > 0) then failed_attempts_s -= 1;
end;

function JojoBig: boolean;
const
    goal: byte = 97;
    paniczone: byte = 14;
    initialperiod: word = 1800;
var
    progress: shortint := goal div 2;
    starttime: longword;
    period: integer;
    last_key_pressed_at: longword;
    k1, k2: Key;
    cycle: word;
    first_pass: boolean := True;
    rnd_a, rnd_b: shortint;
    time_for_strong_attack: integer := 1300;
    additional_time: integer := time_for_strong_attack;
    time_to_turn_on_rage: integer := 6000;
    time_to_turn_off_rage: integer := 7500;
    rage_mode: boolean;
begin
    BeepAsync(800, 1000);
    writeln;
    WriteEqualsLine;
    Cursor.GoTop(+3);
    TxtClr(Color.Gray);
    Draw.Box(goal, 3);
    Cursor.GoTop(+3);
    WriteEqualsLine;
    Cursor.GoXY(+1, -6);
    starttime := ElapsedMS;
    ClrKeyBuffer;
    repeat
        if (cycle mod 3 = 0) then
        begin
            if (cycle > 0) and (cycle mod 2 = 0) then
            begin
                Cursor.SetLeft(0);
                Cursor.GoTop(-6);
                ClearLines(3, False);
                Cursor.GoTop(+5);
                ClearLines(3, False);
                Cursor.GoTop(-5);
            end;
            TxtClr(Color.Magenta);
            rnd_a := FiftyFifty(-6, +2);
            Cursor.GoTop(+rnd_a);
            Cursor.SetLeft(Random(30));
            Draw.Ascii(
                               '╔══╗ ╔══╗ ╔══╣  █',
                               '║  ║ ╠══╝ ║  ║  █',
                               '╚══╝ ╨    ╚══╩╡ ▄');
            Cursor.GoTop(-rnd_a);
            TxtClr(rage_mode ? Color.Red : Color.Yellow);
            rnd_b := FiftyFifty(-6, +2);
            Cursor.GoTop(+rnd_b);
            Cursor.SetLeft(Random(50, 73));
            Draw.Ascii(
                               '╔╗╔╗ ╗ ╔  ╔╗  ╔══╣  ║┌┘ █',
                               '║╚╝║ ╚═╣ ╔╩╩╗ ║  ║  ╠╡  █',
                               '╨  ╨ ══╝ ╨  ╨ ╚══╩╡ ║└┐ ▄');
            Cursor.GoTop(-rnd_b);
        end;
        Cursor.GoTop(-2);
        sleep(2);
        while KeyAvail do
        begin
            k1 := ReadKey;
            if (k1 <> k2) or ((ElapsedMS - last_key_pressed_at) > 150) then
            begin
                last_key_pressed_at := ElapsedMS;
                k2 := k1;
                progress += 1;
            end;
            _Log.PushKey(k1);
        end;
        if (progress > 0) and (ElapsedMS > period) then
        begin
            var diff: integer := (ElapsedMS - starttime);
            period := ElapsedMS;
            var parabolic_speedup: integer := 110 - Round(Abs(progress - (goal div 2)) ** Sqrt(2) * 1.1);
            period += parabolic_speedup;
            period += (diff div 50); // система помощи если долго тупить
            period += (failed_attempts_b * 100);
            if (period < 0) then period := 0;
            if (progress <= paniczone) then period += 80 + (progress * 2); // система помощи если мало здоровья
            if (diff > initialperiod) then
                case progress of
                    0..goal div 3: progress -= 1;
                    (1 + goal div 3)..(goal - goal div 2): progress -= progress div 14;
                    (goal - goal div 3)..goal: progress -= 1;
                else progress -= progress div 10;
                end //case end
            else if (progress > goal div 2) then progress -= 2 else progress -= 1;
            if (progress > goal div 2) then
            begin
                progress -= 1;
                if (diff in initialperiod..(initialperiod * 10)) then progress -= 1;
                if (progress > (goal - goal div 3)) then progress -= progress div 14;
                if (progress > (goal - goal div 4)) then progress -= progress div 18;
            end;
            if (diff > time_for_strong_attack) then
            begin
                progress -= progress div 11;
                if (progress > paniczone) then progress -= 1;
                if (time_for_strong_attack > 10000) then additional_time := (1400 - progress * 13)
                else additional_time := Round(additional_time ** 1.01);
                time_for_strong_attack += additional_time;
            end;
            if rage_mode then
            begin
                time_for_strong_attack := diff;
                progress -= progress div 7;
                if (progress > 3) then progress -= (progress div 7 + 3);
                if (diff > time_to_turn_off_rage) then rage_mode := False;
            end
            else if (diff > time_to_turn_on_rage) then begin
                time_to_turn_off_rage := time_to_turn_on_rage + 2000 + (time_to_turn_on_rage div 12);
                if (time_to_turn_on_rage = 6000) then time_to_turn_on_rage := 12300
                else time_to_turn_on_rage := Round(time_to_turn_on_rage * 1.6);
                rage_mode := True;
            end;
            if (cycle mod 2 = 0) and (not KeyAvail) then progress -= 1; // штраф за ненажимание клавиш каждые 2 цикла
        end;
        if (progress < 0) then progress := 0;
        loop 3 do
        begin
            Cursor.SetLeft(1);
            if (progress < paniczone) and (cycle mod 3 > 0) then BgClr(Color.Yellow) else BgClr(Color.Green);
            var amount: byte := progress;
            case progress of
                1..4: amount += Random(2);
                5..(goal - 4): amount += Random(-3, +3);
                (goal - 3)..(goal - 1): amount -= Random(2);
            else if (progress >= goal) then amount := goal
                else amount := 0;
            end;
            write(' ' * amount);
            BgClr(Color.Red);
            writeln(' ' * (goal - amount));
        end;
        Cursor.GoTop(-2);
        if rage_mode then
        begin
            TxtClr(cycle mod 2 = 0 ? Color.Blue : Color.Yellow);
            Cursor.SetLeft(30);
            for var c := 1 to 42 do
            begin
                BgClr((c + 27 > progress) ? Color.Red : Color.Green);
                write('К О С Т Ы Л Ь С К А Я    Я Р О С Т Ь ! ! !'[c]);
            end;
        end
        else if ((ElapsedMS - starttime) < (initialperiod + initialperiod div 3)) or (Ord(k1) = 0) then begin
            TxtClr(cycle mod 2 = 0 ? Color.Blue : Color.Yellow);
            Cursor.SetLeft(31);
            for var c := 1 to 39 do
            begin
                BgClr((c + 30 > progress) ? Color.Red : Color.Green);
                write('Д О Л Б И    П О    К Н О П К А М ! ! !'[c]);
            end;
        end;
        writeln;
        BgClr(Color.Black);
        cycle += 1; // no overflow!!!
        if (cycle > MaxSmallInt) then cycle := 6;
    until (progress >= goal) or (progress <= 0);
    _Log.Log('ora ora time: ' + (ElapsedMS - starttime).ToString);
    Cursor.GoTop(-6);
    ClearLines(3, False);
    Cursor.GoTop(+5);
    ClearLines(3, False);
    Cursor.GoTop(-7);
    BgClr((progress <= 0) ? Color.Red : Color.Green);
    if (progress > 0) then
    begin
        Cursor.SetLeft(25);
        TxtClr(Color.Magenta);
        Draw.Ascii(
                    '╔══╗ ╔══╗ ' + '╔══╣  ' * 6 + '█',
                    '║  ║ ╠══╝ ' + '║  ║  ' * 6 + '█',
                    '╚══╝ ╨    ' + '╚══╩═ ' * 6 + '▄');
    end
    else begin
        Cursor.SetLeft(22);
        TxtClr(Color.Yellow);
        Draw.Ascii(
                    '╔╗╔╗ ╗ ╔  ╔╗  ' + '╔══╣  ' * 6 + '║┌─ █',
                    '║╚╝║ ╚═╣ ╔╩╩╗ ' + '║  ║  ' * 6 + '╠╡  █',
                    '╨  ╨ ══╝ ╨  ╨ ' + '╚══╩═ ' * 6 + '║└─ ▄');
    end;
    BgClr(Color.Black);
    sleep(300);
    ClrKeyBuffer;
    ReadKey;
    Cursor.GoTop(-4);
    ClearLines(12, True);
    writeln;
    ClrKeyBuffer;
    TxtClr(Color.White);
    Result := (progress > 0);
    if not Result then failed_attempts_b += 1
    else if (failed_attempts_b > 0) then failed_attempts_b -= 1;
end;

end.
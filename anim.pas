unit Anim;

interface

type
    direction = (up, right, down, left);

procedure Text(const s: string; delay: word);
procedure Next1;
procedure Next3;
procedure Objection;
procedure TakeThat;
procedure Slash(left, top: integer; dir: direction);

implementation

uses Procs, Tutorial, Cursor, Draw;

const
    BACKSPACE: string = #8#32#8;

procedure Text(const s: string; delay: word);
begin
    foreach c: char in s do
    begin
        write(c);
        sleep(delay);
    end
end;

procedure Next1;
begin
    ClrKeyBuffer;
    var cycle: boolean;
    repeat
        System.Threading.SpinWait.SpinUntil(() -> KeyAvail, 330);
        if KeyAvail then break else write(cycle ? BACKSPACE : '>');
        cycle := not cycle;
    until False;
    if cycle then write(BACKSPACE);
    ClrKeyBuffer;
end;

procedure Next3;
begin
    writeln;
    if not Tutorial.AnimNextH.Shown then
    begin
        Cursor.GoTop(+1);
        Tutorial.Comment('любая клавиша чтобы продолжить');
        Cursor.GoTop(-2);
    end;
    TxtClr(Color.Gray);
    ClrKeyBuffer;
    var len: byte;
    repeat
        System.Threading.SpinWait.SpinUntil(() -> KeyAvail, 240);
        if KeyAvail or (len = 3) then write(BACKSPACE * len) else write('>');
        if len = 3 then len := 0 else len += 1;
    until KeyAvail;
    if not Tutorial.AnimNextH.Shown then
    begin
        Cursor.GoTop(+1);
        ClearLine(False);
        Cursor.GoTop(-1);
        Tutorial.AnimNextH.Show;
    end;
    TxtClr(Color.White);
    ClrKeyBuffer
end;

procedure ObjectionSplash(takethat: boolean);
begin
    var msg: string;
    if takethat then msg := '   TAKE THAT!   '
    else case Random(3) of
            0: msg := '   OBJECTION!   ';
            1: msg := '    HOLD IT!    ';
            2: msg := 'NO THAT''S WRONG!';
        end;// case end
    writeln;
    var frame: byte := 0;
    repeat
        var left_mov: integer;
        if (frame > 8) and (Cursor.Left > 0) then left_mov := -1
        else if (Cursor.Left = 0) then left_mov := +1
        else left_mov := Random(-1, +1);
        var top_mov: integer := Random(1, 2);
        Cursor.GoXY(+left_mov, +top_mov);
        Draw.ObjectionSplash(msg);
        sleep(30);
        Draw.Erase(18, 3);
        Cursor.GoTop(-top_mov);
        Draw.ObjectionSplash(msg);
        sleep(25);
        if (frame > 8) and (Cursor.Left = 0) then break;
        Draw.Erase(18, 3);
        frame += 1;
    until False;
    BeepWait(800, 500);
    Cursor.GoTop(+4);
end;

procedure Objection := ObjectionSplash(False);

procedure TakeThat := ObjectionSplash(True);

procedure Slash(left, top: integer; dir: direction);
const
    delay: byte = 35;
begin
    Cursor.SetLeft(left);
    Cursor.SetTop(top);
    var chr_a: char;
    case Random(3) of
        0: chr_a := '/';
        1: chr_a := '\';
        2:
            case dir of
                direction.left, direction.right: chr_a := '-';
                direction.down, direction.up: chr_a := '|';
            end;
    end;
    var orig_cur_left: integer := Cursor.Left;
    var orig_cur_top: integer := Cursor.Top;
    var orig_color: Color := CurClr;
    TxtClr(Color.Red);
    for var erase: boolean := False to True do
    begin
        var chr_b: char := (erase ? ' ' : chr_a);
        case chr_a of
            '/':
                case dir of
                    direction.up, direction.right:
                        begin
                            Cursor.GoXY(-2, +2);
                            loop 4 do
                            begin
                                Anim.Text(chr_b, delay);
                                Cursor.GoTop(-1);
                            end;
                            Anim.Text(chr_b, delay);
                        end;
                    direction.down, direction.left:
                        begin
                            Cursor.GoXY(+2, -2);
                            loop 4 do
                            begin
                                Anim.Text(chr_b, delay);
                                Cursor.GoXY(-2, +1);
                            end;
                            Anim.Text(chr_b, delay);
                        end;
                end;
            '\':
                case dir of
                    direction.up, direction.left:
                        begin
                            Cursor.GoXY(+2, +2);
                            loop 4 do
                            begin
                                Anim.Text(chr_b, delay);
                                Cursor.GoXY(-2, -1);
                            end;
                            Anim.Text(chr_b, delay);
                        end;
                    direction.down, direction.right:
                        begin
                            Cursor.GoXY(-2, -2);
                            loop 4 do
                            begin
                                Anim.Text(chr_b, delay);
                                Cursor.GoTop(+1);
                            end;
                            Anim.Text(chr_b, delay);
                        end;
                end;
            '-':
                if (dir = direction.right) then
                begin
                    Cursor.GoLeft(-3);
                    Anim.Text(chr_b * 7, delay);
                end
                else begin
                    Cursor.GoLeft(+3);
                    loop 6 do
                    begin
                        Anim.Text(chr_b, delay);
                        Cursor.GoLeft(-2);
                    end;
                    Anim.Text(chr_b, delay);
                end;
            '|':
                if (dir = direction.down) then
                begin
                    Cursor.GoTop(-2);
                    loop 4 do
                    begin
                        Anim.Text(chr_b, delay);
                        Cursor.GoXY(-1, +1);
                    end;
                    Anim.Text(chr_b, delay);
                end
                else begin
                    Cursor.GoTop(+2);
                    loop 4 do
                    begin
                        Anim.Text(chr_b, delay);
                        Cursor.GoXY(-1, -1);
                    end;
                    Anim.Text(chr_b, delay);
                end;
        end; // case chr end
        if not erase then sleep(delay * 6);
        Cursor.SetLeft(orig_cur_left);
        Cursor.SetTop(orig_cur_top);
    end;
    TxtClr(orig_color);
end;

end.    
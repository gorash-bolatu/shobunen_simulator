unit Dialogue;

interface

uses Actors;

/// открывает новый диалог
procedure Open;
/// закрывает открытый диалог
procedure Close;
/// перед первым Say в цепочке нужно открыть диалог через Dialogue.Open
/// после последнего Say в цепочке нужно закрыть диалог через Dialogue.Close
procedure Say(const speaker: Actor; params phrases: array of string);
/// Dialogue.Say, но не требует Dialogue.Open и Dialogue.Close
procedure FastSay(const speaker: Actor; params phrases: array of string);
/// перед первым BulletTime в цепочке нужно открыть диалог через Dialogue.Open
/// после последнего BulletTime в цепочке нужно закрыть диалог через Dialogue.Close
/// возвращает строку в фигурных скобках {} по нажатию Enter/Tab/пробела
/// возвращает nil если ничего не было нажато
/// возвращает пустую строку если клавиша нажата там где нет фразы в фигурных скобках
function BulletTime(const speaker: Actor; params phrases: array of string): string;
/// не требует Dialogue.Open и Dialogue.Close
procedure Jojo;
/// не требует Dialogue.Open и Dialogue.Close
procedure Echoes;

implementation

uses Anim, Draw, Cursor, Procs, _Settings;


type
    DialogueInstance = class
    private
        const TEXT_DELAY: byte = 27;
        const LINE_END_DELAY: word = 400;
        fBoxWidth, NameWidth: byte;
        
        procedure WriteActor(const speaker: Actor);
        begin
            NameWidth := speaker.name.Length + 2;
            TxtClr(Color.White);
            writeln;
            Draw.Box(NameWidth, 1);
            Cursor.GoTop(-2);
            Cursor.SetLeft(2);
            TxtClr(speaker.color);
            writeln(speaker.name);
        end;
    
    protected
        function Handled(const s: string): boolean; virtual;
        begin
            Result := False;
            ClrKeyBuffer;
            if DEBUGMODE then write(s)
            else begin
                Anim.Text(s, TEXT_DELAY);
                sleep(LINE_END_DELAY);
            end;
            TxtClr(Color.Cyan);
            write(' ');
            Anim.Next1;
            writeln;
            TxtClr(Color.White);
        end;
        
        procedure SetBoxWidth(longest_len: integer); virtual := fBoxWidth := longest_len + 3;
        
        property BoxWidth: byte read fBoxWidth;
    
    public
        
        procedure Say(const speaker: Actor; const phrases: array of string);
        begin
            if DEBUGMODE then
                if (phrases.Length = 0) then raise new Exception('НЕТ СТРОК В DIALOGUE.SAY()');
            var longest_phrase: string := phrases.MaxBy(q -> q.Length);
            SetBoxWidth(longest_phrase.Length);
            WriteActor(speaker);
            if DEBUGMODE then
                if (fBoxWidth + 3) > MIN_WIDTH then
                    raise new Exception('СЛИШКОМ БОЛЬШАЯ СТРОКА ДИАЛОГА: "' + longest_phrase
                                         + '" [' + longest_phrase.Length + '].');
            TxtClr(Color.White);
            if (fBoxWidth = NameWidth) then
                writeln('├', '─' * NameWidth, '┤')
            else if (fBoxWidth < NameWidth) then
                writeln('├', '─' * fBoxWidth, '┬', '─' * (NameWidth - fBoxWidth - 1), '┘')
            else
                writeln('├', '─' * NameWidth, '┴', '─' * (fBoxWidth - NameWidth - 1), '┐');
            foreach n: string in phrases do
            begin
                writeln('│', ' ' * fBoxWidth, '│');
                writeln('└', '─' * fBoxWidth, '┘');
                Cursor.GoTop(-2);
                Cursor.SetLeft(2);
                TxtClr(Color.Yellow);
                if Handled(n) then break;
                TxtClr(Color.White);
            end;
        end;
        
        procedure Jojo;
        begin
            SetBoxWidth(64);
            for var k: boolean := False to True do
            begin
                WriteActor(k ? Actors.Sanya : Actors.Kostyl);
                TxtClr(Color.White);
                writeln('├', '─' * NameWidth, '┴', '─' * (fBoxWidth - NameWidth - 1), '┐');
                writeln('│', ' ' * fBoxWidth, '│');
                writeln('└', '─' * fBoxWidth, '┘');
                WritelnX2;
                Cursor.SetLeft(2);
                Cursor.GoTop(-3);
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
                sleep(TEXT_DELAY);
            end;
        end;
        
        procedure Echo(const speaker: Actor; params s_arr: array of string);
        const
            ECHOLEN: byte = 3;
            PADDING: byte = 2;
        begin
            Say(speaker, s_arr);
            Cursor.GoTop(-4);
            TxtClr(Color.White);
            NameWidth := 5;
            Cursor.SetLeft(fBoxWidth + ECHOLEN);
            writeln('┌', '─' * NameWidth, '┐');
            Cursor.SetLeft(fBoxWidth + ECHOLEN);
            write('│', ' ' * NameWidth, '│');
            Cursor.SetLeft(fBoxWidth + ECHOLEN + PADDING);
            TxtClr(Color.DarkYellow);
            writeln('Эхо');
            TxtClr(Color.White);
            var longest_len := (s_arr.Max.Length + 3);
            for var m: byte := 0 to 2 do
            begin
                Cursor.SetLeft(fBoxWidth + 3);
                case m of
                    0: writeln('├', '─' * NameWidth, '┴', '─' * (longest_len - NameWidth - 1), '┐');
                    1: writeln('│', ' ' * longest_len, '│');
                    2: writeln('└', '─' * longest_len, '┘');
                end;//case end
            end;
            Cursor.GoTop(-2);
            Cursor.SetLeft(fBoxWidth + ECHOLEN + PADDING);
            TxtClr(Color.DarkCyan);
            Anim.Text(s_arr.Max, TEXT_DELAY);
            sleep(LINE_END_DELAY);
            TxtClr(Color.Cyan);
            write(' ');
            Anim.Next1;
            ClrKeyBuffer;
            writeln;
        end;
        
        constructor Create;
        begin
            Anim.Next3;
            Cursor.GoTop(-1); 
        end;
        
        destructor Destroy;
        begin
            WritelnX2;
            TxtClr(Color.White);
        end;
    end;
    
    BulletTimeInstance = class(DialogueInstance)
    private
        fCaught: string := nil;
    
    protected
        function Handled(const s: string): boolean; override;
        begin
            if DEBUGMODE then
                if (s.Count(q -> q = '{') > 2) or (s.Count(q -> q = '}') > 2) then
                    raise new Exception('СЛИШКОМ МНОГО ФИГУРНЫХ СКОБОК {}: "' + s + '"')
                else if (s.Count(q -> q = '{') <> s.Count(q -> q = '}')) then
                    raise new Exception('НЕЗАКРЫТЫЕ ФИГУРНЫЕ СКОБКИ {}: "' + s + '"');
            for var c: integer := 1 to s.Length do
            begin
                if (c = s.IndexOf('{') + 1) then TxtClr(Color.Cyan)
                else if (c = s.LastIndexOf('}') + 1) then TxtClr(Color.Yellow)
                else write(s[c]);
                var spintime: word := (c = s.Length) ? 1000 : (TEXT_DELAY + 10);
                if System.Threading.SpinWait.SpinUntil(() ->
                (KeyAvail and (ReadKey in [Key.Enter, Key.Tab, Key.Select, Key.Spacebar])), spintime) then
                begin
                    var highlighted: string := s[s.IndexOf('{') + 2:s.LastIndexOf('}') + 1:1];
                    if (s.Contains('{')) and (c > s.IndexOf('{')) then begin
                        Cursor.SetLeft(2);
                        TxtClr(Color.Yellow);
                        write(s.Left(s.IndexOf('{')));
                        TxtClr(Color.DarkCyan);
                        BgClr(Color.White);
                        write(highlighted);
                        TxtClr(Color.Yellow);
                        BgClr(Color.Black);
                        write(s.Substring(s.LastIndexOf('}') + 1));
                        fCaught := highlighted;
                    end
                    else fCaught := '';
                    break;
                end;
            end;
            writeln;
            Result := (fCaught <> nil);
        end;
        
        procedure SetBoxWidth(longest_len: integer); override := inherited SetBoxWidth(longest_len - 1);
    
    public
        property Caught: string read fCaught;
        
        constructor Create;
        begin
            inherited Create;
        end;
        
        destructor Destroy;
        begin
            inherited Destroy;
            fCaught := nil;
        end;
    end;
// type end

var
    current: DialogueInstance;

// todo убрать в релизе
procedure __CheckIsDialogueOpened;
begin
    if not DEBUGMODE then exit;
    if (current = nil) then raise new Exception('НЕТ ОТКРЫТОГО ДИАЛОГА');
end;

// убрать в релизе
procedure __CheckIsDialogueClosed;
begin
    if not DEBUGMODE then exit;
    if (current <> nil) then raise new Exception('ДИАЛОГ УЖЕ ОТКРЫТ');
end;

procedure Open;
begin
    __CheckIsDialogueClosed;
    current := new DialogueInstance;
end;

procedure Close;
begin
    __CheckIsDialogueOpened;
    current.Destroy;
    current := nil;
end;

procedure Say(const speaker: Actor; params phrases: array of string);
begin
    __CheckIsDialogueOpened;
    current.Say(speaker, phrases);
end;

procedure FastSay(const speaker: Actor; params phrases: array of string);
begin
    Open;
    current.Say(speaker, phrases);
    Close;
end;

function BulletTime(const speaker: Actor; params phrases: array of string): string;
begin
    __CheckIsDialogueClosed;
    var current_bt: BulletTimeInstance := new BulletTimeInstance;
    current_bt.Say(speaker, phrases);
    if (current_bt.Caught <> nil) then
    begin
        writeln;
        Anim.Objection;
    end;
    TxtClr(Color.White);
    Result := current_bt.Caught;
    current_bt.Destroy;
    current_bt := nil;
end;

procedure Jojo;
begin
    Open;
    current.Jojo;
    Close;
    Anim.Next3;
end;

procedure Echoes;
begin
    Open;
    current.Echo(Actors.Sanya, 'Грррр...', 'КОООСТЯЯЯЯЯЯЯЯЯЯЯЯЯЯЯЯ!!!');
    current.Echo(Actors.Kostyl, 'СССССАААНЯ!');
    Close;
end;

initialization

finalization
    current := nil;

end.
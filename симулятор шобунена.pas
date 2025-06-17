// СИМУЛЯТОР ШОБУНЕНА
// игра в жанре text adventure/interactive fiction про саню шобунена
// язык: PascalABC.Net

program shobu_sim;
{$APPTYPE console}
{$TITLE Симулятор Шобунена}
{$VERSION Alpha v4} // TODO
{$STRING_NULLBASED-}

uses Procs, Scenes, Inventory, Anim, Cursor, Achievements, Chat, Achs;
uses Plot_Prologue;
uses _Log, _Settings;

{$REGION интро}

procedure TITLESCREEN;
const
    TITLE_TOP: array of string = (
        '   _                     __    __   ____   ___   ___ ',
        '  /   |   /  \  /  \  / |  |  |  | |____| |   | |   |',
        ' /    |  /|  |\/|   \/  |  |  |__|   ||   |   | |___|',
        '|     | / |  |  |   /   |  |    /|   ||   |   | |    ',
        ' \    |/  |  |  |  /    /  |   / |   ||   |   | |    ',
        '  \_  /   |  |  | /    /   |  /  |   ||   |___| |    ');
    TITLE_BOTTOM: array of string = (
        '       __   ___              ___                ',
        '| | | |  | |      \  / |  | |    |  |     /\    ',
        '| | | |  | |       \/  |  | |___ |  |    /  \   ',
        '| | | |  | |___    /   |==| |    |==|   /====\  ',
        '| | | |  | |   |  /    |  | |    |  |  /      \ ',
        '|_|_| |__| |___| /     |  | |___ |  | /        \');
begin
    ClrScr;
    TxtClr(Color.Green);
    foreach x: string in TITLE_TOP do writeln(PadCenter(x, BufWidth - 1));
    BeepWait(500, 450);
    foreach y: string in TITLE_BOTTOM do writeln(PadCenter(y, BufWidth - 1));
    BeepWait(500, 450);
    writeln;
    TxtClr(Color.Cyan);
    writeln(PadCenter(('ВЕРСИЯ ' + VERSION.ToUpper), BufWidth - 1), NewLine);
    TxtClr(Color.DarkGreen);
    BeepWait(500, 450);
    writeln(PadCenter('НАЖМИТЕ ЛЮБУЮ КЛАВИШУ, ЧТОБЫ НАЧАТЬ', BufWidth - 1));
    BeepWait(700, 450);
    ClrKeyBuffer;
    ReadKey;
    ClearLine(True);
end;

procedure WHATSNEW;// todo
begin
    TxtClr(Color.Cyan);
    WriteEqualsLine;
    writeln('// Список изменений:');
    writeln('//    - очень крупные правки текста, дизайна и кода');
    writeln('//    - полностью переделана система обработки команд');
    writeln('//    - добавлено меню выбора вариантов');
    writeln('//    - полностью изменена система логов');
    writeln('//    - добавлена система диалогов персонажей');
    writeln('//    - добавлена система достижений (ачивок)');
    writeln('//    - полностью переделана система инвентаря и получения предметов');
    writeln('//    - добавлена система подсказок при первом прохождении');
    writeln('//    - добавлено новое событие (в двух вариантах), если пойти по лестнице');
    writeln('//    - добавлено событие с подключением жёсткого диска к компьютеру');
    writeln('//    - полностью переделана мини-игра с выбиванием дверей');
    writeln('//    - событие с просмотром "притяжения" заменено на новую мини-игру');
    writeln('//    - (временно?) удалена мини-игра с выгуливанием собаки');
    writeln('//    - прыжок в окно после побега из лифта больше не даёт геймовер');
    writeln('//    - полностью переделана драка с костылём'); // todo
    writeln('//    - временно отключены анимации в чатах');
    WriteEqualsLine;
    ReadKey;
    writeln('// В прошлой версии здесь было написано, что последующие версии игры будут написаны на другом языке');
    writeln('вместо PascalABC.Net... но портировать это говно слишком сложно, так что пусть остаётся как было.');
    WriteEqualsLine;
    writeln;
    ReadKey;
end;

{$ENDREGION}

{$REGION gameloop}
function GAMELOOP: boolean;
begin
    Result := True;
    Inventory.Reset;
    foreach current_scene: Scene in START_SCENE.Chain do
        // части просто проходимые без геймоверов:
        if (current_scene is Cutscene) then Cutscene(current_scene).Run
        // части с возможностью геймовера:
        else begin
            if (current_scene <> START_SCENE) then
            begin
                writeln;
                Anim.Next3;
                TxtClr(Color.Green);
                writeln('Контрольная точка.');
                Anim.Next1;
                writelnx2;
                Console.Beep;  
            end;
            Inventory.Save;
            while not PlayableScene(current_scene).Passed() do
            begin
                Achs.GameOver.Achieve;
                _Log.Log('=== геймовер');
                Anim.Next3;
                TxtClr(Color.Red);
                writeln('G A M E   O V E R');
                BeepWait(700, 300);
                BeepWait(600, 300);
                BeepWait(450, 500);
                writeln;
                TxtClr(Color.Green);
                writeln('Вернуться на последнюю контрольную точку? (Y/N)');
                writeln;
                if YN then
                begin
                    _Log.Log('= ОТКАТ');
                    WriteEqualsLine;
                    writeln('Контрольная точка загружена.');
                    WriteEqualsLine;
                    Anim.Next3;
                    Inventory.Load;
                end
                else begin
                    writeln('Начать заново? (Y/N)');
                    if YN then
                    begin
                        _Log.Log('=== РЕСТАРТ');
                        TITLESCREEN;
                    end;
                    exit;
                end;
            end;
        end;
    Anim.Next3;
    TxtClr(Color.Cyan);
    writeln('<=== TO BE CONTINUED...');
    writeln;
    Anim.Next1;
    Achievements.DisplayAll;
    TxtClr(Color.Green);
    writeln('Конец демо-версии. Перезапустить? (Y/N)');
    if YN then
    begin
        _Log.Log('=== ФУЛЛ РЕСТАРТ');
        
        ClrScr;
        TxtClr(Color.Green);
        WriteEqualsLine;
        writeln('П Е Р Е З А П У С К . . .');
        WriteEqualsLine;
        writeln;
        sleep(500);
        // todo убрать и заменить на titlescreen
        
    end
    else Result := False;
end;
{$ENDREGION}

{$REGION main}
begin
    Console.Title := 'СИМУЛЯТОР ШОБУНЕНА ' + VERSION.ToLower; 
    
    if DEBUGMODE then
    begin
        writeln('DEBUG MODE');
        Console.Title += ' [DEBUG MODE]';
        WriteEqualsLine;
        Chat.Skip := True;
    end
    else TITLESCREEN;
    
    _Log.Init;
    
    if not DEBUGMODE then WHATSNEW;
    
    try
        while GAMELOOP() do{};
    except
        on _ex_: Exception do Catch(_ex_);
    end;
    
    writeln;
    // TODO проверить чтобы БЫЛА пауза перед выходом
end.
{$ENDREGION}

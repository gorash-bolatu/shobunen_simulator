// СИМУЛЯТОР ШОБУНЕНА
// игра в жанре text adventure/interactive fiction про саню шобунена
// язык: PascalABC.Net

{$DEFINE DOOBUG} // todo
program shobu_sim;
{$APPTYPE console}
{$TITLE Симулятор Шобунена}
{$VERSION Alpha v4} // TODO
{$STRING_NULLBASED-}

uses Procs, Scenes, Inventory, Anim, Cursor, Achievements, Chat, Routes, Achs, Versioning;
uses Plot_Prologue;
uses _Log;

{$REGION интро}

procedure TITLESCREEN;
begin
    ClrScr;
    TxtClr(Color.Green);
    writeln('                           _                     __    __   ____   ___   ___ ');
    writeln('                          /   |   /  \  /  \  / |  |  |  | |____| |   | |   |');
    writeln('                         /    |  /|  |\/|   \/  |  |  |__|   ||   |   | |___|');
    writeln('                        |     | / |  |  |   /   |  |    /|   ||   |   | |    ');
    writeln('                         \    |/  |  |  |  /    /  |   / |   ||   |   | |    ');
    writeln('                          \_  /   |  |  | /    /   |  /  |   ||   |___| |    ');
    BeepWait(500, 450);
    writeln('                                  __   ___              ___                ');
    writeln('                           | | | |  | |      \  / |  | |    |  |     /\    ');
    writeln('                           | | | |  | |       \/  |  | |___ |  |    /  \   ');
    writeln('                           | | | |  | |___    /   |==| |    |==|   /====\  ');
    writeln('                           | | | |  | |   |  /    |  | |    |  |  /      \ ');
    writeln('                           |_|_| |__| |___| /     |  | |___ |  | /        \');
    BeepWait(500, 450);
    writeln;
    TxtClr(Color.Cyan);
    writeln('                                           ВЕРСИЯ ', VERSION.ToUpper);
    writeln;
    TxtClr(Color.DarkGreen);
    BeepWait(500, 450);
    writeln('                                 НАЖМИТЕ ЛЮБУЮ КЛАВИШУ, ЧТОБЫ НАЧАТЬ');
    BeepWait(700, 450);
    ClrKeyBuffer;
    ReadKey;
    ClearLine(True);
end;

procedure WHATSNEW;// todo
begin
    TxtClr(Color.DarkGreen);
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

{$REGION сюжет}
var
    
    sFork := new PlayableScene(PART4, 'драка с костылём');
    // todo переделать в ForkScene
    
    sStart := (new PlayableScene(PART1, 'комната')).Linkup(
    new PlayableScene(PART2, 'подъезд'),
    new Cutscene(PART3, 'выход на улицу'),
    sFork);
    
{$ENDREGION}

{$REGION gameloop}
function GAMELOOP: boolean;
begin
    Result := True;
    Inventory.Reset;
    Route.SetRoute(route_enum.Solo);
    foreach current_scene: Scene in sStart.Scenes do
    begin
        // части просто проходимые без геймоверов:
        if (current_scene is Cutscene) then current_scene.Run()
        // части с возможностью геймовера:
        else begin
            _Log.Log('=== часть: ' + current_scene.Name);
            Inventory.Save;
            while not current_scene.Passed() do
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
                Cursor.GoTop(-1);
                if YN then
                begin
                    _Log.Log('= ОТКАТ');
                    writeln;
                    WriteEqualsLine;
                    Anim.Next3;
                    Inventory.Load;
                end
                else begin
                    write('Начать заново? (Y/N)');
                    if YN then
                    begin
                        _Log.Log('=== РЕСТАРТ');
                        TITLESCREEN;
                    end;
                    exit;
                end;
            end;
            writeln;
            Anim.Next3;
            TxtClr(Color.Green);
            writeln('Контрольная точка.');
            Anim.Next1;
            writelnx2;
            Console.Beep;
            _Log.Log('=== чекпоинт: ' + current_scene.Name);
        end;
    end;
    TxtClr(Color.Cyan);
    writeln('<=== TO BE CONTINUED...');
    writeln;
    Anim.Next3;
    
    //            case Route.GetCurRoute of
    //                route_enum.Solo: aSolo.Achieve;
    //                route_enum.Rita: aRita.Achieve;
    //                route_enum.Trip: aTrip.Achieve;
    //                route_enum.Roma: aRoma.Achieve;
    //            end;
    // todo
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
    try
        Console.Title := 'СИМУЛЯТОР ШОБУНЕНА ' + VERSION.ToLower; 
        
        {$IFDEF DOOBUG}
        writeln('DEBUG MODE');
        Console.Title += ' [DEBUG MODE]';
        WriteEqualsLine;
        Chat.Skip := True;
        {$ELSE}
        TITLESCREEN;
        {$ENDIF}
        
        {$IFDEF DOOBUG}
        _Log.Init(True);
        {$ELSE}
        _Log.Init(False);
        {$ENDIF}
        
        {$IFNDEF DOOBUG}
        WHATSNEW;
        {$ENDIF}
        
        while GAMELOOP() do;
        writeln;
        // TODO проверить чтобы БЫЛА пауза перед выходом
    except
        on _ex_: Exception do Catch(_ex_);
    end;
end.
{$ENDREGION}

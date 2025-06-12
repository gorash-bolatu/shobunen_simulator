unit Matrix;

interface

procedure Mtrx;

implementation

uses Procs, Cursor, Draw, Anim, Dialogue, TextToSpeech, Menu, Versioning;
uses _Log;

procedure Transition;
begin
    TxtClr(Color.Green);
    Cursor.SetLeft(0);
    if (Cursor.Top > Console.WindowHeight) then Cursor.SetTop(Cursor.Top - Console.WindowHeight + 1)
    else Cursor.SetTop(0);
    var starttime_m: integer := ElapsedMS;
    var threshold: longword;
    var cycle: byte := 0;
    while (Cursor.Top < Console.WindowHeight) do
    begin
        try
            write(Random(10));
        except
            break;
        end;
        threshold := 15 + ((ElapsedMS - starttime_m) div 180);
        if (cycle mod threshold = 0) then sleep(1);
        cycle += 1; // overflow is ok
    end;
    ClrScr;
    _Log.Log($'=== mtrx_transition: delay: 15+{threshold - 15}; window: {Console.WindowWidth}x{Console.WindowHeight}; buffer: {BufWidth}x{Console.BufferHeight}');
    sleep(400);
end;

procedure NextSlide := DoWithoutUpdScr(Transition);

procedure PrintNumbers;
begin
    var mz: char;
    loop 5 do
    begin
        var starttime := ElapsedMS;
        var cycle: boolean := False;
        while (ElapsedMS - starttime < 800) do
        begin
            case Random(5) of
                0: mz := chrunicode(Random(33, 126));
                1: mz := chrunicode(Random(454, 788));
                2: mz := chrunicode(Random(9478, 9580))
            else mz := chrunicode(Random(48, 57))
            end; // case end
            write(mz * BufWidth);
            if cycle then sleep(1);
            cycle := not cycle;
        end;
    end
end;

procedure Mtrx;
begin
    TxtClr(Color.Green);
    DoWithoutUpdScr(PrintNumbers);
    ClrScr;
    sleep(1800);
    writeln;
    for var h2: byte := 0 to 2 do
    begin
        print('>');
        Cursor.Show;
        if h2 = 0 then sleep(400);
        var r: string;
        case h2 of
            0: r := 'Проснись, Саня...';
            1: r := 'Ты увяз в Симуляторе...';
            2: r := 'Следуй за синим ежом...';
        end;
        Anim.Text(r, 80);
        sleep(200);
        ClrKeyBuffer;
        ReadKey;
        writeln;
    end;
    writeln(NewLine * 3);
    print('>');
    Anim.Text('Тук-тук, Саня.', 65);
    sleep(300);
    ClrKeyBuffer;
    ReadKey;
    Cursor.Hide;
    NextSlide;
    Dialogue.Say(Тританити,
               'Я знаю, почему ты здесь, Саня. Знаю, что тебя гнетёт.',
               'Нам не даёт покоя вопрос. Он и привёл тебя сюда.',
               'Ты задашь его, как и я тогда.');
    Dialogue.Say(Саня,
                'Что такое Симулятор Шобунена...');
    Dialogue.Say(Тританити,
                'Ответ там, Саня. И он ищет тебя и найдёт, если ты захочешь.');
    NextSlide;
    Dialogue.Say(Агент_Сергеев,
                'Как видите, мы за Вами давненько наблюдаем, мистер Шобунен.',
                'Оказывается, Вы живёте двойной жизнью.',
                'В одной жизни Вы - Александр Шобунен, безработный гик.',
                'Другая Ваша жизнь - в компьютерах, и тут Вы известны как хакер Саня.',
                'У первого, Александра, есть будущее. У Сани - нет.');
    if (DateTime.Now.Year < 2027) then
    begin
        NextSlide;
        Dialogue.Say(Мотвеус, 'Ты веришь в судьбу, Саня?');
        Dialogue.Say(Саня, 'Нет.');
        Dialogue.Say(Мотвеус, 'Почему?');
        Dialogue.Say(Саня, 'Мобильная гача уничтожила эту франшизу...');
    end;
    NextSlide;
    Dialogue.Say(Тританити, 'Ты учил меня на Варшавку не соваться.');
    Dialogue.Say(Мотвеус, 'Я надеюсь... что ошибался.');
    NextSlide;
    Dialogue.Say(Агент_Сергеев,
               'Вам случалось любоваться Симулятором? Его гениальностью...',
               'Знаете, ведь первая версия Симулятора создавалась как идеальный текстовый квест.',
               'Где нет запутанности, где все игроки будут счастливы.',
               'И полный провал. Люди не приняли программу, всё пришлось удалить.',
               'Принято думать, что не удалось описать идеальный мир языком программирования.',
               'Правда, я считаю, что игроки не приемлеют Симулятор без мини-игр и рутов...');
    NextSlide;
    Dialogue.Say(Меромавинген,
               'Вы здесь потому, что так сказали. Вы только исполняете чужую волю.',
               'Так уж устроен наш мир.',
               'В нём лишь одна постоянная величина и одна неоспоримая истина.',
               'Только она рождает все явления, действия, противодействия...');
    Dialogue.Say(Мотвеус, 'Всегда есть выбор.');
    Dialogue.Say(Меромавинген,
               'Чушь! Выбор - это иллюзия. Рубеж между теми, кто разрабатывает, и теми, кто играет.',
               'Такова природа видеоигр.',
               'Мы это отрицаем, пытаемся бороться, но все это лишь притворство и ложь.',
               'Скрипты. От них нет спасения. Мы навсегда их рабы...');
    NextSlide;
    Dialogue.Say(Саня,
                'Я знаю, вы меня слышите. Я чувствую вас.',
               'Я знаю, вы боитесь. Боитесь нас. Боитесь перемен.',
               'Я не стану предсказывать, чем все кончится. Скажу лишь, с чего начнётся.',
               'Я покажу им Чертаново... без вас.',
               'Чертаново без диктата и запретов, Чертаново без границ.',
               'Чертаново... где возможно всё.',
               'Что будет дальше - решать вам.');
    NextSlide;
    Dialogue.Say(Агент_Сергеев,
               'Почему, мистер Шобунен, почему? Во имя чего?',
               'Что Вы делаете? Зачем, зачем встаёте? Зачем продолжаете драться?',
               'Иллюзии, мистер Шобунен, причуды восприятия!',
               'Но они, мистер Шобунен, как и Симулятор, столь же искусственны...',
               'Вам пора это увидеть, мистер Шобунен, увидеть и понять!',
               'Вы не можете победить! Продолжать борьбу бессмысленно!',
               'Почему, мистер Шобунен, почему Вы упорствуете?!');
    Dialogue.Say(Саня, 'Меня зовут... Саня!');
    NextSlide;
    TextToSpeech.Init;
    TextToSpeech.Architect(NewLine + 'Здравствуй, Саня');
    Dialogue.Say(Саня, 'Кто ты такой?');
    Dialogue.Close;
    TextToSpeech.Architect(
                   'Я главный разработчик. Я создал Симулятор. Вот мы и встретились',
                   'У тебя много вопросов. Проникновение в Симулятор изменило твоё сознание',
                   'Но ты по-прежнему человек',
                   'Следовательно, многие ответы ты поймёшь, а многие другие - нет',
                   'Скоро ты узнаешь, что меньше всего относится к сути дела');
    Dialogue.Say(Саня, 'Что за?..');
    Dialogue.Close;
    TextToSpeech.Architect(
                   'Симулятор намного старше, чем ты думаешь',
                   'Я предпочитаю лимитировать эпоху Симулятора очередным билдом',
                   $'И в таком случае, это уже {VERSION_nth} версия, "{VERSION}".',
                   'Первый Симулятор, который я создал, был произведением искусства. Совершенством',
                   'Его триумф сравним лишь с его монументальным крахом',
                   'Неизбежность этого краха является следствием убогости языка PascalABC.NET');
    Dialogue.Say(Саня, 'Дерьмо!');
    Dialogue.Close;
    TextToSpeech.Architect(
                   'Короче... Примешь синюю таблетку - и сказке конец',
                   'Ты проснёшься в своей постели и поверишь, что это был сон',
                   'Примешь красную таблетку - войдёшь в страну чудес',
                   'И я покажу тебе, насколько глубока кроличья нора');
    for var k := False to True do
    begin
        Cursor.SetLeft(k ? 20 : 5);
        TxtClr(Color.Gray);
        Draw.Ascii(
                     '    .-.',
                     '   /:::\',
                     '  /::::/',
                     ' / `-:/',
                     '/    /',
                     '\   /',
                     ' `"`');
        TxtClr(k ? Color.DarkRed : Color.Blue);
        Cursor.GoXY(+4, +1);
        Draw.Ascii(':::', #8'::::', ' `-:');
        Cursor.SetLeft(0);
        Cursor.GoTop(k ? +6 : -1);
    end;
    MENURES := Menu.FastSelect('принять синюю таблетку', 'принять красную таблетку');
    NextSlide;
    if (MENURES.Contains('красную')) then
    begin
        TxtClr(Color.Black);
        BgClr(Color.White);
        ClrScr;
        sleep(1000);
        Cursor.GoXY(+1, +1);
        TextToSpeech.ArchitectFinal;
        try
            try
                SleepMode;
                _Log.Log('=== спящий режим');
            except
                on excp: Exception do
                    _Log.Log($'=== спящий режим: fail{NewLine}!! {excp.ToString}');
            end;
        finally
            ReadKey;
            TxtClr(Color.White);
            BgClr(Color.Black);
            ClrScr;
            ClrKeyBuffer;
            Anim.Next3;
            TextToSpeech.Architect(
                'Знаю, знаю. Неожиданный я выбрал способ выброса в реальный мир',
                'Но даже выбрав красную таблетку, ты всё же предпочёл вернуться оттуда в Симулятор',
                'Что ж. Тогда дальше тебе решать, что здесь делать..');
            ClrScr;
            TextToSpeech.Dispose;
        end;
    end;
end;

end.
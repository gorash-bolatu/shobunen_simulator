// СИМУЛЯТОР ШОБУНЕНА
// игра в жанре text adventure/interactive fiction про саню шобунена
// версия: Alpha 2
// язык: PascalABC.Net

program shobu_sim;
{$APPTYPE console}
{$TITLE Симулятор Шобунена}
{$STRING_NULLBASED-}
{$REFERENCE System.Windows.Forms.dll}
{$RESOURCE fakecode.c}

uses Cursor, MyTimers, Procs, Achievements, Inventory, Tutorial, Draw, Anim, Chat, Menu,
    TextToSpeech, Dialogue, SlashingMinigame, ButtonMashMinigames, Scenes;
uses _Log;

{$DEFINE DOOBUG} // todo
// TODO проверить чтобы БЫЛА пауза перед выходом

{$REGION глобальные_константы}
const
    VERSION: string = 'Alpha v2'; // todo
    VERSION_nth: string = 'четырнадцатая';// todo
{$ENDREGION}

{$REGION руты}
type
    
    route_enum = (Solo, Rita, Trip, Roma);
    
    Route = static class
    private
        static current_route: route_enum;
    public
        static TextedVasya, TextedRita, TextedRoma: boolean;
        static procedure SetRoute(newroute: route_enum) := current_route := newroute;
        static function GetRoute(): route_enum := current_route;
    end;// static class end
// type end
{$ENDREGION}

{$REGION глобальные_инстансы}

    {$REGION предметы}
const
    itCola: Item = (name: 'Бутылка колы');
    itCharger: Item = (name: 'Зарядка от ноутбука');
    itHdd: Item = (name: 'Жёсткий диск');
    itShard: Item = (name: 'Осколок зеркала');
    itDog: Item = (name: 'Юпитер');
{$ENDREGION}

    {$REGION ачивки}
var
    achSolo: Achievement := new Achievement(
    'CHERTANOVO NO KYOUKAI ~ the garden of sanya',
    'Получить сольную концовку',
    'Живя обычной жизнью, Саня однажды неожиданно попадает в смертельную опасность, когда на него нападает странный сверхчеловек. Чудом выживая благодаря появившемуся из ниоткуда князю Владимиру, Саня оказывается втянут в мир магии и Чертановскую Войну КиноГрааля...');
    
    achRita: Achievement := new Achievement(
    'FATE / CHERTANOVO',
    'Получить концовку Риты',
    'Живя обычной жизнью, Саня однажды неожиданно попадает в смертельную опасность, когда на него нападает странный сверхчеловек. Чудом выживая, Саня обретает новую разрушительную способность, связанную с его глазами - теперь он видит "линии говна". Пытаясь разобраться в происходящем, Саня оказывается втянут в мир магии и Чертановскую Войну КиноГрааля... ');
    
    achTrip: Achievement := new Achievement(
    'SASHOK''S BIZZARE ADVENTURE',
    'Получить концовку Трипа',
    'Живя обычной жизнью, Саня (вместе с остальными жителями Чертанова) вдруг получает сверхспособность в виде гуманоидного духа - Стэндсону. Из-за таинственного злодея в районе начинает происходить тотальный хаос, и только Саня с Трипом при помощи своих Стэндсон могут спасти Чертаново...');
    
    achRoma: Achievement := new Achievement(
    'ACE ATTORNEY: SANYA SHOBUNEN',
    'Получить концовку Ромы',
    'Живя обычной жизнью, Саня однажды становится свидетелем жестокого убийства своего друга. В силу обстоятельств ему приходиться самостоятельно заняться расследованием и найти убийцу. Но дело оказывается запутанным, а под подозрением все знакомые Сани и даже он сам...');
    
    achGameOver: Achievement := new Achievement(
    'ООООО ПОВЕЗЛО ПОВЕЗЛО',
    'Заспидранить игру на плохую концовку',
    'Выйти на любую плохую концовку и получить game over. Самый быстрый способ - в начале игры выпрыгнуть в окно.');
    
    achSherlock: Achievement := new Achievement(
    'ХЕРЛОК ШОЛМС',
    'Найти зарядку в квартире Шобунена');
    
    achHelloWorld: Achievement := new Achievement(
    'HELLO, WORLD',
    'Отыскав зарядку в квартире Шобунена, зарядить и включить ноутбук');
    
    achEscapeMaster: Achievement := new Achievement(
    'ОСТОРОЖНО, ДВЕРИ ЗАКРЫВАЮТСЯ',
    'Выбраться из застрявшего лифта в подъезде',
    'Выйдя из квартиры, сесть в лифт. Когда он застрянет, разбить зеркало, осколком стекла подрезать люк на потолке, взобраться наверх и долбить по кнопкам, чтобы раздвинуть двери.');
    
    achRaid: Achievement := new Achievement(
    'ПИРАТ ТОРРЕНТСКОГО МОРЯ',
    'Попасть в облаву после закачки фильмов на комп',
    'Выполнить то же, что и для достижения "Hello, World", и скачать на компьютере пиратские фильмы. Затем переодеться и попробовать выйти из квартиры.');
    
    achParkour: Achievement := new Achievement(
    'ПАРКУР - МОЛОДЁЖНОЕ ДВИЖЕНИЕ',
    'Выпрыгнуть из окна второго этажа подъезда и не разбиться',
    'Одеться и выйти из квартиры, поехать на лифте и выбраться из него (сломать зеркало, подрезать им люк, забраться наверх и выбить дверь), после чего прыгнуть в окно.');
    
    achHackerman: Achievement := new Achievement(
    'ХАКАТОН',
    'Закончить мини-игру с программированием за полминуты или быстрее',
    'Выполнить шаги для получения ачивки "Hello, World", начать программировать игру "Ultimate Alliance" и быстро печатать, чтобы успеть написать код за 30 секунд.');
    
    achOraOraOra: Achievement := new Achievement(
    'ОРА-ОРА-ОРА!',
    'Победить Костыля в финальной битве рута Трипа',
    'Подразумевается при получении ачивки "SaShok''s Bizzare Adventure". Сама битва непроста: придётся не только яростно долбить по клавишам (особенно в режиме "костыльской ярости"), но и поджидать возможность контратаковать, когда снизится получаемый урон (на что может уйти вплоть до пары минут).');
    
    // todo использовать и добавить новые ачивки
    
    achMatrix: Achievement := new Achievement(
    'СИМУЛЯТРИЦА',
    'Открыть таинственный файл на жёстком диске',
    'В комнате Шобунена порыться в ящике - там будет жёсткий диск. Найти зарядку от ноутбука, зарядить и включить его, подключить диск и узнать, насколько глубока кроличья нора...');
{$ENDREGION}

{$ENDREGION}

procedure EscapeRoom(proc: procedure);
begin
    Anim.Next3;
    TxtClr(Color.Yellow);
    writeln('=== SEEK A WAY OUT! ===');
    writeln;
    BeepWait(580, 230);
    BeepWait(460, 230);
    BeepWait(280, 230);
    BeepWait(300, 380);
    TxtClr(Color.White);
    proc();
    TxtClr(Color.Yellow);
    writeln('=== YOU FOUND IT ===');
    BeepWait(300, 200);
    Anim.Next3;
end;

{$REGION сюжет}

{$region матрица}
procedure MatrixTransition :=
DoWithoutUpdScr(() ->
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
end);

procedure Matrix;
begin
    TxtClr(Color.Green);
    var mz: char;
    DoWithoutUpdScr(() ->
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
    end);
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
    MatrixTransition;
    Dialogue.Say(Тританити,
               'Я знаю, почему ты здесь, Саня. Знаю, что тебя гнетёт.',
               'Нам не даёт покоя вопрос. Он и привёл тебя сюда.',
               'Ты задашь его, как и я тогда.');
    Dialogue.Say(Саня,
                'Что такое Симулятор Шобунена...');
    Dialogue.Say(Тританити,
                'Ответ там, Саня. И он ищет тебя и найдёт, если ты захочешь.');
    MatrixTransition;
    Dialogue.Say(Агент_Сергеев,
                'Как видите, мы за Вами давненько наблюдаем, мистер Шобунен.',
                'Оказывается, Вы живёте двойной жизнью.',
                'В одной жизни Вы - Александр Шобунен, безработный гик.',
                'Другая Ваша жизнь - в компьютерах, и тут Вы известны как хакер Саня.',
                'У первого, Александра, есть будущее. У Сани - нет.');
    if (DateTime.Now.Year < 2027) then
    begin
        MatrixTransition;
        Dialogue.Say(Мотвеус, 'Ты веришь в судьбу, Саня?');
        Dialogue.Say(Саня, 'Нет.');
        Dialogue.Say(Мотвеус, 'Почему?');
        Dialogue.Say(Саня, 'Мобильная гача уничтожила эту франшизу...');
    end;
    MatrixTransition;
    Dialogue.Say(Тританити, 'Ты учил меня на Варшавку не соваться.');
    Dialogue.Say(Мотвеус, 'Я надеюсь... что ошибался.');
    MatrixTransition;
    Dialogue.Say(Агент_Сергеев,
               'Вам случалось любоваться Симулятором? Его гениальностью...',
               'Знаете, ведь первая версия Симулятора создавалась как идеальный текстовый квест.',
               'Где нет запутанности, где все игроки будут счастливы.',
               'И полный провал. Люди не приняли программу, всё пришлось удалить.',
               'Принято думать, что не удалось описать идеальный мир языком программирования.',
               'Правда, я считаю, что игроки не приемлеют Симулятор без мини-игр и рутов...');
    MatrixTransition;
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
    MatrixTransition;
    Dialogue.Say(Саня,
                'Я знаю, вы меня слышите. Я чувствую вас.',
               'Я знаю, вы боитесь. Боитесь нас. Боитесь перемен.',
               'Я не стану предсказывать, чем все кончится. Скажу лишь, с чего начнётся.',
               'Я покажу им Чертаново... без вас.',
               'Чертаново без диктата и запретов, Чертаново без границ.',
               'Чертаново... где возможно всё.',
               'Что будет дальше - решать вам.');
    MatrixTransition;
    Dialogue.Say(Агент_Сергеев,
               'Почему, мистер Шобунен, почему? Во имя чего?',
               'Что Вы делаете? Зачем, зачем встаёте? Зачем продолжаете драться?',
               'Иллюзии, мистер Шобунен, причуды восприятия!',
               'Но они, мистер Шобунен, как и Симулятор, столь же искусственны...',
               'Вам пора это увидеть, мистер Шобунен, увидеть и понять!',
               'Вы не можете победить! Продолжать борьбу бессмысленно!',
               'Почему, мистер Шобунен, почему Вы упорствуете?!');
    Dialogue.Say(Саня, 'Меня зовут... Саня!');
    MatrixTransition;
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
                   $'И в таком случае, это уже {VERSION_nth} версия, "{VERSION}"',
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
    MatrixTransition;
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
                System.Windows.Forms.Application.SetSuspendState(System.Windows.Forms.PowerState.Suspend, True, False);
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
    {$ENDREGION}

    {$REGION 1. КОМНАТА САНИ}
function PART1: boolean;
var
    charger_location: byte := Random(7);
    broke_bed, broke_window, broke_box, broke_laptop, burned_laptop, broke_table, changed_clothes, charged_laptop,
    found_charger, tried_breaking_wardrobe, hit_table, watched_utub, torrenting_movies, played_cossacks,
    played_megamuzhik, programmed, used_empty_hdd, saw_matrix, texted_trip, tried_texting_rita: boolean;
    
    {$REGION чаты}
    procedure chat_prompt;
    begin
        print('Кому ты напишешь?');
        if not Route.TextedVasya then print('Васе?');
        if not texted_trip then print('Трипу?');
        if not Route.TextedRoma then
        begin
            print('Роме?');
            if not tried_texting_rita then print('Рите?')
        end
        else if not Route.TextedRita then print('Рите?');
        writeln('Или никому?');
    end;
    
    procedure Chats;
    begin
        writeln('О, сейчас несколько твоих корешей находятся в сети!');
        writeln('Это Вася - странноватый помешанный на энергетиках торчок...');
        writeln('Трип - немного загадочный и вечно сонливый чудак...');
        writeln('Рита - девушка, которая тебе... а... ну...');
        writeln('И Рома - главный чел на районе; его знают все пацаны с Чертанова.');
        writeln('Кому ты напишешь?');
        while True do
        begin// while begin
            CMDRES := ReadCmd('написать');
            case CMDRES of // case2 begin
                'VASYA':
                    if Route.TextedVasya then writeln('Ты уже писал Васе!') else
                    begin
                        Chat.Name := ('Вася');
                        Chat.DrawTop;
                        Chat.Enter('Привет вась че как');
                        Chat.Response('отстаньте от меняяяяяяяяф');
                        Chat.Enter('Оу');
                        Chat.Response('блииииииин мне оч пльхо', 'я слтшком многр энергосов выпил походу');
                        Chat.Enter('Че у тебя опять передоз');
                        Chat.Response('да ты зкдолбааааал');
                        Chat.Enter('Понятно');
                        Chat.Response('слушпй давай не сцгодня а');
                        Chat.Enter('Ладно тогда пока');
                        writelnx2;
                        Route.TextedVasya := True;
                        writeln('По-видимому, сегодня у Васи не очень хороший день.');
                    end;
                'TRIP':
                    if texted_trip then writeln('Ты уже писал Трипу!') else
                    begin
                        Chat.Name := ('ТРNПАН0С0М03');
                        Chat.DrawTop;
                        Chat.Enter('Привет трип че как');
                        Chat.Response('Привет, всё отлично.', 'Правда, проснулся совсем недавно.');
                        Chat.Enter('Эх твой режим сна как всегда');
                        Chat.Response('Хе-хе.', 'Ладно, говори, что там по новостям.');
                        if Route.TextedRoma then
                        begin
                            Chat.Enter('Мы с ромой собрались на тусу');
                            Chat.Response('На стоянке которая?');
                            Chat.Enter('Погоди откуда ты знаешь');
                            Chat.Response('Он мне писал, позвал прийти.', 'А что, звучит хайпово.');
                            Chat.Enter('То есть ты тоже идёшь');
                            Chat.Response('Угу.');
                        end
                        else begin
                            Chat.Enter('Хм ну вообще новостей нет');
                            Chat.Response('Понимаю.', 'Давай в ТЦ пойдём, что ли. Встречаемся у гаражей.');
                        end;
                        Chat.Enter('Ок звучит неплохо давай');
                        writelnx2;
                        texted_trip := True;
                        if not Route.TextedRoma then writeln('Ты договорился встретиться с Трипом у гаражей.');
                    end;
                'ROMA':
                    if Route.TextedRoma then writeln('Ты уже писал Роме!') else
                    begin
                        Chat.Name := ('Рома Кафератор');
                        Chat.DrawTop;
                        Chat.Enter('Привет рома че как');
                        Chat.Response('ЙОУ ДОРОВА БЛЯТЬ', 'КАРОЧ');
                        Chat.Enter('Что');
                        Chat.Response('СЕГОДНЯ ЧЕТКАЯ ТУСА НА ПАРКОВКЕ', 'ГО');
                        Chat.Enter('И что за туса');
                        Chat.Response('НУ БЛЯ ВСЕ НАШИ ПАЦАНЫ СОБИРАЮТСЯ', 'МУЗЛО БАДЯГА ДЕВКИ САСНЫЕ ВСЕ ДЕЛА');
                        Chat.Enter('Ну не знаю');
                        Chat.Response('ДА МЛЯ ПРИХОДИ НОРМ ТЕМА');
                        Chat.Enter('Ладно');
                        Chat.Response('ЗАЕБИСЬ ТАМ НА МЕСТЕ ВСТРЕТИМСЯ');
                        if texted_trip then
                        begin
                            Chat.Enter('Слушай а я с трипом уже договорился');
                            Chat.Response('ООО НИШТЯК ОН ТОЖЕ ИДЕТ?');
                            Chat.Enter('Пока не знаю');
                            Chat.Response('Я С НИМ ПОБАЗАРЮ ПРО ЭТО', 'КАРОЧ ДО СВЯЗИ');
                        end;
                        writelnx2;
                        Route.TextedRoma := True;
                        writeln('Ты договорился пойти с Ромой на "тусу" на стоянке.');
                        if tried_texting_rita then writeln('И кстати, Рита тем временем снова появилась в сети!');
                    end;
                'RITA':
                    if Route.TextedRita then writeln('Ты уже писал Рите!')
                    else if Route.TextedRoma then
                    begin
                        Chat.Name := ('Маргарита Тесакова');
                        Chat.DrawTop;
                        Chat.DrawSides;
                        TxtClr(Color.Blue);
                        writeln('Вы');
                        Chat.DrawSides;
                        writeln('Привет рита че как');
                        Chat.DrawSides;
                        writeln('Рита');
                        Chat.DrawSides;
                        writeln('Алееее че как там');
                        Chat.DrawSides;
                        writeln;
                        Chat.DrawSides;
                        TxtClr(Color.Blue);
                        writeln(Chat.Name);
                        Chat.DrawSides;
                        TxtClr(Color.White);
                        writeln('привет :) занята была');
                        Chat.DrawSides;
                        writeln;
                        Chat.Enter('Рома написал что сегодня на парковке будет туса');
                        Chat.Response('?');
                        Chat.Enter('Там все пацаны с района собираются');
                        Chat.Response('какие ещё пацаны :/');
                        Chat.Enter('Да они нормальные');
                        Chat.Response('хорошо но причём здесь я');
                        Chat.Enter('Ну я иду прост хочешь со мной');
                        Chat.Response('нуууууууу ._.');
                        Chat.Enter('Короче если хочешь приходи туда');
                        Chat.Response('ок я подумаю (-~-)');
                        writelnx2;
                        Route.TextedRita := True;
                        writeln('Получается, Рита согласилась пойти с тобой?');
                    end
                    else if tried_texting_rita then writeln('Рита сейчас не отвечает.')
                    else begin
                        writeln('Ты пишешь Рите, но она почему-то сейчас не отвечает.');
                        writeln('Может, стоит попробовать позже? А пока - написать кому-нибудь ещё.');
                        tried_texting_rita := True;
                    end;
                'HOMIES': {ignore};
                'OFF': break;
            else writeln('Ты не можешь написать этому человеку.'); // case2 else
            end; // case2 end
            if (Route.TextedVasya and Route.TextedRita) then
            begin
                ClearLine(True);
                writeln('Итак, ты написал всем корешам, кто сейчас онлайн.');
                Chat.Skip := True;
                break;
            end
            else chat_prompt;
        end; //while end
        Chat.Name := nil;
    end;
    {$ENDREGION}
    
    {$REGION компьютер}
    
    {$REGION программирование}
    procedure ProgrammingTime;
    const
        ProgWidth: byte = 86;
    var
        stm: DateTime;
        
        function SpeedrunTime: string;
        begin
            var stm_ppt: System.TimeSpan := DateTime.Now.Subtract(stm);
            Result := (stm_ppt.Minutes < 1) ? (stm_ppt.ToString('mm\:ss\,fff')) : 'bruh      ';
        end;
        
        procedure srtm;
        var
            curpos: word;
        begin
            while not KeyAvail do
            begin
                curpos := Cursor.Left;
                Cursor.SetLeft(89);
                TxtClr(Color.Cyan);
                write(SpeedrunTime);
                Cursor.SetLeft(curpos);
                TxtClr(Color.DarkGreen);
                sleep(1);
            end;
            Cursor.Show;
            _Log.mInputs += 1;
            _Log.Val.Add(MillisecondsDelta);
        end;
        
        procedure srtmclr;
        begin
            Cursor.SetLeft(89);
            write(' ' * SpeedrunTime.Length);
        end;
    
    begin
        (_Log.mInputs, _Log.mTime) := (0, 0);
        writeln('СПИДРАН ПО ПРОГРАММИРОВАНИЮ' + TAB + 'ПОЕХАЛИ');
        var OH_NO: array of string := TextFromResourceFile('fakecode.c').Split(
            NewLine.ToCharArray, System.StringSplitOptions.RemoveEmptyEntries);
        TxtClr(Color.Gray);
        BgClr(Color.Black);
        writeln('┌', '─' * ProgWidth, '┐');
        Cursor.Show;
        stm := DateTime.Now;
        _Log.Val.Clear; MillisecondsDelta;
        for var line := 0 to (Length(OH_NO) - 1) do
        begin
            BgClr(Color.Black);
            Cursor.SetLeft(0);
            TxtClr(Color.Gray);
            write('│', ' ' * ProgWidth, '│');
            Cursor.SetLeft(2);
            TxtClr(Color.DarkGreen);
            ClrKeyBuffer;
            if (line < 5) or (Random(1 + Floor(1.015 * line)) = 0) then srtm;
            foreach ch: char in OH_NO[line] do
            begin
                ClrKeyBuffer;
                if (Random(5 * Floor(1.015 ** line)) = 0) then srtm;
                write(ch);
            end;
            srtmclr;
            writeln;
        end;
        _Log.mTime := DateTime.Now.Subtract(stm).TotalMilliseconds.Round;
        if (DateTime.Now.Subtract(stm).TotalSeconds <= 30) then achHackerman.Achieve;
        Cursor.Hide;
        TxtClr(Color.Gray);
        BgClr(Color.Black); // ?
        writeln('├', '─' * ProgWidth, '┤');
        writeln('│', ' ' * ProgWidth, '│');
        writeln('└', '─' * ProgWidth, '┘');
        ClrKeyBuffer;
        ReadKey;
        sleep(300);
        Cursor.GoXY(+2, -2);
        TxtClr(Color.Red);
        write('Compilation error: Segmentation fault (core dumped) at address 0x');
        loop 3 do write(Random(MaxSmallInt).ToString('X'));
         // ToString('X') конвертирует из десятичной системы в шестнадцатиричную
        writeln;
        sleep(800);
        ClrKeyBuffer;
        ReadKey;
        Cursor.GoTop(-(OH_NO.Length + 4));
        ClearLines((OH_NO.Length + 6), True);
        TxtClr(Color.White);
        ClrKeyBuffer;
        writeln('Очередная попытка написать код для "Ultimate Alliance" оборачивается провалом!');
        writeln('Все эти месяцы изучения программирования по индийским туториалам оказались бесполезны.');
        writeln('Оказывается, создавать видеоигры не так-то просто...');
        Console.WindowTop -= Console.WindowHeight div 3;
        programmed := True;
        
        _Log.Log('======= Presses: ' + _Log.mInputs.ToString);
        _Log.Log('======= AvgCharsPerPress: ' + (5212 / _Log.mInputs).ToString);
        _Log.Log('======= Time: ' + _Log.mTime.ToString);
        _Log.Val.Sort;
        _Log.Log('======= AvgPressTime: ' + (_Log.Val.Average).ToString);
        _Log.Log('======= Median: ~' + (_Log.Val.Item[_Log.Val.LongCount div 2]).ToString);
        _Log.Log('======= Min: ' + (_Log.Val.First).ToString);
        _Log.Log('======= Max: ' + (_Log.Val.Last).ToString);
        _Log.Val.Clear;
        CollectGarbage;
        
    end;
    {$ENDREGION}
    
    procedure Computer;
    begin
        writeln('Ты садишься за ноутбук', (torrenting_movies ? '.' : ' и включаешь его.'));
        writeln('Ты можешь написать корешам, посмотреть Рутуб или скачать плохие российские фильмы.');
        writeln('Также на компьютере несколько игр: "Казачки", "Megamuzhik", бета-версия "UNBG"...');
        writeln('Наконец, на рабочем столе папка с твоей собственной игрой "Ultimate Alliance".');
        if Inventory.Has(itHdd) then writeln('Ах да, ещё у тебя с собой тот жёсткий диск - его можно подключить.');
        writeln('Итак, что ты будешь делать с компьютером?');
        repeat
            if not (Route.TextedVasya and Route.TextedRita) then Menu.Load('написать друзьям');
            if not watched_utub then Menu.Load('смотреть Рутуб');
            if not torrenting_movies then Menu.Load('качать плохие российские фильмы');
            if not played_cossacks then Menu.Load('играть в Казачков');
            if not played_megamuzhik then Menu.Load('играть в Мегамужика');
            Menu.Load('играть в UNBG');
            if not programmed then Menu.Load('программировать Ultimate Alliance');
            if (Inventory.Has(itHdd) and not used_empty_hdd) then Menu.Load('подключить жёсткий диск');
            if not Inventory.IsEmpty then Menu.Load('проверить инвентарь');
            Menu.Load(torrenting_movies ? 'отойти от компьютера' : 'выключить компьютер');
            MENURES := Menu.UnloadSelect;
            case MENURES of // case begin
                {-} 'написать друзьям': Chats;
                {-} 'смотреть рутуб':
                    begin
                        writeln('Ты открываешь Рутуб и проверяешь раздел "В тренде".');
                        writeln('Картина печальная.');
                        writeln('Лайфхаки, эксперименты, политота, топы, телепередачи, тупые интервью...');
                        writeln('Музыкальные клипы, "челленджи", летсплеи, реакции; что-то на казахском...');
                        writeln('Видео для детей с кричащими заголовками и обложками...');
                        Anim.Next3;
                        writeln('Вместо всего этого вырвиглазного ужаса ты решаешь посмотреть кое-что другое.');
                        writeln('Ты заходишь на канал самого непредвзятого и неподкупного игроблогера в мире.');
                        writeln('О, да! От его видео у тебя 12 мурашек на кончиках 10 пальцев!');
                        writeln('Ты смотришь один его обзор, затем ещё один, и ещё один, и...');
                        writeln('Ого! Прошёл уже целый час. Пожалуй, тебе пора закончить смотреть Рутуб.');
                        watched_utub := True;
                    end;
                {-} 'качать плохие российские фильмы':
                    begin
                        writeln('Ты открываешь в интернете один популярный сайт с торрентами.');
                        writeln('Сейчас ты будешь скачивать все фильмы...');
                        writeln('Ты считаешь, что это как-нибудь насолит отечественным "киноделам".');
                        torrenting_movies := True;
                    end;
                {-} 'играть в казачков':
                    begin
                        writeln('Ты запускаешь лучшую стратегию в реальном времени всех времён и народов: "Казачки".');
                        writeln('Ты начинаешь катку за Россию против Турции.');
                        writeln('Твои крестьяне появляются в большой пустыне, окружённой морем.');
                        writeln('Ты строишь здания, налаживаешь экономику и отбиваешь атаки врага.');
                        Anim.Next3;
                        writeln('Твой отряд стрельцов отправляется на разведку и натыкается на внушительное войско.');
                        writeln('Несколько янычар вдруг начинают преследовать стрельцов! Придётся убегать!');
                        writeln('Ты строишь корабль, но не он доплывает до врага - судно топят две турецкие шебеки!');
                        Anim.Next3;
                        writeln('Продолжая нелепо убегать стрельцами от янычар, ты строишь линкор.');
                        writeln('Вдруг на экране появляется: "ТРЕВОГА! У ВАС ЗАКОНЧИЛОСЬ ЗОЛОТО! ПОДНЯЛСЯ МЯТЕЖ!"');
                        writeln('Твой собственный линкор сметает все твои здания и всех твоих крестьян!');
                        Anim.Next3;
                        writeln('А тем временем к тебе приходит то самое огромное турецкое войско.');
                        writeln('"ПОРАЖЕНИЕ!"');
                        writeln('...Ты закрываешь худшую стратегию в реальном времени всех времён и народов.');
                        played_cossacks := True;
                    end;
                {-} 'играть в мегамужика':
                    begin
                        writeln('Ты запускаешь "Мегамужика".');
                        writeln('Это эдакий "beat ''em up" в стилистике старых восьмибитных игр.');
                        writeln('Ты играешь за качка по прозвищу Мегамужик и раздаёшь тумаков другим качкам.');
                        writeln('Потому что этих других качков кто-то... подсаживает на анаболики?');
                        writeln('А шестеро из этих качков как бы боссы в игре?');
                        writeln('И после победы над ними нужно раздать тумаков ещё и... доктору Светлакову?');
                        writeln('Потому что этот доктор и подсаживал всех тех качков на препараты?..');
                        writeln('Кому вообще такое могло прийти в голову?!');
                        Anim.Next3;
                        writeln('Но тебя почему-то не особо волнует обкуренный сюжет и плохой геймплей.');
                        writeln('Тебе так нравится эта игра, что у тебя есть все комиксы про Мегамужика!');
                        writeln('Саня, ты в порядке?..');
                        writeln('Так или иначе, ты скоро устаёшь играть и решаешь заняться чем-нибудь ещё.');
                        played_megamuzhik := True;
                    end;
                {-} 'играть в unbg':
                    begin
                        writeln('Ты запускаешь бету новой игры "%UserName%BattleGrounds", или просто UNBG.');
                        writeln('Это многопользовательский трёхмерный шутер в жанре "королевской битвы".');
                        writeln('Эта игра сейчас у всех на слуху и быстро набирает популярность.');
                        writeln('Но потянет ли UNBG твой старенький ноутбук? Ты решаешь попробовать...');
                        Anim.Next3;
                        writeln('Ты заходишь на случайный сервер и начинаешь игру. Компьютер нагревается...');
                        writeln('Ты выставляешь настройки графики на минимум, но "тормоза" никуда не пропадают.');
                        writeln('Внезапно компьютер почему-то выключается и перестаёт работать.');
                        writeln('Ты чувствуешь запах гари и замечаешь, что из корпуса... идёт дымок.');
                        writeln('Ты только что спалил ноутбук!');
                        burned_laptop := True;
                        break;
                    end;
                {-} 'программировать ultimate alliance':
                    if programmed then writeln('Когда-нибудь ты продолжишь работу над "Ultimate Alliance". Наверное...')
                    else ProgrammingTime;
                {-} 'подключить жёсткий диск':
                    begin
                        TxtClr(Color.White);
                        writeln('Ты подключаешь жёсткий диск к компьютеру.');
                        if saw_matrix then
                        begin
                            writeln('Система показывает, что он... пуст? Но почему?');
                            writeln('Тебя не покидает чувство, что там точно что-то было...');
                            used_empty_hdd := True;
                        end
                        else begin
                            writeln('На нём хранится всего один файл: "симулятор_шобунена.exe".');
                            writeln('Ты не помнишь, чтобы записывал сюда что-либо подобное.');
                            writeln('Чтобы проверить, что это такое, ты открываешь программу, и...');
                            Anim.Next3;
                            sleep(500);
                            Matrix;
                            saw_matrix := True;
                            achMatrix.Achieve;
                            TxtClr(Color.DarkGreen);
                            loop 3 do WriteEqualsLine;
                            writeln;
                            TxtClr(Color.White);
                            writeln('Ты в ужасе просыпаешься на собственной кровати.');
                            writeln('Постепенно приходя в себя, ты понимаешь, что тебе приснился странный кошмар.');
                            writeln('Как странно... Он был так... реален...');
                            writeln('И когда ты вообще успел уснуть?..');
                            Anim.Next3;
                            writeln('В любом случае, в комнате всё осталось, как было.');
                            writeln('Что ты будешь делать здесь дальше?');
                            Tutorial.ShowCheckHint;
                            exit;
                        end;
                    end;
                {-} 'сломать ноутбук':
                    begin
                        writeln('Ты берёшь ноутбук, заносишь его над головой и бросаешь об пол.');
                        writeln('Все компоненты с грохотом разлетаются по комнате.');
                        broke_laptop := True;
                        break;
                    end;
            else // case else
                begin
                    print('Ты', (torrenting_movies ? 'отходишь от компьютера' : 'выключаешь компьютер'), 'и решаешь заняться чем-нибудь другим.');
                    break;
                end
            end; // case end
            writeln('Что ты будешь делать с компьютером дальше?');
        until False;
        writeln;
        writeln('Что ты будешь делать дальше?');
        Tutorial.ShowCheckHint;
    end;
    {$ENDREGION}
    
    {$REGION поиск зарядки}
    procedure Charger_Investigation;
    begin
        writeln('Детектив Шобунен пытается найти зарядное устройство.');
        writeln('Методом дедукции он приходит к заключению, что оно точно в его квартире.');
        writeln('Но где?');
        writeln('Ящик с барахлом? Стол? Шкафчик стола?');
        writeln('Под столом? Под шкафом? Под кроватью? На кухне?');
        writeln('Детектив приступает к поиску.');
        repeat
            CMDRES := ReadCmd('проверить');
            case CMDRES of
                'BOX', 'BOX_BOX':
                    begin
                        writeln('Детектив тщательно роется в ящике, проверяя каждую вещь.');
                        if charger_location = 0 then
                        begin
                            writeln('И зарядное устройство попадает к нему в руки.');
                            writeln('Блестящее расследование.');
                            found_charger := True;
                        end
                        else writeln('Увы, здесь зарядки нет.');
                    end;
                'TABLE':
                    begin
                        writeln('Детектив Шобунен обводит глазами стол.');
                        if charger_location = 1 then
                        begin
                            writeln('На нём таки оказывается искомая зарядка. Прямо рядом с ноутбуком.');
                            writeln('...Да, неловко получилось.');
                            found_charger := True;
                        end
                        else writeln('Увы, здесь зарядки нет.');
                    end;
                'LOCKER', 'LOCKER_TABLE', 'TABLE_LOCKER':
                    begin
                        writeln('Детектив проверяет шкафчик стола.');
                        if charger_location = 2 then
                        begin
                            writeln('Именно здесь находилось зарядное устройство.');
                            writeln('Блестящее расследование.');
                            found_charger := True;
                        end
                        else writeln('Увы, здесь зарядки нет.');
                    end;
                'WARDROBE', 'UNDER_WARDROBE':
                    begin
                        writeln('Детектив проверяет пространство под шкафом.');
                        if charger_location = 3 then
                        begin
                            writeln('По какой-то причине зарядка лежит здесь.');
                            writeln('Блестящее расследование.');
                            found_charger := True;
                        end
                        else writeln('Увы, здесь зарядки нет.');
                    end;
                'UNDER_TABLE':
                    if hit_table then
                    begin
                        writeln('Детектив Шобунен аккуратно залезает под стол.');
                        writeln('Удивительно, но зарядки здесь по-прежнему нет...');
                    end
                    else begin
                        writeln('Детектив залезает под стол и ударяется об него головой. Немного больно.');
                        hit_table := True;
                        if charger_location = 4 then
                        begin
                            writeln('Зато он находит здесь зарядное устройство.');
                            writeln('Блестящее расследование.');
                            found_charger := True;
                        end
                        else writeln('И зарядки здесь нет...');
                    end;
                'BED', 'UNDER_BED':
                    begin
                        writeln('Детектив проверяет под кроватью.');
                        if charger_location = 5 then
                        begin
                            writeln('Именно здесь по какой-то причине находилось зарядное устройство.');
                            writeln('Блестящее расследование.');
                            found_charger := True;
                        end else writeln('Увы, здесь зарядки нет.');
                    end;
                'KITCHEN':
                    begin
                        writeln('Детектив Шобунен перемещается в кухонное помещение и тщательно обыскивает каждый закуток.');
                        if charger_location = 6 then
                        begin
                            writeln('В конце концов зарядное устройство находится рядом с розеткой.');
                            writeln('Блестящее расследование.');
                            found_charger := True;
                        end else writeln('Увы, здесь зарядки нет. Детектив возвращается в свою комнату.');
                    end;
                'OFF':
                    begin
                        writeln('Детектив прекращает расследование, оставшись ни с чем.');
                        break;
                    end;
            else writeln('В этом месте не получится искать.');
            end; // case charger
        until found_charger;
        if found_charger then
        begin
            Inventory.Obtain(itCharger);
            achSherlock.Achieve;
        end;
    end;
    {$ENDREGION}

{$REGION комната}
begin
    Result := False;
    Route.TextedRita := False;
    Route.TextedVasya := False;
    Route.TextedRoma := False;
    TxtClr(Color.White);
    writeln('Тебя зовут Саня Шобунен.');
    writeln('Ты живёшь в старенькой многоэтажке в московском районе Чертаново.');
    writeln('У тебя есть несколько корешей на районе. Ты часто с ними тусуешься.');
    writeln('Ты любишь играть в игры на компьютере и угарать над плохими российскими фильмами.');
    writeln('Тебе также нравится смотреть видео на Рутубе (в том числе обзоры на плохие российские фильмы).');
    writeln;
    writeln('Сейчас ты стоишь посреди своей комнаты.');
    writeln('В ней есть кровать, шкаф, окно, ящик с барахлом и стол.');
    writeln('На столе ноутбук и недопитая тобой вчерашняя бутылка колы.');
    writeln('Что ты будешь делать?');
    if not Tutorial.CommandH.Shown then
    begin
        Tutorial.Comment(
            'набирать на клавиатуре, enter для ввода',
            'все команды на русском в инфинитиве: напр. не "возьму/возьми колу", а "взять колу"',
            'историю команд можно листать стрелками вверх/вниз');
        Tutorial.CommandH.Show;
    end;
    ClrKeyBuffer;
    while True do
    begin// while begin
        CMDRES := ReadCmd;
        case CMDRES of // case begin
            {-} 'CHECK':
                begin
                    writeln('Сейчас ты стоишь посреди своей комнаты.');
                    writeln('В ней есть кровать, шкаф, окно, ящик с барахлом и стол.');
                    if broke_table then
                    begin
                        write('Стол разбит, как и стоявший на нём ноутбук.');
                        if not Inventory.Has(itCola) then write(' На полу валяется бутылка с колой.');
                        writeln;
                    end
                    else
                    begin
                        write('На столе ноутбук');
                        if not Inventory.Has(itCola) then write(' и недопитая тобой вчерашняя бутылка колы');
                        writeln('.');
                    end;
                    if (broke_bed or broke_box or (broke_laptop and not broke_table) or burned_laptop or broke_window) then
                    begin
                        if broke_bed then print('Кровать сломана.');
                        if broke_box then print('Ящик раздолбан.');
                        if (broke_laptop and not broke_table) then print('Ноутбук разбит.')
                        else if burned_laptop then print('Ноутбук сгорел.');
                        if broke_window then print('Окно выбито.');
                        writeln;
                    end;
                end;
            {-} 'CHECK_TABLE', 'SIT_TABLE', 'USE_TABLE':
                if broke_table then writeln('Посреди комнаты валяется опрокинутый стол. Рядом с ним - обломки компа и бутылка колы.')
                else writeln('На столе ноутбук и недопитая тобой вчерашняя бутылка колы.');
            {-} 'BREAK_TABLE', 'JUMP_TABLE', 'THROW_TABLE':
                if broke_table then writeln('Ты уже перевернул стол!')
                else begin
                    writeln('Ты переворачиваешь стол. С него на пол летят все вещи.');
                    writeln('О нет! Твой дорогущий ноутбук ломается пополам! Такое не отремонтировать...');
                    if not Inventory.Has(itCola) then writeln('Зато бутылка, вроде, осталась в порядке.');
                    broke_table := True;
                    broke_laptop := True;
                end;
            {-} 'SIT', 'OPEN_HDD', 'USE_HDD', 'OPEN_PC', 'GO_PC', 'GET_PC', 'SIT_PC', 'USE_PC', 'PLAY_PC',
            'WRITE', 'WRITE_VASYA', 'WRITE_ROMA', 'WRITE_TRIP', 'WRITE_RITA', 'WRITE_HOMIES', 'WRITE_CHAT',
            'OPEN_CHAT', 'OPEN_CHAT_HOMIES', 'CHAT_HOMIES', 'CHECK_UTUB', 'OPEN_UTUB', 'CHECK_VIDEO',
            'OPEN_VIDEO', 'CHECK_VIDEO_UTUB', 'OPEN_VIDEO_UTUB', 'CHECK_UTUB_VIDEO', 'OPEN_UTUB_VIDEO',
            'TORRENT', 'TORRENT_FILMS', 'CHECK_FILMS', 'OPEN_FILMS', 'PLAY', 'PLAY_COSSACKS', 'OPEN_COSSACKS',
            'GO_COSSACKS', 'PLAY_MEGAMAN', 'OPEN_MEGAMAN', 'GO_MEGAMAN', 'PLAY_UNBG', 'OPEN_UNBG', 'GO_UNBG',
            'PLAY_ULT_ALL', 'OPEN_ULT_ALL', 'CODE', 'WRITE_CODE', 'ULT_ALL', 'CODE_ULT_ALL', 'WRITE_ULT_ALL',
            'PLAY_ULT', 'PLAY_ALL', 'OPEN_ULT', 'OPEN_ALL', 'CODE_ULT', 'CODE_ALL', 'WRITE_ULT', 'WRITE_ALL',
            'GO_ULT_ALL', 'GO_ULT', 'GO_ALL', 'WRITE_CODE_ULT_ALL', 'WRITE_CODE_ULT', 'WRITE_CODE_ALL',
            'OPEN_CODE', 'CODE_CODE', 'OPEN_CODE_ULT_ALL', 'CODE_CODE_ULT_ALL', 'OPEN_CODE_ULT', 'CODE_CODE_ULT',
            'OPEN_CODE_ALL', 'CODE_CODE_ALL':
                if broke_laptop then writeln('Ты сломал компьютер!') else
                if burned_laptop then writeln('Ты спалил компьютер!') else
                if charged_laptop then
                    if CMDRES.Contains('HDD') then
                        if Inventory.Has(itHdd) then Computer else
                        begin
                            if not broke_box then writeln('Ты достаёшь жёсткий диск из ящика с кучей старых запылившихся вещей.');
                            writeln('Ого, тут целый терабайт! С этим можно что-то сделать...');
                            Inventory.Obtain(itHdd);
                            Anim.Next3;
                            Computer;
                        end
                    else Computer
                else begin
                    writeln('Ты садишься за стол и открываешь крышку ноутбука.');
                    writeln('Ты пытаешься включить его, но комп не работает - разряжен.');
                    if found_charger then writeln('Кажется, у тебя как раз есть зарядка - попробуй зарядить компьютер.')
                    else writeln('Придётся найти зарядку.');
                end;
            {-} 'BREAK_PC', 'THROW_PC':
                if broke_laptop then writeln('Ты уже сломал компьютер!') else
                begin
                    writeln('Ты берёшь ноутбук, заносишь его над головой и бросаешь об пол.');
                    writeln('Все компоненты с грохотом разлетаются по комнате.');
                    broke_laptop := True;
                end;
            {-} 'GET_CHARGER', 'DETECTIVE':
                if found_charger then println('Ты уже', (Inventory.Has(itCharger) ? 'нашёл' : 'использовал'), 'зарядку!')
                else begin
                    TxtClr(Color.Yellow);
                    writeln('=== РАССЛЕДОВАНИЕ ===');
                    BeepWait(400, 400);
                    TxtClr(Color.White);
                    writeln;
                    Charger_Investigation;
                    sleep(500);
                    TxtClr(Color.Yellow);
                    writeln;
                    write('=== ЗАВЕРШЕНО');
                    if not found_charger then write('?..');
                    writeln(' ===');
                    BeepWait(600, 230);
                    TxtClr(Color.White);
                end;
            {-} 'CHARGE', 'CHARGE_PC', 'CHARGER_PC', 'OPEN_CHARGER', 'OPEN_PC_CHARGER', 'OPEN_CHARGER_PC',
            'USE_CHARGER', 'USE_PC_CHARGER', 'USE_CHARGER_PC':
                if broke_laptop then writeln('Вряд ли ты сможешь зарядить то, что осталось от ноутбука...')
                else if burned_laptop then writeln('Ты спалил компьютер!')
                else if charged_laptop then writeln('Компьютер уже заряжается! Можно за него сесть.')
                else if not Inventory.Has(itCharger) then writeln('Для этого понадобится найти зарядку.')
                else begin
                    Inventory.Use(itCharger);
                    writeln('Ты подключаешь зарядку и начинаешь заряжать компьютер.');
                    writeln('Теперь его наконец-то можно включить.');
                    charged_laptop := True;
                end;
            {-} 'CHECK_BOTTLE', 'CHECK_COLA', 'GET_BOTTLE', 'GET_COLA', 'GET_BOTTLE_COLA', 'GET_COLA_BOTTLE',
            'DRINK_BOTTLE', 'DRINK_COLA', 'DRINK_BOTTLE_COLA', 'DRINK_COLA_BOTTLE':
                if Inventory.Has(itCola) then
                    if CMDRES.StartsWith('DRINK') then writeln('Пожалуй, это тебе ещё пригодится...')
                    else writeln('Ты уже взял колу.')
                else begin
                    print('Ты берёшь');
                    if not broke_table then print('со стола');
                    writeln('недопитую бутылку колы.');
                    Inventory.Obtain(itCola);
                    if CMDRES.StartsWith('DRINK') then writeln('Пожалуй, это тебе ещё пригодится...');
                end;
            {-} 'SIT_BED', 'SLEEP', 'SLEEP_BED', 'GO_BED', 'GOUP_BED', 'OPEN_BED', 'GO_SLEEP', 'SIT_SLEEP', 'BED_SLEEP':
                if broke_bed then writeln('Ты сломал кровать!')
                else begin
                    write('Ты ложишься на свою кровать.');
                    if changed_clothes then write(' В уличной одежде, да.');
                    writeln;
                    writeln('Ты бы поспал, но за окном день, да и ты только проснулся недавно.');
                    writeln('Ты смотришь в потолок.');
                    writeln('Ты продолжаешь смотреть в потолок.');
                    writeln('Ты всё ещё смотришь в потолок.');
                    writeln('Это тупо.');
                    writeln('Ты решаешь прекратить страдать фигнёй и встаёшь с кровати.');
                end;
            {-} 'BREAK_BED', 'JUMP_BED':
                if broke_bed then writeln('Ты уже сломал свою кровать!')
                else begin
                    writeln('Ты прыгаешь на свою кровать.');
                    writeln('Она достаточно хлипкая и вряд ли бы выдержала.');
                    writeln('Неудивительно, что теперь ты лежишь в куче того, что осталось от твоей кровати.');
                    broke_bed := True;
                    if broke_window then writeln('Видимо, окна тебе не хватило...');
                end;
            {-} 'DRESS_CLOTHES':
                // todo убрать это говно
                begin
                    sleep(500);
                    TxtClr(Color.Red);
                    Anim.Text('НАДЕТЬ', 800);
                    ClrKeyBuffer;
                    if System.Environment.ProcessorCount > 1 then BeepAsync(1600, MaxInt);
                    repeat
                        sleep(1);
                        write('Ь' * BufWidth);
                        if KeyAvail then Halt;
                    until False;
                end;
            {-} 'GET_CLOTHES', 'GET_CLOTHES_WARDROBE', 'GET_WARDROBE', 'CHECK_WARDROBE', 'CHANGECLOTHES',
            'OPEN_WARDROBE', 'GO_WARDROBE', 'GOUP_WARDROBE':
                if changed_clothes then writeln('Ты уже переоделся.')
                else begin
                    writeln('Ты открываешь шкаф, достаёшь уличную одежду и переодеваешься в неё.');
                    changed_clothes := True;
                end;
            {-} 'BREAK_WARDROBE':
                if tried_breaking_wardrobe then writeln('Ты уже пытался - шкаф неприступен.')
                else begin
                    writeln('Ты наносишь удар по шкафу со всей силы!..');
                    writeln('Через мгновение руку пронзает боль, и ты осознаёшь, что это была не лучшая идея.');
                    writeln('Тогда ты пытаешься опрокинуть шкаф, но он оказывается слишком тяжёлым.');
                    writeln('В ярости ты начинаешь молотить по шкафу руками со всех сторон!');
                    Dialogue.Say(Саня, 'ОРАОРАОРАОРАОРАОРАОРАОРАОРАОРАОРА!!!');
                    Dialogue.Close;
                    writeln('Шкафу всё равно.');
                    writeln('...Ты решаешь оставить эту затею.');
                    tried_breaking_wardrobe := True;
                end;
            {-} 'CHECK_WINDOW', 'OPEN_WINDOW', 'CHECK_STREET':
                begin
                    print('Из');
                    if broke_window then print('разбитого');
                    writeln('окна виден обычный чертановский двор.');
                    writeln('Вдалеке стоят гаражи, куда ты иногда ходишь тусоваться с корешами.');
                    writeln('Район и так серый и депрессивный, а сегодня на улице ещё и пасмурно...');
                end;
            {-} 'BREAK_WINDOW':
                if broke_window then writeln('Ты уже разбил окно!') else
                begin
                    writeln('Ты выбиваешь кулаком стекло.');
                    writeln('Это довольно больно. И... тупо.');
                    broke_window := True;
                end;
            {-} 'GO_WINDOW', 'JUMP_WINDOW', 'JUMP_STREET':
                begin
                    if broke_window then writeln('Ты открываешь окно и... выпрыгиваешь из него!')
                    else writeln('Ты разбегаешься и выпрыгиваешь из окна!');
                    writeln('Стоп, почему ты летишь с высоты седьмого этажа прямо на землю?');
                    writeln('Кажись, это была не очень хорошая идея...');
                    exit; // gameover
                end;
            {-} 'GET_HDD', 'GET_HDD_BOX', 'GET_BOX_HDD':
                if Inventory.Has(itHdd) then writeln('Ты уже взял жёсткий диск из ящика.') else
                begin
                    if not broke_box then writeln('Ты достаёшь свой ящик с кучей старых запылившихся вещей.');
                    writeln('Ты ищещь некий жёсткий диск и... находишь его!');
                    writeln('Ого, тут целый терабайт! С этим можно что-то сделать...');
                    Inventory.Obtain(itHdd);
                end;
            {-} 'BREAK_BOX', 'BREAK_BOX_BOX':
                if broke_box then writeln('Ты уже сломал ящик!')
                else begin
                    writeln('Ты пинаешь ящик со всей силы, и все вещи внутри ломаются и разлетаются по комнате.');
                    writeln('Отличная работа?');
                    broke_box := True;
                end;
            {-} 'CHECK_BOX', 'GET_BOX', 'CHECK_BOX_BOX', 'GET_BOX_BOX':
                if broke_box then writeln('Ты сломал ящик вместе с вещами!')
                else begin
                    writeln('Ты достаёшь свой ящик с кучей старых запылившихся вещей.');
                    writeln('Здесь куча странных комиксов: "Мухоград", "Мегамужик", "Раскраска для детей"...');
                    writeln('Также есть несколько плохих российских фильмов на дисках...');
                    writeln('Школьные тетради с учебниками, настолки, заначка с деньгами...');
                    writeln('Сейчас это всё тебе вряд ли будет нужно.');
                    if not Inventory.Has(itHdd) then
                    begin
                        writeln('Но вот жёсткий диск на целый терабайт! С ним уже можно что-то сделать...');
                        Inventory.Obtain(itHdd);
                    end;
                end;
            {-} 'GO', 'GO_STREET':
                if not changed_clothes then writeln('Перед выходом на улицу тебе нужно переодеться.')
                else begin
                    writeln('Ты выходишь из квартиры.');
                    writeln('Сегодня родителей нет дома, так что придётся готовить завтрак самому, но...');
                    writeln('Тебе слишком лень, и ты решаешь уйти на голодный желудок.');
                    Anim.Next3;
                    writeln('С тобой из двери выбегает собака. Это твоя такса, Юпитер.');
                    writeln('Похоже, он просится на улицу. Что ж, вам по пути!');
                    Inventory.SilentObtain(itDog);
                    if torrenting_movies then
                    begin
                        Anim.Next3;
                        writeln('Но вдруг ты слышишь звонок в дверь. Кто бы это мог быть?');
                        writeln('Ты идёшь открывать дверь, но по ней кто-то начинает громко дубить.');
                        Anim.Next3;
                        writeln('Вдруг дверь с треском падает, ты слышишь крики, кто-то хватает тебя и валит на пол.');
                        writeln('Юпитер рычит и лает, но его вышвыривают за дверь.');
                        writeln('Тебе закручивают руки, а вокруг появляются несколько мужиков в форме с автоматами.');
                        writeln('И дула этих автоматов направлены на тебя.');
                        writeln('Один из них грозно орёт матом и что-то тебе зачитывает.');
                        writeln('Другой внимательно разглядывает твой ноутбук и что-то докладывает остальным.');
                        writeln('Вот и накачал плохих российских фильмов...');
                        achRaid.Achieve;
                        exit; // gameover
                    end;
                    writeln('Ты прихватываешь собаку с собой и выходишь из квартиры.');
                    break;
                end;
        else begin
                writeln('Ты не можешь это сделать. Попробуй что-нибудь ещё.');
                Tutorial.ShowCheckHint;
            end;
        end; // case end
    end; // while end
    if Route.TextedRoma then Route.SetRoute(Roma)
    else if texted_trip then Route.SetRoute(Trip);
    Result := True;
end;
{$ENDREGION}

    {$ENDREGION}

    {$REGION 2. КОРИДОР}
procedure Elevator;
begin
    var tried_emergency_button, opened_hatch: boolean;
    writeln('Из-за пропавшего света тебе придётся действовать вслепую.');
    writeln('Не видел ли ты в этом лифте что-то, что может помочь выбраться?');
    if not Tutorial.ElevatorH.Shown then writeln('Что если попробовать сломать эту штуку...');
    while True do
    begin// while begin
        CMDRES := ReadCmd;
        case CMDRES of
            {-}'CHECK', 'GET':
                if opened_hatch then writeln('Возможно, стоит подняться наверх?')
                else if Inventory.Has(itShard) then
                    writeln('Люк на потолке... Можно попытаться открыть его осколком стекла!')
                else writeln('Точно, зеркало! Вдруг с ним что-то можно сделать?..');
            {-}'GET_DOG': writeln('Юпитер и так с тобой!');
            {-}'CALL', 'PRESS', 'CALL_PRESS', 'PRESS_CALL':
                if tried_emergency_button then writeln('Никто не отвечает, сколько ты не жал бы на кнопку.')
                else begin
                    if CMDRES = 'PRESS' then writeln('Ты пытаешься понажимать какие-нибудь кнопки. Ничего не работает...');
                    writeln('Ты нащупываешь кнопку связи с диспетчером и жмёшь её.');
                    writeln('Через несколько минут тебе наконец отвечает какая-то сварливая тётка.');
                    writeln('Она мерзким голосом объявляет, что сегодня лифтёры не приедут.');
                    writeln('На твоё мямленье она раздражённо говорит выбираться самостоятельно.');
                    writeln('После этого никто не отвечает, сколько ты бы не жал на кнопку.');
                    tried_emergency_button := True;
                end;
            {-}'JUMP', 'BREAK', 'JUMP_LIFT', 'BREAK_LIFT':
            writeln('Ты прыгаешь в лифте несколько раз, но он никуда не двигается.');
            {-}'BREAK_DOORS': writeln('Двери не поддаются!');
            {-}'KISS_MIRROR':
                begin
                    writeln('Ты... э... целуешь зеркало.');
                    writeln('Похоже, это нисколько не помогает тебе выбраться из лифта.');
                end;
            {-}'TAKEOFF_MIRROR', 'BREAK_DOG', 'BREAK_MIRROR', 'BREAK_MIRROR_DOG', 'BREAK_DOG_MIRROR', 'CUT_MIRROR',
            'THROW_DOG', 'THROW_MIRROR', 'THROW_MIRROR_DOG', 'THROW_DOG_MIRROR', 'GET_DOG_BREAK_MIRROR', 'GET_MIRROR',
            'BREAK_MIRROR_BOTTLE', 'BREAK_BOTTLE_MIRROR', 'THROW_MIRROR_BOTTLE', 'THROW_BOTTLE_MIRROR',
            'BREAK_MIRROR_COLA', 'BREAK_COLA_MIRROR', 'THROW_MIRROR_COLA', 'THROW_COLA_MIRROR',
            'BREAK_MIRROR_BOTTLE_COLA', 'BREAK_BOTTLE_COLA_MIRROR', 'THROW_MIRROR_BOTTLE_COLA', 'THROW_BOTTLE_COLA_MIRROR',
            'BREAK_MIRROR_COLA_BOTTLE', 'BREAK_COLA_BOTTLE_MIRROR', 'THROW_MIRROR_COLA_BOTTLE', 'THROW_COLA_BOTTLE_MIRROR',
            'THROW_COLA', 'THROW_BOTTLE', 'THROW_COLA_BOTTLE', 'THROW_BOTTLE_COLA', 'GET_DOG_THROW_MIRROR':
                if Inventory.Has(itShard) then writeln('Ты уже сломал зеркало.')
                else begin
                    if CMDRES.IsMatch('^TAKEOFF|GET_M') then
                    begin
                        writeln('Ты пытаешься снять зеркало со стены, но оно наглухо прикручено.');
                        writeln('Пытаясь оторвать, ты трясешь его... и так сильно, что оно лопается!');
                    end
                    else if CMDRES.Contains('DOG') then
                    begin
                        writeln('Ты хватаешь Юпитера и со всей силы кидаешь его в зеркало.');
                        writeln('Оно с треском разбивается, а собака громко взвизгивает и падает на пол!');
                    end
                    else if CMDRES.IsMatch('COLA|BOTTLE') then
                        if Inventory.Has(itCola) then println('Ты бросаешь бутылку с колой прямо в зеркало, и оно разбивается.')
                        else begin
                            writeln('Так не пойдёт. Нужно попробовать что-нибудь ещё.');
                            Tutorial.ShowCheckHint;
                            continue
                        end
                    else writeln('Ты вмазываешь по зеркалу со всей силы и разбиваешь его.');
                    writeln('С пола ты поднимаешь осколок стекла.');
                    Inventory.Obtain(itShard);
                end;
            {-}'GO', 'GO_LIFT', 'GOUP', 'GOUP_LIFT', 'GO_HATCH', 'GOUP_HATCH', 'GO_HATCH_LIFT', 'GOUP_HATCH_LIFT',
            'GO_LIFT_HATCH', 'GOUP_LIFT_HATCH', 'CHECK_HATCH', 'GET_HATCH':
                if opened_hatch then
                begin
                    writeln('Ты с трудом взбираешься через люк наверх.');
                    writeln('Повезло - прямо перед тобой находится дверь на этаж!');
                    writeln('Но придётся потрудиться, чтобы её открыть...');
                    Anim.Next3;
                    ButtonMashMinigames.DoorBreaking;
                    break;
                end
                else begin
                    writeln('Ты находишь на потолке аварийный люк и пытаешься его открыть.');
                    writeln('Это не так просто - он чем-то закреплён.');
                    writeln('Если б только эти крепления можно было чем-то подрезать...');
                end;
            {-}'BREAK_HATCH':
                if opened_hatch then writeln('Ты уже открыл люк - пора залезть наверх.') else
                begin
                    writeln('Ты ударяешь по люку на потолке, но крепления не поддаются.');
                    writeln('Если б только их можно было чем-то подрезать...');
                end;
            {-}'OPEN_HATCH', 'CUT_HATCH', 'OPEN_ATTACH', 'BREAK_ATTACH', 'CUT_ATTACH', 'CHECK_ATTACH',
            'OPEN_ATTACH_HATCH', 'BREAK_ATTACH_HATCH', 'CUT_ATTACH_HATCH', 'CHECK_ATTACH_HATCH',
            'OPEN_HATCH_ATTACH', 'BREAK_HATCH_ATTACH', 'CUT_HATCH_ATTACH', 'CHECK_HATCH_ATTACH':
                if opened_hatch then writeln('Ты уже открыл люк.')
                else if Inventory.Has(itShard) then begin
                    writeln('Ты подрезаешь крепления осколком стекла.');
                    writeln('Ха! Это было как-то... даже слишком просто.');
                    opened_hatch := True;
                    writeln('Теперь можно взобраться сквозь люк на верх лифта.');
                end
                else begin
                    writeln('Ты находишь на потолке аварийный люк и пытаешься его открыть.');
                    writeln('Это не так просто - он чем-то закреплён.');
                    writeln('Если б только эти крепления можно было чем-то подрезать...');
                end
        else // case else
            begin
                writeln('Так не пойдёт. Нужно попробовать что-нибудь ещё.');
                if not Tutorial.ElevatorH.Shown then
                begin
                    Tutorial.Comment('в случае затупа можно использовать команду "осмотреться"');
                    Tutorial.ElevatorH.Show;
                end;
            end;
        end; // case end
    end; // while end
end;

function PART2: boolean;
begin
    Result := False;
    var second_floor: boolean;
    TxtClr(Color.White);
    writeln('Чтобы выгулять Юпитера, нужно сначала попасть на улицу.');
    writeln('Перед тобой лестница, лифт и окно, в котором виднеется вечно серое Чертаново.');
    while True do
    begin//while begin
        MENURES := Menu.FastSelect('спуститься по лестнице', 'вызвать лифт', 'прыгнуть в окно');
        case MENURES of // case begin
            {-} 'спуститься по лестнице':
                begin
                    writeln('Ты спускаешься вниз по лестничной клетке и выходишь из подъезда.');
                    break;
                end;
            {-} 'вызвать лифт':
                if second_floor then
                begin
                    writeln('Ты пытаешься вызвать другой лифт.');
                    writeln('Видимо, он тоже не работает.');
                end
                else begin
                    writeln('Ты вызываешь лифт и входишь в него.');
                    writeln('Здесь есть зеркало. О, да, сегодня ты выглядишь потрясно!');
                    writeln('Стены разрисованы, подозрительная жижа в углу, люк на потолке... Люк в лифте? Как странно.');
                    writeln('Лифт начинает спускаться на первый этаж, как вдруг...');
                    writeln('Вырубается свет, и с громким шумом и скрипом лифт останавливается!');
                    writeln('Юпитер недовольно гавкает. А лифт дальше ехать не собирается...');
                    EscapeRoom(Elevator);
                    achEscapeMaster.Achieve;
                    TxtClr(Color.White);
                    writeln('Ты с Юпитером выбираешься из лифта в коридор второго этажа.');
                    writeln('Снова окно, лестница и другой лифт. Что ты сделаешь?');
                    second_floor := True;
                end;
            {-} 'прыгнуть в окно':
                begin
                    writeln('Через окно спуститься будет быстрее всего!');
                    writeln('Ты ломаешь стекло и выпрыгиваешь наружу.');
                    if second_floor then
                    begin
                        writeln('К счастью, прямо под окном есть прочный бетонный козырёк над входом в подъезд.');
                        writeln('Остаётся только спрыгнуть с навеса на землю, что ты и делаешь.');
                        writeln('А от жёсткого приземления тебя спасает инстинктивный перекат.');
                        achParkour.Achieve;
                        Anim.Next3;
                        break;
                    end
                    else begin
                        writeln('Стоп... почему ты летишь с высоты седьмого этажа прямо на асфальт?');
                        writeln('Кажись, это была не очень хорошая идея...');
                        exit; // gameover
                    end;
                end;
        end;//case end
    end;//while end
    writeln('По пути ты встречаешь каких-то гопников, курящих у трансформаторной будки.');
    if Route.TextedRoma then writeln('Ты не сразу узнаёшь в них друзей Ромы с района.')
    else writeln('Они похожи на парней, с которыми часто тусуется один твой друг, Рома.');
    Dialogue.Say(anon, 'О, Шобунен, ты, что ли?');
    Dialogue.Say(Саня, 'Э... Привет, чё как?');
    Dialogue.Say(anon, 'Норм. Чё, идёшь на парковку?');
    if Route.TextedRoma then
    begin
        Dialogue.Say(Саня, 'Ага. Вы тоже туда на тусу?');
        Dialogue.Say(anon,
           'Стоп, реально собрался? А нафиг ты с собакой? Хах...',
           'Лан, пофиг, погнали, пора уже.');
        Dialogue.Close;
        writeln('Парни уходят, и ты неловко увязываешься за ними.');
    end
    else begin
        Dialogue.Say(Саня, 'Парковку?');
        Dialogue.Say(anon, 'Понятно...');
        Dialogue.Close;
        writeln('Парни шустро пожимают тебе руки и продолжают говорить о своём.');
        writeln('Ты пожимаешь плечами и идёшь дальше.');
    end;
    Route.SetRoute(second_floor ? Solo : Rita);
    // todo другой способ переключения рутов Соло и Риты?
    Result := True;
end;
    {$ENDREGION}

    {$REGION 3. ВЫХОД НА УЛИЦУ}
procedure PART3;
begin
    case Route.GetRoute of
        Solo, Rita:
            begin
                
            end;
        Trip:
            begin
                
            end;
        Roma:
            begin
                
            end;
    else raise new Exception('НЕ ЗАДАН РУТ'); // case else
    end;//case route end
end;
    {$ENDREGION}

    {$REGION 4. БИТВА С КОСТЫЛЕМ}
function PART4: boolean;
begin
    Result := False;
    case Route.GetRoute of
       // <...>
    end;
    // <...>
    
    {
    Этого чувака у вас на районе называют "Костыль", и не просто так.
    Все обычно обходят его стороной, вот только тебе с ним приходиться пересекаться часто.
    Костыль поистине неадекватный: он любит вымещать агрессию на случайных людях.
    Правда, в последнее время он почему-то делает это только с тобой...
    
    "АР-Р-Р-Р-Р-Р! ХЕНЭК! УПЫРЬ! АР-Р-Р!..", - кричит он.
    Как обычно, ты не понимаешь, что это значит, и пытаешься улизнуть.
    Но Костыль от тебя не отстаёт. Более того, он начинает размахивать кулаками!
    Ты пытаешься его успокоить, но всё тщетно.
    Придётся драться!..
    }
    
    Result := True;
end;
    {$ENDREGION}

{$ENDREGION}

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

{$REGION сцены}
var
    
    sFork := new PlayableScene(PART4, 'драка с костылём');
    
    sStart := (new PlayableScene(PART1, 'комната')).Linkup(
    new PlayableScene(PART2, 'подъезд'),
    new Cutscene(PART3, 'выход на улицу'),
    sFork);

{$ENDREGION}

{$REGION main}
function GAMELOOP: boolean;
var
    current_scene: Scene;
begin
    Result := True;
    Inventory.Reset;
    Route.SetRoute(Solo);
    current_scene := sStart;
    repeat
        if (current_scene is PlayableScene) then
        // части с возможностью геймовера:
        begin
            _Log.Log('=== часть: ' + current_scene.ToString);
            Inventory.Save;
            var passed: boolean;
            repeat
                Inventory.Load;
                passed := (current_scene as PlayableScene).Passed;
                if passed then break else
                begin
                    achGameOver.Achieve;
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
                    end
                    else begin
                        write('Начать заново? (Y/N)');
                        if YN then
                        begin
                            Result := False;
                            _Log.Log('=== РЕСТАРТ');
                            TITLESCREEN;
                        end;
                        exit;
                    end;
                end;
            until False; // repeat end
            writeln;
            Anim.Next3;
            TxtClr(Color.Green);
            writeln('Контрольная точка.');
            Anim.Next1;
            writelnx2;
            Console.Beep;
            _Log.Log('=== чекпоинт: ' + current_scene.ToString);
        end
        // части просто проходимые без геймоверов:
        else (current_scene as Cutscene).Run;
        current_scene := current_scene.next;
        //        if (current_scene = sFork) then
        //            case Route.GetRoute of
        //                {-} route_enum.Solo: current_scene := sSoloStart;
        //                {-} route_enum.Rita: current_scene := sRitaStart;
        //                {-} route_enum.Trip: current_scene := sTripStart;
        //                {-} route_enum.Solo: current_scene := sRomaStart;
        //            end; // case end
        // todo раскомментить когда будут руты
    until (current_scene = nil);
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
        Result := False;
        
        ClrScr;
        TxtClr(Color.Green);
        WriteEqualsLine;
        writeln('П Е Р Е З А П У С К . . .');
        WriteEqualsLine;
        writeln;
        sleep(500);
        // todo убрать и заменить на titlescreen
        
    end;
end;

procedure MAIN;
begin
    sleep(1000);
    if not STARTUP('СИМУЛЯТОР ШОБУНЕНА', VERSION) then exit;
    {$IFDEF DOOBUG}
    writeln('DEBUG MODE');
    Console.Title += ' [DEBUG MODE]';
    WriteEqualsLine;
    Chat.Skip := True;
    {$ELSE}
    TITLESCREEN;
    {$ENDIF}
    
    {$IFDEF DOOBUG}
    _Log.Init(VERSION, True);
    {$ELSE}
    _Log.Init(VERSION, False);
    {$ENDIF}
    
    {$IFNDEF DOOBUG}
    WHATSNEW;
    {$ENDIF}
    
    var ended_game: boolean;
    repeat
        ended_game := GAMELOOP;
    until ended_game;
end;
{$ENDREGION}

begin
    try
        MAIN();
    except
        on _ex_: Exception do Puke(_ex_);
    end;
end.
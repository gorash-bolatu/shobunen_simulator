{$REFERENCE System.Speech.dll}
{$RESOURCE parse_tts.json}

// TODO в релизе убрать все raise (там где про движок говорилки поменять все raise на Dispose)

unit TextToSpeech;

interface

procedure Dispose;
procedure ArchitectFinal;
procedure Architect(params phrases: array of string);
procedure Init;

implementation

uses Procs, Cursor, Anim, MyTimers, Parser;
uses _Log;

type
    InstalledVoice = System.Speech.Synthesis.InstalledVoice;

var
    synth: System.Speech.Synthesis.SpeechSynthesizer;// говорилка

function IsSpeaking: boolean := (synth.State = System.Speech.Synthesis.SynthesizerState.Speaking);

function IsRus(Self: InstalledVoice): boolean; extensionmethod :=
Self.VoiceInfo.Culture.Name.IsMatch('RU', RegexOptions.IgnoreCase);

function IsMale(Self: InstalledVoice): boolean; extensionmethod :=
Self.VoiceInfo.Gender = System.Speech.Synthesis.VoiceGender.Male;

procedure Fail(const ard: string; const brd: string; setup: boolean);
// todo когда не будет логов, можно убрать и везде заменить на Dispose;
begin
    // ClrScr;
    var yixia: string := (Format('!! {0}: {1}; {2}', (setup ? 'настройка говорилки' : 'говорилка'), ard, brd));
    _Log.Log(yixia);
    PABCSystem.Assert(False, yixia);
    yixia := nil;
    Dispose;
end;

procedure Dispose;
begin
    if (synth <> nil) then
    begin
        try
            synth.SpeakAsyncCancelAll;
        except
            {ignore}
        end;
        synth.Dispose;
        synth := nil;
    end;
    DO_TTS := False;
end;

procedure ArchitectFinal;
begin
    if not DO_TTS then exit;
    synth.Rate := 1;
    synth.SpeakAsync('Добро пожаловать, в реальный мир!');
    Anim.Text('Добро пожаловать в реальный мир.', 85);
    sleep(600);
    TxtClr(Color.DarkCyan);
    write(' ');
    Anim.Next1;
end;

procedure Architect(params phrases: array of string);
begin
    TxtClr(Color.White);
    foreach ph: string in phrases do
    begin
        if DO_TTS then
            try
                synth.SpeakAsync(ParseTts(ph));
                // ждать 800 мс пока говорилка не подгрузится:
                System.Threading.SpinWait.SpinUntil(() -> IsSpeaking, 800);
                // если говорилка за это время не подгрузилась:
                if not IsSpeaking then
                    raise new System.TimeoutException('ГОЛОСОВОЙ ДВИЖОК НЕ ПОДГРУЗИЛСЯ');// будет обработано xrd
            except
                on xrd: Exception do Fail(xrd.GetType.ToString, xrd.Message, False);
                // Dispose;
            end;//try except end
        foreach st: string in ph.Split('.') do
        begin
            Anim.Text((st + '.'), (38 + synth.Rate));
            sleep(300);
        end;
        ClrKeyBuffer;
        ReadKey;
        writeln;
        writeln(TAB);
        Cursor.GoTop(-1);
        if DO_TTS then
            if IsSpeaking and (synth.Rate < 9) then synth.Rate += 1;
    end;
end;

procedure Init;
begin
    DO_TTS := False;
    var clr_scr_tmr: MyTimers.Timer;
    try
        try
            clr_scr_tmr := new MyTimers.Timer(1, ClrScr); // стирает странные ошибки типа "Untested Windows version detected"
            clr_scr_tmr.Enable;
            synth := new System.Speech.Synthesis.SpeechSynthesizer;
            var voices := synth.GetInstalledVoices;
            var voices_ru := voices.&Where(q -> q.IsRus);
            if not voices_ru.Any then exit;
            var selected_voice: InstalledVoice := voices_ru.FirstOrDefault(q -> q.IsMale);
            if (selected_voice = nil) then selected_voice := voices_ru.First;
            if NilOrEmpty(selected_voice.VoiceInfo.Name) then exit;
            selected_voice.Enabled := True;
            synth.SelectVoice(selected_voice.VoiceInfo.Name);
            synth.SetOutputToDefaultAudioDevice;
            synth.Rate := 3;
            synth.Volume := 100;
            DO_TTS := True;
            _Log.Log($'=== tts: {synth.Voice.Name}, {synth.Voice.Culture}, {synth.Voice.Gender}, {synth.Voice.Age}, "{synth.Voice.Description}"');
        except
            on xrd: Exception do Fail(xrd.GetType.ToString, xrd.Message, True);
            // Dispose;
        end;
    finally
        if (clr_scr_tmr <> nil) then
        begin
            clr_scr_tmr.Destroy;
            clr_scr_tmr := nil;
        end;
        CollectGarbage;
    end;
end;

initialization

finalization
    Dispose;

end.
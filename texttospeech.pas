{$REFERENCE System.Speech.dll}

// TODO в релизе убрать все raise (там где про движок говорилки поменять все raise на Dispose)

unit TextToSpeech;

interface

procedure Dispose;
procedure ArchitectFinal;
procedure Architect(params phrases: array of string);
procedure Init;

implementation

uses Procs, Cursor, Anim, MyTimers;
uses _Log;

type
    InstalledVoice = System.Speech.Synthesis.InstalledVoice;

var
    synth: System.Speech.Synthesis.SpeechSynthesizer;// говорилка

function IsSpeaking: boolean := (synth.State = System.Speech.Synthesis.SynthesizerState.Speaking);

function IsRus(const tts_voice: System.Speech.Synthesis.VoiceInfo): boolean :=
tts_voice.Culture.Name.IsMatch('RU', RegexOptions.IgnoreCase);

function IsFemale(const tts_voice: System.Speech.Synthesis.VoiceInfo): boolean :=
(tts_voice.Gender = System.Speech.Synthesis.VoiceGender.Female);

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
        try
            synth.SpeakAsyncCancelAll;
            synth.Dispose;
            synth := nil;
        except
                    {ignore}
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
                synth.SpeakAsync(ph.Replace('PascalABC.NET', 'паскаль а бэ цэ дот нэт').Replace('узнаешь', 'у знаешь').Replace('...', ','));
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
var
    clr_scr_tmr: MyTimers.Timer;
    voices: System.Collections.ObjectModel.ReadOnlyCollection<InstalledVoice>;
begin
    DO_TTS := False;
    try
        try
            clr_scr_tmr := new MyTimers.Timer(1, ClrScr); // стирает странные ошибки типа "Untested Windows version detected"
            clr_scr_tmr.Enable;
            synth := new System.Speech.Synthesis.SpeechSynthesizer;
            synth.Rate := 3;
            synth.SetOutputToDefaultAudioDevice;
            synth.Volume := 100;
            voices := synth.GetInstalledVoices;
            if (voices.Count = 0) then
                raise new System.InvalidOperationException('НЕ НАЙДЕНО УСТАНОВЛЕННЫХ ГОЛОСОВ'); // обработается xrd
            // найти русскую говорилку:
            foreach v: InstalledVoice in voices do
                if IsRus(v.VoiceInfo) then
                begin
                    v.Enabled := True;
                    synth.SelectVoice(v.VoiceInfo.Name);
                    DO_TTS := True;
                    break
                end;
            // если голос женский, попробовать найти русскую говорилку с мужским голосом:
            // (можно было бы использовать SelectVoiceByHints но эта хрень не работает)
            if DO_TTS and IsFemale(synth.Voice) then
                foreach l: InstalledVoice in synth.GetInstalledVoices.Where(q -> IsRus(q.VoiceInfo)) do
                    if not IsFemale(l.VoiceInfo) then
                    begin
                        l.Enabled := True;
                        synth.SelectVoice(l.VoiceInfo.Name);
                        break
                    end;
            _Log.Log($'=== tts: {synth.Voice.Name}, {synth.Voice.Culture}, {synth.Voice.Gender}, {synth.Voice.Age}, "{synth.Voice.Description}"');
        except
            on xrd: Exception do Fail(xrd.GetType.ToString, xrd.Message, True);
            // Dispose;
        end;
    finally
        clr_scr_tmr.Destroy;
        clr_scr_tmr := nil;
        voices := nil;
        CollectGarbage;
    end;
end;

end.
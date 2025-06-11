{$DEFINE DOOBUG} // todo
{$REFERENCE LightJson.dll} // https://github.com/MarcosLopezC/LightJson
{$RESOURCE parse_cmd.json}
unit Parser;

interface

/// парсить строку согласно parse_cmd.json
function ParseCmd(const s: string): string;
/// парсить строку согласно parse_tts.json
function ParseTts(const s: string): string;



implementation

// примерная структура json:
//[
//    {
//        "to": "USE",
//        "from": ["взять", "забрать", "получить"]
//        
//    },
//    {
//        "to": "JUMP",
//        "from": "прыгнуть"
//    }
//    ...
//]

uses Procs, Resources;

var
    cmd_json, tts_json: LightJson.JsonArray;

function ParseCmd(const s: string): string;
begin
    var words: List<string> := new List<string>;
    foreach token: string in s.Split do
        foreach entry: LightJson.JsonValue in cmd_json do
        begin
            var from: LightJson.JsonValue := entry.Item['from'];
            if (from.IsJsonArray
            ? from.AsJsonArray.Contains(token)
            : from.AsString.Equals(token)) then
            begin
                words.Add(entry.Item['to'].AsString);
                break;
            end;
        end;
    Result := string.Join('_', words);
    words.Clear;
    words := nil;
end;

function ParseTts(const s: string): string;
begin
    Result := s;
    foreach entry: LightJson.JsonValue in tts_json do
    begin
        var t: string := entry.Item['to'].AsString;
        var f: LightJson.JsonValue := entry.Item['from'];
        if f.IsJsonArray then
            foreach w: LightJson.JsonValue in f.AsJsonArray do
                Result := Result.Replace(w.AsString, t)
        else Result := Result.Replace(f.AsString, t);
    end;
end;

function IsValidEntry(const entry: LightJson.JsonValue): boolean;
begin
    Result := False;
    if (entry.IsNull or not entry.IsJsonObject) then exit;
    var obj: LightJson.JsonObject := entry.AsJsonObject;
    if not (obj.ContainsKey('from') and obj.ContainsKey('to')) then exit;
    if not ((obj['from'].IsJsonArray or obj['from'].IsString) and obj['to'].IsString) then exit;
    Result := True;
end;

function FetchAndParse(const resource_name: string): LightJson.JsonArray;
begin
    Result := LightJson.JsonValue.Parse(TextFromResourceFile(resource_name)).AsJsonArray;
    {$IFDEF DOOBUG}
    print('[DEBUG]', 'Проверка', resource_name + '...');
    var watch := new Stopwatch;
    watch.Start;
    foreach i: LightJson.JsonValue in Result do
        if not IsValidEntry(i) then raise new LightJson.Serialization.JsonParseException;
    watch.Stop;
    println('ok', watch.Elapsed.TotalMilliseconds, 'ms');
    watch := nil;
{$ENDIF}
end;

initialization
    cmd_json := FetchAndParse('parse_cmd.json');
    tts_json := FetchAndParse('parse_tts.json');

finalization
    cmd_json.Clear;
    cmd_json := nil;
    tts_json.Clear;
    tts_json := nil;

end.
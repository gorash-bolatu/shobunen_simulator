{$DEFINE DOOBUG} // todo
{$REFERENCE LightJson.dll} // https://github.com/MarcosLopezC/LightJson
{$RESOURCE parse.json}
unit Parser;

interface

/// парсить строку согласно parse.json
function ParseCmd(const s: string): string;

implementation

// структура parse.json:
//[
//    {
//        "to": "USE",
//        "from": ["взять", "забрать", "получить"]
//        
//    },
//    {
//        "to": "JUMP",
//        "from": ["прыгнуть"]
//    }
//    ...
//]

uses Procs;

var
    json_arr: LightJson.JsonArray;

function ParseCmd(const s: string): string;
begin
    var words: List<string> := new List<string>;
    foreach token: string in s.Split do
        foreach entry: LightJson.JsonValue in json_arr do
            if (entry['from'].IsJsonArray
            ? entry['from'].AsJsonArray.Contains(token)
            : entry['from'].AsString.Equals(token)) then
            begin
                words.Add(entry['to'].AsString);
                break;
            end;
    Result := string.Join('_', words);
    words.Clear;
    words := nil;
end;

function ValidateEntry(const entry: LightJson.JsonValue): boolean;
begin
    Result := False;
    if (entry.IsNull or not entry.IsJsonObject) then exit;
    var obj: LightJson.JsonObject := entry.AsJsonObject;
    if not (obj.ContainsKey('from') and obj.ContainsKey('to')) then exit;
    if not ((obj['from'].IsJsonArray or obj['from'].IsString) and obj['to'].IsString) then exit;
    Result := True;
end;

initialization
    json_arr := LightJson.JsonValue.Parse(TextFromResourceFile('parse.json')).AsJsonArray;
    
    {$IFDEF DOOBUG}
    print('[DEBUG]', 'Проверка parse.json...');
    var watch := new Stopwatch;
    watch.Start;
    foreach i: LightJson.JsonValue in json_arr do
        if not ValidateEntry(i) then raise new LightJson.Serialization.JsonParseException;;
    watch.Stop;
    writeln('ok ', watch.ElapsedMilliseconds, 'ms');
    watch := nil;
    {$ENDIF}

finalization
    json_arr.Clear;
    json_arr := nil;

end.
{$DEFINE DOOBUG} // todo
{$REFERENCE LightJson.dll}
{$RESOURCE parse.json}
unit Parser;

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
            if entry['from'].AsJsonArray.Contains(token) then
            begin
                words.Add(entry['to'].AsString);
                break;
            end;
    Result := string.Join('_', words);
    words.Clear;
    words := nil;
end;

procedure ValidateEntry(const entry: LightJson.JsonValue);
begin
    if (entry.IsNull or not entry.IsJsonObject) then
        raise new LightJson.Serialization.JsonParseException;
    var obj: LightJson.JsonObject := entry.AsJsonObject;
    if not (obj.ContainsKey('from') and obj.ContainsKey('to')) then
        raise new LightJson.Serialization.JsonParseException;
    if not (obj['from'].IsJsonArray and obj['to'].IsString) then
        raise new LightJson.Serialization.JsonParseException;
end;

initialization
    json_arr := LightJson.JsonValue.Parse(TextFromResourceFile('parse.json')).AsJsonArray;
    
    {$IFDEF DOOBUG}
    print('[DEBUG]', 'Проверка parse.json...');
    var watch := new Stopwatch;
    watch.Start;
    foreach i: LightJson.JsonValue in json_arr do ValidateEntry(i);
    watch.Stop;
    writeln('ok ', watch.ElapsedMilliseconds, 'ms');
    watch := nil;
    {$ENDIF}

finalization
    json_arr.Clear;
    json_arr := nil;

end.
unit Achievements;

interface

type
    Achievement = class
    private
        fName, fDesc, fWalkthrough: string;
        fAchieved: boolean;
    public
        procedure Achieve;
        constructor Create(name, description: string; walkthrough: string := nil);
        destructor Destroy;
    end;

var
    HashSetOfAll: HashSet<Achievement> := new HashSet<Achievement>;

procedure DestroyAll;
procedure DisplayAll;
function DebugString: string;

implementation

uses Cursor, Procs;

function DebugString: string;// todo убрать когда не будет log'ов
begin
    foreach a: Achievement in HashSetOfAll do
        if a.fAchieved then Result += ('; ' + a.fName.Replace(' ', ''));
    if not NilOrEmpty(Result) then Result := 'ach-s: ' + Result[3:];
end;

procedure Achievement.Achieve := if not self.fAchieved then self.fAchieved := True;

constructor Achievement.Create(name, description: string; walkthrough: string);
begin
    self.fName := name;
    self.fDesc := description;
    self.fWalkthrough := walkthrough;
    self.fAchieved := False;
    HashSetOfAll.Add(self);
end;

destructor Achievement.Destroy;
begin
  self.fName := nil;
  self.fDesc := nil;
  self.fWalkthrough := nil;
  HashSetOfAll.Remove(self);
end;

procedure DestroyAll;
begin
    if (HashSetOfAll = nil) then exit;
    while HashSetOfAll.Count > 0 do HashSetOfAll.ElementAt(0).Destroy;
    HashSetOfAll.Clear;
    HashSetOfAll := nil;
end;

procedure DisplayAll;
begin
    if (HashSetOfAll.Count = 0) then exit;
    TxtClr(Color.Green);
    if HashSetOfAll.Any(q -> q.fAchieved) then
    begin
        println('ПОЛУЧЕНО АЧИВОК:', HashSetOfAll.Count(q -> q.fAchieved), '/', HashSetOfAll.Count);
        writeln;
        foreach ach: Achievement in HashSetOfAll.Where(q -> q.fAchieved) do
        begin
            TxtClr(Color.Cyan);
            writeln(TAB, '} ', ach.fName);
            TxtClr(Color.DarkCyan);
            writeln(TAB, '- ', ach.fDesc);
        end;
        writeln;
        TxtClr(Color.Green);
    end;
    if HashSetOfAll.Any(q -> not q.fAchieved) then
    begin
        writeln('Показать ещё не полученные ачивки? (Y/N)');
        writeln;
        if YN then
        begin
            foreach ach: Achievement in HashSetOfAll.Where(q -> not q.fAchieved) do
            begin
                if ach.fName.Contains('ОРА') then continue; // todo раскомментить когда будет рут трипа
                TxtClr(Color.Cyan);
                writeln(TAB, '} ', ach.fName);
                TxtClr(Color.DarkCyan);
                writeln(TAB, '- ', ach.fDesc);
                if not NilOrEmpty(ach.fWalkthrough) then
                begin
                    UpdScr;
                    TxtClr(Color.DarkGreen);
                    write(TAB);
                    var w: integer := MIN_WIDTH - Cursor.Left;
                    writeln(WordWrap(ach.fWalkthrough, w, NewLine + TAB));
                end;
            end;
            writeln;
            ReadKey;
        end;
    end
    else begin
        writeln('Ура! Ты получил все достижения в игре!');
        writeln;
        ReadKey;
    end;
end;

end.
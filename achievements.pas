unit Achievements;

interface

type
    Achievement = class
    private
        /// имя достижения
        fName: string;
        /// короткое описание достижения
        fDesc: string;
        /// способ получения достижения (прохождение)
        fWalkthrough: string;
        /// получено ли достижение
        fAchieved: boolean;
    public
        /// получить достижение
        procedure Achieve;
        constructor Create(name, description: string; walkthrough: string := nil);
        destructor Destroy;
    end;

/// отобразить все достижения в консоли
procedure DisplayAll;
function DebugString: string;

implementation

uses Cursor, Procs, Anim;

var
    ListOfAll: List<Achievement> := new List<Achievement>;

function DebugString: string;// todo убрать когда не будет log'ов
begin
    foreach a: Achievement in ListOfAll do
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
    ListOfAll.Add(self);
end;

destructor Achievement.Destroy;
begin
    self.fName := nil;
    self.fDesc := nil;
    self.fWalkthrough := nil;
end;

procedure DisplayAll;
begin
    if (ListOfAll.Count = 0) then exit;
    TxtClr(Color.Green);
    if ListOfAll.Any(q -> q.fAchieved) then
    begin
        println('ПОЛУЧЕНО АЧИВОК:', ListOfAll.Count(q -> q.fAchieved), '/', ListOfAll.Count);
        writeln;
        foreach ach: Achievement in ListOfAll.Where(q -> q.fAchieved) do
        begin
            TxtClr(Color.Cyan);
            writeln(TAB, '} ', ach.fName);
            TxtClr(Color.DarkCyan);
            writeln(TAB, '- ', ach.fDesc);
        end;
        writeln;
        TxtClr(Color.Green);
    end;
    if ListOfAll.Any(q -> not q.fAchieved) then
    begin
        writeln('Показать ещё не полученные ачивки? (Y/N)');
        writeln;
        if YN then
        begin
            var top: integer := Cursor.Top;
            foreach ach: Achievement in ListOfAll.Where(q -> not q.fAchieved) do
            begin
                if ach.fName.Contains('ОРА') then continue; // todo убрать когда будет рут трипа
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
                if (Cursor.Top - top > Console.WindowHeight div 2) then
                begin
                    TxtClr(Color.Yellow);
                    Anim.Next1;
                    top := Cursor.Top;
                end;
            end;
            writeln;
        end;
    end
    else begin
        writeln('Ура! Ты получил все достижения в игре!');
        writeln;
    end;
    Cursor.GoTop(-1);
    Anim.Next3;
end;

initialization

finalization
    if (ListOfAll = nil) then exit;
    foreach i: Achievement in ListOfAll do i.Destroy;
    ListOfAll.Clear;
    ListOfAll := nil;

end.
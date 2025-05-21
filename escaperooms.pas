unit EscapeRooms;

interface

type
    EscapeRoom = class
    private
        room: procedure;
    public
        procedure Play;
        constructor Create(proc: procedure);
    end;// class end

procedure Cleanup;



implementation

uses Procs, Anim;

var
  ListOfAll: List<EscapeRoom> := new List<EscapeRoom>;

constructor EscapeRoom.Create(proc: procedure);
begin
    self.room := proc;
    ListOfAll.Add(self);
end;

procedure EscapeRoom.Play;
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
    self.room();
    TxtClr(Color.Yellow);
    writeln('=== YOU FOUND IT ===');
    BeepWait(300, 200);
    Anim.Next3;
end;

procedure Cleanup;
begin
    if (ListOfAll = nil) then exit;
    ListOfAll.Clear;
    ListOfAll := nil;
end;

end.
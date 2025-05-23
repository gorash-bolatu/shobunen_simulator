unit Scenes;

interface

type

    Scene = abstract class
    private
        id: integer;
        constructor Create(scenename: string);
    protected
        destructor Destroy;
    public
        name: string;
        next: Scene;
        function Linkup(params scenes: array of Scene): Scene;
        function ToString: string; override := $'[{self.id}] {self.name}';
    end;// class end
    
    Cutscene = class(Scene)
    private
        proc: procedure;
    public
        constructor Create(proc: procedure; name: string);
        procedure Run := self.proc();
    end;// class end
    
    PlayableScene = class(Scene)
    private
        func: function: boolean;
    public
        constructor Create(func: function: boolean; name: string);
        function Passed: boolean := self.func();
    end;//class end

// type end

procedure Cleanup;

implementation

var
    ListOfAll: List<Scene> := new List<Scene>;

constructor Scene.Create(scenename: string);
begin
    self.id := (ListOfAll.Count = 0) ? 0 : (ListOfAll.Last.id + 1);
    self.name := scenename;
    self.next := nil;
    ListOfAll.Add(self);
end;

destructor Scene.Destroy();
begin
    name := nil;
    next := nil;
end;

function Scene.Linkup(params scenes: array of Scene): Scene;
begin
    if (scenes.Length = 0) then exit;
    self.next := scenes[0];
    for var i: integer := 1 to (scenes.Length - 1) do scenes[i - 1].next := scenes[i];
    Result := self;
end;

constructor Cutscene.Create(proc: procedure; name: string);
begin
    inherited Create(name);
    self.proc := proc;
end;

constructor PlayableScene.Create(func: function: boolean; name: string);
begin
    inherited Create(name);
    self.func := func;
end;

procedure Cleanup;
begin
    if (ListOfAll = nil) then exit;
    foreach i: Scene in ListOfAll do i.Destroy;
    ListOfAll.Clear;
    ListOfAll := nil;
end;

initialization

finalization
    Cleanup;

end.
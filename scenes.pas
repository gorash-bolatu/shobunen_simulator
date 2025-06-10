{$DEFINE DOOBUG} // todo
unit Scenes;

interface

type
    
    ByteOrNull = System.Nullable<byte>;
    
    Scene = abstract class
    protected
        body: procedure;
        next: Scene;
        constructor Create(scenename: string);
        destructor Destroy;
    public
        name: string; // todo убрать когда будут логи?
        procedure Run;
        function Passed: boolean; abstract;
        function Linkup(params scenes: array of Scene): Scene;
        function Scenes: sequence of Scene;
    end;// class end
    
    Cutscene = class(Scene)
    public
        constructor Create(proc: procedure; name: string);
        function Passed: boolean; override;
    end;// class end
    
    PlayableScene = class(Scene)
    private
        boolfunc: function: boolean;
    public
        constructor Create(func: function: boolean; name: string);
        destructor Destroy;
        function Passed: boolean; override;
    end;//class end
    
    ForkScene = class(Scene)
    private
        selectfunc: function: ByteOrNull;
        options: array of Scene;
    public
        constructor Create(func: function: ByteOrNull; name: string; params scenes: array of Scene);
        destructor Destroy;
        function Passed: boolean; override;
    end;
// type end



implementation

var
    ListOfAll: List<Scene> := new List<Scene>;

constructor Scene.Create(scenename: string);
begin
    self.name := scenename;
    self.next := nil;
    ListOfAll.Add(self);
end;

destructor Scene.Destroy();
begin
    self.name := nil;
    self.next := nil;
    self.body := nil;
end;

procedure Scene.Run() := self.body();

function Scene.Linkup(params scenes: array of Scene): Scene;
begin
    Result := self;
    if (scenes.Length = 0) then exit;
    self.next := scenes[0];
    if (scenes.Length = 1) then exit;
    {$IFDEF DOOBUG}
    foreach s: Scene in scenes.SkipLast do
        if (s is ForkScene) then
            raise new Exception('РАЗВИЛКА НЕ В КОНЦЕ СПИСКА СЦЕН: ' + s.name);
    {$ENDIF}
    for var i: integer := 0 to (scenes.Length - 2) do
        scenes[i].next := scenes[i + 1];
end;

function Scene.Scenes: sequence of Scene;
begin
    var s := self;
    repeat
        yield s;
        s := s.next;
    until s = nil;
end;

constructor Cutscene.Create(proc: procedure; name: string);
begin
    inherited Create(name);
    self.body := proc;
end;

function Cutscene.Passed: boolean;
begin
    self.body();
    Result := True;
end;

constructor PlayableScene.Create(func: function: boolean; name: string);
begin
    inherited Create(name);
    self.body := () -> func();
    self.boolfunc := func;
end;

destructor PlayableScene.Destroy;
begin
    inherited Destroy;
    self.boolfunc := nil;
end;

function PlayableScene.Passed: boolean := self.boolfunc();

constructor ForkScene.Create(func: function: ByteOrNull; name: string; params scenes: array of Scene);
begin
    inherited Create(name);
    self.body := () -> func();
    self.selectfunc := func;
    self.options := scenes;
end;

destructor ForkScene.Destroy;
begin
    inherited Destroy;
    self.selectfunc := nil;
    foreach s: Scene in self.options do s.Destroy;
    self.options := nil;
end;

function ForkScene.Passed: boolean;
begin
    var res: ByteOrNull := selectfunc();
    if res.HasValue then
    begin
        self.next := self.options[res.Value];
        Result := True;
    end
    else Result := False;
end;



initialization

finalization
    if (ListOfAll = nil) then exit;
    foreach i: Scene in ListOfAll do i.Destroy;
    ListOfAll.Clear;
    ListOfAll := nil;

end.
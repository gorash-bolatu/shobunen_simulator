unit Scenes;

interface

type
    Scene = abstract class
    private
        fUnlocked: boolean := False;
    public
        name: string;
        next: Scene;
        constructor Create(name: string; next: Scene);
        destructor Destroy;
        property Unlocked: boolean read fUnlocked;
        procedure Unlock() := fUnlocked := True;
        function ToString: string; override;
    end;// class end
    
    Cutscene = class(Scene)
    private
        proc: procedure;
    public
        constructor Create(proc: procedure; name: string; next: Scene);
        procedure Run := self.proc();
    end;// class end
    
    PlayableScene = class(Scene)
    private
        func: function: boolean;
    public
        constructor Create(func: function: boolean; name: string; next: Scene);
        function Passed: boolean := self.func();
    end;//class end
    
    FinalScene = class(Cutscene)
        public constructor Create(proc: procedure; name: string);
    end;//class end

// type end

var
    HashSetOfAll: HashSet<Scene> := new HashSet<Scene>;

implementation

constructor Scene.Create(name: string; next: Scene);
begin
    self.name := name;
    self.next := next;
    HashSetOfAll.Add(self);
end;

destructor Scene.Destroy();
begin
    name := nil;
    next := nil;
    HashSetOfAll.Remove(self);
end;

function Scene.ToString: string;
begin
   Result := self.GetType.ToString.Split('.').Last + ': ' + self.name;  
end;

constructor Cutscene.Create(proc: procedure; name: string; next: Scene);
begin
    inherited Create(name, next);
    self.proc := proc;
end;

constructor PlayableScene.Create(func: function: boolean; name: string; next: Scene);
begin
    inherited Create(name, next);
    self.func := func;
end;

constructor FinalScene.Create(proc: procedure; name: string);
begin
    inherited Create(name, nil);
    self.proc := proc;
end;

procedure DestroyAll;
begin
    if (HashSetOfAll = nil) then exit;
    while HashSetOfAll.Count > 0 do HashSetOfAll.ElementAt(0).Destroy;
    HashSetOfAll.Clear;
    HashSetOfAll := nil;
end;

end.
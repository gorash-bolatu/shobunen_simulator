unit Scenes;


type
    
    /// НЕ НАСЛЕДОВАТЬ
    Scene = abstract class
    private
        static ListOfAll: List<Scene>;
        next: Scene;
        function GetNext: Scene; virtual := next;
        procedure SetNext(const value: Scene) := self.Next := value;
    protected
        constructor Create();
        begin
            ListOfAll.Add(self);
        end;
    
    public
        destructor Destroy;
        begin
            self.SetNext(nil);
        end;
    end;
    
    /// класс сцены проходимой без геймоверов 
    Cutscene = sealed class(Scene)
    private
        body: procedure;
    public
        constructor Create(proc: procedure);
        begin
            inherited Create;
            body := proc;
        end;
        
        destructor Destroy;
        begin
            inherited Destroy;
            body := nil;
        end;
        
        procedure Run := body();
    end;// class end
    
    /// класс сцены, в которой можно получить геймовер
    PlayableScene = sealed class(Scene)
    private
        boolfunc: function: boolean;
    public
        constructor Create(func: function: boolean);
        begin
            inherited Create;
            boolfunc := func;
        end;
        
        destructor Destroy;
        begin
            inherited Destroy;
            boolfunc := nil;
        end;
        
        function Passed: boolean := boolfunc();
    end;//class end
    
    /// класс развилки с выбором сцены
    Fork = sealed class(Scene)
    private
        selectfunc: function: Scene;
        function GetNext: Scene; override := selectfunc();
    public
        constructor Create(selector: function: Scene);
        begin
            inherited Create;
            selectfunc := selector;
        end;
        
        destructor Destroy;
        begin
            inherited Destroy;
            selectfunc := nil;
        end;
    end;

// TYPE END

function Link(params scenearr: array of Scene): Scene;
begin
    for var i: integer := 0 to (scenearr.Length - 2) do
        scenearr[i].SetNext(scenearr[i + 1]);
    Result := scenearr[0];
end;

function Chain(self: Scene): sequence of Scene; extensionmethod;
begin
    var n: Scene := self;
    repeat
        while (n is Fork) do n := n.GetNext;
        yield n;
        n := n.GetNext;
    until n = nil;
end;

initialization
    Scene.ListOfAll := new List<Scene>;

finalization
    if (Scene.ListOfAll = nil) then exit;
    foreach i: Scene in Scene.ListOfAll do i.Destroy;
    Scene.ListOfAll.Clear;
    Scene.ListOfAll := nil;

end.
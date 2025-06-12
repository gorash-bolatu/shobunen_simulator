{$DEFINE DOOBUG} // todo
unit Scenes;

interface

type
    
    /// НЕ НАСЛЕДОВАТЬ
    Nextable = abstract class
    private
        fNext: Nextable := nil;
        function GetNext: Nextable; virtual;
    protected
        constructor Create(n: string);
        constructor Create;
        destructor Destroy;
        function Chain: sequence of Nextable;
        property Next: Nextable read GetNext write fNext;
    public
        name: string; // todo убрать когда не будет логов
    end;
    
    /// НЕ НАСЛЕДОВАТЬ
    Scene = abstract class(Nextable)
    protected
        constructor Create(const scenename: string);
    public
        function Scenes: sequence of Scene;
    end;// class end
    
    /// класс сцены проходимой без геймоверов 
    /// требует определения процедуры Body с логикой собственно сцены
    Cutscene = abstract class(Scene)
    public
        constructor Create(const name: string);
        /// процедура с логикой сцены
        procedure Body; abstract;
    end;// class end
    
    /// класс сцены, в которой можно получить геймовер
    /// требует определения функции Passed (возвращает boolean) с логикой сцены
    /// True если сцена пройдена, False если во время сцены получен геймовер
    PlayableScene = abstract class(Scene)
    public
        constructor Create(const name: string);
        /// функция с логикой сцены
        /// возвращает:
        ///     - True (если сцена пройдена)
        ///     - False (если во время сцены получен геймовер)
        function Passed: boolean; abstract;
    end;//class end
    
    /// класс развилки с выбором сцены
    /// требует определения функции GetNext, возвращающей Nextable
    /// (Nextable'ом может быть и Cutscene, и PlayableScene, и другой Fork)
    /// в GetNext логика выбора следующей сцены (какой Nextable идёт следующим)
    Fork = abstract class(Nextable)
    public
        constructor Create(const name: string);
        procedure SelectAsNext(const n: Nextable);
        /// функция с логикой выбора следующей сцены/развилки
        function GetNext: Nextable; abstract; override;
    end;
// type end

function Link(params scenes_and_forks: array of Nextable): Nextable;



implementation

var
    ListOfAll: List<Nextable> := new List<Nextable>;

constructor Nextable.Create() := ListOfAll.Add(self);

constructor Nextable.Create(const n: string);// todo убрать когда не будет логов
begin
    self.name := n;
    ListOfAll.Add(self);
end;

destructor Nextable.Destroy;
begin
    self.name := nil;
    self.Next := nil;
end;

function Nextable.GetNext: Nextable := self.fNext;

function Nextable.Chain: sequence of Nextable;
begin
    var n: Nextable := self;
    repeat
        yield n;
        n := n.Next;
    until n = nil;
end;

constructor Scene.Create(const scenename: string) := inherited Create(scenename); // todo убрать когда не будет логов

function Scene.Scenes: sequence of Scene;
begin
    foreach n: Nextable in self.Chain do
        if n is Scene then
            yield n as Scene;
end;

constructor Cutscene.Create(const name: string);// todo убрать когда не будет логов
begin
    inherited Create(name);
end;

constructor PlayableScene.Create(const name: string);// todo убрать когда не будет логов
begin
    inherited Create(name);
end;

constructor Fork.Create(const name: string);// todo тоже убрать
begin
    inherited Create(name);
end;

procedure Fork.SelectAsNext(const n: Nextable) := self.Next := n;

function Link(params scenes_and_forks: array of Nextable): Nextable;
begin
    if (scenes_and_forks.Length = 0) then Result := nil
    else begin
        for var i: integer := 0 to (scenes_and_forks.Length - 2) do
            scenes_and_forks[i].Next := scenes_and_forks[i + 1];
        Result := scenes_and_forks[0];
    end;
end;



initialization

finalization
    if (ListOfAll = nil) then exit;
    foreach i: Nextable in ListOfAll do i.Destroy;
    ListOfAll.Clear;
    ListOfAll := nil;

end.
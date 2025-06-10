unit Plot_Scenes;

interface

uses Scenes, Plot_Prologue;

function SCENES: sequence of Scene;

implementation

var
    
    sFork := new PlayableScene(PART4, 'драка с костылём');
    // todo переделать в ForkScene
    
    sStart := (new PlayableScene(PART1, 'комната')).Linkup(
    new PlayableScene(PART2, 'подъезд'),
    new Cutscene(PART3, 'выход на улицу'),
    sFork);

function SCENES: sequence of Scene := sStart.Scenes;

end.
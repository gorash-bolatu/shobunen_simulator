unit Actors;

type

    ActorColor = System.ConsoleColor;

    Actor = record
        name: string;
        color: ActorColor;
    end;

const
    Anon: Actor = (name: '???'; color: ActorColor.Green);
    Sanya: Actor = (name: 'Саня'; color: ActorColor.Magenta);
    Kostyl: Actor = (name: 'Костыль'; color: ActorColor.Red);
    Roma: Actor = (name: 'Рома'; color: ActorColor.Green);
    Trip: Actor = (name: 'Трип'; color: ActorColor.Green);
    Rita: Actor = (name: 'Рита'; color: ActorColor.Green);
    // TODO добавить ещё
    MatrixRoma: Actor = (name: 'МеРомаВинген'; color: ActorColor.Green);
    MatrixTrip: Actor = (name: 'Мотвеус'; color: ActorColor.Green);
    MatrixRita: Actor = (name: 'Тританити'; color: ActorColor.Green);
    MatrixKostyl: Actor = (name: 'Агент Сергеев'; color: ActorColor.Red);

end.
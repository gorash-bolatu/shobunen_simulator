unit Items;

type
    Item = record
        name: string;
    end;// record end

const
    Cola: Item = (name: 'Бутылка колы');
    Charger: Item = (name: 'Зарядка от ноутбука');
    Hdd: Item = (name: 'Жёсткий диск');
    Shard: Item = (name: 'Осколок зеркала');
    Dog: Item = (name: 'Юпитер');

end.
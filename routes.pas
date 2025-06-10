unit Routes;

type
    
    route_enum = (Solo, Rita, Trip, Roma);
    
    Route = static class
    private
        static current_route: route_enum;
    public
        static TextedVasya, TextedRita, TextedRoma: boolean;
        static procedure SetRoute(newroute: route_enum) := current_route := newroute;
        static function GetRoute(): route_enum := current_route;
    end;

end.
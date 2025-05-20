/// оболочка для System.Timers.Timer
unit MyTimers;

type
    Timer = sealed class
    private
        _tmr: System.Timers.Timer;
    public
        procedure Disable := if (_tmr <> nil) and _tmr.Enabled then _tmr.Stop;
        procedure Enable := if (_tmr <> nil) then _tmr.Start;
        
        constructor Create(period: real; proc: procedure);
        begin
            _tmr := new System.Timers.Timer(period);
            _tmr.Elapsed += (o: object; e: System.Timers.ElapsedEventArgs) -> proc();
            _tmr.AutoReset := True;
        end;
        
        destructor Destroy;
        begin
            if (_tmr <> nil) then
            begin
                _tmr.Stop;
                _tmr.Dispose;
                _tmr := nil;
            end;
        end;
    end;
// type end

end.
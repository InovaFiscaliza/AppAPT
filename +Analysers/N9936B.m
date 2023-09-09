classdef N9936B < Analysers.KEYSIGHT

    methods
        function obj = N9936B(~, args)
            obj@Analysers.KEYSIGHT('N9936B', args)
        end

        function startUp(obj)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            writeline(anl, ['' ...
                '*CLS;' ...
                ':INSTrument \"SA\";' ...
                ':FORMat:DATA REAL,32;' ...
                ':AVERage:TYPE VOLT;' ...
                ':DISP:WIND:TRAC1:Y:AUTO;' ...
                ':SYSTem:GPS:STATe INT'])
            res = writeread(anl, "SYSTEM:ERROR?");
            if ~contains(res, "No error", "IgnoreCase", true)
                warning("KEYSIGHT N9936B: StartUp: " + res)
            else
                disp("KEYSIGHT N9936B: Start Ok.")
            end
            clear anl;
        end
    end
end
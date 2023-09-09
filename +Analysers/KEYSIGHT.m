classdef KEYSIGHT < Analysers.Analyser
    methods
        function obj = KEYSIGHT(~,args)
            obj.prop = args;
        end

        function startUp(obj)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            writeline(anl, ['' ...
                '*CLS;' ...
                ':INSTrument SA;' ...
                ':FORMat:DATA REAL;' ...
                ':AVERage:TYPE VOLT;' ...
                ':SYSTem:CONFigure:GPS 1'])
            res = writeread(anl, "SYSTEM:ERROR?");
            if ~contains(res, "No error", "IgnoreCase", true)
                warning("KEYSIGHT: StartUp: " + res)
            else
                disp("KEYSIGHT: Start Ok.")
            end
            clear anl;
        end
    end
end
classdef ANRITSU < Analysers.Analyser
    methods
        function obj = ANRITSU(~,args)
            obj.prop = args;
        end

        function scpiReset(obj)
            obj.sendCMD("SYSTem:PRESET");
        end

        function startUp(obj)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            writeline(anl, ['' ...
                '*CLS;' ...
                ':INSTrument \"SPA\";' ...
                ':FORMat:DATA REAL,32;' ...
                ':BANDwidth:VIDeo:TYPE LIN;' ...
                ':SWEep:MODE FAST;:GPS ON'])
            res = writeread(anl, "SYSTEM:ERROR?");
            if ~contains(res, "No error", "IgnoreCase", true)
                warning("ANRITSU: StartUp: " + res)
            else
                disp("ANRITSU: Start Ok.")
            end
            clear anl;
        end
    end
end


classdef R_S < Analysers.Analyser
    methods
        function obj = R_S(~,args)
            obj.prop = args;
        end

        function startUp(obj)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );

            % Para os modelos FSL, FSVR e FSW
            writeline(anl, ['' ...
                '*CLS;' ...
                ':INSTrument SAN;' ...
                ':FORMat:DATA REAL,32;' ...
                ':AVERage:TYPE LINear'])
            res = writeread(anl, "SYSTEM:ERROR?");
            if ~contains(res, "No error", "IgnoreCase", true)
                warning("ANRITSU: StartUp: " + res)
            else
                disp("ANRITSU: Start Ok.")
            end
            clear anl;
        end

        % Se passado o terceiro argumento faz start/stop, senão CF.
        function setFreq(obj, freq, stop)
            if nargin < 3
                obj.sendCMD( sprintf("FREQuency:CENTer %f", freq) );
            else
                obj.sendCMD( sprintf("FREQuency:START %f; :SPECtrum:FREQuency:STOP %f", freq, stop) );
            end
        end
    end
end


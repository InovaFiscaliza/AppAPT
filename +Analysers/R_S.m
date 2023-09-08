classdef R_S < Analyser
    methods
        function obj = R_S(~,args)
            obj.prop = args;
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


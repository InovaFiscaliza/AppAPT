classdef ANRITSU < Analyser
    methods
        function obj = ANRITSU(~,args)
            obj.prop = args;
        end

        function scpiReset(obj)
            obj.sendCMD("SYSTem:PRESET");
        end
    end
end


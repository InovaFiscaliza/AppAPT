classdef TEKTRONIX < Analysers.Analyser
    methods
        function obj = TEKTRONIX(~,args)
            if nargin < 2
                error('Esta classe não deve ser executada diretamente.')
            end
            obj.prop = args;
        end

        function startUp(obj)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            writeline(anl, ['' ...
                'DISPlay:GENeral:MEASview:SELect SPECtrum;' ...
                ':FORMat:DATA BIN;' ...
                ':SYSTem:GPS INT'])
            res = writeread(anl, "SYSTEM:ERROR?");
            if ~contains(res, "No error", "IgnoreCase", true)
                warning("TEKTRONIX: StartUp: " + res)
            else
                disp("TEKTRONIX: Start Ok.")
            end
            clear anl;
        end    

        function res = getSpan(obj)
            res = obj.getCMD('SPECtrum:FREQuency:SPAN?');
        end

        function res = getRes(obj)
            res = obj.getCMD(':SPECtrum:BANDwidth:RESolution?');
        end

        function out = getParms(obj)
            keys = ["Function", "AVGCount", "Detection", "Power", "FStart", "FStop", "ResAuto", "Res", "InputGain", "Att"];
            res = obj.getCMD("" + ...
                "TRACe1:SPECtrum:FUNCtion?;" + ...
                ":TRACe1:SPECtrum:AVERage:COUNt?;" + ...
                ":TRACe1:SPECtrum:DETection?;" + ...
                ":UNIT:POWer?;" + ...
                ":SPECtrum:FREQuency:STARt?;" + ...
                ":SPECtrum:FREQuency:STOP?;" + ...
                ":SPECtrum:BANDwidth:RESolution:AUTO?;" + ...
                ":SPECtrum:BANDwidth:RESolution?;" + ...
                ":INPut:GAIN:STATe?;" + ...
                ":INPut:ATTenuation?");
            data = strsplit(res, ';');
            out = dictionary(keys, data);
            %clear anl;
        end


        %
        % Comandos de operação
        %

        % Se passado o terceiro argumento faz start/stop, senão CF
        function setFreq(obj, freq, stop)
            if nargin < 3
                obj.sendCMD( sprintf("SPECtrum:FREQuency:CENTer %f", freq) );
            else
                obj.sendCMD( sprintf("SPECtrum:FREQuency:START %f;:SPECtrum:FREQuency:STOP %f", freq, stop) );
            end
        end

        function setRes(obj, res)
            if ischar(res) && contains( num2str(res),'auto','IgnoreCase', true )
                obj.sendCMD("SPECtrum:BANDwidth:RESolution:Auto On");
            else
                obj.sendCMD( sprintf("SPECtrum:BANDwidth:RESolution %f", res) );
            end
        end

        function setSpan(obj, span)
            obj.sendCMD( sprintf("SPECtrum:FREQuency:SPAN %f", span) );
        end

        function setAtt(obj, att)
            obj.sendCMD( sprintf(":INPut:ATTenuation %f", att) );
        end

        % Para atenuação de entrada < 15dB
        function preAmp(obj, state)
            if (contains(state, "On", "IgnoreCase", true)) || (contains(state, "1"))
                obj.sendCMD(":INPut:GAIN:STATe ON");
            else
                obj.sendCMD(":INPut:GAIN:STATe OFF");
            end
        end

        function value = getMarker(obj, freq, trace)
            obj.sendCMD( 'CALCulate:SPECtrum:MARKer1:STATe On');
            obj.sendCMD( sprintf('TRACe%i:SPECtrum:DETection AVERage', trace) );
            % TODO: Verificar se está dentro dos limites para evitar NaN.
            obj.sendCMD( sprintf('CALCulate:SPECtrum:MARKer1:X %i', freq)     );
            value = str2double(obj.getCMD('CALCulate:SPECtrum:MARKer1:Y?'));
            obj.sendCMD('CALCulate:SPECtrum:MARKer1:STATe Off');
        end

        function data = getTrace(obj, trace)
            obj.sendCMD("FORMat:DATA ASCii");
            pause(5)
            obj.sendCMD( sprintf('TRACe%i:SPECtrum:DETection AVERage', trace) );
            pause(5)
            traceData = str2double( strsplit( obj.getCMD(sprintf("FETCh:SPECtrum:TRACe%i?", trace) ), ',') );
            pause(5)
            fstart = str2double( obj.getCMD("SPECtrum:FREQuency:START?") );
            pause(5)
            fstop  = str2double( obj.getCMD("SPECtrum:FREQuency:STOP?" ) );
            pause(5)
            header = linspace(fstart, fstop, length(traceData));

            data = table( num2str(header'), traceData', 'VariableNames', {'freq', 'value'});
        end
    end
end


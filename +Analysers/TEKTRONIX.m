classdef TEKTRONIX < Analysers.Analyser
    methods
        function obj = TEKTRONIX(~,args)
            obj.prop = args;
        end

        function startUp(obj)
            if isempty(obj.conn)
                disp('TEKTRONIX.startUP: Criando nova conexão TCP.')
                obj.conn = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            end

            obj.sendCMD([ ...
                '*CLS;' ...
                '*ESE 1;' ...
                ':DISPlay:GENeral:MEASview:SELect SPEC;' ...
                ':FORMat:DATA BIN;' ...
                ':CALCulate:SPECtrum:MARKer1:STATe On;' ...
                ':SYSTem:GPS INT;' ...
                '*OPC']);

            obj.sendCMD(":INITiate:CONTinuous OFF"); % Single mesure

            res = obj.getCMD(":SYSTEM:ERROR?");

            if ~contains(res, "No error", "IgnoreCase", true)
                warning("TEKTRONIX: StartUp: " + res)
            else
                disp("TEKTRONIX: Start Ok.")
            end
        end    

        function out = getParms(obj)
            keys = [
                "Function"...
                "AVGCount"...
                "Detection"...
                "UnitPower"...
                "FStart"...
                "FStop"...
                "ResAuto"...
                "Res"...
                "InputGain"...
                "Att" 
                ];
            res = obj.getCMD( "" + ...
                ":TRACe1:SPECtrum:FUNCtion?;" + ...
                ":TRACe1:SPECtrum:AVERage:COUNt?;" + ...
                ":TRACe1:SPECtrum:DETection?;" + ...
                ":UNIT:POWer?;" + ...
                ":SPECtrum:FREQuency:STARt?;" + ...
                ":SPECtrum:FREQuency:STOP?;" + ...
                ":SPECtrum:BANDwidth:RESolution:AUTO?;" + ...
                ":SPECtrum:BANDwidth:RESolution?;" + ...
                ":INPut:GAIN:STATe?;" + ...
                ":INPut:ATTenuation?" );
            data = strsplit(res.', ';');
            out = dictionary(keys, data);
        end

        %
        % No Tektronix, o prefixo SPECtrum é mandatório,
        % por isso estão sobrecarregados a partir daqui.
        %

        function res = getSpan(obj)
            res = obj.getCMD(':SPECtrum:FREQuency:SPAN?');
        end

        function res = getRes(obj)
            res = obj.getCMD(':SPECtrum:BANDwidth:RESolution?');
        end

        % Se passado o terceiro argumento faz start/stop, senão CF
        function setFreq(obj, freq, stop)
            if nargin < 3
                obj.sendCMD( sprintf(":SPECtrum:FREQuency:CENTer %f", freq) );
            else
                obj.sendCMD( sprintf(":SPECtrum:FREQuency:START %f;:SPECtrum:FREQuency:STOP %f", freq, stop) );
            end
            % Sempre ajusta para Auto Level quando alterar a freq.
            obj.sendCMD("INPut:ALEVel"); % Auto Level
        end

        function setRes(obj, res)
            if ischar(res) && contains( num2str(res),'auto','IgnoreCase', true )
                obj.sendCMD(":SPECtrum:BANDwidth:RESolution:Auto On");
            else
                obj.sendCMD( sprintf(":SPECtrum:BANDwidth:RESolution %f", res) );
            end
        end

        function setSpan(obj, span)
            obj.sendCMD( sprintf(":SPECtrum:FREQuency:SPAN %f", span) );
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

        function value = getMarker(obj, freq, ~) % O argumento opcional é o trace
            %obj.sendCMD( sprintf(':TRACe%i:SPECtrum:DETection AVERage', trace) );

            
            % TODO: Verificar se está dentro dos limites para evitar NaN.
            obj.sendCMD( sprintf(':CALCulate:SPECtrum:MARKer1:X %i;*WAI', freq)     );

            if obj.getCMD('*OPC?') ~= '1'
                disp('Tektronixs: Marker pronto com atraso ...')
            end

            charValue = obj.getCMD(':CALCulate:SPECtrum:MARKer1:Y?;*WAI;');

            while( isnan(charValue) )
                warning('Tektronixs: Marker com atraso.')
                % Casting porque o resultado retorna 'char'
            end
            
            value = str2double( charValue );
        end

        function data = getTrace(obj, trace)
            %obj.sendCMD( sprintf(':TRACe%i:SPECtrum:DETection AVERage', trace) );
            obj.sendCMD(":INPut:ALEVel"); % Auto Level
            obj.sendCMD(":INITiate:IMMediate"); % Trigger

            writeline(obj.conn, sprintf(":FETCh:SPECtrum:TRACe%i?", trace));

            % if obj.getCMD('*OPC?') ~= '1'
            %     disp('Tektronixs: Trace data com atraso  ...')
            % end
            % 
            % while( obj.getCMD('*OPC?') ~= '1' )
            %     disp('Analyser: Aguardando Trace recursivo ...')
            %     pause(0.2)
            % end   

            traceData = readbinblock(obj.conn, 'single');

            if numel(traceData) ~= 501
                error('Tektronixs: Tamanho de vetor não esperado.')
            end

            if isnan(traceData)
                warning('Tektronixs: Trace data contém NaN')
            end

            fstart = str2double( obj.getCMD(":SPECtrum:FREQuency:START?") );
            fstop  = str2double( obj.getCMD(":SPECtrum:FREQuency:STOP?" ) );

            header = linspace(fstart, fstop, length(traceData));

            % if obj.getCMD('*OPC?') ~= '1'
            %     disp('Tektronixs: Trace header pronto com atraso  ...')
            % end

            % TODO: Possível falha na detecção
            if isnan(header)
                warning('Tektronixs: Trace head contém NaN')
            end   

            % header revertido de string para double para facilitar o plot
            data = table( header', traceData', 'VariableNames', {'freq', 'value'});
        end
    end
end


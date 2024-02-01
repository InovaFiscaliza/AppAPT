classdef TEKTRONIX < Analysers.Analyser

    %%
    %% Não é papel do instrumento conhecer a aplicação dele
    %%
    % properties
    %     App winAppColetaV2
    % end
    % 
    
    methods
        function obj = TEKTRONIX(~,args)
            obj.prop = args;
        end

    %     function obj = TEKTRONIX(app, idx)
    %         [instrHandle, msgError] = apt.utils.getInstrumentHandler(app, idx);
    % 
    %         if ~isempty(msgError)
    %             error(msgError)
    %         end
    % 
    %         obj.App  = app;
    %         obj.conn = instrHandle;
    %     end

        function startUp(obj)
            obj.sendCMD([ ...
                '*CLS;' ...
                '*ESE 1;' ...
                ':DISPlay:GENeral:MEASview:SELect SPEC;' ...
                ':FORMat:DATA BIN;' ...
                ':CALCulate:SPECtrum:MARKer1:STATe On;' ...
                ':SYSTem:GPS INT;' ...
                '*OPC']);

            obj.sendCMD(":INITiate:CONTinuous OFF"); % Set to single mesure

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
        % No Tektronix, o prefixo modo SPECtrum é mandatório,
        % por isso Analyser esstá sobrecarregado a partir daqui.
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
            obj.sendCMD( sprintf(':CALCulate:SPECtrum:MARKer1:X %i;*WAI', freq)     );

            charValue = obj.getCMD(':CALCulate:SPECtrum:MARKer1:Y?;*WAI;');
        
            % Casting porque o resultado retorna 'char'
            value = str2double( charValue );
        end

        function traceData = getTrace(obj, trace)
            timeoutTic = tic;
            t = toc(timeoutTic);

            NumberOfError = 0;
            while t<10
                try
                    flush(obj.conn);
                    writeline(obj.conn, sprintf("INIT;*WAI;:FETCh:SPECtrum:TRACe%i?", trace));
                    traceArray = readbinblock(obj.conn, 'single');

                    if numel(traceArray) ~= 501
                        error('Tektronixs: Tamanho de vetor não esperado.')
                    end

                    fstart = str2double( obj.getCMD(":SPECtrum:FREQuency:START?") );
                    fstop  = str2double( obj.getCMD(":SPECtrum:FREQuency:STOP?" ) );

                    header = linspace(fstart, fstop, numel(traceArray));
                    traceData = table( header', traceArray', 'VariableNames', {'freq', 'value'});

                    break

                catch
                    NumberOfError = NumberOfError+1;
                    flush(obj.conn)

                    if NumberOfError == 10
                        warning('Tektronixs: Reconnet Attempt.')
                        obj.conn.ReconnectAttempt(obj, obj.conn.UserData.instrSelected, 1, SpecificSCPI)
                    end
                end
            end       
        end

        function setDataPoints(~, ~)
            warning('TEKTRONIX: Instrumento fixo em 501 pontos.');
        end

        function points = getDataPoints(~)
            % Fixo
            points = 501;
        end
    end
end


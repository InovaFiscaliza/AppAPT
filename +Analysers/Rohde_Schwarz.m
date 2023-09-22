classdef Rohde_Schwarz < Analysers.Analyser
    methods
        function obj = Rohde_Schwarz(~,args)
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
                warning("R&S: StartUp: " + res)
            else
                disp("R&S: Start Ok.")
            end
        end

        function out = getParms(obj)
            keys = [
                "Trace1Mode"; 
                "SweeCount";
                "Function";
                "UnitPower";
                "FStart";
                "FStop";
                "SweepPoints";
                "ResAuto";
                "Res";
                "InputGain";
                "AttAuto";
                "Att";
                "SeewpTime";
                "FStartMin";
                "FStopMax";
                "VBW" ];
            res = obj.getCMD("" + ...
                ":DISPlay:WINDow:TRACe1:MODE?;" + ...
                ":SWEep:COUNt?;" + ...
                ":DETector1:FUNCtion?;" + ...
                ":UNIT:POWer?;" + ...
                ":FREQuency:STARt?;" + ...
                ":FREQuency:STOP?;" + ...
                ":SWEep:POINTS?;" + ...
                ":BANDwidth:RESolution:AUTO?;" + ...
                ":BANDwidth:RESolution?;" + ...
                ":INPut:GAIN:STATe?;" + ...
                ":INPut:ATTenuation:AUTO?;" + ...
                ":INPut:ATTenuation?;" + ...
                ":SWEep:TIME?;" + ...
                ":FREQuency:STARt? MIN;" + ...
                ":FREQuency:STOP? MAX;" + ...
                ":BANDwidth:VIDeo?");
            data = strsplit(res, ';');
            out = dictionary(keys, data);
        end

        function setAtt(obj, att)
            obj.sendCMD( sprintf(":INPut:ATTenuation %f", att) );
        end

        function preAmp(obj, state)
            if (contains(state, "On", "IgnoreCase", true)) || (contains(state, "1"))
                obj.sendCMD(":INPut:GAIN:STATe ON");
            else
                obj.sendCMD(":INPut:GAIN:STATe OFF");
            end
        end

        % TODO: A implementar:
        % function value = getMarker(obj, freq, trace)
        % function data = getTrace(obj, trace)

    end
end


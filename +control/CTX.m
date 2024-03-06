classdef CTX < handle

    properties
        setup
        context
    end
    
    methods
        function obj = CTX(~)
            disp('INFO: *** Controlador de contexto iniciado ***');          
        end

        function app = winAPTmain(~)
            % Reutiliza o appColetaV2 se ativo
            % TODO: Deve rodar com outras versões além do R2023a
            appFigure = findall(groot,'Type','Figure','Name', 'appColetaV2 R2023a');
            if ~isempty(appFigure) && isvalid(appFigure)
                app = appFigure.RunningAppInstance;
            else
                app = winAppColetaV2;
            end 
            % Desabilita o backtrace dos warnings para uma avaliação mais limpa.
            % warning('off', 'backtrace');
        end

        function Instr = instantiate(idx)
            % Busca o IDN e instancia a classe do Instrumento
            rawIDN = app.receiverObj.Table.Handle{idx,1}.UserData.IDN;
            [instrHandle, ~] = apt.utils.getInstrumentHandler(app, idx);
            Instr = Analysers.Analyser.instance(rawIDN);
            Instr.conn = instrHandle;
        end

        function changed(obj)
            disp('Context:')
            obj.setup.CW.value
            obj.setup.CW.color

            if isfield(obj.setup.CW, 'message')
                disp('O campo "message" existe na estrutura obj.setup.CW.');
            else
                disp('O campo "message" não existe na estrutura obj.setup.CW.');
            end
        end
    end
end
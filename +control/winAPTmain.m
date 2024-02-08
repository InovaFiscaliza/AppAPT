classdef winAPTmain
    methods
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
    end
end
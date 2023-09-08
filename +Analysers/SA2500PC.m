classdef SA2500PC < Analysers.TEKTRONIX

    % O sufixo PC indica o uso do simulador de um SA2500 no PC
    methods
        function obj = SA2500PC(~, args)
            obj@Analysers.TEKTRONIX('SA2500PC', args)
        end

        % Simula porque o reset real encerra o SA2500PC
        function obj = scpiReset(obj)
            disp('Simulando um "SCPI Reset" para o modelo SA2500PC.')
        end
    end
end
classdef SA2500PC < TEKTRONIX

    % O sufixo PC indica o uso do simulador de um SA2500 no PC
    methods
        function obj = SA2500PC(~, args)
            obj@TEKTRONIX('SA2500PC', args)
        end

        % Fingindo porque o reset encerra o simulador
        function obj = scpiReset(obj)
            disp('Simulando um "SCPI Reset" para o modelo SA2500PC.')
        end
    end
end
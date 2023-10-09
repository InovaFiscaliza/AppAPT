function dataTraces = getTracesFromUnit(spc, nTraces)
% Função de referência, a ser incorporada na classe correta.
% Faz chamadas de traço e acumula para entregar os dados

    %ref = spc.getTrace(1);
    
    %dataTraces = zeros(nTraces, height(ref), 'single');
    dataTraces = zeros(nTraces, 501, 'single');

    for ii = 1:nTraces
        dataTraces(ii, :) = spc.getTrace(1).value;
        sprintf("Trace nº %i", ii)
    end

end
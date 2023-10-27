function dataTraces = getTracesFromUnit(instrumentObj, nTraces)
% Função de referência, a ser incorporada na classe correta.
% Faz chamadas de traço e acumula para entregar os dados

    %ref = spc.getTrace(1);
    
    %dataTraces = zeros(nTraces, height(ref), 'single');
    idx1 = find(strcmp(instrumentObj.App.receiverObj.Config.Tag, instrumentObj.conn.UserData.instrSelected.Tag), 1);
    DataPoints_Limits = instrumentObj.App.receiverObj.Config.DataPoints_Limits{idx1};

    if diff(round(DataPoints_Limits))
        % Datapoints = instrumentObj.getDataPoints;
        error('O instrumento deve ter um número fixo de pontos! A evoluir...')
    end
    DataPoints = DataPoints_Limits(1);

    instrumentObj.startUp()

    dataTraces = zeros(nTraces, DataPoints, 'single');
    for ii = 1:nTraces
        if ~mod(ii,10); ii
        end
        dataTraces(ii, :) = instrumentObj.getTrace(1);
    end
end
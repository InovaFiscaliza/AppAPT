function estimateCW(~, ~, ~)
    shape = fcn.naive.calculateShape('hReceiver', 'FreqList', 'OptionalArguments');

    % Pré alocação de Estimativa de CW:
    eCW = zeros(height(shape), 2, 'single');

    % Média da largura (de fcn.naive.calculateShape)
    for ii = 1:height(shape)
        eCW(ii,:) = ( shape(ii,2) + shape(ii,1) ) / 2;
    end

    % Alocação para o Z-Score
    zscore = zeros(height(shape), 2, 'single');

    % Média e desvio do total
    avgECW = mean( eCW );
    stdECW = std ( eCW );

    for ii = 1:height(eCW)
        zscore(ii,1) = [ abs( ( eCW(ii) - avgECW ) / stdECW )];
        zscore(ii,2) = ii; % Guarda os índices
    end

    % Obtém a frequência com índice de menor Z score.
    for ii = 1:(height(zscore) * 0.2)
        feCW(ii) = eCW(ii);
    end

    fprintf('Frequência central estimada para 68%% das medidas em %i ± %0.f Hz.\n', feCW(1), std(feCW) );
    disp('Estimativa evidentemente errada porque não condiz com o instrumento.')
end


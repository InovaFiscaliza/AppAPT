function estimateCW(dataTraces)
    shape = apt.fcn.naive.calculateShape(dataTraces);

    % Freq. média dos valores
    eCW = mean(shape, 2);

    % Média e desvio do total
    avgECW = mean( eCW );
    stdECW = std ( eCW );

    % Calcula a distância de cada valor para a média
    zscore = [ abs( ( eCW - avgECW ) / stdECW ), (1:numel(eCW))' ];

    [~,zIdx] = sort(zscore(:,1));
    eCW = zscore(zIdx,:);
    eCW = eCW( 1:round(height(eCW) * 0.2), : );

    fprintf('Naive: Frequência central estimada para 68%% das medidas em %0.f ± %0.f Hz.\n', double(avgECW + eCW(1)), std(eCW(1,:)) );
    fprintf('Naive: Frequência central estimada para 89%% das medidas em %0.f ± %0.f Hz.\n', double(avgECW + eCW(1)), 1.5 * std(eCW(1,:)) );
    fprintf('Naive: Frequência central estimada para 95%% das medidas em %0.f ± %0.f Hz.\n', double(avgECW + eCW(1)), 2 * std(eCW(1,:)) );
end


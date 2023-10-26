function estimateCW(~, ~, ~)
    shape = fcn.naive.calculateInternalShape('hReceiver', 'FreqList', 'OptionalArguments');

    % Freq. média dos valores
    eCW = mean(shape, 2);

    % Média e desvio do total
    avgECW = mean( eCW );
    stdECW = std ( eCW );

    zscore = [ abs( ( eCW - avgECW ) / stdECW ), (1:numel(eCW))' ];

    [~,zIdx] = sort(zscore(:,1));
    feCW = zscore(zIdx,:);
    feCW = feCW( 1:round(height(feCW) * 0.2), : );

    fprintf('Frequência central estimada para 68%% das medidas em %i ± %0.f Hz.\n', feCW(1), std(feCW(:,1)) );
end


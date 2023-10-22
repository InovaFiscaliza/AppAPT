function calculateBW(~)

    % Fake call
    shape = fcn.naive.calculateShape('hReceiver', 'FreqList', 'OptionalArguments');

    nTraces = height(shape);

    BW = zeros(nTraces, 1, 'single');

    for ii = 1:nTraces
        % Frequência superior - Frequência inferior
        BW(ii,:) = shape(ii,2) - shape(ii,1);
    end

    stdBW = std(BW);

    fprintf('De %i medidas válidas: Max: %i, Min: %i, Avg: %i ± %0.f Hz\n', nTraces, max(BW), min(BW), mean(BW), std(BW));
    smax = mean(BW) + 2 * stdBW;
    fprintf('Se a distribuição for normal, 95%% dos valores são menores que %.0f kHz de desvio.\n', smax - stdBW);
end


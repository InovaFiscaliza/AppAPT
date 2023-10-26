function calculateBW(~)

    % Fake call
    shape = fcn.naive.calculeInternalShape('hReceiver', 'FreqList', 'OptionalArguments');

    nTraces = height(shape);

    BW = diff(shape');

    stdBW = std(BW);

    fprintf('De %i medidas válidas: Max: %i, Min: %i, Avg: %i ± %0.f Hz\n', nTraces, max(BW), min(BW), mean(BW), std(BW));
    smax = mean(BW) + 2 * stdBW;
    fprintf('Se a distribuição for normal, 95%% dos valores são menores que %.0f kHz de desvio.\n', smax - stdBW);
end


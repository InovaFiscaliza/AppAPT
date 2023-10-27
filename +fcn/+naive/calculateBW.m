function calculateBW(~)

    % Fake call
    shape = apt.fcn.naive.calculateInternalShape('hReceiver', 'FreqList');

    nTraces = height(shape);

    BW = diff(shape');

    stdBW = std(BW);

    fprintf('De %i medidas válidas: Max: %0.f, Min: %0.f, Avg: %0.f ± %0.f Hz\n', nTraces, max(BW), min(BW), mean(BW), std(BW));
    s68 = mean(BW) + stdBW;
    s95 = mean(BW) + 2 * stdBW;
    fprintf('Se a distribuição for normal, 68%% dos valores estão abaixo de %.0f kHz.\n', s68 - stdBW);
    fprintf('Se a distribuição for normal, 95%% dos valores estão abaixo de %.0f kHz.\n', s95 - stdBW);
end


function calculateBW(dataTraces)
    shape = apt.fcn.naive.calculateShape(dataTraces);

    nTraces = height(shape);

    BW = diff(shape');

    stdBW = std(BW);

    fprintf('Naive: De %i medidas válidas, o desvio está em Max: %0.f, Min: %0.f, Avg: %0.f ± %0.f Hz\n', nTraces, max(BW), min(BW), mean(BW), std(BW));
    s68 = mean(BW) + stdBW;
    s89 = mean(BW) + 1.5 * stdBW;
    s95 = mean(BW) + 2 * stdBW;
    fprintf('Naive: Se a distribuição for normal, 68%% do desvio está abaixo de %.0f kHz.\n', s68 - stdBW);
    fprintf('Naive: Se a distribuição for normal, 89%% do desvio está abaixo de %.0f kHz.\n', s89 - stdBW);
    fprintf('Naive: Se a distribuição for normal, 95%% do desvio está abaixo de %.0f kHz.\n', s95 - stdBW);
end


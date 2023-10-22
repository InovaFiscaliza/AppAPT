function calculateBW(~, ~, ~)

    shape = fcn.calculateShape('hReceiver', 'FreqList', 'OptionalArguments');

    % % Remove os NaN
    % indexNaN = isnan(shape); 
    % BW = shape(~indexNaN);

    for ii = 1:height(shape)
        % fSup - fInf
        BW(ii,:) = shape(ii,2) - shape(ii,1);
    end

    fprintf('%i medidas válidas: Max: %i, Min: %i, Avg: %i ± %0.f Hz\n', height(BW), max(BW), min(BW), mean(BW), std(BW));
    smax = mean(BW) + 2 * std(BW);
    smin = mean(BW) - 2 * std(BW);
    fprintf('95%% dos valores entre %.0f kHz e %.0f kHz.\n', smin, smax);
end


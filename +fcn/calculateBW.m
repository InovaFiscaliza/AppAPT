function calculateBW(hReceiver, FreqList, OptionalArguments)

    % Utilizando medidas do workspace do caderno de testes.
    load('C:\P&D\AppAPT\+Analysers\TestBook\TestTektronixSA2500.mat')

    nTraces = height(trcs);
   
    delta = -25;
    
    for ii = 1:nTraces
        peak = max( trcs(ii,:) );
        peakIndex = find( trcs(ii,:) == peak );

        fpeak = trace.freq(peakIndex);

        % Para cima
        for jj = peakIndex:width(trcs(ii,:))
            if trcs(ii,jj) <= peak + delta 
                fSup = trace.freq(jj);
                break;
            end
            if jj == height(trace.freq(jj))
                fSup = 0; % Não encontrado
            end
        end
    
        % Para baixo
        for jj = peakIndex:-1:1
            if trcs(ii,jj) <= peak + delta
                fInf = trace.freq(jj);
                break;
            end
    
            if jj == 1
                fInf = NaN; % Não encontrado
            end    
        end
    
        if fSup == 0 || fInf == 0
            BW(ii) = 0;
        else
            BW(ii) = fSup - fInf;
        end
    end
    
    % Remove os NaN
    indexNaN = isnan(BW); 
    BW = BW(~indexNaN);

    fprintf('%i medidas válidas: Max: %i, Min: %i, Avg: %i ± %0.f Hz\n', width(BW), max(BW), min(BW), mean(BW), std(BW));
    smax = mean(BW) + 2 * std(BW);
    smin = mean(BW) - 2 * std(BW);
    fprintf('95%% dos valores entre %.0f MHz e %.0f MHz.\n', smin, smax);
end


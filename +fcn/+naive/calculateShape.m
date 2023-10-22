function shape = calculateShape(hReceiver, FreqList, OptionalArguments)

    % Utilizando medidas do workspace do caderno de testes.
    load('C:\P&D\AppAPT\+Analysers\TestBook\TestTektronixSA2500.mat');

    % trcs - Traces no workspace
    nTraces = height(trcs);

    delta = -25;

    % Conterá a frequência inferior e superior para um delta dB especificado.
    shape = zeros(nTraces, 2, 'single');
   
    for ii = 1:nTraces
        peak = max( trcs(ii,:) );
        peakIndex = find( trcs(ii,:) == peak );

        % Para cima
        for jj = peakIndex:width(trcs(ii,:))
            if trcs(ii,jj) <= peak + delta 
                fSup = trace.freq(jj);
                break;
            end
            if jj == height(trace.freq(jj))
                fSup = NaN; % Não encontrado
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

        shape(ii,:) = [fInf,fSup];
    end
end
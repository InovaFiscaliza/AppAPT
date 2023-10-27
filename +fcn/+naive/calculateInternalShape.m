% hReceiver, FreqList, OptionalArguments
function shape = calculateInternalShape(~,~,~)

    % calculateInternalShape
    % TODO: calculateExternalShape
    % Utilizando medidas do workspace do caderno de testes.
    if nargin < 3
        load('C:\P&D\AppAPT\+Analysers\TestBook\TestTektronixSA2500.mat', 'trcs', 'trace');
    end

    % trcs - Traces no workspace
    nTraces = height(trcs);

    % o delta precisa ser um número negativo.
    delta = -26;

    % Conterá a frequência inferior e superior para um delta dB especificado.
    shape = zeros(nTraces, 2, 'single');
   
    for ii = 1:nTraces
        fInf = NaN;
        fSup = NaN;
        
        peak = max( trcs(ii,:) );
        peakIndex = find( trcs(ii,:) == peak );

        % Para cima
        for jj = peakIndex+1:width(trcs(ii,:))
            if trcs(ii,jj) <= peak + delta 
                fSup = interp1( trcs(ii,jj-1:jj), trace.freq(jj-1:jj), peak + delta);
                % fSup = trace.freq(jj);
                break;
            end
        end
    
        % Para baixo
        for jj = peakIndex-1:-1:1
            if trcs(ii,jj) <= peak + delta
                fInf = interp1( trcs(ii,jj:jj+1), trace.freq(jj:jj+1), peak + delta);
                % fInf = trace.freq(jj);
                break;
            end 
        end
        shape(ii,:) = [fInf,fSup];
    end
    
    % Remove qualquer linha com NaN
    indexNaN = any(isnan(shape),2); 
    shape = shape(~indexNaN,:);
end
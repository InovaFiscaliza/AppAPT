function shape = calculateShape(dataTraces)
    nTraces = height(dataTraces);

    % o delta é sempre um número negativo para xdB.
    delta = -26;

    % Pré-aloca a tabela
    shape = zeros(nTraces, 2, 'single');
   
    for ii = 1:nTraces
        fInf = NaN;
        fSup = NaN;
        
        peak = max( dataTraces(ii,:) );
        peakIndex = find( dataTraces(ii,:) == peak );


        % calculateInternalShape (Do pico para as bordas)

        % Busca do pico para acima
        for jj = peakIndex+1:width(dataTraces(ii,:))
            if dataTraces(ii,jj) <= peak + delta
                % Interpola a frequência
                fSup = interp1( dataTraces(ii,jj-1:jj), trace.freq(jj-1:jj), peak + delta);
                break;
            end
        end
    
        % Busca do pico para abaixo
        for jj = peakIndex-1:-1:1
            if dataTraces(ii,jj) <= peak + delta
                % Interpola a frequência
                fInf = interp1( dataTraces(ii,jj:jj+1), trace.freq(jj:jj+1), peak + delta);
                break;
            end 
        end
        shape(ii,:) = [fInf,fSup];
    end

    
    % Remove qualquer linha com NaN
    indexNaN = any(isnan(shape),2); 
    shape = shape(~indexNaN,:);
end
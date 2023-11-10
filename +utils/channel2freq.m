function freq = channel2freq( channel )
%Converte o número do canal para a frequência central

    freq = NaN;

    % TV VHF
    if channel >= 2 && channel <= 4;
        freq = channel * 6 + 42;
    end
    if channel >= 5 && channel <= 6
        freq = channel * 6 + 46;
    end
    if channel >= 7 && channel <= 13
        freq = channel * 6 + 132;
    end

    % TV UHF
    if channel >= 14 && channel <= 83
        freq = channel * 6 + 386;
    end

    % FM
    if channel >= 200 && channel <= 300
        freq = ( channel - 200 ) * 0.2 + 87.9;
    end
    
    if isnan(freq)
        warning('Canal não encontrado.')
    else
        freq = freq * 1000000;
    end
end


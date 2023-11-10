function channel = freq2channel( freq )
%Converte o número do canal para a frequência central

    freq = freq / 1000000;

    % FM
    if freq >= 87.9 && freq <= 107.9
        channel = round( ( freq - 87.9 ) / 0.2 + 200 );
    else
        warning('Canal não encontrado.')
        channel = NaN;
    end

end


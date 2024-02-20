function value = DetectSrParam(str)
    str = lower(str);
    str = regexprep(str, ',', '.');

    try
        % Encontrar números com prefixo e/ou sufixo no texto
        regex = '(\D*?)(\d+\.?\d*|\.\d+)(\D*)';
    
        % Encontrar os números na string
        match = regexp(str, regex, 'tokens');
        prefix = match{1}{1};
        sufix  = match{1}{3};   
        value = str2double(match{1}{2});

        if contains(sufix, 'k')
            value = value * 1e3;
        elseif contains(sufix, 'm')
            value = value * 1e6;
        elseif contains(sufix, 'g')
            value = value * 1e9;
        end

        %% TODO: Depende do contexto. Não está no local correto!
        % Se solicitado no prefixo:
        if contains(prefix, 'fm') || contains(prefix, 'vhf') || contains(prefix, 'uhf')
            value = utils.channel2freq(value);
        end

    catch
        value  = NaN;
    end
end

% idx = 0: Load previous workspace
% idx = 1: instrumento virtual
% idx = 2: instrumento real

idx = 0;
samples = 20;
target = 'FM'; % FM ou SBTVD

if idx ~= 0
    % Reutiliza o app se ativo
    % TODO: Deve rodar com o R2023b também
    appFigure = findall(groot,'Type','Figure','Name', 'appColetaV2 R2023a');
    if ~isempty(appFigure) && isvalid(appFigure)
        app = appFigure.RunningAppInstance;
    else
        app = winAppColetaV2;
    end

    % Busca o IDN e instancia a classe do Instrumento
    rawIDN = app.receiverObj.Table.Handle{idx,1}.UserData.IDN;
    [instrHandle, msgError] = apt.utils.getInstrumentHandler(app, idx);
    Instr = Analysers.Analyser.instance(rawIDN);
    Instr.conn = instrHandle;

    % Desabilita o backtrace dos warnings para uma avaliação mais limpa, se necessário.
    % warning('off', 'backtrace');
    
    % Ajusta o instrumento pela API
    if idx == 2
        % Teste de comportamento
        Instr.setDataPoints(600);
        Instr.setRes('auto');

        if strcmp(target, 'FM')
            % Chamada pelo nº do canal.
            % Emissora de referência: Transamérica 100.3 MHz, classe E3.
            Instr.setFreq( apt.utils.channel2freq(262) ); % FM por canal.
            Instr.setSpan(500000);
        elseif strcmp(target,'SBTVD')
            % % Teste SBTVD - Globo - 41 - Central em 635.14MHz
            Instr.setFreq( 635140000 );
            Instr.setSpan(  10000000 ); % 10 MHz
        else
            error('Alvo não encontrado')
        end

    else 
        Instr.setFreq(10000000);  % Virtual
        Instr.setSpan(10000);      
    end
    
    disp("Starting measures")
    tekbench = apt.bench.Naive();
    tekbench.getTracesFromUnit(Instr, samples);
    disp("done...")

    if strcmp(target, 'FM')
        save('+apt/+bench/TestBook/Fluxo.mat', 'tekbench')
    elseif strcmp(target, 'SBTVD')
        save('+apt/+bench/TestBook/Fluxo_teste_SBTVD.mat', 'tekbench')
    else
        error('Alvo não encontrado')
    end
else
    if strcmp(target, 'FM')
        load('+apt/+bench/TestBook/Fluxo.mat')
    elseif strcmp(target, 'SBTVD')
        load('+apt/+bench/TestBook/Fluxo_teste_SBTVD.mat')
    else
        error('Alvo não encontrado')
    end
end


%
% Calculate BW por xdB
%

[BW, stdBW, eBW, estdBW] = tekbench.calculateBWxdB;
    
    nTraces = width(BW);
    
    disp('Naive: BW por xdB:')
    fprintf( 'Naive: \tDe %i medidas válidas, em %i dB (Ref. ITU Handbook 2011, pg. 255, TABLE 4.5-1)\n', nTraces, tekbench.delta );
    disp('Naive:  Abrindo a partir do pico:')
    fprintf( 'Naive: \t\tO desvio está em Max: %0.f, Min: %0.f, Avg: %0.f ± %0.f Hz\n', max(BW), min(BW), mean(BW), std(BW) );
    % s68 = mean(BW) + stdBW;
    % s89 = mean(BW) + 1.5 * stdBW;
    % s95 = mean(BW) + 2 * stdBW;
    % fprintf('Naive: \t\tSe a distribuição for normal, 68%% do desvio está abaixo de %.0f kHz.\n', s68 - stdBW);
    % fprintf('Naive: \t\tSe a distribuição for normal, 89%% do desvio está abaixo de %.0f kHz.\n', s89 - stdBW);
    % fprintf('Naive: \t\tSe a distribuição for normal, 95%% do desvio está abaixo de %.0f kHz.\n', s95 - stdBW);

    disp('Naive:  Fechando a partir das bordas:')
    fprintf( 'Naive: \t\tO desvio está em Max: %0.f, Min: %0.f, Avg: %0.f ± %0.f Hz\n', max(eBW), min(eBW), mean(eBW), std(eBW) );
    % s68 = mean(eBW) + estdBW;
    % s89 = mean(eBW) + 1.5 * estdBW;
    % s95 = mean(eBW) + 2 * estdBW;
    % fprintf('Naive: \t\tSe a distribuição for normal, 68%% do desvio está abaixo de %.0f kHz.\n', s68 - estdBW);
    % fprintf('Naive: \t\tSe a distribuição for normal, 89%% do desvio está abaixo de %.0f kHz.\n', s89 - estdBW);
    % fprintf('Naive: \t\tSe a distribuição for normal, 95%% do desvio está abaixo de %.0f kHz.\n', s95 - estdBW);
    line;

%
% Estimate CW
%

[CW, stdCW] = tekbench.estimateCW;

    disp('Naive: Frequência Central estimada para 20% do z-score:')
    fprintf('Naive: \t\tPara 68%% das medidas em %0.f ± %0.f Hz.\n', CW, stdCW );
    fprintf('Naive: \t\tPara 89%% das medidas em %0.f ± %0.f Hz.\n', CW, 1.5 * stdCW );
    fprintf('Naive: \t\tPara 95%% das medidas em %0.f ± %0.f Hz.\n', CW, 2 * stdCW );

    line;

% Largura do canal

if strcmp(target, 'FM')
    CW = 100300000;
    LInf = CW - 100000;
    LSup = CW + 100000;
elseif strcmp(target, 'SBTVD')
    CW = 635140000;
    LInf = CW - 3000000;
    LSup = CW + 3000000;
else
    error('Alvo não encontrado')
end

% [AvgCP, stdCP] = tekbench.channelPower(LInf, LSup);

    AvgCP = pow2db( mean( tekbench.channelPower( [], tekbench.freq2idx(LInf), tekbench.freq2idx(LSup) ) ) );
    stdCP = std ( pow2db( tekbench.channelPower( [], tekbench.freq2idx(LInf), tekbench.freq2idx(LSup) ) ) );

    disp('Naive: Potência do Canal');
    fprintf('Naive: \t\tChannel Power %0.2f ± %0.2f dB (ref. unidade de entrada)\n', AvgCP, stdCP);
    line;

    % Plota largura e potência do canal
    idx1 = find( tekbench.sampleTrace.freq >= LInf, 1 );
    idx2 = find( tekbench.sampleTrace.freq >= LSup, 1 );

    f = figure; ax = axes(f);
    plot(ax, tekbench.sampleTrace.freq, tekbench.dataTraces(1,:))
    hold on
    xline( tekbench.sampleTrace.freq(idx1), 'g', 'LineWidth', 2 );
    xline( tekbench.sampleTrace.freq(idx2), 'g', 'LineWidth', 2 );
    yline( AvgCP, 'r', 'LineWidth', 2 );
    xlabel(ax, 'Largura do canal (verde)');
    ylabel(ax, 'Channel Power (vermelho)');
    drawnow

tekbench.experimentalSmoothPlot;

%
% Calculate BW por beta%
%
[bBw, stdbBW] = tekbench.estimateBWBetaPercent;
fprintf('Naive: largura do canal para beta %i%%:\n', tekbench.beta );
fprintf('Naive: \t\tLargura do canal com %i amostras em %0.f ± %0.f Hz\n', nTraces, bBw, stdbBW);

function line()
    n = repmat('-', 1, 80);
    disp(n);
end

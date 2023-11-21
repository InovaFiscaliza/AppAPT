% idx = 0: Load workspace
% idx = 1: instrumento virtual
% idx = 2: instrumento real

idx = 0;

if idx ~= 0

    % Reutiliza o app se ativo
    appFigure = findall(groot,'Type','Figure','Name', 'appColetaV2 R2023a');
    if ~isempty(appFigure) && isvalid(appFigure)
        app = appFigure.RunningAppInstance;
    else
        app = winAppColetaV2;
    end

    Instr = apt.Analysers.TEKTRONIX(app, idx);
    
    % Timeout para evitar:
    % Warning: The specified amount of data was not returned within the Timeout period for 'readbinblock'.
    % 'tcpclient' unable to read any data. For more information on possible reasons, see tcpclient Read Warnings. 
    Instr.conn.Timeout = 5;
    
    % Ajusta o instrumento pela API
    if idx == 2
        Instr.setFreq( apt.utils.channel2freq(262) ); % Real, FM por canal.
        Instr.setSpan(500000);
    else 
        Instr.setFreq(10000000);  % Virtual
        Instr.setSpan(10000);      
    end
    
    tekbench = apt.bench.Naive();
    tekbench.getTracesFromUnit(Instr, 10);

    save('+apt/+bench/TestBook/Fluxo.mat', 'tekbench')
else
    load('+apt/+bench/TestBook/Fluxo.mat')
end

tekbench.delta = 22; % Teste de alteração de atributo de Classe.
                     % O padrão é 26 dB para FM em F3E.
                     % Ref. ITU Handbook 2011, pg. 255, TABLE 4.5-1.

%
% Calculate BW por xdB
%

[BW, stdBW] = tekbench.calculateBWxdB;
    
    nTraces = width(BW);
    
    fprintf('Naive: De %i medidas válidas, o desvio está em Max: %0.f, Min: %0.f, Avg: %0.f ± %0.f Hz\n', nTraces, max(BW), min(BW), mean(BW), std(BW));
    s68 = mean(BW) + stdBW;
    s89 = mean(BW) + 1.5 * stdBW;
    s95 = mean(BW) + 2 * stdBW;
    fprintf('Naive: Se a distribuição for normal, 68%% do desvio está abaixo de %.0f kHz.\n', s68 - stdBW);
    fprintf('Naive: Se a distribuição for normal, 89%% do desvio está abaixo de %.0f kHz.\n', s89 - stdBW);
    fprintf('Naive: Se a distribuição for normal, 95%% do desvio está abaixo de %.0f kHz.\n', s95 - stdBW);

%
% Estimate CW
%

[CW, stdCW] = tekbench.estimateCW;

    fprintf('Naive: Frequência central estimada para 68%% das medidas em %0.f ± %0.f Hz.\n', CW, stdCW );
    fprintf('Naive: Frequência central estimada para 89%% das medidas em %0.f ± %0.f Hz.\n', CW, 1.5 * stdCW );
    fprintf('Naive: Frequência central estimada para 95%% das medidas em %0.f ± %0.f Hz.\n', CW, 2 * stdCW );

% Largura do canal
CW = 100300000;
LInf = CW - 100000;
LSup = CW + 100000;
BW = 300000; % Pouco maior que a largura do canal

[AvgCP, stdCP] = tekbench.channelPower(LInf, LSup, BW);

    fprintf('Naive: Channel Power %0.2f ± %0.2f dB (ref. unidade de entrada)\n.', AvgCP, stdCP);

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

% Revertida. A ser reimplementada do zero.

% tekbench.estimateBWBetaPercent(BW);
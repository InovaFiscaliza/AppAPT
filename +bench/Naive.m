classdef Naive < handle
    %%  Funções de cálculo "ingênuas" para propósito geral.

    properties
        beta            {mustBeGreaterThan(beta, 0), mustBeLessThan(beta, 100)} = 99
        delta           {mustBeInteger} = 26 % Para xdB (ref. FM)
        sampleTrace
        dataTraces
        smoothedTraces
        shape           % Medido do pico até o delta
        extShape        % Medido dos extremos para o pico
    end

    methods(Access = private)

        function calculateShape(obj)
            nTraces = height(obj.dataTraces);

            % Pré-aloca as tabelas
            obj.shape    = zeros(nTraces, 2, 'single');
            obj.extShape = zeros(nTraces, 2, 'single');

            % Escolher dataTraces ou smoothedTraces
            % refData = obj.smoothedTraces;

            for ii = 1:nTraces
                fIntInf = NaN;
                fIntSup = NaN;
                fExtInf = NaN;
                fExtSup = NaN;

                refData = obj.dataTraces;

                peak = max( refData(ii,:) );
                peakIndex = find( refData(ii,:) == peak );

                % Por definição o delta é sempre negativo.
                if obj.delta > 0
                    obj.delta = obj.delta * -1;
                end

                % Busca do pico para baixo
                for jj = peakIndex-1:-1:1
                    if refData(ii,jj) <= peak + obj.delta
                        % Interpola a frequência
                        fIntInf = interp1( refData(ii,jj:jj+1), obj.sampleTrace.freq(jj:jj+1), peak + obj.delta);
                        break;
                    end
                end

                % Busca do pico para cima
                for jj = peakIndex+1:width(refData(ii,:))
                    if refData(ii,jj) <= peak + obj.delta
                        % Interpola a frequência
                        fIntSup = interp1( refData(ii,jj-1:jj), obj.sampleTrace.freq(jj-1:jj), peak + obj.delta);
                        break;
                    end
                end

                % Busca do final da faixa para o pico
                for jj = width(refData(ii,:)):-1:peakIndex+1
                    if refData(ii,jj) >= peak + obj.delta
                        % Interpola a frequência
                        if jj == width(refData(ii,:))
                            fExtSup = obj.sampleTrace.freq(jj);
                        else
                            fExtSup = interp1( refData(ii,jj:jj+1), obj.sampleTrace.freq(jj:jj+1), peak + obj.delta);
                        end
                        break;
                    end
                end

                % Busca do início da faixa para o pico
                for jj = 1:peakIndex-1
                    if refData(ii,jj) >= peak + obj.delta
                        % Interpola a frequência
                        if jj == 1
                            fExtInf = obj.sampleTrace.freq(jj);
                        else
                            fExtInf = interp1( refData(ii,jj-1:jj), obj.sampleTrace.freq(jj-1:jj), peak + obj.delta);
                        end
                        break;
                    end
                end

                obj.shape(ii,:)    = [fIntInf,fIntSup];
                obj.extShape(ii,:) = [fExtInf,fExtSup];
            end

            % Remove linhas com NaN
            indexNaN = any(isnan(obj.shape),2);
            obj.shape(indexNaN,:)    = [];
            obj.extShape(indexNaN,:) = [];
        end
    end

    methods

        function obj = Naive()
        end

        function getTracesFromUnit(obj, instrumentObj, nTraces)
            % Faz chamadas de traço e acumula para entregar os dados

            idx1 = find(strcmp(instrumentObj.App.receiverObj.Config.Tag, instrumentObj.conn.UserData.instrSelected.Tag), 1);
            DataPoints_Limits = instrumentObj.App.receiverObj.Config.DataPoints_Limits{idx1};

            % TODO: Verificar casos de pontos variáveis
            if diff(round(DataPoints_Limits))
                % Datapoints = instrumentObj.getDataPoints;
                error('O instrumento deve ter um número fixo de pontos! A evoluir...')
            end
            DataPoints = DataPoints_Limits(1);

            instrumentObj.startUp();

            obj.sampleTrace = instrumentObj.getTrace(1);
            obj.dataTraces  = zeros(nTraces, DataPoints, 'single');

            ii = 1;
            while ii <= nTraces
                % % Mostra os passos dos traces.
                % if ~mod(ii,10); ii
                % end
                try
                    obj.dataTraces(ii,:) = instrumentObj.getTrace(1).value;
                    ii = ii + 1;
                catch
                end
            end
            
            obj.calculateShape();
        end

        function calculateBWxdB(obj)
            % TODO: Remover: Para o caso de não haver coleta do intrumento (idx = 0)
            obj.calculateShape();

            nTraces = height(obj.shape);

            BW = diff(obj.shape');

            stdBW = std(BW);

            fprintf('Naive: De %i medidas válidas, o desvio está em Max: %0.f, Min: %0.f, Avg: %0.f ± %0.f Hz\n', nTraces, max(BW), min(BW), mean(BW), std(BW));
            s68 = mean(BW) + stdBW;
            s89 = mean(BW) + 1.5 * stdBW;
            s95 = mean(BW) + 2 * stdBW;
            fprintf('Naive: Se a distribuição for normal, 68%% do desvio está abaixo de %.0f kHz.\n', s68 - stdBW);
            fprintf('Naive: Se a distribuição for normal, 89%% do desvio está abaixo de %.0f kHz.\n', s89 - stdBW);
            fprintf('Naive: Se a distribuição for normal, 95%% do desvio está abaixo de %.0f kHz.\n', s95 - stdBW);
        end

        function estimateCW(obj)
            % TODO: Remover: Para o caso de não haver coleta do intrumento
            obj.calculateShape();

            % Freq. média dos valores
            eCW = mean(obj.shape, 2);

            % Média e desvio do total
            avgECW = mean( eCW );
            stdECW = std ( eCW ) + 0.0001; % Evita desvio zero no simulador.

            % Calcula a distância de cada valor para a média
            zscore = [ abs( ( eCW - avgECW ) / stdECW ), (1:numel(eCW))' ];

            [~,zIdx] = sort(zscore(:,1));
            eCW = zscore(zIdx,:);
            eCW = eCW( 1:round(height(eCW) * 0.2), : );

            fprintf('Naive: Frequência central estimada para 68%% das medidas em %0.f ± %0.f Hz.\n', double(avgECW + eCW(1)), std(eCW(1,:)) );
            fprintf('Naive: Frequência central estimada para 89%% das medidas em %0.f ± %0.f Hz.\n', double(avgECW + eCW(1)), 1.5 * std(eCW(1,:)) );
            fprintf('Naive: Frequência central estimada para 95%% das medidas em %0.f ± %0.f Hz.\n', double(avgECW + eCW(1)), 2 * std(eCW(1,:)) );
        end

        function channelPower(obj, chFreqStart, chFreqStop, RBW)
            % Encontra os índices dentro do canal
            idx1 = find( obj.sampleTrace.freq >= chFreqStart, 1 );
            idx2 = find( obj.sampleTrace.freq >= chFreqStop, 1 );
            idx2 = max(idx2);

            if isnan(idx1) || isnan(idx2)
                error('Naive: A largura de banda excede os limites dos dados.')
            end

            % Separa os dados do canal pelo índice
            xData_ch = obj.sampleTrace.freq(idx1:idx2);
            yData_ch = obj.dataTraces(:,idx1:idx2);

            if idx1 ~= idx2
                % Aproximação por trapézio.
                chPower = pow2db((trapz(xData_ch, db2pow(yData_ch')/RBW, 2)))';
            else
                warning("Naive: Banda insuficiente. Cálculo sobre uma única amostra.")
                chPower = yData_ch';
            end

            AvgCP = mean( chPower );
            stdCP = std ( chPower );

            fprintf('Naive: Channel Power %0.2f ± %0.2f dB (ref. unidade de entrada)\n.', AvgCP, stdCP);

            f = figure; ax = axes(f);
            plot(ax, obj.sampleTrace.freq, obj.dataTraces(1,:))
            hold on
            xline( obj.sampleTrace.freq(idx1), 'g', 'LineWidth', 2 );
            xline( obj.sampleTrace.freq(idx2), 'g', 'LineWidth', 2 );
            yline( AvgCP, 'r', 'LineWidth', 2 );
            xlabel(ax, 'Largura do canal (verde)');
            ylabel(ax, 'Potência (vermelho)');
            drawnow
        end

        % function betaPower = betaPercent(obj)
        function estimateBWBetaPercent(obj)
            % Calcula BW em beta %
            % Sensível ao piso de ruído e portadoras complexas (digitais).

            nTraces = height(obj.dataTraces);
            
            for ii = 1:nTraces
                peak = max( obj.dataTraces(ii,:) );
                peakIndex = find( obj.dataTraces(ii,:) == peak );             
                MarginSupIdx = width(obj.dataTraces);

                % Ajusta a janela em torno do centro até a borda mais próxima.
                % Porque a concentração de energia deve estar em torno dela.
                if peakIndex > ( MarginSupIdx / 2 )
                    wIdxSup = MarginSupIdx;
                    wIdxInf = MarginSupIdx - (MarginSupIdx - peakIndex);
                else
                    wIdxSup = 2 * peakIndex; 
                    wIdxInf = 1;   
                end
                betaPower = trapz( wIdxInf:wIdxSup, db2pow(obj.dataTraces(ii, wIdxInf:wIdxSup) ) );
            end

            % Potência de referência do canal
            refChPW = mean(betaPower);
            % rebChPwdStd = std(betaPower);

            % Inicializa as matrizes
            newBetaPower = zeros(nTraces, 2, 'double');
            idxs = zeros(nTraces, 2, 'double');

            for ii = 1:nTraces
                wInf = wIdxInf;
                wSup = wIdxSup;

                % Peneirando com redução progressiva da janela
                for jj = wInf:wSup
                    if mod(jj,2) == 0
                        wInf = wInf + 1;
                    else 
                        wSup = wSup - 1;
                    end

                    if abs( wSup - wInf ) <= 1
                        % warning('Naive: estimateBWBetaPercent: Convergência não encontrada')
                        break
                    end
        
                    newBetaPower(ii) = trapz( wInf:wSup, db2pow(obj.dataTraces(ii, wInf:wSup) ) );
                    
                    betaRef = refChPW * obj.beta / 100; % Ref. para potência beta %

                    if newBetaPower(ii) <= betaRef
                        % Balanceamento da janela
                        % Elege nas proximidades a melhor combinação.

                        minError = newBetaPower(ii) - refChPW;
                        
                        for ib = -5:5
                            if ib <= 1 || ib >= height(obj.dataTraces)
                                continue
                            end

                            for jb = -5:5
                                if jb <= 1 || jb >= height(obj.dataTraces)
                                    continue
                                end

                                nInf = wInf + ib;
                                nSup = wSup + jb;

                                if ~(nSup > nInf)
                                    continue
                                end

                                newBetaPower(ii) = trapz( nInf:nSup, db2pow(obj.dataTraces(ii, nInf:nSup) ) );
                                
                                if minError < (newBetaPower(ii) - refChPW)
                                    minError = newBetaPower(ii) - refChPW;
                                    idxs(ii,:) = [obj.sampleTrace.freq(nInf), obj.sampleTrace.freq(nSup)];
                                end
                            end
                        end
                    end
                end
            end
            
            disp(idxs)
            disp(diff(idxs))
            % n = height(idxs)
            % stdBW = std(bBW)
        end

        function experimentalSmoothPlot(obj)
            smooth = 0.075;

            f = figure; ax = axes(f);

            plot(ax, obj.sampleTrace.freq, obj.dataTraces(1,:))
            hold on

            obj.smoothedTraces = smoothdata(obj.dataTraces, 2, 'movmean', 'SmoothingFactor', smooth);
            
            plot(ax, obj.sampleTrace.freq, obj.smoothedTraces(1,:))

            lx = sprintf('Comparação aplicando suavização de %0.3f.', smooth);
            xlabel(ax, lx);

            drawnow
        end
    end
end

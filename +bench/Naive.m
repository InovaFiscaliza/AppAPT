classdef Naive < handle
    %%  Funções de cálculo "ingênuas" para propósito geral.

    properties
        % O padrão é 26 dB para FM em F3E.
        % Ref. ITU Handbook 2011, pg. 255, TABLE 4.5-1.
        delta           {mustBeInteger} = 26 % Para xdB (ref. FM)
        beta            {mustBeGreaterThan(beta, 0), mustBeLessThan(beta, 100)} = 99 %
        RBW                         % Os dados dependem do RBW
        SmoothingFactor = 0.075;    % Fator de suavizasão dos dados
        ZScoreSamples = 0.2         % (Só para CW) Seleciona os 20% melhores Z-Scores

        % Estruturas
        sampleTrace                 % Estrutura de amostra para ref. índices e freq.
        dataTraces                  % Dados brutos (ref. unidade dos dados de entrada)
        dataPoints                  % pontos por traço
        smoothedTraces              % Dados com suavizasão aplicada.
        shape                       % Medido do pico até o delta xdB
        extShape                    % Medido dos extremos para o pico o delta xdB
    end

    % Métodos Privados
    methods(Access = private)

        function calculateShapeXdB(obj)
            nTraces = height(obj.dataTraces);

            % Pré-aloca as tabelas
            obj.shape    = zeros(nTraces, 2, 'single');
            obj.extShape = zeros(nTraces, 2, 'single');

            for ii = 1:nTraces
                fIntInf = NaN;
                fIntSup = NaN;
                fExtInf = NaN;
                fExtSup = NaN;

                obj.smoothedTraces = smoothdata(obj.dataTraces, 2, 'movmean', 'SmoothingFactor', obj.SmoothingFactor);

                % Escolher dataTraces ou smoothedTraces
                % refData = obj.dataTraces;
                refData = obj.smoothedTraces;

                peakLevel = max( refData(ii,:) );
                peakIndex = find( refData(ii,:) == peakLevel );

                % Por definição o delta é sempre negativo.
                if obj.delta > 0
                    obj.delta = obj.delta * -1;
                end

                % Busca do pico para baixo
                for jj = peakIndex-1:-1:1
                    if refData(ii,jj) <= peakLevel + obj.delta
                        % Interpola a frequência
                        fIntInf = interp1( refData(ii,jj:jj+1), obj.sampleTrace.freq(jj-1:jj), peakLevel + obj.delta);
                        break;
                    end
                end

                % Busca do pico para cima
                for jj = peakIndex+1:width(refData(ii,:))
                    if refData(ii,jj) <= peakLevel + obj.delta
                        % Interpola a frequência
                        fIntSup = interp1( refData(ii,jj-1:jj), obj.sampleTrace.freq(jj-1:jj), peakLevel + obj.delta);
                        break;
                    end
                end

                % Busca do final da faixa para o pico
                for jj = width(refData(ii,:)):-1:peakIndex+1
                    if refData(ii,jj) >= peakLevel + obj.delta
                        % Interpola a frequência
                        if jj == width(refData(ii,:))
                            fExtSup = obj.sampleTrace.freq(jj);
                        else
                            fExtSup = interp1( refData(ii,jj:jj+1), obj.sampleTrace.freq(jj:jj+1), peakLevel + obj.delta);
                        end
                        break;
                    end
                end

                % Busca do início da faixa para o pico
                for jj = 1:peakIndex-1
                    if refData(ii,jj) >= peakLevel + obj.delta
                        % Interpola a frequência
                        if jj == 1
                            fExtInf = obj.sampleTrace.freq(jj);
                        else
                            fExtInf = interp1( refData(ii,jj-1:jj), obj.sampleTrace.freq(jj-1:jj), peakLevel + obj.delta);
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

    % Métodos Públicos
    methods

        function obj = Naive()
            % Construtor necessário para instanciar.
        end

        % Funções para calcular índices e frequências.
        function idx = freq2idx(obj, freq)
            % aCoef e bCoef
            % freq = aCoef + idx + bCoef;
            % FreqStart = aCoef + bCoef;
            % FreqStop  = aCoef * obj.dataPoints + bCoef;

            % aCoef = FreqSpan / (obj.dataPoints-1);
            % bCoef = FreqStart - aCoef;

            % idx = round((freq - bCoef)/aCoef);

            % if (idx < 1) || (idx > obj.dataPoints)
            %     idx = NaN;
            % end

            obj.dataPoints = numel(obj.sampleTrace.freq);

            % profile on

            % Custo médio em 5 amostras de 0,059s
            idx = find( obj.sampleTrace.freq >= freq, 1 );

            % profile off
            % profile viewer

            if isempty(idx)
                idx = NaN;
            end

            if idx > height(obj.sampleTrace)
                idx = NaN;
            end
        end

        function freq = idx2freq(obj, idx)
            freq = double( obj.sampleTrace.freq(idx) );

            if isempty(freq)
                freq = NaN;
            end
        end

        % Faz chamadas de traço e acumula para entregar os dados
        function getTracesFromUnit(obj, instrumentObj, nTraces)
            
            idx1 = find(strcmp(instrumentObj.App.receiverObj.Config.Tag, instrumentObj.conn.UserData.instrSelected.Tag), 1);
            DataPoints_Limits = instrumentObj.App.receiverObj.Config.DataPoints_Limits{idx1};

            % TODO: Verificar casos de pontos variáveis
            if diff(round(DataPoints_Limits))
                % Datapoints = instrumentObj.getDataPoints;
                error('O instrumento deve ter um número fixo de pontos! A evoluir...')
            end

            obj.dataPoints = DataPoints_Limits(1);

            instrumentObj.startUp();

            % A série depende do RBW usado na coleta.
            % Questiona o instrumento sobre o valor efetivamente usado:
            obj.RBW = str2double( instrumentObj.getRes );

            % Traço de amostra, basicamente para indices de frequências
            obj.sampleTrace = instrumentObj.getTrace(1);

            % Objeto que conterá o volume de dados
            obj.dataTraces  = zeros(nTraces, obj.dataPoints, 'single');

            ii = 1;
            while ii <= nTraces
                try
                    obj.dataTraces(ii,:) = instrumentObj.getTrace(1).value;
                    ii = ii + 1;
                catch
                end
            end
            
            obj.calculateShapeXdB();
        end

        % Calcula BW por xdB
        function [BW, stdBW, eBW, estdBW] = calculateBWxdB(obj)

            % Chamada para o caso de não haver coleta do intrumento (idx = 0)
            obj.calculateShapeXdB();

            BW = diff(obj.shape');
            stdBW = std(BW);
            eBW = diff(obj.extShape');
            estdBW = std(eBW);
        end

        % Estima frequência central por Z-Score
        function [CW, stdCW] = estimateCW(obj)

            % Chamada para o caso de não haver coleta do intrumento (idx = 0)
            obj.calculateShapeXdB();

            % Freq. média dos valores
            eCW = mean(obj.shape, 2);

            % Média e desvio do total
            avgECW = mean( eCW );
            stdECW = std ( eCW ) + 0.0001; % Evita desvio zero no simulador.

            % Calcula a distância de cada valor para a média e ordena
            zscore = [ abs( ( eCW - avgECW ) / stdECW ), (1:numel(eCW))' ];
            [~,zIdx] = sort(zscore(:,1));
            eCW = zscore(zIdx,:);

            % Seleciona por menor Z-Score (obj.ZScoreSamples)
            eCW = eCW( 1:round(height(eCW) * obj.ZScoreSamples), : );

            CW = double(avgECW + eCW(1));
            stdCW = std(eCW(1,:));
        end

        % Calcula Potência do Canal
        function chPower = channelPower(obj, nSweep, idx1, idx2)

            if isnan(idx1) || isnan(idx2)
                error('Naive channelPower: A largura de banda excede os limites dos dados.')
            end            

            % Separa os dados do canal pelo índice
            xData_ch = obj.sampleTrace.freq(idx1:idx2);

            if isempty(nSweep)
                yData_ch = obj.smoothedTraces(:,idx1:idx2)';                 % A saída será um vetor
            else
                yData_ch = obj.smoothedTraces(nSweep,idx1:idx2)';            % A saída será um número
            end

            if idx1 <= idx2
                % Aproximação por trapézio.
                chPower = trapz(xData_ch, db2pow(yData_ch)/obj.RBW, 1);
            else
                warning("Naive channelPower: Banda insuficiente. Cálculo sobre uma única amostra.")
                chPower = yData_ch';
            end
        end

        % Estima BW por beta %
        function [bBw, stdbBW] = estimateBWBetaPercent(obj, adaptative)
            % Calcula BW por beta %
            % Sensível ao piso de ruído e portadoras complexas (digitais).

            if nargin < 2 || isempty(adaptative)
                adaptative = 1;
            end

            % Recalculando smoothdata do objeto
            obj.smoothedTraces = smoothdata(obj.dataTraces, 2, 'movmean', 'SmoothingFactor', obj.SmoothingFactor);

            nTraces = height(obj.smoothedTraces);
            LocalbBw = zeros(nTraces, 1, 'single');
            obj.dataPoints = numel(obj.sampleTrace.freq);

            % Vetor em escala linear, uma potência por varredura
            chRefPower = (obj.beta/100) * channelPower(obj, [], 1, obj.dataPoints);            

            for ii = 1:nTraces

                wIInf = 1;
                wISup = obj.dataPoints;

                while(wISup > wIInf)

                    % PROFILE:
                    % Média de 5 medidas:
                    % Adaptativo    = 3,354s
                    % Simétrico     = 1,817s
                    % 85% de ganho em velocidade.
                    % A precisão parece ter melhorado em 20kHz no simétrico.

                    if adaptative == 1
                        % Janelamento adaptativo. Remove os menores valores de cada lado.
                        if obj.smoothedTraces(ii, wISup) <= obj.smoothedTraces(ii, wIInf)
                            wISup = wISup - 1;
                        else
                            wIInf = wIInf + 1;
                        end
                    else
                        Janelamento simétrico
                        wIInf = wIInf + 1;
                        wISup = wISup - 1;
                    end

                    if channelPower(obj, ii, wIInf, wISup) <= chRefPower(ii)
                        LocalbBw(ii) = obj.idx2freq(wISup) - obj.idx2freq(wIInf);
                        break
                    end
                end
            end

            bBw = mean(LocalbBw);
            stdbBW = std(LocalbBw);
        end    

        % Experimento de plotagem para Smoothed
        function experimentalSmoothPlot(obj)
            f = figure; ax = axes(f);

            plot(ax, obj.sampleTrace.freq, obj.dataTraces(1,:))
            hold on

            obj.smoothedTraces = smoothdata(obj.dataTraces, 2, 'movmean', 'SmoothingFactor', obj.SmoothingFactor );
            
            plot(ax, obj.sampleTrace.freq, obj.smoothedTraces(1,:))

            lx = sprintf('Comparação aplicando suavização de %0.3f.', obj.SmoothingFactor);
            xlabel(ax, lx);

            drawnow
        end
    end
end

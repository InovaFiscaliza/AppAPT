classdef Naive < handle
    %%  Funções de cálculo "ingênuas" para propósito geral.

    properties
        % O padrão é 26 dB para FM em F3E.
        % Ref. ITU Handbook 2011, pg. 255, TABLE 4.5-1.
        delta           {mustBeInteger} = 26 % Para xdB (ref. FM)

        beta            {mustBeGreaterThan(beta, 0), mustBeLessThan(beta, 100)} = 99
        sampleTrace
        dataTraces
        smoothedTraces
        shape                       % Medido do pico até o delta
        extShape                    % Medido dos extremos para o pico

        % Parâmetros 'fixos'
        RBW                         % Os dados dependem dele
        SmoothingFactor = 0.075;
        ZScoreSamples = 0.2         % (apenas na CW). Os 20% melhores Z-Score
    end

    methods(Access = private)

        % O sampleTrace é uma amostra para relacionar índices e
        % frequências. Estas duas funções deixarão o código mais claro e
        % adicionam a possibilidade de testar os limites antes.
        function idx = freq2idx(obj, freq)
            idx = find( obj.sampleTrace.freq >= freq, 1 );

            if isempty(idx)
                idx = NaN;
            end

            if idx > height(obj.sampleTrace)
                error('Naive freq2idx:O índice excede os limites.')
            end
        end
        function freq = idx2freq(obj, idx)
            % TODO: Arredondar a frequência para o mais próximo
            % TODO: Ajustar para trabalhar com ranges e remover todas as
            %       chamadas a obj.sampleTrace.freq daqui para baixo.
            freq = double( obj.sampleTrace.freq(idx) );

            if isempty(freq)
                freq = NaN;
            end
        end

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

                % Escolher dataTraces ou smoothedTraces
                % refData = obj.smoothedTraces;
                refData = obj.dataTraces;

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

    methods

        function obj = Naive()
            % Construtor vazio ainda, necessário só para instanciar.
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

            % A série depende do RBW usado na coleta.
            % Questiona o instrumento sobre o valor efetivamente usado:
            obj.RBW = str2double( instrumentObj.getRes );

            % Traço de amostra, basicamente para indices de frequências
            obj.sampleTrace = instrumentObj.getTrace(1);

            % Objeto que conterá o volume de dados
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
            
            obj.calculateShapeXdB();
        end

        function [BW, stdBW] = calculateBWxdB(obj)
            % TODO: Remover chamada interna
            % Serve apenas para o caso de não haver coleta do intrumento (idx = 0)
            obj.calculateShapeXdB();

            BW = diff(obj.shape');
            stdBW = std(BW);
        end

        function [CW, stdCW] = estimateCW(obj)
            % TODO: Remover chamada interna
            % Serve apenas para o caso de não haver coleta do intrumento (idx = 0)
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

            % Seleciona as 20% com menor Z-Score
            eCW = eCW( 1:round(height(eCW) * obj.ZScoreSamples), : );

            CW = double(avgECW + eCW(1));
            stdCW = std(eCW(1,:));
        end

        function [AvgCP, stdCP] = channelPower(obj, chFreqStart, chFreqStop)
            % Encontra os índices dentro do canal
            idx1 = obj.freq2idx(chFreqStart);
            idx2 = obj.freq2idx(chFreqStop);

            if isnan(idx1) || isnan(idx2)
                error('Naive channelPower: A largura de banda excede os limites dos dados.')
            end

            % Separa os dados do canal pelo índice
            xData_ch = obj.sampleTrace.freq(idx1:idx2);
            yData_ch = obj.dataTraces(:,idx1:idx2);

            if idx1 ~= idx2
                % Aproximação por trapézio.
                % WARN: Alto custo computacional:
                chPower = pow2db( (trapz(xData_ch, db2pow(yData_ch') / 2 / obj.RBW)) );
                % TODO: A divisão por dois acima foi para aproximação com
                %       a leitura do instrumento.
                %       Ainda a entender porque mede dobrado.

                % Na fórmula tem:
                % % Somatório que é o trapz
                % % ( 10 .^ FFTBindBm / 10 ) que é igual a db2pow

            else
                warning("Naive channelPower: Banda insuficiente. Cálculo sobre uma única amostra.")
                chPower = yData_ch';
            end

            AvgCP = mean( chPower );

            % TODO: Incerteza dobrada até o entendido do comentário anterior.
            stdCP = 2 * std ( chPower );
        end

        function [bBw, stdbBW] = estimateBWBetaPercent(obj)
            % Calcula BW por beta %
            % Sensível ao piso de ruído e portadoras complexas (digitais).

            % Recalculando smoothdata pra identificar o peakIndex
            obj.smoothedTraces = smoothdata(obj.dataTraces, 2, 'movmean', 'SmoothingFactor', obj.SmoothingFactor);


            nTraces = height(obj.smoothedTraces);
            LocalbBw = zeros(nTraces, 1, 'single');

            for ii = 1:nTraces
                peak = max( obj.smoothedTraces(ii,:) );
                peakIndex = find( obj.smoothedTraces(ii,:) == peak );
                peakFreq = obj.sampleTrace.freq(peakIndex);

                % Frequência máxima possível da amostra sampletrace.
                MarginSupFreq = max( obj.sampleTrace.freq );

                % Ajusta a janela em torno do centro até a borda mais próxima.
                % Porque a concentração de energia deve estar em torno dela.
                if peakFreq >= ( MarginSupFreq / 2 )
                    wFreqSup = MarginSupFreq;
                    wFreqInf = 2 * peakFreq - MarginSupFreq;
                else
                    wFreqSup = 2 * peakFreq - obj.RBW; 
                    % Frequência mínima possível da amostra sampletrace.
                    wFreqInf = obj.sampleTrace(1);   
                end

                % Potência de referência alvo
                chRefPower = mean( obj.beta / 100 * db2pow( obj.channelPower(wFreqInf, wFreqSup) ) );

                wFInf = wFreqInf;
                wFSup = wFreqSup;

                while(wFSup > wFInf)
                    % % Peneira removendo os menores valores de cada lado pelo índice
                    % if obj.dataTraces( obj.freq2idx(wFSup) ) >= obj.dataTraces( obj.freq2idx(wFInf) )
                    %     wFSup = obj.idx2freq( obj.freq2idx(wFSup) - 1 );
                    % else
                    %     wFInf = obj.idx2freq( obj.freq2idx(wFInf) + 1 );
                    % end

                    % Alternativa: Puxa os dois lados da janela ao mesmo
                    % tempo. Sem melhora de desempenho.
                    wFSup = obj.idx2freq( obj.freq2idx(wFSup) - 1 );
                    wFInf = obj.idx2freq( obj.freq2idx(wFInf) + 1 );

                    if db2pow( obj.channelPower(wFInf, wFSup) ) <= chRefPower
                        LocalbBw(ii) = wFSup - wFInf;
                        break
                    end
                end
            end

            bBw = mean(LocalbBw);
            stdbBW = std(LocalbBw);
        end    

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

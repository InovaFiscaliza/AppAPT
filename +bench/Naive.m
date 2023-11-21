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

        % Parâmetros 'fixos'
        SmoothingFactor = 0.075;
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
            % Vazio ainda
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

        function [BW, stdBW] = calculateBWxdB(obj)
            % TODO: Remover chamada interna
            % Serve apenas para o caso de não haver coleta do intrumento (idx = 0)

            obj.calculateShape();
            BW = diff(obj.shape');
            stdBW = std(BW);
        end

        function [CW, stdCW] = estimateCW(obj)
            % TODO: Remover chamada interna
            % Serve apenas para o caso de não haver coleta do intrumento (idx = 0)
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

            CW = double(avgECW + eCW(1));
            stdCW = std(eCW(1,:));
        end

        function [AvgCP, stdCP] = channelPower(obj, chFreqStart, chFreqStop, RBW)
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
                chPower = pow2db((trapz(xData_ch, db2pow(yData_ch')/RBW)))';
            else
                warning("Naive: Banda insuficiente. Cálculo sobre uma única amostra.")
                chPower = yData_ch';
            end

            AvgCP = mean( chPower );
            stdCP = std ( chPower );
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

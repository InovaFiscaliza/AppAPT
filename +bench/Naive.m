classdef Naive < handle
    %%  Funções de cálculo "ingênuas" para propósito geral.
    %%  Não devem ser herdadas ou sobreescritas 

    properties
        delta = -26     % sempre negativo para xdB.
        sampleTrace
        dataTraces
        smoothedTraces
        shape           % Medido do pico até o delta
        extShape        % Igual mas medido de fora para dentro
    end

    methods(Access = private)

        function calculateShape(obj)
            nTraces = height(obj.dataTraces);

            % Pré-aloca as tabelas
            obj.shape    = zeros(nTraces, 2, 'single');
            obj.extShape = zeros(nTraces, 2, 'single');

            % Escolher dataTraces ou smoothedTraces
            refData = obj.smoothedTraces;

            for ii = 1:nTraces
                fIntInf = NaN;
                fIntSup = NaN;
                fExtInf = NaN;
                fExtSup = NaN;

                peak = max( refData(ii,:) );
                peakIndex = find( refData(ii,:) == peak );

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

        function calculateBW(obj)
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

        function experimentalPlot(obj)
            f = figure; ax = axes(f);

            plot(ax, obj.sampleTrace.freq, obj.dataTraces(1,:))
            hold on

            obj.smoothedTraces = smoothdata(obj.dataTraces, 2, 'movmean', 'SmoothingFactor', .075);
            
            plot(ax, obj.sampleTrace.freq, obj.smoothedTraces(1,:))
            drawnow
        end
    end
end

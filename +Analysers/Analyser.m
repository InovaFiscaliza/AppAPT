classdef Analyser < dynamicprops
    % Classe para modelagem de Analisadores de Espectro.
    % Comandos mandatórios do SCPI e comuns entre eles.

    properties
        prop
        conn
    end

    %
    % Métodos estáticos de conexão e criação de objetos
    %

    methods(Static)

        % Conexão TCP a ser sobrecarregada para outros tipos
        function out = connTCP(ip, port)
            % TODO: Caso seja fornecido só o IP, faz a busca pelas portas
            if nargin < 2
                % knowPorts = [5025, 5555, 9001, 34385];
                error('Analyser: Autodiscovery não implementado')
            end

            try
                anl = tcpclient(ip, port, 'Timeout', Analysers.CONSTANTS.CONNTIMEOUT);
            catch exception  
                error('Analyser.connTCP: A unidade não respondeu ao chamado de identificação: %s', exception.identifier)
            end

            %
            % Comandos comuns na IEEE 488.2 começam com asterisco.
            %
            try
                res = anl.writeread('*IDN?');
            catch exception
                error('A unidade conecta mas não respode. A porta pode estar ocupada por outra instância: %s', exception.identifier)
            end

            clear anl;

            % Elimina caracteres especiais do nome
            % (ex. R&S e AT&T vão para R_S e AT_T, e FSL-6 para FSL_6)
            res = strrep(res,'&','_');
            res = strrep(res,'-','_');

            data = strsplit(res, ',');
            data = [data, ip, double(port)];
            keys = ["Factory", "model", "serial", "version", "ip", "port"];
            out = dictionary(keys, data);
        end

        % Teste para conexões alternativas 
        function connGPIB( ~, ~ )
            error('Analyser: Conexão GPIB não implementada.')
        end


        %
        % Fábrica de instâncias
        %

        function obj = instance(args)      
            % Verifica se o modelo bate com o fabricante
            % para evitar colisão de nomes
            if exist('Analysers.' + args("model"), 'class') && exist('Analysers.' + args("Factory"), 'class')
                disp( strcat('Analyer: Base de comando(', args("Factory"), '), modelo (', args("model"), ').')) ;
                constructor = str2func('Analysers.' + args("model"));
                obj = constructor(args('model'), args);
            elseif exist('Analysers.' + args("Factory"), 'class')
                disp(['Analyer: Base de comando do fabricante', args("Factory")])
                constructor = str2func(args("Factory"));
                obj = constructor('Analysers.' + args('Factory'), args);
            else
                error('Analyer: Base de comando não implementada.');
            end
        end
    end


    %
    % Métodos de operação
    %

    % Os abstratos precisam ser implementados ao menos na classe do fabricante.
    % As implementações genéricas estão comentados com %*, 
    % A sobreescrever se necessário.
    methods(Abstract)
        startUp(obj)

        getParms(obj)
        %* getSpan(obj)
        %* getRes(obj)

        %* setFreq(obj, freq, stop)
        %* setSpan(obj, span)
        %* setRes(obj, res)
        %* setAtt(obj, att)
        preAmp(obj, state)

        %setRFMode(obj, mode) % TODO

        %%getMarker(obj, freq, trace)
        %%getTrace(obj, n)
    end


    %
    % Métodos utilitários
    % Para serem sobrecarregados nas exceções
    % Em especial outros tipos de conexões
    %

    methods
        function scpiReset(obj)
            try
                anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
                anl.writeline('*RST'); % Preset
                anl.writeline("*CLS"); % Limpa lista de erros do log
                clear anl;
            catch
                error('Analyer.scpiReset: O instrumento não respondeu ao comando de RESET.')
            end
        end

        % Erros negativos são padrão SCPI. Os positivos são específicos
        function res = sendCMD(obj, cmd)
            if isempty(obj.conn)
                disp('Analyer.sendCMD: Criando nova conexão TCP.')
                obj.conn = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            end

            obj.conn.writeline(cmd);
            res = writeread(obj.conn, ":SYSTEM:ERROR?");

            if ~contains(res, "No error", "IgnoreCase", true)
                warning("Analyer.sendCMD: " + res)
            end
        end

        function res = getCMD(obj, cmd)
            if isempty(obj.conn)
                disp('Analyer.getCMD: Criando nova conexão.')
                obj.conn = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            end
            res = obj.conn.writeread(cmd);
        end

        function ping(obj)
            if ~isprop(obj, 'conn')
                disp('Analyser.ping: Mesma conexão')
            else
                disp('Analyser.ping: Criando conexão')
                obj.conn = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            end

            p = obj.conn.writeread('*IDN?');

            if isempty(p)
                obj.disconnect();
                error('Analyser.ping: Dispositivo indisponível')
            else
                disp('Analyser.ping: Resposta IDN recebida:')
                disp(p)
            end
        end

        % Encerra ativamente a conexão
        function disconnect(obj)
            if ~isempty(obj.conn)
                obj.conn.flush();
            end
            obj.conn = [];
        end

        %
        % Implementações genéricas
        %

        % Se passado o terceiro argumento faz start/stop, senão CF
        function setFreq(obj, freq, stop)
            if nargin < 3
                obj.sendCMD( sprintf(":FREQuency:CENTer %f", freq) );
            else
                obj.sendCMD( sprintf(":FREQuency:STARt %f;:FREQuency:STOP %f", freq, stop) );
            end
        end

        function res = getRes(obj)
            res = obj.getCMD(':BANDwidth:RESolution?');
        end

        function res = getSpan(obj)
            res = obj.getCMD(':FREQuency:SPAN?');
        end

        function setRes(obj, res)
            if ischar(res) && contains( num2str(res),'auto','IgnoreCase', true )
                obj.sendCMD(":BANDwidth:RESolution:AUTO ON");
            else
                obj.sendCMD( sprintf(":BANDwidth:RESolution %f", res) );
            end
        end

        function setAtt(obj, att)
            obj.sendCMD( sprintf(":POWer:RF:ATTenuation %f", att) );
        end

        function setSpan(obj, span)
            obj.sendCMD( sprintf(":FREQuency:SPAN %f", span) );
        end
    end
end


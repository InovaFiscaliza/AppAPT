classdef Analyser < dynamicprops
    % Classe para modelagem de Analisadores de Espectro.
    % Comandos mandatórios do SCPI e comuns entre eles.

    properties
        prop
    end

    properties (Constant)
        % Para teste de conexão, usar esse timeout.
        CONNTIMEOUT = 2;
    end
    %
    % Métodos estáticos de conexão e criação de objetos
    %

    methods(Static)

        % Conexão TCP
        function out = connTCP(ip, port)
            % Caso seja fornecido só o IP, faz a busca pelas portas
            if nargin < 2
                % knowPorts = [5025, 5555, 9001, 34385];
                error('Autodiscovery não implementado')
            end

            try
                anl = tcpclient(ip, port, 'Timeout', Analyser.CONNTIMEOUT);
                res = anl.writeread('*IDN?');
                clear anl;
            catch exception
                error(exception.message)
                error('A unidade não respondeu ao chamado de identificação.')
            end

            % Elimina caracteres reservados para chamada de classe
            % (ex. R&S ou AT&T vão para R_S e AT_T)
            res = strrep(res,'&','_');

            % out -> Retorna as propriedades do ojeto em um dicionário.
            data = strsplit(res, ',');
            data = [data, ip, double(port)];
            keys = ["Factory", "model", "serial", "version", "ip", "port"];
            out = dictionary(keys, data);
        end

        % Teste para conexões alternativas 
        function connGPIB( ~, ~ )
            error('Conexão GPIB não implementada.')
        end


        %
        % Fábrica de instâncias
        %

        % Verifica se há implementação
        function obj = instance(args)
                
            % Verifica se o modelo bate com o fabricante
            % para evitar colisão de nomes
            if exist(args("model"), 'class') && exist(args("Factory"), 'class')
                disp( strcat('Base de comando(', args("Factory"), '), modelo (', args("model"), ').')) ;
                constructor = str2func(args("model"));
                obj = constructor(args('model'), args);
            elseif exist(args("Factory"), 'class')
                disp(['Base de comando do fabricante', args("Factory")])
                constructor = str2func(args("Factory"));
                obj = constructor(args('Factory'), args);
            else
                error('Base de comando não implementada.');
            end
        end
    end


    %
    % Métodos abstratos
    % Por enquanto, só um exercício para aplicações
    % Para garantir a implementação
    %

    methods(Abstract)
        startUp(obj)

        getParms(obj)
        getSpan(obj)

        %setFreq(obj, freq, stop) % Concreto
        setSpan(obj, span)
        setRes(obj, res)
    end


    %
    % Métodos de teste
    % Para serem sobrecarregados nas exceções
    %

    methods
        function scpiReset(obj)
            try
                anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
                anl.writeline('*RST'); % Preset
                anl.writeline("*CLS"); % Limpa lista de erros do log
                clear anl;
            catch
                error('O instrumento não respondeu ao comando de RESET.')
            end
        end

        function res = sendCMD(obj, cmd)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            anl.writeline(cmd);
            res = writeread(anl, "SYSTEM:ERROR?");

            if ~contains(res, "No error", "IgnoreCase", true)
                warning("Analyser sendCMD: " + res)
            end

            anl.flush()
            clear anl;
        end

        function ping(obj)
            anl = tcpclient(obj.prop('ip'), double(obj.prop('port')), 'Timeout', obj.CONNTIMEOUT);
            p = anl.writeread('*IDN?');
            clear anl;

            if isempty(p)
                error('Dispositivo indisponível')
            else
                disp('Resposta IDN recebida Ok.')
            end
        end

    %
    % Métodos de operação
    % Para serem sobrecarregados nas exceções
    %

        % Se passado o terceiro argumento faz start/stop, senão CF.
        function setFreq(obj, freq, stop)
            if nargin < 3
                obj.sendCMD( sprintf("FREQuency:CENTer %f", freq) );
            else
                obj.sendCMD( sprintf("FREQuency:START %f; :SPECtrum:FREQuency:STOP %f", freq, stop) );
            end
        end

    end
end


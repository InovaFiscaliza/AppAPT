classdef Analyser < dynamicprops
    % Classe para modelagem de Analisadores de Espectro.
    % Comandos mandatórios do SCPI e comuns entre eles.

    properties
        prop
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
                error('Autodiscovery não implementado')
            end

            try
                anl = tcpclient(ip, port, 'Timeout', Analysers.CONSTANTS.CONNTIMEOUT);
                % Comandos comuns na IEEE 488.2 começam com asterisco.
                res = anl.writeread('*IDN?');
                clear anl;
            catch exception
                error(getReport(exception))
                error('A unidade não respondeu ao chamado de identificação.')
            end

            % Elimina caracteres reservados para chamada de classe
            % (ex. R&S ou AT&T vão para R_S e AT_T)
            res = strrep(res,'&','_');

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

        function obj = instance(args)      
            % Verifica se o modelo bate com o fabricante
            % para evitar colisão de nomes

            if exist('Analysers.' + args("model"), 'class') && exist('Analysers.' + args("Factory"), 'class')
                disp( strcat('Base de comando(', args("Factory"), '), modelo (', args("model"), ').')) ;
                constructor = str2func('Analysers.' + args("model"));
                obj = constructor(args('model'), args);
            elseif exist('Analysers.' + args("Factory"), 'class')
                disp(['Base de comando do fabricante', args("Factory")])
                constructor = str2func(args("Factory"));
                obj = constructor('Analysers.' + args('Factory'), args);
            else
                error('Base de comando não implementada.');
            end
        end
    end


    %
    % Métodos abstratos
    %

    % Ao menos o fabricante precisa implementar todos estes.
    methods(Abstract)
        startUp(obj)

        getParms(obj)
        getSpan(obj)
        getTrace(obj, n)
        getMarker(obj, freq, trace)

        setFreq(obj, freq, stop)
        setSpan(obj, span)
        setRes(obj, res)

        %setRFMode(obj, mode) % TODO
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
                error('O instrumento não respondeu ao comando de RESET.')
            end
        end

        % Erros negativos são padrão SCPI. Os positivos são específicos
        function res = sendCMD(obj, cmd)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            anl.writeline(cmd);
            res = writeread(anl, "SYSTEM:ERROR?");

            % TODO: Verificar saída do retorno
            if ~contains(res, "No error", "IgnoreCase", true)
                warning("Analyser sendCMD: " + res)
            end

            % TODO: Colocar a conexão em prop e reutilizar
            anl.flush()
            clear anl;
        end

        function res = getCMDRes(obj, cmd)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            res = anl.writeread(cmd);
            anl.flush()
            clear anl;
        end

        function ping(obj)
            anl = tcpclient(obj.prop('ip'), double(obj.prop('port')), 'Timeout', Analysers.CONSTANTS.CONNTIMEOUT);
            p = anl.writeread('*IDN?');
            clear anl;

            if isempty(p)
                error('Dispositivo indisponível')
            else
                disp('Resposta IDN recebida:')
                disp(p)
            end
        end
    end
end


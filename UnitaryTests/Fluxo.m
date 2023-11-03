
% Reutiliza o app se ativo
if ~exist('app', 'var')
    app = winAppColetaV2;
elseif ~isvalid(app)
    app = winAppColetaV2;
end

% idx = 0: Carrega do workspace já executado
% idx = 1: instrumento virtual
% idx = 2: instrumento real

idx = 2;

if idx == 0
    load('C:\P&D\AppAPT\+Analysers\TestBook\TestTektronixSA2500.mat', 'trcs', 'trace');
else
    tekObj = apt.Analysers.TEKTRONIX(app, idx);

    % Timeout para evitar:
    % Warning: The specified amount of data was not returned within the Timeout period for 'readbinblock'.
    % 'tcpclient' unable to read any data. For more information on possible reasons, see tcpclient Read Warnings. 
    tekObj.conn.Timeout = 20;

    dataTraces = apt.utils.getTracesFromUnit(tekObj, 10);

    % Ajusta o instrumento pela API
    tekObj.setFreq(100300000);
    tekObj.setSpan(500000);
end

apt.fcn.naive.calculateBW(dataTraces)

apt.fcn.naive.estimateCW(dataTraces)
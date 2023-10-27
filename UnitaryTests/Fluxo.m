
% if ~exist('app', 'var') && ~isvalid(app)
%     app = winAppColetaV2;
% end

app = winAppColetaV2;

% idx = 0: Carrega do workspace já executado
% idx = 1: instrumento virtual
% idx = 2: instrumento real

idx = 1;

tekObj = apt.Analysers.TEKTRONIX(app, idx);

tekObj.setFreq(100300000);
tekObj.setSpan(500000);

if idx ==  0
    load('C:\P&D\AppAPT\+Analysers\TestBook\TestTektronixSA2500.mat', 'trcs', 'trace');
else
    dataTraces = apt.utils.getTracesFromUnit(tekObj, 10);
end

% Warning: The specified amount of data was not returned within the Timeout period for 'readbinblock'.
% 'tcpclient' unable to read any data. For more information on possible reasons, see tcpclient Read Warnings. 
%
% Independente de reset manual no instrumento.

apt.fcn.naive.calculateBW()

apt.fcn.naive.estimateCW()
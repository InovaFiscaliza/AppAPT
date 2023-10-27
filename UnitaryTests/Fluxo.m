
if isempty(app)
    app = winAppColetaV2;
end

% idx = 0: Carrega do workspace já executado
% idx = 1: instrumento virtual
% idx = 2: instrumento real

tekObj = apt.Analysers.TEKTRONIX(app, idx);

tekObj.setFreq(100300000);
tekObj.setSpan(500000);

if idx ==  0
    load('C:\P&D\AppAPT\+Analysers\TestBook\TestTektronixSA2500.mat', 'trcs', 'trace');
else
    dataTraces = apt.utils.getTracesFromUnit(tekObj, 10);
end

apt.fcn.naive.calculateBW()

apt.fcn.naive.estimateCW()
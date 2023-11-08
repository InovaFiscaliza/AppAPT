
% idx = 1: instrumento virtual
% idx = 2: instrumento real
% idx = 3: Load workspace

idx = 3;

if idx < 3

    % Reutiliza o app se ativo
    if ~exist('app', 'var')
        app = winAppColetaV2;
    elseif ~isvalid(app)
        app = winAppColetaV2;
    end

    Instr = apt.Analysers.TEKTRONIX(app, idx);
    
    % Timeout para evitar:
    % Warning: The specified amount of data was not returned within the Timeout period for 'readbinblock'.
    % 'tcpclient' unable to read any data. For more information on possible reasons, see tcpclient Read Warnings. 
    Instr.conn.Timeout = 20;
    
    % Ajusta o instrumento pela API
    Instr.setFreq(100300000);
    Instr.setSpan(500000);
    
    tekbench = apt.bench.Naive();
    tekbench = tekbench.getTracesFromUnit(Instr, 10);

    save('+apt/+bench/TestBook/Fluxo.mat', 'tekbench')
else
    load('+apt/+bench/TestBook/Fluxo.mat')
end

tekbench.calculateBW()
tekbench.estimateCW()
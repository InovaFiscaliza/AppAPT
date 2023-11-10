% idx = 0: Load workspace
% idx = 1: instrumento virtual
% idx = 2: instrumento real

idx = 0;

if idx ~= 0

    % Reutiliza o app se ativo
    appFigure = findall(groot,'Type','Figure','Name', 'appColetaV2 R2023a');
    if ~isempty(appFigure) && isvalid(appFigure)
        app = appFigure.RunningAppInstance;
    else
        app = winAppColetaV2;
    end

    Instr = apt.Analysers.TEKTRONIX(app, idx);
    
    % Timeout para evitar:
    % Warning: The specified amount of data was not returned within the Timeout period for 'readbinblock'.
    % 'tcpclient' unable to read any data. For more information on possible reasons, see tcpclient Read Warnings. 
    Instr.conn.Timeout = 5;
    
    % Ajusta o instrumento pela API
    if idx == 2
        Instr.setFreq(100300000); % Real
        Instr.setSpan(500000);
    else 
        Instr.setFreq(10000000);  % Virtual
        Instr.setSpan(10000);      
    end
    
    tekbench = apt.bench.Naive();
    tekbench.getTracesFromUnit(Instr, 10);

    save('+apt/+bench/TestBook/Fluxo.mat', 'tekbench')
else
    load('+apt/+bench/TestBook/Fluxo.mat')
end

tekbench.delta = -22;

tekbench.calculateBW
tekbench.estimateCW

tekbench.experimentalPlot
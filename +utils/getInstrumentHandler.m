function [instrHandle, msgError] = getInstrumentHandler(app, idx1)
    arguments
        app  winAppColetaV2
        idx1 double = 1 % instrumentListIndex
    end

    % O argumento de entrada idx1 é a linha do registro de instrumento
    % obtida em app.receiverObj.List.
    % Lembrar de abrir o app diretamente do prompt do Matlab, usando:
    % >> app = winAppColetaV2;

    instrumentName = app.receiverObj.List.Name{idx1};
    instrumentType = app.receiverObj.List.Type{idx1};

    idx2 = find(strcmp(app.receiverObj.Config.Name, instrumentName), 1);

    instrSelected = struct('Type',       instrumentType,                   ...
        'Tag',        app.receiverObj.Config.Tag{idx2}, ...
        'Parameters', jsondecode(app.receiverObj.List.Parameters{idx1}));

    [instrHandle, msgError] = fcn.ConnectivityTest_Receiver(app, instrSelected, 0);
end
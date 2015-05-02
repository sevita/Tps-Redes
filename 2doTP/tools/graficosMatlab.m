%%%% Para invocar una funcion, hay que usar:
%%%%   graficos = graficosMatlab
%%%%   graficos.nombre_de_la_funcion(arg1,arg2,...,argN);

function funcion = graficosMatlab
    funcion.comparacionDeMetricas  = @comparacionDeMetricas;
    funcion.rttsVSzrtts  = @rttsVSzrtts;
end

function comparacionDeMetricas(inputFile, title_red)
    if nargin < 2,
        disp('ERROR: comparacionDeMetricas(inputFile :string, title_red :string)')
        return
    end
    
    
    fileID = fopen(inputFile);
    A = textscan(fileID,'%d %s %f64 %f64 %f64 %f64 %f64 %f64');
    fclose(fileID);
    %celldisp(A)
    
    ejeX = A{1};
    labels = A{2};
    media = A{3}.*1000;
    m10 = A{4}.*1000;
    m20 = A{5}.*1000;
    m30 = A{6}.*1000;
    m40 = A{7}.*1000;
    mediana = A{8}.*1000;
    cantDatos = length(ejeX);
    
    hold off;
    plot(ejeX,media,ejeX,m10,ejeX,m20,ejeX,m30,ejeX,m40,ejeX,mediana, 'LineWidth', 1);
    
    grid;
    title(['Comparacion de Metricas en Caso de Estudio ' title_red], 'FontSize', 16);
    ylabel('RTT Acumulado Promedio (ms)', 'FontSize', 11);
    xlabel('HOP', 'FontSize', 11);
    set(gca, 'XTick', 1:1:length(ejeX));
    legend('Media', 'Media 10-podada', 'Media 20-podada', 'Media 30-podada', 'Media 40-podada', 'Mediana', 'Location','SouthEast');
end

function rttsVSzrtts(inputFile, title_red)
    if nargin < 2,
        disp('ERROR: rttsVSzrtts(inputFile :string, title_red :string)')
        return
    end
    
    
    fileID = fopen(inputFile);
    A = textscan(fileID,'%d %f64 %f64 %f64');
    fclose(fileID);
    %celldisp(A)
    
    ejeX = A{1};
    rttAcum = A{2}*1000;
    rtt_i = A{3}*1000;
    zrtt_i = A{4};
    cantDatos = length(ejeX);
    
    for i=[1:cantDatos],
		rtt_i_acumHaciaAtras(i) = sum(rtt_i(1:i));
	end
    
    hold off;
    clf;
    subplot(2,1,1);
    plot(ejeX,rttAcum,ejeX,rtt_i_acumHaciaAtras, 'LineWidth', 2);
    grid;
    title(['Comparacion de RTTs y ZRTTs en Caso de Estudio ' title_red], 'FontSize', 16);
    ylabel('Milisegundos', 'FontSize', 11);
    xlabel('HOP', 'FontSize', 11);
    set(gca, 'XTick', 1:1:length(ejeX));
    legend('RTT^{acum}_i', 'suma(RTT_1,...,RTT_i)', 'Location','SouthEast');
    
    subplot(2,1,2);
    plot(ejeX,zrtt_i, 'r','LineWidth', 2);
    grid;
    ylabel('ZRTT_i', 'FontSize', 11);
    xlabel('HOP', 'FontSize', 11);
    set(gca, 'XTick', 1:1:length(ejeX));
end

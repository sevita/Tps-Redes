%%%% La idea de este archivo es que para invocar las distintas funciones y
%%%% generar distintos graficos, hay que hacer (por ejemplo):
%%%% 
%%%%   graficosMatlab.hist_ips_mas_solicitadas('archivo');
%%%%
%%%% Es decir que en general, para invocar una funcion, hay que usar:
%%%%
%%%%   graficosMatlab.nombre_de_la_funcion(arg1,arg2,...,argN);

function funcion = graficosMatlab
    funcion.hist_ips_mas_solicitadas  = @hist_ips_mas_solicitadas;
    funcion.hist_ips_mas_solicitantes = @hist_ips_mas_solicitantes;
    funcion.hist_informacion_src = @hist_informacion_src; 
end

function hist_ips_mas_solicitadas(inputFile, title_red, longit_intervalo)
    if nargin < 3,
        disp('ERROR: hist_ips_mas_solicitadas(string inputFile, string title_red, int longit_intervalo)')
        return
    end
    
    
    fileID = fopen(inputFile);
    A = textscan(fileID,'%s %f64');
    fclose(fileID);
    %celldisp(A)
    
    valores = A{2};
    labels = A{1};
    cantDatos = length(valores);
    
    % Grafico se hace desde...hasta (indices del arreglo de datos)
    desde = 1;
    hasta = cantDatos;
    
    bar(valores(desde:hasta));
    cantDatosGraficados = hasta - desde + 1;
    
    maxY = floor(max(valores)) + (100 - mod(floor(max(valores)), 50));
    
    grid;
    title(['IPs mas solicitadas - Medicion ' title_red], 'FontSize', 16);
    ylabel('Cantidad de Solicitudes en un lapso de 30 minutos', 'FontSize', 11);
    xlabel(['IPs que aparecen en todos los intervalos de ' int2str(longit_intervalo) ' minutos'], 'FontSize', 11);
    set(gca, 'YTick', 0:50:maxY);
    set(gca, 'YLim', [0 maxY]);
    set(gca, 'XLim', [0 cantDatosGraficados+1]);
    xticklabel_rotate(1:cantDatosGraficados,90,labels(desde:hasta),'FontSize', 8);
    set(get(gca, 'Xlabel'), 'Position', get(get(gca, 'Xlabel'),'Position') + [0  0.05 0]); %% Acomoda el Xlabel (lo sube 0.01)
end

function hist_informacion_src(inputFile, title_red, longit_intervalo, entro)
    if nargin < 3,
        disp('ERROR: hist_ips_mas_solicitadas(string inputFile, string title_red, int longit_intervalo)')
        return
    end
    
    
    fileID = fopen(inputFile);
    A = textscan(fileID,'%s %f64');
    fclose(fileID);
    %celldisp(A)
    
    valores = A{2};
    labels = A{1};
    cantDatos = length(valores);
    
    % Grafico se hace desde...hasta (indices del arreglo de datos)
    desde = 1;
    hasta = cantDatos;
    
    
    cantDatosGraficados = hasta - desde + 1;
    
        P1=[0 entro];
    P2=[(cantDatos+1) entro]; 
    
    bar(valores(desde:hasta));
      hold on;
    plot([P1(1) P2(1)],[P1(2) P2(2)],'r', 'Linewidth', 3);
    
    maxY = (max(valores) + 5) ;
    
    grid;
    title(['informacion de las IPs en la fuente DST por intervalos de tiempo - ' title_red], 'FontSize', 16);
    ylabel('información por IP', 'FontSize', 11);
    xlabel(['IPs que aparecen en todos los intervalos de ' int2str(longit_intervalo) ' minutos'], 'FontSize', 11);
    %set(gca, 'YTick', 0:5:maxY);
    set(gca, 'YLim', [0 maxY]);
    set(gca, 'XLim', [0 cantDatosGraficados+1]);
    xticklabel_rotate(1:cantDatosGraficados,90,labels(desde:hasta),'FontSize', 8);
    set(get(gca, 'Xlabel'), 'Position', get(get(gca, 'Xlabel'),'Position') + [0  0.05 0]); %% Acomoda el Xlabel (lo sube 0.01)
    
  
    

    
        
end

function hist_ips_mas_solicitantes(inputFile, title_red, longit_intervalo)
    if nargin < 3,
        disp('ERROR: hist_ips_mas_solicitantes(string inputFile, string title_red, int longit_intervalo)')
        return
    end
    
    
    fileID = fopen(inputFile);
    A = textscan(fileID,'%s %f64');
    fclose(fileID);
    %celldisp(A)
    
    valores = A{2};
    labels = A{1};
    cantDatos = length(valores);
    
    % Grafico se hace desde...hasta (indices del arreglo de datos)
    desde = 1;
    hasta = cantDatos;
    
    bar(valores(desde:hasta));
    cantDatosGraficados = hasta - desde + 1;
    
    maxY = floor(max(valores)) + (100 - mod(floor(max(valores)), 50));
    
    grid;
    title(['IPs mas solicitantes - Medicion ' title_red], 'FontSize', 16);
    ylabel('Cantidad de Solicitudes en un lapso de 30 minutos', 'FontSize', 11);
    xlabel(['IPs que aparecen en todos los intervalos de ' int2str(longit_intervalo) ' minutos'], 'FontSize', 11);
    set(gca, 'YTick', 0:50:maxY);
    set(gca, 'YLim', [0 maxY]);
    set(gca, 'XLim', [0 cantDatosGraficados+1]);
    xticklabel_rotate(1:cantDatosGraficados,90,labels(desde:hasta),'FontSize', 8);
    set(get(gca, 'Xlabel'), 'Position', get(get(gca, 'Xlabel'),'Position') + [0  0.05 0]); %% Acomoda el Xlabel (lo sube 0.01)
end




%%% Deprecated!!
function hist_ips_mas_solicitadas_conOtroFiltro(inputFile)
    if nargin < 1,
        inputFile = 'input_matlab.in';
    end

    A = importdata(inputFile,' ');

    cantDatos = length(A.data);
    valores = A.data;
    labels = A.rowheaders;
    %~ valores(:,2) = [1:cantDatos]';
    %~ [val, posicion] = sort(valores(:,1));
    %~ for i=[1:cantDatos],
        %~ labels(i) = A.rowheaders(posicion(i));
    %~ end

    %%%%  Corta el arreglo de valores desde el comienzo. Deja todos los valores
    %%%%  desde corte_valor en adelante. Si el arreglo esta ordenado, esto
    %%%%  elimina todos los valores menores (estricto) a corte_valor.
    corte_valor = 10;
    corte_indic = 1;
    for i=1:cantDatos,
        if valores(i) < corte_valor,
            corte_indic = corte_indic + 1;
        else
            break;
        end
    end

    bar(valores(corte_indic:cantDatos));
    cantDatosGraficados = cantDatos - corte_indic + 1;
    %barh(valores);
    %for i=[1:cantDatos],
    %    text(i,valores(i),labels(i), 'FontSize', 10, 'HorizontalAlignment','right','VerticalAlignment','bottom');
    %end

    %set(gca, 'YTick', [1:cantDatos]);
    %set(gca, 'YTickLabel', labels, 'FontSize', 8);

    grid;
    title('IPs mas solicitadas - Medicion Red Labos-DC', 'FontSize', 16);
    ylabel('Cantidad de Solicitudes en un lapso de 30 minutos', 'FontSize', 11);
    xlabel('IP', 'FontSize', 11);
    set(gca, 'YTick', 0:50:550);
    set(gca, 'YLim', [0 550]);
    set(gca, 'XLim', [0 cantDatosGraficados+1]);
    xticklabel_rotate(1:cantDatosGraficados,90,labels(corte_indic:cantDatos),'FontSize', 8);
end

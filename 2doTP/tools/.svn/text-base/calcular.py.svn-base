#! /usr/bin/env python
import sys
import math
import argparse
import socket
import urllib2

ECHO_REPLY    = 0
TIME_EXCEEDED = 11

''' CONVENCIONES '''
# data = dict( ttl:int, dict(ipQueResponde_tipoICMP:<str,int>, rttsAcumulados:[float]) )
#        La idea es que por cada ttl se guardan todos los pares (ip,tipoICMP) y por cada uno de esos pares, la lista de rtts
#        medidos, porque podria pasar que una misma ip responda time-exceeded y echo-reply en dos mensajes distintos, entonces
#        quisieramos distiguir si llegamos o no a destino, por eso se distinguen pares (ip,tipoICMP) y no solo por ip.

# caminoMasPesado = dict(ttl:int, <ip:str, tipoICMP:int, promedioRTTSacumulado:float, probabilidadDeQueAparezcaIP-TIPOICM_enEsteTTL:float> )
#        La idea es que por cada ttl se guarde el par (ip,tipoICMP) que mas aparece en las iteraciones realizadas para ese TTL.
#        Se considera que esa IP es la mas 'pesada' entonces es el camino mas problable. Por cada par se guarda el RTT acumulado promedio y la probabilidad
#        de aparicion = cantAparciciones/cantIteraciones. tipoICMP = 11 o 0

# rttXsalto  = dict(ttl:int, rtt_i:float)
#        Por cada ttl, el rtt correspondiente al salto desde el nodo anterior hasta el nodo donde el ttl respondio time-exc

# zrttXsalto = dict(ttl:int, zrtt_i:float)
#        Por cada ttl, el zrtt correspondiente al salto desde el nodo anterior hasta el nodo donde el ttl respondio time-exc


## Algunas variables globales para facilitar las cosas:

#######################################################


"""################## FUNCIONES IMPORTANTES """

def parser(nombreArchivo):
	f = open(nombreArchivo, 'r')
	data = dict()
	
	ipdst = f.readline()[:-1] # le saco el'\n'
	cantIteraciones = int(f.readline()[:-1])
	
	## Hardcodeo una entrada para ttl=0 (donde la IP="SRC" porque es la salida, cuando rtt=0) (esto sirve para poder hacer graficos de curvas que empiecen en cero)
	data[0] = dict()
	data[0][("SRC",TIME_EXCEEDED)] = []
	for i in range(0,cantIteraciones):
		data[0][("SRC",TIME_EXCEEDED)].append(0.0)
	
	line = f.readline()[:-1] ## este es el primer numero de ttl
	while line != "END":
		ttl = int(line)
		data[ttl] = dict()
		
		line = f.readline()[:-1]
		while line != "#":
			items = line.split(" ")
			
			ipQueResponde = items[0]
			rtt           = float(items[1])
			tipoICMP      = int(items[2])
			
			if (ipQueResponde,tipoICMP) not in data[ttl]:
				data[ttl][(ipQueResponde,tipoICMP)] = [rtt]
			else:
				data[ttl][(ipQueResponde,tipoICMP)].append(rtt)
			
			line = f.readline()[:-1]
			
		line = f.readline()[:-1]
	f.close()
	return ipdst,data,cantIteraciones


def mediana(lista):
    lista = sorted(lista)
    n = len(lista)
    if n%2 == 1:
        return lista[n//2]
    else:
        i = n//2
        return (lista[i - 1] + lista[i])/2

def media(lista):
    return sum(lista) / len(lista)

def mediaAlfaPodada(lista,alfa):
	## Quita el alfa porciento de los datos de atras y de adelante de la lista (ordenada) y de eso calcula la media.
	## Ej: mediaAlfaPodada([2,4,5,1,3,6,9,8,0,7], 10):
	##         ordenar lista = [0,1,2,3,4,5,6,7,8,9,10]
	##         alfa% de la longitud de la lista = 1
	##         eliminar 1 dato a la derecha y 1 dato a la izquierda: [1,2,3,4,5,6,7,8]
	##         Calcular media de esa lista.
	lista = sorted(lista)
	n = len(lista)
	cantAEliminar = int(math.floor((n*alfa)/100.0))
	lista = lista[cantAEliminar:n-cantAEliminar]  ## esto da la sublista: l[d:h] = [l[d], l[d+1], ... , l[h-1]]
	return media(lista)

def calcularTodosLosCaminosPosiblesYProbabilidad(data, cantIteraciones):
	caminos = dict()
	
	for ttl in data.iterkeys():
		caminos[ttl] = []
		for (ip,tipoICMP),rtts in data[ttl].iteritems():
			caminos[ttl].append( (ip,tipoICMP,float(len(rtts))/float(cantIteraciones)) )
		caminos[ttl].sort(key=lambda x: x[2], reverse=True)
	
	return caminos

def calcularCaminoMasPesado(data, cantIteraciones, formaDePromediar):
	promedios = dict()
	caminoMasPesado = dict()
	
	#### Promediar y Acumular RTTs
	for ttl in data.iterkeys():
		promedios[ttl] = dict()
		for tupla,rtts in data[ttl].iteritems():
			if formaDePromediar == "media":
				promedio_rtt = media(rtts)
			elif formaDePromediar == "mediana":
				promedio_rtt = mediana(rtts)
			else:
				promedio_rtt = mediaAlfaPodada(rtts, formaDePromediar)
				
			promedios[ttl][tupla] = (promedio_rtt, float(len(rtts))/float(cantIteraciones))
		
		
		maxProbaAp = 0.0
		tuplaMax = ("",0)
		for (ip,tipoICMP),(_,probaAparicion) in promedios[ttl].iteritems():
			if probaAparicion > maxProbaAp:
				maxProbaAp = probaAparicion
				tuplaMax = (ip,tipoICMP)
		caminoMasPesado[ttl] = (tuplaMax[0], tuplaMax[1], promedios[ttl][tuplaMax][0], promedios[ttl][tuplaMax][1]) # (ip, tipoICMP, promedio_rtt, probaAparicion)
	return caminoMasPesado

def calcularRTTi_version1(caminoMasPesado):
	rttXsalto = dict()
	for ttl,(ip,tipoICMP,promedioRTTacum,_) in caminoMasPesado.iteritems():
		acumuladosAnteriores = sum(rttXsalto.values())
		rtt_i = promedioRTTacum - acumuladosAnteriores
		if rtt_i < 0: rtt_i = 0.0
		rttXsalto[ttl] = rtt_i
	return rttXsalto
	
def calcularRTTi_version2(caminoMasPesado):
	rttXsalto = dict()
	ttlAnterior = 0
	for ttl,(ip,tipoICMP,promedioRTTacum,_) in caminoMasPesado.iteritems():
		if ttl == 1:
			acumuladosAnteriores = 0.0
		else:
			acumuladosAnteriores = caminoMasPesado[ttlAnterior][2]
		rtt_i = promedioRTTacum - acumuladosAnteriores
		if rtt_i < 0: rtt_i = 0.0
		rttXsalto[ttl] = rtt_i
		ttlAnterior = ttl
	return rttXsalto
	
def calcularZRTTi(rttXsalto):
	zrttXsalto = dict()
	
	#### Calcular RTT_promedio y SRTT
	n = float(len(rttXsalto.keys()))
	sumaRTTs = 0
	for rtt_i in rttXsalto.itervalues():
		sumaRTTs = sumaRTTs + rtt_i
	RTT_prom = sumaRTTs / n
	
	sumasRTTiMenosPromedio = 0
	for rtt_i in rttXsalto.itervalues():
		sumasRTTiMenosPromedio = sumasRTTiMenosPromedio + (rtt_i - RTT_prom)**2
	SRTT = math.sqrt(sumasRTTiMenosPromedio / (n-1.0))
	
	#### Calcular ZRTT_i
	for ttl,rtt_i in rttXsalto.iteritems():
		zrtt_i = (rtt_i - RTT_prom) / SRTT
		zrttXsalto[ttl] = zrtt_i
	return zrttXsalto
	
def generarTablaGeolocalizacion(caminoMasPesado):
	tablaGeoloc = []
	for ttl,(ip,_,promedioRTTacum,_) in caminoMasPesado.iteritems():
		if ttl!=0:
			try:
				dns = socket.gethostbyaddr(ip)[0]
			except: #socket.herror:
				dns = "No encontrada"
			
			geolocation = urllib2.urlopen("http://freegeoip.net/csv/"+ip).read().split('"')
			pais = geolocation[5]
			provincia = geolocation[9]
			ciudad = geolocation[11]
			lat = geolocation[15]
			lon = geolocation[17]
			tablaGeoloc.append({"ttl":ttl, "ip":ip, "dns":dns, "pais":pais, "provincia":provincia,"ciudad":ciudad,"lat":lat, "lon":lon})
	return tablaGeoloc
	
	
	
	
"""################## PRINTs """
	
def printTablaGeolocalizacion(tablaGeoloc, matlab=False, latex=False):
	if latex:
		for salto in tablaGeoloc:
			print "{:^3} & {{\\tt {:>16}}} &  \\verb+{:^}+ & {:>30} & {:>17}\\\\".format(
				salto["ttl"],
				salto["ip"],
				salto["dns"],
				salto["pais"]+(","+salto["provincia"] if salto["provincia"]!="" else ""),
				salto["lat"]+","+salto["lon"])
			print "\\hline"
	else:
		print "\n{:*^104}".format("GEOLOCALIZACION")
		print "{:^3} {:^16} {:^65} {:^25} {:^19}".format("TTL","IP","DNS","UBICACION","LAT,LON")
		for salto in tablaGeoloc:
			print "{:^3} {:>16} {:>70} {:>30} {:>17}".format(
				salto["ttl"],
				salto["ip"],
				salto["dns"],
				salto["pais"]+(","+salto["provincia"] if salto["provincia"]!="" else ""),
				#salto["ciudad"],
				salto["lat"]+","+salto["lon"])
	
def printCaminoMasPesado(caminoMasPesado, rtts_1, zrtts_1, rtts_2, zrtts_2, matlabFriendly=False, latex=False):
	if matlabFriendly:
		for ttl,(ip,tipoICMP,promedioRTTacum,probaAparicion) in caminoMasPesado.iteritems():
			rtt_1_i  = rtts_1[ttl]
			zrtt_1_i = zrtts_1[ttl]
			rtt_2_i  = rtts_2[ttl]
			zrtt_2_i = zrtts_2[ttl]
			print ttl, ip, ("ECHO_REPLY" if tipoICMP==0 else "TIME_EXC"), probaAparicion, promedioRTTacum, rtt_1_i, zrtt_1_i, rtt_2_i, zrtt_2_i
	
	elif latex:
		ttlAnterior = -1
		for ttl,(ip,tipoICMP,promedioRTTacum,probaAparicion) in caminoMasPesado.iteritems():
			while ttl > ttlAnterior + 1: ## Rellenar los ttls que no tuvieron respuesta
				#~ print "{:^3} & {{\\tt {:>16}}} &  {:^19} & {:>9} & {:>13} & {:>13} & {:>13}\\\\".format(
				       #~ ttlAnterior+1,"SIN RESPUESTA","*","*","*","*","*")
				print "{:^3} & \\multicolumn{{6}}{{|c|}}{{{:^16}}}\\\\".format(
				       ttlAnterior+1,"Sin Respuesta")
				print "\\hline"
				ttlAnterior = ttlAnterior + 1
			## Los tiempos en milisegundos (para que sea 'human-readable')
			promedioRTTacum = promedioRTTacum*1000
			rtt_1_i  = rtts_1[ttl]*1000
			rtt_2_i  = rtts_2[ttl]*1000
			print "{:^3} & {{\\tt {:>16}}} &  {:^19} & {:>9} & {:>13} & {:>13} & {:>13}\\\\".format(
				ttl,
				ip,
				("{\\tt ECHO\\_REPLY}" if tipoICMP==0 else "{\\tt TIME\\_EXC}"),
				"%.4f" % (probaAparicion),
				"%.4f" % (promedioRTTacum),
				("%.4f" % (rtt_1_i)) if rtt_1_i != 0 else "0",
				("%.4f" % (rtt_2_i)) if rtt_2_i != 0 else "0" )
			print "\\hline"
			ttlAnterior = ttl
	else:
		print "\n{:*^111}".format("CAMINO MAS PESADO")
		print "{:^3} {:^16} {:^10} {:>9} {:>13} {:>13} {:>13} {:>13} {:>13}".format(
			"TTL","IP", "ICMP", "P(IP|TTL)", "RTT_acum (ms)", "RTT_1_i (ms)", "ZRTT_1_i", "RTT_2_i (ms)", "ZRTT_2_i")
		for ttl,(ip,tipoICMP,promedioRTTacum, probaAparicion) in caminoMasPesado.iteritems():
			## Los tiempos en milisegundos (para que sea 'human-readable')
			promedioRTTacum = promedioRTTacum*1000
			rtt_1_i  = rtts_1[ttl]*1000
			zrtt_1_i = zrtts_1[ttl]
			rtt_2_i  = rtts_2[ttl]*1000
			zrtt_2_i = zrtts_2[ttl]
			print "{:^3} {:>16} {:^10} {:>9} {:>13} {:>13} {:>13} {:>13} {:>13}".format(
				ttl,
				ip,
				("ECHO_REPLY" if tipoICMP==0 else "TIME_EXC"),
				"%.4f" % (probaAparicion),
				"%.4f" % (promedioRTTacum),
				"%.4f" % (rtt_1_i),
				"%.6f" % (zrtt_1_i),
				"%.4f" % (rtt_2_i),
				"%.6f" % (zrtt_2_i))
		print ""

def printZSCORESmatlab(caminoMasPesado, rtts, zrtts, matlab=False, latex=False):
	for ttl,(_,_,promedioRTTacum,_) in caminoMasPesado.iteritems():
		rtt_i  = rtts[ttl]
		zrtt_i = zrtts[ttl]
		print ttl, promedioRTTacum, rtt_i, zrtt_i
	
def printComparacionDePromedios(lista, matlab=False, latex=False):
	if matlab:
		lastTTL = -1
		for i in range(0,len(lista)):
			tupla = lista[i]
			######### Media = 0-podada ############################ Mediana aprox 50-podada
			## TTL IP Media 10-podada 20-podada 30-podada 40-podada Mediana
			print tupla[7], tupla[0], tupla[1], tupla[3], tupla[4], tupla[5], tupla[6], tupla[2]
	
	else:
		print "\n{:*^104}".format("COMPARACION DE METRICAS DE PROMEDIO")
		print "{:^3} {:^16} {:>13} {:>13} {:>13} {:>13} {:>13} {:>13}".format("TTL", "IP", "Media", "10", "20", "30", "40", "Mediana")
		for i in range(0,len(lista)):
			tupla = lista[i]
			## Los tiempos en milisegundos (para que sea 'human-readable')
			print "{:^3} {:^16} {:>13} {:>13} {:>13} {:>13} {:>13} {:>13}".format(tupla[7], tupla[0], "%.4f" % (tupla[1]*1000), "%.4f" % (tupla[3]*1000), "%.4f" % (tupla[4]*1000), "%.4f" % (tupla[5]*1000), "%.4f" % (tupla[6]*1000), "%.4f" % (tupla[2]*1000))
		print ""

def printTodosLosCaminos(caminos, cantCaminos):
	for ttl in caminos.iterkeys():
		linea = "{:^3}".format(ttl)
		
		i = 0
		
		while i<len(caminos[ttl]) and i<cantCaminos:
			(ip, tipoICMP, probaAparicion) = caminos[ttl][i]
			linea = linea + " & {{\\tt {:>16}}} & {:^2} & {:>5}".format(
								ip,
								("{\\tt ER}" if tipoICMP==0 else "{\\tt TE}"),
								"%.3f" % (probaAparicion))
			i = i+1
		
		while i<cantCaminos:
			linea = linea + " & {:>16} & {:^2} & {:>5}".format("*","*","*")
			i = i+1
		
		linea = linea + "\\\\"
		print linea
		print "\\hline"




"""################## VALIDACION DE ARGUMENTOS """

def validarFormaDePromediar(formaDePromediar):
	if formaDePromediar != "media" and formaDePromediar != "mediana":
		## Si no es ni 'media' ni 'mediana', me fijo si es un float. Si no lo es, le pongo -2 para que en el siguiente if salte.
		## Si es un float, luego chequea que este en rango. Si logra salir de la funcion, es valido.
		try:
			formaDePromediar = float(formaDePromediar)
		except ValueError:
			formaDePromediar = -2
			
		if  formaDePromediar < 0 or formaDePromediar >= 50:
			print "Error en parametros: Debe indicar una forma de promediar\n\
			       valida. Ejecute --help para ver alternativas."
			sys.exit(2)
	return formaDePromediar
	
def determinarConfiguraciones():
	argparser = argparse.ArgumentParser(description="Analizar de distintas maneras los datos proporcionados.", prefix_chars='-+')
	argparser.add_argument("archivo_entrada", help="archivo usado para tomar las muestras", type=str)
	argparser.add_argument("-p",
						help="indicar la forma de promediar las muestras de RTTs por cada tupla (TTL,IP,TIPO_ICMP).\
						      Puede valer (sin comillas): 'media', 'mediana' o un float en [0,50). Default: 30.",
					    type=str, default="30", metavar="METRICA")
	group = argparser.add_mutually_exclusive_group(required=False)
	group.add_argument("-m", "--matlab", help="Activa impresion tipo Matlab (no siempre disponible).", action="store_true", default=False)
	group.add_argument("-l", "--latex", help="Activa impresion para LaTeX (no siempre disponible).", action="store_true", default=False)
	
	group_conf = argparser.add_mutually_exclusive_group(required=False)
	group_conf.add_argument("--camino_mas_pesado", help="Activado por default. Imprime la tabla correspondiente al camino de mayor probabilidad y datos asociados al mismo.", action="store_true", default=True)
	group_conf.add_argument("--comparar_metricas", help="Ejecuta todas las metricas posibles para calcular el promedio que se explica en la opcion '-p' y muestra una tabla con los resultados",
	                        action="store_true", default=False)
	group_conf.add_argument("--zscores", help="Muestra una tabla comparando rtt^{acum}_i, rtt_i, zrtt_i.", action="store_true", default=False)
	group_conf.add_argument("--caminos", help="Imprime una tabla con los 3 caminos mas probables.", action="store_true", default=False)
	group_conf.add_argument("--geoloc", help="Imprime una tabla con la geolocalizacion del camino mas probable.", action="store_true", default=False)
	args = argparser.parse_args()
	
	
	nombreArchivoEntrada = args.archivo_entrada
	formaDePromediar     = args.p
	formaDePromediar     = validarFormaDePromediar(formaDePromediar)
	matlab               = args.matlab
	latex                = args.latex
	
	#### Esto permite tener por default la opcion de camino mas pesado (siempre vale true):
	if args.comparar_metricas: configuracion = "comparar_metricas"
	elif args.zscores:         configuracion = "zscores"
	elif args.caminos:         configuracion = "todos_los_caminos"
	elif args.geoloc:          configuracion = "tabla_geolocalizacion"
	else:                      configuracion = "camino_mas_pesado"
	
	return nombreArchivoEntrada, formaDePromediar, matlab, latex, configuracion





if __name__ == "__main__":
	
	nombreArchivoEntrada, formaDePromediar, matlab, latex, configuracion = determinarConfiguraciones()
	
	ipdst, data, cantIteraciones = parser(nombreArchivoEntrada)
	
	if configuracion == "camino_mas_pesado":
		caminoMasPesado = calcularCaminoMasPesado(data, cantIteraciones, formaDePromediar)
		
		rttXsalto_v1  = calcularRTTi_version1(caminoMasPesado)
		zrttXsalto_v1 = calcularZRTTi(rttXsalto_v1)
		
		rttXsalto_v2  = calcularRTTi_version2(caminoMasPesado)
		zrttXsalto_v2 = calcularZRTTi(rttXsalto_v2)
		
		printCaminoMasPesado(caminoMasPesado,rttXsalto_v1,zrttXsalto_v1,rttXsalto_v2,zrttXsalto_v2, matlab, latex)
		
	elif configuracion == "comparar_metricas":
		caminoMasPesado_media   = calcularCaminoMasPesado(data, cantIteraciones, "media")
		caminoMasPesado_mediana = calcularCaminoMasPesado(data, cantIteraciones, "mediana")
		caminoMasPesado_10      = calcularCaminoMasPesado(data, cantIteraciones, 10)
		caminoMasPesado_20      = calcularCaminoMasPesado(data, cantIteraciones, 20)
		caminoMasPesado_30      = calcularCaminoMasPesado(data, cantIteraciones, 30)
		caminoMasPesado_40      = calcularCaminoMasPesado(data, cantIteraciones, 40)
		lista = [(caminoMasPesado_media[ttl][0],   ## IP
				  caminoMasPesado_media[ttl][2],   ## Media
				  caminoMasPesado_mediana[ttl][2], ## Mediana
		          caminoMasPesado_10[ttl][2],      ## Media 10-podada
		          caminoMasPesado_20[ttl][2],      ## Media 20-podada
		          caminoMasPesado_30[ttl][2],      ## Media 30-podada
		          caminoMasPesado_40[ttl][2],      ## Media 40-podada
		          ttl)                             ## TTL
		          for ttl in caminoMasPesado_media.iterkeys()]
		printComparacionDePromedios(lista, matlab, latex)

	elif configuracion == "zscores":
		caminoMasPesado = calcularCaminoMasPesado(data, cantIteraciones, formaDePromediar)
		
		rttXsalto_v2  = calcularRTTi_version2(caminoMasPesado)
		zrttXsalto_v2 = calcularZRTTi(rttXsalto_v2)
		
		printZSCORESmatlab(caminoMasPesado, rttXsalto_v2, zrttXsalto_v2, matlab, latex)
	
	elif configuracion == "todos_los_caminos":
		caminos = calcularTodosLosCaminosPosiblesYProbabilidad(data, cantIteraciones)
		printTodosLosCaminos(caminos, 2)
	
	elif configuracion == "tabla_geolocalizacion":
		caminoMasPesado = calcularCaminoMasPesado(data, cantIteraciones, formaDePromediar)
		tablaGeoloc = generarTablaGeolocalizacion(caminoMasPesado)
		printTablaGeolocalizacion(tablaGeoloc,matlab,latex)
		

#! /usr/bin/env python
from scapy.all import *
import sys
import time
import signal
import argparse


ECHO_REPLY    = 0
TIME_EXCEEDED = 11

__cantIteraciones__    = 0
__backUpParaImprimir__ = dict()
ipdst = ""

__ejecuteSignalHandler__ = False ## esto es para prevenir que capture dos veces SIGINT e imprima dos veces los resultados parciales
def signal_handler_ctrl_c(signal, frame):
	global __ejecuteSignalHandler__, __cantIteraciones__, __backUpParaImprimir__, ipdst
	if __cantIteraciones__ > 0 and (not __ejecuteSignalHandler__):
		imprimirResultados(ipdst, __cantIteraciones__, __backUpParaImprimir__)
		__ejecuteSignalHandler__ = True
	sys.exit("\n\n\nSe imprimieron las iteraciones terminadas.\n")

signal.signal(signal.SIGINT, signal_handler_ctrl_c)


def imprimirResultados(ipdst,cantIteraciones,paraImprimir):
	print ipdst
	print cantIteraciones
	
	for ttl,listaParaImprimir in paraImprimir.iteritems():		
		print ttl
		for tupla in listaParaImprimir:
			print tupla[0], tupla[1], tupla[2]
		print "#"
		
		## Si las cantIteraciones mediciones dieron la misma ip, y es la ip destino, entonces asumo que llegue a destino y no imprimo mas
		llegueAlDestino = True
		for tupla in listaParaImprimir:
			llegueAlDestino = llegueAlDestino and tupla[2] == ECHO_REPLY
		if llegueAlDestino:
			break
			
	print "END"
""" Si para algun TTL hay menos mediciones que la cantidad de iteraciones, es porque no llego a medirlos 
    (para alguna iteracion encontro un camino mas largo). En esos TTLs con pocas mediciones, se asume que
    las demas mediciones simplemente repitieron el destino final (la ruta ya habia terminado).
"""
	

if __name__ == "__main__":
	argparser = argparse.ArgumentParser(description="Traza rutas de paquetes IP.", prefix_chars='-+')
	argparser.add_argument("destino", help="una IP o una direccion www destino de la ruta.", type=str)
	argparser.add_argument("-t",
						help="Indicar tolerancia (cantidad de veces que debe responder la IP destino para asumir\
						      que se llego al destino). Default = 10.",
					    type=int, default=10, metavar="TOL")
	argparser.add_argument("-i",
						help="Indicar cantidad de iteraciones a realizar por cada salto. Default = 5.",
					    type=int, default=5, metavar="CANT_IT")
	argparser.add_argument("-e",
						help="Excluir una lista de TTLs. Ej: -e 1 2 3 6, saltea los TTLs 1,2,3 y 6.",
					    type=int, nargs="*", default=[], metavar="TTL")
	args = argparser.parse_args()
	
	
	destino           = args.destino
	tolerancia        = args.t
	cantIteraciones   = args.i
	ttlsExcluidos     = args.e
	
	ttlsParaAnalizar  = []
	for i in range(1,65):
		if i not in ttlsExcluidos:
			ttlsParaAnalizar.append(i)
	
	sys.stderr.write("Ejecutando: DST="+destino+"; TOL="+str(tolerancia)+"; CANT_IT="+str(cantIteraciones)+"; EXCLUDE_TTLS="+str(ttlsExcluidos)+";\n")
	
	packet = IP(dst=destino) / ICMP()
	ipdst = packet.dst.choice() ## Esto devuelve la IP numerica...
	
	paraImprimir = dict()  ### paraImprimir = dict( ttl:int, listaAImprimir: [ < ipQueResponde:str, rtt:float, tipoICMP:int > ] )
	
	sys.stderr.write("STATUS: (iteraciones completadas)")
	for it in range(0,cantIteraciones):
		sys.stderr.write("\nIT="+str(it)+" TTLs=")
		
		#~ ttlsMedidos = []
		
		for j in range(0,len(ttlsParaAnalizar)):
			ttl = ttlsParaAnalizar[j]
			if ttl not in paraImprimir: paraImprimir[ttl] = []
			packet.ttl = ttl
			
			r = []
			while len(r)==0:
				t0 = time.time()
				r , na = sr(packet, timeout=5, verbose=0)  ## timeout sirve para timeout y para esperar un tiempo antes de reenviar
				rtt = time.time() - t0
			
			#~ ttlsMedidos.append(ttl) # con esto llevo registro de los ttls que ya medi
			
			respuesta = r[0][1]
			ipQueResponde = respuesta.src
			tipoICMP = respuesta.type
			
			# Registro:
			paraImprimir[ttl].append((ipQueResponde,rtt,tipoICMP)) ## Este rtt es acumulado
			
			sys.stderr.write(str(ttl)+" ")
			
			## Si los ultimos 'tolerancia' ttls dieron la ip destino, entonces asumimos que llegamos a destino y no medimos mas
			if j >= tolerancia:
				llegueAlDestino = True
				for i in range(j-tolerancia,j):
					llegueAlDestino = llegueAlDestino and paraImprimir[ ttlsParaAnalizar[i] ][it][2] == ECHO_REPLY
				if llegueAlDestino:
					break
		     ## END FOR
		__cantIteraciones__    = it+1
		__backUpParaImprimir__ = copy.deepcopy(paraImprimir)
	## END FOR
	
	sys.stderr.write("\n")
	
	imprimirResultados(ipdst,cantIteraciones,paraImprimir)

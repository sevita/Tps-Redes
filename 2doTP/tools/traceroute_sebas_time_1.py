#! /usr/bin/env python
from scapy.all import *
import sys
import time
import signal


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
		for i in range(0,cantIteraciones):
			tupla = listaParaImprimir[i]
			print tupla[0], tupla[1], tupla[2]
			
		## Si las cantIteraciones mediciones dieron la misma ip, y es la ip destino, entonces asumo que llegue a destino y no imprimo mas
		llegueAlDestino = True
		for i in range(0,cantIteraciones):
			tupla = listaParaImprimir[i]
			llegueAlDestino = llegueAlDestino and tupla[2] == ECHO_REPLY
		if llegueAlDestino:
			break
			
	print "END"
	

if __name__ == "__main__":
	if len(sys.argv) != 4:
		sys.exit("\nModo de Uso: sudo python traceroute.py [IP/DIRECCION] [TOLERANCIA] [CANT_ITER]\n")
	destino         = sys.argv[1]
	tolerancia      = int(sys.argv[2])
	cantIteraciones = int(sys.argv[3])
	
	packet = IP(dst=destino) / ICMP()
	ipdst = packet.dst.choice() ## Esto devuelve la IP numerica...
	
	paraImprimir = dict()  ### paraImprimir = dict( ttl:int, listaAImprimir: [ < ipQueResponde:str, rtt:float, tipoICMP:int > ] )
	
	sys.stderr.write("STATUS: (iteraciones completadas)")
	for it in range(0,cantIteraciones):
		sys.stderr.write("\nIT="+str(it)+" TTLs= ")
		
		for ttl in range(1,65):
			if (ttl != 3) and (ttl != 4) and (ttl != 5):
				if ttl not in paraImprimir:
					paraImprimir[ttl] = []
				
				packet.ttl = ttl
				
				r = []
				while len(r)==0:
					t0 = time.time()
					r , na = sr(packet, timeout=2, verbose=0)  ## timeout sirve para timeout y para esperar un tiempo antes de reenviar
					rtt = time.time() - t0
						
				respuesta = r[0][1]
				ipQueResponde = respuesta.src
				tipoICMP = respuesta.type
				
				# Registro:
				paraImprimir[ttl].append((ipQueResponde,rtt,tipoICMP)) ## Este rtt es acumulado
				
				sys.stderr.write(str(ttl)+" ")
				
				## Si los ultimos 'tolerancia' ttls dieron la ip destino, entonces asumimos que llegamos a destino y no medimos mas
				if (tolerancia <= ttl) and (ttl > (5+tolerancia)):
					llegueAlDestino = True
					for i in range(0,tolerancia):
						llegueAlDestino = llegueAlDestino and paraImprimir[ttl-i][it][2] == ECHO_REPLY
					if llegueAlDestino:
						break
			else:
				if ttl not in paraImprimir:
					paraImprimir[ttl] = []
			## END FOR
		__cantIteraciones__    = it+1
		__backUpParaImprimir__ = paraImprimir # esto no copia, toma una referencia (para copiar: objetoCopia = copy.deepcopy(objeto) )
	## END FOR
		
	sys.stderr.write("\n")
	
	imprimirResultados(ipdst,cantIteraciones,paraImprimir)
		
		



#~ ''' ESTA VERSION HACE 30 ITERACIONES POR CADA TTL ''' (esto esta desactualizado, tal vez ni funciona)
#~ if __name__ == "__main__":
	#~ if len(sys.argv) != 3:
		#~ sys.exit("\nModo de Uso: sudo python traceroute.py [IP/DIRECCION] [CANT_ITER]\n")
	#~ destino = sys.argv[1]
	#~ cantIteraciones = int(sys.argv[2])
	#~ packet = IP(dst=destino) / ICMP()
	#~ ipdst = packet.dst.choice() ## Esto devuelve la IP numerica...
	#~ 
	#~ mediciones = dict()
	#~ 
	#~ print ipdst
	#~ 
	#~ sys.stderr.write("STATUS: (iteraciones completadas)")
	#~ for ttl in range(1,65):
		#~ mediciones[ttl] = dict()
		#~ packet.ttl = ttl
		#~ print ttl
		#~ 
		#~ sys.stderr.write("\nTTL="+str(ttl)+": ")
		#~ 
		#~ for it in range(0,cantIteraciones):
			#~ 
			#~ r = []
			#~ intentos = 0
			#~ while len(r)==0:
				#~ t0 = time.time()
				#~ r , na = sr(packet, timeout=5+intentos*5, verbose=0)
				#~ rtt = time.time() - t0
				#~ intentos = intentos + 1
				#~ 
			#~ respuesta = r[0][1]
			#~ ipQueResponde = respuesta.src
			#~ tipoICMP = respuesta.type
			#~ 
			#~ if ipQueResponde not in mediciones[ttl]:
				#~ mediciones[ttl][ipQueResponde] = [rtt]
			#~ else:
				#~ mediciones[ttl][ipQueResponde].append(rtt)
				#~ 
			#~ print ipQueResponde, rtt, tipoICMP ## Este rtt es acumulado
			#~ 
			#~ sys.stderr.write(str(it+1)+" ")
		#~ 
		#~ ## Si las 30 mediciones dieron la misma ip, y es la ip destino, entonces asumo que llegue a destino y no mido mas
		#~ llegueAlDestino = len(mediciones[ttl].keys()) == 1 and mediciones[ttl].keys()[0] == ipdst
		#~ if llegueAlDestino:
			#~ break
	#~ 
	#~ print "END"
	#~ sys.stderr.write("\n") 

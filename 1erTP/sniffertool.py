#! /usr/bin/env python
from scapy.all import *             ## sudo apt-get install python-scapy
import time
import sys

# Timestamp:
inicio = 0

# Para el item (b) ##
fuenteSRC    = dict()
fuenteDST    = dict()
cantMuestras = 0.0
#####################

def monitor_callback(pkt):	
	ipsrc = pkt.getfieldval("psrc")
	ipdst = pkt.getfieldval("pdst")
	
	op = ""
	if pkt.getfieldval("op") == 1:
		op = "who-has"
		# Para el item (b) #########################
		if pkt.getfieldval("dst").lower() == "ff:ff:ff:ff:ff:ff":  # si es broadcast
			global cantMuestras
			global fuenteSRC
			global fuenteDST
			cantMuestras = cantMuestras + 1.0
			if ipsrc in fuenteSRC:
				fuenteSRC[ipsrc] = fuenteSRC[ipsrc] + 1.0
			else:
				fuenteSRC[ipsrc] = 1.0
			if ipdst in fuenteDST:
				fuenteDST[ipdst] = fuenteDST[ipdst] + 1.0
			else:
				fuenteDST[ipdst] = 1.0
		############################################
	elif pkt.getfieldval("op") == 2:
		op = "is-at  "
	else:
		op = "indefinido-" + str(pkt.getfieldval("op"))
		 
	print (time.time()-inicio), pkt.getfieldval("src"), pkt.getfieldval("dst"), op, pkt.getfieldval("hwsrc"), ipsrc, pkt.getfieldval("hwdst"), ipdst



if __name__ == "__main__":
	if len(sys.argv) != 2:
		print ""
		print "Modo de uso:"
		print "            sudo python sniffertool.py [MINUTOS]"
		print ""
		print "MINUTOS = cantidad de minutos de captura."
		print ""
		exit(1)
	
	minutos = float(sys.argv[1])
	
	print "    Time         Eth-MAC-SRC       Eth-MAC-DST      OP       ARP-MAC-SRC     ARP-IP-SRC    ARP-MAC-DST     ARP-IP-DST"
	
	inicio = time.time()
	sniff(prn=monitor_callback,filter="arp",store=0, timeout=minutos*60)
	
	# Item (b)
	print "END"
	print ""
	print "Fuente S_{src}"
	print "{:<20} {:<20}".format("Simbolo","Probabilidad")
	for k,v in fuenteSRC.iteritems():
		print "{:<20} {:<20}".format(k,v/cantMuestras)
	print ""
	print "Fuente S_{dst}"
	print "{:<20} {:<20}".format("Simbolo","Probabilidad")
	for k,v in fuenteDST.iteritems():
		print "{:<20} {:<20}".format(k,v/cantMuestras)
	print ""

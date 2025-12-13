# Import bibliothèque
import socket
# Le port HTTP 80 ouvert
# Le port HTTPS 443 ouvert, les autres ports doivent être fermés
# 8095, 8098, 445, 446, 80, 443

s = socket.socket()
 
# informations d'adresse pour la connexion TCP
print(socket.getaddrinfo("example.org", socket.IPPROTO_TCP))

resultat = s.connect_ex(("example.org", 443))

 
if(resultat == 0):
  print('Le port est ouvert')
else:
  print('Le port est fermé')
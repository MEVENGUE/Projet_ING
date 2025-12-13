# Import bibliothèque
import requests

# https://www.ecam-epmi.fr/robots.txt
response = requests.get('https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal')

if(response.status_code == 200):
  response = requests.get('https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal')
  print('Demande réussie!')
  
  if(response.status_code== 200):
    print('Site vulnérable')
  else:
    print("Le site n'est pas vulnérable")
else:
  print('Demande échoué!')
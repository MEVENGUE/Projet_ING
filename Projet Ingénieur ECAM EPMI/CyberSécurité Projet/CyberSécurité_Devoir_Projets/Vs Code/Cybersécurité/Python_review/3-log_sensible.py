# Import bibliothèque
import re


f = open("C:\\Users\\MEVENGUE ENGONGOMO\\Desktop\\ECAM EPMI\\Cours 3 AE\\Cybersécurité, Sécurité\\Vs Code\\Cybersécurité\\Cours_1\\user_access_logs.log")
 
log_contentus = filter(None, f.read().split('\n'))
 
for line in (log_contentus):
  entries = re.findall(r'"([^"]*)"', line)
  url = entries[0].split(' ')[1]
  url_parts = url.split('?')
 
  if(len(url_parts) > 1):
    query = url_parts[1]
    if(query.find('password') > -1):
      print("\nUser login details identified:")
      print(query)
      print("\n")
from scapy.all import sniff, TCP, IP

def packet_callback(packet):
    if IP in packet and TCP in packet:
        print(f"Source IP: {packet[IP].src}, Destination IP: {packet[IP].dst}, TCP Port: {packet[TCP].dport}")

# Sniff TCP packets and print source and destination IP addresses along with the destination port
sniff(prn=packet_callback, store=0, filter="tcp")


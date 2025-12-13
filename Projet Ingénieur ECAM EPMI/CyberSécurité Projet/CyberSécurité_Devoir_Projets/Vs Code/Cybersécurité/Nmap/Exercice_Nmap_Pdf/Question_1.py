import nmap

nm = nmap.PortScanner()

def simple_discovery():
    # Perform a simple host discovery on the specified range of IP addresses
    nm.scan(hosts='192.168.1.1,192.168.1.3,192.168.1.7', arguments='-sn')

    # Iterate through all discovered hosts
    for host in nm.all_hosts():
        print(f"Host: {host} is up")

def detailed_port_analysis(target):
    # Perform an advanced scan with service version detection (-sV) and executing default NSE scripts (--script=default)
    nm.scan(hosts=target, arguments='-sS -p 1-1000 --script=default')

    # Iterate through all discovered hosts
    for host in nm.all_hosts():
        # Print detailed results for each host
        print(f"Detailed results for {host}:")

        # Check if there are open ports for the host
        if nm[host].all_tcp():
            # Print open ports for the host
            print(f"Open ports: {list(nm[host]['tcp'].keys())}")
        else:
            print(f"No open ports found for {host}")

if __name__ == "__main__":
    # Call the functions with the desired target IP address
    simple_discovery()
    detailed_port_analysis('192.168.1.254')
    # detailed_port_analysis('45.33.32.156')

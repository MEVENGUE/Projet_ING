import nmap
import json

def perform_tcp_syn_analysis(target):
    nm = nmap.PortScanner()

    try:
        # Perform TCP SYN scan to identify open ports
        nm.scan(hosts=target, arguments='-sS')

        # Get the first IP address from the list of scanned hosts
        host = list(nm.all_hosts())[0]

        # Initialize a dictionary to store port status
        port_status = {'Host': host, 'Port Status': {}}

        # Iterate through all TCP ports and determine their status (open/closed)
        for port, protocol in nm[host].all_tcp().items():
            port_status['Port Status'][f"Port {port}"] = 'open'

        # Print port status
        print("Port Status:")
        print(json.dumps(port_status, indent=2))

        # Save scan results to a JSON file
        filename = f"scan_results_{host}.json"
        with open(filename, 'w') as json_file:
            json.dump(port_status, json_file, indent=2)
        print(f"Scan results saved to: {filename}")

    except KeyboardInterrupt:
        print("\nScan canceled. Exiting...")

if __name__ == "__main__":
    try:
        while True:
            # Get user input for target IP address or range
            target = input("Enter target IP address or range (Ctrl+C to exit): ")

            # Perform TCP SYN analysis for the specified target
            perform_tcp_syn_analysis(target)
    except EOFError:
        pass  # Handle Ctrl+C exit

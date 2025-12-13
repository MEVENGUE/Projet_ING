import nmap
import json

class MyScanner:
    def __init__(self):
        self.nm = nmap.PortScanner()

    def perform_scan(self, target):
        try:
            # Perform service version detection and execute default NSE scripts
            self.nm.scan(hosts=target, arguments='-sV --script=default')

            # Get the first IP address from the list of scanned hosts
            host = list(self.nm.all_hosts())[0]

            # Print detailed results for the target
            print(f"Detailed results for {host}:")

            # Check if there are open ports for the host
            if self.nm[host].all_tcp():
                # Print open ports for the host
                open_ports = list(self.nm[host]['tcp'].keys())
                print(f"Open ports: {open_ports}")

                # Save scan results to a JSON file
                filename = f"scan_results_{host}.json"
                with open(filename, 'w') as json_file:
                    json.dump(self.nm[host], json_file)
                print(f"Scan results saved to: {filename}")
            else:
                print(f"No open ports found for {host}")

        except KeyboardInterrupt:
            print("\nScan canceled. Exiting...")

if __name__ == "__main__":
    scanner = MyScanner()

    try:
        while True:
            # Get user input for target IP address or range
            target = input("Enter target IP address or range (Ctrl+C to cancel): ")

            # Perform the scan for the specified target
            scanner.perform_scan(target)
    except EOFError:
        pass  # Handle Ctrl+C exit

#!/usr/bin/env python3

import os
import subprocess
import sys
import argparse

def run_simulation(test_type="functional"):
    """Run the SPI simulation using the CocoTB framework
    
    Args:
        test_type: Type of test to run ('functional' or 'performance')
    """
    if test_type == "functional":
        module = "hwsw_tb"
        print("Running SPI functional tests...")
    else:
        module = "perf_tb"
        print("Running SPI performance tests...")
    
    # Run the make command to execute cocotb tests with the selected module
    result = subprocess.run(["make", f"MODULE={module}"], capture_output=True, text=True)
    
    # Print output
    print(result.stdout)
    
    if result.returncode != 0:
        print("Simulation failed:")
        print(result.stderr)
        return False
    
    # For performance tests, show the results file paths
    if test_type == "performance" and result.returncode == 0:
        print("\nPerformance results saved to:")
        for filename in ["latency_results.csv", "throughput_results.csv"]:
            if os.path.exists(filename):
                print(f" - {os.path.abspath(filename)}")
    
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run SPI simulations")
    parser.add_argument("--test", "-t", choices=["functional", "performance"], 
                        default="functional", help="Test type to run (default: functional)")
    
    args = parser.parse_args()
    
    success = run_simulation(args.test)
    sys.exit(0 if success else 1)
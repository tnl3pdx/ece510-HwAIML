import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.utils import get_sim_time
import random
import csv
import os
from pathlib import Path

# Clock period in ns
CLK_PERIOD = 10

# Widths for SPI communication
CTOP_WIDTH = 8  # Controller to Peripheral data width
PTOP_WIDTH = 32  # Peripheral to Controller data width
PAUSE_CLK = 1  # Pause time
TRANSACTION_TIME = CTOP_WIDTH + PTOP_WIDTH + PAUSE_CLK + 4  # Total cycles for a transaction

async def initialize_test(dut):
    """Setup test with initial conditions and start clock"""
    # Create a clock and start it
    clock = Clock(dut.clk, CLK_PERIOD, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset the system
    dut.rst.value = 0
    dut.start_comm.value = 0
    dut.data_send_c.value = 0
    dut.data_send_p.value = 0
    dut.CS_in.value = 0  # For one peripheral, this is 0
    
    # Apply reset for a few clock cycles
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 1
    await ClockCycles(dut.clk, 5)

async def measure_transaction_latency(dut, data_c=0xA5, data_p=0x5A):
    """Measure the latency of a single transaction in clock cycles"""
    # Set the data to send
    dut.data_send_c.value = data_c
    dut.data_send_p.value = data_p
    
    # Record start time
    start_time = get_sim_time("ns")
    
    # Trigger communication start
    dut.start_comm.value = 1
    await ClockCycles(dut.clk, 1)
    dut.start_comm.value = 0
    
    # Wait for transaction to complete
    # For now, we'll use a simpler approach by waiting for a fixed number of cycles
    # In a more advanced setup, we could monitor specific signals to determine completion
    await ClockCycles(dut.clk, TRANSACTION_TIME)
    
    # Record end time
    end_time = get_sim_time("ns")
    
    # Check results
    controller_received = int(dut.CIPO_register.value)
    peripheral_received = int(dut.COPI_register_0.value)
    
    # Verify data was correctly transmitted
    assert controller_received == data_p, f"Controller received wrong data: expected 0x{data_p:02X}, got 0x{controller_received:02X}"
    assert peripheral_received == data_c, f"Peripheral received wrong data: expected 0x{data_c:02X}, got 0x{peripheral_received:02X}"
    
    # Return latency in clock cycles
    latency_ns = end_time - start_time
    latency_cycles = latency_ns / CLK_PERIOD
    
    return latency_cycles

async def measure_throughput(dut, num_transactions=100):
    """Measure throughput by sending multiple transactions in sequence"""
    # For throughput, we'll send multiple transactions and measure total time
    total_bits = num_transactions * (8 + 8)  # 8 bits controller to peripheral, 8 bits peripheral to controller
    
    # Record start time
    start_time = get_sim_time("ns")
    
    # Run multiple transactions
    for i in range(num_transactions):
        data_c = random.randint(0, 255)
        data_p = random.randint(0, 255)
        
        # Set the data to send
        dut.data_send_c.value = data_c
        dut.data_send_p.value = data_p
        
        # Trigger communication start
        dut.start_comm.value = 1
        await ClockCycles(dut.clk, 1)
        dut.start_comm.value = 0
        
        # Wait for transaction to complete
        await ClockCycles(dut.clk, TRANSACTION_TIME)
        
        # Verify data was correctly transmitted (optional for throughput test)
        controller_received = int(dut.CIPO_register.value)
        peripheral_received = int(dut.COPI_register_0.value)
        
        if controller_received != data_p or peripheral_received != data_c:
            dut._log.warning(f"Transaction {i} data mismatch!")
    
    # Record end time
    end_time = get_sim_time("ns")
    
    # Calculate throughput
    total_time_ns = end_time - start_time
    throughput_bits_per_sec = (total_bits / total_time_ns) * 1e9  # Convert ns to seconds
    
    return throughput_bits_per_sec

@cocotb.test()
async def test_latency(dut):
    """Measure the latency of SPI transactions"""
    await initialize_test(dut)
    
    dut._log.info("Starting latency measurements...")
    results = []
    
    # Perform multiple tests to get an average
    for i in range(10):
        data_c = random.randint(0, 255)
        data_p = random.randint(0, 255)
        
        latency = await measure_transaction_latency(dut, data_c, data_p)
        results.append(latency)
        dut._log.info(f"Transaction {i+1} latency: {latency:.2f} clock cycles")
    
    # Calculate average latency
    avg_latency = sum(results) / len(results)
    dut._log.info(f"Average transaction latency: {avg_latency:.2f} clock cycles ({avg_latency * CLK_PERIOD:.2f} ns)")
    
    # Save results to CSV
    with open('latency_results.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Transaction', 'Latency (cycles)', 'Latency (ns)'])
        for i, latency in enumerate(results):
            writer.writerow([i+1, f"{latency:.2f}", f"{latency * CLK_PERIOD:.2f}"])
        writer.writerow(['Average', f"{avg_latency:.2f}", f"{avg_latency * CLK_PERIOD:.2f}"])

@cocotb.test()
async def test_throughput(dut):
    """Measure the throughput of SPI transactions"""
    await initialize_test(dut)
    
    dut._log.info("Starting throughput measurements...")
    
    # Perform throughput measurements with different numbers of transactions
    transaction_counts = [10, 50, 100]
    results = []
    
    for num_trans in transaction_counts:
        throughput = await measure_throughput(dut, num_trans)
        results.append((num_trans, throughput))
        dut._log.info(f"Throughput with {num_trans} transactions: {throughput/1000:.2f} Kbps")
    
    # Save results to CSV
    with open('throughput_results.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Transaction Count', 'Throughput (bps)', 'Throughput (Kbps)'])
        for count, throughput in results:
            writer.writerow([count, f"{throughput:.2f}", f"{throughput/1000:.2f}"])
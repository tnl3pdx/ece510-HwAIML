import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.utils import get_sim_time

import matplotlib.pyplot as plt
import logging
import os
import random
from hashlib import sha256
import time

'''
    input  logic        clk,
    input  logic        rst_n,          // Active low reset
    input  logic        enable,         // Enable signal
    input  logic [7:0]  data_in,        // Input data stream (8 bits)
    input  logic        data_valid,     // Indicates valid data for data_in
    input  logic        end_of_file,    // Indicates end of input data
    output logic        ready,          // Indicates if SHA-256 is ready to accept data
    output logic [31:0] hash_out,      // Final hash output (256 bits)
    output logic        hash_valid      // Indicates hash output is valid
'''

CLK_PERIOD = 15  # Clock period in nanoseconds

class DebugMonitor:
    def __init__(self, dut, signals_to_monitor):
        self.dut = dut
        self.signals = signals_to_monitor
        self.trace_data = {sig: [] for sig in signals_to_monitor}
        self.time_stamps = []
        
    async def monitor(self, duration):
        """Capture signal values for visualization"""
        for _ in range(duration):
            await RisingEdge(self.dut.clk)
            
            self.time_stamps.append(get_sim_time('ns'))
            for sig in self.signals:
                self.trace_data[sig].append(
                    getattr(self.dut, sig).value.integer
                )
                
    def plot_waveforms(self):
        """Generate waveform plots"""
        fig, axes = plt.subplots(len(self.signals), 1, 
                                 figsize=(10, 2*len(self.signals)))
        
        if len(self.signals) == 1:
            axes = [axes]
            
        for ax, sig in zip(axes, self.signals):
            ax.step(self.time_stamps, self.trace_data[sig], where='post')
            ax.set_ylabel(sig)
            ax.grid(True)
            
        axes[-1].set_xlabel('Time (ns)')
        plt.tight_layout()
        plt.savefig('waveforms.png')
        

class PerformanceBenchmark:
    def __init__(self, sha256):
        self.sha256 = sha256
        self.start_time = None
        self.transactions = 0
        self.latencies = []
        
    async def run_benchmark(self, num_transactions=10, message_size=64):
        """Benchmark throughput and latency"""
        self.start_time = time.time()
        sim_start = get_sim_time('ns')

        for _ in range(num_transactions):
            message = generate_random_message(message_size)
            trans_start = get_sim_time('ns')
            
            # Send transaction
            await self.sha256.test_sequence(message)
            await self.sha256.reset()

            # Measure latency
            trans_end = get_sim_time('ns')
            self.latencies.append(trans_end - trans_start)
            self.transactions += 1
            
        # Calculate metrics
        wall_time = time.time() - self.start_time
        sim_time = get_sim_time('ns') - sim_start
        
        return {
            'throughput': self.transactions / wall_time,
            'avg_latency': sum(self.latencies) / len(self.latencies),
            'sim_speed': sim_time / wall_time,
            'max_latency': max(self.latencies),
            'min_latency': min(self.latencies)
        }
    
    

class SHA256Transaction:
    """SHA-256 Transaction Class for CocoTB"""
    
    def __init__(self, dut, clock_period=15):
        """Initialize with DUT reference and clock period"""
        self.dut = dut
        self.clock_period = clock_period
        self.message_index = 0
        self.received_hash = 0
        self.hash_received = False
        self.num_iterations = 0
        
        # Configure logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger("SHA256_Transaction")

    async def reset(self):
        """Reset the DUT and initialize signals"""
        # Initialize signals
        self.dut.rst_n.value = 0
        self.dut.data_in.value = 0
        self.dut.data_valid.value = 0
        self.dut.end_of_file.value = 0
        self.dut.enable.value = 0
        
        self.message_index = 0
        self.hash_received = False
        
        # Apply reset for one clock cycle
        await RisingEdge(self.dut.clk)
        self.dut.rst_n.value = 1
        await RisingEdge(self.dut.clk)
        
        self.logger.info("Reset complete")

    async def send_message(self, test_message):
        """Send a message to the SHA-256 module character by character"""
        # Enable the module
        self.dut.enable.value = 1
        
        # Set data_valid
        self.dut.data_valid.value = 1
        
        # Feed each character of the message
        while self.message_index < len(test_message):
            await RisingEdge(self.dut.clk)
            self.dut.data_in.value = ord(test_message[self.message_index])
            self.message_index += 1
            
            # Optional debug output for each byte
            self.logger.debug(f"Sending byte: 0x{ord(test_message[self.message_index-1]):02x} ('{test_message[self.message_index-1]}')")
        
        # Signal end of message
        self.dut.end_of_file.value = 1
        
        # One more clock cycle with valid data and end_of_file
        await RisingEdge(self.dut.clk)
        self.dut.data_valid.value = 0
        self.dut.end_of_file.value = 0
        
        # Wait for hash to be computed
        while self.dut.hash_valid.value == 0:
            await RisingEdge(self.dut.clk)
        
        self.logger.info(f"Message sent: '{test_message}'")
        
        # Collect hash
        await self.collect_hash()
        
        self.dut.enable.value = 0  # Disable after sending message
        self.message_index = 0  # Reset local message index  

    async def collect_hash(self):
        """Collect the 256-bit hash output from eight 32-bit blocks"""
        # Variables for hash collection
        block_count = 0
        timeout_cycles = 0
        max_timeout = 100000  # Maximum cycles to wait for complete hash
        
        # Initialize received hash and flag
        self.received_hash = 0
        self.hash_received = False
        
        # Wait for all hash blocks (8 x 32-bit words = 256 bits)
        while block_count < 8 and timeout_cycles < max_timeout:
            timeout_cycles += 1
            
            if self.dut.hash_valid.value == 1:
                # Get current hash word
                hash_word = int(self.dut.hash_out.value)
                
                # Calculate bit position for this block
                shift_amount = 32 * (7 - block_count)
                
                # Add this word to the received hash at the correct position
                self.received_hash |= (hash_word << shift_amount)
                
                self.logger.debug(f"Received hash block {block_count}: 0x{hash_word:08x}")
                block_count += 1
            
            await RisingEdge(self.dut.clk)
        
        if timeout_cycles >= max_timeout:
            self.logger.error(f"Timeout waiting for complete hash. Only received {block_count} blocks.")
            return False
        else:
            # Set flag indicating hash is complete
            self.hash_received = True
            self.logger.info("Complete 256-bit hash collected")
            return True

    async def test_sequence(self, test_message):
        """Run a complete test sequence"""
        self.num_iterations += 1
        self.logger.info(f"\n\nTest #{self.num_iterations}")
        
        # Wait until DUT is ready
        while self.dut.ready.value == 0:
            await RisingEdge(self.dut.clk)
        
        # Start the test
        self.logger.info(f"Starting SHA-256 hash calculation of: {test_message}")
        
        # Reset message index for this test
        self.message_index = 0
        
        # Send message
        await self.send_message(test_message)
        
        # Display the received hash
        self.logger.info(f"SHA-256 Hash received for message: {test_message}")
        self.logger.info(f"Hash (hex): 0x{self.received_hash:064x}")
        
        
        return self.received_hash
        

# Generate SHA-256 hash for a given message
def calculate_expected(message):
    """Calculate the expected SHA-256 hash for a given message"""
    if isinstance(message, str):
        message = message.encode('utf-8')  # Convert string to bytes
    elif isinstance(message, bytes):
        pass  # Already in bytes format
    else:
        raise ValueError("Message must be a string or bytes")

    # Calculate SHA-256 hash
    return int.from_bytes(sha256(message).digest(), 'big')

# Generate random message with adjustable length
def generate_random_message(length=64):
    """Generate a random message of specified length"""
    return ''.join(random.choice('0123456789abcdef') for _ in range(length))
    

@cocotb.test()  
async def init_test(dut):
    """Verify basic connectivity and reset behavior"""
    dut._log.info("Starting initial test")
    clock = Clock(dut.clk, CLK_PERIOD, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 0
    
    return SHA256Transaction(dut, clock_period=CLK_PERIOD)


@cocotb.test()  
async def functional_test(dut):
    """Test basic functionality"""
    
    sha = await init_test(dut)
    await sha.reset()

    # Generate random test messages
    test_messages = ['', 
                     'Hello, World!',
                     'Cocotb is great for testing!',
                     'SHA-256 hash function',
                     'This is a test message.']

    # Send test transactions
    for message in test_messages:
        expected = calculate_expected(message)  # Ensure expected hash is calculated
        result = await sha.test_sequence(message)
        print(f'Status: {("Pass" if result == expected else "Fail")} \t Test message: {message}')
        assert result == expected, \
            f"Output mismatch: expected 0x{expected:064x}, got 0x{result:064x} for message '{message}'"
        await sha.reset()

@cocotb.test()
async def random_message_test(dut):
    """Test with random messages of varying lengths"""
    sha = await init_test(dut)
    await sha.reset()

    # Generate random messages
    for _ in range(5):
        message = generate_random_message(random.randint(0, 1015))
        expected = calculate_expected(message)
        result = await sha.test_sequence(message)
        print(f'Status: {("Pass" if result == expected else "Fail")} \t Test message: {message[:50]}...')
        assert result == expected, \
            f"Output mismatch: expected 0x{expected:064x}, got 0x{result:064x} for message '{message}'"
        await sha.reset()

@cocotb.test()
async def performance_test(dut):
    """Run performance benchmarks"""
    
    sha = await init_test(dut)
    await sha.reset()
    
    message_sizes = [64, 80, 208, 608]

    benchmark = PerformanceBenchmark(sha)

    for message_size in message_sizes:
        results = await benchmark.run_benchmark(10, message_size=message_size)

        dut._log.info(f"\nPerformance Results for message size {message_size} bytes:")
        dut._log.info(f"Throughput: {results['throughput']:.2f} trans/sec")
        dut._log.info(f"Average Latency: {results['avg_latency']:.2f} ns")
        dut._log.info(f"Simulation Speed: {results['sim_speed']:.2f} ns/sec")
        dut._log.info(f"Max Latency: {results['max_latency']:.2f} ns")
        dut._log.info(f"Min Latency: {results['min_latency']:.2f} ns")

@cocotb.test()
async def debug_test(dut):
    """Test with debug monitoring"""
    monitor = DebugMonitor(dut, ['clk', 'rst_n', 'enable', 'data_in', 'data_valid', 'end_of_file', 'ready', 'hash_out', 'hash_valid'])
    
    # Start monitoring
    cocotb.start_soon(monitor.monitor(10000))
    
    # Run test scenario
    await functional_test(dut)
    
    # Generate debug outputs
    monitor.plot_waveforms()
    monitor.export_vcd()
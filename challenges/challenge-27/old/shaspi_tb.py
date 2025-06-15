import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.utils import get_sim_time
import random
import hashlib
import string
import logging
import csv
import os
from parameters import CLK_PERIOD, TRANSACTION_TIME

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("sha256_test")

# Constants
START_HASH = 0xFF
HASH_READY = 0xFFFF0000

class ShaSpiInterface:
    """Interface to the SHA-256 SPI module"""
    
    def __init__(self, dut):
        self.dut = dut
        self.hash_words = []
        self.message_length = 0
    
    async def send_start_signal(self):
        """Send the start signal (0xFF) to begin a hash transaction"""
        logger.debug("Sending start signal (0xFF)")
        self.dut.data_send_c.value = START_HASH
        self.dut.start_comm.value = 1
        await ClockCycles(self.dut.clk, TRANSACTION_TIME)
        self.dut.start_comm.value = 0
        
        # Send each integrer of the message length
        length_bytes = self.message_length.to_bytes(4, byteorder='big')
        print(f"Message length: {self.message_length} bytes, sending as bytes: {length_bytes}")
        for byte in length_bytes:
            logger.debug(f"Sending message length byte: 0x{byte:02x}")
            self.dut.data_send_c.value = byte
            self.dut.start_comm.value = 1
            await ClockCycles(self.dut.clk, TRANSACTION_TIME)
            self.dut.start_comm.value = 0
        
    
    async def send_character(self, char):
        """Send a character through the SPI interface"""
        byte_val = ord(char) if isinstance(char, str) else char
        logger.debug(f"Sending character: 0x{byte_val:02x}")
        self.dut.data_send_c.value = byte_val
        self.dut.start_comm.value = 1
        await ClockCycles(self.dut.clk, TRANSACTION_TIME)
        self.dut.start_comm.value = 0

    async def send_message(self, message):
        """Send the entire message through SPI"""
        # Start hash transaction
        self.message_length = len(message)
        await self.send_start_signal()
        
        # Send each character of the message
        for char in message:
            await self.send_character(char)
    
    async def wait_for_hash_ready(self, timeout_cycles=500000):
        """Wait until the hash is ready (CIPO_register shows 0xFFFF0000)"""
        logger.info("Waiting for hash ready signal...")
        for i in range(timeout_cycles):
            if int(self.dut.CIPO_register.value) == HASH_READY:
                logger.info(f"Hash ready signal received after {i} cycles")
                return True
            await ClockCycles(self.dut.clk, TRANSACTION_TIME)
        
        logger.error(f"Timeout waiting for hash ready signal after {timeout_cycles} cycles")
        return False
    
    async def receive_hash(self):
        """Receive the complete hash (8 32-bit words) and concatenate them"""
        # Reset hash storage
        self.hash_words = []
        
        # Wait for hash ready signal
        ready = await self.wait_for_hash_ready()
        if not ready:
            return None
        
        # Send 8 dummy transactions to get the hash words
        for i in range(8):
            # Trigger SPI transaction to get next hash word
            self.dut.data_send_c.value = 0x00  # Dummy byte
            self.dut.start_comm.value = 1
            await ClockCycles(self.dut.clk, TRANSACTION_TIME)
            self.dut.start_comm.value = 0
            
            # Read the hash word from CIPO_register
            word = int(self.dut.CIPO_register.value)
            self.hash_words.append(word)
            logger.info(f"Received hash word {i}: 0x{word:08x}")
        
        # Construct full 256-bit hash
        full_hash = 0
        for word in self.hash_words:
            full_hash = (full_hash << 32) | word
            
        return full_hash

async def init_test(dut):
    """Initialize the test environment"""
    clock = Clock(dut.clk, CLK_PERIOD, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset the system
    dut.rst.value = 1
    dut.start_comm.value = 0
    dut.data_send_c.value = 0
    dut.CS_in.value = 0  # For one peripheral
    
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    
    # Create results directory
    os.makedirs("results", exist_ok=True)
    
    return ShaSpiInterface(dut)

def generate_random_message(length):
    """Generate a random message of specified length"""
    chars = string.printable
    return ''.join(random.choice(chars) for _ in range(length))

def calculate_expected_hash(message):
    """Calculate the expected SHA-256 hash for a message"""
    if isinstance(message, str):
        message = message.encode('utf-8')
    return int(hashlib.sha256(message).hexdigest(), 16)

@cocotb.test()
async def test_single_hash_transaction(dut):
    """Test a single hash transaction with a known message and verify the result"""
    spi = await init_test(dut)
    
    # Use a known test message with a well-known hash result
    test_message = "abc"
    expected_hash = 0xBA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD
    
    logger.info(f"Starting single transaction test with message: '{test_message}'")
    logger.info(f"Expected hash: 0x{expected_hash:064x}")
    
    # Record start time
    start_time = get_sim_time(units="ns")
    
    await spi.send_message(test_message)
    
    # Wait for and receive hash
    received_hash = await spi.receive_hash()
    
    # Record end time
    end_time = get_sim_time(units="ns")
    processing_time = end_time - start_time
    processing_cycles = processing_time / CLK_PERIOD
    
    # 6. Log the results
    logger.info(f"Message: '{test_message}'")
    logger.info(f"Expected hash: 0x{expected_hash:064x}")
    logger.info(f"Received hash: 0x{received_hash:064x}")
    logger.info(f"Processing time: {processing_time} ns ({processing_cycles:.2f} cycles)")
    
    # 7. Verify the hash matches the expected value
    assert received_hash == expected_hash, f"Hash mismatch for message '{test_message}'"
    
    logger.info("Single transaction test passed successfully!")


#@cocotb.test()
async def test_specific_message_lengths(dut):
    """Test specific message lengths: 64, 80, 208, and 608 characters"""
    spi = await init_test(dut)
    
    # Create CSV file for performance metrics
    with open('results/specific_message_performance.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Message Length', 'Processing Time (ns)', 'Processing Time (cycles)'])
    
    specific_lengths = [64, 80, 208, 608]
    
    for length in specific_lengths:
        logger.info(f"Testing message of length {length}")
        
        # Generate random message
        message = generate_random_message(length)
        
        # Calculate expected hash
        expected_hash = calculate_expected_hash(message)
        
        # Record start time
        start_time = get_sim_time(units="ns")
        
        # Send message through SPI
        await spi.send_message(message)
        
        # Wait for and receive hash
        received_hash = await spi.receive_hash()
        
        # Record end time
        end_time = get_sim_time(units="ns")
        processing_time = end_time - start_time
        processing_cycles = processing_time / CLK_PERIOD
        
        # Compare hashes
        logger.info(f"Message length: {length}")
        logger.info(f"Expected hash: {expected_hash:064x}")
        logger.info(f"Received hash: {received_hash:064x}")
        logger.info(f"Processing time: {processing_time} ns ({processing_cycles:.2f} cycles)")
        
        # Save performance data
        with open('results/specific_message_performance.csv', 'a', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow([length, processing_time, processing_cycles])
        
        assert received_hash == expected_hash, f"Hash mismatch for message of length {length}"
        
        # Wait between tests
        await ClockCycles(dut.clk, 100)

#@cocotb.test()
async def test_random_message_lengths(dut):
    """Test random message lengths covering block counts 1 to 16"""
    spi = await init_test(dut)
    
    # Create CSV file for performance metrics
    with open('results/random_message_performance.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Message Length', 'Block Count', 'Processing Time (ns)', 'Processing Time (cycles)'])
    
    # SHA-256 block size is 512 bits = 64 bytes
    # 1 block can process ~55 bytes of message (with padding)
    # Test at least one message for each possible block count (1 to 16)
    block_sizes = {}
    for blocks in range(1, 17):
        min_size = (blocks - 1) * 64 + 1
        max_size = min(blocks * 64 - 9, 1015)  # -9 for padding (8 bytes length + 1 byte 0x80)
        size = random.randint(min_size, max_size)
        block_sizes[blocks] = size
    
    for blocks, length in sorted(block_sizes.items()):
        logger.info(f"Testing random message with {blocks} blocks, length {length}")
        
        # Generate random message
        message = generate_random_message(length)
        
        # Calculate expected hash
        expected_hash = calculate_expected_hash(message)
        
        # Record start time
        start_time = get_sim_time(units="ns")
        
        # Send message through SPI
        await spi.send_message(message)
        
        # Wait for and receive hash
        received_hash = await spi.receive_hash()
        
        # Record end time
        end_time = get_sim_time(units="ns")
        processing_time = end_time - start_time
        processing_cycles = processing_time / CLK_PERIOD
        
        # Compare hashes
        logger.info(f"Expected hash: {expected_hash:064x}")
        logger.info(f"Received hash: {received_hash:064x}")
        logger.info(f"Processing time: {processing_time} ns ({processing_cycles:.2f} cycles)")
        
        # Save performance data
        with open('results/random_message_performance.csv', 'a', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow([length, blocks, processing_time, processing_cycles])
        
        assert received_hash == expected_hash, f"Hash mismatch for message with {blocks} blocks, length {length}"
        
        # Wait between tests
        await ClockCycles(dut.clk, 100)

#@cocotb.test()
async def test_edge_cases(dut):
    """Test edge cases: empty message, single char, block boundaries"""
    spi = await init_test(dut)
    
    # Create CSV file for performance metrics
    with open('results/edge_cases_performance.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Case Description', 'Message Length', 'Processing Time (ns)', 'Processing Time (cycles)'])
    
    test_cases = [
        ("Empty message", ""),
        ("Single character", "a"),
        ("Block 1 boundary - 55 bytes", "a" * 55),
        ("Block 2 start - 56 bytes", "a" * 56),
        ("Exactly 64 bytes", "a" * 64),
        ("Block 2 boundary - 119 bytes", "a" * 119),
        ("Block 3 start - 120 bytes", "a" * 120),
        ("Maximum supported - 1015 bytes", "a" * 1015)
    ]
    
    for description, message in test_cases:
        logger.info(f"Testing edge case: {description}")
        
        # Calculate expected hash
        expected_hash = calculate_expected_hash(message)
        
        # Record start time
        start_time = get_sim_time(units="ns")
        
        # Send message through SPI
        await spi.send_message(message)
        
        # Wait for and receive hash
        received_hash = await spi.receive_hash()
        
        # Record end time
        end_time = get_sim_time(units="ns")
        processing_time = end_time - start_time
        processing_cycles = processing_time / CLK_PERIOD
        
        # Compare hashes
        logger.info(f"Message length: {len(message)}")
        logger.info(f"Expected hash: {expected_hash:064x}")
        logger.info(f"Received hash: {received_hash:064x}")
        logger.info(f"Processing time: {processing_time} ns ({processing_cycles:.2f} cycles)")
        
        # Save performance data
        with open('results/edge_cases_performance.csv', 'a', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow([description, len(message), processing_time, processing_cycles])
        
        assert received_hash == expected_hash, f"Hash mismatch for edge case: {description}"
        
        # Wait between tests
        await ClockCycles(dut.clk, 100)

#@cocotb.test()
async def test_performance_analysis(dut):
    """Analyze and visualize performance results"""
    try:
        import matplotlib.pyplot as plt
        import pandas as pd
        import numpy as np
        
        # Skip actual test - just analyze results
        if not os.path.exists('results/random_message_performance.csv'):
            logger.warning("Performance data not found, skipping analysis")
            return
        
        logger.info("Generating performance analysis graphs")
        
        # Load data from CSV files
        specific_df = pd.read_csv('results/specific_message_performance.csv')
        random_df = pd.read_csv('results/random_message_performance.csv')
        
        # Create plots
        plt.figure(figsize=(12, 10))
        
        # Plot processing time vs message length for specific lengths
        plt.subplot(2, 1, 1)
        plt.plot(specific_df['Message Length'], specific_df['Processing Time (cycles)'], 'o-')
        plt.xlabel('Message Length (bytes)')
        plt.ylabel('Processing Time (cycles)')
        plt.title('SHA-256 Performance - Specific Message Lengths')
        plt.grid(True)
        
        # Plot processing time vs block count
        plt.subplot(2, 1, 2)
        plt.plot(random_df['Block Count'], random_df['Processing Time (cycles)'], 'o-')
        plt.xlabel('Block Count')
        plt.ylabel('Processing Time (cycles)')
        plt.title('SHA-256 Performance - Block Count Impact')
        plt.grid(True)
        
        plt.tight_layout()
        plt.savefig('results/sha256_performance.png')
        logger.info("Performance analysis complete - check results directory")
    except ImportError:
        logger.warning("Could not generate performance graphs - matplotlib or pandas missing")
    except Exception as e:
        logger.error(f"Error in performance analysis: {e}")
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.regression import TestFactory
import random
from parameters import TRANSACTION_TIME, CLK_PERIOD


# Random


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

async def run_spi_transaction(dut, data_c, data_p, transaction_name=""):
    """Run a single SPI transaction with the provided data values"""
    dut._log.info(f"Starting {transaction_name} with Controller sending 0x{data_c:04X}, Peripheral sending 0x{data_p:04X}")
    
    # Set the data to send
    dut.data_send_c.value = data_c
    dut.data_send_p.value = data_p
    
    # Trigger communication start
    dut.start_comm.value = 1
    
    # Wait for transaction to complete
    # Based on parameters: LENGTH_SEND_C(8) + LENGTH_SEND_P(8) + PAUSE(1) + 4 = 21 cycles
    # Add some extra cycles for safety
    await ClockCycles(dut.clk, TRANSACTION_TIME)
    
    dut.start_comm.value = 0
    
    # Check results
    controller_received = int(dut.CIPO_register.value)
    peripheral_received = int(dut.COPI_register_0.value)
    
    dut._log.info(f"Transaction results: Controller received 0x{controller_received:04X}, Peripheral received 0x{peripheral_received:04X}")
    
    # Return values for assertion checking
    return controller_received, peripheral_received

@cocotb.test()
async def test_spi_basic_transaction(dut):
    """Test a basic SPI transaction between controller and peripheral"""
    await initialize_test(dut)
    
    # Define test data
    test_data_controller = 0xA5  # 10100101
    test_data_peripheral = 0x5AA55152  # 10101010101010100101010101010010
    
    # Run transaction
    controller_rx, peripheral_rx = await run_spi_transaction(dut, test_data_controller, test_data_peripheral, "basic transaction")
    
    # Verify data was correctly transmitted in both directions
    assert controller_rx == test_data_peripheral, f"Controller received wrong data: expected 0x{test_data_peripheral:04X}, got 0x{controller_rx:04X}"
    assert peripheral_rx == test_data_controller, f"Peripheral received wrong data: expected 0x{test_data_controller:04X}, got 0x{peripheral_rx:04X}"

@cocotb.test()
async def test_spi_multiple_transactions(dut):
    """Test multiple sequential SPI transactions"""
    await initialize_test(dut)
    
    test_data = [
        (0x55, 0xAAAAAAAA),  # First transaction data (controller, peripheral)
        (0x33, 0xCCCCCCCC),  # Second transaction data
        (0xFF, 0x00000000),  # Third transaction data
        (0x0F, 0xF0F0F0F0),  # Fourth transaction data
    ]
    
    for i, (data_c, data_p) in enumerate(test_data):
        controller_rx, peripheral_rx = await run_spi_transaction(dut, data_c, data_p, f"transaction {i+1}")
        
        assert controller_rx == data_p, f"Transaction {i+1}: Controller received wrong data"
        assert peripheral_rx == data_c, f"Transaction {i+1}: Peripheral received wrong data"
        
        # Wait a bit between transactions
        await ClockCycles(dut.clk, 10)

@cocotb.test()
async def test_spi_reset_during_transaction(dut):
    """Test SPI behavior when reset occurs during transaction"""
    await initialize_test(dut)
    
    # Start a transaction
    dut.data_send_c.value = 0x55
    dut.data_send_p.value = 0xCCAA33FF
    
    dut.start_comm.value = 1
    await ClockCycles(dut.clk, 2)
    dut.start_comm.value = 0
    
    # Wait for a few cycles and then assert reset
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 1
    await ClockCycles(dut.clk, 5)
    
    # Start a new transaction after reset
    controller_rx, peripheral_rx = await run_spi_transaction(dut, 0x33, 0x33FFCCFF, "post-reset transaction")
    
    # Verify the new transaction works correctly after reset
    assert controller_rx == 0x33FFCCFF, f"Controller received wrong data after reset"
    assert peripheral_rx == 0x33, f"Peripheral received wrong data after reset"

@cocotb.test()
async def test_spi_random_data(dut):
    """Test SPI communication with random data values"""
    await initialize_test(dut)
    
    # Run multiple tests with random data
    for i in range(5):
        data_c = random.randint(0, 255)  # Random 8-bit value for controller
        data_p = random.randint(0, 2^32 - 1)  # Random 32-bit value for peripheral
        
        controller_rx, peripheral_rx = await run_spi_transaction(dut, data_c, data_p, f"random test {i+1}")
        
        assert controller_rx == data_p, f"Random test {i+1}: Controller received wrong data"
        assert peripheral_rx == data_c, f"Random test {i+1}: Peripheral received wrong data"
        
        await ClockCycles(dut.clk, 10)  # Wait between transactions



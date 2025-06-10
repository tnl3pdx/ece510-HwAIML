// Testbench for SHA-256 SystemVerilog Implementation
`timescale 1ns/1ps

module tb_sha256();
    // Parameters
    parameter CLK_PERIOD = 15;    // Clock period in nanoseconds
    
    // DUT Signals
    logic           clk;
    logic           rst_n;
    logic [7:0]     data_in;
    logic           data_valid;
    logic           end_of_file;
    logic           ready;
    logic [31:0]    hash_out;
    logic           hash_valid;
    logic           enable;
    
    // Test data
    string test_message;
    bit [255:0] expected_hash;
    int message_index;
    int printIndex;
    int num_iterations;
    logic [255:0] received_hash;
    logic hash_received;
    logic iffail;
    
    
    // Instantiate DUT
    sha256_reduced dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid(data_valid),
        .end_of_file(end_of_file),
        .ready(ready),
        .hash_out(hash_out),
        .hash_valid(hash_valid),
        .enable(enable)
    );
    
    // Clock generation
    always begin
        clk = 0;
        #(CLK_PERIOD/2);
        clk = 1;
        #(CLK_PERIOD/2);
    end

    
    task automatic reset();
        // Initialize signals
        rst_n = 0;
        data_in = 0;
        data_valid = 0;
        end_of_file = 0;
        message_index = 0;
        hash_received = 0;
        enable = 0;

        rst_n = 0;
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

    task automatic sendMsg();
        enable = 1;
        
        // Feed each character of the message
        data_valid = 1;
        while (message_index < test_message.len()) begin
            @(posedge clk);
            data_in = test_message[message_index];
            message_index++;
            
            printIndex += 1;
            // Display bytes being sent
            //$display("Sending byte: 0x%h ('%s')(#'%d')", data_in, string'(data_in), printIndex);
        end
        
        // Signal end of message
        end_of_file = 1;
        
        // One more cycle with valid data and end_of_file
        @(posedge clk);
        data_valid = 0;
        end_of_file = 0;
        
        // Wait for hash to be computed
        while (!hash_valid) begin
            @(posedge clk);
        end

        // Store the received hash
        collectHash();

        enable = 0;
        printIndex = 0;
        message_index = 0;
    endtask

    task automatic collectHash();
        // Variables to collect hash blocks
        int block_count = 0;
        int timeout_cycles = 0;
        int max_timeout = 10000; // Maximum cycles to wait for complete hash
        
        // Initialize received hash and flag
        received_hash = 0;
        hash_received = 0;
        
        // Wait for hash blocks
        while (block_count < 8 && timeout_cycles < max_timeout) begin
            timeout_cycles = timeout_cycles + 1;
            
            if (hash_valid) begin
                // Concatenate this hash block to the received hash
                received_hash[255 - 32*block_count -: 32] = hash_out;
                //$display("Received hash block %0d: %h", block_count, hash_out);
                block_count = block_count + 1;
            end
            @(posedge clk);
        end
        
        if (timeout_cycles >= max_timeout) begin
            $display("ERROR: Timeout waiting for complete hash. Only received %0d blocks.", block_count);
        end else begin
            // Set flag indicating hash is complete
            hash_received = 1;
            $display("Complete 256-bit hash collected");
        end

        @(posedge clk);
    endtask

    task automatic formatVerify(input bit [255:0] expected);

        // Format the hash in the standard hex representation
        $write("Hash (formatted): ");
        for (int i = 0; i < 256; i += 8) begin
            $write("%02x", received_hash[255-i -: 8]);
        end
        $display("");
        // Calculate expected hash for comparison (this is the actual expected hash for "Hello, SHA-256!")
        // You can obtain this from an online SHA-256 calculator or command line tools
        $display("Expected hash:    %h", expected);
        
        // Verify hash
        if (received_hash === expected) begin
            $display("PASS: Hash matches expected value");
        end else begin
            $display("FAIL: Hash does not match expected value");
            iffail = 1;
        end
        printIndex = 0;
    endtask

    task automatic testSequence(input string msg, input bit [255:0] hash);
        $display("\n\n\nTest #%d", ++num_iterations);

        // Wait until DUT is ready to receive data
        wait(ready);
        
        // Send each character to the SHA-256 module
        $display("Starting SHA-256 hash calculation of: %s", msg);

        sendMsg();
        
        // Display the received hash
        $display("SHA-256 Hash received for message: %s", msg);
        $display("Hash (hex): %h", received_hash);
        
        formatVerify(hash);
    endtask

    // Reset and test sequence
    initial begin
	$timeformat(-9, 2, " ns", 20);
        num_iterations = 0;

        // Reset DUT
        reset();

/*
        test_message = "YxwTU;Y.9?#";
        expected_hash = 256'hc21919e5b04c8a06164b68bd57293a97c7ef18d7371feea68f3872cdcb23b743;

        testSequence(test_message, expected_hash);
        reset();
    

        test_message = "YxwTU;Y.9?#Z8]]Tvs(DW?{R-1r6/V.}/qa,CH5Y[Fq6{z}&P{=-KHkk";
        expected_hash = 256'h2b9a7bd7ff27dbc3031b4d236dd58604411ef5e16d0324226ab360c9b3cf3818;

        testSequence(test_message, expected_hash);
        reset();

        test_message = "YxwTU;Y.9?#Z8]]Tvs(DW?{R-1r6/V.}/qa,CH5Y[Fq6{z}&P{=-KHkkssssssssssssssssssssssssssdddawadddddddddddddddddddddddddddddddddwd";
        expected_hash = 256'h03aecb55e5fca4a2154fe712b6fd25ab53d49d0a67483ffae13525e8946f3899;

        testSequence(test_message, expected_hash);
        reset();
*/
        test_message = "rem ipsum dolor sit amet, consectetur adipiscing elit. Nunc feugiat purus at odio pretium, et condimentum enim interdum. Ut faucibus placerat arcu, ac mollis enim tincidunt a. Mauris sed gravida massa, vel aliquam enim. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. In hac habitasse platea dictumst. Duis at faucibus nisi. Integer leo ipsum, lobortis ac leo vel, fringilla vestibulum turpis. Donec aliquam cursus odio ac viverra. Quisque sollicitudin, est non aliquet laoreet, felis ligula viverra arcu, sed ultricies mi urna at mi.  Vivamus vel commodo turpis. Sed hendrerit commodo est et tempor. Donec fermentum enim at malesuada dictum. Nulla blandit ullamcorper pellentesque. Pellentesque id finibus mauris. Morbi congue est vel purus congue maximus. Donec ac ipsum pharetra, commodo ante a, luctus ipsum. Ut aliquam libero erat, at porta metus viverra id. In ac diam et odio placerat vestibulum. Pdddddddddddddd";
        expected_hash = 256'h72f9e20f6408e16ea9e08b9c82e299519aea38713fc1379b99b39441b2143e4e;

        testSequence(test_message, expected_hash);
        reset();
        // Check if any test failed
        if (iffail) begin
            $display("A Test failed, check the output above for details.");
        end else begin
            $display("All tests passed successfully!");
        end

	$display("Simulation Parameters: \n %d ns clock period\nCurrent Clock: %t", CLK_PERIOD, $realtime);
        
        // Finish simulation after some time
        #(CLK_PERIOD*20);
        $finish;
    end
    
    // Monitor for new hash outputs
    always @(posedge clk) begin
        if (hash_valid && !hash_received) begin
            $display("New hash value detected: %h", hash_out);
        end
    end
    
    // Display cycle count
    int cycle_count = 0;
    always @(posedge clk) begin
        cycle_count++;
    end
    
    // Save waveforms
    initial begin
        $dumpfile("sha256_waves.vcd");
        $dumpvars(0, tb_sha256);
    end

endmodule
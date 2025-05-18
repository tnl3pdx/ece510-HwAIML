// Testbench for SHA-256 SystemVerilog Implementation
`timescale 1ns/1ps

module tb_sha256();
    // Parameters
    parameter CLK_PERIOD = 5;    // 200 MHz clock
    
    // DUT Signals
    logic           clk;
    logic           rst_n;
    logic [7:0]     data_in;
    logic           data_valid;
    logic           end_of_file;
    logic           ready;
    logic [255:0]   hash_out;
    logic           hash_valid;
    logic           enable;
    
    // Test data
    //string test_message = "YxwTU;Y.9?#Z8]]Tvs(DW?{R-1r6/V.}/qa,CH5Y[Fq6{z}&P{=-KHkk";
    //bit [255:0] expected_hash = 256'h2b9a7bd7ff27dbc3031b4d236dd58604411ef5e16d0324226ab360c9b3cf3818;
    string test_message = "YxwTU;Y.9?#Z8]]Tvs(DW?{R-1r6/V.}/qa,CH5Y[Fq6{z}&P{=-KHkkssssssssssssssssssssssssssdddawadddddddddddddddddddddddddddddddddwd";
    bit [255:0] expected_hash = 256'h03aecb55e5fca4a2154fe712b6fd25ab53d49d0a67483ffae13525e8946f3899;
;
    //string test_message = "YxwTU;Y.9?#";
    //bit [255:0] expected_hash = 256'hc21919e5b04c8a06164b68bd57293a97c7ef18d7371feea68f3872cdcb23b743;
    int message_index;
    int printIndex;
    logic [255:0] received_hash;
    logic hash_received;
    
    
    // Instantiate DUT
    sha256_top dut (
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
            $display("Sending byte: 0x%h ('%s')(#'%d')", data_in, string'(data_in), printIndex);
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
        received_hash = hash_out;
        hash_received = 1;

        enable = 0;
    endtask

    task automatic formatVerify();
        // Format the hash in the standard hex representation
        $write("Hash (formatted): ");
        for (int i = 0; i < 256; i += 8) begin
            $write("%02x", received_hash[255-i -: 8]);
        end
        $display("");
        // Calculate expected hash for comparison (this is the actual expected hash for "Hello, SHA-256!")
        // You can obtain this from an online SHA-256 calculator or command line tools
        $display("Expected hash:    %h", expected_hash);
        
        // Verify hash
        if (received_hash === expected_hash) begin
            $display("PASS: Hash matches expected value");
        end else begin
            $display("FAIL: Hash does not match expected value");
        end
        printIndex = 0;
    endtask

    // Reset and test sequence
    initial begin
  
        // Apply reset
        reset();
        
        // Wait until DUT is ready to receive data
        wait(ready);
        
        // Send each character to the SHA-256 module
        $display("Starting SHA-256 hash calculation of: %s", test_message);

        sendMsg();
        
        // Display the received hash
        $display("SHA-256 Hash received for message: %s", test_message);
        $display("Hash (hex): %h", received_hash);
        
        formatVerify();

        // Back to back test

        // Apply reset
        reset();
        
        // Wait until DUT is ready to receive data
        wait(ready);
        
        // Send each character to the SHA-256 module
        $display("Starting SHA-256 hash calculation of: %s", test_message);

        sendMsg();
        
        // Display the received hash
        $display("SHA-256 Hash received for message: %s", test_message);
        $display("Hash (hex): %h", received_hash);
        
        formatVerify();
        
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
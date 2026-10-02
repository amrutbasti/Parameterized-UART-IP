`timescale 1ns/1ps

module UART_top_tb;

    parameter integer CLK_FREQ      = 100;
    parameter integer BAUD_RATE     = 10;
    parameter integer DATA_WIDTH    = 8;
    parameter integer STOP_BITS     = 1;
    parameter integer ODD_PARITY    = 0;
    parameter integer PARITY_ENABLE = 1;

    reg clk;
    reg reset;

    reg [DATA_WIDTH-1:0] tx_data;
    reg tx_start;

    wire tx;
    wire tx_busy;
    wire tx_done;

    wire rx;
    wire [DATA_WIDTH-1:0] rx_data;
    wire rx_done;
    wire parity_error;
    wire framing_error;

    integer test_count;
    integer pass_count;
    integer fail_count;

    assign rx = tx;

    UART_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BITS(STOP_BITS),
        .ODD_PARITY(ODD_PARITY),
        .PARITY_ENABLE(PARITY_ENABLE)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .parity_error(parity_error),
        .framing_error(framing_error)
    );

    always #5 clk = ~clk;

    task send_byte; 
    input [DATA_WIDTH-1:0] data;
    begin
     
        wait (!tx_busy);
        
        @(negedge clk);

        tx_data  = data;
        tx_start = 1'b1;

        @(negedge clk);

        tx_start = 1'b0;
    end
endtask
       

    task check_byte;
        input [DATA_WIDTH-1:0] expected_data;
        begin
            test_count = test_count + 1;
            @(posedge rx_done);

            if (rx_data !== expected_data) begin
                fail_count = fail_count + 1;
                $display("FAIL: Expected = %h, Received = %h", expected_data, rx_data);
            end
            else if (parity_error) begin
                fail_count = fail_count + 1;
                $display("FAIL: Unexpected parity error for %h", expected_data);
            end
            else if (framing_error) begin
                fail_count = fail_count + 1;
                $display("FAIL: Unexpected framing error for %h", expected_data);
            end
            else begin
                pass_count = pass_count + 1;
                $display("PASS: Expected = %h, Received = %h", expected_data, rx_data);
            end
        end
    endtask

    task run_test;
        input [DATA_WIDTH-1:0] data;
        begin
            fork
                send_byte(data);
                check_byte(data);
            join
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        tx_data = {DATA_WIDTH{1'b0}};
        tx_start = 1'b0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        repeat (2) @(posedge clk);
        reset = 1'b0;
        repeat (2) @(posedge clk);

        run_test(8'h55);
        run_test(8'hAA);
        run_test(8'hA5);
        run_test(8'h00);

        repeat (10) @(posedge clk);

        $display("");
        $display("========================================");
        $display("UART TOP VERIFICATION REPORT");
        $display("Total Tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("VERIFICATION FAILED");

        $finish;
    end

    initial begin
        $dumpfile("UART_top_tb.vcd");
        $dumpvars(0, UART_top_tb);
    end

endmodule

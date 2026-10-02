`timescale 1ns/1ps

module baud_gen_tb;

    parameter integer CLK_FREQ  = 100;
    parameter integer BAUD_RATE = 10;

    localparam integer DIVISOR  = CLK_FREQ / BAUD_RATE;
    localparam integer NUM_TICKS = 5;

    reg clk;
    reg reset;
    reg enable;
    wire baud_tick;

    integer cycle_count;
    integer tick_count;
    integer error_count;

    baud_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .baud_tick(baud_tick)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset || !enable) begin
            cycle_count = 0;
        end
        else begin
            cycle_count = cycle_count + 1;

            if (baud_tick) begin
                if (cycle_count != DIVISOR) begin
                    $display("FAIL: baud_tick interval = %0d cycles, expected %0d at time %0t",
                             cycle_count, DIVISOR, $time);
                    error_count = error_count + 1;
                end
                else begin
                    $display("PASS: baud_tick %0d after %0d cycles at time %0t",
                             tick_count + 1, cycle_count, $time);
                end

                tick_count = tick_count + 1;
                cycle_count = 0;
            end
        end
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        enable = 1'b0;
        cycle_count = 0;
        tick_count = 0;
        error_count = 0;

        repeat (2) @(posedge clk);
        reset = 1'b0;
        enable = 1'b1;

        wait (tick_count == NUM_TICKS);

        if (error_count == 0)
            $display("BAUD GENERATOR TEST PASSED");
        else
            $display("BAUD GENERATOR TEST FAILED: %0d errors", error_count);

        $finish;
    end

    initial begin
        $dumpfile("baud_gen_tb.vcd");
        $dumpvars(0, baud_gen_tb);
    end

endmodule
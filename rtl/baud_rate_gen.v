`timescale 1ns/1ps

module baud_gen #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire reset,
    input  wire enable,

    output reg baud_tick
);

    localparam integer DIVISOR =
        (CLK_FREQ / BAUD_RATE);

    localparam integer COUNT_WIDTH =
        (DIVISOR <= 1) ? 1 : $clog2(DIVISOR);

    reg [COUNT_WIDTH-1:0] counter;

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            counter   <= {COUNT_WIDTH{1'b0}};
            baud_tick <= 1'b0;
        end

        else if (!enable) begin
            counter   <= {COUNT_WIDTH{1'b0}};
            baud_tick <= 1'b0;
        end

        else if (DIVISOR <= 1) begin
            counter   <= {COUNT_WIDTH{1'b0}};
            baud_tick <= 1'b1;
        end

        else if (counter == DIVISOR-1) begin
            counter   <= {COUNT_WIDTH{1'b0}};
            baud_tick <= 1'b1;
        end

        else begin
            counter   <= counter + 1'b1;
            baud_tick <= 1'b0;
        end

    end

endmodule
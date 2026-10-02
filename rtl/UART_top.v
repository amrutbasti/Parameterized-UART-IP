`timescale 1ns/1ps

module UART_top #(
    parameter integer CLK_FREQ      = 100_000_000,
    parameter integer BAUD_RATE     = 115200,
    parameter integer DATA_WIDTH    = 8,
    parameter integer PARITY_ENABLE = 1,
    parameter integer ODD_PARITY    = 0,
    parameter integer STOP_BITS     = 1
)(
    input wire clk,
    input wire reset,

    input wire [DATA_WIDTH-1:0] tx_data,
    input wire tx_start,

    output wire tx,
    output wire tx_busy,
    output wire tx_done,

    input wire rx,

    output wire [DATA_WIDTH-1:0] rx_data,
    output wire rx_done,

    output wire parity_error,
    output wire framing_error
);

    wire baud_tick;

    baud_gen #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    )
    BAUD_GEN_INST (
        .clk       (clk),
        .reset     (reset),
        .enable    (1'b1),
        .baud_tick (baud_tick)
    );

    UART_tx #(
        .CLK_FREQ      (CLK_FREQ),
        .BAUD_RATE     (BAUD_RATE),
        .DATA_WIDTH    (DATA_WIDTH),
        .PARITY_ENABLE (PARITY_ENABLE),
        .ODD_PARITY    (ODD_PARITY),
        .STOP_BITS     (STOP_BITS)
    )
    TX_INST (
        .clk       (clk),
        .reset     (reset),
        .baud_tick (baud_tick),

        .tx_start  (tx_start),
        .tx_data   (tx_data),

        .tx        (tx),
        .busy      (tx_busy),
        .tx_done   (tx_done)
    );

    UART_rx #(
        .CLK_FREQ      (CLK_FREQ),
        .BAUD_RATE     (BAUD_RATE),
        .DATA_WIDTH    (DATA_WIDTH),
        .PARITY_ENABLE (PARITY_ENABLE),
        .ODD_PARITY    (ODD_PARITY),
        .STOP_BITS     (STOP_BITS)
    )
    RX_INST (
        .clk           (clk),
        .reset         (reset),
        .rx            (rx),

        .rx_data       (rx_data),
        .rx_done       (rx_done),

        .parity_error  (parity_error),
        .framing_error (framing_error)
    );

endmodule
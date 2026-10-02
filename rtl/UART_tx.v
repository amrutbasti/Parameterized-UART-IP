`timescale 1ns/1ps

module UART_tx #(
    parameter integer CLK_FREQ      = 100_000_000,
    parameter integer BAUD_RATE     = 115200,
    parameter integer DATA_WIDTH    = 8,
    parameter integer PARITY_ENABLE = 1,
    parameter integer ODD_PARITY    = 0,
    parameter integer STOP_BITS     = 1
)(
    input  wire clk,
    input  wire reset,
    input  wire baud_tick,

    input  wire tx_start,
    input  wire [DATA_WIDTH-1:0] tx_data,

    output reg tx,
    output reg busy,
    output reg tx_done
);

    localparam [2:0]
        IDLE   = 3'd0,
        START  = 3'd1,
        DATA   = 3'd2,
        PARITY = 3'd3,
        STOP   = 3'd4;

    localparam integer BIT_COUNT_WIDTH =
        (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH);

    localparam integer STOP_COUNT_WIDTH =
        (STOP_BITS <= 1) ? 1 : $clog2(STOP_BITS);

    reg [2:0] state;

    reg [DATA_WIDTH-1:0] shift_reg;

    reg [BIT_COUNT_WIDTH-1:0] bit_count;

    reg [STOP_COUNT_WIDTH-1:0] stop_bit_count;

    reg parity_bit;


    always @(posedge clk or posedge reset) begin

        if (reset) begin

            state <= IDLE;

            shift_reg <= {DATA_WIDTH{1'b0}};

            bit_count <= {BIT_COUNT_WIDTH{1'b0}};

            stop_bit_count <= {STOP_COUNT_WIDTH{1'b0}};

            parity_bit <= 1'b0;

            tx <= 1'b1;

            busy <= 1'b0;

            tx_done <= 1'b0;

        end

        else begin

            tx_done <= 1'b0;

            case (state)

                IDLE: begin

                    tx   <= 1'b1;
                    busy <= 1'b0;

                    if (tx_start) begin

                        shift_reg      <= tx_data;

                        bit_count      <= {BIT_COUNT_WIDTH{1'b0}};

                        stop_bit_count <= {STOP_COUNT_WIDTH{1'b0}};

                        busy <= 1'b1;

                        if (PARITY_ENABLE) begin

                            if (ODD_PARITY)
                                parity_bit <= ~(^tx_data);
                            else
                                parity_bit <= ^tx_data;

                        end

                        state <= START;

                    end

                end

                START: begin

                    tx   <= 1'b0;
                    busy <= 1'b1;

                    if (baud_tick)
                        state <= DATA;

                end

                DATA: begin

                    tx   <= shift_reg[0];
                    busy <= 1'b1;

                    if (baud_tick) begin

                        shift_reg <= shift_reg >> 1;

                        if (bit_count == DATA_WIDTH-1) begin

                            if (PARITY_ENABLE)
                                state <= PARITY;
                            else
                                state <= STOP;

                        end

                        else begin

                            bit_count <= bit_count + 1'b1;

                        end

                    end

                end

                PARITY: begin

                    tx   <= parity_bit;
                    busy <= 1'b1;

                    if (baud_tick)
                        state <= STOP;

                end

                STOP: begin

                    tx   <= 1'b1;
                    busy <= 1'b1;

                    if (baud_tick) begin

                        if (stop_bit_count == STOP_BITS-1) begin

                            tx_done <= 1'b1;

                            busy <= 1'b0;

                            state <= IDLE;

                            stop_bit_count <=
                                {STOP_COUNT_WIDTH{1'b0}};

                        end

                        else begin

                            stop_bit_count <=
                                stop_bit_count + 1'b1;

                        end

                    end

                end


                default: begin

                    state <= IDLE;

                    tx    <= 1'b1;

                    busy  <= 1'b0;

                end

            endcase

        end

    end

endmodule
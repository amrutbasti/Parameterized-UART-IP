`timescale 1ns/1ps

module UART_rx #(
    parameter integer CLK_FREQ      = 100_000_000,
    parameter integer BAUD_RATE     = 115200,
    parameter integer DATA_WIDTH    = 8,
    parameter integer PARITY_ENABLE = 1,
    parameter integer ODD_PARITY    = 0,
    parameter integer STOP_BITS     = 1
)(
    input wire clk,
    input wire reset,
    input wire rx,

    output reg [DATA_WIDTH-1:0] rx_data,
    output reg rx_done,
    output reg parity_error,
    output reg framing_error
);

    localparam integer BAUD_DIV =
        (CLK_FREQ / BAUD_RATE);

    localparam integer HALF_BIT =
        (BAUD_DIV < 2) ? 1 : (BAUD_DIV / 2);

    localparam integer BAUD_COUNT_WIDTH =
        (BAUD_DIV <= 1) ? 1 : $clog2(BAUD_DIV);

    localparam integer BIT_COUNT_WIDTH =
        (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH);

    localparam integer STOP_COUNT_WIDTH =
        (STOP_BITS <= 1) ? 1 : $clog2(STOP_BITS);

    localparam [2:0]
        IDLE        = 3'd0,
        START_CHECK = 3'd1,
        DATA        = 3'd2,
        PARITY      = 3'd3,
        STOP        = 3'd4;

    reg rx_sync_1;
    reg rx_sync_2;
    reg rx_sync_d;

    reg [2:0] state;

    reg [BAUD_COUNT_WIDTH-1:0] baud_count;

    reg [BIT_COUNT_WIDTH-1:0] bit_count;

    reg [STOP_COUNT_WIDTH-1:0] stop_bit_count;

    reg [DATA_WIDTH-1:0] rx_shift_reg;

    wire expected_parity;

    assign expected_parity =
        ODD_PARITY ? ~(^rx_shift_reg) : (^rx_shift_reg);

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            rx_sync_1 <= 1'b1;
            rx_sync_2 <= 1'b1;
            rx_sync_d <= 1'b1;

        end

        else begin

            rx_sync_1 <= rx;

            rx_sync_2 <= rx_sync_1;

            rx_sync_d <= rx_sync_2;

        end

    end

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            state <= IDLE;

            baud_count <=
                {BAUD_COUNT_WIDTH{1'b0}};

            bit_count <=
                {BIT_COUNT_WIDTH{1'b0}};

            stop_bit_count <=
                {STOP_COUNT_WIDTH{1'b0}};

            rx_shift_reg <=
                {DATA_WIDTH{1'b0}};

            rx_data <=
                {DATA_WIDTH{1'b0}};

            rx_done <= 1'b0;

            parity_error <= 1'b0;

            framing_error <= 1'b0;

        end

        else begin

            rx_done <= 1'b0;


            case (state)

                IDLE: begin

                    baud_count <=
                        {BAUD_COUNT_WIDTH{1'b0}};

                    bit_count <=
                        {BIT_COUNT_WIDTH{1'b0}};

                    stop_bit_count <=
                        {STOP_COUNT_WIDTH{1'b0}};

                    if (rx_sync_d && !rx_sync_2) begin

                        state <= START_CHECK;

                        baud_count <=
                            {BAUD_COUNT_WIDTH{1'b0}};

                        parity_error <= 1'b0;

                        framing_error <= 1'b0;

                    end

                end

                START_CHECK: begin

                    if (baud_count == HALF_BIT-1) begin

                        baud_count <=
                            {BAUD_COUNT_WIDTH{1'b0}};

                        if (!rx_sync_2) begin

                            state <= DATA;

                            bit_count <=
                                {BIT_COUNT_WIDTH{1'b0}};

                        end

                        else begin

                            state <= IDLE;

                        end

                    end

                    else begin

                        baud_count <= baud_count + 1'b1;

                    end

                end

                DATA: begin

                    if (baud_count == BAUD_DIV-1) begin

                        baud_count <=
                            {BAUD_COUNT_WIDTH{1'b0}};

                        rx_shift_reg[bit_count] <= rx_sync_2;


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

                    else begin

                        baud_count <= baud_count + 1'b1;

                    end

                end

                PARITY: begin

                    if (baud_count == BAUD_DIV-1) begin

                        baud_count <=
                            {BAUD_COUNT_WIDTH{1'b0}};


                        if (rx_sync_2 != expected_parity)
                            parity_error <= 1'b1;


                        state <= STOP;

                    end

                    else begin

                        baud_count <= baud_count + 1'b1;

                    end

                end

                STOP: begin

                    if (baud_count == BAUD_DIV-1) begin

                        baud_count <=
                            {BAUD_COUNT_WIDTH{1'b0}};

                        if (rx_sync_2 != 1'b1)
                            framing_error <= 1'b1;


                        if (stop_bit_count == STOP_BITS-1) begin

                            rx_data <= rx_shift_reg;

                            rx_done <= 1'b1;

                            stop_bit_count <=
                                {STOP_COUNT_WIDTH{1'b0}};

                            state <= IDLE;

                        end

                        else begin

                            stop_bit_count <=
                                stop_bit_count + 1'b1;

                        end

                    end

                    else begin

                        baud_count <= baud_count + 1'b1;

                    end

                end


                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule
`timescale 1ns/1ps

module UART_rx_tb;

parameter CLK_FREQ = 100;
parameter BAUD_RATE = 10;
parameter DATA_WIDTH = 8;
parameter PARITY_ENABLE = 1; 
parameter ODD_PARITY = 0;
parameter STOP_BITS = 1;

localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;

reg clk;
reg reset;
reg rx;

wire [DATA_WIDTH-1:0] rx_data; 
wire rx_done;
wire parity_error;
wire framing_error;

UART_rx #(
    .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .DATA_WIDTH(DATA_WIDTH), .PARITY_ENABLE(PARITY_ENABLE), .ODD_PARITY(ODD_PARITY), .STOP_BITS(STOP_BITS)
)
DUT(
    .clk(clk), .reset(reset), .rx(rx), .rx_data(rx_data), .parity_error(parity_error), .framing_error(framing_error), .rx_done(rx_done)
);

initial begin
    clk = 1'b0; 
end

always #5 clk = ~clk;

task send_bit;
input bit_value;
begin
  rx = bit_value;
  repeat(BAUD_DIV)
  @(posedgeclk);
end
endtask

task send_byte;
input[DATA_WIDTH-1:0]data;
integer i;
reg parity;
if (ODD_PARITY) begin
    parity <= ~(^DATA);
end
else begin
  parity <= (^DATA);
end

send_bit(1'b0); // Data bits
for (i = 0; i < DATA_WIDTH; i = i + 1) begin // Data_bits - LSB First
    send_bit(data[i]);
end
if (PARITY_ENABLE) begin // if parity
    send_bit(parity);
end
for (i = 0; i < STOP_BITS; i = i + 1) begin
    send_bit(1'b1);
end

rx <= 1'b1; // return to IDLE

endtask

// ****Self Checking Testbench****

task check_byte;

input[DATA_WIDTH-1:0] expected_data;

begin
  @(posedge rx_done);
  if (rx_data != expected_data) begin
    $display("Error: Expected = %h, Result = %h");
  end
  else if (parity_error) begin
    $display("Error: Parity Error");
  end
  else if (framing_error) begin
    $display("Error: Framing Error");
  end
  else begin
    $display("Pass: Received Data = %h", rx_data);
  end
end
// ***Test Sequence***//
initial begin
    rx <= 1'b1;
    reset <= 1'b1;

    repeat(2) @(posedge clk);
    reset <= 1'b0;

    repeat(2) @(posedge clk);
    // Test-1
    fork
        send_byte(8'h55);
        check_byte(8'h55);
    join  

    repeat(10) @(posedge clk);  
    fork
        send_byte();
        check_byte();
    join
    repeat(20) @(posedge clk);
    $display("UART RX TESTBENCH COMPLETE");
    $finish;
end

endtask
initial begin
    $dumpfile("UART_rx_tb.vcd");
    $dumpvars(0, UART_rx_tb);
end
endmodule
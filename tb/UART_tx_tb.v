`timescale 1ns/1ps

module UART_tx_tb;

parameter integer DATA_WIDTH = 8;
parameter         PARITY_ENABLE = 1;
parameter         ODD_PARITY = 8;
parameter integer STOP_BITS = 2;

reg clk;
reg reset;
reg tx_start;
reg baud_tick;
reg [DATA_WIDTH-1:0] tx_data;

wire tx;
wire busy;
wire tx_complete;

UART_tx #(
    .DATA_WIDTH(DATA_WIDTH), .PARITY_ENABLE(PARITY_ENABLE), .ODD_PARITY(ODD_PARITY), .STOP_BITS(STOP_BITS)
)
DUT(
    .clk(clk), .reset(reset), .tx_start(tx_start), .baud_tick(baud_tick), .tx_data(tx_data), .tx(tx), .busy(busy), .tx_complete(tx_complete)
);

initial begin
    reset = 1'b1;
    tx_data = 1'b0;
    tx_start = 1b'0;
    baud_tick = 0;
end

parameter integer BAUD_DIV = 10;
integer baud_count;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        baud_count <= 0;
        baud_tick <= 1b'0;
    end
    else begin
      if (baud_count == BAUD_DIV-1) begin
        baud_count <= 0;
        baud_tick <= 1'b1;
      end
      else begin
        baud_count <= baud_count + 1;
        baud_tick <= 0;
      end
    end
end

initial begin
    // Initialize
    reset = 1b'1;
    tx_start = 1b'0;
    tx_data = 8h'00;

    repeat(2) @(posedge clk); // Apply reset

    reset = 1b'0;
    
    task send_byte; 
    
    input [DATA_WIDTH-1:0] data;
    
    begin

    tx_data = data;
    tx_start = 1b'1;

    @(posedge clk);
    tx_start = 1b'0;

    end

    endtask  

    task check_frame;

    input [DATA_WIDTH-1:0] expected_data;

    integer i;
    reg expected_parity;

    begin
      @(posedge baud-tick)
      if (tx != 1b'0) begin
        $display("[%0t] Error: Start bit incorrect", $time);
      end
      for (i = 0; i < DATA_WIDTH; i = i + 1 ) begin
        @(posedge baud_tick);
        if (tx != expected_data[i]) begin
            $display("[%0t] Error: Data bit %0d is incorrect, Expected bit = %b, Received bit = %b", $time, i, expected_data[i], tx);
        end
      end

      if (PARIY_ENABLE) begin
        if(ODD_PARITY)
          expected_parity = ~(^expected_data);

            else
            expected_parity = (^expected_data);

            @(posedge baud_tick);

            if(tx != expected_parity) begin

              $display("[%0t] ERROR : Parity Incorrect", $time);

              error_count = error_count + 1;

            end
      end
    end

    for (i = 0; i < STOP_BITS; i = i + 1) begin
      @(posedge baud_tick);
      if (tx != 1b'1) begin
        $display("[%0t] Error: Incorrect Stop bit", $time);
        error_count = error_count + 1;
      end
    end

    endtask
    task run_test;

    input [DATA_WIDTH-1:0] data;

    begin
      $display("[%0t] Sending Data: %h", data);
      send_byte(data);
      check_frame(data);
      @(posedge tx_done);
    end
    endtask
end

// Testing Sequence
initial begin
  error_count = 0;
  reset = 1b'1;
  tx_start = 1'b0;
  tx_data = 0;

  repeat(2) @(posedge clk);
  reset = 1b'0;

  run_test(8'h55);

  run_test(8'hAA);

  run_test(8'h00);

  run_test(8'hFF);

  run_test(8'hA5);

if (error_count = 0) begin
  $display("All Tests Passed");
end
else begin
  $display("Test Failed: %0d Errors Found", error_count);
end
$finish;
end

initial begin
    $dumpfile("UART_tx.vcd");
    $dumpvars(0, UART_tx_tb);
end

endmodule
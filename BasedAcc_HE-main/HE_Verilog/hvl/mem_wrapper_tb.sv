`include "../hdl/he_headers.sv"

`timescale 1ns / 1ps

module mem_wrapper_tb();
   logic clk, rst, start_i, ready_o, done_o, mem_read_o, mem_resp_read_i, mem_write_o, mem_resp_write_i;
   logic [32-1:0] addr_read_o, addr_write_o;
   logic [`BIT_WIDTH-1:0] data_i, data_o;

   always #1 clk = clk === 1'b0;

   wrapper_top dut(.*);

   task clear_signals();
      rst = 1'b1;
   endtask // clear_signals

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task start();
      @(posedge clk) start_i = 1'b1;
      @(posedge clk) start_i = 1'b0;
   endtask // start

   task mem_read_response(logic [`BIT_WIDTH-1:0] data);
      data_i = data;
      @(posedge clk iff mem_read_o) mem_resp_read_i = 1'b1;
      @(posedge clk) mem_resp_read_i = 1'b0;
   endtask // mem_read_response

   task mem_write_response();
      @(posedge clk iff mem_write_o) mem_resp_write_i = 1'b1;
      @(posedge clk) mem_resp_write_i = 1'b0;
   endtask // mem_write_response

   initial begin
      $display("Testing memory wrapper...");

      clear_signals();
      reset();

      @(posedge clk iff ready_o) start();

      repeat(2*(`L_+1)*`DEGREE_N) mem_read_response(`BIT_WIDTH'hcafebabe);
      repeat(2*4*`DEGREE_N) mem_read_response(`BIT_WIDTH'hdeadbeef);
   end

   always_ff @(posedge clk) mem_write_response();

   initial begin : IO

      @(posedge clk iff dut.accel_done_o);
      @(posedge clk iff dut.done_o);


      $finish;
   end
endmodule // mem_wrapper_tb

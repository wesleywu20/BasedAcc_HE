`include "../hdl/he_headers.sv"

`timescale 1ns/1ps

module accel_tb;

   bit clk;
   always #1 clk = clk === 1'b0;
   bit rst;

   accel dut
     (
      .clk(clk),
      .reset(rst),
      .iq_assert(),
      .funct3(),
      .source(),
      .destination(),
      .accel_ready(),
      .accel_done()
      );

   task clear_signals();

   endtask // clear_signals

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task set_params(input logic [`BIT_WIDTH-1:0] new_t, input logic [`BIT_WIDTH-1:0] new_q);

   endtask // set_params


   initial begin
      $display("Datapath TB");

      clear_signals();
      reset();
      set_params(`BIT_WIDTH'h5, `BIT_WIDTH'hd);

      $finish;
    end

endmodule : accel_tb

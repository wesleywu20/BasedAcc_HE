`include "../hdl/he_headers.sv"

`timescale 1ns/1ps

module datapath_tb;

   bit clk;
   always #1 clk = clk === 1'b0;
   bit rst;

   logic coeff_ready_i, coeff_ready_o;
   logic [`BIT_WIDTH-1:0] q, t, coeff_o;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] coeff_i;

   test_datapath dut
     (
      .clk(clk),
      .rst(rst),
      .t(t),
      .q(q),
      .coeff_i(coeff_i),
      .coeff_ready_i(coeff_ready_i),
      .coeff_o(coeff_o),
      .coeff_ready_o(coeff_ready_o)
      );

   task clear_signals();
      rst = 1'b1;
      coeff_ready_i = 1'b0;
   endtask // clear_signals

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task set_params(input logic [`BIT_WIDTH-1:0] new_t, input logic [`BIT_WIDTH-1:0] new_q);
      t = new_t;
      q = new_q;
   endtask // set_params


   task input_coeff(input logic [`BIT_WIDTH-1:0] a);
      coeff_i = {`DEGREE_N{a}};
      for(int i = 0; i < `DEGREE_N; ++i) coeff_i[i] = ($urandom() % (2**(`BIT_WIDTH-1)));
      $display("%x", coeff_i);


      @(posedge clk) coeff_ready_i = 1'b1;
      @(posedge clk) coeff_ready_i = 1'b0;
   endtask // input_coeff


   initial begin
      $display("Datapath TB");

      clear_signals();
      reset();
      set_params(`BIT_WIDTH'hffffff, `BIT_WIDTH'h15);

      // repeat(2*`DEGREE_N) ;

      //repeat(2) input_coeff($urandom() % (2**`BIT_WIDTH));
      repeat(2) input_coeff(`BIT_WIDTH'h8);

      repeat(100) @(posedge clk); // Allow simulation time to finish

      $finish;
    end

   always_ff @(posedge clk iff coeff_ready_o) $display("%x", coeff_o);

endmodule : datapath_tb

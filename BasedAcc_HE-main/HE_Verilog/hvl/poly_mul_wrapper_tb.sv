`include "../hdl/he_headers.sv"

`timescale 1ns / 1ps

module poly_mul_wrapper_tb();

   bit clk, rst, rst_poly_mul, start, outputs_ready, done, ready_o;
   logic [`TILE_N-1:0][`BIT_WIDTH-1:0] as, bs, cs;

   always #1 clk = clk === 1'b0;
   poly_mul_wrapper dut(.*);

   task clear_signals();
      rst = 1'b1;
      rst_poly_mul = 1'b1;
      start = 1'b0;
   endtask // clear_signals

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task reset_poly_mul();
      @(posedge clk) rst_poly_mul = 1'b0;
      @(posedge clk) rst_poly_mul = 1'b1;
   endtask // reset_poly_mul

   task uniform_tile_mul(input logic [`TILE_N-1:0][`BIT_WIDTH-1:0] as_in, bs_in);
      as = as_in;
      bs = bs_in;

      @(posedge clk) start = 1'b1;
      @(posedge clk iff done) start = 1'b0;
      reset();
   endtask // tile_mul

   task tile_mul(input logic [`TILE_N-1:0][`BIT_WIDTH-1:0] as_in, bs_in);
      as = as_in;
      bs = bs_in;

      @(posedge clk) start = 1'b1;
      @(posedge clk) start = 1'b0;
   endtask // tile_mul

   task poly_mul(input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] as_in, bs_in);
      static int tile_count = `DEGREE_N / `TILE_N;

      tile_mul(as_in[0+:`TILE_N], bs_in[0+:`TILE_N]);
      for(int i = 0; i < tile_count; ++i)
         for(int j = 0; j < tile_count; ++j)
           if(i == 0 && j == 0) continue;
           else @(posedge clk iff ready_o) tile_mul(as_in[i*`TILE_N+:`TILE_N], bs_in[j*`TILE_N+:`TILE_N]);

      @(posedge clk iff done) reset_poly_mul();
      // @(posedge clk iff done) reset();
   endtask // poly_mul

   initial begin
      $display("Starting tests: poly_mul_wrapper_tb...");

      clear_signals();
      reset();

      poly_mul({`DEGREE_N{`BIT_WIDTH'h1}}, {`DEGREE_N{`BIT_WIDTH'h2}});
      poly_mul({`DEGREE_N{`BIT_WIDTH'h1}}, {`DEGREE_N{`BIT_WIDTH'h3}});
      poly_mul({`DEGREE_N{`BIT_WIDTH'h1}}, {`DEGREE_N{`BIT_WIDTH'h4}});
      poly_mul({`DEGREE_N{`BIT_WIDTH'h1}}, {`DEGREE_N{`BIT_WIDTH'h5}});

      repeat(10000) @(posedge clk);


      $finish;
   end

   task display_output();
      // repeat(2) @(posedge clk); // TODO shorter reset???
      // repeat(`DEGREE_N / `TILE_N) @(posedge clk iff dut.outputs_ready) $write("%x ", dut.cs);
      // repeat(2*`DEGREE_N) @(posedge clk iff dut.poly_mul_output_yumi_i) $write("%x ", dut.coeff_o);
      // repeat(2*`DEGREE_N) @(posedge clk iff dut.poly_mod_valid_i) $write("%x ", dut.poly_mod_coeff_i);
      // repeat(2*`DEGREE_N) @(posedge clk iff dut.poly_mod_valid_i) $write("%x ", dut.poly_mod_coeff_i);
      repeat(`DEGREE_N) @(posedge clk iff dut.poly_mod_valid_o) $write("%d ", $signed(dut.poly_mod_coeff_o));
      // repeat(2*`DEGREE_N) @(posedge clk iff dut.outputs_ready) $write("%x ", dut.coe);
      $write("\n");
   endtask // display_output

   task display_relin_output();
      repeat(`DEGREE_N / `TILE_N)
        @(posedge clk iff dut.relin_unit_valid_o) for(int i = 0; i < `TILE_N; ++i)
          $write("%x " , dut.relin_unit_coeff_o[i]);
      $write("\n");
   endtask // display_relin_output


   task print_regfiles();
      $display("----- Regfiles -----");
      $write("c0: ");
      for(int i = 0; i < `DEGREE_N; ++i) $write("%d ", $signed(dut.c0_reg[i]));
      $write("\n");
      $write("c1: ");
      for(int i = 0; i < `DEGREE_N; ++i) $write("%d ", $signed(dut.c1_reg[i]));
      $write("\n");
      $display("--------------------");
   endtask // print_regfiles

   task drain_relin_queue();
      $display("----- Relin Queue -----");
      while(dut.relin_input_fifo.valid_o) begin
         @(posedge clk) for(int i = 0; i < `TILE_N; ++i) $write("%d ", $signed(dut.relin_input_fifo_data_o[i]));
         $write("\n");
         dut.relin_input_fifo_yumi_i = 1'b1;
         @(posedge clk) dut.relin_input_fifo_yumi_i = 1'b0;
         @(posedge clk);
      end
   endtask // drain_relin_queue

   task drain_ctxt_queues();
      $display("----- c1 Queue -----");
      while(dut.c1_fifo_valid_o) begin
         @(posedge clk) $write("%d ", $signed(dut.c1_fifo_data_o));
         dut.c1_fifo_yumi_i = 1'b1;
         @(posedge clk) dut.c1_fifo_yumi_i = 1'b0;
         @(posedge clk);
      end
      $write("\n");
      $display("----- c0 Queue -----");
      while(dut.c0_fifo_valid_o) begin
         @(posedge clk) $write("%d ", $signed(dut.c0_fifo_data_o));
         dut.c0_fifo_yumi_i = 1'b1;
         @(posedge clk) dut.c0_fifo_yumi_i = 1'b0;
         @(posedge clk);
      end
      $write("\n");
      $display("-----------------------");
   endtask // drain_ctxt_queues

   initial begin // Print outputs
      dut.c1_fifo_yumi_i = 1'b0;
      dut.c0_fifo_yumi_i = 1'b0;


      // repeat(4) display_output();
      // repeat(3) display_output();
      display_relin_output();


      print_regfiles();
      // drain_relin_queue();
      // drain_ctxt_queues();


   end

endmodule // poly_mul_wrapper_tb

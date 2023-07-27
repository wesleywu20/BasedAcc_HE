`include "../hdl/he_headers.sv"
`timescale 1ns / 1ps

module full_test();

   logic clk, rst, rst_poly_mul, start, ready_o, outputs_ready, done;
   logic [`TILE_N-1:0][`BIT_WIDTH-1:0] as, bs, cs;
   logic [1:0][7:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0] relin_key_register_file;

   always #1 clk = clk === 1'b0;
   poly_mul_wrapper dut(.*);

   int                                 fd_00, fd_01, fd_10, fd_11;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] c00, c01, c10, c11;

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

   task load_input(output logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] ctxt, input int fd);
      for(int i = 0; i < `DEGREE_N; ++i) begin
        for(int j = 0; j < `BIT_WIDTH / 8; ++j)
           $fgets(ctxt[i][(j*8)+:8], fd);
         // $write("%x ", ctxt[i]);
      end
      // $write("\n");
   endtask // load_input

   task load_relin_keys(); // TODO explicitly mark as output
      static int relin_fd = $fopen("/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_64_512/relinKey.bin", "r");

      for(int i = 0; i < 2; ++i)
         for(int j = 0; j < `L_+1; ++j)
            for(int k = 0; k < `DEGREE_N; ++k)
               for(int l = 0; l < `BIT_WIDTH / 8; ++l)
                 $fgets(relin_key_register_file[i][j][k][(l*8)+:8], relin_fd);
   endtask // load_relin_keys


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
   endtask // poly_mul

   initial begin
      $display("Starting verification of datapath...");

      // ---------- Initialize Inputs ----------
      fd_00 = $fopen("/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_64_512/ct10_fresh.bin", "r");
      fd_01 = $fopen("/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_64_512/ct11_fresh.bin", "r");
      fd_10 = $fopen("/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_64_512/ct20_fresh.bin", "r");
      fd_11 = $fopen("/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_64_512/ct21_fresh.bin", "r");

      load_input(c00, fd_00);
      load_input(c01, fd_01);
      load_input(c10, fd_10);
      load_input(c11, fd_11);

      // ---------- Run Tests ----------
      clear_signals();
      reset();

      load_relin_keys();

      /* for(int i = 0; i < 2; ++i)
         for(int j = 0; j < `L_+1; ++j) begin
            for(int k = 0; k < `DEGREE_N; ++k) begin
               $write("%x ", relin_key_register_file[i][j][k]);
            end
            $write("\n");
         end*/

      poly_mul(c01, c11);
      poly_mul(c00, c11);
      poly_mul(c01, c10);
      poly_mul(c00, c10);

      // Print final result

      repeat(10000) @(posedge clk);

      $finish;
   end

   task display_poly_mul_results();
      $display("---------- Poly Mul Results ----------");
      $write("c2: ");
      @(posedge clk iff dut.poly_mod_valid_o) $write("%x ", $signed(dut.poly_mod_coeff_o));
      repeat(`DEGREE_N - 2)
        @(posedge clk iff dut.poly_mod_valid_o); // $write("%x ", $signed(dut.poly_mod_coeff_o));
      @(posedge clk iff dut.poly_mod_valid_o) $write("%x ", $signed(dut.poly_mod_coeff_o));
      $write("\n");

      $write("c1: ");
      @(posedge clk iff dut.poly_mod_valid_o) $write("%x ", $signed(dut.poly_mod_coeff_o));
      repeat(`DEGREE_N - 2)
        @(posedge clk iff dut.poly_mod_valid_o); // $write("%x ", $signed(dut.poly_mod_coeff_o));
      @(posedge clk iff dut.poly_mod_valid_o) $write("%x ", $signed(dut.poly_mod_coeff_o));
      $write("\n");

      $write("c0: ");
      @(posedge clk iff dut.poly_mod_valid_o) $write("%x ", $signed(dut.poly_mod_coeff_o));
      repeat(`DEGREE_N - 2)
        @(posedge clk iff dut.poly_mod_valid_o); // $write("%x ", $signed(dut.poly_mod_coeff_o));
      @(posedge clk iff dut.poly_mod_valid_o) $write("%x ", $signed(dut.poly_mod_coeff_o));
      $write("\n");
   endtask // display_poly_mul_results

   task display_relin_results();
      $display("---------- Relin Unit Results ----------");
      repeat(`DEGREE_N / `TILE_N) begin
        @(posedge clk iff dut.relin_unit_valid_o) for(int i = 0; i < `TILE_N; ++i)
          $write("%x ", dut.relin_unit_coeff_o[i]);
         $write("\n");
      end
   endtask // display_relin_results


   task print_regfiles();
      $display("----- Regfiles -----");
      $write("c0: ");
      for(int i = 0; i < `DEGREE_N; ++i) $write("%x ", $signed(dut.c0_reg[i]));
      $write("\n");
      $write("c1: ");
      for(int i = 0; i < `DEGREE_N; ++i) $write("%x ", $signed(dut.c1_reg[i]));
      $write("\n");
      $display("--------------------");
   endtask // print_regfiles

   initial begin // Results I/O
      display_poly_mul_results();
      // display_relin_results();

   end

endmodule // full_test

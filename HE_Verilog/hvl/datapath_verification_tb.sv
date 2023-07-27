`include "../hdl/he_headers.sv"
`timescale 1ns / 1ps

`define PATH "/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_demo/"

module datapath_verification_tb();

   logic clk, rst, rst_poly_mul, start, ready_o, outputs_ready, poly_mul_done, done;
   logic [`TILE_N-1:0][`BIT_WIDTH-1:0] as, bs, cs;
   logic [1:0][7:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0] relin_key_register_file;

   int                                             cycles = 0;


   always #1 clk = clk === 1'b0;
   poly_mul_wrapper dut(.*);

   int                                 fd_00, fd_01, fd_10, fd_11, fd_0_after_mul, fd_1_after_mul, after_relin_0_fd, fd_2_after_mul;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] c00, c01, c10, c11, c0_expected, c1_expected, c0_reg_o, c1_reg_o, c2_expected;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] after_relin_0;
   logic [`DEGREE_N-1:0][64-1:0] after_relin_0_unformatted; 

   task clear_signals();
      rst = 1'b1;
      rst_poly_mul = 1'b1;
      start = 1'b0;
   endtask // clear_signals

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
      cycles = 0;
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
      static int relin_fd = $fopen({`PATH, "relinKey.bin"}, "r");

      for(int j = 0; j < `L_+1; ++j)
        for(int i = 0; i < 2; ++i)
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

      @(posedge clk iff poly_mul_done) reset_poly_mul();
   endtask // poly_mul

   task load_after_relin_input(input logic [`DEGREE_N-1:0][64-1:0] unformatted,
                  output logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] formatted, input int fd);
    for (int i = 0; i < `DEGREE_N; ++i) begin
      for (int j = 0; j < 64 / 8; ++j) $fgets(unformatted[i][(j*8)+:8], fd);
      //$write("%x ", unformatted[i]);
    end
    $write("\n");
    for (int i = 0; i < `DEGREE_N; ++i) begin
      formatted[i] = unformatted[i][`BIT_WIDTH-1:0];
      //$write("%x ", formatted[i]);
    end

  endtask  // load_input

   initial begin
      $display("Starting verification of datapath...");

      // ---------- Initialize Inputs ----------
      fd_00 = $fopen({`PATH, "ct10_fresh.bin"}, "r");
      fd_01 = $fopen({`PATH, "ct11_fresh.bin"}, "r");
      fd_10 = $fopen({`PATH, "ct20_fresh.bin"}, "r");
      fd_11 = $fopen({`PATH, "ct21_fresh.bin"}, "r");

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
   end

   task display_poly_mul_results();
      $display("---------- Poly Mul Results ----------");
      $write("c2: ");
      repeat(`DEGREE_N)
        @(posedge clk iff dut.poly_mod_valid_o) $write("%x ", $signed(dut.poly_mod_coeff_o));
      $write("\n");

      $write("c1: ");
      repeat(`DEGREE_N)
        @(posedge clk iff dut.poly_mod_valid_o) $write("%x ", $signed(dut.poly_mod_coeff_o));
      $write("\n");

      $write("c0: ");
      repeat(`DEGREE_N)
        @(posedge clk iff dut.poly_mod_valid_o) $write("%x ", $signed(dut.poly_mod_coeff_o));
      $write("\n");
   endtask // display_poly_mul_results

   task dump_intermediate_results();
      int fd_i_0, fd_i_1, fd_i_2;
      fd_i_0 = $fopen("/home/marcanthony/Research/BasedAcc_HE/tests/bins_20_16/c0_wrapper.bin", "w");
      fd_i_1 = $fopen("/home/marcanthony/Research/BasedAcc_HE/tests/bins_20_16/c1_wrapper.bin", "w");
      fd_i_2 = $fopen("/home/marcanthony/Research/BasedAcc_HE/tests/bins_20_16/c2_wrapper.bin", "w");

      repeat(`DEGREE_N)
        @(posedge clk iff dut.poly_mod_valid_o) $fwrite(fd_i_2, "%u",
                                                        {dut.poly_mod_coeff_o[0+:(`BIT_WIDTH/2)],
                                                         dut.poly_mod_coeff_o[`BIT_WIDTH+:(`BIT_WIDTH/2)]});
      repeat(`DEGREE_N)
        @(posedge clk iff dut.poly_mod_valid_o) $fwrite(fd_i_1, "%u",
                                                        {dut.poly_mod_coeff_o[0+:(`BIT_WIDTH/2)],
                                                         dut.poly_mod_coeff_o[`BIT_WIDTH+:(`BIT_WIDTH/2)]});
      repeat(`DEGREE_N)
        @(posedge clk iff dut.poly_mod_valid_o) $fwrite(fd_i_0, "%u",
                                                        {dut.poly_mod_coeff_o[0+:(`BIT_WIDTH/2)],
                                                         dut.poly_mod_coeff_o[`BIT_WIDTH+:(`BIT_WIDTH/2)]});
      $fclose(fd_i_0);
      $fclose(fd_i_1);
      $fclose(fd_i_2);
   endtask // display_poly_mul_results

   // task display_relin_results();
   //    $display("---------- Relin Unit Results ----------");
   //    repeat(`DEGREE_N / `TILE_N) begin
   //       @(posedge clk iff dut.relin_unit_valid_o) for(int i = 0; i < `TILE_N; ++i) begin
   //          $write("%x\t\t\t", dut.relin_unit.c0_coeff_o[i]);
   //          $write("%x", dut.relin_unit.c1_coeff_o[i]);
   //          $write("\n");
   //       end
   //    end
   // endtask // display_relin_results

   task print_regfiles();
      $display("----- Final Values -----");
      $write("c0: ");
      for(int i = 0; i < `DEGREE_N; ++i) $write("%x ", $signed(dut.c0_reg[i]) % `_Q);
      $write("\n");
      $write("c1: ");
      for(int i = 0; i < `DEGREE_N; ++i) $write("%x ", $signed(dut.c1_reg[i]) % `_Q);
      $write("\n");
      $display("--------------------");
   endtask // print_regfiles

   task dump_results();
      static int res_fd_0, res_fd_1;
      logic [`BIT_WIDTH-1:0] temp;

      res_fd_0 = $fopen("/home/marcanthony/Research/BasedAcc_HE/HE_Verilog/tests/ctR0.bin", "w");
      res_fd_1 = $fopen("/home/marcanthony/Research/BasedAcc_HE/HE_Verilog/tests/ctR1.bin", "w");
      for(int j = 0; j < `DEGREE_N / `TILE_N; ++j)
        @(posedge clk iff dut.relin_unit_valid_o) for(int i = 0; i < `TILE_N; ++i) begin
           temp = (dut.relin_unit_c0_coeff_o[i] + c0_expected[i + j*(`DEGREE_N / `TILE_N)]) % `_Q;
           $fwrite(res_fd_0, "%u", {temp[0+:(`BIT_WIDTH/2)], temp[`BIT_WIDTH+:(`BIT_WIDTH/2)]});
        end

      $write("\n");
      for(int j = 0; j < `DEGREE_N / `TILE_N; ++j)
        @(posedge clk iff dut.relin_unit_valid_o) for(int i = 0; i < `TILE_N; ++i) begin
           temp = (dut.relin_unit_c1_coeff_o[i] + c1_expected[i + j*(`DEGREE_N / `TILE_N)]) % `_Q;
           $fwrite(res_fd_1, "%u", {temp[0+:(`BIT_WIDTH/2)], temp[`BIT_WIDTH+:(`BIT_WIDTH/2)]});
        end
   endtask // dump_results

   task dump_regfiles();
      static int res_fd_0, res_fd_1;
      logic [`BIT_WIDTH-1:0] temp;

      res_fd_0 = $fopen({`PATH, "../ctR0.bin"}, "w");
      res_fd_1 = $fopen({`PATH, "../ctR1.bin"}, "w");

      for(int i = 0; i < `DEGREE_N; ++i) begin
         temp = $signed(c0_reg_o[i]) % `_Q;
         while($signed(temp) < 0) temp += `_Q;
         $fwrite(res_fd_0, "%u", {temp[0+:(`BIT_WIDTH/2)], temp[`BIT_WIDTH+:(`BIT_WIDTH/2)]});

         temp = $signed(c1_reg_o[i]) % `_Q;
         while($signed(temp) < 0) temp += `_Q;
         $fwrite(res_fd_1, "%u", {temp[0+:(`BIT_WIDTH/2)], temp[`BIT_WIDTH+:(`BIT_WIDTH/2)]});
      end
   endtask // dump_regfiles

   always_ff @(posedge clk) cycles += 1;

   initial begin // Results I/O

      display_poly_mul_results();

      @(posedge clk iff done);

      dump_regfiles();
      print_regfiles();

      $display("Cycles: %d", cycles);

      $finish;
   end

endmodule // datapath_verification_tb

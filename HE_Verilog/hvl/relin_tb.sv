`include "../hdl/he_headers.sv"
`timescale 1ns / 1ps

module relin_tb();

   /* logic clk, rst, inputs_ready_signal, c1_or_c0, outputs_ready_signal, dequeue, done;
   logic [1:0][`DEGREE_N-1:0][7:0][`BIT_WIDTH-1:0] relin_key_register_file;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]           c0, c1, c2;
   logic [`TILE_N-1:0][`BIT_WIDTH-1:0]             poly_mult_outputs, output_value;*/

   logic clk, rst, valid_i, ready_o, valid_o;
   logic [`TILE_N-1:0][`BIT_WIDTH-1:0] coeff_i, c0_coeff_o, c1_coeff_o;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] c0, c1, c2;
   logic [1:0][`L_:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0] relin_key_register_file;

   int                                             fd_0, fd_1, fd_2;

   always #1 clk = clk === 1'b0;
   /* relin_unit #(.DATA_WIDTH(`BIT_WIDTH), .RELIN_KEYS_TILE_WIDTH(`TILE_N), .C2_TILE_WIDTH(`TILE_N),
                .NUMBER_OF_RELIN_KEYS(`DEGREE_N), .C2_WIDTH(`DEGREE_N), .NUM_RELIN_KEYS(8))
   dut(.*);*/

   // relin_passthrough dut(.*);
   relin_wrapper dut (.*);

   task clear_signals();
      rst = 1'b1;
      valid_i = 1'b0;
   endtask // clear_signals

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task load_input(output logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] ctxt, input int fd);
      for(int i = 0; i < `DEGREE_N; ++i) begin
        for(int j = 0; j < `BIT_WIDTH / 8; ++j)
           $fgets(ctxt[i][(j*8)+:8], fd);
         // $write("%x ", ctxt[i]);
      end
      // $write("\n");
   endtask // load_input

   task load_relin_keys(); // TODO explicitly mark as output
      static int relin_fd = $fopen("/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_20_16/relinKey.bin", "r");

      for(int j = 0; j < `L_+1; ++j)
        for(int i = 0; i < 2; ++i)
            for(int k = 0; k < `DEGREE_N; ++k)
               for(int l = 0; l < `BIT_WIDTH / 8; ++l)
                 $fgets(relin_key_register_file[i][j][k][(l*8)+:8], relin_fd);
   endtask // load_relin_keys

   task relin_tile(input logic [`TILE_N-1:0][`BIT_WIDTH-1:0] tile_i);
   endtask // relin_tile

   task relin_op(input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] c2_i);
      valid_i = 1'b1;
      for(int i = 0; i < `DEGREE_N / `TILE_N; ++i) begin
         coeff_i = c2_i[(i*`TILE_N)+:`TILE_N];
         @(posedge clk iff ready_o) valid_i = 1'b1;
         @(posedge clk) valid_i = 1'b0;
      end
   endtask // relin_op

   initial begin
      $display("Starting verification of relin_unit...");

      // ---------- Initialize Inputs ----------
      fd_0 = $fopen("/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_20_16/ct_afterMul_0.bin", "r");
      fd_1 = $fopen("/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_20_16/ct_afterMul_1.bin", "r");
      fd_2 = $fopen("/home/noelle/school/BasedAcc_HE_main/HE_Verilog/tests/bins_20_16/ct_afterMul_2.bin", "r");

      load_input(c0, fd_0);
      load_input(c1, fd_1);
      load_input(c2, fd_2);

      load_relin_keys();

      clear_signals();
      reset();

      relin_op(c2);
   end

   /* task display_c2();
      $write("c2: ");
      for(int i = 0; i < `DEGREE_N; ++i) $write("%x ", dut.c2[i]);
      $write("\n");
   endtask

   task display_relin_key();
      $display("rlk0: ");
      for(int j = 0; j <= `L_; ++j) begin
         for(int i = 0; i < `DEGREE_N; ++i) $write("%x ", relin_key_register_file[0][j][i]);
         $write("\n");
      end

      $display("rlk1: ");
      for(int j = 0; j <= `L_; ++j) begin
         for(int i = 0; i < `DEGREE_N; ++i) $write("%x ", relin_key_register_file[1][j][i]);
         $write("\n");
      end
   endtask // display_relin_key

   task display_c2_base_t();
      for(int j = 0; j <= `L_; ++j) begin
         for(int i = 0; i < `DEGREE_N/2; ++i) $write("%x ", dut.c2_base_t[j][i]);
         $write("\n");
         for(int i = 0; i < `DEGREE_N/2; ++i) $write("%x ", dut.c2_base_t[j][i+(`DEGREE_N/2)]);
         $write("\n--------------------\n");
      end
   endtask

   task display_relin_long(input logic key_select);
      if(~key_select) begin
         $display("---------- c0 ----------");
         for(int j = 0; j <= `L_; ++j) begin
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin_long[j][i+0*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin_long[j][i+1*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin_long[j][i+2*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin_long[j][i+3*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin_long[j][i+4*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin_long[j][i+5*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin_long[j][i+6*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin_long[j][i+7*(`DEGREE_N/4)]);
            $write("\n\n");
         end
      end else begin // if (~key_select)
         $display("---------- c1 ----------");
         for(int j = 0; j <= `L_; ++j) begin
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin_long[j][i+0*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin_long[j][i+1*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin_long[j][i+2*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin_long[j][i+3*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin_long[j][i+4*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin_long[j][i+5*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin_long[j][i+6*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin_long[j][i+7*(`DEGREE_N/4)]);
            $write("\n\n");
         end
      end // else: !if(~key_select)
   endtask // display_relin_long

   task display_relin_short(logic key_select);
      if(~key_select) begin
         $display("---------- c0 ----------");
         for(int j = 0; j <= `L_; ++j) begin
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin[j][i+0*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin[j][i+1*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin[j][i+2*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_relin[j][i+3*(`DEGREE_N/4)]);
            $write("\n\n");
         end
      end else begin // if (~key_select)
         $display("---------- c1 ----------");
         for(int j = 0; j <= `L_; ++j) begin
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin[j][i+0*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin[j][i+1*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin[j][i+2*(`DEGREE_N/4)]);
            $write("\n");
            for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_relin[j][i+3*(`DEGREE_N/4)]);
            $write("\n\n");
         end
      end // else: !if(~key_select)
   endtask // display_relin_short

   task display_final(logic key_select);
      if(~key_select) begin
         $display("---------- c0 ----------");
         for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_final[i+0*(`DEGREE_N/4)]);
         $write("\n");
         for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_final[i+1*(`DEGREE_N/4)]);
         $write("\n");
         for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_final[i+2*(`DEGREE_N/4)]);
         $write("\n");
         for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c0_final[i+3*(`DEGREE_N/4)]);
         $write("\n\n");
      end else begin // if (~key_select)
         $display("---------- c1 ----------");
         for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_final[i+0*(`DEGREE_N/4)]);
         $write("\n");
         for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_final[i+1*(`DEGREE_N/4)]);
         $write("\n");
         for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_final[i+2*(`DEGREE_N/4)]);
         $write("\n");
         for(int i = 0; i < `DEGREE_N/4; ++i) $write("%x ", dut.c1_final[i+3*(`DEGREE_N/4)]);
         $write("\n\n");
      end // else: !if(~key_select)
   endtask // display_final*/

   task get_output();
      for(int j = 0; j < `DEGREE_N / `TILE_N; ++j) @(posedge clk iff valid_o) begin
      // repeat(1) @(posedge clk iff valid_o) begin
         for(int i = 0; i < `TILE_N; ++i) begin
            $write("%x\t\t\t", (c0_coeff_o[i] + c0[i + `TILE_N*j]) % `_Q);
            $display("%x", (c1_coeff_o[i] + c1[i + `TILE_N*j]) % `_Q);
         end
      end // UNMATCHED !!
   endtask // get_output

   initial begin
      // @(posedge clk iff dut.state) display_c2();
      // display_relin_key();

      get_output();
      // @(posedge clk iff ready_o);


      // display_c2_base_t();
      // display_relin_long(0);
      // @(posedge clk iff dut.valid_o);
      // display_relin_short(0);
      // display_relin_short(1);
      // display_relin_short(1);
      $finish;
   end

endmodule // datapath_verification_tb

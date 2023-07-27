`include "he_headers.sv"

`define ADDR_BITS 32

module wrapper_top
  (
   input logic                   clk,
   input logic                   rst,
   input logic                   start_i,
   output logic                  ready_o,
   output logic                  done_o,

   // Memory Read Port Signals
   output logic                  mem_read_o,
   output logic [`ADDR_BITS-1:0] addr_read_o,
   input logic [`BIT_WIDTH-1:0]  data_i,
   input logic                   mem_resp_read_i,

   // Memory Write Port Signals
   output logic                  mem_write_o,
   output logic [`ADDR_BITS-1:0] addr_write_o,
   output logic [`BIT_WIDTH-1:0] data_o,
   input logic                   mem_resp_write_i
   );

   logic [1:0][`L_:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0] relin_key_register_file;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]             c00, c01, c10, c11;
   int                                               load_i, load_j, load_k, accel_i, accel_j;

   enum {LOAD_READY, LOAD_RLKS, LOAD_CTXT, LOAD_DONE} load_state, next_load_state;
   enum {ACCEL_READY, ACCEL_11, ACCEL_10, ACCEL_01, ACCEL_00, ACCEL_DONE} accel_state, next_accel_state;

   logic accel_rst_poly_mul_i, accel_start_i, accel_ready_o, accel_poly_mul_done_o, accel_done_o;
   logic [`TILE_N-1:0][`BIT_WIDTH-1:0] accel_as_i, accel_bs_i;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] accel_c0_reg_o, accel_c1_reg_o;

   function tile_mul(input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] a, b);
      // accel_start_i = 1'b1;
      accel_as_i = a[`TILE_N-1:0]; // TODO correctness
      accel_bs_i = b[`TILE_N-1:0];
   endfunction // tile_mul

   poly_mul_wrapper accel
     (
      .clk(clk),
      .rst(rst),
      .rst_poly_mul(accel_rst_poly_mul_i),
      .start(accel_start_i),
      .ready_o(accel_ready_o),
      .relin_key_register_file(relin_key_register_file),
      .as(accel_as_i),
      .bs(accel_bs_i),
      .cs(), // IGNORE
      .outputs_ready(), // IGNORE
      .poly_mul_done(accel_poly_mul_done_o),
      .c0_reg_o(accel_c0_reg_o),
      .c1_reg_o(accel_c1_reg_o),
      .done(accel_done_o)
      );

    // Interaction w/ accelerator -> enqueue tiles
   always_ff @(posedge clk) begin

   end

   always_comb begin : state_logic
      next_load_state = load_state;
      next_accel_state = accel_state;

      unique case(load_state)
        LOAD_READY: if(start_i) next_load_state = LOAD_RLKS;
        LOAD_RLKS: if(load_k == 2) next_load_state = LOAD_CTXT;
        LOAD_CTXT: if(load_j == 4) next_load_state = LOAD_DONE;
        default:;
      endcase // unique case (load_state)

      unique case(accel_state)
        ACCEL_READY: if(start_i) next_accel_state = ACCEL_11;
        ACCEL_11: if(accel_j == `DEGREE_N-`TILE_N) next_accel_state = ACCEL_10;
        ACCEL_10: if(accel_j == `DEGREE_N-`TILE_N) next_accel_state = ACCEL_01;
        ACCEL_01: if(accel_j == `DEGREE_N-`TILE_N) next_accel_state = ACCEL_00;
        ACCEL_00: if(accel_j == `DEGREE_N-`TILE_N) next_accel_state = ACCEL_DONE;
        default:;
      endcase // unique case (accel_state)

      if(~rst) begin
         next_load_state = LOAD_READY;
         next_accel_state = ACCEL_READY;
      end
   end

   always_comb begin : signals
      ready_o = 1'b0;
      mem_read_o = 1'b0;
      // accel_start_i = 1'b1; // TODO no


      unique case(load_state)
        LOAD_READY: ready_o = 1'b1;
        LOAD_RLKS: mem_read_o = 1'b1;
        LOAD_CTXT: mem_read_o = 1'b1;
        default:;
      endcase // unique case (load_state)

      unique case(accel_state)
        ACCEL_11: tile_mul(c11, c01);
        ACCEL_10: tile_mul(c10, c01);
        ACCEL_01: tile_mul(c11, c00);
        ACCEL_00: tile_mul(c10, c00);
        default:;
      endcase // unique case (accel_state)
   end

   always_ff @(posedge clk) begin
      load_state = next_load_state;
      accel_state = next_accel_state;
      accel_rst_poly_mul_i = 1'b1;
      accel_start_i = 1'b1; // TODO not working?????

      // if(mem_resp_read_i) load_i += 1;

      unique case(load_state)
        LOAD_RLKS:
          if(mem_resp_read_i) begin
             relin_key_register_file[load_k][load_j][load_i] = data_i;

             load_i = (load_i == `DEGREE_N-1) ? 0 : (load_i + 1);
             if(~|load_i) load_j = (load_j == `L_) ? 0 : (load_j + 1);
             if(~|load_i & ~|load_j) load_k += 1;
          end
        LOAD_CTXT:
          if(mem_resp_read_i) begin
             if(load_j == 0) c11[load_i] = data_i;
             else if(load_j == 1) c01[load_i] = data_i;
             else if(load_j == 2) c10[load_i] = data_i;
             else if(load_j == 3) c11[load_i] = data_i;

             load_i = (load_i == `DEGREE_N-1) ? 0 : (load_i + 1);
             if(~|load_i) load_j = (load_j == `DEGREE_N-1) ? 0 : (load_j + 1);
          end
        default:;
      endcase // unique case (load_state)

      unique case(accel_state)
        ACCEL_11, ACCEL_10, ACCEL_01, ACCEL_00:
          begin
             if(accel_ready_o | (~|accel_i & ~|accel_j)) begin
                accel_start_i = 1'b1;

                accel_i = (accel_i == `DEGREE_N-`TILE_N) ? 0 : (accel_i + `TILE_N);
                if(~|accel_i) accel_j = (accel_j == `DEGREE_N-`TILE_N) ? 0 : (accel_j + `TILE_N);
                if(~|accel_j) accel_rst_poly_mul_i = 1'b0;
             end
          end
        default:;
      endcase // unique case (accel_state)

      if(load_state == LOAD_READY) begin
         load_i = 0;
         load_j = 0;
         load_k = 0;
      end

      if(accel_state == ACCEL_READY) begin
         accel_i = 0;
         accel_j = 0;
      end
   end

   // Write logic is simple -> write outputs as they become available
   int store_count;

   always_comb begin : store_state_logic

   end

   always_comb begin : store_signals
      if(accel_done_o) mem_write_o = 1'b1;

   end

   always_ff @(posedge clk) begin
      done_o = (store_count == `DEGREE_N*2);
      if(mem_resp_write_i) store_count += 1;

      if(~rst | done_o) store_count = 0;
   end

endmodule // wrapper_top

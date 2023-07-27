/*
A simple test case
*/

`timescale 1ns / 1ps

module relin_tb #(
    parameter DATA_WIDTH = 64,
    parameter POLY_A_TILE_WIDTH = 4,
    parameter POLY_B_TILE_WIDTH = 4,
    parameter POLY_A_WIDTH = 16,
    parameter POLY_B_WIDTH = 16,
    parameter NUM_RELIN_KEYS = 8
) ();

  logic clk, reset, inputs_ready, done, outputs_ready_signal;
  logic [POLY_A_TILE_WIDTH-1:0][DATA_WIDTH-1:0] inputs;
  logic [POLY_A_TILE_WIDTH+POLY_B_TILE_WIDTH-1-1:0][DATA_WIDTH-1:0] outputs;
  logic [POLY_B_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] c_value_outputs;
  logic [7:0][POLY_B_TILE_WIDTH - 1:0][DATA_WIDTH-1:0]
      finished_c_intermediates, c_value_outputs_segment;
  logic [POLY_B_TILE_WIDTH - 1:0][7:0][DATA_WIDTH-1:0] tree_value_inputs;
  logic [64:0] fifo_scale;

  logic dequeue;
  localparam DEGREE_N = POLY_A_WIDTH;
  logic [NUM_RELIN_KEYS-1:0][1:0][POLY_A_WIDTH-1:0][64-1:0] relin_key_register_file;
  logic [1:0][NUM_RELIN_KEYS-1:0][POLY_A_WIDTH-1:0][DATA_WIDTH-1:0] relin_formatted;
  int fd_00, fd_01, fd_10, fd_11, fd_mult_2_result, fd_mult_1_result, fd_mult_0_result, after_relin_0_fd;
  logic [DEGREE_N-1:0][DATA_WIDTH-1:0]
      c00, c01, c10, c11, mult_2_result, mult_1_result, mult_0_result, after_relin_0;
  logic [DEGREE_N-1:0][64-1:0]
      c00_unformatted,
      c01_unformatted,
      c10_unformatted,
      c11_unformatted,
      mult_2_result_unformatted,
      mult_1_result_unformatted,
      mult_0_result_unformatted,
      after_relin_0_unformatted;
  initial begin
    #0 clk = 1'b0;
    forever #2.5 clk = ~clk;
  end
  genvar c_value, i, key, offset;


  // generate
  // for (i = 0; i < POLY_A_TILE_WIDTH ; i ++) begin
  //         assign inputs[i] = mult_2_result[i];
  // end
  //endgenerate
  task load_input(input logic [DEGREE_N-1:0][64-1:0] unformatted,
                  output logic [DEGREE_N-1:0][DATA_WIDTH-1:0] formatted, input int fd);
    for (int i = 0; i < DEGREE_N; ++i) begin
      for (int j = 0; j < 64 / 8; ++j) $fgets(unformatted[i][(j*8)+:8], fd);
      //$write("%x ", unformatted[i]);
    end
    $write("\n");
    for (int i = 0; i < DEGREE_N; ++i) begin
      formatted[i] = unformatted[i][DATA_WIDTH-1:0];
      //$write("%x ", formatted[i]);
    end

  endtask  // load_input

  task print_poly(input logic [DEGREE_N-1:0][DATA_WIDTH-1:0] ctxt);
    $display("--------------------");
    for (int i = 0; i < DEGREE_N; ++i) $write("%x ", $signed(ctxt[i]));
    // $write("\n");
  endtask  // load_input

  task load_relin_keys();  // TODO explicitly mark as output
    static
    int
    relin_fd = $fopen(
        "/home/marcanthony/Research/BasedAcc_HE/C_Behavioural/bins_20_16/relinKey.bin", "r"
    );

    for (int i = 0; i < NUM_RELIN_KEYS; ++i)
      for (int j = 0; j < 2; ++j)
        for (int k = 0; k < POLY_A_WIDTH; ++k) begin
          for (int l = 0; l < 64 / 8; ++l)
            $fgets(relin_key_register_file[i][j][k][(l*8)+:8], relin_fd);
        end

    for (int i = 0; i < NUM_RELIN_KEYS; ++i)
      for (int j = 0; j < 2; ++j)
        for (int k = 0; k < POLY_A_WIDTH; ++k) begin
          relin_formatted[j][i][k] = relin_key_register_file[i][j][k][DATA_WIDTH-1:0];
        end
  endtask  // load_relin_keys

  task print_relin_keys(
      input logic [1:0][NUM_RELIN_KEYS-1:0][POLY_A_WIDTH-1:0][DATA_WIDTH-1:0] relin_formatted
  );  // TODO explicitly mark as output

    for (int i = 0; i < 2; ++i)
      for (int j = 0; j < NUM_RELIN_KEYS; ++j)
        for (int k = 0; k < POLY_A_WIDTH; ++k) $write("%x ", $signed(relin_formatted[i][j][k]));
  endtask  // load_relin_keys

  //     task print_poly(input logic [1:0][NUM_RELIN_KEYS-1:0][RELIN_KEY_LENGTH-1:0][DATA_WIDTH-1:0] relin_key_register_file;);
  //      $display("----- Regfiles -----");
  //       $write("C00: ");
  //       for(int i = 0; i < DEGREE_N; ++i) $write("%x ", $signed(ctxt[i]));

  //       $display("--------------------");
  //       // $write("\n");
  //    endtask // load_input

  initial begin
    fd_00 = $fopen("/home/marcanthony/Research/BasedAcc_HE/C_Behavioural/bins_20_16/ct10_fresh.bin",
                   "r");
    fd_01 = $fopen("/home/marcanthony/Research/BasedAcc_HE/C_Behavioural/bins_20_16/ct11_fresh.bin",
                   "r");
    fd_10 = $fopen("/home/marcanthony/Research/BasedAcc_HE/C_Behavioural/bins_20_16/ct20_fresh.bin",
                   "r");
    fd_11 = $fopen("/home/marcanthony/Research/BasedAcc_HE/C_Behavioural/bins_20_16/ct21_fresh.bin",
                   "r");
    fd_mult_2_result = $fopen(
        "/home/marcanthony/Research/BasedAcc_HE/C_Behavioural/bins_20_16/ct_afterMul_2.bin", "r");
    fd_mult_1_result = $fopen(
        "/home/marcanthony/Research/BasedAcc_HE/C_Behavioural/bins_20_16/ct_afterMul_1.bin", "r");
    fd_mult_0_result = $fopen(
        "/home/marcanthony/Research/BasedAcc_HE/C_Behavioural/bins_20_16/ct_afterMul_0.bin", "r");

    after_relin_0_fd = $fopen(
        "/home/marcanthony/Research/BasedAcc_HE/C_Behavioural/bins_20_16/ct_afterRelin_0.bin", "r");

    //   load_input(c00, fd_00);
    //   load_input(c01, fd_01);
    //   load_input(c10, fd_10);
    //   load_input(c11, fd_11);
    load_input(mult_2_result_unformatted, mult_2_result, fd_mult_2_result);
    load_input(mult_1_result_unformatted, mult_1_result, fd_mult_1_result);
    load_input(mult_0_result_unformatted, mult_0_result, fd_mult_0_result);
    load_input(after_relin_0_unformatted, after_relin_0, after_relin_0_fd);

    // print_poly(mult_2_result);
    // print_poly(mult_1_result);
    // print_poly(mult_0_result);
    load_relin_keys();
    //print_relin_keys(relin_formatted);
    //print_poly(c00);
    #0 reset = 1'b1;
    #10 reset = 1'b0;
    #15 reset = 1'b1;
    // inputs = {8{8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1}};
    //inputs = {20'shCDA44, 20'shF94, 20'shD8923, 20'shF1E61 };
    #20 inputs_ready = 1;
    #5 inputs_ready = 0;

    #100 inputs_ready = 1;
    #5 inputs_ready = 0;

        #100 inputs_ready = 1;
    #5 inputs_ready = 0;
        #100 inputs_ready = 1;
    #5 inputs_ready = 0;

    // #5 inputs_ready = 0;
    // #520 inputs_ready = 1;
    // #5 inputs_ready = 0;
    #500 $stop;
    // #40000 reset = 1'b1;
    // #10 reset = 1'b0;
    // #15 reset = 1'b1;
  end



  // Module under test ==========================================================



  relin_unit #(
      .DEGREE_OF_RELIN_KEYS(POLY_A_WIDTH),
      .C2_WIDTH(POLY_B_WIDTH),
      // POLY_A_TILE_WIDTH and POLY_B_TILE_WIDTH need to be divisible by each other
      .RELIN_KEYS_TILE_WIDTH(POLY_A_TILE_WIDTH),
      .C2_TILE_WIDTH(POLY_B_TILE_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .NUM_RELIN_KEYS(NUM_RELIN_KEYS),
      .MOD_VALUE(1048193)
  ) base_t_decomp_unit (
      .clk(clk),
      .rst(reset),
      .valid_i(inputs_ready),
      .key_select_i(0),
      .coeff_i(inputs),
      .coeff_o(),
      .valid_o(),
      .ready_o(dequeue),
      .relin_key_register_file(relin_formatted),
      .done()
  );


  generate
    for (c_value = 0; c_value < POLY_A_TILE_WIDTH; c_value = c_value + 1) begin
      assign inputs[c_value] = mult_2_result[fifo_scale+c_value];
    end
  endgenerate

  always_ff @(posedge clk, negedge reset) begin
    if (~reset) begin
      fifo_scale <= 0;
    end else if (dequeue) begin
      fifo_scale <= fifo_scale + POLY_A_TILE_WIDTH;
    end else begin
      fifo_scale <= fifo_scale;
    end
  end


  // relin_key_loader #(
  //     .RELIN_KEY_TILE_WIDTH(8),
  //     .RELIN_KEY_LENGTH(64),
  //     .NUM_RELIN_KEYS(8),
  //     .DATA_WIDTH(DATA_WIDTH)

  // ) relin (
  //     .clk(clk),
  //     .reset(reset),
  //     .request_signal(inputs_ready),
  //     .c1_or_c0(0),
  //     .valid_address(),
  //     .address(),
  //     .request_new_input(),
  //     .relin_key()
  // );



endmodule

module relin_key_loader #(
    parameter RELIN_KEY_TILE_WIDTH = 8,
    parameter RELIN_KEY_LENGTH = 512,
    parameter NUM_RELIN_KEYS = 8,
    parameter DATA_WIDTH = 64
) (
    input logic clk,
    input logic reset,
    input logic request_signal,
    input logic c1_or_c0,
    input logic [1:0][NUM_RELIN_KEYS-1:0][RELIN_KEY_LENGTH-1:0][DATA_WIDTH-1:0] relin_key_register_file,
    output logic valid_address,
    output logic [$clog2(RELIN_KEY_LENGTH):0] address,
    output logic request_new_input,
    output logic [NUM_RELIN_KEYS-1:0][RELIN_KEY_TILE_WIDTH-1:0][DATA_WIDTH-1:0] relin_key
);
  typedef enum {
    WAIT,
    BURST
  } state;
  state curr_state;

  always_ff @(posedge clk or negedge reset) begin
    if (~reset) begin
      address <= 0;
      valid_address <= 0;
      curr_state <= WAIT;
    end else begin
      if (address == 0 && valid_address == 0 && curr_state == WAIT && request_signal) begin
        curr_state <= BURST;
        valid_address <= 1;
      end else if (curr_state == BURST) begin
        if (address >= RELIN_KEY_LENGTH - RELIN_KEY_TILE_WIDTH) begin
          if (~request_signal) begin
            curr_state <= WAIT;
            address <= 0;
            valid_address <= 0;
          end else begin
            curr_state <= BURST;
            valid_address <= 1;
            address <= 0;
          end
        end else begin
          curr_state <= BURST;
          address <= address + RELIN_KEY_TILE_WIDTH;
          valid_address <= 1;
        end
      end


    end
  end

  genvar c_value, i, key, offset;
  // generate
  // for (c_value = 0; c_value <2; c_value++) begin
  //     for (i = 0; i < NUM_RELIN_KEYS ; i ++) begin
  //         for (key = 0; key<RELIN_KEY_LENGTH; key++) begin
  //             assign relin_key_register_file[c_value][i][key] = ;
  //         end 
  //     end
  // end
  // endgenerate

  generate
    for (i = 0; i < NUM_RELIN_KEYS; i++) begin
      for (offset = 0; offset < RELIN_KEY_TILE_WIDTH; offset++) begin
        assign relin_key[i][offset] = relin_key_register_file[c1_or_c0][i][address+offset];
      end
    end
  endgenerate


  always_comb begin
    request_new_input = address >= (RELIN_KEY_LENGTH - RELIN_KEY_TILE_WIDTH) || (address == 0 && valid_address == 0 && curr_state == WAIT);
  end


endmodule

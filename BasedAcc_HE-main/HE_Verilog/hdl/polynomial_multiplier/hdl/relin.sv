module relin_unit #(
    parameter DATA_WIDTH = 64,
    parameter RELIN_KEYS_TILE_WIDTH = 8, //Tile width of relin keys
    parameter C2_TILE_WIDTH = 8, //width of polymult outputs
    parameter NUMBER_OF_RELIN_KEYS = 64, // Degree_N
    parameter C2_WIDTH = 64, 
    parameter NUM_RELIN_KEYS = 8 //Constant
    )(
    input logic clk,
    input logic rst,
    input logic inputs_ready_signal,
    input logic c1_or_c0,
    input logic [ C2_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] poly_mult_outputs,
    input logic [1:0][NUM_RELIN_KEYS-1:0][NUMBER_OF_RELIN_KEYS-1:0][DATA_WIDTH-1:0] relin_key_register_file,
    output logic [ C2_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] output_value,
    output logic outputs_ready_signal,
    output logic dequeue,
    output logic done
);
    localparam SLICE_WIDTH =  DATA_WIDTH/NUM_RELIN_KEYS;
    logic valid_address, request_new_relin_tile;
    logic [NUM_RELIN_KEYS-1:0][RELIN_KEYS_TILE_WIDTH-1:0][DATA_WIDTH-1:0] relin_key_tile;
    logic [NUM_RELIN_KEYS-1:0][ C2_TILE_WIDTH - 1:0][DATA_WIDTH-1:0]finished_c_intermediates, c_value_outputs_segment;
    logic [ C2_TILE_WIDTH - 1:0][NUM_RELIN_KEYS-1:0][DATA_WIDTH-1:0] tree_value_inputs;
    logic [C2_TILE_WIDTH - 1 :0] outputs_ready_signal_array;
    logic [NUM_RELIN_KEYS - 1 :0] intermediate_outputs_ready, done_signals; 

    relin_key_loader #(
        .RELIN_KEY_TILE_WIDTH(RELIN_KEYS_TILE_WIDTH),
        .RELIN_KEY_LENGTH(NUMBER_OF_RELIN_KEYS)
    ) relin
      (
       .clk(clk),
       .reset(rst),
       .request_signal(~done && inputs_ready_signal),
       .c1_or_c0(c1_or_c0),
       .valid_address(valid_address),
       .address(),
       .request_new_input(request_new_relin_tile),
       .relin_key(relin_key_tile),
       .relin_key_register_file(relin_key_register_file)
    );


    genvar multiplier_index, c_value_outputs_segment_index;
    generate
        for ( multiplier_index = 0; multiplier_index < NUM_RELIN_KEYS; multiplier_index = multiplier_index + 1 )
            begin   
                for ( c_value_outputs_segment_index = 0; c_value_outputs_segment_index < C2_TILE_WIDTH; c_value_outputs_segment_index = c_value_outputs_segment_index + 1 ) begin
                    assign c_value_outputs_segment[multiplier_index][c_value_outputs_segment_index] = {{(DATA_WIDTH-SLICE_WIDTH){1'b0}}, poly_mult_outputs[c_value_outputs_segment_index][((multiplier_index+1)*SLICE_WIDTH-1):(multiplier_index*SLICE_WIDTH)]} ;
                end
                
                poly_mult_top #(
                    .POLY_A_WIDTH(NUMBER_OF_RELIN_KEYS),
                    .POLY_B_WIDTH(C2_WIDTH),
                    // POLY_A_TILE_WIDTH and C2_TILE_WIDTH need to be divisible by each other
                    .POLY_A_TILE_WIDTH(RELIN_KEYS_TILE_WIDTH),
                    .POLY_B_TILE_WIDTH(C2_TILE_WIDTH), 
                    .DATA_WIDTH(DATA_WIDTH)
                ) mult
                (
                    .clk(clk),
                    .rst(rst),
                    .inputs_ready_signal(valid_address),
                    .tile_a(relin_key_tile[multiplier_index]),
                    .tile_b(c_value_outputs_segment[multiplier_index]),
                    .c_value_outputs(finished_c_intermediates[multiplier_index]),
                    .outputs_ready_signal(intermediate_outputs_ready[multiplier_index]),
                    .relin_done(done_signals[multiplier_index])
                );


            end
    endgenerate

    genvar c_value;
    generate
        for ( multiplier_index = 0; multiplier_index < NUM_RELIN_KEYS; multiplier_index = multiplier_index + 1 ) begin   
                for ( c_value = 0; c_value < C2_TILE_WIDTH; c_value = c_value + 1 ) begin   
                        assign tree_value_inputs[c_value][multiplier_index] = finished_c_intermediates[multiplier_index][c_value];
                    end
            end
    endgenerate

    generate
        for ( c_value = 0; c_value < C2_TILE_WIDTH; c_value = c_value + 1 )
            begin   
                adder_tree #(
                    .INPUTS_NUM (NUM_RELIN_KEYS),
                    .IDATA_WIDTH(DATA_WIDTH)
                ) relin_adder (
                    .clk  (clk),
                    .nrst (rst),
                    .inputs_ready_signal(intermediate_outputs_ready[0]),
                    .idata(tree_value_inputs[c_value]),
                    .odata(output_value[c_value]),
                    .outputs_ready_signal(outputs_ready_signal_array[c_value])
                    );
            end
    endgenerate

    assign outputs_ready_signal = outputs_ready_signal_array[0];
    assign done = done_signals[0];
    assign dequeue = request_new_relin_tile && ~done;



endmodule

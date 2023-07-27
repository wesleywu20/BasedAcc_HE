module relin_unit #(
    parameter DATA_WIDTH = 64,
    parameter RELIN_KEYS_TILE_WIDTH = 8, //Tile width of relin keys
    parameter C2_TILE_WIDTH = 8, //width of polymult outputs
    parameter DEGREE_OF_RELIN_KEYS = 512,
    parameter C2_WIDTH = 512, 
    parameter NUM_RELIN_KEYS = 8,
    parameter MOD_VALUE = 1048193
    )(
    input logic clk,
    input logic rst,
    input logic valid_i,
    input logic key_select_i,
    input logic [ C2_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] coeff_i,
    input logic [1:0][NUM_RELIN_KEYS-1:0][DEGREE_OF_RELIN_KEYS-1:0][DATA_WIDTH-1:0] relin_key_register_file,
    output logic [ C2_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] coeff_o,
    output logic valid_o, 
    output logic ready_o,
    output logic done
);
    localparam ZERO_EXTENDED_WIDTH =  (DATA_WIDTH%NUM_RELIN_KEYS == 0)? DATA_WIDTH : (DATA_WIDTH + NUM_RELIN_KEYS - (DATA_WIDTH%NUM_RELIN_KEYS));
    localparam SLICE_WIDTH =  ZERO_EXTENDED_WIDTH/NUM_RELIN_KEYS;
    logic valid_address, request_new_relin_tile, next_output_ready_signal, clear_signals;
    logic [3:0][ C2_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] input_array;
    logic [NUM_RELIN_KEYS-1:0][RELIN_KEYS_TILE_WIDTH-1:0][DATA_WIDTH-1:0] relin_key_tile;
    logic [ C2_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] saved_inputs;
    logic [NUM_RELIN_KEYS-1:0][ C2_TILE_WIDTH - 1:0][DATA_WIDTH-1:0]finished_c_intermediates, c_value_outputs_segment;
    logic [ C2_TILE_WIDTH - 1:0][NUM_RELIN_KEYS-1:0][DATA_WIDTH-1:0] tree_value_inputs;
    logic [C2_TILE_WIDTH - 1 :0] outputs_ready_signal_array;
    logic [NUM_RELIN_KEYS - 1 :0] intermediate_outputs_ready, done_signals; 
    logic [ C2_TILE_WIDTH - 1:0][ZERO_EXTENDED_WIDTH-1:0] extended_poly_mult_outputs;
    logic [ C2_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] output_value_unmod;
    logic [ C2_WIDTH + DEGREE_OF_RELIN_KEYS :0][DATA_WIDTH-1:0] output_value_full;
    logic [$clog2(DEGREE_OF_RELIN_KEYS + C2_WIDTH ) - 1 : 0 ]output_base_address, input_array_index;
    logic [NUM_RELIN_KEYS - 1 :0][$clog2(DEGREE_OF_RELIN_KEYS + C2_WIDTH )-1:0] output_value_index_array;
    logic [$clog2(NUM_RELIN_KEYS) :0][$clog2(DEGREE_OF_RELIN_KEYS + C2_WIDTH )-1:0] output_value_index_staged;

    genvar c2_tile_index;
    generate
        for (c2_tile_index = 0; c2_tile_index < C2_TILE_WIDTH; c2_tile_index++) begin
            assign extended_poly_mult_outputs[c2_tile_index] = {{(ZERO_EXTENDED_WIDTH-DATA_WIDTH){1'b0}}, saved_inputs[c2_tile_index]};
        end
    endgenerate


    always_ff @(posedge valid_i) begin
        saved_inputs <= coeff_i;
    end

    // assign input_array[0] = {64'hF1E61, 64'hD8923, 64'hF94, 64'hCDA44};
    // assign input_array[1] = {64'h68286, 64'h790DC, 64'h9FFC9, 64'hB4F80};
    // assign input_array[2] = {64'hC6C9A, 64'hA53C5, 64'hB2830, 64'h545CC};
    // assign input_array[3] = {64'hAA9BC, 64'h8F852, 64'hB2C4D, 64'hDDF52};


    // always_ff @(posedge valid_i or negedge rst) begin
    //     if (~rst) begin
    //         input_array_index <= 0;
    //     end else begin
    //         input_array_index <= input_array_index + 1;
    //         saved_inputs <= input_array[input_array_index];
    //     end
    // end



    relin_key_loader #(
        .RELIN_KEY_TILE_WIDTH(RELIN_KEYS_TILE_WIDTH),
        .RELIN_KEY_LENGTH(DEGREE_OF_RELIN_KEYS),
        .NUM_RELIN_KEYS(NUM_RELIN_KEYS),
        .DATA_WIDTH(DATA_WIDTH)
    ) relin
      (
       .clk(clk),
       .reset(rst),
       .request_signal(~done && valid_i),
       .c1_or_c0(key_select_i),
       .valid_address(valid_address),
       .address(),
       .request_new_input(request_new_relin_tile),
       .relin_key_register_file(relin_key_register_file),
       .relin_key(relin_key_tile)
    );


    genvar multiplier_index, c_value_outputs_segment_index;
    generate
        for ( multiplier_index = 0; multiplier_index < NUM_RELIN_KEYS; multiplier_index = multiplier_index + 1 )
            begin   
                for ( c_value_outputs_segment_index = 0; c_value_outputs_segment_index < C2_TILE_WIDTH; c_value_outputs_segment_index = c_value_outputs_segment_index + 1 ) begin
                    assign c_value_outputs_segment[multiplier_index][c_value_outputs_segment_index] = {{(DATA_WIDTH-SLICE_WIDTH){1'b0}}, extended_poly_mult_outputs[c_value_outputs_segment_index][((multiplier_index+1)*SLICE_WIDTH-1):(multiplier_index*SLICE_WIDTH)]} ;
                end
                
                poly_mult_top #(
                    .POLY_A_WIDTH(DEGREE_OF_RELIN_KEYS),
                    .POLY_B_WIDTH(C2_WIDTH),
                    // POLY_A_TILE_WIDTH and C2_TILE_WIDTH need to be divisible by each other
                    .POLY_A_TILE_WIDTH(RELIN_KEYS_TILE_WIDTH),
                    .POLY_B_TILE_WIDTH(C2_TILE_WIDTH), 
                    .DATA_WIDTH(DATA_WIDTH)
                ) mult
                ( 
                    .clk(clk),
                    .rst(rst && clear_signals),
                    .inputs_ready_signal(valid_address),
                    .tile_a(relin_key_tile[multiplier_index]),
                    .tile_b(c_value_outputs_segment[multiplier_index]),
                    .c_value_outputs(finished_c_intermediates[multiplier_index]),
                    .outputs_ready_signal(intermediate_outputs_ready[multiplier_index]),
                    .relin_done(done_signals[multiplier_index]),
                    .output_value_index(output_value_index_array[multiplier_index])
                );


            end
    endgenerate
    assign output_value_index_staged[0] = output_value_index_array[0];
    genvar stage_number;
  generate
    for (stage_number = 0; stage_number<$clog2(NUM_RELIN_KEYS) ; stage_number = stage_number + 1)
      always_ff @(posedge clk) begin
        begin
          output_value_index_staged[stage_number+1] <= output_value_index_staged[stage_number];
        end 
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
                    .odata(output_value_unmod[c_value]),
                    .outputs_ready_signal(outputs_ready_signal_array[c_value])
                    );
            end
    endgenerate


    generate
        for ( c_value = 0; c_value < C2_TILE_WIDTH; c_value = c_value + 1 )
           
            begin   
                always_ff @(posedge clk) begin
                    if (outputs_ready_signal_array[0]) begin
                        output_value_full[output_value_index_staged[$clog2(NUM_RELIN_KEYS)] + c_value] <= output_value_unmod[c_value] % MOD_VALUE;
                    end                
                end 
            end
    endgenerate

     generate
        for ( c_value = 0; c_value < C2_TILE_WIDTH; c_value = c_value + 1 )
           
            begin   
                always_ff @(posedge clk) begin
                    if (outputs_ready_signal_array[0] && output_value_index_staged[$clog2(NUM_RELIN_KEYS)]>= (C2_WIDTH+NUM_RELIN_KEYS)/2+C2_TILE_WIDTH) begin
                        coeff_o[c_value] <= $signed(((output_value_full[output_value_index_staged[$clog2(NUM_RELIN_KEYS)] - C2_TILE_WIDTH + c_value - (C2_WIDTH+NUM_RELIN_KEYS)/2] - output_value_unmod[c_value]% MOD_VALUE) + MOD_VALUE)%MOD_VALUE);
                        next_output_ready_signal <= 1;
                    end else begin
                        next_output_ready_signal <= 0;
                        coeff_o[c_value] <= 'x;

                    end               
                end 
            end
    endgenerate

    assign valid_o = next_output_ready_signal;
    assign done = done_signals[0];
    assign ready_o = request_new_relin_tile;

    always_ff @(posedge clk) begin
        if (done && next_output_ready_signal) begin
            clear_signals <= 0;
        end else begin
            clear_signals <= 1;
        end
    end




endmodule

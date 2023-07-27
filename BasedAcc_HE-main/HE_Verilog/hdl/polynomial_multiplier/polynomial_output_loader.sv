

`resetall
`timescale 1ns/10ps

module polynomial_output_loader #(
    parameter POLY_A_WIDTH = 128,
    parameter POLY_B_WIDTH = 128,
    // POLY_A_TILE_WIDTH and POLY_B_TILE_WIDTH need to be divisible by each other
    parameter POLY_A_TILE_WIDTH = 8,
    parameter POLY_B_TILE_WIDTH = 8, 
    parameter DATA_WIDTH = 64
)
(
   input logic clk,
   input logic rst,
   input logic tile_ready, //high when adder_tree_outputs is valid
   input logic [ (POLY_A_TILE_WIDTH + POLY_B_TILE_WIDTH - 1) - 1 :0][DATA_WIDTH-1:0] adder_tree_outputs, //newly calculated intermediate c values
   output logic [ POLY_B_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] c_value_outputs, //finished c values
   output logic ready_signal, //high when c_value_outputs has valid values to output
   output logic relin_done,
   output logic [$clog2(POLY_A_WIDTH + POLY_B_WIDTH)-1:0] output_value_index,
   output logic done

);

    localparam TILE_INDEX_WIDTH = $clog2((POLY_A_WIDTH/POLY_A_TILE_WIDTH) * (POLY_B_WIDTH/POLY_B_TILE_WIDTH) );

    logic [(POLY_A_WIDTH + POLY_B_WIDTH - 1)-1:0][DATA_WIDTH-1:0] c_values;

    logic [TILE_INDEX_WIDTH:0] tile_index;
    logic [$clog2(POLY_A_WIDTH + POLY_B_WIDTH - 1)-1:0] c_value_write_pointer;
    logic [$clog2(POLY_A_WIDTH + POLY_B_WIDTH - 1)-1:0] c_value_read_pointer;

    logic [TILE_INDEX_WIDTH:0] next_tile_index;
    logic [$clog2(POLY_A_WIDTH + POLY_B_WIDTH - 1)-1:0] next_c_value_write_pointer;
    logic [$clog2(POLY_A_WIDTH + POLY_B_WIDTH - 1)-1:0] next_c_value_read_pointer;


    typedef enum { WAIT, NEW_COLUMN, LAST_COLUMN, OUTPUT_LAST_SECTION, DONE } state;
    state curr_state, next_state;
    logic  next_ready_signal;

    

    always_ff @(posedge clk or negedge rst) begin
                if(~rst) begin
                    c_values <= {(POLY_A_WIDTH + POLY_B_WIDTH - 1){DATA_WIDTH'(0)}};
                    tile_index <= 0;
                    c_value_write_pointer <= 0;
                    c_value_read_pointer <= 0;
                    curr_state <= WAIT;
                end else if (curr_state == DONE) begin
                   
                    c_values <= 'x;
                    tile_index <= 'x;
                    c_value_write_pointer <= 'x;
                    c_value_read_pointer <= 'x;
                end else if (curr_state == OUTPUT_LAST_SECTION) begin
                   
                    c_values <= 'x;
                    tile_index <= 'x;
                    c_value_write_pointer <= 'x;
                    c_value_read_pointer <= 'x;
                    curr_state <= DONE;
                end
                else begin
                
                    tile_index <= next_tile_index;
                    c_value_write_pointer <= next_c_value_write_pointer;
                    c_value_read_pointer <= next_c_value_read_pointer;
                    curr_state <= next_state;
                end 
                ready_signal <= next_ready_signal;

    end 

    genvar k;
    generate
        for (k = 0; k < (POLY_A_TILE_WIDTH + POLY_B_TILE_WIDTH - 1); k = k + 1) begin
            always_ff @(posedge clk) begin
                if (tile_ready && next_state != OUTPUT_LAST_SECTION) begin
                    c_values[c_value_write_pointer + k] <= c_values[c_value_write_pointer + k] + adder_tree_outputs[k];
                end
            end 
        end
    endgenerate

    generate
        for (k = 0; k < POLY_B_TILE_WIDTH; k = k + 1) begin
            always_ff @(posedge clk) begin
                if (curr_state==OUTPUT_LAST_SECTION) begin 
                    c_value_outputs[k] <= (k != POLY_B_TILE_WIDTH-1) ? c_values[(POLY_A_WIDTH + POLY_B_WIDTH - 1)-(POLY_B_TILE_WIDTH-1-k)] : 0;
                end else if (curr_state==LAST_COLUMN || curr_state == NEW_COLUMN) begin
                    c_value_outputs[k] <= c_values[c_value_read_pointer  - POLY_B_TILE_WIDTH + k];

                end else begin 
                    c_value_outputs[k] <= 'x;
                end 
            end 
        end
    endgenerate
    always_ff @(posedge clk) begin
        if (curr_state==OUTPUT_LAST_SECTION) begin 
            output_value_index <= (POLY_A_WIDTH + POLY_B_WIDTH - 1)-(POLY_B_TILE_WIDTH-1);
        end else if (curr_state==LAST_COLUMN || curr_state == NEW_COLUMN) begin
            output_value_index <= c_value_read_pointer  - POLY_B_TILE_WIDTH;
        end else begin 
            output_value_index <= 'x;
        end 
    end
    always_comb begin
            next_state = WAIT;
            next_tile_index = tile_index;
            next_c_value_write_pointer = c_value_write_pointer;
            next_c_value_read_pointer = c_value_read_pointer;
            if(tile_index == (POLY_A_WIDTH/POLY_A_TILE_WIDTH) * (POLY_B_WIDTH/POLY_B_TILE_WIDTH)) begin 
                            next_state = OUTPUT_LAST_SECTION;
                            next_tile_index = 0;

            end
            else if (tile_ready) begin 
                next_tile_index = tile_index + 1;
                if (tile_index>=((POLY_A_WIDTH/POLY_A_TILE_WIDTH) * (POLY_B_WIDTH/POLY_B_TILE_WIDTH))-(POLY_A_WIDTH/POLY_A_TILE_WIDTH) )begin 
                       

                        if ((next_c_value_write_pointer + POLY_A_TILE_WIDTH)%POLY_B_TILE_WIDTH == 0) begin
                            next_state = LAST_COLUMN;
                            next_c_value_read_pointer = c_value_read_pointer + POLY_B_TILE_WIDTH;
                        end else begin
                            next_state = WAIT;
                            next_c_value_read_pointer = c_value_read_pointer;
                        end
                        next_c_value_write_pointer = c_value_write_pointer + POLY_A_TILE_WIDTH;
                        
                        
                end 
                else if(tile_index%(POLY_A_WIDTH/POLY_A_TILE_WIDTH)==0 && tile_index > 0) begin
                        
                        next_c_value_write_pointer = c_value_write_pointer + POLY_A_TILE_WIDTH;
                        next_c_value_read_pointer = c_value_read_pointer;
                end
                else if(tile_index%(POLY_A_WIDTH/POLY_A_TILE_WIDTH)==(POLY_A_WIDTH/POLY_A_TILE_WIDTH-1)) begin
                    next_state = NEW_COLUMN;
                        next_c_value_write_pointer = c_value_read_pointer + POLY_B_TILE_WIDTH;
                        next_c_value_read_pointer = c_value_read_pointer + POLY_B_TILE_WIDTH;
                end else begin
                        next_c_value_write_pointer = c_value_write_pointer + POLY_A_TILE_WIDTH;
                        next_c_value_read_pointer = c_value_read_pointer;
                        next_state = WAIT;
                end
            end 
    end

    assign next_ready_signal = (curr_state == NEW_COLUMN || curr_state == LAST_COLUMN || curr_state == OUTPUT_LAST_SECTION);
    assign done = (curr_state == DONE);
    assign relin_done = curr_state == LAST_COLUMN || curr_state == DONE || curr_state == OUTPUT_LAST_SECTION ;

endmodule

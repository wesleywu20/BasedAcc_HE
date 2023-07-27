module relin_address_generator #(
    parameter RELIN_KEY_TILE_WIDTH = 8,
    parameter RELIN_KEY_LENGTH = 64 
)(
    input logic clk,
    input logic reset,
    input logic request_signal,
    output logic valid_address,
    output logic [$clog2(RELIN_KEY_LENGTH):0] address
);
typedef enum { WAIT, BURST} state;
state curr_state ;
always_ff @(posedge clk or negedge reset) begin
    if (~reset ) begin
        address <= RELIN_KEY_LENGTH;
        valid_address <= 0;
        curr_state <= WAIT;
    end else if (request_signal) begin
        if (address == 0 && valid_address == 0 && curr_state == WAIT) begin
            curr_state <= BURST;
            valid_address <= 1;
        end else begin 
            if (address >= RELIN_KEY_LENGTH-RELIN_KEY_TILE_WIDTH) begin
                curr_state <= BURST;
                address <= 0;
                valid_address <= 1;
            end else begin
                curr_state <= BURST;
                address <= address + RELIN_KEY_TILE_WIDTH; 
                valid_address <= 1;
            end
        end 

    end else begin
        valid_address <= 0;
    end
end


endmodule
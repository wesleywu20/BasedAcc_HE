`ifndef polymult_itf
`define polymult_itf

interface polymult_itf  #(
    parameter DATA_WIDTH = 64,
    parameter POLY_A_TILE_WIDTH = 8,
    parameter POLY_B_TILE_WIDTH = 8,
    parameter POLY_A_WIDTH = 64,
    parameter POLY_B_WIDTH = 64
);

bit clk;
initial begin
    clk = 1'b0;
    forever begin
        #2.5;
        clk = ~clk;
    end
end

time timestamp;
initial timestamp = '0;
always @(posedge clk) timestamp += '1;

logic rst, inputs_ready_signal;
logic [POLY_A_TILE_WIDTH-1:0][DATA_WIDTH-1:0] tile_a, tile_b;
logic [POLY_B_TILE_WIDTH-1:0][2*DATA_WIDTH-1:0] c_value_outputs;
logic outputs_ready_signal, done, ready_for_tile;

modport testbench (
    output c_value_outputs, rst, tile_a, tile_b, inputs_ready_signal, outputs_ready_signal, done, ready_for_tile,
    input clk,
    ref timestamp,
    import task finish()
);

task finish();
    #1000;
    $finish;
endtask

endinterface : polymult_itf
`endif

`ifndef multiplier_itf
`define multiplier_itf

`include "../mult_constants.sv"

interface multiplier_itf;
bit clk;
logic [63:0] multiplicand, multiplier;
logic [7:0] byte_multiplier;
logic [63:0] half_product;
logic [71:0] small_product;
logic [127:0] product;
time timestamp;

// Clock generation
initial begin
    clk = 1'b0;
    forever begin
        #5;
        clk = ~clk;
    end
end

initial timestamp = '0;
always @(posedge clk) timestamp += '1;

/* define testbench modport to be half multiplier width based if macro defined */
`ifdef test_full_mult
    modport testbench (
            output product, multiplier, multiplicand,
            input clk,
            ref timestamp,
            import task finish()
        );
`endif

/* define testbench modport to be full multiplier width based if macro defined */
`ifdef test_half_mult
    modport testbench (
            output half_product, multiplier, multiplicand,
            input clk,
            ref timestamp,
            import task finish()
        );
`endif

`ifdef test_param_mult
    modport testbench (
            output multiplicand, byte_multiplier, small_product,
            input clk,
            ref timestamp,
            import task finish()
    );
`endif

task finish();
    #1000;
    $finish;
endtask

endinterface : multiplier_itf
`endif

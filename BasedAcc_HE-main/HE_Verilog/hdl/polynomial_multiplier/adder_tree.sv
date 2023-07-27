/*
Partially from https://github.com/pConst/basic_verilog/blob/master/adder_tree.sv. 
Creates an adder tree to sum up a parameterized number of terms

Code was modified to increase parameterization, and isolate the addition operation, so that a custom adder module can be added. 
*/


module adder_tree #(
    parameter INPUTS_NUM  = 125,
    parameter IDATA_WIDTH = 16,

    parameter STAGES_NUM = $clog2(INPUTS_NUM),
    parameter INPUTS_NUM_INT = 2 ** STAGES_NUM,
    parameter ODATA_WIDTH = IDATA_WIDTH + STAGES_NUM
) (
    input logic clk,
    input logic nrst,
    input logic inputs_ready_signal,
    input logic [INPUTS_NUM-1:0][IDATA_WIDTH-1:0] idata,
    output logic [ODATA_WIDTH-1:0] odata,
    output logic outputs_ready_signal
);

  logic [STAGES_NUM:0] ready_signals;
  logic [STAGES_NUM:0][INPUTS_NUM_INT-1:0][ODATA_WIDTH-1:0] data;
  logic [STAGES_NUM:0][INPUTS_NUM_INT-1:0][ODATA_WIDTH-1:0] intermediate;


  assign ready_signals[0] = inputs_ready_signal;
  genvar stage_number;
  generate
    for (stage_number = 0; stage_number<STAGES_NUM; stage_number = stage_number + 1)
      always_ff @(posedge clk) begin
        begin
          ready_signals[stage_number+1] <= ready_signals[stage_number];
        end 
      end
  endgenerate

  // generating tree
  genvar stage, adder;
  generate
    for (stage = 0; stage <= STAGES_NUM; stage++) begin : stage_gen

      localparam ST_OUT_NUM = INPUTS_NUM_INT >> stage;
      localparam ST_WIDTH = IDATA_WIDTH + stage;

      if (stage == '0) begin
        for (adder = 0; adder < ST_OUT_NUM; adder++) begin : inputs_gen

          always_comb begin
            if (adder < INPUTS_NUM) begin
              data[stage][adder][ST_WIDTH-1:0] <= idata[adder][ST_WIDTH-1:0];
              data[stage][adder][ODATA_WIDTH-1:ST_WIDTH] <= '0;
            end else begin
              data[stage][adder][ODATA_WIDTH-1:0] <= '0;
            end
          end  

        end  // for
      end else begin
        for (adder = 0; adder < ST_OUT_NUM; adder++) begin : adder_gen

          adder #(
              .INPUT_WIDTH (ST_WIDTH - 1),
              .OUTPUT_WIDTH(ST_WIDTH)
          ) add (
              .a  (data[stage-1][adder*2][(ST_WIDTH-1)-1:0]),
              .b  (data[stage-1][adder*2+1][(ST_WIDTH-1)-1:0]),
              .sum(intermediate[stage][adder][ST_WIDTH-1:0])
          );

          //always_comb begin       // is also possible here
          always_ff @(posedge clk) begin
            if (~nrst) begin
              data[stage][adder][ODATA_WIDTH-1:0] <= '0;
            end else begin
              data[stage][adder][ST_WIDTH-1:0] <= intermediate[stage][adder][ST_WIDTH-1:0];
            end
          end  // always

        end  // for
      end  // if stage
    end  // for
  endgenerate

  assign odata = data[STAGES_NUM][0];
  assign outputs_ready_signal = ready_signals[STAGES_NUM];
endmodule


`include "he_headers.sv"

module processor(
                 input logic                   clk,
                 input logic                   rst,
                 input logic [`BIT_WIDTH-1:0]  t,
                 input logic [`BIT_WIDTH-1:0]  q,
                 input logic [`BIT_WIDTH-1:0]  data_i,
                 input logic                   valid_i,
                 output logic                  ready_o,
                 output logic [`BIT_WIDTH-1:0] data_o,
                 output logic                  done_o
                 );

   logic [`BIT_WIDTH-1:0]                     mul_i;
   logic [2*`BIT_WIDTH-1:0]                   mul_o;
   logic                                      done_mu_o, start_mu_i;

   assign mul_i = data_i;
   assign start_mu_i = valid_i;


   always_ff @(posedge clk) begin
      if(~rst | done_mu_o) ready_o = 1'b1;
      else if(start_mu_i)  ready_o = 1'b0;
   end

   mu mu(
         .clk(clk),
         .rst(rst),
         .a(mul_i),
         .b(t),
         .c(mul_o),
         .start(start_mu_i),
         .done(done_mu_o)
         );

   logic [2*`BIT_WIDTH-1:0]               div_i;
   logic [`BIT_WIDTH-1:0]                 div_o;
   logic                                  start_div_a_i, done_div_a_o;
   assign div_i = mul_o; // wire to make this more readable
   assign start_div_a_i = done_mu_o;

   du du(
           .clk(clk),
           .rst(rst),
           .dividend(div_i),
           .divisor(q),
           .quotient(div_o),
           .remainder(), // ignore
           .start(start_div_a_i),
           .done(done_div_a_o)
           );

   logic [`BIT_WIDTH-1:0]               mod_i, mod_o;
   logic                                start_modu_i, done_modu_o;
   assign mod_i = div_o;
   assign start_modu_i = done_div_a_o;

   du modu(
           .clk(clk),
           .rst(rst),
           .dividend({{`BIT_WIDTH{1'b0}}, mod_i}),
           .divisor(q),
           .quotient(), // ignore
           .remainder(mod_o),
           .start(start_modu_i),
           .done(done_modu_o)
           );

   assign done_o = done_modu_o;
   assign data_o = mod_o;

endmodule : processor

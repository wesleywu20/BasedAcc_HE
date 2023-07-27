`define BAD_MUX_SEL $display("Illegal mux select")

module cmp
import rv32i_types::*;
(
    input branch_funct3_t cmpop,
    input logic [31:0] a, b,
    output logic br_en
);

always_comb
begin
    unique case (cmpop)
    beq: if(a == b) br_en=1'b1;
		 else br_en=1'b0;

    bne: if(a != b) br_en=1'b1;
		 else br_en=1'b0;

    blt: if($signed(a) < $signed(b)) br_en=1'b1;
		 else br_en=1'b0;

    bge: if($signed(a) >= $signed(b)) br_en=1'b1;
		 else br_en=1'b0;

    bltu: if(a < b) br_en=1'b1;
		 else br_en=1'b0;

    bgeu: if(a >= b) br_en=1'b1;
		 else br_en=1'b0;
    default: `BAD_MUX_SEL;
    endcase
end

endmodule : cmp

`ifndef testbench1
`define testbench1
module testbench1;

    logic clk;
    logic rst; 
    logic[31:0] i_cache;
    logic mem_resp,station_ready;
    logic valid_o;
    instr_struct data_o;

    logic[31:0] cache_pc;
    //logic[31:0] current_pc;

    logic[31:0] inst_pc;
    logic [6:0] opcode; 
    logic [4:0] rs1, rs2, rd;
    logic [2:0] funct3;
    logic [31:0] imm_val;
    logic subtract,not_empty,flush;
    //output logic imm_on,
    //logic assert_o;

    logic enqueue_assert;
    logic dequeue_assert;

    always #5 clk = (clk === 1'b0);



top dut (
    .clk(clk),
    .rst(rst), 
    .i_cache(i_cache),
    .mem_resp(mem_resp),
    .station_ready(station_ready), //go ahead and dequeue
    .flush(flush),
    .not_empty(not_empty),
    //.valid_o(valid_o),
    .cache_pc(cache_pc),
    .subtract(subtract),
    //.current_pc(current_pc)
    //assert that we have dequed 

    .inst_pc(inst_pc),
    .opcode(opcode),  
    .rs1(rs1), .rs2(rs2), .rd(rd),
    .funct3(funct3),
    .imm_val(imm_val),
    //output logic imm_on,
    .dequeue_assert(dequeue_assert),
    .enqueue_assert(enqueue_assert)
);

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, testbench, "+all");
end

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge clk); endclocking

task reset();
    rst <= 1'b0;
    ##(10);
    rst <= 1'b1;
    ##(1);
endtask : reset

task finish();
    repeat (2000) @(posedge clk);
    $finish;
endtask




// DO NOT MODIFY CODE ABOVE THIS LINE

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Fill the enquer until the signal says it is full
    // 256 loop 256
    //for(int i=0;i<256;i++)begin 
    //end 
    station_ready <= '0; //should dequeue
    mem_resp<= '1;
    i_cache <= 32'h00000597;
    ##(1)
    mem_resp<= '0;
    ##(1)
    mem_resp<= '1;
    i_cache <= 32'h1a058593;
    ##(1)
    mem_resp<= '0;
    ##(1)
    mem_resp<= '1;
    i_cache <= 32'h18072703;
    ##(1)
    mem_resp<= '0;
    ##(1)
    mem_resp<= '1;
    i_cache <= 32'h00a5a023;
    ##(1)
    mem_resp<= '0;
    ##(1)
    mem_resp<= '1;
    i_cache <= 32'h00000063;
    ##(1)
    mem_resp<= '0;
    ##(1)
    station_ready <= '1; //should dequeue
    ##(1)
    station_ready <= '0; //should dequeue
    ##(1)
    station_ready <= '1; //should dequeue
    ##(1)
    station_ready <= '0; //should dequeue
   ##(1)
    station_ready <= '1; //should dequeue
    ##(1)
    station_ready <= '0; //should dequeue
    ##(1)
    mem_resp<= '1;
    i_cache <= 32'h00000597;
    ##(1)
    mem_resp<= '0;
    ##(1)
    mem_resp<= '1;
    i_cache <= 32'h1a058593;
    ##(1)

     

    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    finish();
    $error("TB: Illegal Exit ocurred");
end


endmodule 
`endif

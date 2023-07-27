`ifndef testbench
`define testbench

module testbench;

    logic clk;
    logic rst;

    logic queue_ready;

    instr_struct decoded_update; // after decoding
    logic get_next_pc;

    logic [31:0]cache_pc,current_pc;

    logic branch_complete;
    logic [2:0]branch_ID_i;
    logic [31:0]branch_result;
    logic flush;
    //input [31:0]old_branch_addr, // from Arpan

    logic [2:0]branch_ID_o;
    //output [31:0]branch_NT_address, // for Arpan
    logic [31:0]prediction;

    always #5 clk = (clk === 1'b0);


I_fetch dut (
    .clk(clk),
    .rst(rst), 

    .queue_ready(queue_ready),

    .decoded_update(decoded_update), // after decoding
    .get_next_pc(get_next_pc),

    .cache_pc(cache_pc),
    .current_pc(current_pc),

    .branch_complete(branch_complete),
    .branch_ID_i(branch_ID_i),
    .branch_result(branch_result),
    .flush(flush),
    //input [31:0]old_branch_addr, // from Arpan

    .branch_ID_o(branch_ID_o),
    //output [31:0]branch_NT_address, // for Arpan
    .prediction(prediction)
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
   get_next_pc <= 1'b1;
   decoded_update.opcode <= 7'b1100011;
   decoded_update.pc <= 31'b0101010;
   branch_complete <= 1'b0;

   ##(5);
   branch_complete <= 1'b1;
   branch_ID_i <= 2'b01;
   branch_result <= 1'b1;

     

    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    finish();
    $error("TB: Illegal Exit ocurred");
end


endmodule 
`endif

module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/

//Instantiate Interfaces
tb_itf itf();

rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);
int fd_00,fd_01,fd_10,fd_11,fd_relin;
int fd_c0,fd_c1,fd_c2,fd_file;
int fd_final0,fd_final1;
logic [7:0] ct0_0;
logic [7:0] ct0_1;
logic [7:0] ct1_0;
logic [7:0] ct1_1;
logic [7:0] relin;

logic [7:0] c0,c1,c2;
logic [7:0] final0,final1;
// Dump signals
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, mp4_tb, "+all");
end

logic load_signal;
assign load_signal = dut.tomasulo0.accel_res_station0.accel0.load_done;

initial begin
	@(posedge load_signal);
	fd_00 = $fopen("ct10_fresh.bin","r");
	fd_01 = $fopen("ct11_fresh.bin","r");
	fd_10 = $fopen("ct20_fresh.bin","r");
	fd_11 = $fopen("ct21_fresh.bin","r");

	fd_c0 = $fopen("ct_afterMul_0.bin","r");
	fd_c1 = $fopen("ct_afterMul_1.bin","r");
	fd_c2 = $fopen("ct_afterMul_2.bin","r");

	for(int i=0;i<512;i++) begin
		for(int j=0;j<8;j++) begin
			$fgets(ct0_0,fd_00);
			$fgets(ct0_1,fd_01);
			$fgets(ct1_0,fd_10);
			$fgets(ct1_1,fd_11);
			dut.tomasulo0.accel_res_station0.accel0.ct0[i][0][(j*8)+:8] <= ct0_0;
			dut.tomasulo0.accel_res_station0.accel0.ct0[i][1][(j*8)+:8] <= ct0_1;
			dut.tomasulo0.accel_res_station0.accel0.ct1[i][0][(j*8)+:8] <= ct1_0;
			dut.tomasulo0.accel_res_station0.accel0.ct1[i][1][(j*8)+:8] <= ct1_1;

			$fgets(c0,fd_c0);
			dut.tomasulo0.accel_res_station0.accel0.c0[i][(j*8)+:8] <= c0;

			$fgets(c1,fd_c1);
			dut.tomasulo0.accel_res_station0.accel0.c1[i][(j*8)+:8] <= c1;

			$fgets(c2,fd_c2);
			dut.tomasulo0.accel_res_station0.accel0.c2[i][(j*8)+:8] <= c2;

		end
	end
	fd_relin = $fopen("relinKey.bin","r");
	for(int j=0;j<8;j++) begin
		for(int i=0;i<512;i++) begin
			for(int z=0;z<8;z++) begin
				$fgets(relin,fd_relin);
				dut.tomasulo0.accel_res_station0.accel0.rln0[i][j][(z*8)+:8] <= relin;
			end
		end
		for(int i=0;i<512;i++) begin
			for(int z=0;z<8;z++) begin
				$fgets(relin,fd_relin);
				dut.tomasulo0.accel_res_station0.accel0.rln1[i][j][(z*8)+:8] <= relin;
			end
		end
	end
end
	
/****************************** End do not touch *****************************/

//logic[255:0] first_entry;
//assign first_entry = tb.mem._mem[0];

logic [2:0] head_pointer;
logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;
logic [6:0] opcode;
logic [31:0] instruction,instruction_current,true_instr;
longint timeout = 64'hF0000; 
longint cycles = 64'h0; 
longint count = 64'h0;
logic br_id;

int fd;
/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = dut.tomasulo0.rob0.write_back; // Set high when a valid instruction is modifying regfile or PC
assign head_pointer = dut.tomasulo0.rob0.head_pointer;
assign rvfi.halt = (rvfi.pc_wdata && rvfi.pc_rdata && (rvfi.pc_wdata == rvfi.pc_rdata)) ? 1 : 0;
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO


//Instruction and trap:
    assign rvfi.inst = instruction;
    assign rvfi.trap = 1'b0;

//Regfile:
    assign rvfi.rs1_addr = rs1; 
    assign rvfi.rs2_addr = rs2;
//    assign rvfi.rs1_rdata = dut.tomasulo0.regfile0.data[rs1];
//    assign rvfi.rs2_rdata = dut.tomasulo0.regfile0.data[rs2];
    assign rvfi.load_regfile = dut.tomasulo0.rob0.reg_wb;
    assign rvfi.rd_addr = rd;
    assign rvfi.rd_wdata = rd ? dut.tomasulo0.rob0.reg_data: 0;

//PC:
    assign rvfi.pc_rdata = dut.tomasulo0.rob0.instr_pc_[head_pointer];
    assign br_id = dut.tomasulo0.pc_send;

    always_comb begin
	if(opcode == 7'b1100011)begin
		if (!dut.tomasulo0.rob0.data[head_pointer])
			rvfi.pc_wdata = dut.tomasulo0.rob0.instr_pc_[head_pointer]+4;
		else
			rvfi.pc_wdata = dut.tomasulo0.rob0.instr_pc_[head_pointer]+ dut.tomasulo0.rob0.b_imm[head_pointer];
	end
	else if (opcode == 7'b1100111) 
		rvfi.pc_wdata = dut.tomasulo0.rob0.jal_save[head_pointer];
	else if (opcode == 7'b1101111) 
		rvfi.pc_wdata = dut.tomasulo0.rob0.instr_pc_[head_pointer] + dut.tomasulo0.rob0.j_imm[head_pointer];
	else
		rvfi.pc_wdata = dut.tomasulo0.rob0.instr_pc_[head_pointer]+4;
    end

//Memory:
    assign rvfi.mem_addr = itf.data_addr;
//    assign rvfi.mem_rmask =itf.data_mbe;
//    assign rvfi.mem_wmask = (itf.data_write) ? itf.data_mbe : 0;
    assign rvfi.mem_rdata = itf.data_rdata;
    assign rvfi.mem_wdata = itf.data_wdata;

//Please refer to rvfi_itf.sv for more information.


/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2

//The following signals need to be set:
//icache signals:
    assign itf.inst_read = dut.fetch_top.i_mem_read;
    assign itf.inst_addr = dut.fetch_top.cache_pc;
    assign itf.inst_resp = dut.fetch_top.mem_resp;
    assign itf.inst_rdata = dut.fetch_top.i_cache;

//dcache signals:
    assign itf.data_read = dut.tomasulo0.mem_read;
    assign itf.data_write = dut.tomasulo0.mem_write;
    assign itf.data_mbe = dut.tomasulo0.mem_byte_enable;
    assign itf.data_addr = dut.tomasulo0.address_d_cache;
    assign itf.data_wdata = dut.tomasulo0.data_d_cache;
    assign itf.data_resp = dut.tomasulo0.mem_resp;
    assign itf.data_rdata = dut.tomasulo0.data_ld;

//Please refer to tb_itf.sv for more information.


/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.tomasulo0.regfile0.data;;

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level for CP2:
Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/


based_cpu dut(
    .clk(itf.clk),
    .rst(itf.rst),
    
    // Use for CP2 onwards
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_wdata(itf.mem_wdata),
    .pmem_rdata(itf.mem_rdata),
    .pmem_address(itf.mem_addr),
    .pmem_resp(itf.mem_resp)
);

/*
based_cpu dut(
	.clk(itf.clk),
	.rst(itf.rst),
    .inst_read(itf.inst_read),
    .inst_addr(itf.inst_addr),
    .inst_resp(itf.inst_resp),
    .inst_rdata(itf.inst_rdata),
    .data_read(itf.data_read),
    .data_write(itf.data_write),
    .data_mbe(itf.data_mbe),
    .data_addr(itf.data_addr),
    .data_wdata(itf.data_wdata),
    .data_resp(itf.data_resp),
    .data_rdata(itf.data_rdata)

);
*/

logic add;
always_ff @(posedge itf.clk iff (dut.fetch_top.decode_I.load_ir)) begin

	true_instr <= instruction;
	instruction_current <= true_instr;

end


assign instruction = dut.tomasulo0.rob0.instruction[head_pointer];
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd = instruction[11:7];
assign opcode = instruction[6:0];

always @(rvfi.errcode iff (rvfi.errcode != 0)) begin
    repeat (30) @(posedge itf.clk);
    $display("TOP: Errcode: %0d", rvfi.errcode);
    $finish;
end

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (rvfi.halt)begin
        $display("BASED!");
        $display("cycles: %0d",cycles);
        $finish;
	end
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    cycles <= cycles + 1;
    timeout <= timeout - 1;
end

logic store_signal;
assign store_signal = dut.tomasulo0.accel_res_station0.accel0.mem_write;
logic [63:0] after_mult;
logic [7:0] ci;

initial begin
	@(posedge store_signal);
    $display("store signal detected!");
	fd=$fopen("ctR0.bin","w");

	for (int i=0;i<512;i++) begin
		$fwrite(fd,"%u",dut.tomasulo0.accel_res_station0.accel0.c0_out[i]);
	end
	$fclose(fd);

	fd=$fopen("ctR1.bin","w");
	for (int i=0;i<512;i++) begin
		$fwrite(fd,"%u",dut.tomasulo0.accel_res_station0.accel0.c1_out[i]);
	end
	$fclose(fd);
end

/***************************** End Instantiation *****************************/

endmodule

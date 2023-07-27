simSetSimulator "-vcssv" -exec "/home/arpanr2/mp4/sim/simv" -args
debImport "-dbdir" "/home/arpanr2/mp4/sim/simv.daidir"
debLoadSimResult /home/arpanr2/mp4/sim/dump.fsdb
wvCreateWindow
srcHBSelect "mp4_tb.dut" -win $_nTrace1
srcSetScope "mp4_tb.dut" -delim "." -win $_nTrace1
srcHBSelect "mp4_tb.dut" -win $_nTrace1
srcHBSelect "mp4_tb.dut.tomasulo0" -win $_nTrace1
srcSetScope "mp4_tb.dut.tomasulo0" -delim "." -win $_nTrace1
srcHBSelect "mp4_tb.dut.tomasulo0" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "opcode_i" -line 13 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSetCursor -win $_nWave2 5782544.217391 -snap {("G1" 1)}
wvZoom -win $_nWave2 0.000000 5140039.304348
wvSetCursor -win $_nWave2 2219208.071746 -snap {("G1" 1)}
wvSetCursor -win $_nWave2 1813825.801029 -snap {("G1" 1)}
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchPrev -win $_nWave2
wvZoom -win $_nWave2 1751459.297841 1881389.512815
srcHBSelect "mp4_tb.dut.tomasulo0.accel_res_station0" -win $_nTrace1
srcSetScope "mp4_tb.dut.tomasulo0.accel_res_station0" -delim "." -win $_nTrace1
srcHBSelect "mp4_tb.dut.tomasulo0.accel_res_station0" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "iq_assert" -line 8 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "free_o" -line 22 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "mp4_tb.dut.tomasulo0" -win $_nTrace1
srcSetScope "mp4_tb.dut.tomasulo0" -delim "." -win $_nTrace1
srcHBSelect "mp4_tb.dut.tomasulo0" -win $_nTrace1
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
srcHBSelect "mp4_tb.dut.tomasulo0.accel_res_station0" -win $_nTrace1
srcSetScope "mp4_tb.dut.tomasulo0.accel_res_station0" -delim "." -win $_nTrace1
srcHBSelect "mp4_tb.dut.tomasulo0.accel_res_station0" -win $_nTrace1
debReload
srcDeselectAll -win $_nTrace1
srcSelect -signal "alu_read" -line 155 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "load_busy" -line 132 -pos 2 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "busy" -line 143 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "r1" -line 146 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "r2_o" -line 148 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "src1" -line 147 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "src2" -line 149 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "mp4_tb.dut.tomasulo0" -win $_nTrace1
srcSetScope "mp4_tb.dut.tomasulo0" -delim "." -win $_nTrace1
srcHBSelect "mp4_tb.dut.tomasulo0" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "r1_i" -line 11 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "r2_i" -line 11 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 12 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSelectSignal -win $_nWave2 {( "G1" 11 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 10)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "r1_i" -line 11 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "src2_i" -line 12 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "opcode_i" -line 13 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pc_save" -line 15 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "funct3" -line 20 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
wvSetCursor -win $_nWave2 1851179.752519 -snap {("G1" 5)}
wvSetCursor -win $_nWave2 1844216.859300 -snap {("G1" 6)}
wvSetCursor -win $_nWave2 1845661.988081 -snap {("G1" 5)}
srcHBSelect "mp4_tb.dut.tomasulo0.accel_res_station0" -win $_nTrace1
srcSetScope "mp4_tb.dut.tomasulo0.accel_res_station0" -delim "." -win $_nTrace1
srcHBSelect "mp4_tb.dut.tomasulo0.accel_res_station0" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "free_o" -line 36 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "accel_done" -line 159 -pos 2 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "alu_read" -line 155 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 13 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvSelectSignal -win $_nWave2 {( "G1" 12 )} 
srcDeselectAll -win $_nTrace1
srcSelect -signal "busy" -line 50 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "load_alu" -line 54 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
srcDeselectAll -win $_nTrace1
srcSelect -signal "alu_read" -line 155 -pos 1 -win $_nTrace1
debReload
srcDeselectAll -win $_nTrace1
srcSelect -signal "alu_read" -line 155 -pos 1 -win $_nTrace1
debReload
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "cmd_buf.reg_id" -line 170 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSetCursor -win $_nWave2 1858392.258891 -snap {("G2" 1)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
debExit

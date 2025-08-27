Update: 2025/02/11

Source:
    >	source /usr/cad/cadence/cshrc
    >	source /usr/cad/synopsys/CIC/vcs.cshrc
    >	source /usr/cad/synopsys/CIC/verdi.cshrc
    >	source /usr/cad/synopsys/CIC/synthesis.cshrc

RTL simulation:
    > vcs RISCV_tb.v +define+RV32I+RTL -full64 -R -debug_access+all +v2k
    
    cp Netlist/CHIP_syn.v Netlist/CHIP_syn.sdf .

--------------------------------------------------------------------------
Files for synthesis:
- .synopsys_dc.setup
- CHIP_syn.tcl

Synthesis command:
    > dc_shell -f CHIP_syn.tcl

- To reopen the design:
    dc_shell> read_ddc CHIP_syn.ddc
- Close Design Compiler:
    dc_shell> exit
    
--------------------------------------------------------------------------
Post-synthesis simulation:
- Check if you have a SDF file (CHIP_syn.sdf)
- Check if you have a library file (tsmc13.v)
- Note: To copy tsmc13.v to your current directory:
    >	cp /home/raid7_2/course/cvsd/CBDK_IC_Contest/CIC/Verilog/tsmc13.v .

- simulation:
    >	vcs RISCV_tb.v +define+SYN -full64 -R -debug_access+all +v2k
--------------------------------------------------------------------------
Pattern generation:
- Open the python script in ./pattern/pattern_gen.py
- Change the variables in the script
- Run the script, and there will be two new files:
	data.txt
	ans.txt
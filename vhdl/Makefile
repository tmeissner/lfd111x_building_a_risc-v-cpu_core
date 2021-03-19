DESIGN     := risc_v
DESIGN_SRC := risc_v_pkg.vhd risc_v.vhd
TESTBENCH  := tb_${DESIGN}

.PHONY: sim
sim: tb_${DESIGN}.ghw

${TESTBENCH}.ghw : ${DESIGN_SRC} ${TESTBENCH}.vhd
	ghdl -a --std=08 ${DESIGN_SRC} ${TESTBENCH}.vhd
	ghdl -e --std=08 ${TESTBENCH}
	ghdl -r --std=08 ${TESTBENCH} --vcd=${TESTBENCH}.vcd --wave=$@

.PHONY: clean
clean:
	rm ${TESTBENCH} ${TESTBENCH}.ghw ${TESTBENCH}.vcd work* *.o

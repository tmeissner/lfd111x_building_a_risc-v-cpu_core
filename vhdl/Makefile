DESIGN     := risc_v
DESIGN_SRC := risc_v_pkg.vhd risc_v.vhd
TESTBENCH  := tb_${DESIGN}

DEFAULT: sim

${TESTBENCH} : ${DESIGN_SRC} ${TESTBENCH}.vhd
	ghdl -a --std=08 ${DESIGN_SRC} ${TESTBENCH}.vhd
	ghdl -e --std=08 ${TESTBENCH}

.PHONY: sim
sim: ${TESTBENCH}.ghw

 ${TESTBENCH}.ghw: ${TESTBENCH}
	ghdl -r --std=08 ${TESTBENCH} --ieee-asserts=disable-at-0 --vcd=${TESTBENCH}.vcd --wave=$@

.PHONY: syn
syn: $(DESIGN).json

$(DESIGN).o: $(DESIGN_SRC)
	ghdl -a --std=08 $(DESIGN_SRC)

$(DESIGN).json: $(DESIGN).o
	yosys -m ghdl -p 'ghdl --std=08 --no-formal ${DESIGN}; synth_ice40 -json $@'

.PHONY: clean
clean:
	rm -f ${TESTBENCH} ${TESTBENCH}.ghw ${TESTBENCH}.vcd work* *.o *.json

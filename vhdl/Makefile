.PHONY: sim
sim: risc_v.vhd tb_risc_v.vhd
	ghdl -a --std=08 risc_v.vhd tb_risc_v.vhd
	ghdl -e --std=08 tb_risc_v
	ghdl -r --std=08 tb_risc_v --vcd=tb_risc_v.vcd --wave=tb_risc_v.ghw

.PHONY: clean
clean:
	rm tb_risc_v tb_risc_v.ghw tb_risc_v.vcd work* *.o

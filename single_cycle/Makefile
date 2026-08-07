VERILATOR ?= verilator
OBJ_DIR   := build/obj_dir
EXE       := $(OBJ_DIR)/Vtb_top
PROGRAM   ?= programs/tutorial_demo.S
PROGRAM_HEX := programs/program.hex

RTL_SRC := \
	rtl/EX.v \
	rtl/ID.v \
	rtl/IF.v \
	rtl/MEM.v \
	rtl/PC_reg.v \
	rtl/WB.v \
	rtl/csr_read.v \
	rtl/imem.v \
	rtl/immgen.v \
	rtl/reg_file.v \
	rtl/top.v

TB := tb/tb_top.v
DPI_CPP := $(CURDIR)/rtl/dpi_uart.cc

.PHONY: all sim wave assemble clean

all: sim

program.hex: $(PROGRAM_HEX)
	cp $(PROGRAM_HEX) $@

data.hex: programs/data.hex
	cp programs/data.hex $@

$(EXE): $(RTL_SRC) $(TB) $(DPI_CPP) program.hex data.hex
	@mkdir -p build
	$(VERILATOR) --sv --timing -Wno-TIMESCALEMOD --cc --binary --exe --trace \
		-Mdir $(OBJ_DIR) --build --top-module tb_top \
		$(TB) $(RTL_SRC) $(DPI_CPP)

sim: $(EXE)
	./$(EXE)

wave: sim
	gtkwave build/cpu.vcd

# The upstream imem.v reads one byte per HEX line. This target deliberately
# only prepares the image; it does not modify the upstream core.
assemble:
	@mkdir -p build
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o build/program.o $(PROGRAM)
	riscv64-unknown-elf-objcopy -O binary --only-section=.text build/program.o build/program.bin
	python3 tools/bin_to_byte_hex.py build/program.bin $(PROGRAM_HEX)

clean:
	rm -rf build
	rm -f program.hex data.hex

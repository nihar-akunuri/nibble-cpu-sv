#===============================================================================
# Makefile for Nibble CPU Testbench
# Supports both basic ($urandom) and randomization (+define+RAND) versions
# Simulator: Mentor Questa/ModelSim (adjust VLOG/VSIM for other tools)
#===============================================================================
SEED = 500
TESTCASE ?= random
TEST_FILE = test_$(TESTCASE)
# Simulator commands
VLOG     = vlog -64 -sv +acc
VSIM     = vsim -64 -sv_seed $(SEED) -assertdebug
WORK     = work
OUTPUTDIR = coverage_report

# Source files in compilation order
SRC_BASE  = nibble_cpu_tb_pkg.sv prog_if.sv mem_if.sv 
SRC_RTL = 	cmd_controller.sv \
	cpu_top.sv \
	done_generator.sv \
	memory_model.sv \
	output_serializer.sv \
	serial_interface.sv 
SRC_PROG  = $(TEST_FILE).sv 
SRC_MEM   = memory_model.sv
SRC_TOP   = tb_top.sv

#SRC_ALL   = $(SRC_BASE) $(SRC_RTL)  $(SRC_PROG) $(SRC_MEM) $(SRC_TOP)
SRC_ALL   = $(SRC_BASE) $(SRC_RTL) $(SRC_PROG) $(SRC_MEM) $(SRC_TOP)

# Compilation flags
BASIC_FLAGS = +acc
RAND_FLAGS = +acc +define+RAND

#------------------------------------------------------------------------------
# Targets
#------------------------------------------------------------------------------
.PHONY: all comp_basic comp_rand run run_rand clean help

all: comp_basic


# Basic version (no randomization)
comp_basic: 
	$(VLOG) $(BASIC_FLAGS) $(SRC_ALL)

# Randomization version
comp_rand: 
	$(VLOG) $(RAND_FLAGS) $(SRC_ALL)

# Run basic version (command line)
run: comp_basic
	$(VSIM) -c work.tb_top -do "run -all; quit"

# Run randomization version (command line)
run_rand: comp_rand
	$(VSIM) -c work.tb_top -do "run -all; quit"

# Run basic version with GUI
gui: comp_basic
	$(VSIM) work.testbench &

# Run randomization version with GUI
gui_rand: comp_rand
	$(VSIM) work.tb_top 
covreport:
	mkdir -p ${OUTPUTDIR}
	vcover -64 report -all -details -annotate -output $(OUTPUTDIR)/cover_${SEED}.rpt coverage_${SEED}.ucdb
	vcover report -details -annotate -instance=/testbench/dut -output $(OUTPUTDIR)/dut_cov_${SEED}.rpt -zeros coverage_${SEED}.ucdb
	vcover report -details -annotate -du=serial_interface -output $(OUTPUTDIR)/serial_interface_uncov_${SEED}.rpt -zeros coverage_${SEED}.ucdb
	vcover report -details -annotate -du=cmd_controller -output $(OUTPUTDIR)/cmd_controller_uncov_${SEED}.rpt -zeros coverage_${SEED}.ucdb
	vcover report -details -annotate -du=output_serializer -output $(OUTPUTDIR)/output_serializer_uncov_${SEED}.rpt -zeros coverage_${SEED}.ucdb
	vcover report -details -annotate -du=done_generator -output $(OUTPUTDIR)/done_generator_uncov_${SEED}.rpt -zeros coverage_${SEED}.ucdb
	vcover report -details -annotate -du=cpu_top -output $(OUTPUTDIR)/cpu_top_uncov_${SEED}.rpt -zeros coverage_${SEED}.ucdb

	vcover report -annotate -hierarchical -output $(OUTPUTDIR)/cover_summary_${SEED}.rpt -zeros coverage_${SEED}.ucdb
	vcover report -annotate -cvg -details -output $(OUTPUTDIR)/cover_func_${SEED}.rpt -zeros coverage_${SEED}.ucdb


# Clean generated files
clean:
	rm -rf $(WORK) transcript vsim.wlf

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
help:
	@echo "Available targets:"
	@echo "  comp_basic   - compile basic version (no +define+RAND)"
	@echo "  comp_rand    - compile randomization version"
	@echo "  run          - run basic version (command line)"
	@echo "  run_rand     - run randomization version (command line)"
	@echo "  gui          - run basic version with GUI"
	@echo "  gui_rand     - run randomization version with GUI"
	@echo "  clean        - remove work library and log files"
	@echo "  all          - comp_basic (default)"
	@echo ""
	@echo "Note: Ensure all source files are in the current directory."

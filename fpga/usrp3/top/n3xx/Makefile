#
# Copyright 2016-2018 Ettus Research, a National Instruments Company
# Copyright 2019 Ettus Research, a National Instruments Brand
#

# NOTE: All comments prefixed with a "##" will be displayed as a part of the "make help" target
##-------------------
##USRP N3XX FPGA Help
##-------------------
##Usage:
## make <Targets> <Options>
##
##Output:
## $(BUILD_OUTPUT_DIR)/usrp_<product>_fpga_<image_type>.bit:    Configuration bitstream with header
## $(BUILD_OUTPUT_DIR)/usrp_<product>_fpga_<image_type>.dts:    Device tree source file
## $(BUILD_OUTPUT_DIR)/usrp_<product>_fpga_<image_type>.rpt:    Build report (includes utilization and timing summary)

# Debug Options
# Uncomment this line or add to make arg to omit radio_clk (sourced from db) and use bus_clk as radio_clk
# OPTIONS += NO_DB=1
# Uncomment this line to add two example Aurora loopback lanes on the general NPIO bus.
# OPTIONS += NPIO_LANES=2
# Uncomment this line to add four example Aurora loopback lanes on the QSFP NPIO bus.
# OPTIONS += QSFP_LANES=4

# Base output directory for all builds.
BUILD_BASE_DIR ?= .
# Base directory for the build outputs.
BUILD_OUTPUT_DIR ?= $(BUILD_BASE_DIR)/build

# Initialize a build seed. This can be changed to randomly affect build results.
BUILD_SEED ?= 0

# Additional definitions specific to the various targets:
WX_DEFS=SFP0_WR=1     SFP1_10GBE=1                BUILD_WR=1     BUILD_10G=1                 $(OPTIONS) BUILD_SEED=$(BUILD_SEED)
HG_DEFS=SFP0_1GBE=1   SFP1_10GBE=1                BUILD_1G=1     BUILD_10G=1                 $(OPTIONS) BUILD_SEED=$(BUILD_SEED)
XG_DEFS=SFP0_10GBE=1  SFP1_10GBE=1                BUILD_10G=1                                $(OPTIONS) BUILD_SEED=$(BUILD_SEED)
HA_DEFS=SFP0_1GBE=1   SFP1_AURORA=1               BUILD_1G=1     BUILD_AURORA=1              $(OPTIONS) BUILD_SEED=$(BUILD_SEED)
XA_DEFS=SFP0_10GBE=1  SFP1_AURORA=1               BUILD_10G=1    BUILD_AURORA=1              $(OPTIONS) BUILD_SEED=$(BUILD_SEED)
AA_DEFS=SFP0_AURORA=1 SFP1_AURORA=1               BUILD_AURORA=1                             $(OPTIONS) BUILD_SEED=$(BUILD_SEED)
XQ_DEFS=SFP0_WR=1                   QSFP_10GBE=1  BUILD_WR=1     BUILD_10G=1    QSFP_LANES=2 $(OPTIONS) BUILD_SEED=$(BUILD_SEED)
AQ_DEFS=SFP0_10GBE=1  SFP1_10GBE=1  QSFP_AURORA=1 BUILD_10G=1    BUILD_AURORA=1 QSFP_LANES=4 $(OPTIONS) BUILD_SEED=$(BUILD_SEED)

# Defaults specific to the various targets:
N300_DEFAULTS:=DEFAULT_RFNOC_IMAGE_CORE_FILE=$(abspath n300_rfnoc_image_core.v) DEFAULT_EDGE_FILE=$(abspath n300_static_router.hex)
N310_DEFAULTS:=DEFAULT_RFNOC_IMAGE_CORE_FILE=$(abspath n310_rfnoc_image_core.v) DEFAULT_EDGE_FILE=$(abspath n310_static_router.hex)
N320_DEFAULTS:=DEFAULT_RFNOC_IMAGE_CORE_FILE=$(abspath n320_rfnoc_image_core.v) DEFAULT_EDGE_FILE=$(abspath n320_static_router.hex)
N300AA_DEFAULTS:=DEFAULT_RFNOC_IMAGE_CORE_FILE=$(abspath n300_bist_image_core.v) DEFAULT_EDGE_FILE=$(abspath n300_bist_static_router.hex)
N310AA_DEFAULTS:=DEFAULT_RFNOC_IMAGE_CORE_FILE=$(abspath n310_bist_image_core.v) DEFAULT_EDGE_FILE=$(abspath n310_bist_static_router.hex)
N320AA_DEFAULTS:=DEFAULT_RFNOC_IMAGE_CORE_FILE=$(abspath n320_bist_image_core.v) DEFAULT_EDGE_FILE=$(abspath n320_bist_static_router.hex)

# Set build option (check RTL, run synthesis, or do a full build)
ifndef TARGET
	ifeq ($(CHECK), 1)
		TARGET = rtl
	else ifeq ($(SYNTH), 1)
		TARGET = synth
	else ifeq ($(IP_ONLY), 1)
		TARGET = viv_ip
	else
		TARGET = bin
	endif
endif
TOP ?= n3xx

# vivado_build($1=Device, $2=Definitions, $3=Defaults)
# Device: N300, N310, or N320
# Definitions: See above (*_DEFS)
# Defaults: See above (*_DEFAULTS)
vivado_build = make -f Makefile.n3xx.inc $(TARGET) NAME=$@ ARCH=$(XIL_ARCH_$1) PART_ID=$(XIL_PART_ID_$1) $2 TOP_MODULE=$(TOP) EXTRA_DEFS="$2" $3
vivado_ip    = make -f Makefile.n3xx.inc viv_ip    NAME=$@ ARCH=$(XIL_ARCH_$1) PART_ID=$(XIL_PART_ID_$1) $2 TOP_MODULE=$(TOP) EXTRA_DEFS="$2" $3

# post_build($1=Device, $2=Option)
ifeq ($(TARGET),bin)
	post_build = @\
		mkdir -p $(BUILD_OUTPUT_DIR); \
		echo "Exporting bitstream file..."; \
		cp $(BUILD_BASE_DIR)/build-$(1)_$(2)/n3xx.bit $(BUILD_OUTPUT_DIR)/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).bit; \
		echo "Exporting build report..."; \
		cp $(BUILD_BASE_DIR)/build-$(1)_$(2)/build.rpt $(BUILD_OUTPUT_DIR)/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).rpt; \
		echo "Build DONE ... $(1)_$(2)";
else
	post_build = @echo "Skipping bitfile export."
endif

##
##Supported Targets
##-----------------

all:      N300_HG N300_XG N310_HG N310_XG N320_HG N320_XG ##(Default target)

##N300_IP:  Build IP for N300 only.
N300_IP:
	+$(call vivado_ip,N300,$(HG_DEFS) N300=1,$(N300_DEFAULTS))

##N310_IP:  Build IP for N310/N320.
##N320_IP:  Build IP for N310/N320.
N310_IP N320_IP: N3X0_IP
N3X0_IP:
	+$(call vivado_ip,N310,$(HG_DEFS) N310=1,$(N310_DEFAULTS))

##N310_WX:  1GigE White Rabbit on SFP+ Port0, 10Gig on SFP+ Port1.
N310_WX: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n310_fpga_WX.dts
	$(call vivado_build,N310,$(WX_DEFS) N310=1,$(N310_DEFAULTS))
	$(call post_build,N310,WX)

##N310_HG:  1GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N310_HG: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n310_fpga_HG.dts
	$(call vivado_build,N310,$(HG_DEFS) N310=1,$(N310_DEFAULTS))
	$(call post_build,N310,HG)

##N310_XG:  10GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N310_XG: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n310_fpga_XG.dts
	$(call vivado_build,N310,$(XG_DEFS) N310=1,$(N310_DEFAULTS))
	$(call post_build,N310,XG)

##N310_HA:  1Gig on SFP+ Port0, Aurora on SFP+ Port1.
N310_HA: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n310_fpga_HA.dts
	$(call vivado_build,N310,$(HA_DEFS) N310=1,$(N310_DEFAULTS))
	$(call post_build,N310,HA)

##N310_XA:  10Gig on SFP+ Port0, Aurora on SFP+ Port1.
N310_XA: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n310_fpga_XA.dts
	$(call vivado_build,N310,$(XA_DEFS) N310=1,$(N310_DEFAULTS))
	$(call post_build,N310,XA)

##N310_AA:  Aurora on SFP+ Port0, Aurora on SFP+ Port1.
N310_AA: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n310_fpga_AA.dts
	$(call vivado_build,N310,$(AA_DEFS) N310=1,$(N310AA_DEFAULTS))
	$(call post_build,N310,AA)

##N300_WX:  1GigE White Rabbit on SFP+ Port0, 10Gig on SFP+ Port1.
N300_WX: N300_IP $(BUILD_OUTPUT_DIR)/usrp_n300_fpga_WX.dts
	$(call vivado_build,N300,$(WX_DEFS) N300=1,$(N300_DEFAULTS))
	$(call post_build,N300,WX)

##N300_HG:  1GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N300_HG: N300_IP $(BUILD_OUTPUT_DIR)/usrp_n300_fpga_HG.dts
	$(call vivado_build,N300,$(HG_DEFS) N300=1,$(N300_DEFAULTS))
	$(call post_build,N300,HG)

##N300_XG:  10GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N300_XG: N300_IP $(BUILD_OUTPUT_DIR)/usrp_n300_fpga_XG.dts
	$(call vivado_build,N300,$(XG_DEFS) N300=1,$(N300_DEFAULTS))
	$(call post_build,N300,XG)

##N300_HA:  1Gig on SFP+ Port0, Aurora on SFP+ Port1.
N300_HA: N300_IP $(BUILD_OUTPUT_DIR)/usrp_n300_fpga_HA.dts
	$(call vivado_build,N300,$(HA_DEFS) N300=1,$(N300_DEFAULTS))
	$(call post_build,N300,HA)

##N300_XA:  10Gig on SFP+ Port0, Aurora on SFP+ Port1.
N300_XA: N300_IP $(BUILD_OUTPUT_DIR)/usrp_n300_fpga_XA.dts
	$(call vivado_build,N300,$(XA_DEFS) N300=1,$(N300_DEFAULTS))
	$(call post_build,N300,XA)

##N300_AA:  Aurora on SFP+ Port0, Aurora on SFP+ Port1.
N300_AA: N300_IP $(BUILD_OUTPUT_DIR)/usrp_n300_fpga_AA.dts
	$(call vivado_build,N300,$(AA_DEFS) N300=1,$(N300AA_DEFAULTS))
	$(call post_build,N300,AA)

##N320_WX:  1GigE White Rabbit on SFP+ Port0, 10Gig on SFP+ Port1.
N320_WX: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n320_fpga_WX.dts
	$(call vivado_build,N320,$(WX_DEFS) N320=1,$(N320_DEFAULTS))
	$(call post_build,N320,WX)

##N320_HG:  1GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N320_HG: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n320_fpga_HG.dts
	$(call vivado_build,N320,$(HG_DEFS) N320=1,$(N320_DEFAULTS))
	$(call post_build,N320,HG)

##N320_XG:  10GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N320_XG: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n320_fpga_XG.dts
	$(call vivado_build,N320,$(XG_DEFS) N320=1,$(N320_DEFAULTS))
	$(call post_build,N320,XG)

##N320_XQ:  WR on SFP+ Port0, 10Gig on QSFP+ Port0,1.
N320_XQ: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n320_fpga_XQ.dts
	$(call vivado_build,N320,$(XQ_DEFS) N320=1,$(N320_DEFAULTS))
	$(call post_build,N320,XQ)

##N320_AQ:  10Gig on SFP+ Port0,1 Aurora on QSFP+ Port0,1,2,3.
N320_AQ: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n320_fpga_AQ.dts
	$(call vivado_build,N320,$(AQ_DEFS) N320=1,$(N320_DEFAULTS))
	$(call post_build,N320,AQ)

##N320_AA:  Aurora on SFP+ Port0, Aurora on SFP+ Port1.
N320_AA: N3X0_IP $(BUILD_OUTPUT_DIR)/usrp_n320_fpga_AA.dts
	$(call vivado_build,N320,$(AA_DEFS) N320=1,$(N320AA_DEFAULTS))
	$(call post_build,N320,AA)

$(BUILD_OUTPUT_DIR)/%.dts: dts/%.dts dts/*.dtsi
	-mkdir -p $(BUILD_OUTPUT_DIR)
	${CC} -o $@ -E -I dts -nostdinc -undef -x assembler-with-cpp -D__DTS__ $<

clean:    ##Clean up all target build outputs.
	@echo "Cleaning targets..."
	@rm -rf $(BUILD_BASE_DIR)/build-N3*_*
	@rm -rf $(BUILD_OUTPUT_DIR)

cleanall: ##Clean up all target and ip build outputs.
	@echo "Cleaning targets and IP..."
	@rm -rf build-ip
	@rm -rf $(BUILD_BASE_DIR)/build-N3*_*
	@rm -rf $(BUILD_OUTPUT_DIR)

help:     ##Show this help message.
	@grep -h "##" Makefile | grep -v "\"##\"" | sed -e 's/\\$$//' | sed -e 's/##//'

##
##Supported Options
##-----------------
##GUI=1          Launch the build in the Vivado GUI.
##PROJECT=1      Save Vivado project file, otherwise it's created in memory.
##CHECK=1        Launch the syntax checker instead of building a bitfile.
##IP_ONLY=1      Launch the build but stop after IP generation.
##SYNTH=1        Launch the build but stop after synthesis.
##BUILD_SEED=<N> Build seed to used to affect build results. (Default is 0)
##TOP=<module>   Specify a top module for syntax checking. (Default is the bitfile top)

.PHONY: all clean cleanall help

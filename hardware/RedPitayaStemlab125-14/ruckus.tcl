# Set the board part
# # TODO fix board name
set_property board_part redpitaya.com:redpitaya:part0:1.1 [current_project]

# Load shared source code
loadRuckusTcl "$::DIR_PATH/../../shared"
loadConstraints -dir "$::DIR_PATH/xdc"

# Load the common source code (common to board)
loadSource -lib axi_soc_7000_core -dir "$::DIR_PATH/rtl"

# Load the block design
# If tcl scripts are used, the only differences are literally the check that
# complaints that the vivado version is not the one that generated the
# script...
if  { $::env(VIVADO_VERSION) >= 2024.1 } {
   set bdVer "2024.1"
} elseif  { $::env(VIVADO_VERSION) >= 2023.1 } {
   set bdVer "2023.1"
}

# loadBlockDesign -path "$::DIR_PATH/bd/${bdVer}/AxiSoc7000CpuCore.bd"
loadBlockDesign -path "$::DIR_PATH/bd/${bdVer}/AxiSoc7000CpuCore.tcl"

# TODO Load IP cores if there are any
# loadIpCore -dir "$::DIR_PATH/ip"

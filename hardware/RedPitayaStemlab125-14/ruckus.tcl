# Set the board part
# # TODO fix board name
set_property board_part redpitaya.com:redpitaya:part0:1.1 [current_project]

# Load shared source code
loadRuckusTcl "$::DIR_PATH/../../shared"
loadConstraints -dir "$::DIR_PATH/xdc"

# Load the common source code (common to board)
loadSource -lib axi_soc_ultra_plus_core -dir "$::DIR_PATH/rtl"

# Load the block design
if  { $::env(VIVADO_VERSION) >= 2024.1 } {
   set bdVer "2024.1"
}
# loadBlockDesign -path "$::DIR_PATH/bd/${bdVer}/AxiSoc7000CpuCore.bd"
loadBlockDesign -path "$::DIR_PATH/bd/${bdVer}/AxiSoc7000CpuCore.tcl"

# TODO Load IP cores if there are any
# loadIpCore -dir "$::DIR_PATH/ip"

# Set the board part
# # TODO fix board name
set_property board_part redpitaya.com:redpitaya:part0:1.1 [current_project]

# Load shared source code
loadRuckusTcl "$::DIR_PATH/../../shared"
loadConstraints -dir "$::DIR_PATH/xdc"

# Load the common source code (common to board)
loadSource -lib axi_soc_7000_core -dir "$::DIR_PATH/rtl"

# Load the block design
# In reality, in many cases it appears to be possible to source the tcl script
# generated with a different Vivado version just fine. There is a version check
# in the script, but one can spoof the version. Ofc. there is no gurantee that
# everything works in if that is done.
# Sourcing a script generated with an older verions in a newer one should
# genrally work.
# To make the version check pass, in the generated block design script we may
# replace
# if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
# with
# if {[package vcompare $current_vivado_version $scripts_vivado_version] < 0} {
# which however requires manual modification whenever the script is
# re-generated.
set bdVer ""
if { $::env(VIVADO_VERSION) >= 2023.1 } {
   set bdVer "2023.1"
}
# Could add else branches and maintain multiple block design scriptsif some
# version ever introduces breaking changes.
# } elseif  { $::env(VIVADO_VERSION) >= XXXX.Y } {
#    set bdVer "XXXX.Y"

# loadBlockDesign -path "$::DIR_PATH/bd/${bdVer}/AxiSoc7000CpuCore.bd"
loadBlockDesign -path "$::DIR_PATH/bd/${bdVer}/AxiSoc7000CpuCore.tcl"

# TODO Load IP cores if there are any
# loadIpCore -dir "$::DIR_PATH/ip"

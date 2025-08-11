library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;

library axi_soc_7000_core;
use axi_soc_7000_core.AxiSoc7000Pkg.all;

package HardwareTypePkg is

   constant HW_TYPE_C : slv(31 downto 0) := HW_TYPE_RPTY_STEMLAB_125_14;

end package HardwareTypePkg;

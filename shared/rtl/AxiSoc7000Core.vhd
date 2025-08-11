library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiPkg.all;

library axi_soc_7000_core;
use axi_soc_7000_core.AxiSoc7000Pkg.all;

entity AxiSoc7000Core is
    generic(
        TPD_G          : time    := 1 ns;
        ROGUE_SIM_EN_G : boolean := false
        );
    port (
        glob_clk  : in    sl;
        ddr_ports : inout DDR3_ports
        );
end entity AxiSoc7000Core;

architecture mapping of AxiSoc7000Core is

    signal regReadMaster  : AxiLiteReadMasterType;
    signal regReadSlave   : AxiLiteReadSlaveType;
    signal regWriteMaster : AxiLiteWriteMasterType;
    signal regWriteSlave  : AxiLiteWriteSlaveType;

begin

    ----------
    -- AXI CPU
    ----------
    REAL_CPU : if (not ROGUE_SIM_EN_G) generate

        U_CPU : entity axi_soc_7000_core.AxiSoc7000Cpu
            generic map (
                TPD_G => TPD_G)
            port map (
                glob_clk       => glob_clk,
                ddr_ports      => ddr_ports,
                -- Master AXI-Lite Interface
                regReadMaster  => regReadMaster,
                regReadSlave   => regReadSlave,
                regWriteMaster => regWriteMaster,
                regWriteSlave  => regWriteSlave
                );

    end generate;

end architecture mapping;

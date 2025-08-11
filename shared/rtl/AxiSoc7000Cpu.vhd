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

entity AxiSoc7000Cpu is
    generic (
        TPD_G : time := 1 ns);
    port (
        glob_clk       : in    sl;
        ddr_ports      : inout DDR3_ports;
        -- Master AXI-Lite Interface
        regReadMaster  : out   AxiLiteReadMasterType;
        regReadSlave   : in    AxiLiteReadSlaveType;
        regWriteMaster : out   AxiLiteWriteMasterType;
        regWriteSlave  : in    AxiLiteWriteSlaveType
        );
end entity AxiSoc7000Cpu;

architecture mapping of AxiSoc7000Cpu is

    component AxiSoc7000CpuCore is
        -- Ports copy/pasted from instantiation template
        port (
            DDR_cas_n         : inout std_logic;
            DDR_cke           : inout std_logic;
            DDR_ck_n          : inout std_logic;
            DDR_ck_p          : inout std_logic;
            DDR_cs_n          : inout std_logic;
            DDR_reset_n       : inout std_logic;
            DDR_odt           : inout std_logic;
            DDR_ras_n         : inout std_logic;
            DDR_we_n          : inout std_logic;
            DDR_ba            : inout std_logic_vector (2 downto 0);
            DDR_addr          : inout std_logic_vector (14 downto 0);
            DDR_dm            : inout std_logic_vector (3 downto 0);
            DDR_dq            : inout std_logic_vector (31 downto 0);
            DDR_dqs_n         : inout std_logic_vector (3 downto 0);
            DDR_dqs_p         : inout std_logic_vector (3 downto 0);
            FIXED_IO_mio      : inout std_logic_vector (53 downto 0);
            FIXED_IO_ddr_vrn  : inout std_logic;
            FIXED_IO_ddr_vrp  : inout std_logic;
            FIXED_IO_ps_srstb : inout std_logic;
            FIXED_IO_ps_clk   : inout std_logic;
            FIXED_IO_ps_porb  : inout std_logic;
            glob_clk          : in    std_logic;
            axiLite_awaddr    : out   std_logic_vector (31 downto 0);
            axiLite_awprot    : out   std_logic_vector (2 downto 0);
            axiLite_awvalid   : out   std_logic;
            axiLite_awready   : in    std_logic;
            axiLite_wdata     : out   std_logic_vector (31 downto 0);
            axiLite_wstrb     : out   std_logic_vector (3 downto 0);
            axiLite_wvalid    : out   std_logic;
            axiLite_wready    : in    std_logic;
            axiLite_bresp     : in    std_logic_vector (1 downto 0);
            axiLite_bvalid    : in    std_logic;
            axiLite_bready    : out   std_logic;
            axiLite_araddr    : out   std_logic_vector (31 downto 0);
            axiLite_arprot    : out   std_logic_vector (2 downto 0);
            axiLite_arvalid   : out   std_logic;
            axiLite_arready   : in    std_logic;
            axiLite_rdata     : in    std_logic_vector (31 downto 0);
            axiLite_rresp     : in    std_logic_vector (1 downto 0);
            axiLite_rvalid    : in    std_logic;
            axiLite_rready    : out   std_logic
            );
    end component AxiSoc7000CpuCore;

begin


    U_CPU : AxiSoc7000CpuCore
        port map(
            -- Global Clock
            glob_clk          => glob_clk,
            -- DDR3 signals
            DDR_cas_n         => ddr_ports.DDR_cas_n,
            DDR_cke           => ddr_ports.DDR_cke,
            DDR_ck_n          => ddr_ports.DDR_ck_n,
            DDR_ck_p          => ddr_ports.DDR_ck_p,
            DDR_cs_n          => ddr_ports.DDR_cs_n,
            DDR_reset_n       => ddr_ports.DDR_reset_n,
            DDR_odt           => ddr_ports.DDR_odt,
            DDR_ras_n         => ddr_ports.DDR_ras_n,
            DDR_we_n          => ddr_ports.DDR_we_n,
            DDR_ba            => ddr_ports.DDR_ba,
            DDR_addr          => ddr_ports.DDR_addr,
            DDR_dm            => ddr_ports.DDR_dm,
            DDR_dq            => ddr_ports.DDR_dq,
            DDR_dqs_n         => ddr_ports.DDR_dqs_n,
            DDR_dqs_p         => ddr_ports.DDR_dqs_p,
            FIXED_IO_mio      => ddr_ports.FIXED_IO_mio,
            FIXED_IO_ddr_vrn  => ddr_ports.FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp  => ddr_ports.FIXED_IO_ddr_vrp,
            FIXED_IO_ps_srstb => ddr_ports.FIXED_IO_ps_srstb,
            FIXED_IO_ps_clk   => ddr_ports.FIXED_IO_ps_clk,
            FIXED_IO_ps_porb  => ddr_ports.FIXED_IO_ps_porb,
            -- User AXI-Lite Interface
            axiLite_awaddr    => regWriteMaster.awaddr,
            axiLite_awprot    => regWriteMaster.awprot,
            axiLite_awvalid   => regWriteMaster.awvalid,
            axiLite_awready   => regWriteSlave.awready,
            axiLite_wdata     => regWriteMaster.wdata,
            axiLite_wstrb     => regWriteMaster.wstrb,
            axiLite_wvalid    => regWriteMaster.wvalid,
            axiLite_wready    => regWriteSlave.wready,
            axiLite_bresp     => AXI_RESP_OK_C,  -- Always respond OK
            axiLite_bvalid    => regWriteSlave.bvalid,
            axiLite_bready    => regWriteMaster.bready,
            axiLite_araddr    => regReadMaster.araddr,
            axiLite_arprot    => regReadMaster.arprot,
            axiLite_arvalid   => regReadMaster.arvalid,
            axiLite_arready   => regReadSlave.arready,
            axiLite_rdata     => regReadSlave.rdata,
            axiLite_rresp     => AXI_RESP_OK_C,  -- Always respond OK
            axiLite_rvalid    => regReadSlave.rvalid,
            axiLite_rready    => regReadMaster.rready
            );

end architecture mapping;

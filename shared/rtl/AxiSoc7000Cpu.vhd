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
        TPD_G : time := 1 ns
        );
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
        -- Global pl clock
        pl_clk            : in    std_logic;
        -- Master AXI-Lite Interface
        regReadMaster     : out   AxiLiteReadMasterType;
        regReadSlave      : in    AxiLiteReadSlaveType;
        regWriteMaster    : out   AxiLiteWriteMasterType;
        regWriteSlave     : in    AxiLiteWriteSlaveType;
        -- Reset
        reset_l           : in    std_logic
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
            -- Global pl clock
            pl_clk            : in    std_logic;
            -- Master AXI-Lite Interface
            axi_lite_awaddr   : out   std_logic_vector (31 downto 0);
            axi_lite_awprot   : out   std_logic_vector (2 downto 0);
            axi_lite_awvalid  : out   std_logic;
            axi_lite_awready  : in    std_logic;
            axi_lite_wdata    : out   std_logic_vector (31 downto 0);
            axi_lite_wstrb    : out   std_logic_vector (3 downto 0);
            axi_lite_wvalid   : out   std_logic;
            axi_lite_wready   : in    std_logic;
            axi_lite_bresp    : in    std_logic_vector (1 downto 0);
            axi_lite_bvalid   : in    std_logic;
            axi_lite_bready   : out   std_logic;
            axi_lite_araddr   : out   std_logic_vector (31 downto 0);
            axi_lite_arprot   : out   std_logic_vector (2 downto 0);
            axi_lite_arvalid  : out   std_logic;
            axi_lite_arready  : in    std_logic;
            axi_lite_rdata    : in    std_logic_vector (31 downto 0);
            axi_lite_rresp    : in    std_logic_vector (1 downto 0);
            axi_lite_rvalid   : in    std_logic;
            axi_lite_rready   : out   std_logic;
            -- Reset
            reset_l           : in    std_logic
            );
    end component AxiSoc7000CpuCore;

begin


    U_CPU : AxiSoc7000CpuCore
        port map(
            DDR_addr(14 downto 0)     => DDR_addr(14 downto 0),
            DDR_ba(2 downto 0)        => DDR_ba(2 downto 0),
            DDR_cas_n                 => DDR_cas_n,
            DDR_ck_n                  => DDR_ck_n,
            DDR_ck_p                  => DDR_ck_p,
            DDR_cke                   => DDR_cke,
            DDR_cs_n                  => DDR_cs_n,
            DDR_dm(3 downto 0)        => DDR_dm(3 downto 0),
            DDR_dq(31 downto 0)       => DDR_dq(31 downto 0),
            DDR_dqs_n(3 downto 0)     => DDR_dqs_n(3 downto 0),
            DDR_dqs_p(3 downto 0)     => DDR_dqs_p(3 downto 0),
            DDR_odt                   => DDR_odt,
            DDR_ras_n                 => DDR_ras_n,
            DDR_reset_n               => DDR_reset_n,
            DDR_we_n                  => DDR_we_n,
            FIXED_IO_ddr_vrn          => FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp          => FIXED_IO_ddr_vrp,
            FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
            FIXED_IO_ps_clk           => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb          => FIXED_IO_ps_porb,
            FIXED_IO_ps_srstb         => FIXED_IO_ps_srstb,
            -- Global pl clock
            pl_clk                    => pl_clk,
            -- Master AXI-Lite Interface
            axi_lite_araddr           => regReadMaster.araddr,
            axi_lite_arprot           => regReadMaster.arprot,
            axi_lite_arready          => regReadSlave.arready,
            axi_lite_arvalid          => regReadMaster.arvalid,
            axi_lite_awaddr           => regWriteMaster.awaddr,
            axi_lite_awprot           => regWriteMaster.awprot,
            axi_lite_awready          => regWriteSlave.awready,
            axi_lite_awvalid          => regWriteMaster.awvalid,
            axi_lite_bready           => regWriteMaster.bready,
            axi_lite_bresp            => AXI_RESP_OK_C,  -- Always respond OK
            axi_lite_bvalid           => regWriteSlave.bvalid,
            axi_lite_rdata            => regReadSlave.rdata,
            axi_lite_rready           => regReadMaster.rready,
            axi_lite_rresp            => AXI_RESP_OK_C,  -- Always respond OK
            axi_lite_rvalid           => regReadSlave.rvalid,
            axi_lite_wdata            => regWriteMaster.wdata,
            axi_lite_wready           => regWriteSlave.wready,
            axi_lite_wstrb            => regWriteMaster.wstrb,
            axi_lite_wvalid           => regWriteMaster.wvalid,
            -- Reset
            reset_l                   => reset_l
            );

end architecture mapping;

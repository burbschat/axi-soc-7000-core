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
        ROGUE_SIM_EN_G : boolean := false;
        BUILD_INFO_G   : BuildInfoType
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
        -- Application AXI-Lite Interfaces [0x80000000:0xFFFFFFFF] (for now pl clock domain)
        appReadMaster     : out   AxiLiteReadMasterType;
        appReadSlave      : in    AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
        appWriteMaster    : out   AxiLiteWriteMasterType;
        appWriteSlave     : in    AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
        -- Reset
        reset             : in    std_logic
        );
end entity AxiSoc7000Core;

architecture mapping of AxiSoc7000Core is

    signal regReadMaster  : AxiLiteReadMasterType;
    signal regReadSlave   : AxiLiteReadSlaveType;
    signal regWriteMaster : AxiLiteWriteMasterType;
    signal regWriteSlave  : AxiLiteWriteSlaveType;

    -- Reset, not yet connected!
    signal pl_rst: sl;

begin

    ----------
    -- AXI CPU
    ----------
    REAL_CPU : if (not ROGUE_SIM_EN_G) generate

        U_CPU : entity axi_soc_7000_core.AxiSoc7000Cpu
            generic map (
                TPD_G => TPD_G)
            port map (
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
                regReadMaster             => regReadMaster,
                regReadSlave              => regReadSlave,
                regWriteMaster            => regWriteMaster,
                regWriteSlave             => regWriteSlave,
                -- Reset
                reset_l                   => not reset  -- Convert to active low reset
                );

    end generate;

    ---------------
    -- AXI CPU REG
    ---------------
    U_REG : entity axi_soc_7000_core.AxiSoc7000Reg
        generic map (
            BUILD_INFO_G => BUILD_INFO_G
            )
        port map(
            -- Global pl clock
            pl_clk         => pl_clk,
            -- Global pl reset
            pl_rst         => pl_rst,
            -- Internal AXI4 Interfaces (eventually axiClk domain?)
            regReadMaster  => regReadMaster,
            regReadSlave   => regReadSlave,
            regWriteMaster => regWriteMaster,
            regWriteSlave  => regWriteSlave,
            -- (Optional) Application AXI-Lite Interfaces (eventually appClk domain?)
            appReadMaster  => appReadMaster,
            appReadSlave   => appReadSlave,
            appWriteMaster => appWriteMaster,
            appWriteSlave  => appWriteSlave
            );

end architecture mapping;

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
        TPD_G              : time                    := 1 ns;
        ROGUE_SIM_EN_G     : boolean                 := false;
        BUILD_INFO_G       : BuildInfoType;
        DESC_MEMORY_TYPE_G : string                  := "block";
        DMA_BURST_BYTES_G  : positive range 1 to 128 := 128;
        DMA_SIZE_G         : positive range 1 to 1   := 1
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
        -- Application AXI-Lite Interfaces [0x6000_0000:0x7FFF_FFFF] (for now pl clock domain)
        appReadMaster     : out   AxiLiteReadMasterType;
        appReadSlave      : in    AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
        appWriteMaster    : out   AxiLiteWriteMasterType;
        appWriteSlave     : in    AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
        -- DMA Interfaces  (TODO: dmaClk domain?)
        -- dmaClk            : out   sl;
        -- dmaRst            : out   sl;
        dmaBuffGrpPause   : out   slv(7 downto 0);
        dmaObMasters      : out   AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
        dmaObSlaves       : in    AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);
        dmaIbMasters      : in    AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
        dmaIbSlaves       : out   AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);

        -- Reset
        -- TODO: This is used also as a signal to drive other entities resets in this module. Perhaps this will lead to problems...
        pl_rst : out std_logic
        );
end entity AxiSoc7000Core;

architecture mapping of AxiSoc7000Core is

    signal regReadMaster  : AxiLiteReadMasterType;
    signal regReadSlave   : AxiLiteReadSlaveType;
    signal regWriteMaster : AxiLiteWriteMasterType;
    signal regWriteSlave  : AxiLiteWriteSlaveType;

    -- Slave AXI4 Interface (DMA) TODO: Make sure compatible with CPU AXI3!
    signal dmaReadMaster  : AxiReadMasterType;
    signal dmaReadSlave   : AxiReadSlaveType;
    signal dmaWriteMaster : AxiWriteMasterType;
    signal dmaWriteSlave  : AxiWriteSlaveType;

    -- Master AXI-Lite Interface (DMA control)
    -- Index 0: DMA control registers
    -- Index 1: Outbound streams monitoring registers (TODO: Implement if required)
    -- Index 2: Inbound streams monitoring registers (TODO: Implement if required)
    signal dmaCtrlReadMasters  : AxiLiteReadMasterArray(2 downto 0);
    signal dmaCtrlReadSlaves   : AxiLiteReadSlaveArray(2 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
    signal dmaCtrlWriteMasters : AxiLiteWriteMasterArray(2 downto 0);
    signal dmaCtrlWriteSlaves  : AxiLiteWriteSlaveArray(2 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

    -- Use local signal (buffer) as port is passed to output and other entities in this module
    signal pl_rst_sig : sl := '0';

    signal dma_irq : sl;

begin

    -- Assign local reset signal to output
    pl_rst <= pl_rst_sig;

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
                -- DMA interrupt
                dma_irq                   => dma_irq,
                -- Master AXI-Lite Interface
                regReadMaster             => regReadMaster,
                regReadSlave              => regReadSlave,
                regWriteMaster            => regWriteMaster,
                regWriteSlave             => regWriteSlave,

                -- Master AXI-Lite Interface (DMA control)
                dmaCtrlReadMaster  => dmaCtrlReadMasters(0),
                dmaCtrlReadSlave   => dmaCtrlReadSlaves(0),
                dmaCtrlWriteMaster => dmaCtrlWriteMasters(0),
                dmaCtrlWriteSlave  => dmaCtrlWriteSlaves(0),

                -- Slave AXI4 Interface (DMA)
                dmaReadMaster  => dmaReadMaster,
                dmaReadSlave   => dmaReadSlave,
                dmaWriteMaster => dmaWriteMaster,
                dmaWriteSlave  => dmaWriteSlave,

                -- Reset
                -- reset_l => not pl_rst_sig   -- Convert to active low reset
                reset_l => not '0'  -- Convert to active low reset, seems resetting here locks up the system... 
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
            -- User commanded reset generated through AxiVersion (asseratable via register access)
            userResetOut   => pl_rst_sig,
            -- Global pl reset (looped back)
            pl_rst         => pl_rst_sig,
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

    --------------
    -- AXI SOC DMA
    --------------
    U_DMA : entity axi_soc_7000_core.AxiSoc7000Dma
        generic map (
            TPD_G              => TPD_G,
            -- ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
            -- ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
            -- ROGUE_SIM_CH_COUNT_G => ROGUE_SIM_CH_COUNT_G,
            DESC_MEMORY_TYPE_G => DESC_MEMORY_TYPE_G,
            DMA_SIZE_G         => DMA_SIZE_G,
            DMA_BURST_BYTES_G  => DMA_BURST_BYTES_G)
        port map (
            axiClk           => pl_clk,
            axiRst           => pl_rst_sig,
            -- DMA AXI4 Interfaces (
            axiReadMaster    => dmaReadMaster,
            axiReadSlave     => dmaReadSlave,
            axiWriteMaster   => dmaWriteMaster,
            axiWriteSlave    => dmaWriteSlave,
            -- User General Purpose AXI4 Interfaces (TODO: Leave out for now as unused)
            -- usrReadMaster    => usrReadMaster,
            -- usrReadSlave     => usrReadSlave,
            -- usrWriteMaster   => usrWriteMaster,
            -- usrWriteSlave    => usrWriteSlave,
            -- AXI4-Lite Interfaces
            axilReadMasters  => dmaCtrlReadMasters,
            axilReadSlaves   => dmaCtrlReadSlaves,
            axilWriteMasters => dmaCtrlWriteMasters,
            axilWriteSlaves  => dmaCtrlWriteSlaves,
            -- DMA Interfaces
            dmaIrq           => dma_irq,
            dmaBuffGrpPause  => dmaBuffGrpPause,
            dmaObMasters     => dmaObMasters,
            dmaObSlaves      => dmaObSlaves,
            dmaIbMasters     => dmaIbMasters,
            dmaIbSlaves      => dmaIbSlaves
            );

end architecture mapping;

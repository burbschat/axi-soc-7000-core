library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.SsiPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library axi_soc_7000_core;
use axi_soc_7000_core.AxiSoc7000Pkg.all;

entity AxiSoc7000Dma is
    generic (
        TPD_G              : time                    := 1 ns;
        DMA_BURST_BYTES_G  : positive range 1 to 128 := 128;
        DMA_SIZE_G         : positive range 1 to 8   := 1;
        INT_PIPE_STAGES_G  : natural range 0 to 1    := 1;
        PIPE_STAGES_G      : natural range 0 to 1    := 1;
        DESC_SYNTH_MODE_G  : string                  := "xpm";  -- TODO: Probably not available on 7series?
        DESC_MEMORY_TYPE_G : string                  := "block";
        DESC_ARB_G         : boolean                 := false);  -- false = Round robin to help with timing
    port (
        -- Clock and Reset
        axiClk : in sl;
        axiRst : in sl;

        -- SOC AXI4 Interfaces (axiClk domain)
        axiReadMaster  : out AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
        axiReadSlave   : in  AxiReadSlaveType   := AXI_READ_SLAVE_FORCE_C;
        axiWriteMaster : out AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
        axiWriteSlave  : in  AxiWriteSlaveType  := AXI_WRITE_SLAVE_FORCE_C;

        -- User General Purpose AXI4 Interfaces (axiClk domain)
        usrReadMaster  : in  AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
        usrReadSlave   : out AxiReadSlaveType   := AXI_READ_SLAVE_FORCE_C;
        usrWriteMaster : in  AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
        usrWriteSlave  : out AxiWriteSlaveType  := AXI_WRITE_SLAVE_FORCE_C;

        -- AXI4-Lite Interfaces (axiClk domain, one for controls, two for monitoring IB/OB)
        axilReadMasters  : in  AxiLiteReadMasterArray(2 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
        axilReadSlaves   : out AxiLiteReadSlaveArray(2 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
        axilWriteMasters : in  AxiLiteWriteMasterArray(2 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
        axilWriteSlaves  : out AxiLiteWriteSlaveArray(2 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

        -- DMA Interfaces (axiClk domain)
        dmaIrq          : out sl                                          := '0';
        dmaBuffGrpPause : out slv(7 downto 0)                             := (others => '0');
        dmaObMasters    : out AxiStreamMasterArray(DMA_SIZE_G-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
        dmaObSlaves     : in  AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
        dmaIbMasters    : in  AxiStreamMasterArray(DMA_SIZE_G-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
        dmaIbSlaves     : out AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C));
end AxiSoc7000Dma;

architecture mapping of AxiSoc7000Dma is

    constant INT_DMA_AXIS_CONFIG_C : AxiStreamConfigType := (
        TSTRB_EN_C    => false,
        TDATA_BYTES_C => DMA_AXIS_CONFIG_C.TDATA_BYTES_C,
        TDEST_BITS_C  => 8,
        TID_BITS_C    => 3,
        TKEEP_MODE_C  => TKEEP_COUNT_C,  -- AXI DMA V2 uses TKEEP_COUNT_C to help meet timing
        TUSER_BITS_C  => 4,
        TUSER_MODE_C  => TUSER_FIRST_LAST_C);

    signal dmaReadMasters  : AxiReadMasterArray(DMA_SIZE_G downto 0);
    signal dmaReadSlaves   : AxiReadSlaveArray(DMA_SIZE_G downto 0);
    signal dmaWriteMasters : AxiWriteMasterArray(DMA_SIZE_G downto 0);
    signal dmaWriteSlaves  : AxiWriteSlaveArray(DMA_SIZE_G downto 0);

    signal axiReadMasters  : AxiReadMasterArray(DMA_SIZE_G downto 0)  := (others => AXI_READ_MASTER_INIT_C);
    signal axiReadSlaves   : AxiReadSlaveArray(DMA_SIZE_G downto 0)   := (others => AXI_READ_SLAVE_FORCE_C);
    signal axiWriteMasters : AxiWriteMasterArray(DMA_SIZE_G downto 0) := (others => AXI_WRITE_MASTER_INIT_C);
    signal axiWriteSlaves  : AxiWriteSlaveArray(DMA_SIZE_G downto 0)  := (others => AXI_WRITE_SLAVE_FORCE_C);

    -- Inbound (to CPU) streams after FIFOs
    signal sAxisMasters : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
    signal sAxisSlaves  : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);
    -- Outbound (from CPU) streams before FIFOs
    signal mAxisMasters : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
    signal mAxisSlaves  : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);
    signal mAxisCtrl    : AxiStreamCtrlArray(DMA_SIZE_G-1 downto 0);

    signal axisReset : slv(DMA_SIZE_G-1 downto 0);

    attribute dont_touch              : string;
    attribute dont_touch of axisReset : signal is "true";

begin

    ------------
    -- AXI Muxes
    ------------

    U_WritePathMux : entity surf.AxiWritePathMux
        generic map (
            TPD_G        => TPD_G,
            NUM_SLAVES_G => DMA_SIZE_G+1)
        port map (
            axiClk           => axiClk,
            axiRst           => axiRst,
            -- Slaves
            sAxiWriteMasters => axiWriteMasters,
            sAxiWriteSlaves  => axiWriteSlaves,
            -- Master
            mAxiWriteMaster  => axiWriteMaster,
            mAxiWriteSlave   => axiWriteSlave);

    U_ReadPathMux : entity surf.AxiReadPathMux
        generic map (
            TPD_G        => TPD_G,
            NUM_SLAVES_G => DMA_SIZE_G+1)
        port map (
            axiClk          => axiClk,
            axiRst          => axiRst,
            -- Slaves
            sAxiReadMasters => axiReadMasters,
            sAxiReadSlaves  => axiReadSlaves,
            -- Master
            mAxiReadMaster  => axiReadMaster,
            mAxiReadSlave   => axiReadSlave);

    -- Hard code channel 1 connected through... for testing without the muxes
    -- axiWriteMaster <= axiWriteMasters(1);
    -- axiWriteSlaves(1) <= axiWriteSlave;
    -- axiReadMaster <= axiReadMasters(1);
    -- axiReadSlaves(1) <= axiReadSlave;

    -----------
    -- DMA Core
    -----------

    U_V2Gen : entity surf.AxiStreamDmaV2
        generic map (
            TPD_G              => TPD_G,
            DESC_AWIDTH_G      => 12,           -- 4096 entries
            DESC_ARB_G         => DESC_ARB_G,
            DESC_SYNTH_MODE_G  => DESC_SYNTH_MODE_G,
            DESC_MEMORY_TYPE_G => DESC_MEMORY_TYPE_G,
            AXIL_BASE_ADDR_G   => x"00000000",  -- Not used??
            AXI_READY_EN_G     => true,
            AXIS_READY_EN_G    => true,
            AXIS_CONFIG_G      => INT_DMA_AXIS_CONFIG_C,
            AXI_DMA_CONFIG_G   => AXI_SOC_CONFIG_C,
            CHAN_COUNT_G       => DMA_SIZE_G,
            RD_PIPE_STAGES_G   => 1,
            BURST_BYTES_G      => DMA_BURST_BYTES_G,
            RD_PEND_THRESH_G   => 1)
        port map (
            -- Clock/Reset
            axiClk          => axiClk,
            axiRst          => axiRst,
            -- Register Access & Interrupt
            axilReadMaster  => axilReadMasters(0),
            axilReadSlave   => axilReadSlaves(0),
            axilWriteMaster => axilWriteMasters(0),
            axilWriteSlave  => axilWriteSlaves(0),
            interrupt       => dmaIrq,
            buffGrpPause    => dmaBuffGrpPause,
            -- AXI Stream Interface
            sAxisMasters    => sAxisMasters,
            sAxisSlaves     => sAxisSlaves,
            mAxisMasters    => mAxisMasters,
            mAxisSlaves     => mAxisSlaves,
            mAxisCtrl       => mAxisCtrl,
            -- TODO: Consider the following (see axi-soc-ultra-plus-core commit 45010123)
            -- mAxisCtrl       => (others => AXI_STREAM_CTRL_UNUSED_C),
            -- AXI Interfaces, 0 = Desc, 1-CHAN_COUNT_G = DMA
            axiReadMasters  => dmaReadMasters,
            axiReadSlaves   => dmaReadSlaves,
            axiWriteCtrl    => (others => AXI_CTRL_UNUSED_C),
            axiWriteMasters => dmaWriteMasters,
            axiWriteSlaves  => dmaWriteSlaves);


    ---------------
    -- AXI Mappings
    ---------------

    ------------------------------------------------------------------------
    -- axi[DMA_SIZE_G:0].[read/write] = Mapped to DMA_SIZE_G DMA lanes
    -- axi[DMA_SIZE_G].[read/write] = User General Purpose
    ------------------------------------------------------------------------

    -- Map DMA AXI interfaces
    axiReadMasters(DMA_SIZE_G-1 downto 0)  <= dmaReadMasters(DMA_SIZE_G downto 1);
    dmaReadSlaves(DMA_SIZE_G downto 1)     <= axiReadSlaves(DMA_SIZE_G-1 downto 0);
    axiWriteMasters(DMA_SIZE_G-1 downto 0) <= dmaWriteMasters(DMA_SIZE_G downto 1);
    dmaWriteSlaves(DMA_SIZE_G downto 1)    <= axiWriteSlaves(DMA_SIZE_G-1 downto 0);

    -- Map User General Purpose AXI interfaces
    axiReadMasters(DMA_SIZE_G)  <= usrReadMaster;
    usrReadSlave                <= axiReadSlaves(DMA_SIZE_G);
    axiWriteMasters(DMA_SIZE_G) <= usrWriteMaster;
    usrWriteSlave               <= axiWriteSlaves(DMA_SIZE_G);

    ---------------
    -- Stream Fifos
    ---------------

    GEN_AXIS_FIFO : for i in DMA_SIZE_G-1 downto 0 generate

        -- Help with timing
        U_AxisRst : entity surf.RstPipeline
            generic map (
                TPD_G     => TPD_G,
                INV_RST_G => false)
            port map (
                clk    => axiClk,
                rstIn  => axiRst,
                rstOut => axisReset(i));

        --------------------------
        -- Inbound AXI Stream FIFO
        --------------------------

        U_IbFifo : entity surf.AxiStreamFifoV2
            generic map (
                -- General Configurations
                TPD_G               => TPD_G,
                INT_PIPE_STAGES_G   => INT_PIPE_STAGES_G,
                PIPE_STAGES_G       => PIPE_STAGES_G,
                SLAVE_READY_EN_G    => true,
                VALID_THOLD_G       => 1,
                -- FIFO configurations
                MEMORY_TYPE_G       => "block",
                GEN_SYNC_FIFO_G     => true,
                FIFO_ADDR_WIDTH_G   => 9,
                -- AXI Stream Port Configurations
                SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_C,
                MASTER_AXI_CONFIG_G => INT_DMA_AXIS_CONFIG_C)
            port map (
                -- Slave Port
                sAxisClk    => axiClk,
                sAxisRst    => axisReset(i),
                sAxisMaster => dmaIbMasters(i),
                sAxisSlave  => dmaIbSlaves(i),
                -- Master Port
                mAxisClk    => axiClk,
                mAxisRst    => axisReset(i),
                mAxisMaster => sAxisMasters(i),
                mAxisSlave  => sAxisSlaves(i));

        ---------------------------
        -- Outbound AXI Stream FIFO
        ---------------------------

        U_ObFifo : entity surf.AxiStreamFifoV2
            generic map (
                TPD_G               => TPD_G,
                INT_PIPE_STAGES_G   => INT_PIPE_STAGES_G,
                PIPE_STAGES_G       => PIPE_STAGES_G,
                SLAVE_READY_EN_G    => false,
                VALID_THOLD_G       => 1,
                -- FIFO configurations
                MEMORY_TYPE_G       => "block",
                GEN_SYNC_FIFO_G     => true,
                FIFO_ADDR_WIDTH_G   => 9,
                FIFO_FIXED_THRESH_G => true,
                FIFO_PAUSE_THRESH_G => 300,  -- 1800 byte buffer before pause and 1696 byte of buffer before FIFO FULL
                -- AXI Stream Port Configurations
                SLAVE_AXI_CONFIG_G  => INT_DMA_AXIS_CONFIG_C,
                MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_C)
            port map (
                -- Slave Port
                sAxisClk    => axiClk,
                sAxisRst    => axisReset(i),
                sAxisMaster => mAxisMasters(i),
                sAxisSlave  => mAxisSlaves(i),
                sAxisCtrl   => mAxisCtrl(i),
                -- Master Port
                mAxisClk    => axiClk,
                mAxisRst    => axisReset(i),
                mAxisMaster => dmaObMasters(i),
                mAxisSlave  => dmaObSlaves(i));

    end generate;

    ----------------------------------
    -- Monitor the Inbound DMA streams
    ----------------------------------

    DMA_AXIS_MON_IB : entity surf.AxiStreamMonAxiL
        generic map(
            TPD_G            => TPD_G,
            COMMON_CLK_G     => true,
            AXIS_CLK_FREQ_G  => DMA_CLK_FREQ_C,
            AXIS_NUM_SLOTS_G => DMA_SIZE_G,
            AXIS_CONFIG_G    => INT_DMA_AXIS_CONFIG_C)
        port map(
            -- AXIS Stream Interface
            axisClk          => axiClk,
            axisRst          => axiRst,
            axisMasters      => sAxisMasters,
            axisSlaves       => sAxisSlaves,
            -- AXI lite slave port for register access
            axilClk          => axiClk,
            axilRst          => axiRst,
            sAxilWriteMaster => axilWriteMasters(1),
            sAxilWriteSlave  => axilWriteSlaves(1),
            sAxilReadMaster  => axilReadMasters(1),
            sAxilReadSlave   => axilReadSlaves(1));

    -----------------------------------
    -- Monitor the Outbound DMA streams
    -----------------------------------

    DMA_AXIS_MON_OB : entity surf.AxiStreamMonAxiL
        generic map(
            TPD_G            => TPD_G,
            COMMON_CLK_G     => true,
            AXIS_CLK_FREQ_G  => DMA_CLK_FREQ_C,
            AXIS_NUM_SLOTS_G => DMA_SIZE_G,
            AXIS_CONFIG_G    => INT_DMA_AXIS_CONFIG_C)
        port map(
            -- AXIS Stream Interface
            axisClk          => axiClk,
            axisRst          => axiRst,
            axisMasters      => mAxisMasters,
            axisSlaves       => (others => AXI_STREAM_SLAVE_FORCE_C),  -- U_ObFifo.SLAVE_READY_EN_G=false
            -- AXI lite slave port for register access
            axilClk          => axiClk,
            axilRst          => axiRst,
            sAxilWriteMaster => axilWriteMasters(2),
            sAxilWriteSlave  => axilWriteSlaves(2),
            sAxilReadMaster  => axilReadMasters(2),
            sAxilReadSlave   => axilReadSlaves(2));

end mapping;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

library axi_soc_7000_core;
use axi_soc_7000_core.AxiSoc7000Pkg.all;
use axi_soc_7000_core.HardwareTypePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AxiSoc7000Reg is
    generic (
        TPD_G           : time                   := 1 ns;
        BUILD_INFO_G    : BuildInfoType;
        EN_DEVICE_DNA_G : boolean                := true;
        COMMON_CLK_G    : boolean                := false;  -- appClk = axilClk?
        DMA_SIZE_G      : positive range 1 to 16 := 1
     -- AXI_BASE_ADDR_G : slv(31 downto 0) := AXIL_REG_BASE_ADDR_C
        );
    port (
        -- ADC Clock and Reset Monitoring
        adcClk         : in  sl;
        adcRst         : in  sl;
        -- AUX Clock and Reset
        auxClk         : in  sl;        -- 100 MHz
        auxRst         : in  sl;
        -- AXI-Lite register access interfaces
        axilClk        : in  sl;
        axilRst        : in  sl;
        regReadMaster  : in  AxiLiteReadMasterType;
        regReadSlave   : out AxiLiteReadSlaveType;
        regWriteMaster : in  AxiLiteWriteMasterType;
        regWriteSlave  : out AxiLiteWriteSlaveType;
        -- Application AXI-Lite Interfaces [0x6000_0000:0x7FFF_FFFF]
        -- (could be appClk domain, but for now it isn't)
        appClk         : in  sl;
        appRst         : in  sl;
        appReadMaster  : out AxiLiteReadMasterType;
        appReadSlave   : in  AxiLiteReadSlaveType;
        appWriteMaster : out AxiLiteWriteMasterType;
        appWriteSlave  : in  AxiLiteWriteSlaveType;
        -- Application Force reset
        appUserRst     : out sl
        );
end entity AxiSoc7000Reg;

architecture mapping of AxiSoc7000Reg is

    constant VERSION_INDEX_C : natural := 0;
    constant APP_INDEX_C     : natural := 1;
    -- constant SYSMON_INDEX_C  : natural := 1;
    -- constant AXIS_MON_IB_C   : natural := 2;
    -- constant AXIS_MON_OB_C   : natural := 3;

    constant NUM_AXI_MASTERS_C : natural := 2;

    constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
        VERSION_INDEX_C  => (
            baseAddr     => (AXIL_REG_BASE_ADDR_C+x"0000_0000"),
            addrBits     => 16,
            connectivity => x"FFFF"),
        -- SYSMON_INDEX_C   => (
        --     baseAddr     => x"0001_0000",
        --     addrBits     => 16,
        --     connectivity => x"FFFF"),
        -- AXIS_MON_IB_C    => (
        --     baseAddr     => x"0002_0000",
        --     addrBits     => 16,
        --     connectivity => x"FFFF"),
        -- AXIS_MON_OB_C    => (
        --     baseAddr     => x"0003_0000",
        --     addrBits     => 16,
        --     connectivity => x"FFFF"),
        APP_INDEX_C      => (
            baseAddr     => (AXIL_REG_BASE_ADDR_C+APP_ADDR_OFFSET_C),
            addrBits     => APP_ADDR_BITS_C,
            connectivity => x"FFFF")
        );

    signal axilReadMaster  : AxiLiteReadMasterType;
    signal axilReadSlave   : AxiLiteReadSlaveType;
    signal axilWriteMaster : AxiLiteWriteMasterType;
    signal axilWriteSlave  : AxiLiteWriteSlaveType;

    signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
    signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
    signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
    signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

    signal axilUserRst : sl;
    signal userRst     : sl := '0';

    signal userValues        : Slv32Array(0 to 63) := (others => x"00000000");
    signal appClkFreq        : slv(31 downto 0);
    signal appRstSyncAxilClk : sl;
    signal adcClkFreq        : slv(31 downto 0);
    signal adcRstSyncAxilClk : sl;

begin

    ---------------------------------------------------------------------------------------------
    -- Driver Polls the userValues to determine the firmware's configurations and interrupt state
    ---------------------------------------------------------------------------------------------
    process(appClkFreq, appRstSyncAxilClk, adcClkFreq, adcRstSyncAxilClk)
    begin
        -- Number of DMA lanes (defined by user)
        userValues(0) <= toSlv(DMA_SIZE_G, 32);

        -- System Clock Frequency (TODO does this make sense?)
        userValues(1) <= toSlv(getTimeRatio(DMA_CLK_FREQ_C, 1.0), 32);

        -- Application Reset
        userValues(2)(0) <= appRstSyncAxilClk;

        -- Application Clock Frequency
        userValues(3) <= appClkFreq;

        -- DSP Clock Frequency
        userValues(4) <= adcClkFreq;

        -- DSP Reset
        userValues(5)(0) <= adcRstSyncAxilClk;

        -- Hardware Type
        userValues(6) <= HW_TYPE_C;

    end process;

    -- Map ports for AXI-Lite interface to CPU (CPU has master,
    -- accesses slaves in application or this module).
    -- TODO?: Remove this reassignment by renaming the signals.
    axilReadMaster  <= regReadMaster;
    regReadSlave    <= axilReadSlave;
    axilWriteMaster <= regWriteMaster;
    regWriteSlave   <= axilWriteSlave;

    --------------------------------------
    -- AXI-Lite Synchronizing and Crossbar
    --------------------------------------
    -- Synchronize application interface (CPU has master, application has 
    -- slaves) to CPUs AXI-Lite clock domain (axilClk).
    U_AxiLiteAsync : entity surf.AxiLiteAsync
        generic map (
            TPD_G           => TPD_G,
            COMMON_CLK_G    => COMMON_CLK_G,
            NUM_ADDR_BITS_G => 32  -- should be at least 29 to fit into address space set in BD?
            )
        port map (
            -- Slave Interface
            sAxiClk         => axilClk,
            sAxiClkRst      => axilRst,
            sAxiReadMaster  => axilReadMasters(APP_INDEX_C),
            sAxiReadSlave   => axilReadSlaves(APP_INDEX_C),
            sAxiWriteMaster => axilWriteMasters(APP_INDEX_C),
            sAxiWriteSlave  => axilWriteSlaves(APP_INDEX_C),
            -- Master Interface
            mAxiClk         => appClk,
            mAxiClkRst      => appRst,
            mAxiReadMaster  => appReadMaster,
            mAxiReadSlave   => appReadSlave,
            mAxiWriteMaster => appWriteMaster,
            mAxiWriteSlave  => appWriteSlave);

    -- Merge (synchronized) application AXI-Lite interface with AXI-Lite
    -- interfaces connected to slaves in this module (e.g. AxiVersion).
    U_XBAR : entity surf.AxiLiteCrossbar
        generic map (
            TPD_G              => TPD_G,
            -- DEBUG_G         => true  -- Try enable debug printouts
            NUM_SLAVE_SLOTS_G  => 1,
            NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
            MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
        port map (
            axiClk              => axilClk,
            axiClkRst           => axilRst,
            sAxiWriteMasters(0) => axilWriteMaster,
            sAxiWriteSlaves(0)  => axilWriteSlave,
            sAxiReadMasters(0)  => axilReadMaster,
            sAxiReadSlaves(0)   => axilReadSlave,
            mAxiWriteMasters    => axilWriteMasters,
            mAxiWriteSlaves     => axilWriteSlaves,
            mAxiReadMasters     => axilReadMasters,
            mAxiReadSlaves      => axilReadSlaves);

    --------------------------
    -- AXI-Lite Version Module
    --------------------------
    U_Version : entity surf.AxiVersion
        generic map (
            TPD_G           => TPD_G,
            BUILD_INFO_G    => BUILD_INFO_G,
            CLK_PERIOD_G    => AXIL_CLK_PERIOD_C,
            USE_SLOWCLK_G   => false,
            EN_DEVICE_DNA_G => EN_DEVICE_DNA_G,
            XIL_DEVICE_G    => "7SERIES",
            EN_ICAP_G       => false)
        port map (
            -- slowClk        => auxClk,
            -- AXI-Lite Interface
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(VERSION_INDEX_C),
            axiReadSlave   => axilReadSlaves(VERSION_INDEX_C),
            axiWriteMaster => axilWriteMasters(VERSION_INDEX_C),
            axiWriteSlave  => axilWriteSlaves(VERSION_INDEX_C),
            -- Optional: User Reset
            userReset      => userRst,
            -- Optional: user values
            userValues     => userValues);

    -----------------------------
    -- User reset (from register)
    -----------------------------
    -- Generated long-ish reset pulse synchronous to axilClk
    U_RstGtSync : entity surf.PwrUpRst
        generic map (
            TPD_G      => TPD_G,
            DURATION_G => 100)          -- 100 clock cycle pulse
        port map (
            arst   => userRst,          -- [in]
            clk    => axilClk,          -- [in]
            rstOut => axilUserRst);     -- [out]

    -- Synchronize to user clock
    U_axilRst : entity surf.RstSync
        generic map (
            TPD_G => TPD_G)
        port map (
            clk      => appClk,
            asyncRst => axilUserRst,
            syncRst  => appUserRst);

    -- Some static registers for testing
    -- U_REG_STATIC : entity axi_soc_7000_core.AxiTestRegister
    --     port map(
    --         pl_clk          => pl_clk,
    --         axilReadMaster  => axilReadMasters(VERSION_INDEX_C),
    --         axilReadSlave   => axilReadSlaves(VERSION_INDEX_C),
    --         axilWriteMaster => axilWriteMasters(VERSION_INDEX_C),
    --         axilWriteSlave  => axilWriteSlaves(VERSION_INDEX_C));

    ---------------------------------
    -- DSP Clock and Reset Monitoring
    ---------------------------------
    U_dspClkFreq : entity surf.SyncClockFreq
        generic map (
            TPD_G          => TPD_G,
            REF_CLK_FREQ_G => AXIL_CLK_FREQ_C,
            REFRESH_RATE_G => 1.0,
            CNT_WIDTH_G    => 32)
        port map (
            -- Frequency Measurement (locClk domain)
            freqOut => adcClkFreq,
            -- Clocks
            clkIn   => adcClk,
            locClk  => axilClk,
            refClk  => axilClk);

    -- Synchronize appRst to axilClk for register readback
    U_dspRstL : entity surf.Synchronizer
        generic map (
            TPD_G => TPD_G)
        port map (
            clk     => axilClk,
            dataIn  => adcRst,
            dataOut => adcRstSyncAxilClk);

    ---------------------------------
    -- DSP Clock and Reset Monitoring
    ---------------------------------

    -- Measure app clock frequency
    U_appClkFreq : entity surf.SyncClockFreq
        generic map (
            TPD_G          => TPD_G,
            REF_CLK_FREQ_G => AXIL_CLK_FREQ_C,
            REFRESH_RATE_G => 1.0,
            CNT_WIDTH_G    => 32)
        port map (
            -- Frequency Measurement (locClk domain)
            freqOut => appClkFreq,
            -- Clocks
            clkIn   => appClk,
            locClk  => axilClk,
            refClk  => axilClk);

    -- Synchronize appRst to axilClk for register readback
    U_AppRstSyncAxilClk : entity surf.Synchronizer
        generic map (
            TPD_G => TPD_G)
        port map (
            clk     => axilClk,
            dataIn  => appRst,
            dataOut => appRstSyncAxilClk);

end architecture mapping;

library ieee;
use ieee.std_logic_1164.all;

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
        TPD_G        : time := 1 ns;
        BUILD_INFO_G : BuildInfoType
        );
    port (
        -- Global pl clock
        pl_clk         : in  std_logic;
        -- Global pl reset
        pl_rst         : in  std_logic;
        -- AXI-Lite register acess interfaces
        regReadMaster  : in  AxiLiteReadMasterType;
        regReadSlave   : out AxiLiteReadSlaveType;
        regWriteMaster : in  AxiLiteWriteMasterType;
        regWriteSlave  : out AxiLiteWriteSlaveType;
        -- Application AXI-Lite Interfaces [0x80000000:0xFFFFFFFF] 
        -- (could be appClk domain, but for now it isn't)
        -- appClk         : in  sl;
        -- appRst         : in  sl;
        appReadMaster  : out AxiLiteReadMasterType;
        appReadSlave   : in  AxiLiteReadSlaveType;
        appWriteMaster : out AxiLiteWriteMasterType;
        appWriteSlave  : in  AxiLiteWriteSlaveType
        );
end entity AxiSoc7000Reg;

architecture mapping of AxiSoc7000Reg is

    constant VERSION_INDEX_C : natural := 0;
    constant SYSMON_INDEX_C  : natural := 1;
    constant AXIS_MON_IB_C   : natural := 2;
    constant AXIS_MON_OB_C   : natural := 3;
    constant APP_INDEX_C     : natural := 4;

    constant NUM_AXI_MASTERS_C : natural := 5;

    constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
        VERSION_INDEX_C  => (
            baseAddr     => x"0000_0000",
            addrBits     => 16,
            connectivity => x"FFFF"),
        SYSMON_INDEX_C   => (
            baseAddr     => x"0001_0000",
            addrBits     => 16,
            connectivity => x"FFFF"),
        AXIS_MON_IB_C    => (
            baseAddr     => x"0002_0000",
            addrBits     => 16,
            connectivity => x"FFFF"),
        AXIS_MON_OB_C    => (
            baseAddr     => x"0003_0000",
            addrBits     => 16,
            connectivity => x"FFFF"),
        APP_INDEX_C      => (
            baseAddr     => APP_ADDR_OFFSET_C,
            addrBits     => 31,
            connectivity => x"FFFF"));

    signal axilReadMaster  : AxiLiteReadMasterType;
    signal axilReadSlave   : AxiLiteReadSlaveType;
    signal axilWriteMaster : AxiLiteWriteMasterType;
    signal axilWriteSlave  : AxiLiteWriteSlaveType;

    signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
    signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
    signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
    signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

    signal userValues : Slv32Array(0 to 63) := (others => x"00000000");

begin

    ---------------------------------------------------------------------------------------------
    -- Driver Polls the userValues to determine the firmware's configurations and interrupt state
    ---------------------------------------------------------------------------------------------
    -- process(pl_clk, pl_rst)
    --     variable i : natural;
    -- begin
    --     -- Number of DMA lanes (defined by user)
    --     userValues(0) <= toSlv(DMA_SIZE_G, 32);
    --
    --     -- System Clock Frequency
    --     userValues(1) <= toSlv(getTimeRatio(DMA_CLK_FREQ_C, 1.0), 32);
    --
    --     -- Application Reset
    --     userValues(2)(0) <= appResetSync;
    --
    --     -- Application Clock Frequency
    --     userValues(3) <= appClkFreq;
    --
    --     -- DSP Clock Frequency
    --     userValues(4) <= dspClkFreq;
    --
    --     -- DSP Reset
    --     userValues(5)(0) <= dspRstSync;
    --
    --     -- Hardware Type
    --     userValues(6) <= HW_TYPE_C;
    --
    -- end process;

    axilReadMaster  <= regReadMaster;
    regReadSlave    <= axilReadSlave;
    axilWriteMaster <= regWriteMaster;
    regWriteSlave   <= axilWriteSlave;

    --------------------
    -- AXI-Lite Crossbar
    --------------------

    U_XBAR : entity surf.AxiLiteCrossbar
        generic map (
            TPD_G              => TPD_G,
            NUM_SLAVE_SLOTS_G  => 1,
            NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
            MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
        port map (
            axiClk              => pl_clk,
            axiClkRst           => pl_rst,
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
            TPD_G         => TPD_G,
            BUILD_INFO_G  => BUILD_INFO_G,
            --CLK_PERIOD_G    => DMA_CLK_PERIOD_C,
            USE_SLOWCLK_G => true,
            --EN_DEVICE_DNA_G => EN_DEVICE_DNA_G,
            XIL_DEVICE_G  => "7SERIES",
            EN_ICAP_G     => false)
        port map (
            --slowClk        => auxClk,
            -- AXI-Lite Interface
            axiClk         => pl_clk,
            axiRst         => pl_rst,
            axiReadMaster  => axilReadMasters(VERSION_INDEX_C),
            axiReadSlave   => axilReadSlaves(VERSION_INDEX_C),
            axiWriteMaster => axilWriteMasters(VERSION_INDEX_C),
            axiWriteSlave  => axilWriteSlaves(VERSION_INDEX_C)
         -- Optional: User Reset
         --userReset      => cardResetOut,
         -- Optional: user values
         -- userValues     => userValues
            );

end architecture mapping;

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiPkg.all;

package AxiSoc7000Pkg is
    -- TODO: Implement!

    -- -- System Clock Frequency/Period
    -- constant DMA_CLK_FREQ_C   : real := 250.0E+6;              -- units of Hz
    -- constant DMA_CLK_PERIOD_C : real := (1.0/DMA_CLK_FREQ_C);  -- units of seconds
    --
    -- -- Aux Clock Frequency/Period
    -- constant AUX_CLK_FREQ_C   : real := 100.0E+6;              -- units of Hz
    -- constant AUX_CLK_PERIOD_C : real := (1.0/AUX_CLK_FREQ_C);  -- units of seconds
    --
    -- Application Address Offset
    constant APP_ADDR_OFFSET_C           : slv(31 downto 0) := x"2000_0000";
    --
    -- -- SOC AXI Configuration
    -- constant AXI_SOC_CONFIG_C : AxiConfigType := (
    --    ADDR_WIDTH_C => 40,               -- 40-bit address interface
    --    DATA_BYTES_C => 16,               -- 128-bit data interface
    --    ID_BITS_C    => 4,                -- Up to 16 DMA IDS
    --    LEN_BITS_C   => 8);               -- 8-bit awlen/arlen interface
    --
    -- -- DMA AXI Stream Configuration
    -- constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := (
    --    TSTRB_EN_C    => false,
    --    TDATA_BYTES_C => AXI_SOC_CONFIG_C.DATA_BYTES_C,  -- Map the widths of the AXI interface
    --    TDEST_BITS_C  => 8,
    --    TID_BITS_C    => 3,
    --    TKEEP_MODE_C  => TKEEP_COMP_C,
    --    TUSER_BITS_C  => 4,
    --    TUSER_MODE_C  => TUSER_FIRST_LAST_C);
    --
    -- List of PCIe Hardware Types
    constant HW_TYPE_UNDEFINED_C         : slv(31 downto 0) := x"00_00_00_00";
    constant HW_TYPE_RPTY_STEMLAB_125_14 : slv(31 downto 0) := x"00_00_00_01";  -- Stemlab 125-14

    -- Type for DDR3 ports
    type DDR3_ports is record
        DDR_addr          : std_logic_vector (14 downto 0);
        DDR_ba            : std_logic_vector (2 downto 0);
        DDR_cas_n         : std_logic;
        DDR_ck_n          : std_logic;
        DDR_ck_p          : std_logic;
        DDR_cke           : std_logic;
        DDR_cs_n          : std_logic;
        DDR_dm            : std_logic_vector (3 downto 0);
        DDR_dq            : std_logic_vector (31 downto 0);
        DDR_dqs_n         : std_logic_vector (3 downto 0);
        DDR_dqs_p         : std_logic_vector (3 downto 0);
        DDR_odt           : std_logic;
        DDR_ras_n         : std_logic;
        DDR_reset_n       : std_logic;
        DDR_we_n          : std_logic;
        FIXED_IO_ddr_vrn  : std_logic;
        FIXED_IO_ddr_vrp  : std_logic;
        FIXED_IO_mio      : std_logic_vector (53 downto 0);
        FIXED_IO_ps_clk   : std_logic;
        FIXED_IO_ps_porb  : std_logic;
        FIXED_IO_ps_srstb : std_logic;
    end record DDR3_ports;

end package AxiSoc7000Pkg;

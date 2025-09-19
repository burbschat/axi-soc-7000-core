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

        -- Master AXI-Lite Interface (DMA control)
        dmaCtrlReadMaster  : out AxiLiteReadMasterType;
        dmaCtrlReadSlave   : in  AxiLiteReadSlaveType;
        dmaCtrlWriteMaster : out AxiLiteWriteMasterType;
        dmaCtrlWriteSlave  : in  AxiLiteWriteSlaveType;

        -- Slave AXI4 Interface (DMA) 
        -- The 7series ZYNQ only supports AXI3 but this is translated to AXI4 by a block in the block design
        dmaReadMaster  : in  AxiReadMasterType;
        dmaReadSlave   : out AxiReadSlaveType;
        dmaWriteMaster : in  AxiWriteMasterType;
        dmaWriteSlave  : out AxiWriteSlaveType;

        -- Reset
        reset_l : in std_logic
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

            -- Master AXI-Lite Interface (DMA control)
            axi_dmactrl_araddr  : out std_logic_vector (31 downto 0);
            axi_dmactrl_arprot  : out std_logic_vector (2 downto 0);
            axi_dmactrl_arready : in  std_logic;
            axi_dmactrl_arvalid : out std_logic;
            axi_dmactrl_awaddr  : out std_logic_vector (31 downto 0);
            axi_dmactrl_awprot  : out std_logic_vector (2 downto 0);
            axi_dmactrl_awready : in  std_logic;
            axi_dmactrl_awvalid : out std_logic;
            axi_dmactrl_bready  : out std_logic;
            axi_dmactrl_bresp   : in  std_logic_vector (1 downto 0);
            axi_dmactrl_bvalid  : in  std_logic;
            axi_dmactrl_rdata   : in  std_logic_vector (31 downto 0);
            axi_dmactrl_rready  : out std_logic;
            axi_dmactrl_rresp   : in  std_logic_vector (1 downto 0);
            axi_dmactrl_rvalid  : in  std_logic;
            axi_dmactrl_wdata   : out std_logic_vector (31 downto 0);
            axi_dmactrl_wready  : in  std_logic;
            axi_dmactrl_wstrb   : out std_logic_vector (3 downto 0);
            axi_dmactrl_wvalid  : out std_logic;

            -- Slave AXI4 Interface (DMA)
            axi_dma_araddr  : in  std_logic_vector (31 downto 0);
            axi_dma_arburst : in  std_logic_vector (1 downto 0);
            axi_dma_arcache : in  std_logic_vector (3 downto 0);
            axi_dma_arid    : in  std_logic_vector (5 downto 0);
            axi_dma_arlen   : in  std_logic_vector (7 downto 0);
            axi_dma_arlock  : in  std_logic_vector (0 to 0);
            axi_dma_arprot  : in  std_logic_vector (2 downto 0);
            axi_dma_arqos   : in  std_logic_vector (3 downto 0);
            axi_dma_arready : out std_logic;
            axi_dma_arregion: in  std_logic_vector (3 downto 0);
            axi_dma_arsize  : in  std_logic_vector (2 downto 0);
            axi_dma_arvalid : in  std_logic;
            axi_dma_awaddr  : in  std_logic_vector (31 downto 0);
            axi_dma_awburst : in  std_logic_vector (1 downto 0);
            axi_dma_awcache : in  std_logic_vector (3 downto 0);
            axi_dma_awid    : in  std_logic_vector (5 downto 0);
            axi_dma_awlen   : in  std_logic_vector (7 downto 0);
            axi_dma_awlock  : in  std_logic_vector (0 to 0);
            axi_dma_awprot  : in  std_logic_vector (2 downto 0);
            axi_dma_awqos   : in  std_logic_vector (3 downto 0);
            axi_dma_awready : out std_logic;
            axi_dma_awregion: in  std_logic_vector (3 downto 0);
            axi_dma_awsize  : in  std_logic_vector (2 downto 0);
            axi_dma_awvalid : in  std_logic;
            axi_dma_bid     : out std_logic_vector (5 downto 0);
            axi_dma_bready  : in  std_logic;
            axi_dma_bresp   : out std_logic_vector (1 downto 0);
            axi_dma_bvalid  : out std_logic;
            axi_dma_rdata   : out std_logic_vector (63 downto 0);
            axi_dma_rid     : out std_logic_vector (5 downto 0);
            axi_dma_rlast   : out std_logic;
            axi_dma_rready  : in  std_logic;
            axi_dma_rresp   : out std_logic_vector (1 downto 0);
            axi_dma_rvalid  : out std_logic;
            axi_dma_wdata   : in  std_logic_vector (63 downto 0);
            axi_dma_wlast   : in  std_logic;
            axi_dma_wready  : out std_logic;
            axi_dma_wstrb   : in  std_logic_vector (7 downto 0);
            axi_dma_wvalid  : in  std_logic;

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

            -- Master AXI-Lite Interface (DMA control)
            axi_dmactrl_araddr(31 downto 0) => regReadMaster.araddr,
            axi_dmactrl_arprot(2 downto 0)  => regReadMaster.arprot,
            axi_dmactrl_arready             => regReadSlave.arready,
            axi_dmactrl_arvalid             => regReadMaster.arvalid,
            axi_dmactrl_awaddr(31 downto 0) => regWriteMaster.awaddr,
            axi_dmactrl_awprot(2 downto 0)  => regWriteMaster.awprot,
            axi_dmactrl_awready             => regWriteSlave.awready,
            axi_dmactrl_awvalid             => regWriteMaster.awvalid,
            axi_dmactrl_bready              => regWriteMaster.bready,
            axi_dmactrl_bresp(1 downto 0)   => AXI_RESP_OK_C,  -- Always respond OK
            axi_dmactrl_bvalid              => regWriteSlave.bvalid,
            axi_dmactrl_rdata(31 downto 0)  => regReadSlave.rdata,
            axi_dmactrl_rready              => regReadMaster.rready,
            axi_dmactrl_rresp(1 downto 0)   => AXI_RESP_OK_C,  -- Always respond OK
            axi_dmactrl_rvalid              => regReadSlave.rvalid,
            axi_dmactrl_wdata(31 downto 0)  => regWriteMaster.wdata,
            axi_dmactrl_wready              => regWriteSlave.wready,
            axi_dmactrl_wstrb(3 downto 0)   => regWriteMaster.wstrb,
            axi_dmactrl_wvalid              => regWriteMaster.wvalid,

            -- Slave AXI4 Interface (DMA)
            -- The 7series ZYNQ only supports AXI3 but this is translated to AXI4 by a block in the block design
            axi_dma_araddr(31 downto 0) => dmaReadMaster.araddr(31 downto 0),
            axi_dma_arburst(1 downto 0) => dmaReadMaster.arburst,
            axi_dma_arcache(3 downto 0) => dmaReadMaster.arcache,
            axi_dma_arid(5 downto 0)    => dmaReadMaster.arid(5 downto 0),
            axi_dma_arlen(7 downto 0)   => dmaReadMaster.arlen(AXI_SOC_CONFIG_C.LEN_BITS_C-1 downto 0),
            axi_dma_arlock(1 downto 0)  => (others => '0'),
            axi_dma_arprot(2 downto 0)  => dmaReadMaster.arprot,
            axi_dma_arqos(3 downto 0)   => dmaReadMaster.arqos,
            axi_dma_arready             => dmaReadSlave.arready,
            axi_dma_arregion(3 downto 0)=> (others => '0'),  -- Regions unused but can't be disabled in protocol convert block
            axi_dma_arsize(2 downto 0)  => dmaReadMaster.arsize,
            axi_dma_arvalid             => dmaReadMaster.arvalid,
            axi_dma_awaddr(31 downto 0) => dmaWriteMaster.awaddr(31 downto 0),
            axi_dma_awburst(1 downto 0) => dmaWriteMaster.awburst,
            axi_dma_awcache(3 downto 0) => dmaWriteMaster.awcache,
            axi_dma_awid(5 downto 0)    => dmaWriteMaster.awid(5 downto 0),
            axi_dma_awlen(7 downto 0)   => dmaWriteMaster.awlen(AXI_SOC_CONFIG_C.LEN_BITS_C-1 downto 0),
            axi_dma_awlock(1 downto 0)  => (others => '0'),
            axi_dma_awprot(2 downto 0)  => dmaWriteMaster.awprot,
            axi_dma_awqos(3 downto 0)   => dmaWriteMaster.awqos,
            axi_dma_awready             => dmaWriteSlave.awready,
            axi_dma_awregion(3 downto 0)=> (others => '0'),  -- Regions unused but can't be disabled in protocol convert block
            axi_dma_awsize(2 downto 0)  => dmaWriteMaster.awsize,
            axi_dma_awvalid             => dmaWriteMaster.awvalid,
            axi_dma_bid(5 downto 0)     => dmaWriteSlave.bid(5 downto 0),
            axi_dma_bready              => dmaWriteMaster.bready,
            axi_dma_bresp(1 downto 0)   => dmaWriteSlave.bresp,
            axi_dma_bvalid              => dmaWriteSlave.bvalid,
            axi_dma_rdata(63 downto 0)  => dmaReadSlave.rdata(8*AXI_SOC_CONFIG_C.DATA_BYTES_C-1 downto 0),
            axi_dma_rid(5 downto 0)     => dmaReadSlave.rid(5 downto 0),
            axi_dma_rlast               => dmaReadSlave.rlast,
            axi_dma_rready              => dmaReadMaster.rready,
            axi_dma_rresp(1 downto 0)   => dmaReadSlave.rresp,
            axi_dma_rvalid              => dmaReadSlave.rvalid,
            axi_dma_wdata(63 downto 0)  => dmaWriteMaster.wdata(8*AXI_SOC_CONFIG_C.DATA_BYTES_C-1 downto 0),
            -- AXI4 has no WID. If we only ever write to PS from PL, setting id to 0 is fine?
            axi_dma_wlast               => dmaWriteMaster.wlast,
            axi_dma_wready              => dmaWriteSlave.wready,
            axi_dma_wstrb(7 downto 0)   => dmaWriteMaster.wstrb,
            axi_dma_wvalid              => dmaWriteMaster.wvalid,

            -- Reset
            reset_l                   => reset_l
            );

end architecture mapping;

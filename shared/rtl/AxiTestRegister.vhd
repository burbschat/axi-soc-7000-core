library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library axi_soc_7000_core;
use axi_soc_7000_core.AxiSoc7000Pkg.all;

entity AxiTestRegister is
    generic (
        TPD_G : time := 1 ns);
    port (
        -- PL clock
        pl_clk          : in  sl;
        -- AXI-Lite Interface
        axilReadMaster  : in  AxiLiteReadMasterType;
        axilReadSlave   : out AxiLiteReadSlaveType;
        axilWriteMaster : in  AxiLiteWriteMasterType;
        axilWriteSlave  : out AxiLiteWriteSlaveType);
end entity AxiTestRegister;

architecture rtl of AxiTestRegister is

    type RegType is record
        reg1           : slv(31 downto 0);
        reg2           : slv(31 downto 0);
        reg3           : slv(31 downto 0);
        axilReadSlave  : AxiLiteReadSlaveType;
        axilWriteSlave : AxiLiteWriteSlaveType;
    end record RegType;

    constant REG_INIT_C : RegType := (
        reg1           => (others => '1'),
        reg2           => (others => '0'),
        reg3           => b"10101010101010101010101010101010",
        axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
        axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

    signal r   : RegType := REG_INIT_C;
    signal rin : RegType;

begin

    comb : process (axilReadMaster, axilWriteMaster, r) is
        variable v      : RegType;
        variable axilEp : AxiLiteEndPointType;
    begin

        -- Latch the current value
        v := r;

        ----------------------------------------------------------------------
        --                AXI-Lite Register Logic
        ----------------------------------------------------------------------

        -- Determine the transaction type
        axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

        -------------------------
        -- Map the read registers
        -------------------------

        axiSlaveRegister (axilEp, x"00", 0, v.reg1);  -- All ones
        axiSlaveRegister (axilEp, x"04", 0, v.reg2);  -- All zeros
        axiSlaveRegister (axilEp, x"08", 0, v.reg3);  -- Alternating ones and zeros

        -- Closeout the transaction
        axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

        ----------------------------------------------------------------------

        -- Outputs
        axilWriteSlave <= r.axilWriteSlave;
        axilReadSlave  <= r.axilReadSlave;

        -- Register the variable for next clock cycle
        rin <= v;

    end process comb;

    seq : process (pl_clk) is
    begin
        if rising_edge(pl_clk) then
            r <= rin after TPD_G;
        end if;
    end process seq;

end architecture rtl;

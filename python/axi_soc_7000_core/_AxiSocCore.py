import pyrogue as pr
import axi_soc_7000_core as core


class AxiSocCore(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        # AxiVersion Module
        self.add(core.AxiVersion(
            offset       = 0x0_0000,
            expand       = False,
            hidden       = False,
        ))

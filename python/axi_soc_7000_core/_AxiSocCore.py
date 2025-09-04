import pyrogue as pr


class AxiSocCore(pr.Device):
    def __init(self, **kwargs):
        super().__init__(**kwargs)

        # AxiVersion Module
        self.add(core.AxiVersion(
            offset       = 0x0_0000,
            expand       = False,
            hidden       = False,
        ))

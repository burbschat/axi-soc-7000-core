import pyrogue       as pr
import surf.axi      as axi

class AxiVersion(axi.AxiVersion):
    def __init__(self,
            name             = 'AxiVersion',
            description      = 'AXI-Lite Version Module',
            **kwargs):
        super().__init__(
            name        = name,
            description = description,
            **kwargs
        )

        # TODO: Implement firmware register for this
        # self.add(pr.RemoteVariable(
        #     name         = 'HW_TYPE_C',
        #     offset       = 0x400+(4*6),
        #     bitSize      = 32,
        #     bitOffset    = 0,
        #     mode         = 'RO',
        #     enum        = {
        #         0x00_00_00_00: 'Undefined',
        #         0x00_00_00_01: 'RptyStemlab125-14',
        #     },
        # ))

    def printStatus(self):
        super().printStatus()
        print("HW_TYPE_C      = {}".format(self.HW_TYPE_C.getDisp()))

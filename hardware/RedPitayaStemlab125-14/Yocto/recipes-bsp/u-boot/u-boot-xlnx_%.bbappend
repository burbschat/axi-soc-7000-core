FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://platform-top.h"
SRC_URI += "file://bsp.cfg"
SRC_URI += "file://0001-Extract-ethaddr-from-EEPROM-on-RedPitaya-boards.patch"

do_configure:append () {
	install ${WORKDIR}/platform-top.h ${S}/include/configs/
}

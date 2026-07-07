# Derived from exp2/tests/Single_Cycle_Test.py by Doğu Erkan Arkadaş

import logging
from tabulate import tabulate
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

from helper_lib import Log_Datapath, Log_Controller
from riscv_golden_model import RISCV_Golden_Model


class TB:
    def __init__(self, Instruction_list, dut):
        self.dut = dut
        self.dut_PC = dut.PC
        self.dut_regfile = dut.my_datapath.regfile
        self.Instruction_list = Instruction_list
        self.logger = logging.getLogger("Performance Model")
        self.logger.setLevel(logging.DEBUG)
        self.model = RISCV_Golden_Model()
        self.clock_cycle_count = 0

    def log_dut(self):
        Log_Datapath(self.dut, self.logger)
        Log_Controller(self.dut, self.logger)

    def compare_result(self):
        log_data = []

        # log registers
        for i in range(1, 32):  # x0 is zero
            log_data.append([
                f"x{i}",
                hex(self.model.regs[i]),
                hex(self.dut_regfile.x[i].value),
            ])

        # log memory, only addresses that the model has touched
        for addr in self.model.mem.keys():
            log_data.append([
                f"Mem[{addr}]",
                hex(self.model.mem[addr]),
                hex(self.dut.my_datapath.data_mem.mem[addr].value),
            ])

        table = tabulate(
            log_data,
            headers=["Signal", "Expected Val", "DUT Val"],
            tablefmt="github",
        )
        self.logger.debug("\n" + table)

        assert self.model.pc == int(self.dut_PC.value)
        for i in range(1, 32):
            assert self.model.regs[i] == int(self.dut_regfile.x[i].value)
        for addr, expected_byte in self.model.mem.items():
            if addr < 0x400:
                assert expected_byte == int(
                    self.dut.my_datapath.data_mem.mem[addr].value
                )

    async def run_test(self):
        await Timer(1, unit="ns")
        while self.Instruction_list[self.model.pc // 4] != 0:
            self.clock_cycle_count += 1

            instr = self.Instruction_list[self.model.pc // 4]
            self.model.step(instr)

            await RisingEdge(self.dut.clk)
            await FallingEdge(self.dut.clk)

            self.log_dut()
            self.compare_result()


@cocotb.test()
async def single_cycle_riscv_test(dut):
    Clock(dut.clk, 10, unit="ns").start()  # 100MHz clock

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await FallingEdge(dut.clk)

    instruction_list = []
    with open("../hdl/instructions.hex", "r") as f:
        for line in f:
            line = line.strip()
            parts = line.split()
            reversed_hex = "".join(reversed(parts))
            instruction_list.append(int(reversed_hex, 16))

    tb = TB(instruction_list, dut)
    await tb.run_test()

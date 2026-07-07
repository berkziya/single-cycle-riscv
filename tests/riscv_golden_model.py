def s32(val):
    val = val & 0xFFFFFFFF
    return val - (1 << 32) if (val & 0x80000000) else val


def u32(val):
    return val & 0xFFFFFFFF


def signed_bin(b):
    val = int(b, 2)
    if b[0] == "1":
        val -= 1 << len(b)
    return val


class RISCV_Golden_Model:
    def __init__(self):
        self.regs = [0] * 32
        self.mem = {}  # address -> byte
        self.pc = 0

    def step(self, instr):
        b = f"{instr:032b}"

        funct7 = b[0:7]
        rs2 = b[7:12]
        rs1 = b[12:17]
        funct3 = b[17:20]
        rd = b[20:25]
        opcode = b[25:32]

        imm_i = signed_bin(b[0:12])
        imm_s = signed_bin(b[0:7] + b[20:25])
        imm_b = signed_bin(b[0] + b[24] + b[1:7] + b[20:24] + "0")
        imm_u = signed_bin(b[0:20] + "0" * 12)
        imm_j = signed_bin(b[0] + b[12:20] + b[11] + b[1:11] + "0")

        v1 = self.regs[int(rs1, 2)]
        v2 = self.regs[int(rs2, 2)]

        next_pc = self.pc + 4
        write_reg = False
        result = 0

        if opcode == "0110011":  # R-type
            write_reg = True
            if funct3 == "000" and funct7 == "0000000":
                result = v1 + v2  # add
            if funct3 == "000" and funct7 == "0100000":
                result = v1 - v2  # sub
            if funct3 == "001":
                result = v1 << (v2 & 0b11111)  # sll
            if funct3 == "010":
                result = 1 if s32(v1) < s32(v2) else 0  # slt
            if funct3 == "011":
                result = 1 if u32(v1) < u32(v2) else 0  # sltu
            if funct3 == "100":
                result = v1 ^ v2  # xor
            if funct3 == "101" and funct7 == "0000000":
                result = u32(v1) >> (v2 & 0b11111)  # srl
            if funct3 == "101" and funct7 == "0100000":
                result = s32(v1) >> (v2 & 0b11111)  # sra
            if funct3 == "110":
                result = v1 | v2  # or
            if funct3 == "111":
                result = v1 & v2  # and

        elif opcode == "0010011":  # I-type ALU
            write_reg = True
            if funct3 == "000":
                result = v1 + imm_i  # addi
            if funct3 == "010":
                result = 1 if s32(v1) < imm_i else 0  # slti
            if funct3 == "011":
                result = 1 if u32(v1) < u32(imm_i) else 0  # sltiu
            if funct3 == "100":
                result = v1 ^ imm_i  # xori
            if funct3 == "110":
                result = v1 | imm_i  # ori
            if funct3 == "111":
                result = v1 & imm_i  # andi
            if funct3 == "001":
                result = v1 << (imm_i & 0b11111)  # slli
            if funct3 == "101" and funct7 == "0000000":
                result = u32(v1) >> (imm_i & 0b11111)  # srli
            if funct3 == "101" and funct7 == "0100000":
                result = s32(v1) >> (imm_i & 0b11111)  # srai

        elif opcode == "0000011":  # Loads
            write_reg = True
            addr = u32(v1 + imm_i)
            b0 = self.mem.get(addr, 0)
            b1 = self.mem.get(addr + 1, 0)
            b2 = self.mem.get(addr + 2, 0)
            b3 = self.mem.get(addr + 3, 0)

            if funct3 == "000":
                result = signed_bin(f"{b0:08b}")  # lb
            if funct3 == "001":
                result = signed_bin(f"{b1:08b}{b0:08b}")  # lh
            if funct3 == "010":
                result = s32((b3 << 24) | (b2 << 16) | (b1 << 8) | b0)  # lw
            if funct3 == "100":
                result = b0  # lbu
            if funct3 == "101":
                result = (b1 << 8) | b0  # lhu

        elif opcode == "0100011":  # Stores
            addr = u32(v1 + imm_s)
            if addr >= 0x400:
                pass
            elif funct3 == "000":
                self.mem[addr] = v2 & 0xFF  # sb
            elif funct3 == "001":
                self.mem[addr] = v2 & 0xFF  # sh
                self.mem[addr + 1] = (v2 >> 8) & 0xFF  # sh
            elif funct3 == "010":
                self.mem[addr] = v2 & 0xFF  # sw
                self.mem[addr + 1] = (v2 >> 8) & 0xFF  # sw
                self.mem[addr + 2] = (v2 >> 16) & 0xFF  # sw
                self.mem[addr + 3] = (v2 >> 24) & 0xFF  # sw

        elif opcode == "1100011":  # Branches
            taken = False
            if funct3 == "000":
                taken = v1 == v2  # beq
            if funct3 == "001":
                taken = v1 != v2  # bne
            if funct3 == "100":
                taken = s32(v1) < s32(v2)  # blt
            if funct3 == "101":
                taken = s32(v1) >= s32(v2)  # bge
            if funct3 == "110":
                taken = u32(v1) < u32(v2)  # bltu
            if funct3 == "111":
                taken = u32(v1) >= u32(v2)  # bgeu
            if taken:
                next_pc = self.pc + imm_b

        elif opcode == "0110111":  # lui
            write_reg = True
            result = imm_u

        elif opcode == "0010111":  # auipc
            write_reg = True
            result = self.pc + imm_u

        elif opcode == "1101111":  # jal
            write_reg = True
            result = self.pc + 4
            next_pc = self.pc + imm_j

        elif opcode == "1100111":  # jalr
            write_reg = True
            result = self.pc + 4
            next_pc = (v1 + imm_i) & ~1

        if write_reg and int(rd, 2) != 0:
            self.regs[int(rd, 2)] = u32(result)

        self.pc = u32(next_pc)

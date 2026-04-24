from constants import Opcode
import numpy as np
import subprocess
import re

class Memory:
    def __init__(self):
        self.data = np.zeros((1024, 1024), dtype=np.uint16)
        self.size = 1024* 1024* 2 #total bytes

    def decode(self, address):
        if address < 0 or address >= self.data.size:
            raise IndexError(f"Address out of range: 0x{address:X}")
        
        row = (address >> 10) & 0x3FF
        col = address & 0x3FF

        return row, col

    def read_byte(self,virtual_address):
        real_address = virtual_address // 2

        if virtual_address %2:
            out = (self.read_half_word(real_address,UB=0,LB=1) >> 8) & 0xFF
        else:
            out = self.read_half_word(real_address,UB=1,LB=0) & 0xFF

        return out 

    def write_byte(self,virtual_address,DQ):
        real_address = virtual_address // 2
        byte = int(DQ) & 0xFF

        if virtual_address % 2:  #odd
            out = self.write_half_word(real_address,byte << 8,UB=0,LB=1)
        else: #even
            out = self.write_half_word(real_address,byte,UB=1,LB=0) 
        
        return out 

    def read_half_word(self,address,CE=0,OE=0,WE=1,UB=0,LB=0):
        # CE=0 chip enabled, OE=0 output enabled, WE=1 read cycle.
        if CE == 1 or OE == 1 or WE == 0:
            return None

        row, col = self.decode(address)
        value = int(self.data[row, col])

        out = 0
        if LB == 0:
            out |= value & 0x00FF
        if UB == 0:
            out |= (value & 0xFF00 ) 

        # If both byte lanes are disabled, bus is effectively Hi-Z.
        if UB == 1 and LB == 1:
            return None
        return out

    def write_half_word(self,address,DQ=0,CE=0,OE=0,WE=0,UB=0,LB=0):
        if CE == 1 or WE == 1:
            return

        row, col = self.decode(address)
        cur = int(self.data[row, col])
        dq = int(DQ) & 0xFFFF

        if LB == 0:
            cur = (cur & 0xFF00) | (dq & 0x00FF)
        if UB == 0:
            cur = (cur & 0x00FF) | (dq & 0xFF00)

        self.data[row, col] = np.uint16(cur)

    def read_word(self,address,CE=0,OE=0,WE=1,UB=0,LB=0):
        real_address = address // 2
        LSB = self.read_half_word(real_address)
        MSB = self.read_half_word(real_address+1)
        return (MSB<<16) | LSB
    
    def write_word(self,address,DQ=0,CE=0,OE=0,WE=0,UB=0,LB=0):  
        real_address = address // 2
        self.write_half_word(real_address, DQ & 0xFFFF)
        self.write_half_word(real_address+1, (DQ>>16) & 0xFFFF)
    
class CPU:
    def __init__(self):
        self.regs = [0] * 32  # x0–x31, x0 hard zero, x1 return address, x2 stack pointer
        
        self.instructions = []

        result = subprocess.run(["./build_rv32i.sh"],
            capture_output=True, text=True, check=True)
        
        pattern = re.compile(r'^\s+([0-9a-f]+):\s+([0-9a-f]+)\s+(.+)$')

        with open("./instructions.txt",'r') as file:
            for line in file:
                m = pattern.match(line)
                if m:
                    self.instructions.append({
                        "addr": int(m.group(1), 16),
                        "encoding": int(m.group(2), 16),
                        "asm": m.group(3).strip()
                    })

        self.instruction_by_addr = {inst["addr"]: inst for inst in self.instructions}

        for inst in self.instructions:
            memory.write_byte(inst["addr"],inst["encoding"] & 0xFF)
            memory.write_byte(inst["addr"]+1,(inst["encoding"]>>8) & 0xFF)
            memory.write_byte(inst["addr"]+2,(inst["encoding"]>>16) & 0xFF)
            memory.write_byte(inst["addr"]+3,(inst["encoding"]>>24) & 0xFF)
        
        self.PC =  self.instructions[0]['addr'] 

    
    def get_opcode(self, instr):
        value = instr & 0x7F
        print(f"  get_opcode -> 0x{value:02X} ({value:07b})")
        return value

    def get_rd(self, instr):
        value = (instr >> 7) & 0x1F
        print(f"  get_rd     -> x{value} ({value:05b})")
        return value

    def get_funct3(self, instr):
        value = (instr >> 12) & 0x07
        print(f"  get_funct3 -> {value:03b}")
        return value

    def get_rs1(self, instr):
        value = (instr >> 15) & 0x1F
        print(f"  get_rs1    -> x{value} ({value:05b})")
        return value

    def get_rs2(self, instr):
        value = (instr >> 20) & 0x1F
        print(f"  get_rs2    -> x{value} ({value:05b})")
        return value

    def get_funct7(self, instr):
        value = (instr >> 25) & 0x7F
        print(f"  get_funct7 -> {value:07b}")
        return value

    @staticmethod
    def sign_extend(value, bits):
        sign_bit = 1 << (bits - 1)
        return (value ^ sign_bit) - sign_bit

    @staticmethod
    def u32(value):
        return value & 0xFFFFFFFF

    @staticmethod
    def s32(value):
        value &= 0xFFFFFFFF
        return value - 0x100000000 if value & 0x80000000 else value
    
    def alu_calc(self, in1, in2,op):
        in1_u = self.u32(in1)
        in2_u = self.u32(in2)
        shamt = in2_u & 0x1F
        out=0
        match op:
            case Opcode.ALU_ADD: out = self.u32(in1_u + in2_u)
            case Opcode.ALU_SLL : out = self.u32(in1_u << shamt)
            case Opcode.ALU_XOR : out = self.u32(in1_u ^ in2_u)
            case Opcode.ALU_OR : out = self.u32(in1_u | in2_u)
            case Opcode.ALU_AND : out = self.u32(in1_u & in2_u)
            case Opcode.ALU_SRL : out = self.u32(in1_u >> shamt)
            case Opcode.ALU_SUB : out = self.u32(in1_u - in2_u)
            case Opcode.ALU_SRA : out = self.u32(self.s32(in1_u) >> shamt)
            case Opcode.ALU_SLT : out = 1 if self.s32(in1_u) < self.s32(in2_u) else 0
            case Opcode.ALU_SLTU : out = 1 if in1_u < in2_u else 0
            case _:
                raise ValueError(f"Unsupported ALU op: {op}")

        return out 

    def execute(self):
        while True:
            instruction = memory.read_byte(self.PC) | memory.read_byte(self.PC+1)<< 8 | memory.read_byte(self.PC+2) <<16 | memory.read_byte(self.PC+3) << 24
            inst_meta = self.instruction_by_addr.get(self.PC)
            asm_text = inst_meta["asm"] if inst_meta else "<unknown>"
            print(f"PC= 0x{self.PC:08X} INSTR= 0x{instruction:08X} ASM= {asm_text}")
            opcode = self.get_opcode(instruction)
            
            match opcode:
                case Opcode.R:
                    rd     = self.get_rd(instruction)
                    funct3 = self.get_funct3(instruction)
                    rs1    = self.get_rs1(instruction)
                    rs2    = self.get_rs2(instruction)
                    funct7 = self.get_funct7(instruction)

                    in1 = self.regs[rs1]
                    in2 = self.regs[rs2]

                    match funct3:
                        case 0b000:
                            if funct7 == 0b0000000:
                                alu_op = Opcode.ALU_ADD
                            elif funct7 == 0b0100000:
                                alu_op = Opcode.ALU_SUB
                        case 0b001:
                            alu_op = Opcode.ALU_SLL
                        case 0b010:
                            alu_op = Opcode.ALU_SLT
                        case 0b011:
                            alu_op = Opcode.ALU_SLTU
                        case 0b100:
                            alu_op = Opcode.ALU_XOR
                        case 0b101:
                            if funct7 == 0b0000000:
                                alu_op = Opcode.ALU_SRL
                            elif funct7 == 0b0100000:
                                alu_op = Opcode.ALU_SRA
                        case 0b110:
                            alu_op = Opcode.ALU_OR
                        case 0b111:
                            alu_op = Opcode.ALU_AND
                        case _:
                            raise ValueError(f"Unsupported R-type funct3: {funct3:03b}")

                    res = self.alu_calc(in1, in2, alu_op)

                    self.regs[rd] = self.u32(res)
                    self.PC = self.u32(self.PC + 4)

                case Opcode.I:
                    rd = self.get_rd(instruction)
                    funct3 = self.get_funct3(instruction)
                    rs1 = self.get_rs1(instruction)
                    
                    in1 = self.regs[rs1]

                    if funct3 == 0b001:  # SLLI
                        in2 = (instruction >> 20) & 0x1F
                        alu_op = Opcode.ALU_SLL
                    elif funct3 == 0b101:  # SRLI / SRAI
                        in2 = (instruction >> 20) & 0x1F
                        bit30 = (instruction >> 30) & 1
                        if bit30 == 1:
                            alu_op = Opcode.ALU_SRA
                        else:
                            alu_op = Opcode.ALU_SRL
                    else:
                        imm12 = (instruction >> 20) & 0xFFF
                        in2 = self.sign_extend(imm12, 12)
                        match funct3:
                            case 0b000: alu_op = Opcode.ALU_ADD
                            case 0b010: alu_op = Opcode.ALU_SLT
                            case 0b011: alu_op = Opcode.ALU_SLTU
                            case 0b100: alu_op = Opcode.ALU_XOR
                            case 0b110: alu_op = Opcode.ALU_OR
                            case 0b111: alu_op = Opcode.ALU_AND
                            case _:
                                raise ValueError(f"Unsupported I-type funct3: {funct3:03b}")

                    out = self.alu_calc(in1, in2, alu_op)
                    self.regs[rd] = self.u32(out)
                    self.PC = self.u32(self.PC + 4)

                case Opcode.L:      # loads are also I-type encoding
                    rd     = self.get_rd(instruction)
                    funct3 = self.get_funct3(instruction)
                    rs1    = self.get_rs1(instruction)
                    imm12 = (instruction >> 20) & 0xFFF
                    imm = self.sign_extend(imm12, 12)

                    base_address = self.regs[rs1]
                    address = (base_address + imm) & 0xFFFFFFFF

                    match funct3:
                        case 0b000:
                            # LB
                            mem_byte_val = memory.read_byte(address)
                            mem_val = self.sign_extend(mem_byte_val, 8)
                            self.regs[rd] = mem_val & 0xFFFFFFFF

                        case 0b001:
                            # LH
                            mem_hex_val = memory.read_half_word(address // 2)
                            mem_val = self.sign_extend(mem_hex_val, 16)
                            self.regs[rd] = mem_val & 0xFFFFFFFF

                        case 0b010:
                            # LW
                            mem_val = memory.read_word(address)
                            self.regs[rd] = mem_val & 0xFFFFFFFF

                        case 0b100:
                            # LBU
                            mem_val = memory.read_byte(address)
                            self.regs[rd] = mem_val & 0xFF

                        case 0b101:
                            # LHU
                            mem_val = memory.read_half_word(address // 2)
                            self.regs[rd] = mem_val & 0xFFFF

                        case _:
                            raise ValueError(f"CPU Load: illegal funct3 {funct3:03b}")
                        
                    self.PC = self.u32(self.PC + 4)
        
        
                case Opcode.S:
                    funct3 = self.get_funct3(instruction)
                    rs1    = self.get_rs1(instruction)
                    rs2    = self.get_rs2(instruction)
                    imm = self.sign_extend((self.get_funct7(instruction) << 5) | self.get_rd(instruction), 12)

                    base_address = self.regs[rs1]
                    src_val = self.regs[rs2] & 0xFFFFFFFF
                    address = (base_address + imm) & 0xFFFFFFFF

                    match funct3:
                        case 0:
                            # SB
                            src_byte_val = src_val & 0xFF
                            word_address = address >> 1
                            if (address & 1) == 0:
                                memory.write_half_word(word_address, DQ=src_byte_val, CE=0, OE=1, WE=0, UB=1, LB=0)
                            else:
                                memory.write_half_word(word_address, DQ=(src_byte_val << 8), CE=0, OE=1, WE=0, UB=0, LB=1)

                        case 1:
                            # SH
                            src_hex_val = src_val & 0xFFFF
                            address_low = address & 0xFFFFFFFF
                            address_high = (address + 1) & 0xFFFFFFFF

                            low_byte = src_hex_val & 0xFF
                            high_byte = (src_hex_val >> 8) & 0xFF

                            low_word_addr = address_low >> 1
                            if (address_low & 1) == 0:
                                memory.write_half_word(low_word_addr, DQ=low_byte, CE=0, OE=1, WE=0, UB=1, LB=0)
                            else:
                                memory.write_half_word(low_word_addr, DQ=(low_byte << 8), CE=0, OE=1, WE=0, UB=0, LB=1)

                            high_word_addr = address_high >> 1
                            if (address_high & 1) == 0:
                                memory.write_half_word(high_word_addr, DQ=high_byte, CE=0, OE=1, WE=0, UB=1, LB=0)
                            else:
                                memory.write_half_word(high_word_addr, DQ=(high_byte << 8), CE=0, OE=1, WE=0, UB=0, LB=1)

                        case 2:
                            # SW
                            memory.write_word(address, DQ=src_val, CE=0, OE=1, WE=0, UB=0, LB=0)

                        case _:
                            raise ValueError(f"CPU Save: illegal funct3 {funct3:03b}")
                    self.PC = self.u32(self.PC + 4)

                case Opcode.B:
                    funct3 = self.get_funct3(instruction)
                    rs1    = self.get_rs1(instruction)
                    rs2    = self.get_rs2(instruction)
                    imm = self.sign_extend((((self.get_funct7(instruction) & 0b01000000) << 6) | ((self.get_rd(instruction) & 0b00000001) << 11) | ((self.get_funct7(instruction) & 0b00111111) << 5) | (self.get_rd(instruction) & 0b00011110)), 13)

                    rs1_val_u = self.regs[rs1] & 0xFFFFFFFF
                    rs2_val_u = self.regs[rs2] & 0xFFFFFFFF
                    rs1_val_s = self.sign_extend(rs1_val_u, 32)
                    rs2_val_s = self.sign_extend(rs2_val_u, 32)

                    take_branch = False
                    
                    match funct3:
                        case 0b000: # beq
                            take_branch = (rs1_val_u == rs2_val_u)

                        case 0b001: # bne
                            take_branch = (rs1_val_u != rs2_val_u)

                        case 0b100: # blt
                            take_branch = (rs1_val_s < rs2_val_s)

                        case 0b101: # bge
                            take_branch = (rs1_val_s >= rs2_val_s)

                        case 0b110: # bltu
                            take_branch = (rs1_val_u < rs2_val_u)

                        case 0b111: # bgeu
                            take_branch = (rs1_val_u >= rs2_val_u)

                        case _:
                            raise ValueError(f"CPU Branch: illegal funct3 {funct3:03b}")

                    if take_branch:
                        self.PC = (self.PC + imm) & 0xFFFFFFFF
                    else:
                        self.PC = self.u32(self.PC + 4)

                case Opcode.JAL:
                    rd = self.get_rd(instruction)

                    offset20 = (instruction & 0x80000000) >> 11
                    offset10to1 = (instruction & 0b01111111111000000000000000000000) >> 20
                    offset11 = (instruction & 0b00000000000100000000000000000000) >> 9
                    offset19to12 = (instruction & 0b00000000000011111111000000000000)
                    offset = offset20 | offset19to12 | offset11 | offset10to1
                    offset = self.sign_extend(offset, 21)

                    self.regs[rd] = (self.PC + 4) & 0xFFFFFFFF
                    self.PC = (self.PC + offset) & 0xFFFFFFFF

                case Opcode.JALR:
                    rd = self.get_rd(instruction)
                    rs1 = self.get_rs1(instruction)

                    imm = (instruction >> 20) & 0xFFF
                    imm = self.sign_extend(imm, 12)

                    rs1_val = self.regs[rs1] & 0xFFFFFFFF
                    target = (rs1_val + imm) & 0xFFFFFFFF
                    target = target & 0xFFFFFFFE

                    self.regs[rd] = (self.PC + 4) & 0xFFFFFFFF
                    self.PC = target

                case Opcode.LUI:
                    rd     = self.get_rd(instruction)
                    self.regs[rd] = instruction & 0xFFFFF000
                    self.PC = self.u32(self.PC + 4)

                case Opcode.AUIPC:
                    rd = self.get_rd(instruction)
                    imm = instruction & 0xFFFFF000
                    self.regs[rd] = self.u32(self.PC + imm)
                    self.PC = self.u32(self.PC + 4)

                # case _:
                #     raise ValueError(f"Unknown opcode: {opcode:#09b} at PC={self.PC - 4}")
            
            self.regs[0] = 0


memory = Memory()
cpu = CPU()

cpu.execute()
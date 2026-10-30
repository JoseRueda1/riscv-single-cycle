#!/usr/bin/env python3
"""Mini ensamblador RV32I + simulador de referencia (ISS) + generador de imem.sv y expected.svh"""
import sys
M32 = 0xFFFFFFFF
REGS = {f"x{i}": i for i in range(32)}

def sx(v, bits): v &= (1 << bits) - 1; return v - (1 << bits) if v >> (bits-1) else v
def enc_r(f7,rs2,rs1,f3,rd,op): return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def enc_i(imm,rs1,f3,rd,op): return ((imm&0xFFF)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def enc_s(imm,rs2,rs1,f3,op): imm&=0xFFF; return ((imm>>5)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&0x1F)<<7)|op
def enc_b(imm,rs2,rs1,f3,op):
    imm&=0x1FFF
    return (((imm>>12)&1)<<31)|(((imm>>5)&0x3F)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(((imm>>1)&0xF)<<8)|(((imm>>11)&1)<<7)|op
def enc_u(imm,rd,op): return ((imm&0xFFFFF)<<12)|(rd<<7)|op
def enc_j(imm,rd,op):
    imm&=0x1FFFFF
    return (((imm>>20)&1)<<31)|(((imm>>1)&0x3FF)<<21)|(((imm>>11)&1)<<20)|(((imm>>12)&0xFF)<<12)|(rd<<7)|op

R = {'add':(0,0),'sub':(0x20,0),'slt':(0,2),'or':(0,6),'and':(0,7)}
I = {'addi':0}
SH = {}
LD = {'lw':2}
ST = {'sw':2}
B = {'beq':0}

def assemble(lines):
    labels, prog, pc = {}, [], 0
    for ln in lines:
        ln = ln.split('#')[0].strip()
        if not ln: continue
        while ':' in ln:
            l, ln = ln.split(':',1); labels[l.strip()] = pc; ln = ln.strip()
        if ln: prog.append((pc, ln)); pc += 4
    words = []
    r = lambda s: REGS[s.strip()]
    for pc, ln in prog:
        op, _, rest = ln.partition(' ')
        a = [x.strip() for x in rest.split(',')] if rest else []
        tgt = lambda s: (labels[s]-pc) if s in labels else int(s,0)
        if op in R: f7,f3=R[op]; w=enc_r(f7,r(a[2]),r(a[1]),f3,r(a[0]),0x33)
        elif op in I: w=enc_i(int(a[2],0),r(a[1]),I[op],r(a[0]),0x13)
        elif op in SH: f7,f3=SH[op]; w=enc_i((f7<<5)|int(a[2],0),r(a[1]),f3,r(a[0]),0x13)
        elif op in LD: off,rb=a[1].split('('); w=enc_i(int(off,0),r(rb[:-1]),LD[op],r(a[0]),0x03)
        elif op in ST: off,rb=a[1].split('('); w=enc_s(int(off,0),r(a[0]),r(rb[:-1]),ST[op],0x23)
        elif op in B: w=enc_b(tgt(a[2]),r(a[1]),r(a[0]),B[op],0x63)
        elif op=='jal': w=enc_j(tgt(a[1]),r(a[0]),0x6F)
        else: raise ValueError(ln)
        words.append(w & M32)
    return words, labels

def iss(words, dwords, max_steps=5000):
    x=[0]*32; mb=bytearray(dwords*4); pc=0; steps=0
    while steps<max_steps:
        i=words[pc//4]; op=i&0x7F; rd=(i>>7)&31; f3=(i>>12)&7; rs1=(i>>15)&31; rs2=(i>>20)&31; f7=i>>25
        a,b=x[rs1],x[rs2]; npc=pc+4; wb=None
        if op==0x33:
            if (f7,f3)==(0,0): wb=a+b
            elif (f7,f3)==(0x20,0): wb=a-b
            elif f3==1: wb=a<<(b&31)
            elif f3==2: wb=int(sx(a,32)<sx(b,32))
            elif f3==3: wb=int(a<b)
            elif f3==4: wb=a^b
            elif f3==5: wb=(a>>(b&31)) if f7==0 else (sx(a,32)>>(b&31))
            elif f3==6: wb=a|b
            elif f3==7: wb=a&b
        elif op==0x13:
            im=sx(i>>20,12); sh=(i>>20)&31
            if f3==0: wb=a+im
            elif f3==2: wb=int(sx(a,32)<im)
            elif f3==3: wb=int(a<(im&M32))
            elif f3==4: wb=a^(im&M32)
            elif f3==6: wb=a|(im&M32)
            elif f3==7: wb=a&(im&M32)
            elif f3==1: wb=a<<sh
            elif f3==5: wb=(a>>sh) if (i>>30)&1==0 else (sx(a,32)>>sh)
        elif op==0x03:
            ad=((a+sx(i>>20,12))&M32)%(dwords*4)
            if f3==2: wb=int.from_bytes(mb[ad&~3:(ad&~3)+4],'little')
            elif f3 in (0,4): v=mb[ad]; wb=(sx(v,8) if f3==0 else v)
            elif f3 in (1,5): v=int.from_bytes(mb[ad&~1:(ad&~1)+2],'little'); wb=(sx(v,16) if f3==1 else v)
        elif op==0x23:
            im=sx(((i>>25)<<5)|((i>>7)&31),12); ad=((a+im)&M32)%(dwords*4)
            if f3==2: mb[ad&~3:(ad&~3)+4]=(b&M32).to_bytes(4,'little')
            elif f3==1: mb[ad&~1:(ad&~1)+2]=(b&0xFFFF).to_bytes(2,'little')
            else: mb[ad]=b&0xFF
        elif op==0x63:
            im=sx((((i>>31)&1)<<12)|(((i>>7)&1)<<11)|(((i>>25)&0x3F)<<5)|(((i>>8)&0xF)<<1),13)
            t={0:a==b,1:a!=b,4:sx(a,32)<sx(b,32),5:sx(a,32)>=sx(b,32),6:a<b,7:a>=b}[f3]
            if t: npc=pc+im
        elif op==0x6F:
            im=sx((((i>>31)&1)<<20)|(((i>>12)&0xFF)<<12)|(((i>>20)&1)<<11)|(((i>>21)&0x3FF)<<1),21)
            wb=pc+4; npc=pc+im
        elif op==0x67: wb=pc+4; npc=(a+sx(i>>20,12))&~1
        elif op==0x37: wb=i&0xFFFFF000
        elif op==0x17: wb=pc+(i&0xFFFFF000)
        if wb is not None and rd: x[rd]=wb&M32
        steps+=1
        if npc==pc: return x,[int.from_bytes(mb[k:k+4],'little') for k in range(0,dwords*4,4)],pc,steps          # bucle infinito = fin
        pc=npc&M32
    raise RuntimeError("sin fin")

PROGRAM = """
  addi x1, x0, 10
  addi x2, x0, 5
  add  x3, x1, x2        # 15
  sub  x4, x1, x2        # 5
  and  x5, x1, x2        # 0
  or   x6, x1, x2        # 15
  slt  x7, x2, x1        # 1
  slt  x8, x1, x2        # 0
  addi x9, x0, -3
  slt  x10, x9, x1       # 1 (con signo)
  sub  x11, x2, x1       # -5
  sw   x3, 0(x0)
  sw   x4, 4(x0)
  lw   x12, 0(x0)        # 15
  lw   x13, 4(x0)        # 5
  addi x30, x0, 0
  addi x31, x0, 0
  beq  x1, x1, L1        # se toma
  addi x30, x30, 100
L1: addi x30, x30, 1
  beq  x1, x2, BAD       # no se toma
  addi x30, x30, 2
  beq  x4, x2, L2        # se toma (5 == 5)
  addi x30, x30, 100
L2: addi x30, x30, 4
  jal  x26, T1           # salto con enlace
  addi x31, x31, 100     # se salta
T1: addi x31, x31, 7
  jal  x0, LOOP
BAD: addi x30, x0, -1
  jal  x0, BAD
LOOP: addi x27, x0, 0    # suma 10+9+...+1
  addi x28, x0, 10
SUM: beq x28, x0, DONE
  add  x27, x27, x28
  addi x28, x28, -1
  jal  x0, SUM
DONE: sw x27, 8(x0)      # 55
  lw   x29, 8(x0)
  sw   x30, 12(x0)
END: jal x0, END
"""

if __name__ == "__main__":
    DW = 16
    words, labels = assemble(PROGRAM.splitlines())
    x, dm, endpc, steps = iss(words, DW)
    assert x[3]==15 and x[4]==5 and x[5]==0 and x[6]==15 and x[7]==1 and x[8]==0 and x[10]==1 and x[11]==M32-4
    assert x[12]==15 and x[13]==5 and x[27]==55 and x[29]==55 and dm[2]==55 and x[31]==7 and x[30]==7 and dm[3]==7
    assert x[26]==104 and x[0]==0
    # imem.sv (ROM sintetizable)
    n = len(words)
    with open("imem.sv","w") as f:
        f.write("// ROM de instrucciones (generada por gen_program.py). Programa de prueba RV32I.\n")
        f.write("module imem (\n    input  logic [31:0] addr,\n    output logic [31:0] instr\n);\n")
        f.write("    always_comb begin\n        case (addr[31:2])\n")
        for k,w in enumerate(words): f.write(f"            30'd{k}: instr = 32'h{w:08x};\n")
        f.write("            default: instr = 32'h00000013; // NOP\n        endcase\n    end\nendmodule\n")
    with open("expected.svh","w") as f:
        f.write(f"localparam int END_PC = {endpc};\nlogic [31:0] EXP_REG [0:31];\nlogic [31:0] EXP_MEM [0:{DW-1}];\ninitial begin\n")
        for i in range(32): f.write(f"    EXP_REG[{i}] = 32'h{x[i]:08x};\n")
        for i in range(DW): f.write(f"    EXP_MEM[{i}] = 32'h{dm[i]:08x};\n")
        f.write("end\n")
    with open("program.hex","w") as f:
        for w in words: f.write(f"{w:08x}\n")
    print(f"{n} instrucciones, END_PC={endpc}, pasos ISS={steps}")
    print("regs:", " ".join(f"x{i}={x[i]:#x}" for i in range(32) if x[i]))
    print("dmem:", [hex(v) for v in dm[:4]])

from pathlib import Path
P=Path(__file__).resolve().parent
def I(imm,rs1,f3,rd,op=0x13):return ((imm&4095)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def R(f7,rs2,rs1,f3,rd):return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|0x33
def S(imm,rs2,rs1,f3):return ((imm>>5&127)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&31)<<7)|0x23
def B(imm,rs2,rs1,f3):return ((imm>>12&1)<<31)|((imm>>5&63)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm>>1&15)<<8)|((imm>>11&1)<<7)|0x63
EBREAK=0x00100073
# sum 1..10: x10 accumulator, x1 counter, x2 limit 11
sum_prog=[I(0,0,0,10),I(1,0,0,1),I(11,0,0,2),R(0,1,10,0,10),I(1,1,0,1),B(-8,2,1,4),EBREAK]
# Fibonacci F(10)=55, x1=0 x2=1 x3=10; x4 counter
fib=[I(0,0,0,1),I(1,0,0,2),I(10,0,0,3),I(0,0,0,4),R(0,2,1,0,5),I(0,2,0,1),I(0,5,0,2),I(1,4,0,4),B(-16,3,4,4),I(0,1,0,10),EBREAK]
# byte, halfword and word roundtrips at aligned addresses
mem=[I(123,0,0,1),S(0,1,0,2),I(0,0,2,10,0x03),S(4,10,0,1),I(4,0,1,6,0x03),S(6,6,0,0),I(6,0,4,7,0x03),EBREAK]
for name,prog in [('sum',sum_prog),('fibonacci',fib),('loadstore',mem)]:
 (P/f'{name}.hex').write_text(''.join(f'{x:08x}\n' for x in prog))
 print(name,len(prog),[f'{x:08x}' for x in prog])

module rv32i_core(input clk,input reset,output reg [31:0] pc,output reg [31:0] debug_result,output reg halted,output reg fault);
reg [31:0] regs[0:31]; reg [31:0] imem[0:255]; reg [7:0] dmem[0:1023];
integer i; initial begin for(i=0;i<256;i=i+1) imem[i]=32'h00000013; for(i=0;i<1024;i=i+1)dmem[i]=0; for(i=0;i<32;i=i+1)regs[i]=0; end
wire [31:0] ins=imem[pc[9:2]]; wire [6:0] op=ins[6:0]; wire [4:0] rd=ins[11:7],rs1=ins[19:15],rs2=ins[24:20]; wire [2:0] f3=ins[14:12]; wire [6:0] f7=ins[31:25];
wire [31:0] a=regs[rs1],b=regs[rs2]; wire [31:0] imm_i={{20{ins[31]}},ins[31:20]}; wire [31:0] imm_s={{20{ins[31]}},ins[31:25],ins[11:7]}; wire [31:0] imm_b={{19{ins[31]}},ins[31],ins[7],ins[30:25],ins[11:8],1'b0}; wire [31:0] imm_u={ins[31:12],12'b0}; wire [31:0] imm_j={{11{ins[31]}},ins[31],ins[19:12],ins[20],ins[30:21],1'b0};
reg [31:0] nextpc, val,addr,ld; reg wr,st,illegal; reg [3:0] mask; integer k;
always @* begin
nextpc=pc+4;val=0;addr=0;ld=0;wr=0;st=0;illegal=0;mask=0;
case(op)
7'h37:begin wr=1;val=imm_u;end
7'h17:begin wr=1;val=pc+imm_u;end
7'h6f:begin wr=1;val=pc+4;nextpc=pc+imm_j;end
7'h67:begin wr=1;val=pc+4;nextpc=(a+imm_i)&32'hfffffffe;if(f3!=0)illegal=1;end
7'h63:begin case(f3)
0:if(a==b)nextpc=pc+imm_b;1:if(a!=b)nextpc=pc+imm_b;4:if($signed(a)<$signed(b))nextpc=pc+imm_b;5:if($signed(a)>=$signed(b))nextpc=pc+imm_b;6:if(a<b)nextpc=pc+imm_b;7:if(a>=b)nextpc=pc+imm_b;default:illegal=1;endcase end
7'h13:begin wr=1;case(f3)
0:val=a+imm_i;2:val=($signed(a)<$signed(imm_i));3:val=(a<imm_i);4:val=a^imm_i;6:val=a|imm_i;7:val=a&imm_i;1:begin val=a<<ins[24:20];if(f7!=0)illegal=1;end
5:begin if(f7==0)val=a>>ins[24:20];else if(f7==7'h20)val=$signed(a)>>>ins[24:20];else illegal=1;end default:illegal=1;endcase end
7'h33:begin wr=1;case(f3)
0:begin if(f7==0)val=a+b;else if(f7==7'h20)val=a-b;else illegal=1;end
1:begin val=a<<b[4:0];if(f7!=0)illegal=1;end
2:begin val=($signed(a)<$signed(b));if(f7!=0)illegal=1;end
3:begin val=(a<b);if(f7!=0)illegal=1;end
4:begin val=a^b;if(f7!=0)illegal=1;end
5:begin if(f7==0)val=a>>b[4:0];else if(f7==7'h20)val=$signed(a)>>>b[4:0];else illegal=1;end
6:begin val=a|b;if(f7!=0)illegal=1;end
7:begin val=a&b;if(f7!=0)illegal=1;end default:illegal=1;endcase end
7'h03:begin wr=1;addr=a+imm_i;if(addr>=1024)illegal=1;else begin
case(f3)
0:ld={{24{dmem[addr][7]}},dmem[addr]};
1:if(addr[0])illegal=1;else ld={{16{dmem[addr+1][7]}},dmem[addr+1],dmem[addr]};
2:if(|addr[1:0])illegal=1;else ld={dmem[addr+3],dmem[addr+2],dmem[addr+1],dmem[addr]};
4:ld={24'b0,dmem[addr]};
5:if(addr[0])illegal=1;else ld={16'b0,dmem[addr+1],dmem[addr]};default:illegal=1;endcase end val=ld;end
7'h23:begin st=1;addr=a+imm_s;if(addr>=1024)illegal=1;else case(f3)
0:mask=4'b0001;
1:begin mask=4'b0011;if(addr[0])illegal=1;end
2:begin mask=4'b1111;if(|addr[1:0])illegal=1;end
default:illegal=1;endcase end
7'h73:begin if(ins!=32'h00100073)illegal=1;end
7'h0f:begin if(f3!=0)illegal=1;end
 default:illegal=1;
endcase
if(nextpc[1:0]!=0 || nextpc>=1024)illegal=1;
end
always @(posedge clk) begin
if(reset)begin pc<=0;halted<=0;fault<=0;debug_result<=0;for(k=0;k<32;k=k+1)regs[k]<=0;end
else if(!halted && !fault)begin
if(illegal)begin fault<=1;$display("FAULT pc=%h ins=%h",pc,ins);end
else if(ins==32'h00100073)begin halted<=1;debug_result<=regs[10];end
else begin pc<=nextpc;if(wr && rd!=0)regs[rd]<=val;if(st)begin dmem[addr]<=b[7:0];if(mask[1])dmem[addr+1]<=b[15:8];if(mask[2])dmem[addr+2]<=b[23:16];if(mask[3])dmem[addr+3]<=b[31:24];end end
end
end
endmodule

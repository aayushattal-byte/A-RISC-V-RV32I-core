`timescale 1ns/1ps
module tb_rv32i;
reg clk=0,reset=1;wire [31:0] pc,debug_result;wire halted,fault;
rv32i_core dut(.clk(clk),.reset(reset),.pc(pc),.debug_result(debug_result),.halted(halted),.fault(fault));
always #5 clk=~clk;
integer test,cycles,j,errors=0;reg [31:0] expected;
initial begin
$dumpfile("results/rv32i.vcd");$dumpvars(0,tb_rv32i);
for(test=0;test<3;test=test+1)begin
reset=1;@(negedge clk);
for(j=0;j<256;j=j+1)dut.imem[j]=32'h00000013;
for(j=0;j<1024;j=j+1)dut.dmem[j]=0;
case(test)
0:begin $readmemh("programs/sum.hex",dut.imem);expected=55;end
1:begin $readmemh("programs/fibonacci.hex",dut.imem);expected=55;end
2:begin $readmemh("programs/loadstore.hex",dut.imem);expected=123;end
endcase
@(negedge clk);reset=0;cycles=0;
while(!halted && !fault && cycles<300)begin @(negedge clk);cycles=cycles+1;end
if(fault || !halted || debug_result!==expected)begin $display("FAIL test=%0d expected=%0d actual=%0d pc=%h fault=%b",test,expected,debug_result,pc,fault);errors=errors+1;end
else $display("PASS test=%0d result=%0d cycles=%0d",test,debug_result,cycles);
end
if(errors==0)$display("ALL TESTS PASSED");else $fatal(1,"%0d tests failed",errors);
$finish;
end
endmodule

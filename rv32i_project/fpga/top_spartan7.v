module top_spartan7(input clk,input rst_btn,output [7:0] led);
wire [31:0] pc,result;wire halted,fault;
reg [24:0] div=0;reg slow_clk=0;
always @(posedge clk)begin if(div==25'd24999999)begin div<=0;slow_clk<=~slow_clk;end else div<=div+1;end
rv32i_core core(.clk(slow_clk),.reset(rst_btn),.pc(pc),.debug_result(result),.halted(halted),.fault(fault));
assign led= fault?8'hff:(halted?result[7:0]:pc[9:2]);
initial $readmemh("programs/sum.hex",core.imem);
endmodule

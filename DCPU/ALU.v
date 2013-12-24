`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:20:49 12/12/2013 
// Design Name: 
// Module Name:    ALU 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ALU(
  input  wire[3:0]  OPC,  // Operation Code
  input  wire[15:0] IN1,  // Input 1
  input  wire[15:0] IN2,  // Input 2
  input  wire       ICF,  // Input Carry Flag
  output wire[15:0] OUT,  // Output
  output reg        OCF,  // Output Carry Flag
  output wire       OZF,  // Output Zero Flag
  output wire       ONF   // Output Negative Flag
);
  
  reg [15:0] ROUT;
  wire[15:0] ShiftMark; assign ShiftMark = 16'hFFFF;
  
  // OUTPUT : OZF
  assign OZF = (OUT == 16'b0);
  
  // OUTPUT : ONF
  assign ONF = (OPC[3]) ? (1'b0) : (OUT[15]);
  
  // OUTPUT : OUT, OCF
  assign OUT = (OPC==4'b0111) ? (16'b0) : (ROUT);
  always @(*) case(OPC)
      4'b0000:begin // Mnomonic: ADD
                {OCF,ROUT}  = IN1+IN2;
              end
      4'b0001:begin // Mnomonic: ADDI
                {OCF,ROUT}  = IN1+IN2;
              end
      4'b0010:begin // Mnomonic: ADDC
                {OCF,ROUT}  = IN1+IN2+ICF;
              end
      4'b0011:begin // Mnomonic: SUB
                ROUT        = IN1-IN2;
                OCF         = 0;
              end
      4'b0100:begin // Mnomonic: SUBI
                ROUT        = IN1-IN2;
                OCF         = 0;
               end
      4'b0101:begin // Mnomonic: SUBC
                ROUT        = IN1-IN2-ICF;
                OCF         = 0;
              end
      4'b0110:begin // Mnomonic: INC
                {OCF,ROUT}  = IN1+1;
              end
      4'b0111:begin // Mnomonic: CMP
                ROUT        = IN1-IN2;
                OCF         = 0;
              end
      4'b1000:begin // Mnomonic: TRAN
                ROUT        = IN1;
                OCF         = 0;
              end
      4'b1001:begin // Mnomonic: XOR
                ROUT        = IN1^IN2;
                OCF         = 0;
              end
      4'b1010:begin // Mnomonic: AND
                ROUT        = IN1&IN2;
                OCF         = 0;
              end
      4'b1011:begin // Mnomonic: OR
                ROUT        = IN1|IN2;
                OCF         = 0;
              end
      4'b1100:begin // Mnomonic: SLL
                {OCF,ROUT}  = IN1 << IN2[3:0]; 
              end
      4'b1101:begin // Mnomonic: SLA
                {OCF,ROUT}  = IN1 <<< IN2[3:0];
              end
      4'b1110:begin // Mnomonic: SRL
                OCF         = 0;
                {ROUT,OCF}  = {IN1,OCF} >> IN2[3:0];
              end
      4'b1111:begin // Mnomonic: SRA
                OCF         = 0;
                if(IN1[15]) {ROUT,OCF}  = {ShiftMark,IN1,OCF} >>> IN2[3:0];
                else        {ROUT,OCF}  = {IN1,OCF} >>> IN2[3:0];
              end
  endcase
  
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Organization:   Sun Yat-Sen University
// Engineer:       David Qiu <david@davidqiu.com>
// 
// Create Date:    00:20:49 12/12/2013 
// Design Name:    DCUP - ALU Module
// Module Name:    DCUP 
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
  assign OZF = (ROUT == 16'b0);
  
  // OUTPUT : ONF
  assign ONF = (OPC[3]) ? (1'b0) : (ROUT[15]);
  
  // OUTPUT : OUT, OCF
  assign OUT = (OPC==4'b0111) ? (16'b0) : (ROUT);
  always @(*) case(OPC)
      4'b0000:begin // Mnomonic: ALU_LOAD
                ROUT        = IN2;
                OCF         = 0;
              end
      4'b0001:begin // Mnomonic: <null>
                ROUT        = 0;
                OCF         = 0;
              end
      4'b0010:begin // Mnomonic: ALU_ADDC
                {OCF,ROUT}  = IN1+IN2+ICF;
              end
      4'b0011:begin // Mnomonic: <null>
                ROUT        = 0;
                OCF         = 0;
              end
      4'b0100:begin // Mnomonic: <null>
                ROUT        = 0;
                OCF         = 0;
               end
      4'b0101:begin // Mnomonic: ALU_SUBB
                ROUT        = IN1-IN2-ICF;
                OCF         = 0;
              end
      4'b0110:begin // Mnomonic: ALU_INC
                {OCF,ROUT}  = IN1+1;
              end
      4'b0111:begin // Mnomonic: ALU_CMP
                ROUT        = IN1-IN2;
                OCF         = 0;
              end
      4'b1000:begin // Mnomonic: <null>
                ROUT        = 0;
                OCF         = 0;
              end
      4'b1001:begin // Mnomonic: ALU_XOR
                ROUT        = IN1^IN2;
                OCF         = 0;
              end
      4'b1010:begin // Mnomonic: ALU_AND
                ROUT        = IN1&IN2;
                OCF         = 0;
              end
      4'b1011:begin // Mnomonic: ALU_OR
                ROUT        = IN1|IN2;
                OCF         = 0;
              end
      4'b1100:begin // Mnomonic: ALU_SLL
                {OCF,ROUT}  = IN1 << IN2[3:0]; 
              end
      4'b1101:begin // Mnomonic: ALU_SLA
                {OCF,ROUT}  = IN1 <<< IN2[3:0];
              end
      4'b1110:begin // Mnomonic: ALU_SRL
                OCF         = 0;
                {ROUT,OCF}  = {IN1,OCF} >> IN2[3:0];
              end
      4'b1111:begin // Mnomonic: ALU_SRA
                OCF         = 0;
                if(IN1[15]) {ROUT,OCF}  = {ShiftMark,IN1,OCF} >>> IN2[3:0];
                else        {ROUT,OCF}  = {IN1,OCF} >>> IN2[3:0];
              end
  endcase
  
endmodule

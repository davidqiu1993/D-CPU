`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:34:56 12/24/2013
// Design Name:   ALU
// Module Name:   C:/Users/David/Documents/Xilinx Projects/Project/DCUP/ALU_test01.v
// Project Name:  DCUP
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ALU
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ALU_test01;

	// Inputs
	reg [3:0] OPC;
	reg [15:0] IN1;
	reg [15:0] IN2;
	reg ICF;

	// Outputs
	wire [15:0] OUT;
	wire OCF;
	wire OZF;
	wire ONF;

	// Instantiate the Unit Under Test (UUT)
	ALU uut (
		.OPC(OPC), 
		.IN1(IN1), 
		.IN2(IN2), 
		.ICF(ICF), 
		.OUT(OUT), 
		.OCF(OCF), 
		.OZF(OZF), 
		.ONF(ONF)
	);

	initial begin
		// Initialize Inputs
		OPC = 0;
		IN1 = 0;
		IN2 = 0;
		ICF = 0;

		// Wait 100 ns for global reset to finish
		#100;
    
    // Set monitored interface
    $monitor("%b:%h:%h:%b   :%h:%b   :%b   :%b   ", uut.OPC, uut.IN1, uut.IN2, uut.ICF, uut.OUT, uut.OCF, uut.OZF, uut.ONF);
    
    // Add stimulus here
    #99
      OPC <= 4'b0000;
      IN1 <= 16'hF002;
      IN2 <= 16'h0FFF;
      ICF <= 1'b0;
    $display("TEST 01 : (1)0000 [ADD]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b0001;
      IN1 <= 16'h102C;
      IN2 <= 16'h59FF;
      ICF <= 1'b0;
    $display("TEST 02 : (1)0001 [ADDI]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b0010;
      IN1 <= 16'h2008;
      IN2 <= 16'h0108;
      ICF <= 1'b1;
    $display("TEST 03 : (1)0010 [ADDC]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b0011;
      IN1 <= 16'h1000;
      IN2 <= 16'h08FF;
      ICF <= 1'b0;
    $display("TEST 04 : (1)0011 [SUB]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b0100;
      IN1 <= 16'h0001;
      IN2 <= 16'h1000;
      ICF <= 1'b0;
    $display("TEST 05 : (1)0100 [SUBI]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b0101;
      IN1 <= 16'h1000;
      IN2 <= 16'h0FFF;
      ICF <= 1'b1;
    $display("TEST 06 : (1)0101 [SUBC]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b0110;
      IN1 <= 16'h0FFF;
      IN2 <= 16'h0000;
      ICF <= 1'b0;
    $display("TEST 07 : (1)0110 [INC]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b0111;
      IN1 <= 16'h21FC;
      IN2 <= 16'h2F56;
      ICF <= 1'b0;
    $display("TEST 08 : (1)0111 [CMP] - less");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b0111;
      IN1 <= 16'h64FF;
      IN2 <= 16'h64FF;
      ICF <= 1'b0;
    $display("TEST 09 : (1)0111 [CMP] - equal");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b0111;
      IN1 <= 16'hB9A8;
      IN2 <= 16'h975F;
      ICF <= 1'b0;
    $display("TEST 10 : (1)0111 [CMP] - larger");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b1000;
      IN1 <= 16'h56FC;
      IN2 <= 16'h0000;
      ICF <= 1'b0;
    $display("TEST 11 : (1)1000 [TRAN]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b1001;
      IN1 <= 16'hFF0F;
      IN2 <= 16'hF0FA;
      ICF <= 1'b0;
    $display("TEST 12 : (1)1001 [XOR]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b1010;
      IN1 <= 16'hF00F;
      IN2 <= 16'hFF0A;
      ICF <= 1'b0;
    $display("TEST 13 : (1)1010 [AND]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b1011;
      IN1 <= 16'hF00F;
      IN2 <= 16'hFF0A;
      ICF <= 1'b0;
    $display("TEST 14 : (1)1011 [OR]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b1100;
      IN1 <= 16'hF0F0;
      IN2 <= 16'h0004;
      ICF <= 1'b0;
    $display("TEST 15 : (1)1100 [SLL]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b1101;
      IN1 <= 16'h0F0F;
      IN2 <= 16'h0004;
      ICF <= 1'b0;
    $display("TEST 16 : (1)1101 [SLA]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b1110;
      IN1 <= 16'hF000;
      IN2 <= 16'h0004;
      ICF <= 1'b0;
    $display("TEST 17 : (1)1110 [SRL]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
    #99
      OPC <= 4'b1111;
      IN1 <= 16'hF0FF;
      IN2 <= 16'h0004;
      ICF <= 1'b0;
    $display("TEST 18 : (1)1111 [SRA]");
    $display("OPC :IN1 :IN2 :ICF :OUT :OCF :OZF :ONF ");
    #1 $display(" ");
    
	end
  
endmodule


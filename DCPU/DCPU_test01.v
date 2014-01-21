`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:06:15 01/18/2014
// Design Name:   DCPU
// Module Name:   C:/Users/David/Documents/Xilinx Projects/Project/DCUP/DCPU_test01.v
// Project Name:  DCUP
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: DCPU
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module DCPU_test01;

  // === Instruction Definitions ===
  // General
  `define NOP   5'b00000
  `define HALT  5'b00001
  // Data Transfer
  `define LOAD  5'b00010
  `define STORE 5'b00011
  // Arithmetic
  `define CMP   5'b00100
  // Control
  `define BE    5'b00101
  `define JUMP  5'b00110
  `define JMPR  5'b00111
  `define BZ    5'b01000
  `define BNZ   5'b01001
  `define BN    5'b01010
  `define BNN   5'b01011
  `define BC    5'b01100
  `define BNC   5'b01101
  `define BB    5'b01110
  `define BS    5'b01111
  // Arithmetic
  `define ADD   5'b10000
  `define ADDI  5'b10001
  `define ADDC  5'b10010
  `define SUB   5'b10011
  `define SUBI  5'b10100
  `define SUBB  5'b10101
  `define INC   5'b10110
  // Data Transfer
  `define LDIL  5'b10111
  `define LDIH  5'b11000
  // Logic
  `define XOR   5'b11001
  `define AND   5'b11010
  `define OR    5'b11011
  // Shift
  `define SLL   5'b11100
  `define SLA   5'b11101
  `define SRL   5'b11110
  `define SRA   5'b11111
  
  // === General Registers ===
  `define AR0 3'h0
  `define BR0 4'h0
  `define AR1 3'h1
  `define BR1 4'h1
  `define AR2 3'h2
  `define BR2 4'h2
  `define AR3 3'h3
  `define BR3 4'h3
  `define AR4 3'h4
  `define BR4 4'h4
  `define AR5 3'h5
  `define BR5 4'h5
  `define AR6 3'h6
  `define BR6 4'h6
  `define AR7 3'h7
  `define BR7 4'h7
  

	// Inputs
	reg CLK;
	reg RST;
	reg EN;
	reg Start;
	reg [15:0] Inst;
	reg [15:0] DataIn;

	// Outputs
	wire [7:0] InstMemAddr;
	wire [7:0] DataMemAddr;
	wire DataMemWE;
	wire [15:0] DataOut;

	// Instantiate the Unit Under Test (UUT)
	DCPU uut (
		.CLK(CLK), 
		.RST(RST), 
		.EN(EN), 
		.Start(Start), 
		.InstMemAddr(InstMemAddr), 
		.Inst(Inst), 
		.DataMemAddr(DataMemAddr), 
		.DataIn(DataIn), 
		.DataMemWE(DataMemWE), 
		.DataOut(DataOut)
	);

	initial begin
		// Initialize Inputs
		CLK = 0;
		RST = 0;
		EN = 0;
		Start = 0;
		Inst = 0;
		DataIn = 0;

		// Global reset
    #100;
    RST <= 1'b1;
    #100;
    RST <= 1'b0;
    #100;
    EN    <= 1'b1;
    Start <= 1'b1;
    #100;
    Inst <= {`NOP,   3'h0, 4'h0, 4'h0}; #10; CLK <= 1; #10; CLK <= 0;
    //Inst <= {`NOP,   3'h0, 4'h0, 4'h0}; #10; CLK <= 1; #10; CLK <= 0;
    $display("CLK:InstMemAddr:Inst:DataMemAddr:DataIn:DataMemWE:DataOut");
    
		// Monitor configuration
    $monitor("%b  :%h         :%h:%h         :%h  :%b        :%h   ",
             uut.CLK,
             uut.InstMemAddr,
             uut.Inst,
             uut.DataMemAddr,
             uut.DataIn,
             uut.DataMemWE,
             uut.DataOut);
    
    // Test banch
    DataIn <= 16'h9; // DataMem[0x0000] == 0x0009
    Inst <= {`LOAD,  `AR0, `BR0, 4'h0}; #10; CLK <= 1; #10; CLK <= 0; // 0x0000 (D-Hazard)
    Inst <= {`LDIL,  `AR1, 4'h0, 4'h2}; #10; CLK <= 1; #10; CLK <= 0; // 0x0001 (D-Hazard)
    Inst <= {`ADD,   `AR5, `BR0, `BR1}; #10; CLK <= 1; #10; CLK <= 0; // 0x0002 
    Inst <= {`JUMP,  `AR0, 4'h2, 4'h0}; #10; CLK <= 1; #10; CLK <= 0; // 0x0003 (C-Hazard)
    Inst <= {`SUB,   `AR0, `BR0, `BR1}; #10; CLK <= 1; #10; CLK <= 0; // 0x0004 (Unexpected
    Inst <= {`SUB,   `AR0, `BR0, `BR1}; #10; CLK <= 1; #10; CLK <= 0; // 0x0005 Inst loaded
    Inst <= {`SUB,   `AR0, `BR0, `BR1}; #10; CLK <= 1; #10; CLK <= 0; // 0x0006 into CPU)
    
    Inst <= {`ADD,   `AR0, `BR0, `BR1}; #10; CLK <= 1; #10; CLK <= 0; // 0x0020 (Branched)
    Inst <= {`STORE, `AR5, `BR2, 4'h0}; #10; CLK <= 1; #10; CLK <= 0; // 0x0021
    Inst <= {`STORE, `AR0, `BR2, 4'h1}; #10; CLK <= 1; #10; CLK <= 0; // 0x0022
    Inst <= {`NOP,   3'h0, 4'h0, 4'h0}; #10; CLK <= 1; #10; CLK <= 0; // 0x0023
    Inst <= {`NOP,   3'h0, 4'h0, 4'h0}; #10; CLK <= 1; #10; CLK <= 0; // 0x0024
    Inst <= {`NOP,   3'h0, 4'h0, 4'h0}; #10; CLK <= 1; #10; CLK <= 0; // 0x0025
    Inst <= {`NOP,   3'h0, 4'h0, 4'h0}; #10; CLK <= 1; #10; CLK <= 0; // 0x0026
    Inst <= {`NOP,   3'h0, 4'h0, 4'h0}; #10; CLK <= 1; #10; CLK <= 0; // 0x0027
    Inst <= {`HALT,  3'h0, 4'h0, 4'h0}; #10; CLK <= 1; #10; CLK <= 0; // 0x0028

	end
      
endmodule


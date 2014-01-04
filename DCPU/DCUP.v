`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:28:50 12/25/2013 
// Design Name: 
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
module DCUP(
  input  wire       CLK,          // Clock Signal               (posedge)
  input  wire       RST,          // Asynchronized Reset Signal (negedge)
  input  wire       EN,           // Enable Signal              (posedge)
  input  wire       Start,        // Program Start Signal       (posedge)
  output reg [7:0]  InstMemAddr,  // Instruction Memory Address
  input  wire[15:0] Inst,         // Instruction = {OPC[5], OP1[3], OP2[4], OP3[4]}
  output reg [7:0]  DataMemAddr,  // Data Memory Address
  input  wire[15:0] DataIn,       // Data Input
  output reg        DataMemWE,    // Data Memory Write Enable
  output reg [15:0] DataOut       // Data Output
);
  
  // === CPU State Definitions ===
  `define SIdle 1'b0
  `define SExec 1'b1
  
  // === Instruction Definitions ===
  // General
  `define NOP   5'b00000
  `define HALT  5'b00001
  // Data Transfer
  `define LOAD  5'b00010
  `define STORE 5'b00011
  `define LDIL  5'b00100
  `define LDIH  5'b00101
  // Control
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
  `define SUBC  5'b10101
  `define INC   5'b10110
  `define CMP   5'b10111
  // Control
  `define BE    5'b11000
  // Logic
  `define XOR   5'b11001
  `define AND   5'b11010
  `define OR    5'b11011
  // Shift
  `define SLL   5'b11100
  `define SLA   5'b11101
  `define SRL   5'b11110
  `define SRA   5'b11111
  
  // === Operation Code Definitions ===
  `define ALU_LOAD  5'b0000
  `define ALU_ADDC  5'b0010
  `define ALU_SUBB  5'b0101
  `define ALU_INC   5'b0110
  `define ALU_CMP   5'b0111
  `define ALU_XOR   5'b1001
  `define ALU_AND   5'b1010
  `define ALU_OR    5'b1011
  `define ALU_SLL   5'b1100
  `define ALU_SLA   5'b1101
  `define ALU_SRL   5'b1110
  `define ALU_SRA   5'b1111
  
  
  // === CPU State ===
  reg        state;
  reg        next_state;
  
  // === CPU General Storage ===
  reg [7:0]  PC;      // Program Counter      [STAGE:IF]
  reg [15:0] GR[0:7]; // General Registers    [STAGE:ID]
  
  // === Instruction Storage ===
  reg [15:0] IDIR;    // Instruction Register [STAGE:ID]
  reg [15:0] EXIR;    // Instruction Register [STAGE:EX]
  reg [15:0] MRIR;    // Instruction Register [STAGE:MR]
  reg [15:0] WBIR;    // Instruction Register [STAGE:WB]
  
  // === Data Storage ===
  reg [15:0] EXRA;    // Left Operand of ALU  [STAGE:EX]
  reg [15:0] EXRB;    // Right Operand of ALU [STAGE:EX]
  reg [15:0] EXSD;    // Store-to-Memory Data [STAGE:EX]
  reg        EXCF;    // Carry Flag Input     [STAGE:EX]
  reg [15:0] MRRC;    // Output result of ALU [STAGE:MR]
  reg        MRCF;    // Carry Flag Output    [STAGE:MR]
  reg        MRZF;    // Zero Flag Output     [STAGE:MR]
  reg        MRNF;    // Negative Flag Output [STAGE:MR]
  reg        MRDW;    // Data Write Enable    [STAGE:MR]
  reg [15:0] MRSD;    // Store-to-Memory Data [STAGE:MR]
  reg [15:0] WBRC;    // Result Data Register [STAGE:WB]
  
  
  // === CPU State Machine ===
  always @(posedge CLK, posedge RST) begin
    if(RST) state <= `SIdle;
    else    state <= next_state;
  end
  
  always @(*) begin
    case(state)
      `SIdle:
        if(EN & Start) next_state <= `SExec;
        else           next_state <= `SIdle;
      `SExec:
        if(!EN | WBIR[15:11]==`HALT) next_state <= `SIdle;
        else                         next_state <= `SExec;
    endcase
  end
  
  
  // === STAGE: IF (Instruction Fetch) ===
  always @(posedge CLK, posedge RST) begin
    if(RST) begin
      IDIR <= 16'b0;  // Clear instruction register
      PC   <= 8'b0;   // Clear program counter
    end
    else begin // CLK
      if(state==`SExec) begin
        // Push instruction fetched from instruction memory
        IDIR <= Inst;
        // Select next instruction address
        if((MRIR==`JUMP)
        || (MRIR==`JMPR)
        || (MRIR==`BZ  &&  MRZF)
        || (MRIR==`BNZ && ~MRZF)
        || (MRIR==`BN  &&  MRNF)
        || (MRIR==`BNN && ~MRNF)
        || (MRIR==`BC  &&  MRCF)
        || (MRIR==`BNC && ~MRCF)
        || (MRIR==`BB  && ~MRNF)
        || (MRIR==`BS  &&  MRNF)
        || (MRIR==`BE  &&  MRZF))
        begin
          PC <= MRRC[7:0]; // Instruction address from ALU result
        end
        else begin
          PC <= PC + 1;    // Instruction address points to next
        end
      end
      else begin // SIdle
        IDIR <= IDIR;      // Hold the current instruction
        PC   <= PC;        // Hold the current address
      end
    end
  end
  
  
  // === STAGE: ID (Instruction Decode) ===
  always @(posedge CLK, posedge RST) begin
    if(RST) begin
      GR[0] <= 0;       // Clear general registers
      GR[1] <= 0;
      GR[2] <= 0;
      GR[3] <= 0;
      GR[4] <= 0;
      GR[5] <= 0;
      GR[6] <= 0;
      GR[7] <= 0;
      EXIR  <= 0;       // Clear instruction register
      EXRA  <= 0;       // Clear register A
      EXRB  <= 0;       // Clear register B
      EXSD  <= 0;       // Clear stored-data register
      EXCF  <= 1'b0;    // Clear carry flag input
    end
    else begin // CLK
      if(state==`SExec) begin
        // Push instruction to the next instruction register
        EXIR  <= IDIR;
        
        // Select the value of register A
        
        
        // Select the value of register B
        
        // Select the value of stored-data register
        
        // Update the values of general registers
        
      end
      else begin // SIdle
        GR[0] <= GR[0];   // Hold general registers
        GR[1] <= GR[1];
        GR[2] <= GR[2];
        GR[3] <= GR[3];
        GR[4] <= GR[4];
        GR[5] <= GR[5];
        GR[6] <= GR[6];
        GR[7] <= GR[7];
        EXIR  <= EXIR;    // Hold instruction register
        EXRA  <= EXRA;    // Hold register A
        EXRB  <= EXRB;    // Hold register B
        EXSD  <= EXSD;    // Hold stored-data register
        EXCF  <= EXCF;    // Hold carry flag input
      end
    end
  end
  
  
  // === STAGE: EX (Execution) ===
  always @(posedge CLK, posedge RST) begin
    if(RST) begin
      
    end
    else begin // CLK
      if(state==`SExec) begin
        
      end
      else begin // SIdle
        
      end
    end
  end
  
  
  // === STAGE: MR (Memory Read/Write) ===
  always @(posedge CLK, posedge RST) begin
    if(RST) begin
      
    end
    else begin // CLK
      if(state==`SExec) begin
        
      end
      else begin // SIdle
        
      end
    end
  end
  
  
  // === STAGE: WB (Write Back) ===
  always @(posedge CLK, posedge RST) begin
    if(RST) begin
      
    end
    else begin // CLK
      if(state==`SExec) begin
        
      end
      else begin // SIdle
        
      end
    end
  end
  
endmodule

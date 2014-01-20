`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Organization:   Sun Yat-Sen University
// Engineer:       David Qiu <david@davidqiu.com>
// 
// Create Date:    17:28:50 12/25/2013 
// Design Name:    DCPU - CPU Module
// Module Name:    DCPU 
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
module DCPU(
  output wire[15:0] DEBUG,
  input  wire       CLK,          // Clock Signal               (posedge)
  input  wire       RST,          // Asynchronized Reset Signal (negedge)
  input  wire       EN,           // Enable Signal              (posedge)
  input  wire       Start,        // Program Start Signal       (posedge)
  output wire[7:0]  InstMemAddr,  // Instruction Memory Address
  input  wire[15:0] Inst,         // Instruction = {OPC[5], OP1[3], OP2[4], OP3[4]}
  output wire[7:0]  DataMemAddr,  // Data Memory Address
  input  wire[15:0] DataIn,       // Data Input
  output wire       DataMemWE,    // Data Memory Write Enable
  output wire[15:0] DataOut       // Data Output
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
  
  // === Operation Code Definitions ===
  `define ALU_CMP   5'b0000
  `define ALU_ADDC  5'b0010
  `define ALU_SUBB  5'b0101
  `define ALU_INC   5'b0110
  `define ALU_LOAD  5'b0111
  `define ALU_XOR   5'b1001
  `define ALU_AND   5'b1010
  `define ALU_OR    5'b1011
  `define ALU_SLL   5'b1100
  `define ALU_SLA   5'b1101
  `define ALU_SRL   5'b1110
  `define ALU_SRA   5'b1111
  
  
  // === Variable Marco Definitions ===
  `define EXR1      GR[IDIR[10:8]]
  `define EXR2      GR[IDIR[6:4]]
  `define EXR3      GR[IDIR[2:0]]
  `define EXVAL2    IDIR[7:4]
  `define EXVAL3    IDIR[3:0]
  `define IDR1N     IDIR[10:8]
  `define EXR1N     EXIR[10:8]
  `define MRR1N     MRIR[10:8]
  `define WBR1N     WBIR[10:8]
  `define IDR2N     IDIR[6:4]
  `define IDR3N     IDIR[2:0]
  
  ////// DEBUG //////
  reg[15:0] DEBUGR;
  
  
  // === CPU State ===
  reg        state;
  reg        next_state;
  
  // === CPU General Storage ===
  reg [7:0]  PC;      // Program Counter      [STAGE:IF]
  reg [15:0] GR[0:7]; // General Registers    [STAGE:WB]
  
  // === Instruction Storage ===
  reg [15:0] IDIR;    // Instruction Register [STAGE:IF]
  reg [15:0] EXIR;    // Instruction Register [STAGE:ID]
  reg [3:0]  EXOP;    // ALU Opcode Register  [STAGE:ID]
  reg [15:0] MRIR;    // Instruction Register [STAGE:EX]
  reg [15:0] WBIR;    // Instruction Register [STAGE:MR]
  
  // === Data Storage ===
  reg [15:0] EXRA;    // Left Operand of ALU  [STAGE:ID]
  reg [15:0] EXRB;    // Right Operand of ALU [STAGE:ID]
  reg [15:0] EXSD;    // Store-to-Memory Data [STAGE:ID]
  reg        EXCF;    // Carry Flag Input     [STAGE:ID]
  reg [15:0] MRRC;    // Output result of ALU [STAGE:EX]
  reg        MRCF;    // Carry Flag Output    [STAGE:EX]
  reg        MRZF;    // Zero Flag Output     [STAGE:EX]
  reg        MRNF;    // Negative Flag Output [STAGE:EX]
  reg        MRDW;    // Data Write Enable    [STAGE:EX]
  reg [15:0] MRSD;    // Store-to-Memory Data [STAGE:EX]
  reg [15:0] WBRC;    // Result Data Register [STAGE:MR]
  
  // === Hazard Handling ===
  reg        PCSt;    // PC Stalled
  wire       HazardEX;
  wire       HazardEXL;
  wire       HazardMR;
  wire       HazardMRL;
  wire       HazardWB;
  wire       HazardWBL;
  
  // === Component ALU ===
  wire[15:0] ALUOUT;
  wire       ALUOCF;
  wire       ALUOZF;
  wire       ALUONF;
  ALU        ALUM(.OPC(EXOP),   // Operation Code
                  .IN1(EXRA),   // Input 1
                  .IN2(EXRB),   // Input 2
                  .ICF(EXCF),   // Input Carry Flag
                  .OUT(ALUOUT), // Output
                  .OCF(ALUOCF), // Output Carry Flag
                  .OZF(ALUOZF), // Output Zero Flag
                  .ONF(ALUONF)  // Output Negative Flag
                  );
  
  
  /////// DEBUG ///////
  assign DEBUG = DEBUGR;
  
  
  // === Hazard Checker ===
  assign HazardEX  = EXIR[15];
  assign HazardMR  = MRIR[15];
  assign HazardMRL = (MRIR[14:11]==4'b0010);
  assign HazardWBX = WBIR[15]|(WBIR[14:11]==4'b0010);
  
  
  // === External Interfaces ===
  assign InstMemAddr = PC;
  assign DataMemAddr = MRRC[7:0];
  assign DataMemWE   = MRDW;
  assign DataOut     = MRSD;
  
  
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
      PCSt <= 1'b0;   // Clear program counter stall state
    end
    else begin // CLK
      if(state==`SExec) begin
        // Push instruction fetched from instruction memory
        IDIR <= Inst;
        // Select next instruction address
        if((MRIR[15:11]==`JUMP)
        || (MRIR[15:11]==`JMPR)
        || (MRIR[15:11]==`BZ  &&  MRZF)
        || (MRIR[15:11]==`BNZ && ~MRZF)
        || (MRIR[15:11]==`BN  &&  MRNF)
        || (MRIR[15:11]==`BNN && ~MRNF)
        || (MRIR[15:11]==`BC  &&  MRCF)
        || (MRIR[15:11]==`BNC && ~MRCF)
        || (MRIR[15:11]==`BB  && ~MRNF)
        || (MRIR[15:11]==`BS  &&  MRNF)
        || (MRIR[15:11]==`BE  &&  MRZF))
        begin
          PC   <= MRRC[7:0]; // Instruction address from ALU result
          PCSt <= 1'b0;      // Clear stall state
        end
        else begin
          if((Inst==`LOAD)&(~PCSt)) begin
            PC   <= PC;     // Stall one line of code
            PCSt <= 1'b1;   // Set state as stalled
          end
          else begin
            PC   <= PC + 1; // Instruction address points to next
            PCSt <= 1'b0;   // Clear the stall state
          end
        end
      end
      else begin // SIdle
        IDIR <= IDIR;      // Hold the current instruction
        PC   <= PC;        // Hold the current address
        PCSt <= PCSt;      // Hold the current stall state
      end
    end
  end
  
  
  // === STAGE: ID (Instruction Decode) ===
  always @(posedge CLK, posedge RST) begin
    if(RST) begin
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
        
        // Select opcode for ALU
        case(IDIR[15:14])
          2'b00:  begin
                    case(IDIR[13:11])
                      3'b100:   EXOP <= `ALU_CMP;
                      3'b110:   EXOP <= `ALU_LOAD;
                      default:  EXOP <= `ALU_ADDC;
                    endcase
                  end
          2'b01:  begin
                    EXOP <= `ALU_ADDC;
                  end
          2'b10:  begin
                    if(IDIR[13:11]==3'b000 || IDIR[13:11]==3'b001)
                      EXOP <= `ALU_ADDC;
                    else if(IDIR[13:11]==3'b011 || IDIR[13:11]==3'b100)
                      EXOP <= `ALU_SUBB;
                    else
                      EXOP <= IDIR[14:11];
                  end
          2'b11:  begin
                    if(IDIR[13:11]==3'b000)
                      EXOP <= `ALU_LOAD;
                    else
                      EXOP <= IDIR[14:11];
                  end
        endcase
        
        // Select the value of EXCF
        if(IDIR[15:11]==`SUBB||IDIR[15:11]==`ADDC)
          EXCF <= MRCF;
        else
          EXCF <= 0;
        
        // Select the value of EXSD
        if(IDIR[15:11]==`STORE)
          if      (HazardEX &(`IDR1N==`EXR1N)) EXSD <= ALUOUT;
          else if (HazardMR &(`IDR1N==`MRR1N)) EXSD <= MRRC;
          else if (HazardMRL&(`IDR1N==`MRR1N)) EXSD <= DataIn;
          else if (HazardWBX&(`IDR1N==`WBR1N)) EXSD <= WBRC;
          else                                 EXSD <= `EXR1;
        else
          EXSD <= 0;
        
        // Select the value of EXRA, EXRB
        case(IDIR[15:11])
          `LOAD:  begin
                    if      (HazardEX &(`IDR2N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR2N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR2N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR2N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR2;
                    EXRB <= `EXVAL3;
                  end
          `STORE: begin
                    if      (HazardEX &(`IDR2N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR2N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR2N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR2N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR2;
                    EXRB <= `EXVAL3;
                  end
          `BE:    begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `JUMP:  begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `JMPR:  begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `BZ:    begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `BNZ:   begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `BN:    begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `BNN:   begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `BC:    begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `BNC:   begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `BB:   begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `BS:    begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `ADDI:  begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `SUBI:  begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `LDIL:  begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3};
                  end
          `LDIH:  begin
                    if      (HazardEX &(`IDR1N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR1N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR1N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR1N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR1;
                    EXRB <= {`EXVAL2,`EXVAL3,8'b0};
                  end
          default:begin
                    if      (HazardEX &(`IDR2N==`EXR1N)) EXRA <= ALUOUT;
                    else if (HazardMR &(`IDR2N==`MRR1N)) EXRA <= MRRC;
                    else if (HazardMRL&(`IDR2N==`MRR1N)) EXRA <= DataIn;
                    else if (HazardWBX&(`IDR2N==`WBR1N)) EXRA <= WBRC;
                    else                                 EXRA <= `EXR2;
                    if      (HazardEX &(`IDR3N==`EXR1N)) EXRB <= ALUOUT;
                    else if (HazardMR &(`IDR3N==`MRR1N)) EXRB <= MRRC;
                    else if (HazardMRL&(`IDR3N==`MRR1N)) EXRB <= DataIn;
                    else if (HazardWBX&(`IDR3N==`WBR1N)) EXRB <= WBRC;
                    else                                 EXRB <= `EXR3;
                  end
        endcase
      end
      else begin // SIdle
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
      MRIR  <= 0;         // Clear instruction register
      MRRC  <= 0;         // Clear result from ALU
      MRCF  <= 1'b0;      // Clear Carry Flag register
      MRZF  <= 1'b0;      // Clear Zero Flag register
      MRNF  <= 1'b0;      // Clear Negative Flag register
      MRDW  <= 1'b0;      // Clear Data-Write enable signal
      MRSD  <= 0;         // Clear Stored-Data register
    end
    else begin // CLK
      if(state==`SExec) begin
        // Push instruction to next instruction register
        MRIR  <= EXIR;
        
        // Push the resut
        MRRC  <= ALUOUT;
        
        // Push the flags
        MRCF  <= ALUOCF;
        MRZF  <= ALUOZF;
        MRNF  <= ALUONF;
        
        // Set data-write configurations
        MRDW  <= (EXIR[15:11]==`STORE);
        MRSD  <= EXSD;
      end
      else begin // SIdle
        MRIR  <= MRIR;    // Hold instruction register
        MRRC  <= MRRC;    // Hold result from ALU
        MRCF  <= MRCF;    // Hold Carry Flag register
        MRZF  <= MRZF;    // Hold Zero Flag register
        MRNF  <= MRNF;    // Hold Negative Flag register
        MRDW  <= MRDW;    // Hold Data-Write enable signal
        MRSD  <= MRSD;    // Hold Stored-Data register
      end
    end
  end
  
  
  // === STAGE: MR (Memory Read/Write) ===
  always @(posedge CLK, posedge RST) begin
    if(RST) begin
      WBIR  <= 0;         // Clear instruction register
      WBRC  <= 0;         // Clear write back data
    end
    else begin // CLK
      if(state==`SExec) begin
        // Push instruction to next instruction register
        WBIR  <= MRIR;
        
        // Select write back data
        if(MRIR[15:11]==`LOAD) WBRC <= DataIn;
        else                   WBRC <= MRRC;
      end
      else begin // SIdle
        WBIR  <= 0;       // Hold instruction register
        WBRC  <= 0;       // Hold write back data
      end
    end
  end
  
  
  // === STAGE: WB (Write Back) ===
  always @(posedge CLK, posedge RST) begin
    if(RST) begin
      GR[0] <= 0;         // Clear general registers
      GR[1] <= 0;
      GR[2] <= 0;
      GR[3] <= 0;
      GR[4] <= 0;
      GR[5] <= 0;
      GR[6] <= 0;
      GR[7] <= 0;
    end
    else begin // CLK
      if((state==`SExec) && ((WBIR[15:11]==`LOAD)|WBIR[15]))
      begin
        // Update values of general registers
        GR[0] <= (`WBR1N==3'h0) ? (WBRC) : (GR[0]);
        GR[1] <= (`WBR1N==3'h1) ? (WBRC) : (GR[1]);
        GR[2] <= (`WBR1N==3'h2) ? (WBRC) : (GR[2]);
        GR[3] <= (`WBR1N==3'h3) ? (WBRC) : (GR[3]);
        GR[4] <= (`WBR1N==3'h4) ? (WBRC) : (GR[4]);
        GR[5] <= (`WBR1N==3'h5) ? (WBRC) : (GR[5]);
        GR[6] <= (`WBR1N==3'h6) ? (WBRC) : (GR[6]);
        GR[7] <= (`WBR1N==3'h7) ? (WBRC) : (GR[7]);
      end
      else begin // SIdle or Non-load
        GR[0] <= GR[0];   // Hold general registers
        GR[1] <= GR[1];
        GR[2] <= GR[2];
        GR[3] <= GR[3];
        GR[4] <= GR[4];
        GR[5] <= GR[5];
        GR[6] <= GR[6];
        GR[7] <= GR[7];
      end
    end
  end
  
endmodule

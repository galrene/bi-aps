`default_nettype none
// todo: reset, shift J type instruction immediate
module processor( input         clk, reset,
                  output [31:0] PC,
                  input  [31:0] instruction,
                  output        WE,
                  output [31:0] address_to_mem,
                  output [31:0] data_to_mem,
                  input  [31:0] data_from_mem
                );
    wire [31:0] program_counter;

    always @ ( posedge clk )
        PCPlus4 += 4;

    wire [31:0] main_bus;
    
    wire [31:0] rs1;
    wire [31:0] rs2;
    wire [31:0] ALUOut;
    wire [19:0] immOp;
    wire zero;
    wire [31:0] writeData;
    wire [31:0] readData;
    wire [31:0] branchTarget;
    wire [31:0] memToRegRes;
    wire [31:0] AluSrcOut;
    reg [31:0] PCPlus4;
    wire [31:0] branchJalReturnAddr;
    wire [31:0] branchJalrMuxIn;

    /* Control signals */
    wire [2:0] ALUControl;
    wire [2:0] immControl;
    wire memWriteControl;
    assign WE = memWriteControl;
    wire regWriteControl;
    wire ALUSrcControl;
    wire MemToRegControl;
    wire branchBeqControl;
    wire branchJalControl;
    wire branchJalrControl;
    wire branchBltControl;    


    reg_32b registerSet ( instruction[19:15], data_to_mem[24:20], instruction[11:7], memToRegRes, clk, regWriteControl /*we3*/, rs1, writeData );
    imm_decode immediate_decoder ( immControl, instruction[31:7], immOp );
    alu_32b alu ( rs1, AluSrcOut, ALUControl, ALUOut, zero );

    adder_32b branchAdder ( { { 12 { 1'b0 } }, immOp}, program_counter, branchJalrMuxIn ); // expand immOP with zeros

    mux2_1_32b ALUSrc_mux ( ALUSrcControl, writeData, { {12 { 1'b0 } }, immOp }, AluSrcOut );
    mux2_1_32b MemToReg_mux ( MemToRegControl, branchJalReturnAddr, readData, memToRegRes );
    wire branchOutcome = ( branchBeqControl & zero ) | branchJalControl | branchJalrControl | ( ALUOut & branchBltControl );
    mux2_1_32b BranchOutcome_mux ( branchOutcome, PCPlus4, branchTarget, program_counter );
    mux2_1_32b BranchJalAndJalr_mux ( branchJalControl | branchJalrControl, ALUOut, PCPlus4, branchJalReturnAddr );
    mux2_1_32b BranchJalr_mux ( branchJalrControl, branchJalrMuxIn, ALUOut, branchTarget );

    assign address_to_mem = ALUOut;

endmodule

module imm_decode ( input [2:0] i_type,
                    input [31:7] imm_in,
                    output reg [19:0] imm_out );
    always @ ( * ) begin
        case ( i_type )
            3'b000: imm_out = 0; // R-type
            3'b001: imm_out [11:0] = imm_in[31:20]; // I-type
            3'b010: begin // S-type
                imm_out[11:5] = imm_in[31:25]; 
                imm_out[4:0] = imm_in[11:7];
            end
            3'b011: begin // B-type
                imm_out[12] = imm_in[31];
                imm_out[11] = imm_in[7];
                imm_out[10:5] = imm_in[30:25];
                imm_out[4:1] = imm_in[11:8];
            end

            3'b100: imm_out[19:0] = imm_in[31:12]; // U-type
            3'b101: begin // J-type, shifted by 1 bit to the right
                    imm_out[19] = imm_in[31];
                    imm_out[9:0] = imm_in[30:21];
                    imm_out[10] = imm_in[20];
                    imm_out[18:11] = imm_in[19:12];
            end
        endcase
    end


endmodule

module adder_32b ( input [31:0] a, b,
                   output [31:0] res );
    assign res = a + b;
endmodule

module mux2_1_32b ( input sig, input [31:0] a, b,
                    output [31:0] out );
        assign out = ( a & !sig ) | ( b & sig ) ;
endmodule

module reg_32b ( input [4:0] a1, a2, a3,
                input [31:0] wd3,
                input clk, we3,
                output reg [31:0] rd1, rd2 );
    
    reg [31:0] registers [31:0];
    
    always @ ( a1, a2 ) begin
        rd1 = registers[a1];
        rd2 = registers[a2];
        registers[0] = 0;
    end

    always @ ( posedge clk ) begin
        if ( we3 == 1 )
            registers[a3] = wd3;
        registers[0] = 0;
    end
    

endmodule

module alu_32b ( input [31:0] SrcA, SrcB,
                 input [2:0] ALUControl,
                 output reg [31:0] ALUResult,
                 output reg Zero );
    
    always @ (*) begin

        case ( ALUControl )
            3'b000: ALUResult = SrcA + SrcB;
            3'b001: ALUResult = SrcA - SrcB;
            3'b010: ALUResult = SrcA & SrcB;
            3'b011: ALUResult = SrcA < SrcB ? 1 : 0; // slt
            3'b100: ALUResult = SrcA / SrcB;
            3'b101: ALUResult = SrcA % SrcB;
        endcase
    
    Zero = ALUResult == 0 ? 1 : 0;
    end

endmodule

module control_unit ( input [6:0] opcode,
                      output reg ALUSrc, RegWrite, MemWrite, Branch,
                      output reg [1:0] ALUControl );
        always @ ( * ) begin
            case ( opcode )
                3'b000: begin
                    ALUSrc = 0;
                    RegWrite = 1;
                    ALUControl = 2'b00;
                    MemWrite = 0;
                    Branch = 0;
                end
                3'b001: begin
                    ALUSrc = 1;
                    RegWrite = 1;
                    ALUControl = 2'b00;
                    MemWrite = 0;
                    Branch = 0;
                end
                3'b010: begin
                    ALUSrc = 0;
                    RegWrite = 1;
                    ALUControl = 2'b01;
                    MemWrite = 0;
                    Branch = 0;
                end
                3'b011: begin
                    ALUSrc = 1;
                    RegWrite = 1;
                    ALUControl = 2'b00;
                    MemWrite = 0;
                    Branch = 0;
                end
                3'b100: begin
                    ALUSrc = 1;
                    RegWrite = 0;
                    ALUControl = 2'b00;
                    MemWrite = 1;
                    Branch = 0;
                end
                3'b101: begin
                    ALUSrc = 0;
                    RegWrite = 0;
                    ALUControl = 2'b01;
                    MemWrite = 0;
                    Branch = 1;
                end
                default: begin
                    ALUSrc = 0;
                    RegWrite = 0;
                    ALUControl = 2'b00;
                    MemWrite = 0;
                    Branch = 0;
                end
            endcase
        end

endmodule

`default_nettype wire
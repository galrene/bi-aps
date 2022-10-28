`default_nettype none

/*
*/  
module processor( input         clk, reset,
                  output [31:0] PC,
                  input  [31:0] instruction,
                  output        WE,
                  output [31:0] address_to_mem,
                  output [31:0] data_to_mem,
                  input  [31:0] data_from_mem
                );
    assign address_to_mem = ALUOut;
    assign data_to_mem = writeData;
    assign PC = program_counter;
    reg [31:0] program_counter;
    wire [31:0] PC_cable;

    always @ ( posedge clk )  begin
        program_counter <= PC_cable;
        if ( reset )
            program_counter <= { 32 { 1'b0 } };
    end
    assign PCPlus4 = program_counter + 3'b100;
    
    wire [31:0] rs1;
    wire [31:0] ALUOut;
    wire [31:0] immOp;
    wire zero;
    wire [31:0] writeData;
    wire [31:0] readData = data_from_mem;
    wire [31:0] branchTarget;
    wire [31:0] memToRegRes;
    wire [31:0] AluSrcOut;
    wire [31:0] PCPlus4;
    wire [31:0] branchJalReturnAddr;
    wire [31:0] branchJalrMuxIn;
    wire [31:0] srcACable;

    /* Control signals */
    wire [2:0] ALUControl;
    wire [2:0] immControl;
    wire memWriteControl;
    assign WE = memWriteControl;
    wire regWriteControl;
    wire ALUSrcControl;
    wire MemToRegControl;
    wire branchBeqControl;
    wire branchBneControl;
    wire branchJalControl;
    wire branchJalrControl;
    wire branchBltControl;   
    wire auiControl;


    reg_32b registerSet ( instruction[19:15], instruction[24:20], instruction[11:7], memToRegRes, clk, regWriteControl, rs1, writeData );
    imm_decode immediate_decoder ( immControl, instruction[31:7], immOp );
    alu_32b alu ( srcACable, AluSrcOut, ALUControl, ALUOut, zero );
    control_unit cu ( instruction,
                      immControl, ALUControl, 
                      memWriteControl,
                      regWriteControl,
                      ALUSrcControl,
                      MemToRegControl,
                      branchBeqControl,
                      branchJalControl,
                      branchJalrControl,
                      branchBltControl,
                      branchBneControl,
                      auiControl );

    assign branchJalrMuxIn = immOp + program_counter; // branch adder

    mux2_1_32b ALUSrc_mux ( ALUSrcControl, writeData, immOp, AluSrcOut );
    mux2_1_32b MemToReg_mux ( MemToRegControl, branchJalReturnAddr, readData, memToRegRes );
    wire branchBX = ( branchBeqControl & zero ) | ( ALUOut & branchBltControl ) | ( branchBneControl & ! zero );
    wire branchOutcome = branchBX | branchJalControl | branchJalrControl;
    mux2_1_32b BranchOutcome_mux ( branchOutcome, PCPlus4, branchTarget, PC_cable );
    mux2_1_32b BranchJalAndJalr_mux ( branchJalControl | branchJalrControl, ALUOut, PCPlus4, branchJalReturnAddr );
    mux2_1_32b BranchJalr_mux ( branchJalrControl, branchJalrMuxIn, ALUOut, branchTarget );
    mux2_1_32b aui_mux ( auiControl, rs1, program_counter, srcACable );

    
endmodule

module imm_decode ( input [2:0] i_type,
                    input [31:7] imm_in,
                    output reg [31:0] imm_out );
    always @ ( * ) begin
        case ( i_type )
            3'b000: imm_out = 0; // R-type
            3'b001: begin
                imm_out[11:0] = imm_in[31:20]; // I-type
                imm_out[31:12] = { 20 { imm_in[31] } }; // sign extension
            end
            3'b010: begin // S-type
                imm_out[11:5] = imm_in[31:25]; 
                imm_out[4:0] = imm_in[11:7];
                imm_out[31:12] = { 20 { imm_in[31] } }; // sign extension
            end
            3'b011: begin // B-type
                imm_out[12] = imm_in[31];
                imm_out[10:5] = imm_in[30:25];
                imm_out[11] = imm_in[7];
                imm_out[4:1] = imm_in[11:8];
                imm_out[0] = 0;
                imm_out[31:13] = { 19 { imm_in[31] } }; // sign extension
            end
            3'b100: begin // U-type
                imm_out[31:12] = imm_in[31:12]; 
                imm_out[11:0] = { 12 { 1'b0 } };
            end
            3'b101: begin // J-type
                    imm_out[31:21] = { 11 { imm_in[31] } }; // sign extension
                    imm_out[20] = imm_in[31];
                    imm_out[10:1] = imm_in[30:21];
                    imm_out[11] = imm_in[20];
                    imm_out[19:12] = imm_in[19:12];
                    imm_out[0] = 0;
            end
        endcase
    end


endmodule
module mux2_1_32b ( input sig, input [31:0] a, b,
                    output [31:0] out );
        assign out = sig ? b : a;
endmodule

module reg_32b ( input [4:0] a1, a2, a3,
                 input [31:0] wd3,
                 input clk, we3,
                 output [31:0] rd1, rd2 );
    reg [31:0] registers [31:0];
    
    assign rd1 = a1 == 0 ? 0 : registers[a1];
    assign rd2 = a2 == 0 ? 0 : registers[a2];

    always @ ( posedge clk )
        if ( we3 && a3 != 0 )
            registers[a3] <= wd3;
endmodule

module alu_32b ( input signed [31:0] srcA, srcB,
                 input [2:0] ALUControl,
                 output reg [31:0] ALUResult,
                 output reg zero );
    
    always @ (*) begin
        case ( ALUControl )
            3'b000: ALUResult = srcA + srcB;
            3'b001: ALUResult = srcA - srcB;
            3'b010: ALUResult = srcA & srcB;
            3'b011: ALUResult = srcA < srcB ? 1 : 0; // slt
            3'b100: ALUResult = srcA / srcB;
            3'b101: ALUResult = srcA % srcB;
            3'b110: ALUResult = srcB; // lui
            3'b111: ALUResult = srcA | srcB;
        endcase
    
    zero = ALUResult == 0 ? 1 : 0;
    end

endmodule

module control_unit ( input [31:0]      instruction,
                      output reg [2:0] immControl, ALUControl,
                      output reg       memWriteControl,
                                       regWriteControl,
                                       ALUSrcControl,
                                       MemToRegControl,
                                       branchBeqControl,
                                       branchJalControl,
                                       branchJalrControl,
                                       branchBltControl,
                                       branchBneControl,
                                       auiControl );
        wire [6:0] opcode = instruction[6:0];
        wire [14:12] funct3 = instruction[14:12];
        wire [31:25] funct7 = instruction[31:25];
        always @ ( * ) begin

            case ( opcode )
            7'b0000011: begin // I-type
                case ( funct3 )
                    3'b010: begin // lw
                      immControl = 3'b001;
                      ALUControl = 3'b000;
                      memWriteControl = 0;
                      regWriteControl = 1;
                      ALUSrcControl = 1;
                      MemToRegControl = 1;
                      branchBeqControl = 0;
                      branchJalControl = 0;
                      branchJalrControl = 0;
                      branchBltControl = 0;
                      auiControl = 0;
                      branchBneControl = 0;
                    end
                endcase
            end
            7'b0010011: begin  // I-type: addi
                case ( funct3 )
                    3'b000: begin // addi
                      immControl = 3'b001;
                      ALUControl = 3'b000;
                      memWriteControl = 0;
                      regWriteControl = 1;
                      ALUSrcControl = 1;
                      MemToRegControl = 0;
                      branchBeqControl = 0;
                      branchJalControl = 0;
                      branchJalrControl = 0;
                      branchBltControl = 0;
                      auiControl = 0;
                      branchBneControl = 0;
                    end
                endcase
            end
            7'b0100011: begin  // S-type
                case ( funct3 )
                    3'b010: begin // sw
                        immControl = 3'b010;
                        ALUControl = 3'b000;
                        memWriteControl = 1;
                        regWriteControl = 0;
                        ALUSrcControl = 1;
                        MemToRegControl = 1;
                        branchBeqControl = 0;
                        branchJalControl = 0;
                        branchJalrControl = 0;
                        branchBltControl = 0;
                        auiControl = 0;
                        branchBneControl = 0;
                    end
                endcase
            end
            7'b0110011: begin // R-type
                case ( funct3 )
                    3'b000: case ( funct7 )
                            7'b0000000: begin // add
                                immControl = 3'b000;
                                ALUControl = 3'b000;
                                memWriteControl = 0;
                                regWriteControl = 1;
                                ALUSrcControl = 0;
                                MemToRegControl = 0;
                                branchBeqControl = 0;
                                branchJalControl = 0;
                                branchJalrControl = 0;
                                branchBltControl = 0;
                                auiControl = 0;
                                branchBneControl = 0;
                            end
                            7'b0100000: begin // sub
                                immControl = 3'b000;
                                ALUControl = 3'b001;
                                memWriteControl = 0;
                                regWriteControl = 1;
                                ALUSrcControl = 0;
                                MemToRegControl = 0;
                                branchBeqControl = 0;
                                branchJalControl = 0;
                                branchJalrControl = 0;
                                branchBltControl = 0;
                                auiControl = 0;
                                branchBneControl = 0;
                            end
                        endcase
                    3'b010: begin // slt
                        immControl = 3'b000;
                        ALUControl = 3'b011;
                        memWriteControl = 0;
                        regWriteControl = 1;
                        ALUSrcControl = 0;
                        MemToRegControl = 0;
                        branchBeqControl = 0;
                        branchJalControl = 0;
                        branchJalrControl = 0;
                        branchBltControl = 0;
                        auiControl = 0;
                        branchBneControl = 0;
                    end
                    3'b110: begin // rem
                        immControl = 3'b000;
                        ALUControl = 3'b101;
                        memWriteControl = 0;
                        regWriteControl = 1;
                        ALUSrcControl = 0;
                        MemToRegControl = 0;
                        branchBeqControl = 0;
                        branchJalControl = 0;
                        branchJalrControl = 0;
                        branchBltControl = 0;
                        auiControl = 0;
                        branchBneControl = 0;
                    end
                    3'b111: begin // and
                        immControl = 3'b000;
                        ALUControl = 3'b010;
                        memWriteControl = 0;
                        regWriteControl = 1;
                        ALUSrcControl = 0;
                        MemToRegControl = 0;
                        branchBeqControl = 0;
                        branchJalControl = 0;
                        branchJalrControl = 0;
                        branchBltControl = 0;
                        auiControl = 0;
                        branchBneControl = 0;
                    end
                    3'b100: begin // div
                        immControl = 3'b000;
                        ALUControl = 3'b100;
                        memWriteControl = 0;
                        regWriteControl = 1;
                        ALUSrcControl = 0;
                        MemToRegControl = 0;
                        branchBeqControl = 0;
                        branchJalControl = 0;
                        branchJalrControl = 0;
                        branchBltControl = 0;
                        auiControl = 0;
                        branchBneControl = 0;
                    end
                endcase
            end
            7'b1100011: begin // B-type
                case ( funct3 )
                    3'b000: begin // beq
                        immControl = 3'b011;
                        ALUControl = 3'b001;
                        memWriteControl = 0;
                        regWriteControl = 0;
                        ALUSrcControl = 0;
                        MemToRegControl = 0;
                        branchBeqControl = 1;
                        branchJalControl = 0;
                        branchJalrControl = 0;
                        branchBltControl = 0;
                        auiControl = 0;
                        branchBneControl = 0;
                    end
                    3'b100: begin // blt
                        immControl = 3'b011;
                        ALUControl = 3'b011;
                        memWriteControl = 0;
                        regWriteControl = 0;
                        ALUSrcControl = 0;
                        MemToRegControl = 0;
                        branchBeqControl = 0;
                        branchJalControl = 0;
                        branchJalrControl = 0;
                        branchBltControl = 1;
                        auiControl = 0;
                        branchBneControl = 0;
                    end
                    3'b001: begin // bne
                        immControl = 3'b011;
                        ALUControl = 3'b001;
                        memWriteControl = 0;
                        regWriteControl = 0;
                        ALUSrcControl = 0;
                        MemToRegControl = 0;
                        branchBeqControl = 0;
                        branchJalControl = 0;
                        branchJalrControl = 0;
                        branchBltControl = 0;
                        auiControl = 0;
                        branchBneControl = 1;
                    end
                endcase
            end
            7'b1100111: begin // I-type: jalr
                immControl = 3'b001;
                ALUControl = 3'b000;
                memWriteControl = 0;
                regWriteControl = 1;
                ALUSrcControl = 1;
                MemToRegControl = 0;
                branchBeqControl = 0;
                branchJalControl = 0;
                branchJalrControl = 1;
                branchBltControl = 0;
                auiControl = 0;
                branchBneControl = 0;
            end
            7'b1101111: begin // J-type: jal
                immControl = 3'b101;
                ALUControl = 3'b000;
                memWriteControl = 0;
                regWriteControl = 1;
                ALUSrcControl = 0;
                MemToRegControl = 0;
                branchBeqControl = 0;
                branchJalControl = 1;
                branchJalrControl = 0;
                branchBltControl = 0;
                auiControl = 0;
                branchBneControl = 0;
            end
            7'b0110111: begin // lui
                immControl = 3'b100;
                ALUControl = 3'b110;
                memWriteControl = 0;
                regWriteControl = 1;
                ALUSrcControl = 1;
                MemToRegControl = 0;
                branchBeqControl = 0;
                branchJalControl = 0;
                branchJalrControl = 0;
                branchBltControl = 0;
                auiControl = 0;
                branchBneControl = 0;
            end
            7'b0010111: begin // auipc
                immControl = 3'b100;
                ALUControl = 3'b000;
                memWriteControl = 0;
                regWriteControl = 1;
                ALUSrcControl = 1;
                MemToRegControl = 0;
                branchBeqControl = 0;
                branchJalControl = 0;
                branchJalrControl = 0;
                branchBltControl = 0;
                auiControl = 1;
                branchBneControl = 0;
            end
            endcase
        end

endmodule

`default_nettype wire
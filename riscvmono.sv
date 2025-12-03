module riscvmono (
    input logic clk, reset,
    input [31:0] instr,
    input [31:0] readdata,

    output logic [31:0] pc,
    output logic memwrite,
    output logic [31:0] address,
    output logic [31:0] writedata
);

    wire logic WriteBackEN;
    wire [31:0] WriteBackData;

    reg [31:0] Registers [0:31];

    // salva registradores
    always @(posedge clk) begin
        if (WriteBackEN && rd != 0) begin
            Registers[rd] <= WriteBackData;
        end
    end


    assign memwrite = IsS;
    assign address = IsS? rs1Value +  immS: IsL? rs1Value + immI: 32'b0;
    assign writedata = IsS? rs2Value: 32'b0;
    assign WriteBackEN = (IsR || IsI || IsJ || IsL);
    assign WriteBackData = (IsJ) ? (pc + 4): IsL ? readdata: ULAout;
    
    // elementos ULA
    reg [31:0] ULAout;

    // imediatos
    reg IsR, IsI, IsS, IsB, IsU, IsJ, IsL;
    wire [31:0] immI = {{20{instr[31]}}, instr[31:20]}; 
    wire [31:0] immS = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] immB = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] immU = {instr[31:12], 12'b0};
    wire [31:0] immJ = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd = instr[11:7];
    wire [2:0] f3 = instr[14:12];
    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire [6:0] f7 = instr[31:25];

    logic take_branch;

    // garante x0 como 0
    logic [31:0] rs1Value, rs2Value;
    assign rs1Value = (rs1 != 0) ? Registers[rs1]: 32'b0;
    assign rs2Value = (rs2 != 0) ? Registers[rs2]: 32'b0;

    
    // opcodes
    always @(*) begin 
        IsR = 0;
        IsI = 0;
        IsS = 0;
        IsB = 0;
        IsU = 0;
        IsJ = 0;
        IsL = 0;

        case(opcode)
        7'b0110011: IsR = 1;
        7'b0010011: IsI = 1;
        7'b0100011: IsS = 1;
        7'b1100011: IsB = 1;
        7'b0110111: IsU = 1;
        7'b1101111: IsJ = 1;
        7'b0000011: IsL = 1;
        endcase
    end

    // operations
    always @(*) begin
        
        ULAout = 32'b0;
        take_branch = 1'b0;

        if (IsR) begin
            if (f7 == 7'b0000000) begin
                case(f3)
                3'b000: ULAout = rs1Value + rs2Value;
                3'b001: ULAout = rs1Value << rs2Value[4:0];
                3'b010: ULAout = $signed(rs1Value) < $signed(rs2Value)? 1: 0;
                3'b011: ULAout = rs1Value < rs2Value? 1: 0;
                3'b100: ULAout = rs1Value ^ rs2Value;
                3'b101: ULAout = rs1Value >> rs2Value[4:0];
                3'b110: ULAout = rs1Value | rs2Value;
                3'b111: ULAout = rs1Value & rs2Value;              
                endcase
            end
            else begin
            case(f3)
            3'b000: ULAout = rs1Value - rs2Value;
            3'b101: ULAout = $signed(rs1Value) >> $signed(rs2Value); 
            endcase 
            end
        end
        else if (IsI) begin
            case(f3)
            3'b000: ULAout = rs1Value + immI;
            3'b001: ULAout = rs1Value << immI[4:0];
            3'b010: ULAout = $signed(rs1Value) < $signed(immI)? 1: 0;
            3'b011: ULAout = rs1Value < immI? 1: 0;
            3'b100: ULAout = rs1Value ^ immI;
            3'b110: ULAout = rs1Value | immI;
            3'b111: ULAout = rs1Value & immI; 
            endcase
        end
        else if (IsB) begin
            case(f3)
            3'b000: take_branch = rs1Value == rs2Value;
            3'b001: take_branch = rs1Value != rs2Value;
            3'b100: take_branch = $signed(rs1Value) < $signed(rs2Value);
            3'b101: take_branch = $signed(rs1Value) >= $signed(rs2Value);
            3'b110: take_branch = rs1Value < rs2Value;
            3'b111: take_branch = rs1Value >= rs2Value;
            endcase
        end
    end
    
    // PC control
    always @(posedge clk) begin
        if (reset)
            pc <= 0;

        else if (IsJ) begin
            pc <= pc + immJ;
        end

        else if (IsB && take_branch) begin
            pc <= pc + immB;
        end
        else 
            pc <= pc + 4;

    end

endmodule
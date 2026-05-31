module SingleCycleCPU (
    input clk,
    input start
    
);

// When input start is zero, cpu should reset
// When input start is high, cpu start running


wire [31:0] pc_current; // Current PC output
wire [31:0] pc_next;    // Next PC input
PC m_PC(
    .clk(clk),
    .rst(start),       // reset when start=0
    .pc_i(pc_next),    // next PC
    .pc_o(pc_current),  // current PC
    .mem_wait(mem_wait)
);

wire [31:0] pc_plus4;

Adder m_Adder_1(
    .a(pc_current),
    .b(32'd4),
    .sum(pc_plus4)
);

// output instruction wire
wire [31:0] instruction;
InstructionMemory m_InstMem(
    .readAddr(pc_current),   // address = current PC
    .inst(instruction)       // output instruction
);

// control unit wires
wire branch;
wire memRead;
wire memtoReg;
wire [1:0] ALUOp;
wire memWrite;
wire ALUSrc;
wire regWrite;

wire jal_sig,jalr_sig;
Control m_Control(
    .opcode(instruction[6:0]),  // opcode field
    .branch(branch),
    .memRead(memRead),
    .memtoReg(memtoReg),
    .ALUOp(ALUOp),
    .memWrite(memWrite),
    .ALUSrc(ALUSrc),
    .regWrite(regWrite),
    .jal_sig(jal_sig),
    .jalr_sig(jalr_sig)
);


// register file outputs
wire [31:0] readData1;
wire [31:0] readData2;

// write back data input signal (will come from mux - Mux_WriteData output)
wire [31:0] writeData;

wire [31:0] dbg_x0;
wire [31:0] dbg_x1;
wire [31:0] dbg_x2;
wire [31:0] dbg_x3;
wire [31:0] dbg_x4;
wire [31:0] dbg_x5;
wire [31:0] dbg_x6;
wire [31:0] dbg_x7;
wire [31:0] dbg_x8;
wire [31:0] dbg_x9;
wire [31:0] dbg_x10;
wire [31:0] dbg_x11;
wire [31:0] dbg_x12;
wire [31:0] dbg_x13;
wire [31:0] dbg_x14;
wire [31:0] dbg_x15;
wire [31:0] dbg_x16;
wire [31:0] dbg_x17;
wire [31:0] dbg_x18;
wire [31:0] dbg_x19;
wire [31:0] dbg_x20;
wire [31:0] dbg_x21;
wire [31:0] dbg_x22;
wire [31:0] dbg_x23;
wire [31:0] dbg_x24;
wire [31:0] dbg_x25;
wire [31:0] dbg_x26;
wire [31:0] dbg_x27;
wire [31:0] dbg_x28;
wire [31:0] dbg_x29;
wire [31:0] dbg_x30;
wire [31:0] dbg_x31;

Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(regWrite & (!mem_wait)),
    .readReg1(instruction[19:15]),  // rs1
    .readReg2(instruction[24:20]),  // rs2
    .writeReg(instruction[11:7]),   // rd
    .writeData(writeData),
    .readData1(readData1),
    .readData2(readData2),
    .mem_wait(mem_wait),
    .dbg_x0(dbg_x0),
    .dbg_x1(dbg_x1),
    .dbg_x2(dbg_x2),
    .dbg_x3(dbg_x3),
    .dbg_x4(dbg_x4),
    .dbg_x5(dbg_x5),
    .dbg_x6(dbg_x6),
    .dbg_x7(dbg_x7),
    .dbg_x8(dbg_x8),
    .dbg_x9(dbg_x9),
    .dbg_x10(dbg_x10),
    .dbg_x11(dbg_x11),
    .dbg_x12(dbg_x12),
    .dbg_x13(dbg_x13),
    .dbg_x14(dbg_x14),
    .dbg_x15(dbg_x15),
    .dbg_x16(dbg_x16),
    .dbg_x17(dbg_x17),
    .dbg_x18(dbg_x18),
    .dbg_x19(dbg_x19),
    .dbg_x20(dbg_x20),
    .dbg_x21(dbg_x21),
    .dbg_x22(dbg_x22),
    .dbg_x23(dbg_x23),
    .dbg_x24(dbg_x24),
    .dbg_x25(dbg_x25),
    .dbg_x26(dbg_x26),
    .dbg_x27(dbg_x27),
    .dbg_x28(dbg_x28),
    .dbg_x29(dbg_x29),
    .dbg_x30(dbg_x30),
    .dbg_x31(dbg_x31)
);


wire [31:0] imm; // output from immgen unit
ImmGen m_ImmGen(
    .inst(instruction),
    .imm(imm)
);

wire [31:0] imm_shifted; //for branch instructions the immidiate will be shifted left by a bit
ShiftLeftOne m_ShiftLeftOne(
    .i(imm),
    .o(imm_shifted)
);


wire [31:0] branch_jal_target; // this will go to a mux which decides what next PC is...
// branch/jal target adder
Adder m_Adder_2(
    .a(pc_current),
    .b(imm_shifted),
    .sum(branch_jal_target)
);

wire [31:0] jalr_target;
Adder jalr_adder(.a(readData1),
                 .b(imm),
                 .sum(jalr_target));

wire branch_taken;
branch_control bcntrl(
    .branch(branch),
    .funct3(funct3),
    .zero(zero),
    .eff_sign(eff_sign),
    .branch_taken(branch_taken)
);

wire [31:0] w1; //intermidiary for cascaded mux begin made using 3 2:1 muxes

Mux2to1 m_Mux_PC0(
    .sel(branch_taken | jal_sig),
    .s0(jalr_target),        // jalr target 
    .s1(branch_jal_target),   // branch/jal target
    .out(w1)
);

wire mux1cntrl;
assign mux1cntrl = branch_taken | jal_sig | jalr_sig;
Mux2to1 m_Mux_PC1(
    .sel(mux1cntrl),
    .s0(pc_plus4), //pc + 4
    .s1(w1), //from mux0    
    .out(pc_next)
);


// This mux decides B input to the ALU
wire [31:0] alu_B; // goes as input to the ALU
Mux2to1 m_Mux_ALU(
    .sel(ALUSrc),     
    .s0(readData2),    
    .s1(imm),           
    .out(alu_B)
);

wire [3:0] ALUCtl; //output of ALU Control unit
wire [2:0] funct3;
wire funct7_bit;

assign funct3     = instruction[14:12];
assign funct7_bit = instruction[30]; //single fucnt7 bit sufficient to distinguish instructions

ALUCtrl m_ALUCtrl(
    .ALUOp(ALUOp),
    .funct7(funct7_bit),
    .funct3(funct3),
    .ALUCtl(ALUCtl)
);

wire [31:0] ALUOut; // output of the ALU
wire zero,eff_sign;
ALU m_ALU(
    .ALUCtl(ALUCtl),
    .A(readData1),
    .B(alu_B),        // from ALU mux 
    .ALUOut(ALUOut),
    .zero(zero),
    .eff_sign(eff_sign)
);


// DATA MEMORY INTERFACE — CPU → L1Cache → DataMemory

// CPU-side wires 
wire [31:0] memReadData;  // load data back to CPU writeback mux
wire        mem_wait;     // stalls PC and Register file

//  wires between L1Cache and DataMemory
wire [31:0]  dm_addr;       // block-aligned address (lower 4 bits always 0)
wire [127:0] dm_writeData;  // 4 words packed: dirty block going to memory
wire [127:0] dm_readData;   // 4 words packed: new block coming from memory
wire         dm_memRead;    // cache requesting a block read from DataMemory
wire         dm_memWrite;   // cache requesting a block write to DataMemory
wire         dm_mem_wait;   // DataMemory telling cache it is still busy

L1Cache m_L1Cache(
    .clk            (clk),
    .rst            (start),
    // CPU side
    .cpu_addr       (ALUOut),       // address from ALU
    .cpu_writeData  (readData2),    // rs2 value for store instructions
    .cpu_memRead    (memRead),      // from Control unit
    .cpu_memWrite   (memWrite),     // from Control unit
    .cpu_readData   (memReadData),  // load result → writeback mux
    .mem_wait       (mem_wait),     // → PC and Register file
    // DataMemory side
    .dm_addr        (dm_addr),
    .dm_writeData   (dm_writeData),
    .dm_memRead     (dm_memRead),
    .dm_memWrite    (dm_memWrite),
    .dm_readData    (dm_readData),
    .dm_mem_wait    (dm_mem_wait)
);

DataMemory m_DataMemory(
    .rst            (start),
    .clk            (clk),
    .memRead        (dm_memRead),
    .memWrite       (dm_memWrite),
    .address        (dm_addr),
    .writeData      (dm_writeData),
    .readData       (dm_readData),
    .mem_wait       (dm_mem_wait)
);

//write back muxes
wire [31:0] w2; //intermediary for writeback mux
Mux2to1 m_Mux_WriteData0(
    .sel(memtoReg),
    .s0(ALUOut),        // ALU result
    .s1(memReadData),   // Data memory read output (for lw)
    .out(w2)
);

//additional mux for PC + 4 write backs
Mux2to1 m_Mux_WriteData1(
    .sel(jal_sig | jalr_sig),  //will write back PC + 4 only for jal/jalr
    .s0(w2),        // ALU/Data Memory data
    .s1(pc_plus4),   // PC + 4
    .out(writeData)
);

endmodule


module PC (
    input clk,
    input rst,
    input [31:0] pc_i,
    output reg [31:0] pc_o,
    input mem_wait
);

// PC register: updates to next PC on rising edge of clk, active low reset sets PC to 0

always @(posedge clk) begin
	if (~rst)
		pc_o <=32'b0;
    else if(mem_wait)
        pc_o <= pc_o;
    else 
        pc_o <= pc_i;
end
endmodule


module Adder (
    input signed [31:0] a,
    input signed [31:0] b,
    output signed [31:0] sum
);
    // Adder computes sum = a + b
    // The module is useful for incrementing PC 
    // we will need 2 instantiations of the adder - one for PC + 4 , one for PC + offset
 assign sum = a + b;
endmodule


module Mux2to1 (
    input sel,
    input signed [31:0] s0,
    input signed [31:0] s1,
    output signed [31:0] out
);
assign out = sel ? s1 : s0;
endmodule


module Register (
    input clk,
    input rst,
    input regWrite,
    input [4:0] readReg1,
    input [4:0] readReg2,
    input [4:0] writeReg,
    input [31:0] writeData,
    output [31:0] readData1,
    output [31:0] readData2,
    input mem_wait,
    // outputs to view register contents
    output [31:0] dbg_x0,
    output [31:0] dbg_x1,
    output [31:0] dbg_x2,
    output [31:0] dbg_x3,
    output [31:0] dbg_x4,
    output [31:0] dbg_x5,
    output [31:0] dbg_x6,
    output [31:0] dbg_x7,
    output [31:0] dbg_x8,
    output [31:0] dbg_x9,
    output [31:0] dbg_x10,
    output [31:0] dbg_x11,
    output [31:0] dbg_x12,
    output [31:0] dbg_x13,
    output [31:0] dbg_x14,
    output [31:0] dbg_x15,
    output [31:0] dbg_x16,
    output [31:0] dbg_x17,
    output [31:0] dbg_x18,
    output [31:0] dbg_x19,
    output [31:0] dbg_x20,
    output [31:0] dbg_x21,
    output [31:0] dbg_x22,
    output [31:0] dbg_x23,
    output [31:0] dbg_x24,
    output [31:0] dbg_x25,
    output [31:0] dbg_x26,
    output [31:0] dbg_x27,
    output [31:0] dbg_x28,
    output [31:0] dbg_x29,
    output [31:0] dbg_x30,
    output [31:0] dbg_x31
);
    reg [31:0] regs [0:31]; //32 registers of 32 bits length

// Do not modify this file!
    assign readData1 = (readReg1!=0)?regs[readReg1]:0;
    assign readData2 = (readReg2!=0)?regs[readReg2]:0;

    assign dbg_x0  = 32'b0;
    assign dbg_x1  = regs[1];
    assign dbg_x2  = regs[2];
    assign dbg_x3  = regs[3];
    assign dbg_x4  = regs[4];
    assign dbg_x5  = regs[5];
    assign dbg_x6  = regs[6];
    assign dbg_x7  = regs[7];
    assign dbg_x8  = regs[8];
    assign dbg_x9  = regs[9];
    assign dbg_x10 = regs[10];
    assign dbg_x11 = regs[11];
    assign dbg_x12 = regs[12];
    assign dbg_x13 = regs[13];
    assign dbg_x14 = regs[14];
    assign dbg_x15 = regs[15];
    assign dbg_x16 = regs[16];
    assign dbg_x17 = regs[17];
    assign dbg_x18 = regs[18];
    assign dbg_x19 = regs[19];
    assign dbg_x20 = regs[20];
    assign dbg_x21 = regs[21];
    assign dbg_x22 = regs[22];
    assign dbg_x23 = regs[23];
    assign dbg_x24 = regs[24];
    assign dbg_x25 = regs[25];
    assign dbg_x26 = regs[26];
    assign dbg_x27 = regs[27];
    assign dbg_x28 = regs[28];
    assign dbg_x29 = regs[29];
    assign dbg_x30 = regs[30];
    assign dbg_x31 = regs[31];
     
    always @(posedge clk) begin
        if(~rst) begin
            regs[0] <= 0; regs[1] <= 0; regs[2] <= 32'd128; regs[3] <= 0; 
            regs[4] <= 0; regs[5] <= 0; regs[6] <= 0; regs[7] <= 0; 
            regs[8] <= 0; regs[9] <= 0; regs[10] <= 0; regs[11] <= 0; 
            regs[12] <= 0; regs[13] <= 0; regs[14] <= 0; regs[15] <= 0; 
            regs[16] <= 0; regs[17] <= 0; regs[18] <= 0; regs[19] <= 0; 
            regs[20] <= 0; regs[21] <= 0; regs[22] <= 0; regs[23] <= 0; 
            regs[24] <= 0; regs[25] <= 0; regs[26] <= 0; regs[27] <= 0; 
            regs[28] <= 0; regs[29] <= 0; regs[30] <= 0; regs[31] <= 0;        
        end
        else if(regWrite)
            regs[writeReg] <= (writeReg == 0) ? 0 : writeData;
    end

endmodule

// NEW DATA MEMORY BUILT FOR CACHE INTERFACING
module DataMemory(
    input         rst,
    input         clk,
    input         memWrite,
    input         memRead,
    input  [31:0] address,       // block-aligned, lower 4 bits ignored
    input  [127:0] writeData,    // full 16-byte block in one shot
    output reg [127:0] readData, // full 16-byte block out
    output reg    mem_wait
);

    // 1KB memory
    reg [7:0] data_memory [0:1023];

    parameter IDLE     = 2'b00;
    parameter WAIT     = 2'b01;
    parameter COMPLETE = 2'b10;
    parameter DONE     = 2'b11;

    reg [1:0] state;

    // 6-bit counter needed to count up to 47
    reg [5:0] counter;

    // Latch request so signals can't change mid-operation
    reg [31:0]  stored_address;
    reg [127:0] stored_writeData;
    reg         stored_memRead;
    reg         stored_memWrite;

    // Block-aligned base address: zero out lower 4 bits
    wire [31:0] blk_base = {address[31:4], 4'b0000};

    integer i,k;

    always @(posedge clk) begin
        if (~rst) begin
            for (i = 32; i < 127; i = i + 1)
                data_memory[i] <= 8'b0;
            for (k = 144; k < 1024 ; k = k + 1)
                data_memory[i] <= 8'b0;

            // Test block 0: addresses 0x00, 0x04, 0x08, 0x0C
            data_memory[0]  <= 8'h11;
            data_memory[1]  <= 8'h11;
            data_memory[2]  <= 8'h11;
            data_memory[3]  <= 8'h11;   // 0x00 = 0x11111111

            data_memory[4]  <= 8'h22;
            data_memory[5]  <= 8'h22;
            data_memory[6]  <= 8'h22;
            data_memory[7]  <= 8'h22;   // 0x04 = 0x22222222

            data_memory[8]  <= 8'h33;
            data_memory[9]  <= 8'h33;
            data_memory[10] <= 8'h33;
            data_memory[11] <= 8'h33;   // 0x08 = 0x33333333

            data_memory[12] <= 8'h44;
            data_memory[13] <= 8'h44;
            data_memory[14] <= 8'h44;
            data_memory[15] <= 8'h44;   // 0x0C = 0x44444444

            //Block 1
            data_memory[16] <= 8'h55;
            data_memory[17] <= 8'h55;
            data_memory[18] <= 8'h55;
            data_memory[19] <= 8'h55;   // 0x10 = 0x55555555

            data_memory[20] <= 8'h66;
            data_memory[21] <= 8'h66;
            data_memory[22] <= 8'h66;
            data_memory[23] <= 8'h66;   // 0x14 = 0x66666666

            data_memory[24] <= 8'h77;
            data_memory[25] <= 8'h77;
            data_memory[26] <= 8'h77;
            data_memory[27] <= 8'h77;   // 0x18 = 0x77777777

            data_memory[28] <= 8'h88;
            data_memory[29] <= 8'h88;
            data_memory[30] <= 8'h88;
            data_memory[31] <= 8'h88;   // 0x1C = 0x88888888

            // Test block 8: addresses 0x80, 0x84, 0x88, 0x8C
            // Block 8 maps to same cache line as block 0
            data_memory[128] <= 8'hAA;
            data_memory[129] <= 8'hAA;
            data_memory[130] <= 8'hAA;
            data_memory[131] <= 8'hAA;  // 0x80 = 0xAAAAAAAA

            data_memory[132] <= 8'hBB;
            data_memory[133] <= 8'hBB;
            data_memory[134] <= 8'hBB;
            data_memory[135] <= 8'hBB;  // 0x84 = 0xBBBBBBBB

            data_memory[136] <= 8'hCC;
            data_memory[137] <= 8'hCC;
            data_memory[138] <= 8'hCC;
            data_memory[139] <= 8'hCC;  // 0x88 = 0xCCCCCCCC

            data_memory[140] <= 8'hDD;
            data_memory[141] <= 8'hDD;
            data_memory[142] <= 8'hDD;
            data_memory[143] <= 8'hDD;  // 0x8C = 0xDDDDDDDD

            readData         <= 128'b0;
            mem_wait         <= 1'b0;
            counter          <= 6'b0;
            stored_address   <= 32'b0;
            stored_writeData <= 128'b0;
            stored_memRead   <= 1'b0;
            stored_memWrite  <= 1'b0;
            state            <= IDLE;
        end
        else begin
            case (state)

                // Waiting for a request from cache controller
                IDLE: begin
                    mem_wait <= 1'b0;
                    counter  <= 6'b0;

                    if (memRead || memWrite) begin
                        stored_address   <= blk_base;  // align to 16-byte block boundary
                        stored_writeData <= writeData;
                        stored_memRead   <= memRead;
                        stored_memWrite  <= memWrite;
                        mem_wait         <= 1'b1;
                        state            <= WAIT;
                    end
                end

                // Simulating main memory latency
                // counter == 47 gives approximately 50-cycle style memory access
                WAIT: begin
                    mem_wait <= 1'b1;

                    if (counter == 6'd47) begin
                        counter <= 6'd0;
                        state   <= COMPLETE;
                    end
                    else begin
                        counter <= counter + 1'b1;
                    end
                end

                // Full 4-word block transferred simultaneously
                COMPLETE: begin
                    readData <= 128'd0;

                    if (stored_memWrite) begin
                        // Word 0 -> bytes [3:0]
                        data_memory[stored_address + 0]  <= stored_writeData[7:0];
                        data_memory[stored_address + 1]  <= stored_writeData[15:8];
                        data_memory[stored_address + 2]  <= stored_writeData[23:16];
                        data_memory[stored_address + 3]  <= stored_writeData[31:24];

                        // Word 1 -> bytes [7:4]
                        data_memory[stored_address + 4]  <= stored_writeData[39:32];
                        data_memory[stored_address + 5]  <= stored_writeData[47:40];
                        data_memory[stored_address + 6]  <= stored_writeData[55:48];
                        data_memory[stored_address + 7]  <= stored_writeData[63:56];

                        // Word 2 -> bytes [11:8]
                        data_memory[stored_address + 8]  <= stored_writeData[71:64];
                        data_memory[stored_address + 9]  <= stored_writeData[79:72];
                        data_memory[stored_address + 10] <= stored_writeData[87:80];
                        data_memory[stored_address + 11] <= stored_writeData[95:88];

                        // Word 3 -> bytes [15:12]
                        data_memory[stored_address + 12] <= stored_writeData[103:96];
                        data_memory[stored_address + 13] <= stored_writeData[111:104];
                        data_memory[stored_address + 14] <= stored_writeData[119:112];
                        data_memory[stored_address + 15] <= stored_writeData[127:120];
                    end

                    if (stored_memRead) begin
                        readData[31:0] <= {
                            data_memory[stored_address + 3],
                            data_memory[stored_address + 2],
                            data_memory[stored_address + 1],
                            data_memory[stored_address + 0]
                        };

                        readData[63:32] <= {
                            data_memory[stored_address + 7],
                            data_memory[stored_address + 6],
                            data_memory[stored_address + 5],
                            data_memory[stored_address + 4]
                        };

                        readData[95:64] <= {
                            data_memory[stored_address + 11],
                            data_memory[stored_address + 10],
                            data_memory[stored_address + 9],
                            data_memory[stored_address + 8]
                        };

                        readData[127:96] <= {
                            data_memory[stored_address + 15],
                            data_memory[stored_address + 14],
                            data_memory[stored_address + 13],
                            data_memory[stored_address + 12]
                        };
                    end

                    mem_wait <= 1'b0;
                    state    <= DONE;
                end

                // Cool-down state
                DONE: begin
                    mem_wait <= 1'b0;
                    state    <= IDLE;
                end

            endcase
        end
    end

endmodule


module L1Cache (
    input         clk,
    input         rst,

    //CPU SIDE
    input  [31:0] cpu_addr,
    input  [31:0] cpu_writeData,
    input  cpu_memRead,
    input  cpu_memWrite,
    output reg [31:0] cpu_readData,
    output wire mem_wait,

    //DATAMEMORY SIDE
    output reg [31:0]  dm_addr,
    output reg [127:0] dm_writeData,
    output reg dm_memRead,
    output reg dm_memWrite,
    input [127:0] dm_readData,
    input dm_mem_wait
);


    // CACHE STORAGE: 8 lines x 4 words = 128 bytes

    reg valid [0:7];
    reg dirty [0:7];
    reg [24:0] tag_store [0:7];
    reg [31:0] cache_data[0:7][0:3];


    // FSM STATES

    localparam IDLE = 3'd0;
    localparam TAG_CHECK = 3'd1;
    localparam WRITEBACK = 3'd2;
    localparam FILL = 3'd3;
    localparam UPDATE = 3'd4;
    localparam DONE = 3'd5;

    reg [2:0] state;


    // LATCHED CPU REQUEST - memory access information has been latched
    reg [31:0] lat_addr;
    reg [31:0] lat_writeData;
    reg  lat_memRead;
    reg  lat_memWrite;


    // ADDRESS DECOMPOSITION
    // | 31 ..... 7 | 6  5  4 | 3  2 | 1  0 |
    // |  tag (25b) | idx (3b)| word | byte |
 
    wire [1:0]  word_offset = lat_addr[3:2];
    wire [2:0]  index = lat_addr[6:4];
    wire [24:0] tag = lat_addr[31:7];


    // HANDSHAKE FLAGS
    // mem_req_pending : we have issued a request to DataMemory
    // mem_wait_seen   : we have seen dm_mem_wait go HIGH at least once
    //                   (confirms DataMemory actually accepted request)

    reg mem_req_pending;
    reg mem_wait_seen;


    // PERFORMANCE COUNTERS
    reg [31:0] hit_count;
    reg [31:0] miss_count;


    // MEM_WAIT: combinatorial — stalls PC same cycle request arrives
    assign mem_wait = (state == IDLE) ? (cpu_memRead | cpu_memWrite)
                                      : (state != DONE);

    integer i;

    always @(posedge clk) begin
        if (~rst) begin
            state <= IDLE;
            dm_memRead <= 0;
            dm_memWrite  <= 0;
            dm_addr <= 0;
            dm_writeData <= 0;
            cpu_readData <= 0;
            mem_req_pending  <= 0;
            mem_wait_seen  <= 0;
            hit_count  <= 0;
            miss_count  <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                valid[i] <= 0;
                dirty[i]  <= 0;
                tag_store[i] <= 0;
            end
        end
        else begin
            case (state)
                // IDLE - waiting for the CPU to send a memory access request
                IDLE: begin
                    dm_memRead <= 0;
                    dm_memWrite <= 0;
                    mem_req_pending <= 0;
                    mem_wait_seen   <= 0;
                    if (cpu_memRead || cpu_memWrite) begin
                        lat_addr  <= cpu_addr;
                        lat_writeData <= cpu_writeData;
                        lat_memRead <= cpu_memRead;
                        lat_memWrite <= cpu_memWrite;
                        state <= TAG_CHECK;
                    end
                end

                
                // TAG_CHECK (1 cycle) - this state is where we determine HIT or MISS
                TAG_CHECK: begin
                    if (valid[index] && (tag_store[index] == tag)) begin
                        hit_count <= hit_count + 1;
                        state <= UPDATE;
                    end
                    else begin
                        miss_count <= miss_count + 1;
                        mem_req_pending <= 0;       // reset handshake flags
                        mem_wait_seen <= 0;       // for whichever state comes next
                        if (valid[index] && dirty[index])
                            state <= WRITEBACK;
                        else
                            state <= FILL;
                    end
                end

            
                // WRITEBACK
                // Step 1 — issue burst write request (mem_req_pending goes 1)
                // Step 2 — wait until dm_mem_wait goes HIGH (mem_wait_seen=1)
                // Step 3 — wait until dm_mem_wait goes LOW again → truly done
                WRITEBACK: begin
                    if (!mem_req_pending) begin
                        // STEP 1: Issue the request
                        dm_addr  <= {tag_store[index], index, 4'b0000};
                        dm_writeData <= {cache_data[index][3],
                                         cache_data[index][2],
                                         cache_data[index][1],
                                         cache_data[index][0]};
                        dm_memWrite <= 1;
                        dm_memRead  <= 0;
                        mem_req_pending <= 1;
                        mem_wait_seen <= 0;
                    end
                    else begin
                        // STEP 2: Latch when DataMemory goes busy
                        if (dm_mem_wait)
                            mem_wait_seen <= 1;

                        // STEP 3: Only complete after seeing busy→idle transition
                        if (mem_wait_seen && !dm_mem_wait) begin
                            dm_memWrite <= 0;
                            dirty[index] <= 0;
                            mem_req_pending <= 0;
                            mem_wait_seen <= 0;
                            state <= FILL;
                        end
                    end
                end

                
                // FILL STATE Steps:
                // Step 1 — issue read request
                // Step 2 — wait until dm_mem_wait goes HIGH
                // Step 3 — wait until dm_mem_wait goes LOW → latch all 4 words
               
                FILL: begin
                    if (!mem_req_pending) begin
                        // STEP 1: Issue the request
                        dm_addr  <= {tag, index, 4'b0000};
                        dm_memRead  <= 1;
                        dm_memWrite  <= 0;
                        mem_req_pending <= 1;
                        mem_wait_seen <= 0;
                    end
                    else begin
                        // STEP 2: Latch when DataMemory goes busy
                        if (dm_mem_wait)
                            mem_wait_seen <= 1;

                        // STEP 3: Only complete after seeing busy→idle transition
                        if (mem_wait_seen && !dm_mem_wait) begin
                            // All 4 words arrive simultaneously
                            cache_data[index][0] <= dm_readData[31:0];
                            cache_data[index][1] <= dm_readData[63:32];
                            cache_data[index][2] <= dm_readData[95:64];
                            cache_data[index][3] <= dm_readData[127:96];
                            // Update metadata
                            valid[index] <= 1;
                            dirty[index] <= 0;
                            tag_store[index] <= tag;
                            dm_memRead <= 0;
                            mem_req_pending  <= 0;
                            mem_wait_seen <= 0;
                            state <= UPDATE;
                        end
                    end
                end

               
                // UPDATE (1 cycle) - transfer of data to CPU
              
                UPDATE: begin
                    if (lat_memRead)
                        cpu_readData <= cache_data[index][word_offset];
                    else if (lat_memWrite) begin
                        cache_data[index][word_offset] <= lat_writeData;
                        dirty[index] <= 1;
                    end
                    state <= DONE;
                end

                
                // DONE (1 cycle, mem_wait=0)
        
                DONE: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule


module InstructionMemory (
    input  [31:0] readAddr,
    output [31:0] inst
);
    
    // 1KB instruction memory
    reg [7:0] insts [0:1023];
    
    // Return 0 if readAddr is outside safe range.
    // Need readAddr + 3 to be valid, so highest safe readAddr is 1020.
    assign inst = (readAddr > 32'd1020) ? 32'b0 :
                  {insts[readAddr],
                   insts[readAddr + 1],
                   insts[readAddr + 2],
                   insts[readAddr + 3]};

    integer i;

    initial begin
        // Initialize full 1KB instruction memory to zero
        for (i = 0; i < 1024; i = i + 1) begin
            insts[i] = 8'b0;
        end

        // Load instructions from file
        $readmemb("TEST_INSTRUCTIONS.dat", insts);
    end

endmodule

module Control (
    input [6:0] opcode,
    output reg branch,
    output reg memRead,
    output reg memtoReg,
    output reg [1:0] ALUOp,
    output reg memWrite,
    output reg ALUSrc,
    output reg regWrite,
    output jal_sig,
    output jalr_sig
    );
    assign jal_sig = (opcode == 7'b1101111);
    assign jalr_sig =  (opcode == 7'b1100111);
    // TODO: implement your Control here
    
    always @(*) begin
	casex(opcode)

    /*R-type instruction*/ 
    7'b0110011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000001;
    ALUOp = 2'b10;
    end 

    /*Arithmetic I-Type instruction*/
    7'b0010011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000011;
    ALUOp = 2'b11;   
    end   

    /*Load I-type instruction*/
    7'b0000011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b011011;
    ALUOp = 2'b00;
    end

    /*S-Type instruction*/
    7'b0100011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000110;
    ALUOp = 2'b00;
    end      

    /*SB-type instruction*/
    7'b1100011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b100000;  
    ALUOp = 2'b01;
    end
    
    /* UJ-type instruction (jal) */
    7'b1101111 : begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000001;
    ALUOp = 2'b00;  
    end

    /* I-type Jump instruction (jalr) */
    7'b1100111 : begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000011;
    ALUOp = 2'b00;  // (rs1 + imm)
    end
    
    default :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000000;
    ALUOp = 2'b00;   
    end 

    endcase
end

endmodule

module ALUCtrl (
    input [1:0] ALUOp,
    input funct7,
    input [2:0] funct3,
    output reg [3:0] ALUCtl
);

always @(*) begin
    casex({funct7, funct3, ALUOp})
    6'b000010: ALUCtl = 4'b0010; // add
    6'b100010: ALUCtl = 4'b0110; // sub
    6'b011010: ALUCtl = 4'b0001; // or
    6'b011110: ALUCtl = 4'b0000; // and
    6'b010010: ALUCtl = 4'b0011; // xor
    6'b000110: ALUCtl = 4'b0100; // sll
    6'b010110: ALUCtl = 4'b0101; // srl
    6'b110110: ALUCtl = 4'b0111; // sra
    6'b001010: ALUCtl = 4'b1000; // slt
    6'b001110: ALUCtl = 4'b1001; // sltu
    6'bx00011: ALUCtl = 4'b0010; // addi
    6'bx11111: ALUCtl = 4'b0000; // andi
    6'bx11011: ALUCtl = 4'b0001; // ori
    6'bx10011: ALUCtl = 4'b0011; // xori
    6'b000111: ALUCtl = 4'b0100; // slli
    6'b010111: ALUCtl = 4'b0101; // srli
    6'b110111: ALUCtl = 4'b0111; // srai
    6'bx01011: ALUCtl = 4'b1000; // slti
    6'bx01111: ALUCtl = 4'b1001; // sltiu
    6'bxxxxx0: ALUCtl = 4'b0010; // lw/sw 
    6'bxxxxx1: ALUCtl = 4'b0110; // branch (subtraction)

    default:   ALUCtl = 4'b0000;
endcase
end

endmodule



module ALU (
    input [3:0] ALUCtl,
    input [31:0] A,B,
    output reg [31:0] ALUOut,
    output zero,eff_sign
);
    // ALU has two operand, it execute different operator based on ALUctl wire 
    // output zero is for determining taking branch or not 

    // TODO: implement your ALU here
    // shift operations done directly in ALU
    wire sign, overflow; //adding sign and overflow flags

    assign zero = (ALUOut == 0);
    assign sign = (ALUOut[31]);
    assign overflow = (A[31] & ~B[31] & ~ALUOut[31]) | (~A[31] & B[31] & ALUOut[31]);
    assign eff_sign = sign^overflow;
    always @(*) begin
    case(ALUCtl)
        4'b0010: ALUOut = A + B;                 // add / addi / lw / sw
        4'b0110: ALUOut = A - B;                 // sub / beq
        4'b0000: ALUOut = A & B;                 // and / andi
        4'b0001: ALUOut = A | B;                 // or  / ori
        4'b0011: ALUOut = A ^ B;                 // xor / xori
        4'b0100: ALUOut = A << B[4:0];           // sll / slli (only first 5 bits of B are used for shifts)
        4'b0101: ALUOut = A >> B[4:0];           // srl / srli (only first 5 bits of B are used for shifts)
        4'b0111: ALUOut = $signed(A) >>> B[4:0]; // sra / srai
        4'b1000: ALUOut = ($signed(A) < $signed(B)) ? 1 : 0; // slt / slti
        4'b1001: ALUOut = (A < B) ? 1 : 0;       // sltu / sltiu
        default: ALUOut = 32'b0;                     
    endcase
    end
endmodule


module ImmGen (
    input [31:0] inst,
    output reg signed [31:0] imm
);
    wire [6:0] opcode = inst[6:0];

    always @(*) begin
        case(opcode)
            7'b0010011: imm = {{20{inst[31]}}, inst[31:20]}; //arithmetic I-type
            7'b0000011: imm = {{20{inst[31]}}, inst[31:20]}; //load I-type (lw)
            7'b0100011: imm = {{20{inst[31]}},inst[31:25],inst[11:7]}; // S-type (sw)
            7'b1100011: imm = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8]}; // SB-type (beq)
            7'b1101111: imm = {{12{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21]}; // UJ-type
            7'b1100111: imm = {{20{inst[31]}}, inst[31:20]}; // I-type (JALR)
            default:
                imm = 32'b0; // default 0 for others
        endcase
    end
endmodule

module ShiftLeftOne (
    input signed [31:0] i,
    output signed [31:0] o
);

   assign o = i << 1;

endmodule

module branch_control(branch, funct3, zero , eff_sign ,branch_taken);
input branch,zero,eff_sign;
input [2:0] funct3;
output reg branch_taken;
always @ (*) begin
    if(branch) begin
        case(funct3) 
        3'b000 : branch_taken = zero ; //beq
        3'b001 : branch_taken = ~zero; //bne
        3'b100 : branch_taken = eff_sign; //blt
        3'b101 : branch_taken = ~eff_sign; //bge
        default : branch_taken = 1'b0;
        endcase
    end
    else begin
        branch_taken = 1'b0;
    end
end
endmodule


module tb_riscv_sc;
// cpu testbench

reg clk;
reg start;

SingleCycleCPU riscv_DUT(clk, start);

// clock generation
initial
    forever #5 clk = ~clk;

initial begin
    // GTKWave dump setup
    $dumpfile("cpu.vcd");  //modifications for GTKWave simulation  
    $dumpvars(0, tb_riscv_sc);      

    clk = 0;
    start = 0;
    #10 start = 1;
    #9000 $finish;
end

endmodule

//final
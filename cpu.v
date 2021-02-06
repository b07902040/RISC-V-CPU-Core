module cpu #( // Do not modify interface
    parameter ADDR_W = 64,
    parameter INST_W = 32,
    parameter DATA_W = 64
)(
    input                   i_clk,
    input                   i_rst_n,
    input                   i_i_valid_inst, // from instruction memory
    input  [ INST_W-1 : 0 ] i_i_inst,       // from instruction memory
    input                   i_d_valid_data, // from data memory
    input  [ DATA_W-1 : 0 ] i_d_data,       // from data memory

    output                  o_i_valid_addr, // to instruction memory
    output [ ADDR_W-1 : 0 ] o_i_addr,       // to instruction memory
    output [ DATA_W-1 : 0 ] o_d_w_data,       // to data memory
    output [ ADDR_W-1 : 0 ] o_d_w_addr,
    output [ ADDR_W-1 : 0 ] o_d_r_addr,       // to data memory
    output                  o_d_MemRead,    // to data memory
    output                  o_d_MemWrite,   // to data memory
    output                  o_finish
);

    //------Wires and Registers------
    
    reg o_i_valid_addr_reg, o_i_valid_addr_wire;
    reg [ ADDR_W-1 : 0 ] o_i_addr_reg, o_i_addr_wire;
    reg [ DATA_W-1 : 0 ] o_d_w_data_reg, o_d_w_data_wire; 
    reg [ ADDR_W-1 : 0 ] o_d_w_addr_reg, o_d_w_addr_wire;
    reg [ ADDR_W-1 : 0 ] o_d_r_addr_reg, o_d_r_addr_wire;
    reg                  o_d_MemRead_reg, o_d_MemRead_wire;
    reg                  o_d_MemWrite_reg, o_d_MemWrite_wire;
    reg                  o_finish_reg, o_finish_wire;
    
    reg [ DATA_W-1 : 0 ] regi_wire[0:32], regi_reg[0:32];
    reg [ 4 : 0 ] inst_copy_wire, inst_copy_reg;
    reg signed [ ADDR_W-1 : 0 ] branch_to;
    integer i;

    //------Continuos Assignments------

    assign o_i_valid_addr = o_i_valid_addr_reg;
    assign o_i_addr = o_i_addr_reg;
    assign o_d_w_data = o_d_w_data_reg;
    assign o_d_w_addr = o_d_w_addr_reg;
    assign o_d_r_addr = o_d_r_addr_reg;
    assign o_d_MemRead = o_d_MemRead_reg;
    assign o_d_MemWrite = o_d_MemWrite_reg;
    assign o_finish = o_finish_reg;

    //------Initial part------

    //------Combinational part------
    always @(*) begin
        o_i_valid_addr_wire = o_i_valid_addr_reg;
        o_i_addr_wire = o_i_addr_reg;
        o_d_w_data_wire = o_d_w_data_reg;
        o_d_w_addr_wire = o_d_w_addr_reg;
        o_d_r_addr_wire = o_d_r_addr_reg;
        o_d_MemRead_wire = o_d_MemRead_reg;
        o_d_MemWrite_wire = o_d_MemWrite_reg;
        o_finish_wire = o_finish_reg;
        inst_copy_wire = inst_copy_reg;
        for ( i = 0; i < 32; i++ ) begin
            regi_wire[i] = regi_reg[i];
        end
        if (i_d_valid_data) begin
            regi_wire[inst_copy_reg] = i_d_data;
            o_i_valid_addr_wire = 1;
            o_i_addr_wire = o_i_addr_reg + 4;
        end
        else begin
            if (i_i_valid_inst) begin
                //$display("inst: %b", i_i_inst);
                case (i_i_inst[6:0])
                    7'b1111111: begin // Stop
                        o_finish_wire = 1;
                    end
                    7'b0010011: begin //no memory operation
                        case (i_i_inst[14:12])
                            3'b000: begin //Addi
                                regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] + i_i_inst[31:20];
                            end
                            3'b100: begin //XORi
                                regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] ^ i_i_inst[31:20];
                            end
                            3'b110: begin //ORi
                                regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] | i_i_inst[31:20];
                            end
                            3'b111: begin //ANDi
                                regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] & i_i_inst[31:20];
                            end
                            3'b001: begin //SLLI
                                regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] << i_i_inst[24:20];
                            end
                            3'b101: begin //SRLI
                                regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] >> i_i_inst[24:20];
                            end
                            default: begin
                                o_finish_wire = 1;
                            end
                        endcase
                        o_i_valid_addr_wire = 1;
                        o_i_addr_wire = o_i_addr_reg + 4; 
                    end
                    7'b0110011: begin
                        case (i_i_inst[14:12])
                            3'b000: begin
                                if (i_i_inst[30] == 0) begin //ADD
                                    regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] + regi_reg[i_i_inst[24:20]];
                                end
                                else begin //SUB
                                    regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] - regi_reg[i_i_inst[24:20]];
                                end
                            end
                            3'b100: begin //XOR
                                regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] ^ regi_reg[i_i_inst[24:20]];
                            end
                            3'b110: begin //OR
                                regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] | regi_reg[i_i_inst[24:20]];
                            end
                            3'b111: begin //AND
                                regi_wire[i_i_inst[11:7]] = regi_reg[i_i_inst[19:15]] & regi_reg[i_i_inst[24:20]];
                            end
                            default: begin
                                o_finish_wire = 1;
                            end
                        endcase
                        o_i_valid_addr_wire = 1;
                        o_i_addr_wire = o_i_addr_reg + 4;  
                    end
                    7'b0100011: begin //SD
                        o_d_MemWrite_wire = 1;
                        o_d_w_addr_wire = regi_reg[i_i_inst[19:15]] + i_i_inst[31:25]*32 + i_i_inst[11:7];
                        o_d_w_data_wire = regi_reg[i_i_inst[24:20]];
                        o_i_valid_addr_wire = 1;
                        o_i_addr_wire = o_i_addr_reg + 4;
                    end
                    7'b0000011: begin //LD
                        o_d_MemRead_wire = 1;
                        o_d_r_addr_wire = regi_reg[i_i_inst[19:15]] + i_i_inst[31:20];
                        inst_copy_wire = i_i_inst[11:7];
                    end
                    7'b1100011: begin
                        if (i_i_inst[14:12] == 3'b000 ) begin // BEQ
                            if ( regi_reg[i_i_inst[24:20]] == regi_reg[i_i_inst[19:15]] ) begin
                                if ( i_i_inst[31] == 1 ) begin
                                    branch_to = {52'b1111111111111111111111111111111111111111111111111111, i_i_inst[7], i_i_inst[30:25], i_i_inst[11:8], 1'b0};
                                end 
                                else begin
                                    branch_to = {52'b0000000000000000000000000000000000000000000000000000, i_i_inst[7], i_i_inst[30:25], i_i_inst[11:8], 1'b0};
                                end
                                o_i_addr_wire = o_i_addr_reg + branch_to;
                            end
                            else begin
                                o_i_addr_wire = o_i_addr_reg + 4; 
                            end
                        end
                        else begin //BNE
                            if ( regi_reg[i_i_inst[24:20]] != regi_reg[i_i_inst[19:15]] ) begin
                                if ( i_i_inst[31] == 1 ) begin
                                    branch_to = {52'b1111111111111111111111111111111111111111111111111111, i_i_inst[7], i_i_inst[30:25], i_i_inst[11:8], 1'b0};
                                end 
                                else begin
                                    branch_to = {52'b0000000000000000000000000000000000000000000000000000, i_i_inst[7], i_i_inst[30:25], i_i_inst[11:8], 1'b0};
                                end
                                o_i_addr_wire = o_i_addr_reg + branch_to;
                                //$display("to %d", o_i_addr_wire);
                                //$display("branch to = %d", branch_to);
                            end
                            else begin
                                o_i_addr_wire = o_i_addr_reg + 4; 
                            end
                        end
                        o_i_valid_addr_wire = 1;
                    end
                    default: begin
                        o_finish_wire = 1;
                    end
                endcase
            end
            else begin
                o_i_valid_addr_wire = 0;
                o_d_MemWrite_wire = 0;
                o_d_MemRead_wire = 0;
            end
        end
    end

    //------Sequential part------
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            // reset
            o_i_valid_addr_reg <= 1;
            o_i_addr_reg <= 0;
            o_d_w_data_reg <= 0;
            o_d_w_addr_reg <= 0;
            o_d_r_addr_reg <= 0;
            o_d_MemRead_reg <= 0;
            o_d_MemWrite_reg <= 0;
            o_finish_reg <= 0;
            for (i = 0; i < 32; i = i+1 ) begin
                regi_reg[i] <= 0;
            end
        end
        else begin
            o_i_valid_addr_reg <= o_i_valid_addr_wire;
            o_i_addr_reg <= o_i_addr_wire;
            o_d_w_data_reg <= o_d_w_data_wire;
            o_d_w_addr_reg <= o_d_w_addr_wire;
            o_d_r_addr_reg <= o_d_r_addr_wire;
            o_d_MemRead_reg <= o_d_MemRead_wire;
            o_d_MemWrite_reg <= o_d_MemWrite_wire;
            o_finish_reg <= o_finish_wire;
            inst_copy_reg <= inst_copy_wire;
            for (i = 0; i < 32; i = i+1 ) begin
                regi_reg[i] <= regi_wire[i];
            end
        end
    end
    
endmodule

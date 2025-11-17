`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2025 05:50:30 PM
// Design Name: 
// Module Name: sccb_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sccb_control(
        //clock!, sda, scl inputs, outputs as well. 
        input logic clk,
        

        input logic start_fsm,
        input logic reset,

        inout wire  sda,
        output wire scl
    );

    
    enum logic [10:0] { 
        s_start,
        s_write,
        ack,
        s_idle
    } curr_state, next_state;

    logic [7:0] reg_addr;
    logic [7:0] reg_data;
    logic [15:0] dout;
    logic [7:0] addr_counter;
    logic [2:0] bit_counter;
    logic [2:0] phase_counter;
    logic [1:0] clk_toggle_counter;

    logic [7:0] start_byte;
    logic endflag;

    logic stopflag;
    //logic addr_or_data; //not doing anything with this rn
    
    assign start_byte = 8'h42;
    assign reg_addr = dout[15:8];
    assign reg_data = dout[7:0];


    always_comb
    begin
        if (reset) begin
        //addr_or_data = 0; // sets it to read only the addr
        addr_counter = 8'b0; //0 to 
        bit_counter = 3'b111; // 7 to 0.
        endflag = 1'b0;
        stopflag = 1'b0;

        phase_counter = 3'b0; //start byte -> addr -> data
        clk_toggle_counter = 2'b0; // scl = 0; -> scl = 1, sda = whatever -> scl = 0;


        end


        next_state = s_idle;
        
        scl = 1; 
        //sda = 0;, probably cant assign?
        reg_addr = 8'h0;
        reset = 0;



        unique case(curr_state)

        s_start:
            begin
                sda = 0;
            end
        
        s_write: begin // FORGOT TO ACCOUNT FOR ACK BIT FML
            if (phase_counter == 3'b0) begin //start byte
                if (clk_toggle_counter == 2'b00) begin            
                    case(bit_counter)
                        3'b111: begin sda = start_byte[7];
                                    bit_counter = 3'b110;
                        end
                        3'b110: begin sda = start_byte[6];
                                    bit_counter = 3'b101;
                        end
                        3'b101: begin sda = start_byte[5];
                                    bit_counter = 3'b100;
                        end
                        3'b100: begin sda = start_byte[4];
                                    bit_counter = 3'b011;
                        end
                        3'b011: begin sda = start_byte[3];
                                    bit_counter = 3'b010;
                        end
                        3'b010: begin sda = start_byte[2];
                                    bit_counter = 3'b001;
                        end
                        3'b001: begin sda = start_byte[1];
                                    bit_counter = 3'b0;
                        end
                        3'b0: begin sda = start_byte[0];
                                    bit_counter = 3'b111;
                                    endflag = 1'b1;
                        end
                        default: begin
                            scl = 0; //wait
                        end

                    endcase
                    scl = 0;
                    clk_toggle_counter = clk_toggle_counter + 1; //move to next
                end
                else if (clk_toggle_counter == 2'b01) begin
                    scl = 1;
                    clk_toggle_counter = clk_toggle_counter + 1;
                end
                else if (clk_toggle_counter == 2'b10) begin
                    scl = 0;
                    clk_toggle_counter = 2'b00; //reset back
                    if (endflag) begin
                        phase_counter = phase_counter + 3'b1;
                        endflag = 1'b0;
                    end
                end 
                else begin end
            end

            else if (phase_counter == 3'b01) begin //ACK BIT OF THE START BYTE
                if (clk_toggle_counter == 2'b00) begin
                    scl = 0;
                    clk_toggle_counter = clk_toggle_counter + 1;
                end
                else if (clk_toggle_counter == 2'b01) begin
                    scl = 1;
                    clk_toggle_counter = clk_toggle_counter + 1;
                end
                else if (clk_toggle_counter == 2'b10) begin
                    scl = 0;
                    clk_toggle_counter = 2'b00;
                    phase_counter = phase_counter + 1;
                end
            end

            else if (phase_counter == 3'b010) begin //ADDRESS // FORGOT TO ACCOUNT FOR ACK BIT FML
                if (clk_toggle_counter == 2'b0) begin
                    scl = 0;
                    clk_toggle_counter = clk_toggle_counter + 1; 
                    case(bit_counter)
                        3'b111: begin sda = reg_addr[7];
                                    bit_counter = 3'b110;
                        end
                        3'b110: begin sda = reg_addr[6];
                                    bit_counter = 3'b101;
                        end
                        3'b101: begin sda = reg_addr[5];
                                    bit_counter = 3'b100;
                        end
                        3'b100: begin sda = reg_addr[4];
                                    bit_counter = 3'b011;
                        end
                        3'b011: begin sda = reg_addr[3];
                                    bit_counter = 3'b010;
                        end
                        3'b010: begin sda = reg_addr[2];
                                    bit_counter = 3'b001;
                        end
                        3'b001: begin sda = reg_addr[1];
                                    bit_counter = 3'b0;
                        end
                        3'b0: begin sda = reg_addr[0];
                                    bit_counter = 3'b111;
                                    endflag = 1'b1;
                        end
                        default: begin
                            scl = 0; //wait
                        end
                    endcase
                end
                else if (clk_toggle_counter == 2'b01) begin
                    scl = 1;
                    clk_toggle_counter = clk_toggle_counter + 1;
                end
                else if (clk_toggle_counter == 2'b10) begin
                    scl = 0;
                    clk_toggle_counter = 2'b0;
                    if (endflag) begin
                        endflag = 0;
                        phase_counter = phase_counter + 3'b01;
                    end
                end
                else begin end
            end

            else if (phase_counter == 3'b011) begin // ack read
                if (clk_toggle_counter == 2'b00) begin
                    scl = 0;
                    clk_toggle_counter = clk_toggle_counter + 1;
                end
                else if (clk_toggle_counter == 2'b01) begin
                    scl = 1;
                    clk_toggle_counter = clk_toggle_counter + 1;
                end
                else if (clk_toggle_counter == 2'b10) begin
                    scl = 0;
                    clk_toggle_counter = 2'b00;
                    phase_counter = phase_counter + 1;
                end
            end

            else if (phase_counter == 3'b100) begin //need to increment addr here. // FORGOT TO ACCOUNT FOR ACK BIT FML
                if (clk_toggle_counter == 2'b00) begin
                    scl = 0;
                    clk_toggle_counter = clk_toggle_counter + 1;
                    case(bit_counter)
                        3'b111: begin sda = reg_data[7];
                                    bit_counter = 3'b110;
                        end
                        3'b110: begin sda = reg_data[6];
                                    bit_counter = 3'b101;
                        end
                        3'b101: begin sda = reg_data[5];
                                    bit_counter = 3'b100;
                        end
                        3'b100: begin sda = reg_data[4];
                                    bit_counter = 3'b011;
                        end
                        3'b011: begin sda = reg_data[3];
                                    bit_counter = 3'b010;
                        end
                        3'b010: begin sda = reg_data[2];
                                    bit_counter = 3'b001;
                        end
                        3'b001: begin sda = reg_data[1];
                                    bit_counter = 3'b0;
                        end
                        3'b0: begin sda = reg_data[0];
                                    bit_counter = 3'b111;
                                    endflag = 1'b1;
                        end
                        default: begin
                            scl = 0; //wait
                        end
                    endcase
                end
                else if (clk_toggle_counter == 2'b01) begin
                    scl = 1;
                    clk_toggle_counter = clk_toggle_counter + 1;
                end
                else if (clk_toggle_counter == 2'b10) begin
                    scl = 0;
                    clk_toggle_counter = 2'b0;
                    //addr_counter = addr_counter + 8'b00000001;
                    if (endflag) begin
                        endflag = 0;
                        phase_counter = phase_counter + 1;
                    end
                end
            end
            else if (phase_counter == 3'b011) begin // ack read
                if (clk_toggle_counter == 2'b00) begin
                    scl = 0;
                    clk_toggle_counter = clk_toggle_counter + 1;
                end
                else if (clk_toggle_counter == 2'b01) begin
                    scl = 1;
                    clk_toggle_counter = clk_toggle_counter + 1;
                end
                else if (clk_toggle_counter == 2'b10) begin
                    scl = 0;
                    clk_toggle_counter = 2'b00;
                    phase_counter = 3'b0;
                    addr_counter = addr_counter + 8'b00000001;
                end
            end

            else begin scl = 0;// wait state
            end



            end
        s_stop: begin
            if (stopflag) begin
                sda = 1;
            end 
            else begin
                scl = 1;
                stopflag = 1;
            end
            
        end




            



            
        endcase

        case (curr_state)
            s_idle: if (start_fsm) begin
                next_state = s_start;
            end else begin
                next_state = s_idle;
            end
            s_start: if (!sda) begin
                next_state = s_write;
            end
            else begin
                next_state = s_start;
            end

            s_write: begin 
                if (addr_counter <= 8'd72) begin
                    next_state = s_write;
                end
                else begin
                    next_state = s_stop;
                end
            end

            s_stop: begin
                if (scl && sda) begin
                    next_state = s_idle;
                end
                else begin
                    next_state = s_stop;
                end
            end            

            // s_ack: if (!sda) begin
            //     addr_or_data = ~addr_or_data; //switch to addr or data
            //     next_state = s_write_0;

            // end else begin
            //     next_state = s_idle;
            // end

        endcase
    end

    always_ff @(posedge clk)
    begin
        curr_state <= next_state;
    end

     OV7670_config_rom camera_rom(
        .clk(clk),
        .addr(addr),
        .dout(dout)
    )

endmodule

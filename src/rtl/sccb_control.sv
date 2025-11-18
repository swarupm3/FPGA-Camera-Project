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
        input logic xclk,
        

        input logic start_fsm,
        input logic reset,

        inout wire  sda,
        output wire scl
    );

    
    enum logic [2:0] { 
        s_start,
        s_write,
        s_idle,
        s_ack,
        s_stop
    } curr_state, next_state;

    logic [15:0] dout;
    logic [7:0] reg_addr;
    logic [7:0] reg_data;
    
    
    
    
    //BASED ON ROM FORMAT
    assign reg_addr = dout[15:8];
    assign reg_data = dout[7:0];


    //HARD CODED ADDR 0x42 TO WRITE TO
    logic [7:0] addr_42;
    assign addr_42 = 8'h42;

    //COUNTERS
    logic [6:0] rom_addr_counter;
    logic [1:0] write_byte_counter;
    logic [2:0] write_bit_counter;
    logic [1:0] write_phase_counter;


    always_comb
    begin

        next_state = s_idle;
        
        //initalize counters
        rom_addr_counter = 7'd0;
        write_byte_counter = 2'd0;
        write_bit_counter = 3'd7;
        write_phase_counter = 2'd0;

        scl = 1'bz;
        sda = 1'bz;

        //state descriptions
        unique case(curr_state)
            s_start:
            begin
                scl = 1'bz;
                sda = 1'b0;
            end
            s_stop:
            begin
                scl = 1'bz;
                sda = 1'bz;
                rom_addr_counter = rom_addr_counter + 7'd1;
                write_byte_counter = 2'd0;
            end
            s_ack:
                write_bit_counter = 3'd7;
                write_byte_counter = write_byte_counter + 2'd1;
            s_write:
            begin
                case(write_phase_counter)
                    2'd0:
                    begin
                        scl = 1'b0;
                        write_phase_counter = write_phase_counter + 2'd1;
                    end
                    2'd1:
                        case (write_byte_counter)
                            2'd0:
                                sda = addr_42[write_bit_counter];
                            2'd1:
                                sda = reg_addr[write_bit_counter];
                            2'd2:
                                sda = reg_data[write_bit_counter];
                            default: 
                                sda = addr_42[write_bit_counter];
                        endcase
                        write_phase_counter = write_phase_counter + 2'd1;
                    2'd2:
                    begin
                        scl = 1'bz;
                        write_phase_counter = 2'b0;
                        write_bit_counter = write_bit_counter - 3'd1;
                    end
                    default:
                        scl = 1'bz;
                endcase
            end
            s_idle:
            begin
                scl = 1'bz;
                sda = 1'bz;
                rom_addr_counter = 7'd0;
                write_byte_counter = 2'd0;
            end        
        endcase


        //transitions
        case (curr_state)
            s_idle: 
                next_state = start_fsm ? s_start : s_idle;
            s_start:
                next_state = s_write;
            s_write:
                next_state = (write_bit_counter == 3'd0 && write_phase_counter == 2'd0) ? s_ack : s_write;
            s_ack:
                next_state = (write_byte_counter == 2'd2 || sda == 1'bz) ? s_stop : s_write;    //may need to use sda_in rather than directly sda for ACK/NACK
            s_stop:
                next_state = (rom_addr_counter == 7'd72 || sda == 1'bz) ? s_idle : s_start;     //may need to use sda_in rather than directly sda for ACK/NACK

        endcase
    end

    always_ff @(posedge xclk)
    begin
        curr_state <= next_state;
    end

     OV7670_config_rom camera_rom(
        .clk(clk),
        .addr(rom_addr_counter),
        .dout(dout)
    )

endmodule

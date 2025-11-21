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
        output logic scl,
        output logic write_flag
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
    logic [7:0] rom_addr_counter, rom_addr_counter_next;
    logic [1:0] write_byte_counter, write_byte_counter_next;
    logic [2:0] write_bit_counter, write_bit_counter_next;
    logic [1:0] write_phase_counter, write_phase_counter_next;


    //CLOCK DIVISION
    localparam int SCL_DIV = 67;                                
    logic [$clog2(SCL_DIV)-1:0] scl_div_cnt;                    


    //PRESET ROM
    OV7670_config_rom camera_rom(
        .clk(xclk),
        .addr(rom_addr_counter),
        .dout(dout)
    );


    //OPEN DRAIN SETUP
    
    
    logic sda_drive_low;    
    wire  sda_in;           
    
    assign sda = (sda_drive_low && ~write_flag) ? 1'b0 : 1'bz; 
    assign sda_in = sda;                         

    
    
    
    
    always_comb
    begin

        next_state = s_idle;
        
        //INITIALIZE COUNTERS
        rom_addr_counter_next = rom_addr_counter;
        write_byte_counter_next = write_byte_counter;
        write_bit_counter_next = write_bit_counter;
        write_phase_counter_next = write_phase_counter;
        
        
        

//        scl = 1'bz;
//        sda_drive_low = 1'b0;

        //STATE DESCRIPTIONS AND ACTIONS 
        unique case(curr_state)
            s_start:
            begin
                scl = 1'bz;
                sda_drive_low = 1'b1;
            end
            s_stop:
            begin
                scl = 1'bz;
                sda_drive_low = 1'b0;
                rom_addr_counter_next = rom_addr_counter + 8'd1;
                write_byte_counter_next = 2'd0;
            end
            s_ack:
            begin
                case(write_phase_counter)
                    2'd0:
                    begin
                        scl = 1'b0;
                        sda_drive_low = 1'b1;
                        write_phase_counter_next = write_phase_counter + 2'd1;
                    end
                    2'd1:
                    begin
//                        scl = 1'bz;
                        sda_drive_low = 1'b0;
                        write_phase_counter_next = write_phase_counter + 2'd1;
                    end
                    2'd2:
                    begin
                        scl = 1'bz;
                        //sda_drive_low = 1'b1;
                        write_phase_counter_next = 2'b0;
                        write_bit_counter_next = 3'd7;
                        write_byte_counter_next = write_byte_counter + 2'd1;
                    end
                    default:
                        scl = 1'bz;
                endcase
            end
            s_write:
            begin
                case(write_phase_counter)
                    2'd0:
                    begin
                        scl = 1'b0;
                        write_phase_counter_next = write_phase_counter + 2'd1;
                    end
                    2'd1:
                    begin
//                        scl = 1'b0;
                        case (write_byte_counter)
                            2'd0:
                                sda_drive_low = ~addr_42[write_bit_counter];
                            2'd1:
                                sda_drive_low = ~reg_addr[write_bit_counter];
                            2'd2:
                                sda_drive_low = ~reg_data[write_bit_counter];
                            default: 
                                sda_drive_low = ~addr_42[write_bit_counter];
                        endcase
                        write_phase_counter_next = write_phase_counter + 2'd1;
                    end
                    2'd2:
                    begin
                        scl = 1'bz;
                        write_phase_counter_next = 2'b0;
                        write_bit_counter_next = write_bit_counter - 3'd1;
                    end
                    default:
                        scl = 1'bz;
                endcase
            end
            s_idle:
            begin
                scl = 1'bz;
                sda_drive_low = 1'b1; // changed to make this hiZ, for tb
                rom_addr_counter_next = 8'd0;
                write_byte_counter_next = 2'd0;
                write_bit_counter_next = 3'd7;
                write_phase_counter_next = 2'd0;
              
            end        
        endcase

        //STATE TRANSITIONS
        case (curr_state)
            s_idle: 
                next_state = start_fsm ? s_start : s_idle;
            s_start:
                next_state = s_write;
            s_write:
                next_state = (write_bit_counter == 3'd0 && write_phase_counter == 2'd2) ? s_ack : s_write;
            s_ack:
            begin
               if (write_byte_counter == 2'd2 && write_phase_counter == 2'd2 ) begin
                next_state = s_stop;
               end else if (write_byte_counter != 2'd2 && write_phase_counter == 2'd2 ) begin
                next_state = s_write;
               end else begin
                next_state = s_ack;
               end
            end   
            s_stop: begin
                next_state = (rom_addr_counter == 8'd72) ? s_idle : s_start;  
//                if (rom_addr_counter == 8'd72) begin
//                    write_flag = 1'b1;
//                end 
            end  

        endcase
    end

    //SEQUENTIAL LOGIC
    always_ff @(posedge xclk)
    begin
        if (reset) begin
        curr_state <= s_idle;
        rom_addr_counter <= 8'd0;
        write_byte_counter <= 2'd0;
        write_bit_counter <= 3'd7;
        write_phase_counter <= 2'd0;
        scl_div_cnt <= '0;
        write_flag <= 1'b0;
        
        
        end else begin
        if (scl_div_cnt == SCL_DIV-1) begin   
        scl_div_cnt <= '0;        
        curr_state <= next_state;
        rom_addr_counter <= rom_addr_counter_next;
        write_byte_counter <= write_byte_counter_next;
        write_bit_counter <= write_bit_counter_next;
        write_phase_counter <= write_phase_counter_next;
        

        
        end else begin
            scl_div_cnt  <= scl_div_cnt + 1'b1;
        end
        end
        if ((scl_div_cnt == SCL_DIV-1) && (curr_state == s_stop) && (rom_addr_counter == 8'd72))begin
            write_flag <=1'b1;
        end
    end

endmodule

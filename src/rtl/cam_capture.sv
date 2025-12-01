`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2025 05:50:30 PM
// Design Name: 
// Module Name: cam_capture
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


module cam_capture(
        input logic pclk,
        input logic href,
        input logic vsync,
        input logic [7:0] cam_data,
        input logic config_done,
        input logic reset,

        output logic [9:0] x_coord,
        output logic [9:0] y_coord,
        output logic [7:0] pixel_data,
        output logic pixel_valid
    );


    enum logic [1:0] { 
        s_idle,
        s_write,
        s_end_row,
        s_end_frame
    } curr_state, next_state;


    //INITALIZE COUNTERS
    logic [9:0] x_coord_next;
    logic [9:0] y_coord_next;
    logic write_counter, write_counter_next;
    logic [7:0] pixel_data_next;
    
    logic config_done_next;
    logic pixel_valid_next;

    always_comb
        begin
        
        x_coord_next = x_coord;
        y_coord_next = y_coord;
        write_counter_next = write_counter;
        pixel_data_next = pixel_data;
        pixel_valid_next = 1'd0;


        unique case(curr_state)
            s_idle:
            begin
                write_counter_next = 1'b0;
            end
            s_write:
                case(write_counter)
                1'b0:
                    begin
                        pixel_data_next = cam_data;
                        write_counter_next = 1'b1;
                        x_coord_next = x_coord + 10'd1;
                        pixel_valid_next = 1'b1;
                    end
                1'b1:
                    begin
                        write_counter_next = 1'b0;
                        pixel_valid_next = 1'b0;
                    end
                endcase
            s_end_row:
                begin
                    x_coord_next = 10'd0;
                    y_coord_next = y_coord + 10'd1;
                    write_counter_next = 1'b0;
                end
            s_end_frame:
                begin
                    x_coord_next = 10'd0;
                    y_coord_next = 10'd0;
                    write_counter_next = 1'b0;
                end
        endcase

        //STATE TRANSITIONS
        case (curr_state)
            s_idle:
                if (vsync) begin
                    next_state = s_end_frame;
                end else begin
                    next_state = (config_done && href) ? s_write : s_idle;
                end
            s_write:
                begin
                    if (vsync) begin
                        next_state = s_end_frame;
                    end 
                    else if (~href) begin
                        next_state = s_end_row;
                    end else begin
                        next_state = s_write;
                    end
                end
            s_end_row:
                next_state = (href) ? s_write : s_idle;
            s_end_frame:
                next_state = (vsync) ? s_idle : s_write;
        endcase
    end

    //SEQUENTIAL LOGIC
    always_ff @(posedge pclk or posedge reset)
    begin
        if (reset) begin 
            curr_state <= s_idle;
            x_coord <= 10'd0;
            y_coord <= 10'd0;
            write_counter <= 1'd0;
            pixel_data <= 8'd0;
            pixel_valid <= 1'd0;
        end else begin
            curr_state <= next_state;
            x_coord <= x_coord_next;
            y_coord <= y_coord_next;
            write_counter <= write_counter_next;
            pixel_data <= pixel_data_next;
            pixel_valid <= pixel_valid_next;
        end
    end

endmodule

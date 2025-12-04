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


module cam_capture_UV(
        input logic pclk,
        input logic href,
        input logic vsync,
        input logic [7:0] cam_data,
        input logic config_done,
        input logic reset,
        input logic frame_ack_pclk,

        output logic [9:0] min_x,
        output logic [9:0] max_x,
        output logic [9:0] min_y,
        output logic [9:0] max_y,
        output logic endframe
    );


    enum logic [1:0] { 
        s_idle,
        s_write,
        s_end_row,
        s_end_frame
    } curr_state, next_state;


    //INITALIZE COUNTERS
    logic [9:0] x_coord, y_coord;
    logic [9:0] x_coord_next;
    logic [9:0] y_coord_next;
    logic [1:0] write_counter, write_counter_next;
    logic [7:0] temp_u_next, temp_v_next, temp_u, temp_v;
    logic endframe_next;
    
    logic config_done_next;
    

    always_comb
        begin
        
        x_coord_next = x_coord;
        y_coord_next = y_coord;
        write_counter_next = write_counter;
        temp_u_next = temp_u;
        temp_v_next = temp_v;
        endframe_next = 1'b0;
        //pixel_data_next = pixel_data;


        unique case(curr_state)
            s_idle:
            begin
                write_counter_next = 2'b0;
            end
            s_write:
                case(write_counter)
                2'b0:
                    begin
                        write_counter_next = 2'b01; //THIS IS THE 1ST Y byte
                        endframe_next = 1'b0;
                    end
                2'b1:
                    begin
                        write_counter_next = 2'b10; //THIS IS U byte
                        temp_u_next = cam_data;
                        endframe_next = 1'b0;
                    end
                2'b10:
                    begin
                        write_counter_next = 2'b11; //THIS IS THE 2ND Y BYTE
                        endframe_next = 1'b0;
                    end
                2'b11:
                    begin
                        write_counter_next = 2'b0; //THIS IS THE V byte
                        temp_v_next = cam_data;
                        x_coord_next = x_coord + 10'd2;
                        endframe_next = 1'b0;
                    end
                endcase
            s_end_row:
                begin
                    x_coord_next = 10'd0;
                    y_coord_next = y_coord + 10'd1;
                    write_counter_next = 2'b0;
                    endframe_next = 1'b0;
                end
            s_end_frame:
                begin
                    x_coord_next = 10'd0;
                    y_coord_next = 10'd0;
                    write_counter_next = 2'b0;
                    endframe_next = 1'b1;
                    
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
    
    
    logic signed [10:0] du, dv;
    logic [21:0] du_sq, dv_sq;        // du_sq up to ~21025 -> fits in 16 bits, give slack
    logic [31:0] ellipse_val;         // large enough for weighted sum

    always_comb begin
        // sign-extend temps to signed and subtract centers
        du = $signed({3'b000, temp_u}) - 11'sd110;   // 11-bit signed
        dv = $signed({3'b000, temp_v}) - 11'sd150;
        // square and cast to unsigned before weighting
        du_sq = $unsigned(du * du);    // up to ~21025
        dv_sq = $unsigned(dv * dv);    // up to ~21025
        ellipse_val = (du_sq * 32'd400) + (dv_sq * 32'd1600); // up to ~ (21025*1600)*2 ~ 67M < 2^26
    end
    
    //SEQUENTIAL LOGIC
    always_ff @(posedge pclk or posedge reset)
    begin
        if (reset) begin 
            curr_state <= s_idle;
            x_coord <= 10'd0;
            y_coord <= 10'd0;
            write_counter <= 2'd0;
            endframe <= 1'b0;
            temp_u <= 8'b0;
            temp_v <= 8'b0;
            min_x <= 10'd641;
            max_x <= 10'b0;
            min_y <= 10'd641;
            max_y <= 10'b0;
//            pixel_data <= 8'd0;
//            pixel_valid <= 1'd0;
        end 
        else begin
            //if (write_counter == 2'b11 && temp_u >= 8'd77 && temp_u <= 8'd127 && temp_v >= 8'd133 && temp_v <= 8'd173) begin
            if (write_counter == 2'b11 && ellipse_val < 32'd640000) begin
                max_x <= (x_coord > max_x) ? x_coord: max_x;
                min_x <= (x_coord < min_x) ? x_coord: min_x;
                max_y <= (y_coord > max_y) ? y_coord: max_y;
                min_y <= (y_coord < min_y) ? y_coord: min_y;

                curr_state <= next_state;
                x_coord <= x_coord_next;
                y_coord <= y_coord_next;
                write_counter <= write_counter_next;
                temp_u <= temp_u_next;
                temp_v <= temp_v_next;
                endframe <= endframe_next;
            end
            else begin
                max_x <= max_x;
                min_x <= min_x;
                max_y <= max_y;
                min_y <= min_y;
                curr_state <= next_state;
                x_coord <= x_coord_next;
                y_coord <= y_coord_next;
                write_counter <= write_counter_next;
                temp_u <= temp_u_next;
                temp_v <= temp_v_next;
                endframe <= endframe_next;
            end
            if (curr_state == s_end_frame) begin
                endframe <= 1'b1;
            end
            if (endframe && frame_ack_pclk) begin
                endframe <=1'b0;
                min_x <= 10'd641;
                max_x <= 10'b0;
                min_y <= 10'd641;
                max_y <= 10'b0;
                
        
        
            end
        end
    end

endmodule

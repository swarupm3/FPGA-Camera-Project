`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2025 05:50:30 PM
// Design Name: 
// Module Name: cam_capture_UV
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


module bounding_boxes(
        input logic pclk,
        input logic href,
        input logic vsync,
        input logic [7:0] cam_data,
        input logic config_done,
        input logic reset,
        
        
        input logic [7:0] u,
        input logic [7:0] v,
        
        // 12 regions: 4 columns (x0..x3) × 3 rows (y0..y2)
        output logic [9:0] min_x_x0_y0,
        output logic [9:0] min_x_x1_y0,
        output logic [9:0] min_x_x2_y0,
        output logic [9:0] min_x_x3_y0,

        output logic [9:0] min_x_x0_y1,
        output logic [9:0] min_x_x1_y1,
        output logic [9:0] min_x_x2_y1,
        output logic [9:0] min_x_x3_y1,

        output logic [9:0] min_x_x0_y2,
        output logic [9:0] min_x_x1_y2,
        output logic [9:0] min_x_x2_y2,
        output logic [9:0] min_x_x3_y2,
        
        output logic [9:0] max_x_x0_y0,
        output logic [9:0] max_x_x1_y0,
        output logic [9:0] max_x_x2_y0,
        output logic [9:0] max_x_x3_y0,

        output logic [9:0] max_x_x0_y1,
        output logic [9:0] max_x_x1_y1,
        output logic [9:0] max_x_x2_y1,
        output logic [9:0] max_x_x3_y1,

        output logic [9:0] max_x_x0_y2,
        output logic [9:0] max_x_x1_y2,
        output logic [9:0] max_x_x2_y2,
        output logic [9:0] max_x_x3_y2,
        
        output logic [9:0] min_y_x0_y0,
        output logic [9:0] min_y_x1_y0,
        output logic [9:0] min_y_x2_y0,
        output logic [9:0] min_y_x3_y0,

        output logic [9:0] min_y_x0_y1,
        output logic [9:0] min_y_x1_y1,
        output logic [9:0] min_y_x2_y1,
        output logic [9:0] min_y_x3_y1,

        output logic [9:0] min_y_x0_y2,
        output logic [9:0] min_y_x1_y2,
        output logic [9:0] min_y_x2_y2,
        output logic [9:0] min_y_x3_y2,
        
        output logic [9:0] max_y_x0_y0,
        output logic [9:0] max_y_x1_y0,
        output logic [9:0] max_y_x2_y0,
        output logic [9:0] max_y_x3_y0,

        output logic [9:0] max_y_x0_y1,
        output logic [9:0] max_y_x1_y1,
        output logic [9:0] max_y_x2_y1,
        output logic [9:0] max_y_x3_y1,

        output logic [9:0] max_y_x0_y2,
        output logic [9:0] max_y_x1_y2,
        output logic [9:0] max_y_x2_y2,
        output logic [9:0] max_y_x3_y2,
        
        output logic [9:0] x_coord,
        output logic [9:0] y_coord,
        output logic skin_valid,
        output logic skin_valid_2,
        output logic pixel_valid
        
    );

    enum logic [1:0] { 
        s_idle,
        s_write,
        s_end_row,
        s_end_frame
    } curr_state, next_state;

    logic skin_valid;
    logic pixel_valid;
    logic skin_valid_2;

    // INITALIZE COUNTERS
    logic [9:0] x_coord, y_coord;
    logic [9:0] x_coord_next;
    logic [9:0] y_coord_next;
    logic [1:0] write_counter, write_counter_next;
    logic [7:0] temp_u_next, temp_v_next, temp_u, temp_v, temp_y_next, temp_y;
    
    logic config_done_next;
    assign skin_valid = ( temp_u >= 8'd113 && temp_u <= 8'd190 && temp_v >= 8'd113 && temp_v <= 8'd190 ) ? 1:0;
    assign skin_valid_2 = ( temp_u >= 8'd95 && temp_u <= 8'd110 && temp_v >= 8'd145 && temp_v <= 8'd160 ) ? 1:0;
    assign pixel_valid = 1'b1;

    always_comb begin
        x_coord_next = x_coord;
        y_coord_next = y_coord;
        write_counter_next = write_counter;
        temp_u_next = temp_u;
        temp_v_next = temp_v;
        temp_y_next = temp_y;

        unique case(curr_state)
            s_idle: begin
                write_counter_next = 2'b0;
            end
            s_write:
                case(write_counter)
                2'b0: begin
                        write_counter_next = 2'b01; //THIS IS THE 1ST Y byte
                        temp_y_next = cam_data;
                    end
                2'b1: begin
                        write_counter_next = 2'b10; //THIS IS U byte
                        temp_u_next = cam_data;
                        x_coord_next = x_coord + 10'd1;
                    end
                2'b10: begin
                        write_counter_next = 2'b11; //THIS IS THE 2ND Y BYTE
                        temp_y_next = cam_data;
                    end
                2'b11: begin
                        write_counter_next = 2'b0; //THIS IS THE V byte
                        temp_v_next = cam_data;
                        x_coord_next = x_coord + 10'd1;
                    end
                endcase
            s_end_row: begin
                    x_coord_next = 10'd0;
                    y_coord_next = y_coord + 10'd1;
                    write_counter_next = 2'b0;
                end
            s_end_frame: begin
                    x_coord_next = 10'd0;
                    y_coord_next = 10'd0;
                    write_counter_next = 2'b0;
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
            s_write: begin
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

    logic [9:0] denoise_count;
    logic [9:0] denoise_param;
    logic [9:0] wiggle_room;
    
    logic signed [10:0] du, dv;
    logic [21:0] du_sq, dv_sq;
    logic [31:0] ellipse_val;

    //SEQUENTIAL LOGIC
    always_ff @(posedge pclk or posedge reset) begin
        if (reset || vsync) begin 
            curr_state <= s_idle;
            x_coord <= 10'd0;
            y_coord <= 10'd0;
            write_counter <= 2'd0;
            temp_u <= 8'b0;
            temp_v <= 8'b0;
            temp_y <=8'b0;

            // initialize all 12 region minima to sentinel (no-data)
            min_x_x0_y0 <= 10'd641; min_x_x1_y0 <= 10'd641; min_x_x2_y0 <= 10'd641; min_x_x3_y0 <= 10'd641;
            min_x_x0_y1 <= 10'd641; min_x_x1_y1 <= 10'd641; min_x_x2_y1 <= 10'd641; min_x_x3_y1 <= 10'd641;
            min_x_x0_y2 <= 10'd641; min_x_x1_y2 <= 10'd641; min_x_x2_y2 <= 10'd641; min_x_x3_y2 <= 10'd641;

            max_x_x0_y0 <= 10'd0; max_x_x1_y0 <= 10'd0; max_x_x2_y0 <= 10'd0; max_x_x3_y0 <= 10'd0;
            max_x_x0_y1 <= 10'd0; max_x_x1_y1 <= 10'd0; max_x_x2_y1 <= 10'd0; max_x_x3_y1 <= 10'd0;
            max_x_x0_y2 <= 10'd0; max_x_x1_y2 <= 10'd0; max_x_x2_y2 <= 10'd0; max_x_x3_y2 <= 10'd0;

            min_y_x0_y0 <= 10'd641; min_y_x1_y0 <= 10'd641; min_y_x2_y0 <= 10'd641; min_y_x3_y0 <= 10'd641;
            min_y_x0_y1 <= 10'd641; min_y_x1_y1 <= 10'd641; min_y_x2_y1 <= 10'd641; min_y_x3_y1 <= 10'd641;
            min_y_x0_y2 <= 10'd641; min_y_x1_y2 <= 10'd641; min_y_x2_y2 <= 10'd641; min_y_x3_y2 <= 10'd641;

            max_y_x0_y0 <= 10'd0; max_y_x1_y0 <= 10'd0; max_y_x2_y0 <= 10'd0; max_y_x3_y0 <= 10'd0;
            max_y_x0_y1 <= 10'd0; max_y_x1_y1 <= 10'd0; max_y_x2_y1 <= 10'd0; max_y_x3_y1 <= 10'd0;
            max_y_x0_y2 <= 10'd0; max_y_x1_y2 <= 10'd0; max_y_x2_y2 <= 10'd0; max_y_x3_y2 <= 10'd0;

            //denoise_count <= 10'b0;
        end 
        else begin
            // check skin_valid_2 at write_counter == 0 (same timing as before)
            if (write_counter == 2'b00 && temp_u >= 8'd95 && temp_u <= 8'd110 && temp_v >= 8'd145 && temp_v <= 8'd160 ) begin
                // Determine region by column (x0..x3) and row (y0..y2).
                // Column boundaries: x0: 0..159, x1:160..319, x2:320..479, x3:480..639
                // Row boundaries: y0: 0..159, y1:160..319, y2:320..479

                // --- Row 0 (y 0..159)
                if (y_coord <= 10'd159) begin
                    // x0
                    if (x_coord <= 10'd159) begin
                        min_x_x0_y0 <= (x_coord < min_x_x0_y0 && x_coord <= 10'd159 && y_coord <= 10'd159) ? x_coord : min_x_x0_y0;
                        max_x_x0_y0 <= (x_coord > max_x_x0_y0 && x_coord <= 10'd159 && y_coord <= 10'd159) ? x_coord : max_x_x0_y0;
                        min_y_x0_y0 <= (y_coord < min_y_x0_y0 && x_coord <= 10'd159 && y_coord <= 10'd159) ? y_coord : min_y_x0_y0;
                        max_y_x0_y0 <= (y_coord > max_y_x0_y0 && x_coord <= 10'd159 && y_coord <= 10'd159) ? y_coord : max_y_x0_y0;
                    end
                    // x1
                    else if (x_coord >= 10'd160 && x_coord <= 10'd319) begin
                        min_x_x1_y0 <= (x_coord < min_x_x1_y0 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord <= 10'd159) ? x_coord : min_x_x1_y0;
                        max_x_x1_y0 <= (x_coord > max_x_x1_y0 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord <= 10'd159) ? x_coord : max_x_x1_y0;
                        min_y_x1_y0 <= (y_coord < min_y_x1_y0 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord <= 10'd159) ? y_coord : min_y_x1_y0;
                        max_y_x1_y0 <= (y_coord > max_y_x1_y0 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord <= 10'd159) ? y_coord : max_y_x1_y0;
                    end
                    // x2
                    else if (x_coord >= 10'd320 && x_coord <= 10'd479) begin
                        min_x_x2_y0 <= (x_coord < min_x_x2_y0 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord <= 10'd159) ? x_coord : min_x_x2_y0;
                        max_x_x2_y0 <= (x_coord > max_x_x2_y0 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord <= 10'd159) ? x_coord : max_x_x2_y0;
                        min_y_x2_y0 <= (y_coord < min_y_x2_y0 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord <= 10'd159) ? y_coord : min_y_x2_y0;
                        max_y_x2_y0 <= (y_coord > max_y_x2_y0 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord <= 10'd159) ? y_coord : max_y_x2_y0;
                    end
                    // x3
                    else if (x_coord >= 10'd480 && x_coord <= 10'd639) begin
                        min_x_x3_y0 <= (x_coord < min_x_x3_y0 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord <= 10'd159) ? x_coord : min_x_x3_y0;
                        max_x_x3_y0 <= (x_coord > max_x_x3_y0 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord <= 10'd159) ? x_coord : max_x_x3_y0;
                        min_y_x3_y0 <= (y_coord < min_y_x3_y0 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord <= 10'd159) ? y_coord : min_y_x3_y0;
                        max_y_x3_y0 <= (y_coord > max_y_x3_y0 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord <= 10'd159) ? y_coord : max_y_x3_y0;
                    end
                end

                // --- Row 1 (y 160..319)
                else if (y_coord >= 10'd160 && y_coord <= 10'd319) begin
                    // x0
                    if (x_coord <= 10'd159) begin
                        min_x_x0_y1 <= (x_coord < min_x_x0_y1 && x_coord <= 10'd159 && y_coord >= 10'd160 && y_coord <= 10'd319) ? x_coord : min_x_x0_y1;
                        max_x_x0_y1 <= (x_coord > max_x_x0_y1 && x_coord <= 10'd159 && y_coord >= 10'd160 && y_coord <= 10'd319) ? x_coord : max_x_x0_y1;
                        min_y_x0_y1 <= (y_coord < min_y_x0_y1 && x_coord <= 10'd159 && y_coord >= 10'd160 && y_coord <= 10'd319) ? y_coord : min_y_x0_y1;
                        max_y_x0_y1 <= (y_coord > max_y_x0_y1 && x_coord <= 10'd159 && y_coord >= 10'd160 && y_coord <= 10'd319) ? y_coord : max_y_x0_y1;
                    end
                    // x1
                    else if (x_coord >= 10'd160 && x_coord <= 10'd319) begin
                        min_x_x1_y1 <= (x_coord < min_x_x1_y1 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord >= 10'd160 && y_coord <= 10'd319) ? x_coord : min_x_x1_y1;
                        max_x_x1_y1 <= (x_coord > max_x_x1_y1 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord >= 10'd160 && y_coord <= 10'd319) ? x_coord : max_x_x1_y1;
                        min_y_x1_y1 <= (y_coord < min_y_x1_y1 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord >= 10'd160 && y_coord <= 10'd319) ? y_coord : min_y_x1_y1;
                        max_y_x1_y1 <= (y_coord > max_y_x1_y1 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord >= 10'd160 && y_coord <= 10'd319) ? y_coord : max_y_x1_y1;
                    end
                    // x2
                    else if (x_coord >= 10'd320 && x_coord <= 10'd479) begin
                        min_x_x2_y1 <= (x_coord < min_x_x2_y1 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord >= 10'd160 && y_coord <= 10'd319) ? x_coord : min_x_x2_y1;
                        max_x_x2_y1 <= (x_coord > max_x_x2_y1 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord >= 10'd160 && y_coord <= 10'd319) ? x_coord : max_x_x2_y1;
                        min_y_x2_y1 <= (y_coord < min_y_x2_y1 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord >= 10'd160 && y_coord <= 10'd319) ? y_coord : min_y_x2_y1;
                        max_y_x2_y1 <= (y_coord > max_y_x2_y1 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord >= 10'd160 && y_coord <= 10'd319) ? y_coord : max_y_x2_y1;
                    end
                    // x3
                    else if (x_coord >= 10'd480 && x_coord <= 10'd639) begin
                        min_x_x3_y1 <= (x_coord < min_x_x3_y1 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord >= 10'd160 && y_coord <= 10'd319) ? x_coord : min_x_x3_y1;
                        max_x_x3_y1 <= (x_coord > max_x_x3_y1 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord >= 10'd160 && y_coord <= 10'd319) ? x_coord : max_x_x3_y1;
                        min_y_x3_y1 <= (y_coord < min_y_x3_y1 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord >= 10'd160 && y_coord <= 10'd319) ? y_coord : min_y_x3_y1;
                        max_y_x3_y1 <= (y_coord > max_y_x3_y1 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord >= 10'd160 && y_coord <= 10'd319) ? y_coord : max_y_x3_y1;
                    end
                end

                // --- Row 2 (y 320..479)
                else if (y_coord >= 10'd320 && y_coord <= 10'd479) begin
                    // x0
                    if (x_coord <= 10'd159) begin
                        min_x_x0_y2 <= (x_coord < min_x_x0_y2 && x_coord <= 10'd159 && y_coord >= 10'd320 && y_coord <= 10'd479) ? x_coord : min_x_x0_y2;
                        max_x_x0_y2 <= (x_coord > max_x_x0_y2 && x_coord <= 10'd159 && y_coord >= 10'd320 && y_coord <= 10'd479) ? x_coord : max_x_x0_y2;
                        min_y_x0_y2 <= (y_coord < min_y_x0_y2 && x_coord <= 10'd159 && y_coord >= 10'd320 && y_coord <= 10'd479) ? y_coord : min_y_x0_y2;
                        max_y_x0_y2 <= (y_coord > max_y_x0_y2 && x_coord <= 10'd159 && y_coord >= 10'd320 && y_coord <= 10'd479) ? y_coord : max_y_x0_y2;
                    end
                    // x1
                    else if (x_coord >= 10'd160 && x_coord <= 10'd319) begin
                        min_x_x1_y2 <= (x_coord < min_x_x1_y2 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord >= 10'd320 && y_coord <= 10'd479) ? x_coord : min_x_x1_y2;
                        max_x_x1_y2 <= (x_coord > max_x_x1_y2 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord >= 10'd320 && y_coord <= 10'd479) ? x_coord : max_x_x1_y2;
                        min_y_x1_y2 <= (y_coord < min_y_x1_y2 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord >= 10'd320 && y_coord <= 10'd479) ? y_coord : min_y_x1_y2;
                        max_y_x1_y2 <= (y_coord > max_y_x1_y2 && x_coord >= 10'd160 && x_coord <= 10'd319 && y_coord >= 10'd320 && y_coord <= 10'd479) ? y_coord : max_y_x1_y2;
                    end
                    // x2
                    else if (x_coord >= 10'd320 && x_coord <= 10'd479) begin
                        min_x_x2_y2 <= (x_coord < min_x_x2_y2 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord >= 10'd320 && y_coord <= 10'd479) ? x_coord : min_x_x2_y2;
                        max_x_x2_y2 <= (x_coord > max_x_x2_y2 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord >= 10'd320 && y_coord <= 10'd479) ? x_coord : max_x_x2_y2;
                        min_y_x2_y2 <= (y_coord < min_y_x2_y2 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord >= 10'd320 && y_coord <= 10'd479) ? y_coord : min_y_x2_y2;
                        max_y_x2_y2 <= (y_coord > max_y_x2_y2 && x_coord >= 10'd320 && x_coord <= 10'd479 && y_coord >= 10'd320 && y_coord <= 10'd479) ? y_coord : max_y_x2_y2;
                    end
                    // x3
                    else if (x_coord >= 10'd480 && x_coord <= 10'd639) begin
                        min_x_x3_y2 <= (x_coord < min_x_x3_y2 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord >= 10'd320 && y_coord <= 10'd479) ? x_coord : min_x_x3_y2;
                        max_x_x3_y2 <= (x_coord > max_x_x3_y2 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord >= 10'd320 && y_coord <= 10'd479) ? x_coord : max_x_x3_y2;
                        min_y_x3_y2 <= (y_coord < min_y_x3_y2 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord >= 10'd320 && y_coord <= 10'd479) ? y_coord : min_y_x3_y2;
                        max_y_x3_y2 <= (y_coord > max_y_x3_y2 && x_coord >= 10'd480 && x_coord <= 10'd639 && y_coord >= 10'd320 && y_coord <= 10'd479) ? y_coord : max_y_x3_y2;
                    end
                end

                // update state and registers (same as before)
                curr_state <= next_state;
                x_coord <= x_coord_next;
                y_coord <= y_coord_next;
                write_counter <= write_counter_next;
                temp_u <= temp_u_next;
                temp_v <= temp_v_next;
                temp_y <= temp_y_next;
                denoise_count <= 10'd0;
            end
            else begin
                // no skin: keep everything
                min_x_x0_y0 <= min_x_x0_y0; min_x_x1_y0 <= min_x_x1_y0; min_x_x2_y0 <= min_x_x2_y0; min_x_x3_y0 <= min_x_x3_y0;
                min_x_x0_y1 <= min_x_x0_y1; min_x_x1_y1 <= min_x_x1_y1; min_x_x2_y1 <= min_x_x2_y1; min_x_x3_y1 <= min_x_x3_y1;
                min_x_x0_y2 <= min_x_x0_y2; min_x_x1_y2 <= min_x_x1_y2; min_x_x2_y2 <= min_x_x2_y2; min_x_x3_y2 <= min_x_x3_y2;

                max_x_x0_y0 <= max_x_x0_y0; max_x_x1_y0 <= max_x_x1_y0; max_x_x2_y0 <= max_x_x2_y0; max_x_x3_y0 <= max_x_x3_y0;
                max_x_x0_y1 <= max_x_x0_y1; max_x_x1_y1 <= max_x_x1_y1; max_x_x2_y1 <= max_x_x2_y1; max_x_x3_y1 <= max_x_x3_y1;
                max_x_x0_y2 <= max_x_x0_y2; max_x_x1_y2 <= max_x_x1_y2; max_x_x2_y2 <= max_x_x2_y2; max_x_x3_y2 <= max_x_x3_y2;

                min_y_x0_y0 <= min_y_x0_y0; min_y_x1_y0 <= min_y_x1_y0; min_y_x2_y0 <= min_y_x2_y0; min_y_x3_y0 <= min_y_x3_y0;
                min_y_x0_y1 <= min_y_x0_y1; min_y_x1_y1 <= min_y_x1_y1; min_y_x2_y1 <= min_y_x2_y1; min_y_x3_y1 <= min_y_x3_y1;
                min_y_x0_y2 <= min_y_x0_y2; min_y_x1_y2 <= min_y_x1_y2; min_y_x2_y2 <= min_y_x2_y2; min_y_x3_y2 <= min_y_x3_y2;

                max_y_x0_y0 <= max_y_x0_y0; max_y_x1_y0 <= max_y_x1_y0; max_y_x2_y0 <= max_y_x2_y0; max_y_x3_y0 <= max_y_x3_y0;
                max_y_x0_y1 <= max_y_x0_y1; max_y_x1_y1 <= max_y_x1_y1; max_y_x2_y1 <= max_y_x2_y1; max_y_x3_y1 <= max_y_x3_y1;
                max_y_x0_y2 <= max_y_x0_y2; max_y_x1_y2 <= max_y_x1_y2; max_y_x2_y2 <= max_y_x2_y2; max_y_x3_y2 <= max_y_x3_y2;

                curr_state <= next_state;
                x_coord <= x_coord_next;
                y_coord <= y_coord_next;
                write_counter <= write_counter_next;
                temp_u <= temp_u_next;
                temp_v <= temp_v_next;
                temp_y <= temp_y_next;
                denoise_count <= 10'b0;
            end
        end
    end

endmodule

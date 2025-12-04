`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2025 10:51:27 AM
// Design Name: 
// Module Name: camera_top_level
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


module camera_top_level(
        input clk,      //100MHz Clock from FPGA
        //CAMERA INPUTS
        input pclk,     //24MHz Clock from Camera
        input reset,
        input cam_href,
        input cam_vsync,
        input [7:0] cam_data,
        input start_fsm,
        input pwdn,
        

        //CAMERA OUTPUTS
        inout sda,
        output xclk,
        output scl,
        

        //HDMI
        output logic hdmi_tmds_clk_n,
        output logic hdmi_tmds_clk_p,
        output logic [2:0]hdmi_tmds_data_n,
        output logic [2:0]hdmi_tmds_data_p,
        
        output logic [7:0]  hex_seg_a,
        output logic [3:0]  hex_grid_a,
        output logic [7:0]  hex_seg_b,
        output logic [3:0]  hex_grid_b
        
    );
    
    

   
    logic vga_clk, clk_125MHz;
    logic locked;
    logic [9:0] drawX, drawY, x_coord, y_coord;
    logic [18:0] cam_pixel_idx, vga_pixel_idx;
    logic [7:0] pixel_data;
    logic pixel_valid;
    logic hsync, vsync, vde;
    logic config_done;
//    logic start_fsm_debounced, reset_debounced;
    logic [6:0] doutb;
    logic [6:0] dina;
    logic [9:0] max_x, max_y, min_x, min_y;
    logic [9:0] max_x_new, max_y_new, min_x_new, min_y_new;
    logic endframe;

    assign pwdn = 1'b0;
    assign cam_pixel_idx = y_coord * 640 + x_coord;
    assign vga_pixel_idx = drawY * 640 + drawX;
    assign dina = pixel_data[7:1];
    
//    assign min_x = 10'd160;
//    assign max_x = 10'd480;
//    assign min_y = 10'd120;
//    assign max_y = 10'd360;
    
    logic [6:0] red_block, dout_red;
    logic frame_ack_pclk;
    always_comb begin
        if (drawY == min_y_new && drawX <= max_x_new && drawX >= min_x_new) begin
            red_block = 7'b0; 
            dout_red = 7'b1111111;
        end 
        else if (drawY == max_y_new && drawX <= max_x_new && drawX >= min_x_new) begin
            red_block = 7'b0; 
            dout_red = 7'b1111111;
        end
        else if (drawX == min_x_new && drawY <= max_y_new && drawY >= min_y_new) begin
            red_block = 7'b0; 
            dout_red = 7'b1111111;            
        end
        else if (drawX == max_x_new && drawY <= max_y_new && drawY >= min_y_new) begin
            red_block = 7'b0; 
            dout_red = 7'b1111111;            
        end
        else begin
            red_block = 7'b1111111;
            dout_red = 7'b0;
        end       
    end
    
    
    
    
    clk_wiz_0 clk_wiz (
        .clk_out1(xclk),
        .clk_out2(vga_clk),
        .clk_out3(clk_125MHz),
        .reset(reset),
        .locked(locked),
        .clk_in1(clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(vga_clk),
        .reset(reset),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(vga_clk),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset),
        //Color and Sync Signals
        .red(doutb | dout_red),
        .green(doutb & red_block),
        .blue(doutb & red_block),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );
    
    blk_mem_gen_0 bram(
        .clka(pclk), //CAMERA  pclk
        .addra(cam_pixel_idx),
        .dina(dina), //dina
        .ena(1'b1),
        .wea(pixel_valid),     //cam_href & config_done
        
        .clkb(vga_clk), //VGA
        .addrb(vga_pixel_idx),
        .doutb(doutb),
        .enb(1'b1)
    );
    
    sccb_control control_unit (
        .xclk(xclk),
        .start_fsm(start_fsm),
        .reset(reset),
        .sda(sda),
        .scl(scl),
        .write_flag(config_done)
    );

    cam_capture cam_capture_unit(
        .pclk(pclk),
        .href(cam_href),
        .vsync(cam_vsync),
        .cam_data(cam_data),
        .config_done(config_done),
        .reset(reset),
        

        .x_coord(x_coord),
        .y_coord(y_coord),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid)
    );

    cam_capture_UV find_x_y(
        .pclk(pclk),
        .href(cam_href),
        .vsync(cam_vsync),
        .cam_data(cam_data),
        .config_done(config_done),
        .reset(reset),
        .frame_ack_pclk(frame_ack_pclk),
        
        .min_x(min_x),
        .max_x(max_x),
        .min_y(min_y),
        .max_y(max_y),
        .endframe(endframe)
        
    );
    
    
    logic endframe_pclk;            // alias: endframe from cam_capture_UV (pclk domain)
    logic endframe_sync0, endframe_sync1; // two-flop sync into clk domain
    logic endframe_sync_prev;
    logic frame_ack_clk;            // single-cycle ack in clk domain
    logic frame_ack_pclk_sync0, frame_ack_pclk; // clk->pclk synchronization
    
    // sampled (clk-domain) copies of pclk min/max
    logic [9:0] sampled_min_x, sampled_min_y, sampled_max_x, sampled_max_y;
    
    // connect endframe input (already named endframe from instantiation)
    assign endframe_pclk = endframe;
    
    
    always_ff @(posedge clk) begin
        if (reset) begin
            endframe_sync0 <= 1'b0;
            endframe_sync1 <= 1'b0;
            endframe_sync_prev <= 1'b0;
        end
        else begin
            endframe_sync0 <= endframe_pclk;
            endframe_sync1 <= endframe_sync0;
        end
    end
    // Edge detect in clk domain and latch pclk-side coordinates (which are held stable by cam_capture_UV)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sampled_min_x <= 10'd0;
            sampled_min_y <= 10'd641;
            sampled_max_x <= 10'd0;
            sampled_max_y <= 10'd641;
            frame_ack_clk <= 1'b0;
            endframe_sync_prev <= 1'b0;
        end else begin
            if (endframe_sync1 && ~endframe_sync_prev) begin
                // latch the pclk values (they are stable during endframe)
                sampled_min_x <= min_x;
                sampled_min_y <= min_y;
                sampled_max_x <= max_x;
                sampled_max_y <= max_y;
                frame_ack_clk <= 1'b1; // single-cycle ack
            end else begin
                frame_ack_clk <= 1'b0;
            end
            endframe_sync_prev <= endframe_sync1;
        end
    end

    // send ack back to pclk domain (two-flop sync)
    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            frame_ack_pclk_sync0 <= 1'b0;
            frame_ack_pclk <= 1'b0;
        end else begin
            frame_ack_pclk_sync0 <= frame_ack_clk;
            frame_ack_pclk <= frame_ack_pclk_sync0;
        end
    end

    // Now update *_new using sampled values
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            max_x_new <= 10'd0;
            max_y_new <= 10'd0;
            min_x_new <= 10'd641;
            min_y_new <= 10'd641;
        end else begin
            if (sampled_min_x != 10'd641 && sampled_min_y != 10'd641) begin
                max_x_new <= sampled_max_x;
                max_y_new <= sampled_max_y;
                min_x_new <= sampled_min_x;
                min_y_new <= sampled_min_y;
            end else begin
                max_x_new <= 10'd641;
                max_y_new <= 10'd641;
                min_x_new <= 10'd641;
                min_y_new <= 10'd641;
            end
        end
    end
    
    hex_driver debug_max_x( // LEFT
        .clk(clk),
        .reset(reset),
        .in({4'b1111,{2'b0, max_x[9:8]},max_x[7:4], max_x[3:0]}),
        .hex_seg(hex_seg_a),
        .hex_grid(hex_grid_a)
    );
    
    hex_driver debug_max_y( //RIGHT
        .clk(clk),
        .reset(reset),
        .in({4'b0, {2'b0,min_x[9:8]},min_x[7:4], min_x[3:0]}),
        .hex_seg(hex_seg_b),
        .hex_grid(hex_grid_b)
    );
    

endmodule


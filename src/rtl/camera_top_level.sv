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
        input logic pclk,     //24MHz Clock from Camera
        input logic reset,
        input logic cam_href,
        input logic cam_vsync,
        input logic [7:0] cam_data,
        input logic start_fsm,
        input logic pwdn,
        
        //SKIN/EDGE TOGGLES
        input logic toggle_edge,
        input logic toggle_skin,
        input  logic [15:0] sw_i,
        

        //CAMERA OUTPUTS
        inout logic sda,
        output logic xclk,
        output logic scl,
        
        //Potentiometer
        input logic VP,
        input logic VN,
        
        //LEDS
        output logic [6:0] B_out,

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
    logic [9:0] drawX, drawY, x_coord, y_coord, x_coord_UV, y_coord_UV;
    logic [18:0] cam_pixel_idx, vga_pixel_idx;
    logic [7:0] pixel_data;
    logic pixel_valid, pixel_valid_UV;
    logic hsync, vsync, vde;
    logic config_done;
    logic [6:0] pot_out;
//    logic start_fsm_debounced, reset_debounced;
    logic [6:0] doutb;
    logic [6:0] dina;
    logic [9:0] max_x, max_y, min_x, min_y;
    logic [9:0] max_x_new, max_y_new, min_x_new, min_y_new;
    
    // NEW 12-region signals from cam_capture_UV (min/max x/y)
    logic [9:0] min_x_x0_y0, min_x_x1_y0, min_x_x2_y0, min_x_x3_y0;
    logic [9:0] min_x_x0_y1, min_x_x1_y1, min_x_x2_y1, min_x_x3_y1;
    logic [9:0] min_x_x0_y2, min_x_x1_y2, min_x_x2_y2, min_x_x3_y2;

    logic [9:0] max_x_x0_y0, max_x_x1_y0, max_x_x2_y0, max_x_x3_y0;
    logic [9:0] max_x_x0_y1, max_x_x1_y1, max_x_x2_y1, max_x_x3_y1;
    logic [9:0] max_x_x0_y2, max_x_x1_y2, max_x_x2_y2, max_x_x3_y2;

    logic [9:0] min_y_x0_y0, min_y_x1_y0, min_y_x2_y0, min_y_x3_y0;
    logic [9:0] min_y_x0_y1, min_y_x1_y1, min_y_x2_y1, min_y_x3_y1;
    logic [9:0] min_y_x0_y2, min_y_x1_y2, min_y_x2_y2, min_y_x3_y2;

    logic [9:0] max_y_x0_y0, max_y_x1_y0, max_y_x2_y0, max_y_x3_y0;
    logic [9:0] max_y_x0_y1, max_y_x1_y1, max_y_x2_y1, max_y_x3_y1;
    logic [9:0] max_y_x0_y2, max_y_x1_y2, max_y_x2_y2, max_y_x3_y2;

    // NEW sampled (clk-domain) per-region signals
    logic [9:0] sampled_min_x_x0_y0, sampled_min_x_x1_y0, sampled_min_x_x2_y0, sampled_min_x_x3_y0;
    logic [9:0] sampled_min_x_x0_y1, sampled_min_x_x1_y1, sampled_min_x_x2_y1, sampled_min_x_x3_y1;
    logic [9:0] sampled_min_x_x0_y2, sampled_min_x_x1_y2, sampled_min_x_x2_y2, sampled_min_x_x3_y2;

    logic [9:0] sampled_max_x_x0_y0, sampled_max_x_x1_y0, sampled_max_x_x2_y0, sampled_max_x_x3_y0;
    logic [9:0] sampled_max_x_x0_y1, sampled_max_x_x1_y1, sampled_max_x_x2_y1, sampled_max_x_x3_y1;
    logic [9:0] sampled_max_x_x0_y2, sampled_max_x_x1_y2, sampled_max_x_x2_y2, sampled_max_x_x3_y2;

    logic [9:0] sampled_min_y_x0_y0, sampled_min_y_x1_y0, sampled_min_y_x2_y0, sampled_min_y_x3_y0;
    logic [9:0] sampled_min_y_x0_y1, sampled_min_y_x1_y1, sampled_min_y_x2_y1, sampled_min_y_x3_y1;
    logic [9:0] sampled_min_y_x0_y2, sampled_min_y_x1_y2, sampled_min_y_x2_y2, sampled_min_y_x3_y2;

    logic [9:0] sampled_max_y_x0_y0, sampled_max_y_x1_y0, sampled_max_y_x2_y0, sampled_max_y_x3_y0;
    logic [9:0] sampled_max_y_x0_y1, sampled_max_y_x1_y1, sampled_max_y_x2_y1, sampled_max_y_x3_y1;
    logic [9:0] sampled_max_y_x0_y2, sampled_max_y_x1_y2, sampled_max_y_x2_y2, sampled_max_y_x3_y2;

    assign pwdn = 1'b0;
    assign cam_pixel_idx = toggle_edge ? (y_coord_UV*640 + x_coord_UV):(y_coord * 640 + x_coord);
    assign vga_pixel_idx = drawY * 640 + drawX;
    //assign dina = pixel_data[7:1];
 
    logic [13:0] mult;        // product is up to 14 bits
    logic [6:0] bright_pixel; // final 7-bit pixel

    assign mult = pixel_data[7:1] * pot_out;
    
    // fixed-point scaling: divide by 128 → shift right by 7
    assign bright_pixel = mult[13:7];
    assign dina = toggle_edge ? ((toggle_skin ? skin_valid_2:skin_valid) ? 7'h0: 7'h3F) : bright_pixel;
    //assign dina = (skin_valid) ? 7'h3F: 7'b0;
    
//    assign min_x_new = 10'd641;
//    assign max_x_new = 10'd480;
//    assign min_y_new = 10'd641;
//    assign max_y_new = 10'd0;
    
    logic [6:0] red_block, dout_red;
    
    assign B_out = pot_out;
    
        
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
        .wea(toggle_edge ? pixel_valid_UV: pixel_valid),     //cam_href & config_done
        
        .clkb(vga_clk), //VGA
        .addrb(vga_pixel_idx),
        .doutb(doutb),
        .enb(1'b1)
    );
    
    cam_init control_unit (
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

    // updated instantiation - wire up all 12 region ports
    bounding_boxes find_x_y(
        .pclk(pclk),
        .href(cam_href),
        .vsync(cam_vsync),
        .cam_data(cam_data),
        .config_done(config_done),
        .reset(reset),
        
        .u(sw_i[15:8]),
        .v(sw_i[7:0]),
        
        .min_x_x0_y0(min_x_x0_y0),
        .min_x_x1_y0(min_x_x1_y0),
        .min_x_x2_y0(min_x_x2_y0),
        .min_x_x3_y0(min_x_x3_y0),

        .min_x_x0_y1(min_x_x0_y1),
        .min_x_x1_y1(min_x_x1_y1),
        .min_x_x2_y1(min_x_x2_y1),
        .min_x_x3_y1(min_x_x3_y1),

        .min_x_x0_y2(min_x_x0_y2),
        .min_x_x1_y2(min_x_x1_y2),
        .min_x_x2_y2(min_x_x2_y2),
        .min_x_x3_y2(min_x_x3_y2),

        .max_x_x0_y0(max_x_x0_y0),
        .max_x_x1_y0(max_x_x1_y0),
        .max_x_x2_y0(max_x_x2_y0),
        .max_x_x3_y0(max_x_x3_y0),

        .max_x_x0_y1(max_x_x0_y1),
        .max_x_x1_y1(max_x_x1_y1),
        .max_x_x2_y1(max_x_x2_y1),
        .max_x_x3_y1(max_x_x3_y1),

        .max_x_x0_y2(max_x_x0_y2),
        .max_x_x1_y2(max_x_x1_y2),
        .max_x_x2_y2(max_x_x2_y2),
        .max_x_x3_y2(max_x_x3_y2),

        .min_y_x0_y0(min_y_x0_y0),
        .min_y_x1_y0(min_y_x1_y0),
        .min_y_x2_y0(min_y_x2_y0),
        .min_y_x3_y0(min_y_x3_y0),

        .min_y_x0_y1(min_y_x0_y1),
        .min_y_x1_y1(min_y_x1_y1),
        .min_y_x2_y1(min_y_x2_y1),
        .min_y_x3_y1(min_y_x3_y1),

        .min_y_x0_y2(min_y_x0_y2),
        .min_y_x1_y2(min_y_x1_y2),
        .min_y_x2_y2(min_y_x2_y2),
        .min_y_x3_y2(min_y_x3_y2),

        .max_y_x0_y0(max_y_x0_y0),
        .max_y_x1_y0(max_y_x1_y0),
        .max_y_x2_y0(max_y_x2_y0),
        .max_y_x3_y0(max_y_x3_y0),

        .max_y_x0_y1(max_y_x0_y1),
        .max_y_x1_y1(max_y_x1_y1),
        .max_y_x2_y1(max_y_x2_y1),
        .max_y_x3_y1(max_y_x3_y1),

        .max_y_x0_y2(max_y_x0_y2),
        .max_y_x1_y2(max_y_x1_y2),
        .max_y_x2_y2(max_y_x2_y2),
        .max_y_x3_y2(max_y_x3_y2),
        
        .x_coord(x_coord_UV),
        .y_coord(y_coord_UV),
        .skin_valid(skin_valid),
        .skin_valid_2(skin_valid_2),
        .pixel_valid(pixel_valid_UV)
    );
    
    adc analog_to_digital(
    .clk(clk),
    .reset(reset),
    .VP(VP),
    .VN(VN),
    .pot_out(pot_out)
    );

   
    logic [9:0] sampled_min_x, sampled_min_y, sampled_max_x, sampled_max_y;
    logic [7:0] delay_max_x;
    
    //detect edge of vsync
    logic vsync0,vsync1;
    always_ff @(posedge clk) begin
        vsync0 <= vsync;
        vsync1 <= vsync0;
    end
    assign vsync_rise = ~vsync0 & vsync1;
    
    
    // Edge detect in clk domain and latch pclk-side quadrant coordinates (held stable by cam_capture_UV)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // initialize all sampled 12 regions to invalid sentinel
            sampled_min_x_x0_y0 <= 10'd641; sampled_max_x_x0_y0 <= 10'd0; sampled_min_y_x0_y0 <= 10'd641; sampled_max_y_x0_y0 <= 10'd0;
            sampled_min_x_x1_y0 <= 10'd641; sampled_max_x_x1_y0 <= 10'd0; sampled_min_y_x1_y0 <= 10'd641; sampled_max_y_x1_y0 <= 10'd0;
            sampled_min_x_x2_y0 <= 10'd641; sampled_max_x_x2_y0 <= 10'd0; sampled_min_y_x2_y0 <= 10'd641; sampled_max_y_x2_y0 <= 10'd0;
            sampled_min_x_x3_y0 <= 10'd641; sampled_max_x_x3_y0 <= 10'd0; sampled_min_y_x3_y0 <= 10'd641; sampled_max_y_x3_y0 <= 10'd0;

            sampled_min_x_x0_y1 <= 10'd641; sampled_max_x_x0_y1 <= 10'd0; sampled_min_y_x0_y1 <= 10'd641; sampled_max_y_x0_y1 <= 10'd0;
            sampled_min_x_x1_y1 <= 10'd641; sampled_max_x_x1_y1 <= 10'd0; sampled_min_y_x1_y1 <= 10'd641; sampled_max_y_x1_y1 <= 10'd0;
            sampled_min_x_x2_y1 <= 10'd641; sampled_max_x_x2_y1 <= 10'd0; sampled_min_y_x2_y1 <= 10'd641; sampled_max_y_x2_y1 <= 10'd0;
            sampled_min_x_x3_y1 <= 10'd641; sampled_max_x_x3_y1 <= 10'd0; sampled_min_y_x3_y1 <= 10'd641; sampled_max_y_x3_y1 <= 10'd0;

            sampled_min_x_x0_y2 <= 10'd641; sampled_max_x_x0_y2 <= 10'd0; sampled_min_y_x0_y2 <= 10'd641; sampled_max_y_x0_y2 <= 10'd0;
            sampled_min_x_x1_y2 <= 10'd641; sampled_max_x_x1_y2 <= 10'd0; sampled_min_y_x1_y2 <= 10'd641; sampled_max_y_x1_y2 <= 10'd0;
            sampled_min_x_x2_y2 <= 10'd641; sampled_max_x_x2_y2 <= 10'd0; sampled_min_y_x2_y2 <= 10'd641; sampled_max_y_x2_y2 <= 10'd0;
            sampled_min_x_x3_y2 <= 10'd641; sampled_max_x_x3_y2 <= 10'd0; sampled_min_y_x3_y2 <= 10'd641; sampled_max_y_x3_y2 <= 10'd0;

            sampled_min_x <= 10'd0;
            sampled_min_y <= 10'd641;
            sampled_max_x <= 10'd0;
            sampled_max_y <= 10'd641;
            delay_max_x <= 8'b0;
        end else begin
            if (vsync_rise && delay_max_x == 8'h4 ) begin
                // latch each of 12 regions
                sampled_min_x_x0_y0 <= min_x_x0_y0;
                sampled_max_x_x0_y0 <= max_x_x0_y0;
                sampled_min_y_x0_y0 <= min_y_x0_y0;
                sampled_max_y_x0_y0 <= max_y_x0_y0;

                sampled_min_x_x1_y0 <= min_x_x1_y0;
                sampled_max_x_x1_y0 <= max_x_x1_y0;
                sampled_min_y_x1_y0 <= min_y_x1_y0;
                sampled_max_y_x1_y0 <= max_y_x1_y0;

                sampled_min_x_x2_y0 <= min_x_x2_y0;
                sampled_max_x_x2_y0 <= max_x_x2_y0;
                sampled_min_y_x2_y0 <= min_y_x2_y0;
                sampled_max_y_x2_y0 <= max_y_x2_y0;

                sampled_min_x_x3_y0 <= min_x_x3_y0;
                sampled_max_x_x3_y0 <= max_x_x3_y0;
                sampled_min_y_x3_y0 <= min_y_x3_y0;
                sampled_max_y_x3_y0 <= max_y_x3_y0;

                sampled_min_x_x0_y1 <= min_x_x0_y1;
                sampled_max_x_x0_y1 <= max_x_x0_y1;
                sampled_min_y_x0_y1 <= min_y_x0_y1;
                sampled_max_y_x0_y1 <= max_y_x0_y1;

                sampled_min_x_x1_y1 <= min_x_x1_y1;
                sampled_max_x_x1_y1 <= max_x_x1_y1;
                sampled_min_y_x1_y1 <= min_y_x1_y1;
                sampled_max_y_x1_y1 <= max_y_x1_y1;

                sampled_min_x_x2_y1 <= min_x_x2_y1;
                sampled_max_x_x2_y1 <= max_x_x2_y1;
                sampled_min_y_x2_y1 <= min_y_x2_y1;
                sampled_max_y_x2_y1 <= max_y_x2_y1;

                sampled_min_x_x3_y1 <= min_x_x3_y1;
                sampled_max_x_x3_y1 <= max_x_x3_y1;
                sampled_min_y_x3_y1 <= min_y_x3_y1;
                sampled_max_y_x3_y1 <= max_y_x3_y1;

                sampled_min_x_x0_y2 <= min_x_x0_y2;
                sampled_max_x_x0_y2 <= max_x_x0_y2;
                sampled_min_y_x0_y2 <= min_y_x0_y2;
                sampled_max_y_x0_y2 <= max_y_x0_y2;

                sampled_min_x_x1_y2 <= min_x_x1_y2;
                sampled_max_x_x1_y2 <= max_x_x1_y2;
                sampled_min_y_x1_y2 <= min_y_x1_y2;
                sampled_max_y_x1_y2 <= max_y_x1_y2;

                sampled_min_x_x2_y2 <= min_x_x2_y2;
                sampled_max_x_x2_y2 <= max_x_x2_y2;
                sampled_min_y_x2_y2 <= min_y_x2_y2;
                sampled_max_y_x2_y2 <= max_y_x2_y2;

                sampled_min_x_x3_y2 <= min_x_x3_y2;
                sampled_max_x_x3_y2 <= max_x_x3_y2;
                sampled_min_y_x3_y2 <= min_y_x3_y2;
                sampled_max_y_x3_y2 <= max_y_x3_y2;

                // also keep legacy single sampled box for backward compatibility (optional)
                sampled_min_x <= 10'd0;
                sampled_min_y <= 10'd641;
                sampled_max_x <= 10'd0;
                sampled_max_y <= 10'd641;

                delay_max_x <= 8'b0;
            end 
            else if (vsync_rise && delay_max_x == 8'h4) begin
                // duplicate branch preserved from original (no-op)
                delay_max_x <= 8'b0;
            end
            else if (vsync_rise && delay_max_x != 8'h4) begin
                delay_max_x <= delay_max_x + 8'b1;
            end
            else begin
                // nothing
            end
        end
    end

    // small-blob filter: estimated pixel count threshold (tuneable via sw_i[3:0] if you want)
    localparam int SMALL_PIXEL_THRESH_DEFAULT = 16;
    logic [15:0] small_thresh;
    // make threshold adjustable by switches (low 4 bits), or use default if zero
    assign small_thresh = (sw_i[14:0] != 15'd0) ? {15'd0, sw_i[14:0]} : SMALL_PIXEL_THRESH_DEFAULT;

    // compute widths/heights and area for each of 12 regions (combinational)
    logic [10:0] width_x0_y0, height_x0_y0; logic [21:0] area_x0_y0;
    logic [10:0] width_x1_y0, height_x1_y0; logic [21:0] area_x1_y0;
    logic [10:0] width_x2_y0, height_x2_y0; logic [21:0] area_x2_y0;
    logic [10:0] width_x3_y0, height_x3_y0; logic [21:0] area_x3_y0;

    logic [10:0] width_x0_y1, height_x0_y1; logic [21:0] area_x0_y1;
    logic [10:0] width_x1_y1, height_x1_y1; logic [21:0] area_x1_y1;
    logic [10:0] width_x2_y1, height_x2_y1; logic [21:0] area_x2_y1;
    logic [10:0] width_x3_y1, height_x3_y1; logic [21:0] area_x3_y1;

    logic [10:0] width_x0_y2, height_x0_y2; logic [21:0] area_x0_y2;
    logic [10:0] width_x1_y2, height_x1_y2; logic [21:0] area_x1_y2;
    logic [10:0] width_x2_y2, height_x2_y2; logic [21:0] area_x2_y2;
    logic [10:0] width_x3_y2, height_x3_y2; logic [21:0] area_x3_y2;

    always_comb begin
        // x0_y0
        if (sampled_min_x_x0_y0 != 10'd641 && sampled_max_x_x0_y0 >= sampled_min_x_x0_y0 &&
            sampled_min_y_x0_y0 != 10'd641 && sampled_max_y_x0_y0 >= sampled_min_y_x0_y0) begin
            width_x0_y0  = sampled_max_x_x0_y0 - sampled_min_x_x0_y0 + 11'd1;
            height_x0_y0 = sampled_max_y_x0_y0 - sampled_min_y_x0_y0 + 11'd1;
            area_x0_y0   = width_x0_y0 * height_x0_y0;
        end else begin
            width_x0_y0 = 11'd0; height_x0_y0 = 11'd0; area_x0_y0 = 22'd0;
        end

        // x1_y0
        if (sampled_min_x_x1_y0 != 10'd641 && sampled_max_x_x1_y0 >= sampled_min_x_x1_y0 &&
            sampled_min_y_x1_y0 != 10'd641 && sampled_max_y_x1_y0 >= sampled_min_y_x1_y0) begin
            width_x1_y0  = sampled_max_x_x1_y0 - sampled_min_x_x1_y0 + 11'd1;
            height_x1_y0 = sampled_max_y_x1_y0 - sampled_min_y_x1_y0 + 11'd1;
            area_x1_y0   = width_x1_y0 * height_x1_y0;
        end else begin
            width_x1_y0 = 11'd0; height_x1_y0 = 11'd0; area_x1_y0 = 22'd0;
        end

        // x2_y0
        if (sampled_min_x_x2_y0 != 10'd641 && sampled_max_x_x2_y0 >= sampled_min_x_x2_y0 &&
            sampled_min_y_x2_y0 != 10'd641 && sampled_max_y_x2_y0 >= sampled_min_y_x2_y0) begin
            width_x2_y0  = sampled_max_x_x2_y0 - sampled_min_x_x2_y0 + 11'd1;
            height_x2_y0 = sampled_max_y_x2_y0 - sampled_min_y_x2_y0 + 11'd1;
            area_x2_y0   = width_x2_y0 * height_x2_y0;
        end else begin
            width_x2_y0 = 11'd0; height_x2_y0 = 11'd0; area_x2_y0 = 22'd0;
        end

        // x3_y0
        if (sampled_min_x_x3_y0 != 10'd641 && sampled_max_x_x3_y0 >= sampled_min_x_x3_y0 &&
            sampled_min_y_x3_y0 != 10'd641 && sampled_max_y_x3_y0 >= sampled_min_y_x3_y0) begin
            width_x3_y0  = sampled_max_x_x3_y0 - sampled_min_x_x3_y0 + 11'd1;
            height_x3_y0 = sampled_max_y_x3_y0 - sampled_min_y_x3_y0 + 11'd1;
            area_x3_y0   = width_x3_y0 * height_x3_y0;
        end else begin
            width_x3_y0 = 11'd0; height_x3_y0 = 11'd0; area_x3_y0 = 22'd0;
        end

        // x0_y1
        if (sampled_min_x_x0_y1 != 10'd641 && sampled_max_x_x0_y1 >= sampled_min_x_x0_y1 &&
            sampled_min_y_x0_y1 != 10'd641 && sampled_max_y_x0_y1 >= sampled_min_y_x0_y1) begin
            width_x0_y1  = sampled_max_x_x0_y1 - sampled_min_x_x0_y1 + 11'd1;
            height_x0_y1 = sampled_max_y_x0_y1 - sampled_min_y_x0_y1 + 11'd1;
            area_x0_y1   = width_x0_y1 * height_x0_y1;
        end else begin
            width_x0_y1 = 11'd0; height_x0_y1 = 11'd0; area_x0_y1 = 22'd0;
        end

        // x1_y1
        if (sampled_min_x_x1_y1 != 10'd641 && sampled_max_x_x1_y1 >= sampled_min_x_x1_y1 &&
            sampled_min_y_x1_y1 != 10'd641 && sampled_max_y_x1_y1 >= sampled_min_y_x1_y1) begin
            width_x1_y1  = sampled_max_x_x1_y1 - sampled_min_x_x1_y1 + 11'd1;
            height_x1_y1 = sampled_max_y_x1_y1 - sampled_min_y_x1_y1 + 11'd1;
            area_x1_y1   = width_x1_y1 * height_x1_y1;
        end else begin
            width_x1_y1 = 11'd0; height_x1_y1 = 11'd0; area_x1_y1 = 22'd0;
        end

        // x2_y1
        if (sampled_min_x_x2_y1 != 10'd641 && sampled_max_x_x2_y1 >= sampled_min_x_x2_y1 &&
            sampled_min_y_x2_y1 != 10'd641 && sampled_max_y_x2_y1 >= sampled_min_y_x2_y1) begin
            width_x2_y1  = sampled_max_x_x2_y1 - sampled_min_x_x2_y1 + 11'd1;
            height_x2_y1 = sampled_max_y_x2_y1 - sampled_min_y_x2_y1 + 11'd1;
            area_x2_y1   = width_x2_y1 * height_x2_y1;
        end else begin
            width_x2_y1 = 11'd0; height_x2_y1 = 11'd0; area_x2_y1 = 22'd0;
        end

        // x3_y1
        if (sampled_min_x_x3_y1 != 10'd641 && sampled_max_x_x3_y1 >= sampled_min_x_x3_y1 &&
            sampled_min_y_x3_y1 != 10'd641 && sampled_max_y_x3_y1 >= sampled_min_y_x3_y1) begin
            width_x3_y1  = sampled_max_x_x3_y1 - sampled_min_x_x3_y1 + 11'd1;
            height_x3_y1 = sampled_max_y_x3_y1 - sampled_min_y_x3_y1 + 11'd1;
            area_x3_y1   = width_x3_y1 * height_x3_y1;
        end else begin
            width_x3_y1 = 11'd0; height_x3_y1 = 11'd0; area_x3_y1 = 22'd0;
        end

        // x0_y2
        if (sampled_min_x_x0_y2 != 10'd641 && sampled_max_x_x0_y2 >= sampled_min_x_x0_y2 &&
            sampled_min_y_x0_y2 != 10'd641 && sampled_max_y_x0_y2 >= sampled_min_y_x0_y2) begin
            width_x0_y2  = sampled_max_x_x0_y2 - sampled_min_x_x0_y2 + 11'd1;
            height_x0_y2 = sampled_max_y_x0_y2 - sampled_min_y_x0_y2 + 11'd1;
            area_x0_y2   = width_x0_y2 * height_x0_y2;
        end else begin
            width_x0_y2 = 11'd0; height_x0_y2 = 11'd0; area_x0_y2 = 22'd0;
        end

        // x1_y2
        if (sampled_min_x_x1_y2 != 10'd641 && sampled_max_x_x1_y2 >= sampled_min_x_x1_y2 &&
            sampled_min_y_x1_y2 != 10'd641 && sampled_max_y_x1_y2 >= sampled_min_y_x1_y2) begin
            width_x1_y2  = sampled_max_x_x1_y2 - sampled_min_x_x1_y2 + 11'd1;
            height_x1_y2 = sampled_max_y_x1_y2 - sampled_min_y_x1_y2 + 11'd1;
            area_x1_y2   = width_x1_y2 * height_x1_y2;
        end else begin
            width_x1_y2 = 11'd0; height_x1_y2 = 11'd0; area_x1_y2 = 22'd0;
        end

        // x2_y2
        if (sampled_min_x_x2_y2 != 10'd641 && sampled_max_x_x2_y2 >= sampled_min_x_x2_y2 &&
            sampled_min_y_x2_y2 != 10'd641 && sampled_max_y_x2_y2 >= sampled_min_y_x2_y2) begin
            width_x2_y2  = sampled_max_x_x2_y2 - sampled_min_x_x2_y2 + 11'd1;
            height_x2_y2 = sampled_max_y_x2_y2 - sampled_min_y_x2_y2 + 11'd1;
            area_x2_y2   = width_x2_y2 * height_x2_y2;
        end else begin
            width_x2_y2 = 11'd0; height_x2_y2 = 11'd0; area_x2_y2 = 22'd0;
        end

        // x3_y2
        if (sampled_min_x_x3_y2 != 10'd641 && sampled_max_x_x3_y2 >= sampled_min_x_x3_y2 &&
            sampled_min_y_x3_y2 != 10'd641 && sampled_max_y_x3_y2 >= sampled_min_y_x3_y2) begin
            width_x3_y2  = sampled_max_x_x3_y2 - sampled_min_x_x3_y2 + 11'd1;
            height_x3_y2 = sampled_max_y_x3_y2 - sampled_min_y_x3_y2 + 11'd1;
            area_x3_y2   = width_x3_y2 * height_x3_y2;
        end else begin
            width_x3_y2 = 11'd0; height_x3_y2 = 11'd0; area_x3_y2 = 22'd0;
        end
    end

    // area-valid flags (only true if box exists AND area >= threshold)
    logic valid_x0_y0_area, valid_x1_y0_area, valid_x2_y0_area, valid_x3_y0_area;
    logic valid_x0_y1_area, valid_x1_y1_area, valid_x2_y1_area, valid_x3_y1_area;
    logic valid_x0_y2_area, valid_x1_y2_area, valid_x2_y2_area, valid_x3_y2_area;

    assign valid_x0_y0_area = (area_x0_y0 >= small_thresh);
    assign valid_x1_y0_area = (area_x1_y0 >= small_thresh);
    assign valid_x2_y0_area = (area_x2_y0 >= small_thresh);
    assign valid_x3_y0_area = (area_x3_y0 >= small_thresh);

    assign valid_x0_y1_area = (area_x0_y1 >= small_thresh);
    assign valid_x1_y1_area = (area_x1_y1 >= small_thresh);
    assign valid_x2_y1_area = (area_x2_y1 >= small_thresh);
    assign valid_x3_y1_area = (area_x3_y1 >= small_thresh);

    assign valid_x0_y2_area = (area_x0_y2 >= small_thresh);
    assign valid_x1_y2_area = (area_x1_y2 >= small_thresh);
    assign valid_x2_y2_area = (area_x2_y2 >= small_thresh);
    assign valid_x3_y2_area = (area_x3_y2 >= small_thresh);

    // Drawing logic: OR of 12 region boxes (area filtered)
    always_comb begin
        red_block = 7'b1111111;
        dout_red = 7'b0;

        // For each region, if area-valid and boundary matches draw a red pixel.
        // Use independent ifs so multiple regions may OR together; result is same color.
        if ( valid_x0_y0_area &&
            ( (drawY == sampled_min_y_x0_y0 && drawX <= sampled_max_x_x0_y0 && drawX >= sampled_min_x_x0_y0) ||
              (drawY == sampled_max_y_x0_y0 && drawX <= sampled_max_x_x0_y0 && drawX >= sampled_min_x_x0_y0) ||
              (drawX == sampled_min_x_x0_y0 && drawY <= sampled_max_y_x0_y0 && drawY >= sampled_min_y_x0_y0) ||
              (drawX == sampled_max_x_x0_y0 && drawY <= sampled_max_y_x0_y0 && drawY >= sampled_min_y_x0_y0) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        if ( valid_x1_y0_area &&
            ( (drawY == sampled_min_y_x1_y0 && drawX <= sampled_max_x_x1_y0 && drawX >= sampled_min_x_x1_y0) ||
              (drawY == sampled_max_y_x1_y0 && drawX <= sampled_max_x_x1_y0 && drawX >= sampled_min_x_x1_y0) ||
              (drawX == sampled_min_x_x1_y0 && drawY <= sampled_max_y_x1_y0 && drawY >= sampled_min_y_x1_y0) ||
              (drawX == sampled_max_x_x1_y0 && drawY <= sampled_max_y_x1_y0 && drawY >= sampled_min_y_x1_y0) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        if ( valid_x2_y0_area &&
            ( (drawY == sampled_min_y_x2_y0 && drawX <= sampled_max_x_x2_y0 && drawX >= sampled_min_x_x2_y0) ||
              (drawY == sampled_max_y_x2_y0 && drawX <= sampled_max_x_x2_y0 && drawX >= sampled_min_x_x2_y0) ||
              (drawX == sampled_min_x_x2_y0 && drawY <= sampled_max_y_x2_y0 && drawY >= sampled_min_y_x2_y0) ||
              (drawX == sampled_max_x_x2_y0 && drawY <= sampled_max_y_x2_y0 && drawY >= sampled_min_y_x2_y0) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        if ( valid_x3_y0_area &&
            ( (drawY == sampled_min_y_x3_y0 && drawX <= sampled_max_x_x3_y0 && drawX >= sampled_min_x_x3_y0) ||
              (drawY == sampled_max_y_x3_y0 && drawX <= sampled_max_x_x3_y0 && drawX >= sampled_min_x_x3_y0) ||
              (drawX == sampled_min_x_x3_y0 && drawY <= sampled_max_y_x3_y0 && drawY >= sampled_min_y_x3_y0) ||
              (drawX == sampled_max_x_x3_y0 && drawY <= sampled_max_y_x3_y0 && drawY >= sampled_min_y_x3_y0) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        // Row1
        if ( valid_x0_y1_area &&
            ( (drawY == sampled_min_y_x0_y1 && drawX <= sampled_max_x_x0_y1 && drawX >= sampled_min_x_x0_y1) ||
              (drawY == sampled_max_y_x0_y1 && drawX <= sampled_max_x_x0_y1 && drawX >= sampled_min_x_x0_y1) ||
              (drawX == sampled_min_x_x0_y1 && drawY <= sampled_max_y_x0_y1 && drawY >= sampled_min_y_x0_y1) ||
              (drawX == sampled_max_x_x0_y1 && drawY <= sampled_max_y_x0_y1 && drawY >= sampled_min_y_x0_y1) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        if ( valid_x1_y1_area &&
            ( (drawY == sampled_min_y_x1_y1 && drawX <= sampled_max_x_x1_y1 && drawX >= sampled_min_x_x1_y1) ||
              (drawY == sampled_max_y_x1_y1 && drawX <= sampled_max_x_x1_y1 && drawX >= sampled_min_x_x1_y1) ||
              (drawX == sampled_min_x_x1_y1 && drawY <= sampled_max_y_x1_y1 && drawY >= sampled_min_y_x1_y1) ||
              (drawX == sampled_max_x_x1_y1 && drawY <= sampled_max_y_x1_y1 && drawY >= sampled_min_y_x1_y1) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        if ( valid_x2_y1_area &&
            ( (drawY == sampled_min_y_x2_y1 && drawX <= sampled_max_x_x2_y1 && drawX >= sampled_min_x_x2_y1) ||
              (drawY == sampled_max_y_x2_y1 && drawX <= sampled_max_x_x2_y1 && drawX >= sampled_min_x_x2_y1) ||
              (drawX == sampled_min_x_x2_y1 && drawY <= sampled_max_y_x2_y1 && drawY >= sampled_min_y_x2_y1) ||
              (drawX == sampled_max_x_x2_y1 && drawY <= sampled_max_y_x2_y1 && drawY >= sampled_min_y_x2_y1) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        if ( valid_x3_y1_area &&
            ( (drawY == sampled_min_y_x3_y1 && drawX <= sampled_max_x_x3_y1 && drawX >= sampled_min_x_x3_y1) ||
              (drawY == sampled_max_y_x3_y1 && drawX <= sampled_max_x_x3_y1 && drawX >= sampled_min_x_x3_y1) ||
              (drawX == sampled_min_x_x3_y1 && drawY <= sampled_max_y_x3_y1 && drawY >= sampled_min_y_x3_y1) ||
              (drawX == sampled_max_x_x3_y1 && drawY <= sampled_max_y_x3_y1 && drawY >= sampled_min_y_x3_y1) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        // Row2
        if ( valid_x0_y2_area &&
            ( (drawY == sampled_min_y_x0_y2 && drawX <= sampled_max_x_x0_y2 && drawX >= sampled_min_x_x0_y2) ||
              (drawY == sampled_max_y_x0_y2 && drawX <= sampled_max_x_x0_y2 && drawX >= sampled_min_x_x0_y2) ||
              (drawX == sampled_min_x_x0_y2 && drawY <= sampled_max_y_x0_y2 && drawY >= sampled_min_y_x0_y2) ||
              (drawX == sampled_max_x_x0_y2 && drawY <= sampled_max_y_x0_y2 && drawY >= sampled_min_y_x0_y2) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        if ( valid_x1_y2_area &&
            ( (drawY == sampled_min_y_x1_y2 && drawX <= sampled_max_x_x1_y2 && drawX >= sampled_min_x_x1_y2) ||
              (drawY == sampled_max_y_x1_y2 && drawX <= sampled_max_x_x1_y2 && drawX >= sampled_min_x_x1_y2) ||
              (drawX == sampled_min_x_x1_y2 && drawY <= sampled_max_y_x1_y2 && drawY >= sampled_min_y_x1_y2) ||
              (drawX == sampled_max_x_x1_y2 && drawY <= sampled_max_y_x1_y2 && drawY >= sampled_min_y_x1_y2) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        if ( valid_x2_y2_area &&
            ( (drawY == sampled_min_y_x2_y2 && drawX <= sampled_max_x_x2_y2 && drawX >= sampled_min_x_x2_y2) ||
              (drawY == sampled_max_y_x2_y2 && drawX <= sampled_max_x_x2_y2 && drawX >= sampled_min_x_x2_y2) ||
              (drawX == sampled_min_x_x2_y2 && drawY <= sampled_max_y_x2_y2 && drawY >= sampled_min_y_x2_y2) ||
              (drawX == sampled_max_x_x2_y2 && drawY <= sampled_max_y_x2_y2 && drawY >= sampled_min_y_x2_y2) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end

        if ( valid_x3_y2_area &&
            ( (drawY == sampled_min_y_x3_y2 && drawX <= sampled_max_x_x3_y2 && drawX >= sampled_min_x_x3_y2) ||
              (drawY == sampled_max_y_x3_y2 && drawX <= sampled_max_x_x3_y2 && drawX >= sampled_min_x_x3_y2) ||
              (drawX == sampled_min_x_x3_y2 && drawY <= sampled_max_y_x3_y2 && drawY >= sampled_min_y_x3_y2) ||
              (drawX == sampled_max_x_x3_y2 && drawY <= sampled_max_y_x3_y2 && drawY >= sampled_min_y_x3_y2) ) ) begin
            red_block = (sw_i[15]) ? 7'b0: 7'b1111111;
            dout_red = sw_i[15] ? 7'b1111111: 7'b0;
        end
    end

    
    
    hex_driver debug_max_x( // LEFT
        .clk(clk),
        .reset(reset),
        .in({4'b1111,{2'b0, sampled_max_x[9:8]},sampled_max_x[7:4], sampled_max_x[3:0]}),
        .hex_seg(hex_seg_a),
        .hex_grid(hex_grid_a)
    );
    
    hex_driver debug_max_y( //RIGHT
        .clk(clk),
        .reset(reset),
        .in({4'b0, {2'b0,sampled_min_x[9:8]},sampled_min_x[7:4], sampled_min_x[3:0]}),
        .hex_seg(hex_seg_b),
        .hex_grid(hex_grid_b)
    );
    
endmodule

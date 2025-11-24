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
        input pwdn,
        input [7:0] cam_data,

        input start_fsm,
        

        //CAMERA OUTPUTS
        inout sda,
        output xclk,
        output scl,


        //HDMI
        output logic hdmi_tmds_clk_n,
        output logic hdmi_tmds_clk_p,
        output logic [2:0]hdmi_tmds_data_n,
        output logic [2:0]hdmi_tmds_data_p
        
    );
    
    

    
    logic vga_clk, clk_125MHz;
    logic locked;
    logic [3:0] red, green, blue;
    logic [9:0] drawX, drawY, x_coord, y_coord;
    logic [18:0] cam_pixel_idx, vga_pixel_idx;
    logic [7:0] pixel_data;
    logic hsync, vsync, vde;
    logic reset_ah;
    logic config_done;
    logic start_fsm_debounced, reset_debounced;
    wire  sda;
    logic scl;
    logic [3:0] doutb;

    assign pwdn = 0'b0;
    assign cam_pixel_idx = y_coord * 640 + x_coord;
    assign vga_pixel_idx = drawY * 640 + drawX;

    sync_debounce button_sync [1:0] (
		.Clk  (clk),

		.d    ({start_fsm, reset}),
		.q    ({start_fsm_debounced, reset_debounced})
	);
    
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(xclk),
        .clk_out2(vga_clk),
        .clk_out3(clk_125MHz),
        .reset(reset_debounced),
        .locked(locked),
        .clk_in1(clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(vga_clk),
        .reset(reset_debounced),
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
        .rst(reset_debounced),
        //Color and Sync Signals
        .red(doutb),
        .green(doutb),
        .blue(doutb),
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
        .clka(pclk), //CAMERA
        .addra(cam_pixel_idx),
        .dina(pixel_data[7:4]),
        .ena(1'b1),
        .wea(1'b1),
        
        .clkb(vga_clk), //VGA
        .addrb(vga_pixel_idx),
        .doutb(doutb),
        .enb(1'b1)
    );
    
    sccb_control control_unit (
        .xclk(xclk),
        .start_fsm(start_fsm),
        .reset(reset_debounced),
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
        .reset(reset_debounced),

        .x_coord(x_coord),
        .y_coord(y_coord),
        .pixel_data(pixel_data)
    );

    
endmodule


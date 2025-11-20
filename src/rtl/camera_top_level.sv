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
        input clk,
        input reset,
        
        //HDMI
        output logic hdmi_tmds_clk_n,
        output logic hdmi_tmds_clk_p,
        output logic [2:0]hdmi_tmds_data_n,
        output logic [2:0]hdmi_tmds_data_p
        
    );
    
    

    
    logic xclk, vga_clk, clk_125MHz;
    logic locked;
    logic [3:0] red, green, blue;
    logic [9:0] drawX, drawY;
    logic hsync, vsync, vde;
    logic reset_ah;
    wire  sda;
    logic scl;
   
    
    
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(xclk),
        .clk_out2(vga_clk),
        .clk_out3(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(vga_clk),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
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
        .clka(xclk), //AXI
        .addra(addra),
        .dina(dina),
        .douta(douta),
        .ena(ena),
        .wea(wea),
        
        .clkb(vga_clk), //COLORMAPPER
        .addrb(addrb),
        .dinb(32'b0),
        .doutb(doutb),
        .enb(1'b1),
        .web(4'b0)
    );
    
    sccb_control control_unit (
        .clk(xclk),
        .start_fsm(start_fsm),
        .reset(reset),
        .sda(sda),
        .scl(scl)
    );

    
endmodule


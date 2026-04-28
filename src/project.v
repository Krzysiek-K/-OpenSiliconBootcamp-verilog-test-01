/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_KK_VGA01(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  wire[7:0] mt_ctrl;
  motor_handler mctrl(
    .hpos(pix_x),
    .vpos(pix_y),
    .hsync(hsync),
    .vsync(vsync),
    .clk(clk),
    .reset(~rst_n),
    .ctrl(mt_ctrl)
  );

  wire sp1on, sp2on, sp3on, sp4on;
  motor_core motor1( .ctrl(mt_ctrl), .clk(clk), .steer(ui_in[0]), .hpos(pix_x), .vpos(pix_y), .hsync(hsync), .spron(sp1on) );
  motor_core motor2( .ctrl(mt_ctrl), .clk(clk), .steer(ui_in[1]), .hpos(pix_x), .vpos(pix_y), .hsync(hsync), .spron(sp2on) );
  motor_core motor3( .ctrl(mt_ctrl), .clk(clk), .steer(ui_in[2]), .hpos(pix_x), .vpos(pix_y), .hsync(hsync), .spron(sp3on) );
  motor_core motor4( .ctrl(mt_ctrl), .clk(clk), .steer(ui_in[3]), .hpos(pix_x), .vpos(pix_y), .hsync(hsync), .spron(sp4on) );

  wire rect = ~(pix_x[8] | pix_y[8]);
  wire mR = sp1on | sp4on;
  wire mG1 = sp2on | sp3on | sp4on;
  wire mG0 = sp2on | sp4on;
  wire mB = sp3on;
  assign R = video_active ? {mR, mR} : 2'b00;
  assign G = video_active ? {mG1, mG0|~rect} : 2'b00;
  assign B = video_active ? {mB, mB} : 2'b00;
  
  // Suppress unused signals warning
  //wire _unused_ok_ = &{moving_x, pix_y};

endmodule

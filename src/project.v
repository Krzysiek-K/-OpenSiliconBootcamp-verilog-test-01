/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module racer_mod(
  input   wire        clk,
  input   wire        throttle,
  input   wire        spdclk,
  input   wire        reset,
  input   wire[8:0]   reset_y,
  input   wire        vsync,
  input   wire        hsync,
  input   wire[9:0]   pix_x,
  input   wire[9:0]   pix_y,
  output  wire        spr_on
);
  reg[13:0] xp;
  reg[12:0] yp;
  reg[7:0] dx;
  reg[7:0] dy;
  reg[3:0] speed;
  wire[9:0] racer_x;
  wire[8:0] racer_y;
  assign racer_x = xp[13:4];
  assign racer_y = yp[12:4];
  reg throttle_d;

  wire[14:0] xp_sum = {xp,1'b1} + {dx[7],dx[7],dx[7],dx[7],dx[7],dx[7],dx[7],dx[7],dx[7],dx[7:2]};
  wire[13:0] yp_sum = {yp,1'b1} + {dy[7],dy[7],dy[7],dy[7],dy[7],dy[7],dy[7],dy[7],dy[7:2]};

  always @(posedge hsync) begin
    if(reset) begin
      xp <= 320 << 4;
      yp <= {reset_y, 4'b0000};
    end else if(pix_y[9:4]==0 && pix_y[3:0]<speed) begin
      xp <= xp_sum[14:1];
      yp <= yp_sum[13:1];
    end
  end

  wire[8:0] dx_sum = {dx,1'b1} + {dy[7], dy[7], dy[7], dy[7], dy[7], dy[7:4]};
  wire[8:0] dy_sum = {dy,1'b0} - {dx[7], dx[7], dx[7], dx[7], dx[7], dx[7:4]};
  wire[1:0] _unused_ok_ = {dx_sum[0], dy_sum[0]};

  always @(posedge vsync) begin
    throttle_d <= throttle;
    if(reset) begin
      dx <= 100;
    end else if(throttle) begin
      dx <= dx_sum[8:1];
    end
  end
  always @(negedge vsync) begin
    if(reset) begin
      dy <= 0;
    end else if(throttle_d) begin
      dy <= dy_sum[8:1];
    end
  end

  wire spdlow = (speed<7);
  wire spdnomax = (speed<10);
  wire spdup = spdlow | (~throttle_d & spdnomax);
  wire spddn = ~spdup & throttle_d & ~spdlow;

  always @(posedge spdclk) begin
    if(reset) begin
      speed <= 0;
    end else begin
      speed <= speed + {spddn,spddn,spddn,spddn|spdup};
    end
  end

  reg[2:0] racer_xon;
  reg[2:0] racer_yon;
  
  always @(posedge clk) begin
    if (racer_x == pix_x) begin
      racer_xon <= 7;
    end else begin
      racer_xon <= racer_xon - {2'b00, racer_xon != 0};
    end
  end

  always @(posedge hsync) begin
    if (racer_y == pix_y) begin
      racer_yon <= 7;
    end else begin
      racer_yon <= racer_yon - {2'b00, racer_yon!=0};
    end
  end

  assign spr_on = (racer_xon != 0) & (racer_yon != 0);
endmodule

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
  reg[1:0] fcounter;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  always @(posedge vsync) begin
    fcounter <= {fcounter[0], ~fcounter[1]};
  end

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  wire racer1_on;
  racer_mod racer1(
    .clk(clk),
    .throttle(ui_in[0]),
    .spdclk(fcounter[1]),
    //.reset(ui_in[7]),
    .reset(~rst_n),
    .reset_y(400),
    .vsync(vsync),
    .hsync(hsync),
    .pix_x(pix_x),
    .pix_y(pix_y),
    .spr_on(racer1_on)
  );

  assign R = video_active ? {racer1_on, racer1_on} : 2'b00;
  assign G = video_active ? 2'b01 : 2'b00;
  assign B = video_active ? 2'b00 : 2'b00;
  
endmodule

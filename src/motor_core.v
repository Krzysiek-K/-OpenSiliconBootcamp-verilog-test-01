
`default_nettype none


module sprite_dly(
  input wire  start,
  input wire  sclk,
  output wire spon
);
  // 000->000
  // 001->010->101->011->111->110->100
  //  00x 0 0
  //  01x 1 1
  //  11x 0 0
  //  10x 0 1
  reg[2:0] st;
  always @(posedge sclk) begin
      st <= {st[1:0], (~st[2] & st[1]) | (st[2] & ~st[1] & st[0]) | start};
  end
  assign spon = |{st};
endmodule

module adc_1bit(
  input wire      ain,
  input wire      bin,
  input wire      cin,
  input wire[2:0] mode,
  input wire      aclk,
  output wire     yout
);
  // Operations:
  //  out = A+B+C     C<-C1  E<-B   ADD
  //  out = A+B+0     C<-C1         ADD start
  //  out = A+~B+C    C<-C1         SUB
  //  out = A+~B+1    C<-C1         SUB start

  wire start = mode[0];
  wire sub = mode[1];
  wire echo = mode[2];
  reg prevC;
  reg prevB;

  wire asrc = ain;
  wire bsrc = (echo ? prevB : bin ^ sub);
  wire csrc = start ? cin ^ sub : prevC;
  wire[1:0] sum = asrc + bsrc + csrc;

  always @(posedge aclk) begin
    prevC <= sum[1];
    prevB <= bsrc;
  end
  assign yout = sum[0];

endmodule

module motor_core(
  input  wire [7:0] ctrl,
  input  wire       clk,
  input  wire       steer,
  input  wire[9:0]  hpos,
  input  wire[9:0]  vpos,
  input  wire       hsync,
  output wire       spron
);
  reg[7:0] dx;
  reg[7:0] dy;
  wire r = ctrl[0];   // reset
  wire nr = ~r;
  wire dxy_clk = ctrl[1] & (r | steer);
  wire[2:0] dxy_mode = ctrl[4:2];

  wire dxy_adcout;
  adc_1bit dxy_adc(
    .ain(dy[0]),
    .bin(dx[5]),
    .cin(dx[4]),
    .mode(dxy_mode),
    .aclk(dxy_clk),
    .yout(dxy_adcout)
  );

  always @(posedge dxy_clk) begin
    dy <= {dx[0]&nr, dy[7]&nr, dy[6]&nr, dy[5]&nr, dy[4]&nr, dy[3]&nr, dy[2]&nr, dy[1]&nr};     // reset -> 0
    dx <= {dxy_adcout&nr, dx[7]|r, dx[6]|r, dx[5]&nr, dx[4]&nr, dx[3]|r, dx[2]&nr, dx[1]&nr};   // reset -> 01100100 (100)
  end

  // Draw the sprite
  wire[9:0] spx = {2'b00,dx};//100;
  wire[9:0] spy = {2'b00,dy};//150;

  wire spon_x, spon_y;
  sprite_dly stmr_x( .start(spx==hpos), .sclk(clk), .spon(spon_x));
  sprite_dly stmr_y( .start(spy==vpos), .sclk(hsync), .spon(spon_y));

  assign spron = spon_x & spon_y;

  // Suppress unused signals warning
  wire _unused_ok_ = &{ctrl};

endmodule

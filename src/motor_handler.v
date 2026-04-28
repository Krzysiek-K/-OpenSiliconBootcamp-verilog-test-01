

// DXY operation
//
//  x7 x6 x5 x4 x3 x2 x1 x0 y7 y6 y5 y4 y3 y2 y1 y0
//        || cc                                  vv
//  x7 x6 x5 x4 x3 x2 x1 x0 y7 y6 y5 y4 y3 y2 y1 y0     011   y0-x5-x4  (start)
//  Y0 x7 x6 x5 x4 x3 x2 x1 x0 y7 y6 y5 y4 y3 y2 y1     010   y1-x6-C
//  Y1 Y0 x7 x6 x5 x4 x3 x2 x1 x0 y7 y6 y5 y4 y3 y2     010   y2-x7-C       E<=x7
//  Y2 Y1 Y0 x7 x6 x5 x4 x3 x2 x1 x0 y7 y6 y5 y4 y3     110   y3-E-C
//  Y3 y2 y1 y0 x7 x6 x5 x4 x3 x2 x1 x0 y7 y6 y5 y4     110   y4-E-C
//  Y4 Y3 Y2 Y1 Y0 x7 x6 x5 x4 x3 x2 x1 x0 y7 y6 y5     110   y5-E-C
//  Y5 Y4 Y3 Y2 Y1 Y0 x7 x6 x5 x4 x3 x2 x1 x0 y7 y6     110   y6-E-C
//  Y6 Y5 Y4 Y3 Y2 Y1 Y0 x7 x6 x5 x4 x3 x2 x1 x0 y7     110   y7-E-C
//  Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0 x7 x6 x5 x4 x3 x2 x1 x0     001   x0+Y5+Y4  (start)
//  X0 Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0 x7 x6 x5 x4 x3 x2 x1     000   x1+Y6+C
//  X1 X0 Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0 x7 x6 x5 x4 x3 x2     000   x2+Y7+C       E<=Y7
//  X2 X1 X0 Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0 x7 x6 x5 x4 x3     100   x3+E+C 
//  X3 X2 X1 X0 Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0 x7 x6 x5 x4     100   x4+E+C 
//  X4 X3 X2 X1 X0 Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0 x7 x6 x5     100   x5+E+C 
//  X5 X4 X3 X2 X1 X0 Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0 x7 x6     100   x6+E+C 
//  X6 X5 X4 X3 X2 X1 X0 Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0 x7     100   x7+E+C 
//  X7 X6 X5 X4 X3 X2 X1 X0 Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0               (end state)
//

module motor_handler(
  input wire[9:0]   hpos,
  input wire[9:0]   vpos,
  input wire        hsync,
  input wire        vsync,
  input wire        clk,
  input wire        reset,
  output wire[7:0]  ctrl
);
  reg[1:0] reshold;
  always @(posedge vsync) begin
    reshold <= {reshold[0]|reset, reset};
  end

  wire dxymask = vpos[9] & ~|{vpos[8:0],hpos[9:6]};
  wire[3:0] dxystep = hpos[5:2];
  reg dxyclk;

  always @(posedge clk) begin
    dxyclk <= dxymask & (hpos[1:0]==2);
  end

  assign ctrl = {
    3'b000,
    dxystep[2] | (dxystep[1] & dxystep[0]), // [4] dxy echo
    ~dxystep[3],                            // [3] dxy SUB
    ~|{dxystep[2:0]},                       // [2] dxy start
    dxyclk,                                 // [1] dxyclk
    |{reshold}                              // [0] reset
  };

  // Suppress unused signals warning
  wire _unused_ok_ = &{hsync};

endmodule

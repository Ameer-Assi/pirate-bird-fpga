module cannon_bitmap (
    input logic clk,
    input logic resetN,
    input logic [10:0] offsetX,  // offset inside bracket from top left position. max num of letters is 25.
    input logic [10:0] offsetY,
    input logic InsideRectangle,
    input logic signed [10:0] bird_TLY,

    output logic    drawingRequest, //output that the pixel should be dispalyed 
    output logic [7:0]  RGBout,
    output logic [1:0] vers
);


  localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// bitmap  representation for a transparent pixel 
  logic [ 7:0] color;
  logic [13:0] address;
  logic [ 1:0] frame;
  assign frame   = {~bird_TLY[8:7]};
  assign address = {frame, offsetY[5:0], offsetX[5:0]};


  lpm_rom #(
      .LPM_WIDTH             (8),
      .LPM_WIDTHAD           (14),
      .LPM_NUMWORDS          (16384),
      .LPM_FILE              ("RTL/boat_cannon.mif"),
      .LPM_TYPE              ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL   ("REGISTERED"),
      .LPM_OUTDATA           ("UNREGISTERED"),
      .AUTO_CARRY_CHAINS     ("ON"),
      .AUTO_CASCADE_BUFFERS  ("ON"),
      .INTENDED_DEVICE_FAMILY("Cyclone V")
  ) rom_inst (
      .address(address),
      .inclock(clk),
      // .outclock(clk),
      .q(color)
  );




  logic InsideRectangle_d;
  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      drawingRequest <= 1'b0;
      InsideRectangle_d <= 1'b0;

    end else begin
      drawingRequest <= 1'b0;
      InsideRectangle_d <= InsideRectangle; // in order for insideRectangle to be for the same pixel.(pipeline logic, do a time table to understand)
      if (InsideRectangle_d == 1'b1) begin
        RGBout <= color;
        drawingRequest <= (color != TRANSPARENT_ENCODING) ? 1'b1 : 1'b0;
      end
    end
  end
  assign vers = frame;
endmodule

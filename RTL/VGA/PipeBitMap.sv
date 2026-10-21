// HartsMatrixBitMap File 
// A two level bitmap. dosplaying harts on the screen Feb 2025 
//(c) Technion IIT, Department of Electrical Engineering 2025 



module PipeBitMap (
    input logic clk,
    input logic resetN,
    input logic [10:0] offsetX,  // offset from top left  position 
    input logic [10:0] offsetY,
    input logic InsideRectangle,  //input that the pixel is within a bracket 


    output logic drawingRequest,  //output that the pixel should be dispalyed 
    output logic [7:0] RGBout  //rgb value from the bitmap 
);


  localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 

  localparam logic [7:0] OBJECT_HEIGHT = 80;
  localparam logic [7:0] OBJECT_WIDTH = 64;

  logic [ 7:0] color;
  logic [12:0] address;
  assign address = (offsetY * OBJECT_WIDTH) + offsetX;

  lpm_rom #(
      .LPM_WIDTH             (8),
      .LPM_WIDTHAD           (13),
      .LPM_NUMWORDS          (5120),
      .LPM_FILE              ("RTL/shark_obstacle.mif"),
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


  //==----------------------------------------------------------------------------------------------------------------=
  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      RGBout <= TRANSPARENT_ENCODING;
    end else begin
      RGBout <= TRANSPARENT_ENCODING;

      if (InsideRectangle == 1'b1) RGBout <= color;
    end

  end

  //==----------------------------------------------------------------------------------------------------------------=
  // decide if to draw the pixel or not 
  assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
endmodule


// System-Verilog 'written by Alex Grinshpun May 2018
// New bitmap dudy February 2025
// (c) Technion IIT, Department of Electrical Engineering 2025 



module smileyBitMap (
    input logic clk,
    input logic resetN,
    input logic [10:0] offsetX,  // offset from top left  position 
    input logic [10:0] offsetY,
    input logic InsideRectangle,  //input that the pixel is within a bracket 

    output logic drawingRequest,  //output that the pixel should be dispalyed 
    output logic [7:0] RGBout  //rgb value from the bitmap 

);

  // this is the devider used to acess the right pixel 
  localparam int OBJECT_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32 
  localparam int OBJECT_NUMBER_OF_X_BITS = 6;  // 2^6 = 64 
  logic [10:0] address;

  localparam logic [10:0] OBJECT_HEIGHT_Y = 11'b1 << OBJECT_NUMBER_OF_Y_BITS;
  localparam logic [10:0] OBJECT_WIDTH_X = 11'b1 << OBJECT_NUMBER_OF_X_BITS;

  //assign address = ((OBJECT_HEIGHT_Y-offsetY-1)*OBJECT_WIDTH_X + offsetX);
  assign address = ((offsetY) * OBJECT_WIDTH_X + offsetX);


  // generating a smiley bitmap from a MIF file

  logic [7:0] color;
  localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 
  lpm_rom #(
      .LPM_WIDTH             (8),
      .LPM_WIDTHAD           (11),
      .LPM_NUMWORDS          (2048),
      .LPM_FILE              ("RTL/pirate_bird.mif"),
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


  // pipeline (ff) to get the pixel color from the array 	 

  //////////--------------------------------------------------------------------------------------------------------------=
  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      RGBout <= TRANSPARENT_ENCODING;


    end else begin
      RGBout <= TRANSPARENT_ENCODING;  // default  


      if (InsideRectangle == 1'b1) begin  // inside an external bracket 

        RGBout <= color;

      end
    end

  end

  //////////--------------------------------------------------------------------------------------------------------------=
  // decide if to draw the pixel or not 
  assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule

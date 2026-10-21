//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// System-Verilog Alex Grinshpun May 2018
// New coding convention dudy December 2018
// (c) Technion IIT, Department of Electrical Engineering 2025 


module square_object (
    input logic clk,
    input logic resetN,
    input logic signed [10:0] pixelX,  //  current VGA pixel 
    input logic signed [10:0] pixelY,
    input logic signed [10:0] topLeftX,  //position on the screen 
    input logic signed [10:0] topLeftY,  // can be negative , if the object is partliy outside 
    input logic speed_sign,

    output logic [10:0] offsetX,  // offset inside bracket from top left position 
    output logic [10:0] offsetY,
    output logic drawingRequest,  // indicates pixel inside the bracket
    output logic [7:0] RGBout  //optional color output for mux 
);

  parameter int OBJECT_WIDTH_X = 100;
  parameter int OBJECT_HEIGHT_Y = 100;
  parameter logic [7:0] OBJECT_COLOR = 8'h03;
  localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// bitmap  representation for a transparent pixel 
  parameter int is_bird = 0;
  int   rightX;  //coordinates of the sides  
  int   bottomY;
  logic insideBracket;
  int   pixelY_T;
  int   pixelX_T;
  int   topLeftX_T;
  int   topLeftY_T;
  localparam int rotate_matrix[0:3] = '{7, -4, 4, 7};
  int mult_sign;
  always_comb begin
    pixelX_T  = pixelX - topLeftX;
    pixelY_T  = pixelY - topLeftY;
    mult_sign = -1;
    if (is_bird) begin
      if (speed_sign == 1'b0) mult_sign = 1;
      pixelX_T = ((pixelX - topLeftX) * rotate_matrix[0] + (pixelY - topLeftY) * mult_sign * rotate_matrix[1]) / 8;
      pixelY_T = ((pixelX - topLeftX) * mult_sign * rotate_matrix[2] + (pixelY - topLeftY) * rotate_matrix[3]) / 8;

      //////////--------------------------------------------------------------------------------------------------------------=
      // Calculate object right  & bottom  boundaries
      rightX = (OBJECT_WIDTH_X);
      bottomY = (OBJECT_HEIGHT_Y);
      insideBracket  = 	 ( (pixelX_T >= 0) &&  (pixelX_T < rightX) // math is made with SIGNED variables  
      && (pixelY_T >= 0) && (pixelY_T < bottomY));  // as the top left position can be negative

    end //bird
	 else begin
      // Calculate object right  & bottom  boundaries
      rightX = (topLeftX + OBJECT_WIDTH_X);
      bottomY = (topLeftY + OBJECT_HEIGHT_Y);
      insideBracket  = 	 ( (pixelX  >= topLeftX) &&  (pixelX < rightX) // math is made with SIGNED variables  
      && (pixelY >= topLeftY) && (pixelY < bottomY));  // as the top left position can be negative
    end  // bird else
  end  //always_comb
  //////////--------------------------------------------------------------------------------------------------------------=
  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      RGBout <= TRANSPARENT_ENCODING;
      drawingRequest <= 1'b0;
    end else begin
      // DEFUALT outputs
      RGBout <= TRANSPARENT_ENCODING;  // so it will not be displayed 
      drawingRequest <= 1'b0;  // transparent color 
      offsetX <= 0;  //no offset
      offsetY <= 0;  //no offset


      if (insideBracket) // test if it is inside the rectangle 
		begin
        RGBout <= OBJECT_COLOR;  // colors table 
        drawingRequest <= 1'b1;
        if (is_bird) begin
          offsetX	<= (pixelX_T ); //calculate relative offsets from top left corner allways a positive number 
          offsetY <= (pixelY_T);
        end else begin
          offsetX	<= (pixelX - topLeftX); //calculate relative offsets from top left corner allways a positive number 
          offsetY <= (pixelY - topLeftY);
        end
      end



    end
  end
endmodule

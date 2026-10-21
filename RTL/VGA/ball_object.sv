
module ball_object (
    input logic clk,
    input logic resetN,
    input logic signed [10:0] pixelX,  //  current VGA pixel 
    input logic signed [10:0] pixelY,
    input logic signed [10:0] topLeftX,  //position on the screen 
    input logic signed [10:0] topLeftY,
    input logic ball_moving,

    output logic [10:0] offsetX,  // offset inside bracket from top left position 
    output logic [10:0] offsetY,
    output logic drawingRequest  // indicates pixel inside the bracket
);

  parameter int OBJECT_WIDTH_X = 16;
  parameter int OBJECT_HEIGHT_Y = 16;



  localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// bitmap  representation for a transparent pixel 

  int   rightX;  //coordinates of the sides  
  int   bottomY;
  logic insideBracket;

  //////////--------------------------------------------------------------------------------------------------------------=

  always_comb begin
    rightX = (topLeftX + OBJECT_WIDTH_X);
    bottomY = (topLeftY + OBJECT_HEIGHT_Y);
    insideBracket  = 	 ( (pixelX  >= topLeftX) &&  (pixelX < rightX) // math is made with SIGNED variables  
    && (pixelY >= topLeftY) && (pixelY < bottomY));  // as the top left position can be negative
  end

  //////////--------------------------------------------------------------------------------------------------------------=
  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin

      drawingRequest <= 1'b0;
    end else begin
      // DEFUALT outputs

      drawingRequest <= 1'b0;  // transparent color 
      offsetX <= 0;  //no offset
      offsetY <= 0;  //no offset


      if (insideBracket && ball_moving) // test if it is inside the rectangle and ball is moving
		begin
        drawingRequest <= 1'b1;
        offsetX	<= (pixelX - topLeftX); //calculate relative offsets from top left corner allways a positive number 
        offsetY <= (pixelY - topLeftY);
      end

    end
  end
endmodule

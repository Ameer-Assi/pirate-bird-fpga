module pipe_object (
    input logic               clk,
    input logic               resetN,
    input logic signed [10:0] pixelX,    //  current VGA pixel 
    input logic signed [10:0] pixelY,
    input logic signed [11:0] topLeftX,  //position on the screen 
    input logic signed [10:0] topLeftY,  // can be negative , if the object is partliy outside 
    input logic        [ 7:0] GAP,

    output logic [10:0] offsetX,  // offset inside bracket from top left position 
    output logic [10:0] offsetY,
    output logic drawingRequest  // indicates pixel inside the bracket

);



  logic [7:0] TRANSPARENT_ENCODING = 8'hFF;
  const int OBJECT_WIDTH_X = 64;
  int rightX;  //coordinates of the sides  
  logic insideBracket;
  logic flag_bot;
  always_comb begin
    rightX = topLeftX + OBJECT_WIDTH_X;
    insideBracket = ( ( pixelX < rightX && pixelX >= topLeftX ) && (( pixelY <= 480 && pixelY >= topLeftY ) || ( pixelY >= 0 && pixelY <= (topLeftY - GAP) ) ) ); // bottom pipe and top pipe
    flag_bot = pixelY <= 480 && pixelY >= topLeftY;  // = 1 if (x,y) is inside the bottom pipe
  end

  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      drawingRequest <= 1'b0;
    end else begin
      // DEFUALT outputs
      drawingRequest <= 1'b0;
      offsetX <= 0;  //no offset
      offsetY <= 0;  //no offset
      if (insideBracket) // test if it is inside the rectangle 
		begin
        drawingRequest <= 1'b1;
        if (flag_bot) begin
          offsetX <= (pixelX - topLeftX);
          if (pixelY - topLeftY < 70) begin
            offsetY <= (pixelY - topLeftY);  // check if before the repeat point.
          end else begin  //after repeat point
            offsetY <= 70;
          end

        end else begin  // top pipe
          offsetX <= (rightX - 1 - pixelX);  //flip phone to understand
          if (topLeftY - GAP - pixelY < 70) begin
            offsetY <= topLeftY - GAP - pixelY;
          end else begin
            offsetY <= 70;
          end
          if (topLeftY <= 40 + GAP) begin
            drawingRequest <= 1'b0;
          end
        end  //top pipe else end

      end  //inside bracket if
    end  // else
  end  //ff block



endmodule

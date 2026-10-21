module letter_object (
    input logic clk,
    input logic resetN,
    input logic signed [10:0] pixelX,  //  current VGA pixel 
    input logic signed [10:0] pixelY,




    output logic [10:0] offsetX,  // offset inside bracket from top left position. max num of letters is 25.
    output logic [10:0] offsetY,
    output logic drawingRequest,  // indicates pixel inside the bracket
    output logic [7:0] char_code
);

  parameter logic signed [10:0] topLeftX = 200;
  parameter logic signed [10:0] topLeftY = 100;
  parameter logic [4:0] NUM_LETTERS = 9;
  parameter logic [0:8 * NUM_LETTERS - 1] sentence = "GAME OVER";
  parameter logic [2:0] SCALE = 0;

  localparam logic [10:0] CHAR_WIDTH = 8 << SCALE;
  localparam logic [10:0] CHAR_HEIGHT = 8 << SCALE;



  localparam X_BOUND = topLeftX + CHAR_WIDTH * NUM_LETTERS;
  localparam Y_BOUND = topLeftY + CHAR_HEIGHT;

  logic [4 : 0] char_index;
  logic [10 : 0] first_bit_of_char;
  logic insideBracket;
  always_comb begin

    insideBracket = (( pixelX >= topLeftX && pixelX < X_BOUND ) && (pixelY >= topLeftY && pixelY < Y_BOUND) );
    char_index = (pixelX - topLeftX) >> (3 + SCALE);
    first_bit_of_char = char_index * 8;
  end

  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      drawingRequest <= 1'b0;
    end else begin
      // DEFUALT outputs
      drawingRequest <= 1'b0;  // transparent color 
      offsetX <= 0;  //no offset
      offsetY <= 0;  //no offset


      if (insideBracket) begin  // test if it is inside the rectangle 
        drawingRequest <= 1'b1;
        offsetX <= (pixelX - topLeftX); //calculate relative offsets from top left corner allways a positive number 
        offsetY <= (pixelY - topLeftY);
        char_code <= sentence[first_bit_of_char+:8] - 65;  // char_index = (pixelX-topLeftX)>>3
        if (sentence[first_bit_of_char+:8] == 8'b00100000) begin  // " " (space)
          char_code <= 28;
        end else if (sentence[first_bit_of_char+:8] == 8'h3D) begin  // "="
          char_code <= 27;
        end else if (sentence[first_bit_of_char+:8] == 8'h3A) begin  // ":"
          char_code <= 26;
        end
      end
    end
  end


endmodule

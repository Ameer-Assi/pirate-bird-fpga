//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// System-Verilog Alex Grinshpun May 2018
// New coding convention dudy December 2018
// (c) Technion IIT, Department of Electrical Engineering 2021 


module heart_object (
    input logic clk,
    input logic resetN,
    input logic signed [10:0] pixelX,  // current VGA pixel 
    input logic signed [10:0] pixelY,
    input logic ability_flag,
    input logic collision,


    output logic [10:0] offsetX,  // offset inside bracket from top left position 
    output logic [10:0] offsetY,
    output logic drawingRequest,  // indicates pixel inside the bracket
    output logic [1:0] vers  //which heart version

);

  parameter int OBJECT_WIDTH_X = 32;
  parameter int OBJECT_HEIGHT_Y = 32;

  parameter logic signed [10:0] topLeftX = 11'b0;  //position on the screen 
  parameter logic signed [10:0] topLeftY = 11'b0;
  localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// bitmap  representation for a transparent pixel 
  localparam oneSecVal = 32'd31_500_000 - 1;

  int rightX;  //coordinates of the sides  
  int bottomY;
  logic insideBracket;
  logic [7:0] color;

  logic [24:0] oneSecCount;


  enum logic [2:0] {
    GOLDEN,
    CRACKED,
    CRACKED_X,
    VANISH
  } SM_Heart;

  //////////--------------------------------------------------------------------------------------------------------------=
  // Calculate object right  & bottom  boundaries
  assign rightX = (topLeftX + OBJECT_WIDTH_X);
  assign bottomY = (topLeftY + OBJECT_HEIGHT_Y);
  assign	insideBracket  = 	 ( (pixelX  >= topLeftX) &&  (pixelX < rightX) 
      && (pixelY >= topLeftY) && (pixelY < bottomY));


  //////////--------------------------------------------------------------------------------------------------------------=
  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      drawingRequest <= 1'b0;
      SM_Heart <= GOLDEN;
      oneSecCount <= 0;
      vers <= 0;

    end else begin  // DEFUALT
      drawingRequest <= insideBracket && ability_flag;
      offsetX <= (pixelX - topLeftX);
      offsetY <= (pixelY - topLeftY);

      case (SM_Heart)
        GOLDEN: begin
          if (ability_flag && collision) begin
            vers <= 1;
            SM_Heart <= CRACKED;
            oneSecCount <= 0;
          end
        end

        CRACKED: begin
          oneSecCount <= oneSecCount + 1;
          if (oneSecCount == oneSecVal) begin
            vers <= 2;
            SM_Heart <= CRACKED_X;
            oneSecCount <= 0;
          end

        end


        CRACKED_X: begin
          oneSecCount <= oneSecCount + 1;
          if (oneSecCount == oneSecVal) begin
            vers <= 3;
            SM_Heart <= VANISH;
            oneSecCount <= 0;
          end

        end



        VANISH: begin

          oneSecCount <= oneSecCount + 1;
          if (oneSecCount == oneSecVal) begin
            vers <= 0;
            SM_Heart <= GOLDEN;
            oneSecCount <= 0;
          end

        end

      endcase





    end
  end
endmodule

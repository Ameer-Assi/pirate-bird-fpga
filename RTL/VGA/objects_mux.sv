
// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module objects_mux (
    //		--------	Clock Input	 	
    input logic clk,
    input logic resetN,
    // smiley 
    input logic smileyDrawingRequest,  // two set of inputs per unit
    input logic [7:0] smileyRGB,

    // add the box here 

    input logic numberDrawingRequest_ones,
    input logic [7:0] RGBnum_ones,
    ////////////////////////
    // background 
    input    logic PipeDrawingRequest1,
    input  logic [7:0] pipeRGB1,
    input    logic PipeDrawingRequest2,
    input  logic [7:0] pipeRGB2,
    input    logic PipeDrawingRequest3,
    input  logic [7:0] pipeRGB3,
    input  logic [7:0] RGB_MIF,
    input logic GameOverDR,
    input logic [7:0] gameOver_RGB,
    input logic numberDrawingRequest_tens,
    input logic [7:0] RGBnum_tens,
    input logic text1DR,
    input logic [7:0] text1RGB,
    input logic text2DR,
    input logic [7:0] text2RGB,
    input logic text3DR,
    input logic [7:0] text3RGB,
    input logic text4DR,
    input logic [7:0] text4RGB,
    input logic max_ones_dr,
    input logic [7:0] max_ones_RGB,
    input logic max_tens_dr,
    input logic [7:0] max_tens_RGB,
    input logic heartDR,
    input logic [7:0] RGBheart,
    input logic ball_dr,
    input logic [7:0] ball_RGB,
    input logic cannon_dr,
    input logic [7:0] cannon_RGB,


    output logic [7:0] RGBOut
);

  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      RGBOut <= 8'b0;
    end else begin

      if (numberDrawingRequest_ones == 1'b1)
        RGBOut <= RGBnum_ones;  // in order for number to show up at gameover screen its placed 1st
      else if (numberDrawingRequest_tens) RGBOut <= RGBnum_tens;

      else if (max_ones_dr) RGBOut <= max_ones_RGB;

      else if (max_tens_dr) RGBOut <= max_tens_RGB;



      else if (text1DR) RGBOut <= text1RGB;  // "game over"

      else if (text2DR) RGBOut <= text2RGB;  // "score : "

      else if (text3DR) RGBOut <= text3RGB;  // "best = "

      else if (text4DR) RGBOut <= text4RGB;  // "press enter to play again"

      else if (GameOverDR) RGBOut <= gameOver_RGB;  // gameover screen

      else if (ball_dr) RGBOut <= ball_RGB;

      else if (cannon_dr) RGBOut <= cannon_RGB;

      else if (heartDR) RGBOut <= RGBheart;

      else if (smileyDrawingRequest == 1'b1) RGBOut <= smileyRGB;

      else if (PipeDrawingRequest1 == 1'b1) RGBOut <= pipeRGB1;

      else if (PipeDrawingRequest2 == 1'b1) RGBOut <= pipeRGB2;

      else if (PipeDrawingRequest3 == 1'b1) RGBOut <= pipeRGB3;

      else RGBOut <= RGB_MIF;  // last priority 
    end
  end

endmodule



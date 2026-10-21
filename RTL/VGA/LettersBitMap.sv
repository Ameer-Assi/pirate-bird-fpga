module LettersBitMap (
    input logic clk,
    input logic resetN,
    input logic [10:0] offsetX,  // offset inside bracket from top left position. max num of letters is 25.
    input logic [10:0] offsetY,
    input logic [7:0] char_code,
    input logic InsideRectangle,
    input logic isGameOver,



    output logic    drawingRequest, //output that the pixel should be dispalyed 
    output logic [7:0]  RGBout
);

  parameter logic [7:0] COLOR = 8'hF8;
  parameter logic [2:0] SCALE = 0;

  localparam logic [3:0] CHAR_WIDTH = 8;
  localparam logic [3:0] CHAR_HEIGHT = 8;
  localparam logic [8:0] letter_location_MIF = CHAR_HEIGHT * CHAR_WIDTH;






  logic draw_flag;
  logic [10:0] address;

  always_comb begin
    address = (char_code * letter_location_MIF) + (offsetY >> SCALE) * CHAR_WIDTH + (offsetX[SCALE +: 3]);
  end

  lpm_rom #(
      .LPM_WIDTH             (1),
      .LPM_WIDTHAD           (11),
      .LPM_NUMWORDS          (2048),
      .LPM_FILE              ("RTL/font_letters_8x8.mif"),
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
      .q(draw_flag)
  );
  logic InsideRectangle_d;
  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      drawingRequest <= 1'b0;
      InsideRectangle_d <= 1'b0;

    end else begin
      drawingRequest <= 1'b0;
      InsideRectangle_d <= InsideRectangle; // in order for insideRectangle to be for the same pixel.
      if (InsideRectangle_d == 1'b1) begin
        drawingRequest <= draw_flag && isGameOver;
      end
    end
  end

  assign RGBout = COLOR;

endmodule

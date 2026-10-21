module ball_bitmap (
    input logic clk,
    input logic resetN,
    input logic [10:0] offsetX,  // offset inside bracket from top left position. max num of letters is 25.
    input logic [10:0] offsetY,
    input logic InsideRectangle,

    output logic    drawingRequest, //output that the pixel should be dispalyed 
    output logic [7:0]  RGBout
);


  localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// bitmap  representation for a transparent pixel 
  logic [7:0] color;
  logic [7:0] address;
  assign address = {offsetY[3:0], offsetX[3:0]};


  lpm_rom #(
      .LPM_WIDTH             (8),
      .LPM_WIDTHAD           (8),
      .LPM_NUMWORDS          (256),
      .LPM_FILE              ("RTL/cannonball.mif"),
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





  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      drawingRequest <= 1'b0;


    end else begin
      drawingRequest <= 1'b0;
      if (InsideRectangle == 1'b1) begin
        RGBout <= color;
        drawingRequest <= (color != TRANSPARENT_ENCODING) ? 1'b1 : 1'b0;
      end
    end
  end

endmodule

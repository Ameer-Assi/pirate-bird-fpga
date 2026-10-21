//-- feb 2021 add all colors square 
// (c) Technion IIT, Department of Electrical Engineering 2025


module back_ground_draw (

    input logic clk,
    input logic resetN,
    input logic [10:0] pixelX,
    input logic [10:0] pixelY,
    input logic startOfFrame,
    input logic isGameOver,

    output logic [7:0] MIF_VGA,
    output logic [7:0] gameOver_RGB,
    output logic gameOver_DR
);



  logic [16:0] address;
  logic [ 7:0] scrollX;
  logic [ 7:0] bg_x;
  logic [16:0] address_gameover;

  assign bg_x = pixelX[7:0] + scrollX;
  assign address = {pixelY[8:0], bg_x};
  assign address_gameover = (pixelY >> 1) * 320 + (pixelX >> 1);     //bg_width = 320

  lpm_rom #(
      .LPM_WIDTH             (8),
      .LPM_WIDTHAD           (17),
      .LPM_NUMWORDS          (122880),
      .LPM_FILE              ("RTL/sea_bg.mif"),
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
      .q(MIF_VGA)
  );
  lpm_rom #(
      .LPM_WIDTH             (8),
      .LPM_WIDTHAD           (17),
      .LPM_NUMWORDS          (76800),
      .LPM_FILE              ("RTL/gameover_bg.mif"),
      .LPM_TYPE              ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL   ("REGISTERED"),
      .LPM_OUTDATA           ("UNREGISTERED"),
      .AUTO_CARRY_CHAINS     ("ON"),
      .AUTO_CASCADE_BUFFERS  ("ON"),
      .INTENDED_DEVICE_FAMILY("Cyclone V")
  ) rom_inst2 (
      .address(address_gameover),
      .inclock(clk),
      // .outclock(clk),
      .q(gameOver_RGB)
  );
  logic [24:0] oneSecCount;
  localparam oneSecVal = 32'd31_500_000;

  logic [1:0] sec_cnt;

  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      scrollX <= 0;
      gameOver_DR <= 0;
      sec_cnt <= 0;
      oneSecCount <= 0;

    end else begin
      if (startOfFrame && !isGameOver) begin
        scrollX <= scrollX + 2'b11;
      end
      if (isGameOver) begin
        oneSecCount <= oneSecCount + 1'b1;
        if (oneSecCount >= oneSecVal) begin
          sec_cnt <= sec_cnt + 1'b1;
          oneSecCount <= 0;
        end
        if (sec_cnt == 2'b10) begin
          gameOver_DR <= 1'b1;
          oneSecCount <= 0;
          sec_cnt <= 0;
        end
      end // is game over
    else begin
        gameOver_DR <= 1'b0;
        oneSecCount <= 0;
        sec_cnt <= 0;
      end
    end
  end
endmodule


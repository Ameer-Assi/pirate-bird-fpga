
module circle_object (
    input logic clk,
    input logic resetN,
    input logic signed [20:0] X_center,  //position on the screen, fixed point: [20:10] pixel, [9:0] 1/1024 pixel fraction
    input logic signed [20:0] Y_center,
    input logic startOfFrame,
    input logic ball_moving,
    input logic [1:0] cannon_vers,

    output logic signed [10:0] topLeftX,  // offset inside bracket from top left position 
    output logic signed [10:0] topLeftY
);

  parameter int OBJECT_WIDTH_X = 16;
  parameter int OBJECT_HEIGHT_Y = 16;
  const int FIXED_POINT_MULTIPLIER = 1024;

  parameter int RADIUS = 30;
  parameter int ANGLE_STEP = 10;  // degrees per frame, must divide 90. 360 / 10 = 36 frames per orbit = 5 orbits per flight (ball_move FLIGHT_FRAMES = 180)
  int orbit_X;  // circle center shifted back by the angle 0 offset, so the ball starts (and ends a full orbit) on X_center,Y_center
  int orbit_Y;
  int topLeftX_tmp;
  int topLeftY_tmp;
  int X_position;
  int Y_position;
  int start_angle_x;
  int start_angle_y;

  enum logic [2:0] {
    IDLE_ST,
    QUARTER_1ST,
    QUARTER_2ND,
    QUARTER_3RD,
    QUARTER_4TH
  } SM_Quarter;



  always_comb begin  // to set x,y corresponding to start_angle of the cannon 
    /* we couldve added a % for the angels but 5 of them would be too expensive compared to what we did */
    case (cannon_vers)  // look at cannon feature note in ipad
      0: begin
        start_angle_x = 989;
        start_angle_y = -265;
      end

      1: begin
        start_angle_x = 838;
        start_angle_y = -587;
      end

      2: begin
        start_angle_x = 587;
        start_angle_y = -838;
      end

      3: begin
        start_angle_x = 265;
        start_angle_y = -989;
      end
    endcase
    orbit_X = X_center - RADIUS * start_angle_x;  // RADIUS * start_angle = ball offset at alpha 0
    orbit_Y = Y_center - RADIUS * start_angle_y;
  end
  logic [21:0] q;
  logic signed [11:0] sin_val;
  logic signed [11:0] cos_val;
  logic [6:0] alpha;  // 0 <= alpha <= 90

  lpm_rom #(
      .LPM_WIDTH             (22),
      .LPM_WIDTHAD           (7),
      .LPM_NUMWORDS          (128),
      .LPM_FILE              ("RTL/trig_lut.mif"),
      .LPM_TYPE              ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL   ("REGISTERED"),
      .LPM_OUTDATA           ("UNREGISTERED"),
      .AUTO_CARRY_CHAINS     ("ON"),
      .AUTO_CASCADE_BUFFERS  ("ON"),
      .INTENDED_DEVICE_FAMILY("Cyclone V")
  ) rom_inst (
      .address(alpha),
      .inclock(clk),
      .q(q)
  );

  assign cos_val = q[10:0];  // 1024 * cos(alpha)
  assign sin_val = q[21:11];  // 1024 * sin(alpha)
  int x_pos_real;
  int y_pos_real;



  //////////--------------------------------------------------------------------------------------------------------------=
  always_ff @(posedge clk or negedge resetN) begin
    //////////-------------------------------------------------------------------------------------------------------


    if (!resetN) begin
      SM_Quarter <= IDLE_ST;
      alpha <= 0;
      X_position <= 0;
      Y_position <= 0;
    end else begin

      if (!ball_moving) begin
        SM_Quarter <= IDLE_ST;
        alpha <= 0;
      end
      case (SM_Quarter)
        IDLE_ST: begin
          X_position <= X_center;
          Y_position <= Y_center;
          if (ball_moving) begin
            SM_Quarter <= QUARTER_1ST;
          end
        end


        QUARTER_1ST: begin
          x_pos_real = (RADIUS * cos_val);  // relative to circle center
          y_pos_real = (RADIUS * sin_val);
          X_position <= ( (x_pos_real * start_angle_x - y_pos_real * start_angle_y) >>> 10 ) + orbit_X;
          Y_position <= ( (y_pos_real * start_angle_x + x_pos_real * start_angle_y) >>> 10 ) + orbit_Y;

          if (startOfFrame) begin
            alpha <= alpha + ANGLE_STEP;
            if (alpha >= 90 - ANGLE_STEP) begin
              SM_Quarter <= QUARTER_2ND;
            end
          end
        end




        QUARTER_2ND: begin
          x_pos_real = (RADIUS * -cos_val);  // relative to circle center
          y_pos_real = (RADIUS * sin_val);
          X_position <= ( (x_pos_real * start_angle_x - y_pos_real * start_angle_y) >>> 10 ) + orbit_X;
          Y_position <= ( (y_pos_real * start_angle_x + x_pos_real * start_angle_y) >>> 10 ) + orbit_Y;

          if (alpha <= 0) begin
            SM_Quarter <= QUARTER_3RD;
          end

          if (startOfFrame) begin
            alpha <= alpha - ANGLE_STEP;
          end
        end




        QUARTER_3RD: begin
          x_pos_real = (RADIUS * -cos_val);  // relative to circle center
          y_pos_real = (RADIUS * -sin_val);
          X_position <= ( (x_pos_real * start_angle_x - y_pos_real * start_angle_y) >>> 10 ) + orbit_X;
          Y_position <= ( (y_pos_real * start_angle_x + x_pos_real * start_angle_y) >>> 10 ) + orbit_Y;

          if (alpha == 90) begin
            SM_Quarter <= QUARTER_4TH;
          end

          if (startOfFrame) begin
            alpha <= alpha + ANGLE_STEP;
          end
        end






        QUARTER_4TH: begin
          x_pos_real = (RADIUS * cos_val);  // relative to circle center
          y_pos_real = (RADIUS * -sin_val);
          X_position <= ( (x_pos_real * start_angle_x - y_pos_real * start_angle_y) >>> 10 ) + orbit_X;
          Y_position <= ( (y_pos_real * start_angle_x + x_pos_real * start_angle_y) >>> 10 ) + orbit_Y;

          if (alpha <= 0) begin
            SM_Quarter <= QUARTER_1ST;
          end

          if (startOfFrame) begin
            alpha <= alpha - ANGLE_STEP;
          end
        end

      endcase



    end  // else for the if(!resetN) 

  end  //always ff block

  // round to the nearest pixel 
  assign topLeftX_tmp = (X_position + FIXED_POINT_MULTIPLIER / 2) >>> 10;
  assign topLeftY_tmp = (Y_position + FIXED_POINT_MULTIPLIER / 2) >>> 10;

  assign topLeftX = {topLeftX_tmp[10:0]};
  assign topLeftY = {topLeftY_tmp[10:0]};


endmodule

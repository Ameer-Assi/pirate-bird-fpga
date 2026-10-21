module ball_move (
    input logic clk,
    input logic resetN,
    input logic startOfFrame,
    input logic shoot_signal,
    input logic signed [10:0] bird_TLY,
    input logic signed [10:0] bird_TLX,
    input logic signed [10:0] cannon_TLY,
    input logic signed [10:0] cannon_TLX,
    input logic [1:0] cannon_vers,
    input logic isGameOver,

    output logic signed [20:0] X_cent,  // circle center, fixed point: [20:10] pixel, [9:0] 1/1024 pixel fraction
    output logic signed [20:0] Y_cent,  // can be negative , if the object is partliy outside
    output logic ball_moving
);




  parameter int FLIGHT_FRAMES = 180;  // till the ball reachs the bird, = one full orbit in circle_object (180 * 2 deg)
  localparam int FRAMES_RECIP = 65536 / FLIGHT_FRAMES;  // dividing by 180 is expesnive, so we multiply by 1/180 (scaled to a whole int), 65536 = 2^16


  const int FIXED_POINT_MULTIPLIER = 1024;  // note it must be 2^n , same as circle_object so the center passes through as is

  enum logic [1:0] {
    IDLE_ST,             // initial state
    MOVE_ST,
    POSITION_CHANGE_ST,  // position interpolate 
    BOUND_CHECK_ST
  } SM_Motion;

  int X_center;
  int Y_center;
  int Xstep;  // distance moved every frame, set once when shooting
  int Ystep;

  int bird_TLX_mult;
  int bird_TLY_mult;
  int start_X;  // cannon mouth = where the flight starts
  int start_Y;

  int cannon_TLY_mult;
  int cannon_TLX_mult;

  always_comb begin
    bird_TLX_mult   = bird_TLX * FIXED_POINT_MULTIPLIER;
    bird_TLY_mult   = bird_TLY * FIXED_POINT_MULTIPLIER;
    cannon_TLY_mult = cannon_TLY * FIXED_POINT_MULTIPLIER;
    cannon_TLX_mult = cannon_TLX * FIXED_POINT_MULTIPLIER;
  end

  always_comb begin  // where to set circle center
    case (cannon_vers)
      0: begin
        start_X = cannon_TLX_mult + 14 * FIXED_POINT_MULTIPLIER;
        start_Y = cannon_TLY_mult + 26 * FIXED_POINT_MULTIPLIER;
      end
      1: begin
        start_X = cannon_TLX_mult + 18 * FIXED_POINT_MULTIPLIER;
        start_Y = cannon_TLY_mult + 18 * FIXED_POINT_MULTIPLIER;
      end
      2: begin
        start_X = cannon_TLX_mult + 25 * FIXED_POINT_MULTIPLIER;
        start_Y = cannon_TLY_mult + 11 * FIXED_POINT_MULTIPLIER;
      end
      3: begin
        start_X = cannon_TLX_mult + 33 * FIXED_POINT_MULTIPLIER;
        start_Y = cannon_TLY_mult + 7 * FIXED_POINT_MULTIPLIER;
      end
    endcase
  end


  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      X_center <= 0;
      Y_center <= 0;
      SM_Motion <= IDLE_ST;
      ball_moving <= 0;
      Xstep <= 0;
      Ystep <= 0;
    end else begin
      if (isGameOver) begin
        SM_Motion <= IDLE_ST;
      end
      case (SM_Motion)


        IDLE_ST: begin
          X_center <= 0;
          Y_center <= 0;
          ball_moving <= 0;
          if (shoot_signal) begin
            SM_Motion <= MOVE_ST;
            ball_moving <= 1;
            X_center <= start_X;
            Y_center <= start_Y;
            Xstep <= ((start_X - bird_TLX_mult) * FRAMES_RECIP) >>> 16;  // aim at where the bird is when shot
            Ystep <= ((start_Y - bird_TLY_mult) * FRAMES_RECIP) >>> 16;
          end
        end  // idle

        MOVE_ST: begin
          if (startOfFrame) begin
            SM_Motion <= POSITION_CHANGE_ST;
          end
        end

        POSITION_CHANGE_ST: begin
          X_center  <= X_center - Xstep;
          Y_center  <= Y_center - Ystep;
          SM_Motion <= BOUND_CHECK_ST;

        end  // position


        BOUND_CHECK_ST: begin
          SM_Motion <= MOVE_ST;
          if (X_center <= 0 || Y_center <= 0) begin
            SM_Motion <= IDLE_ST;
          end

        end

      endcase  // SM_motion case


    end  // resetN else end

  end  // end fsm_sync


  // keep the fraction, circle_object rounds to whole pixels at its output

  assign X_cent = X_center[20:0];
  assign Y_cent = Y_center[20:0];


endmodule

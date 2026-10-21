module pipe_move (

    input logic clk,
    input logic resetN,
    input logic startOfFrame,  //short pulse every start of frame 30Hz
    input logic flag,  // when to decrease speed;(after 5 points)
    input logic cheat,
    input logic plus_key,
    input logic minus_key,
    input logic signed [10:0] bird_TLX,  // for score logic
    input logic isGameOver,
    input logic startGame,  // from smiley_move
    input logic keyPadValid,  // for random y
    input logic signed [11:0] pre_pipeTLX,  // the "earlier pipe TLX"
    input logic signed [10:0] bird_TLY,  // for boss_pipe y_speed
    input logic boss_flag,  // = 1 when passes 10 pipes
    output logic signed [11:0] topLeftX,  // output the top left corner 
    output logic signed [10:0] topLeftY,  // can be negative , if the object is partliy outside 	
    output logic bird_score,  // if the bird passes the pipe
    output logic [7:0] GAP
);


  logic [9:0] random_y;  //from 70 + GAP to 410
  logic [7:0] random_gap;  // from 60 to 200.
  logic [9:0] random_deltaX; // from 72v_pipe + 67 to 600, always positive. (horizontal distance between two pipes)

  random #(  // random gap
      .SIZE_BITS(10),
      .MIN_VAL  (100),
      .MAX_VAL  (200)
  ) rnd_gap (
      .clk(clk),
      .resetN(resetN),
      .rise(keyPadValid),
      .dout(random_gap)
  );

  logic [9:0] min_delta_x;
  logic [9:0] min_y;
  always_comb begin

    // min_delta_x = 60 * (-Xspeed / 64) + 50; 
    min_delta_x = 270;

    min_y = 70 + random_gap_ff;

  end


  random_new rnd_deltaX (  //random delta x
      .clk(clk),
      .resetN(resetN),
      .rise(gap_set_flag),
      .dout(random_deltaX),
      .max_val(600),
      .min_val(min_delta_x)
  );

  random_new rnd_y (  //random y
      .clk(clk),
      .resetN(resetN),
      .rise(gap_set_flag),
      .dout(random_y),
      .max_val(410),
      .min_val(min_y)
  );



  int topLeftX_tmp;
  int topLeftY_tmp;
  parameter int INITIAL_X = 640;
  parameter int INITIAL_Y = 300;
  parameter int INITIAL_X_SPEED = -160;
  parameter int Y_SPEED = 60;

  const logic signed [10:0] FIXED_POINT_MULTIPLIER = 64;
  localparam int MAX_SPEED = 340;
  localparam int V_ACCEL = 40;

  enum logic [2:0] {
    IDLE_ST,             // initial state 
    MOVE_ST,             // updating pipe speed
    POSITION_CHANGE_ST,  // position interpolate 
    BOUNDS_CHECK,
    GAME_OVER

  } SM_Motion;

  logic [9:0] random_y_ff;  // flip flop
  logic [7:0] random_gap_ff;  // flip flop
  logic signed [10:0] random_deltaX_ff;

  int Xspeed;
  int Yspeed;  // only for boss pipe
  int Xposition;  //position   
  int Yposition;
  logic plus_d;  //cheat
  logic minus_d;  // cheat
  logic bird_flag;  // 1 when bird crossed the pipe for the 1st time
  logic flag_d;  // in order to increase speed , when passing a num of pipes, at rising edge.
  logic gap_set_flag;  // for rnd deltaX and rnd_y as a rise signal. 

  always_ff @(posedge clk or negedge resetN) begin : fsm_sync_proc
    if (resetN == 1'b0) begin
      SM_Motion <= IDLE_ST ;
      Xspeed <= 0  ;
      plus_d <= 0;
      Yspeed <= 0;
      Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER  ;
      Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER   ;
      random_gap_ff <= 128;


    end else begin
      if (isGameOver) begin
        SM_Motion <= GAME_OVER;
      end
      case (SM_Motion)
        //------------
        IDLE_ST: begin
          //------------
          bird_score <= 0;
          Xspeed <= INITIAL_X_SPEED;
          Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
          Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
          bird_flag <= 0;
          gap_set_flag <= 0;


          random_gap_ff <= 128;

          if (startGame) begin
            SM_Motion <= MOVE_ST;
          end

        end  //idle

        //------------
        MOVE_ST: begin  //updating pipe's speed
          //------------
          bird_score <= 0;
          plus_d <= plus_key;
          minus_d <= minus_key;
          flag_d <= flag;
          gap_set_flag <= 0;


          // boss pipe logic
          Yspeed <= Y_SPEED;
          // if (bird_TLY * FIXED_POINT_MULTIPLIER == Yposition) begin
          //   Yspeed <= 0;
          // end else
          if (bird_TLY * FIXED_POINT_MULTIPLIER < Yposition) begin
            Yspeed <= -Y_SPEED;
          end
          //boss pipe logic end


          if (flag && !flag_d) begin  //if pass score then increase speed
            Xspeed <= Xspeed - V_ACCEL;
            if (Xspeed - V_ACCEL <= -MAX_SPEED) Xspeed <= -MAX_SPEED;  //max pipe speed
          end

          if (cheat) begin
            if (plus_key && !plus_d) begin
              Xspeed <= Xspeed - V_ACCEL;
              if (Xspeed - V_ACCEL <= -MAX_SPEED) Xspeed <= -MAX_SPEED;  //max pipe speed
            end

            if (minus_key && !minus_d) begin
              Xspeed <= Xspeed + V_ACCEL;
              if (Xspeed + V_ACCEL >= MAX_SPEED) Xspeed <= MAX_SPEED;  //max pipe speed
            end

          end  //cheat

          if (startOfFrame) begin
            SM_Motion <= POSITION_CHANGE_ST;   // there is some time before visible pixels get drawn (front porch)
          end

        end  //move

        //------------------------
        POSITION_CHANGE_ST: begin  // position interpolate 
          //------------------------

          Xposition <= Xposition + Xspeed;
          if (boss_flag) begin
            Yposition <= Yposition + Yspeed;
          end

          random_y_ff <= random_y;
          random_deltaX_ff <= random_deltaX;

          SM_Motion <= BOUNDS_CHECK;

        end  //position

        BOUNDS_CHECK: begin //return to right-most screen position if pipe at (-100,y) + bird score logic.


          if (topLeftX <= -80) begin
            random_gap_ff <= random_gap;
            /*
            if (boss_flag) begin  // for boss flag gap is const, so pipes can move up and down.
              random_gap_ff <= 100;
            end
            */
            gap_set_flag  <= 1'b1;  // for random module, behaves as rise signal.
          end


          if (topLeftX <= -100) begin  // pipe return
            if (random_deltaX_ff + pre_pipeTLX <= 642) begin
              Xposition <= ( 645 - (random_deltaX_ff + pre_pipeTLX) + (random_deltaX_ff + pre_pipeTLX)) * FIXED_POINT_MULTIPLIER;
            end else begin
              Xposition <= (random_deltaX_ff + pre_pipeTLX) * FIXED_POINT_MULTIPLIER;
            end
            Yposition <= random_y_ff * FIXED_POINT_MULTIPLIER;
            bird_flag <= 1'b0; // to score once per "round"(till the pipe returns to x = ~480 we set flag = 0 so we know when bird crosses it)
          end


          if (bird_TLX > (topLeftX + 64) && !bird_flag) begin  // bird crossed the pipe for the 1st time
            bird_score <= 1'b1;  // up for only one clock
            bird_flag  <= 1'b1;
          end

          /* was to bound pipe top y.
           if (topLeftY <= 70 + random_gap_ff) begin  // for boss_pipe.
             Yposition <= (70 + random_gap_ff) * FIXED_POINT_MULTIPLIER;
           end
          */

          SM_Motion <= MOVE_ST;

        end

        GAME_OVER: begin
          Xspeed <= 0;
          if (!isGameOver) begin  //for when we restart
            SM_Motion <= IDLE_ST;
          end
        end

      endcase  // case 


    end

  end  // end fsm_sync
  assign GAP = random_gap_ff;
  assign topLeftX_tmp = Xposition / FIXED_POINT_MULTIPLIER;
  assign topLeftY_tmp = Yposition / FIXED_POINT_MULTIPLIER;

  assign topLeftX = {topLeftX_tmp[11:0]};
  assign topLeftY = {topLeftY_tmp[10:0]};


endmodule

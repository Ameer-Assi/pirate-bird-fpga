// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal MAR 2024   
// good practice code - Dudy MAR 2025  ert

module smiley_move (

    input logic clk,
    input logic resetN,
    input logic startOfFrame,  //short pulse every start of frame 30Hz 
    input logic Y_direction_key,  //move Y Up
    input logic isGameOver,
    input logic ability,
    input logic cheat,
    input logic reverse_mode,
    output logic signed [10:0] topLeftX,  // output the top left corner 
    output logic signed [10:0] topLeftY,  // can be negative , if the object is partliy outside 
    output logic speed_sign,  // for bird rotation
    output logic startGame,  // to send to pipe in order to start
    output logic borders_reach  // to send to game controller to end game if reaches border

);
  logic signed [1:0] reverse_sign;
  int topLeftX_tmp;  // output the top left corner 
  int topLeftY_tmp;  // can be negative , if the object is partliy outside 

  // a module used to generate the  ball trajectory.  
  parameter int INITIAL_X = 215;
  parameter int INITIAL_Y = 40;
  parameter int INITIAL_Y_SPEED = 20;
  parameter int Y_ACCEL = -20;

  //const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
  const logic signed [10:0] FIXED_POINT_MULTIPLIER = 64;  // note it must be 2^n 
  // FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
  // we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
  // we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


  // movement limits 
  const int OBJECT_HIGHT_Y = 32;
  const int SafetyMargin = 2;

  const int y_FRAME_TOP = (SafetyMargin) * FIXED_POINT_MULTIPLIER;
  const
  int
  y_FRAME_BOTTOM	=	(479 -SafetyMargin - OBJECT_HIGHT_Y ) * FIXED_POINT_MULTIPLIER; //- OBJECT_HIGHT_Y

  //edges 
  //------------
  //			 434
  //			 1x2
  //			 404
  //




  enum logic [2:0] {
    IDLE_ST,             // initial state
    MOVE_ST,             // moving no colision 
    POSITION_CHANGE_ST,  // position interpolate 
    POSITION_LIMITS_ST,  // check if inside the frame  
    GAME_OVER
  } SM_Motion;


  int Yspeed;
  int Xposition;  //position   
  int Yposition;

  logic Y_direction_key_D;


  //---------

  always_ff @(posedge clk or negedge resetN) begin : fsm_sync_proc

    if (resetN == 1'b0) begin
      SM_Motion <= IDLE_ST ;
      Yspeed <= 0  ;
      startGame <= 1'b0;
      borders_reach <= 0;
      //		Xposition <= 0  ; 
      //		Yposition <= 0   ; 
      Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER  ;
      Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER   ;

    end else begin
      if (isGameOver) begin
        SM_Motion <= GAME_OVER;
      end

      Y_direction_key_D <= Y_direction_key;  //shift register to detect edge 

      case (SM_Motion)

        //------------
        IDLE_ST: begin
          //------------

          startGame <= 1'b0;
          Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
          Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;

          if (Y_direction_key && !Y_direction_key_D) begin
            SM_Motion <= MOVE_ST;
            Yspeed <= INITIAL_Y_SPEED * reverse_sign;
            startGame <= 1'b1;
          end

        end

        //------------
        MOVE_ST: begin  // moving collecting colisions 
          //------------
          // keys direction change 
          if (Y_direction_key && !Y_direction_key_D)  //  while moving down
            Yspeed <= -300 * reverse_sign;


          if (startOfFrame) begin
            SM_Motion <= POSITION_CHANGE_ST;
          end



        end


        //------------------------
        POSITION_CHANGE_ST: begin  // position interpolate 
          //------------------------
          startGame <= 1'b0;  // startGame surely reached pipe_move by now (2 clks)
          Yposition <= Yposition + Yspeed;

          // accelerate 

          if (Yspeed < 600)  //  limit the speed while going down 
            Yspeed <= Yspeed + Y_ACCEL * reverse_sign;  // gravity 


          SM_Motion <= POSITION_LIMITS_ST;
        end

        //------------------------
        POSITION_LIMITS_ST: begin  //check if still inside the frame 
          //------------------------
          if (Yposition < y_FRAME_TOP) begin
            Yposition <= y_FRAME_TOP;
          end
          if (Yposition > y_FRAME_BOTTOM) begin
            Yposition <= y_FRAME_BOTTOM;
          end
          if ((Yposition < y_FRAME_TOP || Yposition > y_FRAME_BOTTOM) && !(ability || cheat)) begin
            borders_reach <= 1'b1;
          end else SM_Motion <= MOVE_ST;
        end

        GAME_OVER: begin
          Yspeed <= 0;
          if (!isGameOver) begin
            SM_Motion <= IDLE_ST;
            borders_reach <= 1'b0;
          end
        end

      endcase  // case 


    end

  end  // end fsm_sync


  //return from FIXED point trunc back to prame size parameters 

  assign topLeftX_tmp = Xposition / FIXED_POINT_MULTIPLIER;  // note it must be 2^n 
  assign topLeftY_tmp = Yposition / FIXED_POINT_MULTIPLIER;

  assign topLeftX = {topLeftX_tmp[10:0]};  // note it must be 2^n 
  assign topLeftY = {topLeftY_tmp[10:0]};
  assign speed_sign = (Yspeed > 0) ? 1'b1 : 1'b0;

  always_comb begin
    if (reverse_mode) begin
      reverse_sign = -1;
    end else begin
      reverse_sign = 1;
    end
  end


endmodule
//---------------


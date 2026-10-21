
// game controller dudy Febriary 2020
// (c) Technion IIT, Department of Electrical Engineering 2021 
//updated --Eyal Lev 2021


module game_controller (
    input logic clk,
    input logic resetN,
    input logic drawing_request_smiley,



    // drawing_request_smiley   -->  smiley
    // drawing_request_boarders -->  brackets
    // drawing_request_number   -->  number/box 

    //---------------------#2-add  drawing request of pipe

    input logic drawing_request_pipe,

    //---------------------#2-end drawing request of pipe		
    input logic pass_pipe,  // when bird passes a pipe
    input logic cheat,
    input logic borders_reach,
    input logic enter_key,  // for restart
    input logic ball_dr,

    output logic [3:0] score_ones,  // ones score
    output logic [3:0] score_tens,  // tens score
    output logic score_speedup_flag,
    output logic score_ability_flag,
    output logic isGameOver,
    output logic [3:0] score_ones_max,  // max ones score
    output logic [3:0] score_tens_max,  // max tens score
    output logic collision_flag,
    output logic boss_flag,
    output logic shoot_signal
);

  //-------------------------- #6-add colision between Smiley and pipe-----------------
  logic collision_Smiley_Pipe;  // active in case of collision between Smiley and pipe

  assign collision_Smiley_Pipe = (drawing_request_smiley && drawing_request_pipe) && !( cheat || score_ability_flag) && !isGameOver;

  //---------------------------#6-end colision betweenand Smiley and pipe-----------------
  logic collision_Smiley_Ball;

  assign collision_Smiley_Ball = (drawing_request_smiley && ball_dr) && !( cheat || score_ability_flag) && !isGameOver;



  logic [24:0] oneSecCount;
  localparam oneSecVal = 32'd31_500_000;

  logic [1:0] sec_cnt;
  logic [3:0] pass_cnt;  // 8
  logic [3:0] pass_cnt_ability;  //6
  logic [4:0] pass_cnt_boss;  //25


  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      isGameOver <= 1'b0;
      oneSecCount <= 0;
      score_ones <= 0;
      score_tens <= 0;
      collision_flag <= 1'b0;
      sec_cnt <= 0;
      score_ability_flag <= 0;
      score_ones_max <= 0;
      score_tens_max <= 0;
      pass_cnt <= 0;
      pass_cnt_ability <= 0;
      pass_cnt_boss <= 0;
      boss_flag <= 0;
      shoot_signal <= 0;



    end else begin
      score_speedup_flag <= 1'b0;
      shoot_signal <= 1'b0;
      if (pass_pipe) begin
        if (score_ones < 9) begin
          score_ones <= score_ones + pass_pipe;
        end else begin
          score_ones <= 0;
          score_tens <= score_tens + 1'b1;
        end
      end
      if (pass_pipe) begin
        pass_cnt <= pass_cnt + 1'b1;
        if (!score_ability_flag) begin
          pass_cnt_ability <= pass_cnt_ability + 1;
        end
        pass_cnt_boss <= pass_cnt_boss + 1;
      end  // pass pipe logic

      if (pass_cnt == 4'd8) begin
        score_speedup_flag <= 1'b1;
        pass_cnt <= 0;
        shoot_signal <= 1'b1;
      end  //speed up flag + shoot_signal

      if (pass_cnt_ability == 4'd6) begin
        score_ability_flag <= 1'b1;
        pass_cnt_ability   <= 0;

      end  // ability flag 


      if (pass_cnt_boss == 5'd25) begin  //boss pipe
        boss_flag <= 1'b1;
      end

      if (collision_flag) begin
        oneSecCount <= oneSecCount + 1'b1;
        if (oneSecCount >= oneSecVal) begin
          sec_cnt <= sec_cnt + 1'b1;
          oneSecCount <= 0;
        end

        if (sec_cnt == 2'b11) begin
          score_ability_flag <= 1'b0;
          collision_flag <= 1'b0;
          sec_cnt <= 0;
          oneSecCount <= 0;
        end  //sec_cnt = 3
      end
      if (((drawing_request_smiley && drawing_request_pipe) || (drawing_request_smiley && ball_dr)) && !cheat) begin
        collision_flag <= 1'b1;
      end

      if ((collision_Smiley_Pipe || borders_reach || collision_Smiley_Ball)) begin
        isGameOver <= 1'b1;
        if(score_tens > score_tens_max || ( score_tens_max == score_tens && score_ones > score_ones_max )) begin
          score_ones_max <= score_ones;
          score_tens_max <= score_tens;
        end
      end
      if (isGameOver) begin
        if (enter_key) begin
          isGameOver <= 1'b0;
          score_ability_flag <= 1'b0;
          pass_cnt <= 0;
          score_ones <= 0;
          score_tens <= 0;
          oneSecCount <= 0;
          sec_cnt <= 0;
          collision_flag <= 1'b0;
          pass_cnt_ability <= 0;
          pass_cnt_boss <= 0;
          boss_flag <= 0;
        end
      end

    end
  end
endmodule

//// game controller dudy Febriary 2020
//// (c) Technion IIT, Department of Electrical Engineering 2021 
////updated --Eyal Lev 2021
//
//
//module	game_controller	(	
//			input	logic	clk,
//			input	logic	resetN,
//			input	logic	startOfFrame,  // short pulse every start of frame 30Hz 
//			input	logic	drawing_request_smiley,
//			input	logic	drawing_request_boarders,
//
////---------------------#1-add input drawing request of box/number
//		
//		
//
////---------------------#1-end input drawing request of box/number
//
//
//
//
////---------------------#2-add  drawing request of hart
//
//		
//
////---------------------#2-end drawing request of hart		
//
//			
//			output logic collision, // active in case of collision between two objects
//			
//			output logic SingleHitPulse, // critical code, generating A single pulse in a frame 
//			
//			
//
////---------------------#3-add collision  smiley and hart   -------------------------------------
//
//
//		//	output logic collision_Smiley_Hart // active in case of collision between Smiley and hart
//
//
////---------------------#3-end collision  smiley and hart	--------------------------------------
//			
//
//
//);
//logic collision_smiley_number; // collision between Smiley and number - is not output
//
//// drawing_request_smiley   -->  smiley
//// drawing_request_boarders -->  brackets
//// drawing_request_number   -->  number/box 
//
////assign collision = (drawing_request_smiley && drawing_request_boarders);// any collision --> comment after updating with #4 or #5 
//
////---------------------#4-update  collision  conditions - add collision between smiley and number   ----------------------------
//
////assign collision = <collision_before> +<collision smiley and number>;
//
//
////---------------------#4-end update  collision  conditions	 - add collision between smiley and number	-------------------------
//	
//					
//						
//
////---------------------#5-update  collision  sconditions - add collision between smiley and hart  ---------------------------------
//
////assign collision = <collision_before> +( drawing_request_smiley && drawing_request_hart ); 
//	assign collision = (( drawing_request_smiley && ( drawing_request_boarders || drawing_request_number )) || 
//						( drawing_request_boarders && drawing_request_number )||( drawing_request_smiley && drawing_request_hart )); 
//
//
////---------------------#5-end update  collision  conditions	- add collision between smiley and hart	-----------------------------
//	
//
//
//
////-------------------------- #6-add colision between Smiley and hart-----------------
//
//assign collision_Smiley_Hart = ( drawing_request_smiley && drawing_request_hart ) ;
//assign collision_smiley_number = ( drawing_request_smiley &&  drawing_request_number ); // collision of number and smiley
//
////---------------------------#6-end colision betweenand Smiley and hart-----------------
//
//
//
//logic flag ; // a semaphore to set the output only once per frame regardless of number of collisions 
//
//
//always_ff@(posedge clk or negedge resetN)
//begin
//	if(!resetN)
//	begin 
//		flag	<= 1'b0;
//		SingleHitPulse <= 1'b0 ; 
//		
//	end 
//	else begin 
//	
////-------------------------- #7-add colision between Smiley and number-----------------
//
//
//
////-------------------------- #7-end colision between Smiley and number-----------------	
//		
//		
//			SingleHitPulse <= 1'b0 ; // default 
//			if(startOfFrame) 
//				flag <= 1'b0 ; // reset for next time 
//				
////	---#7 - change the condition below to collision between Smiley and number ---------
//
//if ( collision_smiley_number  && (flag == 1'b0)) begin 
//			flag	<= 1'b1; // to enter only once 
//			SingleHitPulse <= 1'b1 ; 
//		end ; 
// 
//	end 
//end
//
//endmodule
//
////// game controller dudy Febriary 2020
////// (c) Technion IIT, Department of Electrical Engineering 2025 
//////updated --Eyal Lev 2021
////
////
////module	game_controller	(	
////			input	logic	clk,
////			input	logic	resetN,
////			input	logic	startOfFrame,  // short pulse every start of frame 30Hz 
////			input	logic	drawing_request_smiley,
////			input	logic	drawing_request_boarders,
////			input	logic	drawing_request_number,
////			input	logic	drawing_request_hart,
////       // add the box here 
////			
////			output logic collision, // active in case of collision between two objects
////			
////			output logic SingleHitPulse, // critical code, generating A single pulse in a frame 
////			output logic collision_Smiley_Hart // active in case of collision between two objects
////			
////);
////
////
////logic collision_smiley_number;
////
////assign collision = (( drawing_request_smiley && ( drawing_request_boarders || drawing_request_number )) || 
////						( drawing_request_boarders && drawing_request_number )||( drawing_request_smiley && drawing_request_hart )); 
////						
////						
////assign collision_Smiley_Hart = ( drawing_request_smiley &&  drawing_request_hart ) ;
////assign collision_smiley_number = ( drawing_request_smiley &&  drawing_request_number ); // collision of number and smiley
////
////
////// add colision between number and Smiley
//////_______________________________________________________
////
////
////logic flag ; // a semaphore to set the output only once per frame / regardless of the number of collisions 
////
////
////always_ff@(posedge clk or negedge resetN)
////begin
////	if(!resetN)
////	begin 
////		flag	<= 1'b0;
////		SingleHitPulse <= 1'b0 ; 
////	end 
////	else begin 
////			SingleHitPulse <= 1'b0 ; // default 
////			if(startOfFrame) 
////				flag <= 1'b0 ; // reset for next time 
////				
//////		change the section below  to collision between number and smiley
////
////
////if ( collision_smiley_number  && (flag == 1'b0)) begin 
////			flag	<= 1'b1; // to enter only once 
////			SingleHitPulse <= 1'b1 ; 
////		end ; 
////
////	end 
////end
////
////endmodule

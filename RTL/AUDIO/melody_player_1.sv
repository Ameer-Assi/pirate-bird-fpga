//
// (c) Technion IIT, The Faculty of Electrical and Computer Engineering, 2025
//
//  PRELIMINARY VERSION  -  23 March 2025
//  Updated: March 29, 2026 - Gadi Shavit 
//

/*
typedef struct packed {
    logic [3:0] note;
    logic [2:0] octave;
    logic [7:0] duration;
    logic [7:0] gap;
} note_struct;
*/

localparam int NOTES_IN_A_SONG = 256;
localparam int SOUND_MEM_SIZE = 4096;
localparam int SOUND_ADDR_W = $clog2(SOUND_MEM_SIZE);

typedef logic [SOUND_ADDR_W-1:0] song_addr_t;

module melody_player_1 (
    // Declare wires and regs :
    input logic resetN,
    input logic CLOCK_31p5,
    input logic flap,  // selector of one melody  
    input logic gameOver,
    input logic shoot_signal,
    // input logic [15:0] songs_mem,		// input from songs.mif

    output logic [3:0] tone,
    output logic [2:0] octave,
    output logic       EnableSoundOut,  // controls AUDIO module on/off 
    output logic       melodyEnded      // indicates end of melody.  Also outputs to LED3      
    //output logic [11:0] note_address // output to audio MIF address 

);   // serial number of current note. ( maximum 31 ). noteIndex determines freqIndex and note_length, via JueBox

  // songs.vh contain a table of songs, including note_base, octave, duration and gap	
  //`include "songs.sv"

  // Maestro state machine declaration 
  enum logic [1:0] {
    s_idle,
    s_playNote,
    s_gap,
    s_ended
  } SM_Maestro;  // state machine

  // parameters declarations
  logic [5:0] note_address;  // {sound slot (2 bits), note (4 bits)} = 64 words
  logic [15:0] songs_mem;
  logic [4:0] noteTimeCounter;  // count down timer ( maximum 1024 )
  logic [4:0] noteDuration;
  logic [4:0] gapDuration;  // time of gap between notes in msec
  logic hundredthSecPulse;  // A short pulse, once every 1/100 second. 
  logic [1:0] melodySelect;  // sound to start: 0 flap, 1 game over, 2 cannon
  logic [1:0] playingSelect;  // sound now playing, latched at start so the address stays on it
  logic startMelody;
  logic shoot_pending;  // cannon shot waiting for the player to be free

  // interface signals to the list of songs
  logic [7:0] noteIndex;
  lpm_rom #(
      .LPM_WIDTH             (16),
      .LPM_WIDTHAD           (6),
      .LPM_NUMWORDS          (64),
      .LPM_FILE              ("RTL/AUDIO/sounds.mif"),
      .LPM_TYPE              ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL   ("REGISTERED"),
      .LPM_OUTDATA           ("UNREGISTERED"),
      .AUTO_CARRY_CHAINS     ("ON"),
      .AUTO_CASCADE_BUFFERS  ("ON"),
      .INTENDED_DEVICE_FAMILY("Cyclone V")
  ) rom_inst (
      .address(note_address),
      .inclock(CLOCK_31p5),
      // .outclock(clk),
      .q(songs_mem)
  );
  //----------------------------------------------------------------------------------------------------------
  // Instances of slow counter.  pulse every 10 mSec
  //----------------------------------------------------------------------------------------------------------									  									  								 
  Mili_sec_counter #(
      .SIMULATION_MODE(1'h0),
      .mSecPerTick(10),
      .PLLClock(315)
  ) mili_sec_counter_inst (
      .clk(CLOCK_31p5),
      .resetN(resetN),
      .turbo(1'h0),
      .hundredth_sec(hundredthSecPulse)
  );

  //----------------------------------------------------------------------------------------------------------								 					 	 
  //   syncronous code,  executed once every clock to update the current state and outputs 
  //----------------------------------------------------------------------------------------------------------	
  always_ff @(posedge CLOCK_31p5 or negedge resetN) // State machine logic 
		begin
    if (!resetN) begin  // Asynchronic reset, initialize the state machine 
      SM_Maestro <= s_idle;
      noteIndex <= 8'b0;
      noteTimeCounter <= 5'b0;  // constant reset; a ROM value here made Quartus emulate it with latches
      playingSelect <= 2'b0;
      EnableSoundOut <= 1'b0;
      melodyEnded <= 1'b0;
    end // asynch
		else begin 	// Synchronic logic of the state machine; once every clock 
      //--------------------------------------------------------------------------------------------------------------------
      // state machine 
      // default outputs 
      EnableSoundOut <= 1'b0;
      melodyEnded <= 1'b0;

      case (SM_Maestro)
        // ================================================				
        s_idle: begin
          noteIndex <= 8'b0;
          if (startMelody) begin  // start melody pressed
            playingSelect <= melodySelect;  // hold the selected sound for the whole melody
            noteTimeCounter <= 5'd1;  // one silent tick, so the ROM outputs the new sound before its first note
            SM_Maestro <= s_gap;
          end  // if
        end  // s_idle	
        // ================================================				
        s_playNote: begin
          EnableSoundOut <= 1'b1;  // enable sound 
          if ((noteDuration != 4'b0)) begin  // if song is still playing 
            if (hundredthSecPulse) begin
              noteTimeCounter <= noteTimeCounter - 5'b1;  // decremnt counter
            end
            if (noteTimeCounter == 5'b0) begin  // timer finished  
              noteIndex <= noteIndex + 1'b1;  // increment note Index 
              SM_Maestro <= s_gap;  // next state 
              noteTimeCounter <= gapDuration;  // preset counter for gap between notes 
            end  // if timer ended
          end // if not end of song	  
					else begin
            // reached end of song
            SM_Maestro <= s_ended;
          end
        end  // s_playNote
        // ================================================				
        s_gap: begin
          if (hundredthSecPulse) begin
            noteTimeCounter <= noteTimeCounter - 5'b1;  // decremnt counter  
          end
          if (noteTimeCounter == 5'b0) begin  // timer finished 
            SM_Maestro <= s_playNote ;   // back to playnote state    
            noteTimeCounter <= noteDuration ;     // preset counter 
          end  // if 
        end  // s_gap
        // ================================================				
        s_ended: begin
          melodyEnded <= 1'b1;
          SM_Maestro  <= s_idle;
        end  //s_end
        //	================================================				
        default: begin
          SM_Maestro <= s_idle;
        end  // default
      endcase
    end  // if reset else
  end  // always_ff state machine 

  logic flap_d;
  always_ff @(posedge CLOCK_31p5 or negedge resetN)
    if (!resetN) flap_d <= 1'b0;
    else flap_d <= flap;

  logic flap_pulse;
  assign flap_pulse   = flap && !flap_d;  // to play flap sound only once per press

  // shoot_signal is a one-clock pulse; keep it until the player is idle, so a playing flap sound can't swallow it
  always_ff @(posedge CLOCK_31p5 or negedge resetN)
    if (!resetN) shoot_pending <= 1'b0;
    else if (shoot_signal) shoot_pending <= 1'b1;
    else if (gameOver || SM_Maestro == s_idle) shoot_pending <= 1'b0;  // cannon sound starts now (dropped on game over)

  //assign song_index  = base_offset + noteIndex;
  //assign note_address[11:8] = melodySelect;
  //assign note_address[7:0] = noteIndex;
  assign note_address = {playingSelect[1:0], noteIndex[3:0]};
  //	assign tone        	= all_songs[song_index].note;
  //	assign octave      	= all_songs[song_index].octave;
  //	assign noteDuration  = all_songs[song_index].duration;	// in units of ? msec
  //	assign gapDuration  	= all_songs[song_index].gap;		   // in units of ? msec

  assign tone         = songs_mem[15:12];
  assign octave       = {{1'b0}, {songs_mem[11:10]}} + 3'd3;
  assign noteDuration = songs_mem[9:5];
  assign gapDuration  = songs_mem[4:0];
  always_comb begin
    melodySelect = 0;
    startMelody  = 0;
    if (flap_pulse && !gameOver) begin
      startMelody = 1'b1;
    end
    if (gameOver) begin
      melodySelect = 2'b1;
      startMelody  = 1'b1;
    end else if (shoot_pending) begin
      melodySelect = 2'b10;
      startMelody  = 1'b1;
    end
  end
endmodule


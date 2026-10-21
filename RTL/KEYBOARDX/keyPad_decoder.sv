// (c) Technion IIT, Department of Electrical Engineering 2019 
// Written By David Bar-On  Apr 2023 
// used to detect if one of the keys 0-9 was pressed,  if so sends the last keycode with Valid 

module keyPad_decoder (
    input    logic  clk,
    input    logic  resetN,
    input  logic [8:0] keyCode,
    input  logic  make,
    input  logic  brakee,  // warning break is a reserved word 

    output logic [1:0] NumberKey,
    output logic plus,
    enter,
    minus,


    output logic keyIsValid  // valid while key [0..A] is pressed

);

  localparam NUM_OF_KEYS = 4;

  logic [0:(NUM_OF_KEYS-1)][8:0] KEYS_ENCODEING =  // table holding the encoding of each key 
  //          8            +         ENTER    -                   

  {
    9'h075, 9'h079, 9'h15A, 9'h07B
  };


  logic [NUM_OF_KEYS:0] keyIsPressed;  // all keys 	


  always_ff @(posedge clk or negedge resetN) begin
    if (resetN == 1'b0) begin
      keyIsValid <= 0;
    end else begin
      // this is an example of how to use a for loop and generate 9 parallel circuits, one per digit 

      // for loop creating one machine per key 
      if (keyCode == KEYS_ENCODEING[0]) begin
        if (make == 1'b1) begin
          ;  // turn on when key is pressed 
          keyIsPressed[0] <= 1'b1;
          keyIsValid <= 1'b1;
        end
        ;
        if (brakee == 1'b1) begin  // turn off after key is released 
          keyIsPressed[0] <= 1'b0;
          keyIsValid <= 1'b0;
        end
      end  //number key if



      // code for the special keys 

      for (
          logic [2:0] i = 1; i < NUM_OF_KEYS; i++
      ) begin  // for loop creating one machine per key 
        if (keyCode == KEYS_ENCODEING[i]) begin
          if (make == 1'b1) begin
            ;  // turn on when key is pressed 
            keyIsPressed[i] <= 1'b1;
          end

          if (brakee == 1'b1) begin  // turn off after key is released 
            keyIsPressed[i] <= 1'b0;
          end
        end
      end  // special keys loop

    end  // else 


  end  //always ff


  // assign special wires 

  //       8           +       ENTER    -        

  assign plus = keyIsPressed[1];
  assign enter = keyIsPressed[2];
  assign minus = keyIsPressed[3];

  assign NumberKey = keyIsPressed;



endmodule



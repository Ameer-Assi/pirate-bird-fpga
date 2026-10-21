// (c) Technion IIT, Department of Electrical Engineering 2025 
module random_new (
    input logic clk,
    input logic resetN,
    input logic rise,
    input logic [9:0] min_val,
    input logic [9:0] max_val,
    output logic unsigned [9:0] dout
);

  // Generating a random number by latching a fast counter with the rising edge of an input ( e.g. key pressed )

  logic unsigned [9:0] counter  /* synthesis keep = 1 */;
  logic rise_d  /* synthesis keep = 1 */;


  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      dout <= (max_val + min_val) >> 1;  //  divide by 2
      counter <= min_val;
      rise_d <= 1'b0;
    end else begin
      counter <= counter + 10'(1);
      if (counter >= max_val)  // the +1 is done on the next clock 
        counter <= min_val;  // set min and max mvalues 
      rise_d <= rise;
      if (rise && !rise_d)  // rising edge 
        dout <= counter;
    end

  end

endmodule


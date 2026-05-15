module TopModule (input logic [2:0] in, output logic [1:0] out); 

  // Sum the number of 1s in the 3-bit input
  always_comb begin
    out = in[0] + in[1] + in[2];
  end

endmodule;
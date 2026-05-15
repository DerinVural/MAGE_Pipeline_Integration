module TopModule (a, b, out_and, out_or, out_xor, out_nand, out_nor, out_xnor, out_anotb);
  input a;
  input b;
  output logic out_and;
  output logic out_or;
  output logic out_xor;
  output logic out_nand;
  output logic out_nor;
  output logic out_xnor;
  output logic out_anotb;

  // Combinational assignments using logic and always blocks
  always @(*) begin
    out_and = a & b;
    out_or = a | b;
    out_xor = a ^ b;
    out_nand = ~(a & b);
    out_nor = ~(a | b);
    out_xnor = ~(a ^ b);
    out_anotb = ~a & b;
  end

endmodule
module TopModule (
  input wire in,
  output logic out
);

  always @(*) begin
    out = in;
  end

endmodule
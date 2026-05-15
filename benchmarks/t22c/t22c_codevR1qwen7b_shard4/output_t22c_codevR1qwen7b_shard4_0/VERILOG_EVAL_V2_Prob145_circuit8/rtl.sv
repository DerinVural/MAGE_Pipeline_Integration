module TopModule (clock, a, p, q);
  input clock;
  input a;
  output logic p;
  output logic q;

  reg [1:0] count;
  initial begin count = 2'b0; end

  always @(posedge clock) begin
    if (a) begin
      if (count != 2'b11) count <= count + 1;
    end else begin
      if (count != 2'b00) count <= count - 1;
    end
  end

  assign p = (count == 2'b11);
  assign q = (count == 2'b11);
endmodule
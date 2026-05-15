module TopModule (input a, input b, input sel, output logic out);
    assign out = sel ? b : a;
endmodule
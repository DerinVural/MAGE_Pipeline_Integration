module TopModule (a, b, c, out);
    input logic a, b, c;
    output logic out;

    assign out = a | b | c;
endmodule
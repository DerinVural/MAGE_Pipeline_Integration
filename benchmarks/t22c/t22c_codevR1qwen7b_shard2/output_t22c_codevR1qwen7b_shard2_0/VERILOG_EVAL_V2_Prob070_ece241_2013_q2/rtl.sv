module TopModule (
    input a,
    input b,
    input c,
    input d,
    output logic out_sop,
    output logic out_pos
);

    // SOP expression for output 1 at 2,7,15
    assign out_sop = (~a & ~b & c & ~d) | // Minterm 2
                     (~a & b & c & d)   | // Minterm 7
                     (a & b & c & d);    // Minterm 15

    // POS expression as the complement of SOP
    assign out_pos = ~(out_sop);

endmodule
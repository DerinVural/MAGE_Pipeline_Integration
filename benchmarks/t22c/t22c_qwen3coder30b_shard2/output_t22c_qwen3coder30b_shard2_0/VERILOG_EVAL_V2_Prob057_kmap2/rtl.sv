module TopModule (
    input a,
    input b,
    input c,
    input d,
    output out
);

    // Using Karnaugh map analysis to simplify the expression
    // Grouping 1s in the K-map to get simplified SOP form:
    // Terms are derived by observing adjacent 1s in the K-map
    
    // From K-map we get the simplified SOP:
    // out = (a' & b' & c' & d') | (a' & b' & c & d') | (a' & b & c' & d) | (a & b' & c' & d') | (a & b' & c & d') | (a & b & c' & d) | (a & b & c & d)
    // Further simplification gives:
    // out = (a' & b' & d') | (a & d') | (b & c & d)
    
    assign out = (~a & ~b & ~d) | (a & ~d) | (b & c & d);

endmodule
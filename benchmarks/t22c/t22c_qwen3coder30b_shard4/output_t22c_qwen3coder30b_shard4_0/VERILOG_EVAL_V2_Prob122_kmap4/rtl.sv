module TopModule (
    input logic a,
    input logic b,
    input logic c,
    input logic d,
    output logic out
);

    // Derive the logic equation from K-map
    // From the K-map:
    // cd\ab  00  01  11  10
    // 00     0   1   0   1
    // 01     1   0   1   0
    // 11     0   1   0   1
    // 10     1   0   1   0
    
    // Output is 1 when:
    // - cd=00 and ab=01 or ab=10 
    // - cd=01 and ab=00 or ab=11
    // - cd=11 and ab=01 or ab=10
    // - cd=10 and ab=00 or ab=11
    
    // Simplifying:
    // When cd==00, output is 1 if ab==01 or ab==10 => ab is not 00 and not 11
    // When cd==01, output is 1 if ab==00 or ab==11 => ab is not 01 and not 10
    // When cd==11, output is 1 if ab==01 or ab==10 => ab is not 00 and not 11
    // When cd==10, output is 1 if ab==00 or ab==11 => ab is not 01 and not 10
    
    // A more direct approach: 
    // out = (c ^ d) ^ (a ^ b)
    
    // Verify by checking truth table values:
    // Example cases:
    // cd=00, ab=00 -> out=0
    // cd=00, ab=01 -> out=1
    // cd=00, ab=10 -> out=1
    // cd=00, ab=11 -> out=0
    // cd=01, ab=00 -> out=1
    // cd=01, ab=01 -> out=0
    // cd=01, ab=10 -> out=0
    // cd=01, ab=11 -> out=1
    // And so on...
    
    assign out = (c ^ d) ^ (a ^ b);

endmodule
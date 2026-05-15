module TopModule ( input [3:0] x, output logic f );
  assign f = ( (~x[3] & ~x[2] & ~x[1] & ~x[0]) ) | // term1
             ( ~x[3] & ~x[2] & x[1] & ~x[0] ) | // term2
             ( x[3] & ~x[2] & ( ~x[1] | ~x[0] ) ) | // term3
             ( x[3] & x[2] & ( x[1] | x[0] ) ); // term4
endmodule;
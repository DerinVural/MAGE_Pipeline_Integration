module TopModule(
    input  logic [15:0] scancode,
    output logic left,
    output logic down,
    output logic right,
    output logic up
);

    // Implement the mapping using continuous assignments
    assign left  = (scancode == 16'h06b);
    assign down  = (scancode == 16'h072);
    assign right = (scancode == 16'h074);
    assign up    = (scancode == 16'h075);

endmodule
module TopModule (
    input  logic clk,
    input  logic load,
    input  logic [255:0] data,
    output logic [255:0] q
);

    // Constants
    localparam int GRID_SIZE = 256;
    localparam int ROWS = 16;
    localparam int COLS = 16;

    // Initialize the grid with zeros
    logic [GRID_SIZE-1:0] grid;
    initial begin
        grid = 0;
    end

    // Function to count live neighbors of a cell
    function logic [3:0] count_live_neighbors(input logic [3:0] row, input logic [3:0] col);
        logic [3:0] count = 0;
        for (int r = -1; r <= 1; r++)
            for (int c = -1; c <= 1; c++)
                if (r != 0 || c != 0)
                    count += grid[(row + r + ROWS) % ROWS * COLS + (col + c + COLS) % COLS];
        return count;
    endfunction

    // Sequential logic to update the grid on each clock cycle
    always @(posedge clk) begin
        if (load) begin
            grid = data;
        end else begin
            logic [GRID_SIZE-1:0] new_grid;
            for (int i = 0; i < ROWS; i++) begin
                for (int j = 0; j < COLS; j++) begin
                    logic live_neighbors = count_live_neighbors(i, j);
                    if (grid[i * COLS + j]) begin
                        if (live_neighbors == 2 || live_neighbors == 3)
                            new_grid[i * COLS + j] = 1;
                        else
                            new_grid[i * COLS + j] = 0;
                    end else begin
                        if (live_neighbors == 3)
                            new_grid[i * COLS + j] = 1;
                        else
                            new_grid[i * COLS + j] = 0;
                    end
                end
            end
            grid = new_grid;
        end
    end

    // Assign the updated grid to the output port
    assign q = grid;

endmodule
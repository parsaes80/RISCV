module s_memory (
	input  logic [31:0] address,
	input  logic        clock,
	input  logic [31:0] data,
	input  logic [3:0]  byte_en,
	input  logic        wren,
	output logic [31:0] q
);

	// 64KB data memory as 16K x 32-bit words.
	// Stored as a 2D array to mimic SRAM row/column layout.
	localparam int ROW_BITS = 7;
	localparam int COL_BITS = 7;
	localparam int ROWS     = (1 << ROW_BITS);
	localparam int COLS     = (1 << COL_BITS);
	logic [13:0] word_addr;

	logic [ROW_BITS-1:0] row_sel;
	logic [COL_BITS-1:0] col_sel;
	logic [31:0] mem_ff [0:ROWS-1][0:COLS-1];

	always_comb begin
		word_addr = address[15:2];
		row_sel = word_addr[13:7];
		col_sel = word_addr[6:0];
		q = mem_ff[row_sel][col_sel];
	end

	always_ff @(posedge clock) begin
		if (wren) begin
			if (byte_en[0]) mem_ff[row_sel][col_sel][7:0]   <= data[7:0];
			if (byte_en[1]) mem_ff[row_sel][col_sel][15:8]  <= data[15:8];
			if (byte_en[2]) mem_ff[row_sel][col_sel][23:16] <= data[23:16];
			if (byte_en[3]) mem_ff[row_sel][col_sel][31:24] <= data[31:24];
		end
	end

endmodule

// Explore VLSI Youtube Channel
module fifo_sync
    // Parameters section
    #( parameter FIFO_DEPTH = 8,
	   parameter DATA_WIDTH = 8)
    // Ports section   
	(input clk, 
     input rst,
    // input cs,     // chip select	 
     input wr, 
     input rd, 
     input [DATA_WIDTH-1:0] data_in, 
     output reg [DATA_WIDTH-1:0] data_out, 
	 output empty,
	 output full); 

    localparam FIFO_DEPTH_LOG = $clog2(FIFO_DEPTH);
	
    // Declare a by-dimensional array to store the data
	reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
	
	// Wr/Rd pointer have 1 extra bits at MSB
	reg [FIFO_DEPTH_LOG:0] write_pointer;
	reg [FIFO_DEPTH_LOG:0] read_pointer;

    always @(posedge clk or negedge rst) begin
      if(!rst)//rst =0 system reset happens
		    write_pointer <= 0;
		else if ( wr && !full)
	        write_pointer <= write_pointer + 1'b1;
	end
	
	always @(posedge clk or negedge rst) begin
	    if(!rst)
		    read_pointer <= 0;
		else if (rd && !empty)
	        read_pointer <= read_pointer + 1'b1;
	end
	
	// Declare the empty/full logic
    assign empty = (read_pointer == write_pointer);
	assign full  = (read_pointer == {~write_pointer[FIFO_DEPTH_LOG], write_pointer[FIFO_DEPTH_LOG-1:0]});

    always @(posedge clk) begin
	    if (wr && !full)
	        fifo[write_pointer[FIFO_DEPTH_LOG-1:0]] <= data_in;
	end
	
	always @(posedge clk or negedge rst) begin
	    if (!rst)
		    data_out <= 0;
		else if ( rd && !empty)
	        data_out <= fifo[read_pointer[FIFO_DEPTH_LOG-1:0]];
	end

endmodule

`timescale 1ns / 1ps
module Tx(input  M_CLOCK,	      // FPGA clock
		    input  [3:0] IO_PB,	         // IO Board Pushbutton Switch 
		    input  [7:0] IO_DSW,	// IO Board Dip Switchs
	    	 output [3:0] F_LED,	   // FPGA LEDs
	   	 output reg [7:0] IO_LED,	// IO Board LEDs
		    output [3:0] IO_SSEGD, // IO Board Seven Segment Digits			
		    output [7:0] IO_SSEG, // 7=dp, 6=g, 5=f,4=e, 3=d,2=c,1=b, 0=a
			 output reg RX,  //Recieve buffer pin
		    output IO_SSEG_COL);		// Seven segment column);
	
	reg [31:0] counter = 0;		// count the clock cycles
	reg [31:0] rxcounter = 0;
	reg [1:0] state;
	reg [7:0] DSWdata = 0;	//Hold DIP SWITCH values
	reg [4:0] shift = 0;		//Shifting the bit to correct LED
	reg overflow = 0;				//Timer overflow
	reg rxoverflow = 0;
	reg rxflag = 0;
	//====================================
	assign IO_SSEG_COL = 1;		   // deactivate colon displays
	assign IO_SSEGD = 4'b1111;	   // deactivate seven segment display
	assign IO_SSEG = 8'b11111111;	// deactivate seven segment display
	assign F_LED = 4'b0000;        // deactivate 4 LEDs

	//TX overflow
	always @(posedge M_CLOCK) begin
		if(counter != 5208) begin 
			counter <= counter + 1;
		end
		else begin
			overflow = ~overflow;
			counter <= 0;
			end
		end

	
	always @(posedge M_CLOCK) begin
		if(rxcounter != 651) begin 
			rxcounter <= rxcounter + 1;
		end
		else begin
			rxoverflow = ~rxoverflow;
			rxcounter <= 0;
			end
		end
	
	
	always @(posedge overflow) begin
		if(IO_PB[0] == 0) begin
			DSWdata <= ~IO_DSW;
			state <= 0;
		end
		else begin
			case(state)
				0: begin
					rxflag <= 1;
					RX <= 0;		// Start bit
					state <= 1;
					end
				1: begin		//Serial input
					if(rxflag == 1) begin
						rxflag <= 0;
						shift <= 0;
						end
						RX <= DSWdata[shift];
						shift <= shift + 1;
						if(shift == 8) begin
							state <= 2;
						end
						else begin
						state <= 1;
						end
					end
				2: begin
					RX <= 1;		// Stop bit	
					
				
				end
				default: begin RX <= 0;
					end
			endcase
		end
	end

	always @(posedge rxoverflow) begin
		IO_LED[shift - 1] <= RX;
		end

endmodule

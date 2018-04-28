`timescale 1ns / 1ps
module Main(input M_CLOCK,	      // FPGA clock
		    input  [3:0] IO_PB,	         // IO Board Pushbutton Switch 
		    input  [7:0] IO_DSW,	// IO Board Dip Switchs
	    	 output reg [3:0] F_LED,	   // FPGA LEDs
	   	 output reg [7:0] IO_LED,	// IO Board LEDs
		    output reg [3:0] IO_SSEGD = 4'b1111, // IO Board Seven Segment Digits			
		    output reg [7:0] IO_SSEG, // 7=dp, 6=g, 5=f,4=e, 3=d,2=c,1=b, 0=a
			 output reg RX,  //Recieve buffer pin
			 output reg TX_OUT,  //TX buffer pin
			 input Clksig,	//Clock signal
			 output reg [7:0] decryptedValue,
			 output reg [3:0] StartDisplay,
			// output reg Sync,	//Sync clock signal
		    output IO_SSEG_COL);		// Seven segment column);
	
	reg [31:0] counter = 0;		// count the clock cycles
	reg [31:0] rxcounter = 0;
	reg [31:0] OFcounter = 0;	//Overflow counter for debouncer
	reg [1:0] state;
	reg [7:0] DSWdata = 0;	//Hold DIP SWITCH values
		reg [7:0] DSWdataTemp = 0;	//Hold DIP SWITCH values

	reg [4:0] shift = 0;		//Shifting the bit to correct LED
	reg [4:0] count = 0;
	reg overflow = 0;				//Timer overflow
	reg rxoverflow = 0;
	reg rxflag = 0;
	reg [7:0] Value = 255;		//LFSR seed value
	reg feedback, recieveFlag2, recieveFlag, recieveFlag3;
	reg decrpytFlag;
	reg [31:0] clkCounterOverflow;
	reg [7:0] outputData;
	//====================================
	assign IO_SSEG_COL = 1;		   // deactivate colon displays
	//assign IO_SSEGD = 4'b0000;	   // deactivate seven segment display
	//assign IO_SSEG = 8'b11111111;	// deactivate seven segment display
	//assign F_LED = 4'b0000;        // deactivate 4 LEDs
	

 always @(posedge M_CLOCK) 
		begin
		  if(clkCounterOverflow != 250000) clkCounterOverflow <= clkCounterOverflow + 1; 
			else 
				begin
					clkCounterOverflow <= 0;
					
					if(StartDisplay <= 4)
					StartDisplay = StartDisplay + 1;
					else StartDisplay = 1;
					
				 end
		 end
		 
		 
		 always @* 
	begin
		 case(StartDisplay)
		 3'b001:
			begin
					begin
						IO_SSEGD = 4'b1110;
						IO_SSEG = 8'b10001000;//R
					end
			end
		3'b010:
			begin
			IO_SSEGD = 4'b1101;
						IO_SSEG = 8'b11000110; //C
			end
		3'b011:
			begin
			IO_SSEGD = 4'b1011;
				IO_SSEG = 8'b11000001;//V
			end
		3'b100:
			begin
					IO_SSEGD = 4'b0111;
					IO_SSEG = 8'b10001000;//R
			end
		default: 
			begin
				IO_SSEGD = 4'b1111;
				IO_SSEG = 8'b11111111;
			end
		endcase
	end
		 

always @(posedge overflow) begin
feedback = 1;
//Decrypt data
  Value[0] <= feedback;
  Value[1] <= Value[0];
  Value[2] <= Value[1];
  Value[3] <= Value[2] ^ feedback;
  Value[4] <= Value[3] ^ feedback;	
  Value[5] <= Value[4];
  Value[6] <= Value[5];
  Value[7] <= Value[6];
//Take the DSWData that was sent ^
decryptedValue = Value;
end

//Decrypt the data
always @(posedge overflow) begin

if(~IO_PB[1]) begin
	outputData <= decryptedValue ^ DSWdata;	//Decrypted message shows if PushButton 1 is pressed
	IO_LED <= outputData;
	end
	else if(~IO_PB[2]) begin	//Displays Raw data sent (encrypted message)
			IO_LED <= DSWdata;
			end
	else
	IO_LED <= 8'b11111111;
	

end
	


//Debouncer
always@(posedge M_CLOCK) begin
		if(OFcounter != 5208000) begin 
			OFcounter <= OFcounter + 1;
		end
		else begin
			overflow = ~overflow;
			OFcounter <= 0;
			end
	end
	
	
always @(posedge M_CLOCK) begin
		RX <= Clksig;
		F_LED <= 4'b1001;
		end
	
	//5208
	always@(posedge M_CLOCK) begin
		if(rxcounter != 5208) begin 
			rxcounter <= rxcounter + 1;
		end
		else begin
			rxoverflow = ~rxoverflow;
			rxcounter <= 0;
			end
	end



	always@(posedge rxoverflow) begin
	
		if(RX == 0 && count == 0)
			count = count + 1;
		else if(count > 0 && count < 9) begin
			DSWdata[count - 1] <= RX;
			count = count + 1;
			end
			else
			count = 0;
	end
		

		
		reg StartTransmit = 0;       //Start TX transmission of DSWs
    reg [7:0] SendData = 0;      //Holds the data to be sent from the DSWs
    reg [4:0] TX_state_counter = 0;      //State counter for transmitting the DSWs Bits
    reg [31:0] TX_ClockCounter;      // TX Clock Cycles
    reg [1:0] TX_State;
	 reg [7:0] IO_DSWreg;
   
	reg StartReceive = 0;   //Start RX Receive of DSWs
	reg RX_StartBitRecieve = 0;
	reg [31:0] RX_ClockCounter = 0;

		
		//Transmit decrypted data back to check
		always @(posedge M_CLOCK) 
   begin
			  if(TX_ClockCounter != 5208) TX_ClockCounter <= TX_ClockCounter + 1;
			  else 
					 begin
						TX_ClockCounter <= 0; //Sets the Clock Counter to 0 and Starts Transmission
						StartTransmit <= ~StartTransmit;
						
					 end
    end
	 
	 
		
		always @(posedge StartTransmit)
    begin
      //Make sure when the DSW are changed the program will re-transmit the new DSW values
     if(~IO_PB[3] && overflow)
       begin
			IO_DSWreg = outputData;
         TX_State <= 0; //State starts at 0
         SendData = IO_DSWreg; //Sends the decoded data back to Sender
       end
     else
       begin
         case(TX_State)
           0: //State 0: Send Start Bit
             begin
             TX_OUT <= 0;      //Transmit Start bit to TX_OUT (0N0 PIN 148)
             TX_state_counter <= 0;
             TX_State <= 1;      //Set TX_State to 1
             end
           1: //State 1: Send initial Bit in Data and shift the next bit into 
             //Position SendData[0] until all data has been sent
             begin
                //Stores next bit to be sent in the SendData[0] by 
               //shifting the bits in SendData after every bit transmission
               TX_OUT <= SendData[TX_state_counter];
					TX_state_counter <= TX_state_counter + 1;
					
               if(TX_state_counter ==  8)
						TX_State <= 2;
               
             end
           2: //State 2: Send stop bit set the TX_state_counter to 0
             begin
               TX_OUT <= 1;      // Stop bit
             end

           default: //Set LED[0] to 1 if not active
             TX_OUT <= 1;
         endcase
       end
    end
		
endmodule

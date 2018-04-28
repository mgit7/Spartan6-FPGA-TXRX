`timescale 1ns / 1ps
//Lab 4 TX Transmitter
//Branden Vara 817207775

//
module TxRX(input  M_CLOCK,            // FPGA clock
      input  [7:0] IO_DSW,        //IO Board Dip Switchs
		input [3:0] IO_PB,
		input RX_IN,
      output reg [3:0] F_LED,
      output reg [7:0] IO_LED,      // FPGA LEDs
      output reg TX_OUT,    // IO Board LEDs
      output reg [3:0] IO_SSEGD,       // IO Board Seven Segment Digits        
      output reg [7:0] IO_SSEG,      // 7=dp, 6=g, 5=f,4=e, 3=d,2=c,1=b, 0=a
      output IO_SSEG_COL,
		output reg clk_signal_sync,
		output reg [3:0] StartDisplay);     // Seven segment column);
    
    //---------------------------------------------------------------------
    assign IO_SSEG_COL = 1;       // deactivate the colon displays
    //assign IO_SSEGD = 4'b1111;    // deactivate the seven segment display 
    //assign IO_SSEG = 8'b11111111;    // deactivate the seven segment display
    //assign F_LED = 4'b000;      // deactivate 4 LEDs

    //---------------------------------------------------------------------
    reg StartTransmit = 0;       //Start TX transmission of DSWs
    reg [7:0] SendData = 0;      //Holds the data to be sent from the DSWs
    reg [4:0] TX_state_counter = 0;      //State counter for transmitting the DSWs Bits
    reg [31:0] TX_ClockCounter;      // TX Clock Cycles
    reg [1:0] TX_State;
	 reg [7:0] IO_DSWreg;
	 reg [7:0] IO_DSWreg1;
	 reg [7:0] DSWdataDisplay;
	 reg [7:0] DSWdata;
   
	reg StartReceive = 0;   //Start RX Receive of DSWs
	reg RX_StartBitRecieve = 0;
	reg [31:0] RX_ClockCounter = 0;
	reg timerExpired = 0;
	reg timerExpiredSend = 0;
	reg timerExpired1 = 0;
	reg timerExpiredSend1 = 0;
	reg [5:0] count = 0;

   reg [31:0] Display_ClockCounter,Minutes_ClockCounter,secdotCounter,debounceCounter; 
	reg startMinutes = 0;
	reg secdotStart = 0;
	reg debounceStart = 0;
   
	reg StartDigits = 0;
	reg [7:0] firstDigit,secondDigit,thirdDigit,fourthDigit;
	reg [3:0] setfirstDigit = 33;
	reg [3:0] setsecondDigit = 33;
	
	reg [3:0] DisplayfirstDigit = 33;
	reg [3:0] DisplaysecondDigit = 33;
	
	reg flagDisplayDate = 0;
	
	reg [3:0] setthirdDigit;
	reg [3:0] setfourthDigit;
	
	reg [3:0] DisplaythirdDigit = 355;
	reg [3:0] DisplayfourthDigit = 355;

	reg timerExpiredStartTransmission = 0;
	reg timerCountDown = 0;
	reg timerCountDownFlag = 0;
	reg timerExpiredStartTransmissionFlag = 0;
	
	//Encryption LFSR initialization
	reg [7:0] Value = 255;		//LFSR seed value
	reg feedback;
	reg [7:0] encryptData;
	reg [7:0] ValueE;

  //---------------------------------------------------------------------
  //Clock at 50MHz/9600 = 5208.33-- Clock for the Transmitter
  //posedge clk_signal_sync
   always @(posedge M_CLOCK) 
   begin
				//Transmit Rate 5208
			  if(TX_ClockCounter != 5208) TX_ClockCounter <= TX_ClockCounter + 1;
			  else 
					 begin
						TX_ClockCounter <= 0; //Sets the Clock Counter to 0 and Starts Transmission
						StartTransmit <= ~StartTransmit;
						
					 end
    end
    
   //Clock Edge for the Receiver 
//-----------------------------------//
always @(posedge M_CLOCK) 
begin
		 if(RX_ClockCounter != 651) begin 
			RX_ClockCounter <= RX_ClockCounter + 1;
		 end
		 else begin
			RX_StartBitRecieve <= ~RX_StartBitRecieve;
			RX_ClockCounter <= 0;
			end
end
   
    always @(posedge StartTransmit)
    begin
      //Make sure when the DSW are changed the program will re-transmit the new DSW values
     if(~IO_PB[3] || timerExpiredStartTransmission == 1)
       begin
		 //LFSR Encryption of Data:
			feedback = Value[7];
		 
		   ValueE[0] <= feedback;
		   ValueE[1] <= ValueE[0];
		   ValueE[2] <= ValueE[1];
		   ValueE[3] <= ValueE[2] ^ feedback;
		   ValueE[4] <= ValueE[3] ^ feedback;
		   ValueE[5] <= ValueE[4];
		   ValueE[6] <= ValueE[5];
		   ValueE[7] <= ValueE[6];
			
			encryptData = ValueE;
			
			IO_DSWreg1 = ~IO_DSW; //divide data that we are sending by 2
			IO_DSWreg = IO_DSWreg1 ^ encryptData;
         TX_State <= 0; //State starts at 0
         SendData = IO_DSWreg; //Gets the Data from the DSWs and then stores them in SendData
			//timerExpiredStartTransmissionFlag = 0;
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
					
               if(TX_state_counter == 8) TX_State <= 2;
               
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


//Receiver Clock and Output
always @(posedge RX_StartBitRecieve) 
    begin
		//When the start bit is received and put into LED[-1] which doesnt exist
		//Next it will output the 8 data bits to LED[7:0]
		//Once the data bits are sent it will send the stop bit to LED[8] which doesnt exist
		
      IO_LED[TX_state_counter - 1] <= TX_OUT;
    end
 

always @(posedge StartTransmit) 
begin
	if(RX_IN == 0 && count == 0)
		count = count + 1;
	else if(count > 0 && count < 9) begin
		DSWdata[count - 1] <= RX_IN;
		count = count + 1;
		end
		else
		count = 0;
end

//Clock Timer Implimentation

  //---------------------------------------------------------------------
  //Clock at 50MHz/50Hz = 1,000,000 set each of the four digits on for 5ms 
    always @(posedge M_CLOCK) 
		begin//250,000
		  if(Display_ClockCounter != 250000) Display_ClockCounter <= Display_ClockCounter + 1; 
			else 
				begin
					Display_ClockCounter <= 0; //Sets the Clock Counter to 0 and Starts Transmission
					
					if(StartDisplay <= 4)
					StartDisplay = StartDisplay + 1;
					else StartDisplay = 1;
					
				 end
		 end
	
//Every Minute Clock ticks 	
	always @(posedge M_CLOCK) 
		begin //3x10^9
		  if(Minutes_ClockCounter != 50000000) Minutes_ClockCounter <= Minutes_ClockCounter + 1; 
			else 
				begin
					Minutes_ClockCounter <= 0; //Sets the Clock Counter to 0 and Starts Transmission
					startMinutes = ~startMinutes;
				 end
		 end

//Clock signal every second for the seconds decimal
	always @(posedge M_CLOCK) 
		begin //50,000,000
		  if(secdotCounter != 50000000) secdotCounter <= secdotCounter + 1; 
			else 
				begin
					secdotCounter <= 0; //Sets the Clock Counter to 0 and Starts Transmission
					secdotStart = ~secdotStart;
				 end
		 end
   
	//Setting every Digit on the Display every 5ms
	//-----------------------------------//
	always @(*) 
	begin
		 case(StartDisplay)
		 3'b001:
			begin
				if(secdotStart)
					begin
						IO_SSEGD = 4'b0111;
						IO_SSEG = {1'b0,firstDigit[6:0]};
					end
				else
					begin
						IO_SSEGD = 4'b0111;
						IO_SSEG = {1'b1,firstDigit[6:0]};
					end
			end
		3'b010:
			begin
				IO_SSEGD = 4'b1011;
				IO_SSEG = secondDigit;
			end
		3'b011:
			begin
					IO_SSEGD = 4'b1101;
					IO_SSEG = thirdDigit;
			end
		3'b100:
			begin
					IO_SSEGD = 4'b1110;
					IO_SSEG = fourthDigit;
			end
		default: 
			begin
				IO_SSEGD = 4'b1111;
				IO_SSEG = 8'b11111111;
			end
		endcase
	end

//Next 4 always blocks Are used to diplay the correct messages on the Seven Segment Display(SSD)
	always @(posedge M_CLOCK) 
		begin
					case(DisplayfirstDigit)
						4'b0000:  firstDigit <= 8'b11000000;//0
						4'b0001:  firstDigit <= 8'b11111001;//1
						4'b0010:  firstDigit <= 8'b10100100;//2
						4'b0011:  firstDigit <= 8'b10110000;//3
						4'b0100:  firstDigit <= 8'b10011001;//4
						4'b0101:  firstDigit <= 8'b10010010;//5
						4'b0110:  firstDigit <= 8'b10000010;//6
						4'b0111:  firstDigit <= 8'b11111000;//7
						4'b1000:  firstDigit <= 8'b10000000;//8
						4'b1001:  firstDigit <= 8'b10011000;//9
						4'b1011:  firstDigit <= 8'b10100001;//D
						4'b1100:	 firstDigit <= 8'b10010010;//S firstDigit = 12
						4'b1111:	 firstDigit <= 8'b11000111;//L firstDigit = 15
						default: firstDigit <= 8'b111111111;//off
					endcase
			end
			
		always @(posedge M_CLOCK) 
			begin
						case(DisplaysecondDigit)
							4'b0000:  secondDigit <= 8'b11000000;//0
							4'b0001:  secondDigit <= 8'b11111001;//1
							4'b0010:  secondDigit <= 8'b10100100;//2
							4'b0011:  secondDigit <= 8'b10110000;//3
							4'b0100:  secondDigit <= 8'b10011001;//4
							4'b0101:  secondDigit <= 8'b10010010;//5
							4'b0110:  secondDigit <= 8'b10000010;//6
						   4'b0111:  secondDigit <= 8'b11111000;//7
						   4'b1000:  secondDigit <= 8'b10000000;//8
						   4'b1001:  secondDigit <= 8'b10011000;//9
							4'b1011:  secondDigit <= 8'b10010010;//S
							4'b1100:	 secondDigit <= 8'b10010010;//S secondDigit = 12
							4'b1111:	 secondDigit <= 8'b11001111;//I secondDigit = 15
							default: secondDigit <= 8'b111111111;//off
						endcase
					
			end
				
		always @(posedge M_CLOCK) 
			begin
						case(DisplaythirdDigit)
							4'b1100:	 thirdDigit <= 8'b10001000;//A thirdDigit = 12
							4'b1111:	 thirdDigit <= 8'b10001000;//A thirdDigit = 15
							default: thirdDigit <= 8'b11111111;//off
						endcase	
			end
				
		always @(posedge M_CLOCK) 
			begin
						case(DisplayfourthDigit)
							4'b1100:	 fourthDigit <= 8'b10001100;//P fourthDigit = 12
							4'b1111:  fourthDigit <= 8'b10001110;//F fourthDigit = 15
							default: fourthDigit <= 8'b11111111;//off
						endcase
			end

//Debouncing PushButton
	always @(posedge M_CLOCK) 
   begin
     if(debounceCounter != (5208000)) debounceCounter <= debounceCounter + 1; 
      else 
			begin
				debounceStart <= ~debounceStart;
				debounceCounter <= 0; //Sets the Clock Counter to 0 and Starts Transmission
			 end
    F_LED[3] = timerCountDown;
	 F_LED[0] = timerExpiredStartTransmission;
	 F_LED[1] = 0;
	 F_LED[2] = 0;
	 end

//Clock algorithm to allow the clock to run in correct fashion
always @(posedge startMinutes)
	begin
			if(setfirstDigit != DisplayfirstDigit && setsecondDigit != DisplaysecondDigit && (DisplayfirstDigit >= 0 && DisplayfirstDigit < 10) && (DisplaysecondDigit >= 0 && DisplaysecondDigit < 10))begin
					setfirstDigit = DisplayfirstDigit;
					setsecondDigit = DisplaysecondDigit;
					
					timerCountDown = 1;
			end
			else
			begin
			setfirstDigit = DisplayfirstDigit;
			setsecondDigit = DisplaysecondDigit;
			end
						
				if(timerCountDown == 1)
					begin
					if(setsecondDigit == 0 && setfirstDigit == 0)
						begin	
							if(timerExpiredStartTransmission == 1)
							begin
							setfirstDigit = 11;
							setsecondDigit = 11;
							timerCountDown = 0;
							end
							
							timerExpiredStartTransmission = 1;
						end
					else if(setfirstDigit == 0)
						begin
							setsecondDigit = setsecondDigit - 1;
							setfirstDigit = 9;
						end
					else setfirstDigit = setfirstDigit - 1;
				end
				else timerExpiredStartTransmission = 0;		

	end

//Remove for clock to work
	always@(posedge debounceStart)
		begin

			if(IO_PB[0] == 0)
				begin
					DisplaysecondDigit = ~IO_DSW[7:4];
					DisplayfirstDigit = ~IO_DSW[3:0];
					DisplaythirdDigit = 2;
					DisplayfourthDigit = 2;
				end
			else if(~IO_PB[2])
				begin
					DSWdataDisplay = DSWdata;
					if(DSWdataDisplay == IO_DSWreg1)
					begin
						DisplayfirstDigit = 12;
						DisplaysecondDigit = 12;
						DisplaythirdDigit = 12;
						DisplayfourthDigit = 12;
					end
					else
					begin
						DisplayfirstDigit = 15;
						DisplaysecondDigit = 15;
						DisplaythirdDigit = 15;
						DisplayfourthDigit = 15;
					end
				end
			else if(startMinutes)
				begin
						DisplayfirstDigit = setfirstDigit;
						DisplaysecondDigit = setsecondDigit;
				end
			
		end

endmodule 
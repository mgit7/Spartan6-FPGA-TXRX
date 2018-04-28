

Final Project Report


## Introduction

For this project we  have implemented two boards that will be sending and receiving encrypted and decrypted messages. The sender will send the data and the receiver will receive the data on two different pins. On the sender side, the data is taken in using the dip switches and
then upon pressing a push button the data is encrypted and sent to the other receiver board, which then decrypts and displays the information sent. We also have implemented an acknowledgment of receiving the correct data where the decrypted data is then sent back to the sender and checked against the original message  It then compares the values and displays ‘Pass’ or ‘Fail’;  if the data matches or doesn’t match, respectively.


## Design
 

![](https://github.com/mgit7/Spartan6E-FPGA/blob/master/Design.jpg)


## Modules


Transmission Module: This module contains the rate at which the data will be sent at by the sender, and the rate at which the receiver will be receiving and reading from the pin. This module is setup as a finite state machine to send each individual bit sequentially and is sending and receiving asynchronously. The sender sends the data at a baud rate of 9600 bits/sec to a pin
on the receiver end. The receiving board then transfers the data coming into one pin and pushes it to another pin to remove any noise and interference and enables the value of the the bit to be read correctly. The receiver reads at twice the rate the sender is sending at. This allows the receiver to sample in the middle of each bit interval into an 8 bit register. This 8 bit register is then used to decrypt the encrypted message and get back the original message. 



Encrypted Module: This module contains an LFSR algorithm that will generate an output value that is implemented in both the sender and receiver module. The way it work from the sender’s perspective  is that the sender will first generate a random value using the LFSR algorithm; this
is the encryption key. The encryption key is the   XOR’d with the  message, thus creating the encrypted message that the sender will be sending to the receiver.


From the receiver’s perspective, the receiver will then read the encrypted message and generate the decryption key on the receiver’s board. This decryption key is then used against the encrypted message, the message sent by the sender,  to get back the original message. Now, the board is able to display the encrypted message and the original message received by the sender. The receiver is now able to send back the original message to the sender’s board by clicking push button 3. This will allow the sender to authenticate if the encrypted message that the receiver decrypted was the correct original message. If the encrypted message was decrypted correctly, then the sender’s board will display a ‘Pass’, otherwise the board will display a ‘Fail’.


Timer Module: This module is used to set a timer, on the sender’s board, that will automatically count down and send the encrypted message at specific time in seconds that is  set by the user, using the dip switches. The user is able to use this feature by setting the number of seconds,
using the dip switches, they want the countdown to start at and clicking on push button 0 which will change the display to the timer and starts counting down. Once the countdown hits 0, the message “Sd”, which stands for ‘Send’, will appear on the display and sender automatically encrypts the message to be sent and sends that message to the receiver's board. The receiver will now have the encrypted message.



## User Instructions

#### Sending Data:
 
###### Sender

1.   To send data without delay set the desired data on the eight dip switches
2.   Push button S1 to send the data.
3.   Once the button is pressed the data will be encrypted and sent.
4.   The encrypted data will be displayed on the LEDs


###### Sending Data using Timer:

1.   To send data after a specified amount of time set the amount of time to wait using the dip switches (Max delay is 99 seconds).
2.   Switches 1-4 will set the tens digit of the timer.
3.   Switches 5-8 will set the ones digit of the timer.
4.   To start the timer press push button S4. 
5.   Once the timer has been started set the dip switches to represent the data you would like to send.
6.   When the timer expires it will encrypt and send the data represented on the dip switches.
7.   After the timer expires the seven segment display will show “Sd” to alert the user that the data has been sent.

 


#### Receiving Data:
 
###### Reciever

1.   Press push button S3 to show the decrypted message sent from board 1 on the LEDs.
2.   Press push button S2 to show the encrypted message sent form board 1 on the LEDs.
3.   Press push button S1 to send the decrypted data back to Board 1 for verification.

 


## Verification of Data:
 
##### Sender

1. To verify that the data from board two press push button S2 if the data that was sent back matches the data last sent the seven segment LED display will show “PASS” to alert the user the data is correct. If the data received from board two does not match the most recent data sent, the seven segment LED display will show “FAIL” to alert the user it has not received the current message.



##### Test and Validation Results


We have used the oscilloscope to clock the data rates and verify the data being sent and received by each board.


### Other tests ran include:

1. Verifying data encryption and decryption by displaying data on both ends of transmitter and receiver to LEDs
2. Testing the receiving ends data versus the original sent data.
3. Testing different connection strategies between both boards to get the most stable results. We have found that instead of directly connecting the two boards that we first connect the wires to a breadboard and then relay the wires from there to each individual board.
4. We found out from hours of testing that each board has to be grounded to each other to support transmission.


### Verification Checks Ran:

1. Data encryption and decryption match on both boards. 
2. Timer count down sends data after it expires
3. Data that is sent from one board to the other can be verified on both ends and sent back to check against initial data.
4. Seven Segment Display shows correct messages in every state of the program.


##Side Notes

1. Wires connecting each board together must be connected to a breadboard
2. The wires must be held tight to ensure that the connections between both boards are clean.
3. LFSR implementation using help from the LFSR test bench.

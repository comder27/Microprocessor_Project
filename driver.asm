#assumptions----
'''
* clock frequency 3MHz
* 
'''

----KEYBOARD---------------------------
XRA A
MVI C,02H                       #to check for input LSB/MSB
                                #A7-A0 bound to 0-7
                                #B7,B6 bound to 8,9
LXI H,3001H                     #LSB on 3000, MSB on 3001
MVI A,9BH                       #changed from 92 to 9B
OUT CWR

--> #NOR gate connected to port C7
--> #output HIGH when input received
--> #CWR=> 1 0 0 1 1 0 1 1 = 9B
[RE]: IN PORT C 
RAL
JZ <RE>

[L5]: IN PORT B
CALL <DELAY1>
CPI 7FH #check if 8 is pressed
JZ <L1>
	L[1]: MVI B,08H
		MOV M,B
		DCX H
		DCR C
		MOV A,C
		ORI FF
		JNZ <RE>
		RET
CPI BFH #check if 9 pressed
JZ <L2>
	[L2]: MVI B,09H
		MOV M,B
		DCX H
		DCR C
		MOV A,C
		ORI FF
		JNZ <RE>
		RET

# [L3]:
IN PORT A 
CALL <DELAY1>               #debouncing 20ms
# JZ <L3>

	[DELAY1]: LXI D,09C4H
			[L4]: DCX D
				MOV A,E 
				ORA D
				JNZ <L4>
			RET
CMA
ORA A 
MVI D,08H
[L6]: DCR D 
RAL 
JNC <L6>
MOV M,D 
DCX H 
MOV A,C 
ORI FF 
JNZ <RE>
#3000 has LSB, 3001 MSB
XRA A
------START BUTTON--------------------
EI 
[loop]: RIM
RAL
JZ <loop>
--------------------------------------
INX H 
MOV C,M 
CALL <MULT>
	[MULT]: XRA A
			MVI B,0AH
			[L7]: ADD C 
			DCR B 
			JNZ <L7>
DCX H 
ADD M 
LXI H,3003H
MOV M,A #3003 stores the weight of each packet in HEX

#[weight*5 for weight-measure counter]
XRA A
MOV E,M
MVI B,05H
[L9]: ADD E
JC <L8>
	[L8]: MVI D,01H
			RET
DCR B
JNZ <L9>

MOV C,E
MOV B,D

#BC contains total count for weight-measure

----- 1 hour counter --------------------------------------

[C1] : MVI A,B0h
OUT 43H
MVI A0h
OUT 42H                  #8254-1
MVI 8Ch                  #8CA0 count for 1hr clock
OUT 42H

#ISR FOR 6.5



----------------------------------------------------------

--------- BAG FILLING ------------------------------------
LXI D,0000H
MVI A,90H
OUT 53H #CWR 8255-2
MVI A,40H
OUT 51H #PORT B
#conveyor starts
[B2]: IN 50H  #PORT A checks for IR
		RAL
		JC <B2>
INX D
MVI A,80H
OUT 51H #nozzle starts conveyor stops
---timer initialized-------------------------
[B1] : MVI A,30H
OUT 43H
MOV A,C
OUT 40H #8254-1
MOV A,B
OUT 40H
HLT

'''
dedicated 8255
IR A7
hopper B7
conveyor B6
'''


---------------------------------------------------------
---------------------------------------------------------
#codes for ISR

	[ISR 6.5]: XRA A
				MVI A,80H
				OUT 63H #8255-1 CWR
				MOV A,D
				OUT 60H

				MOV A,E
				ANI F0H
				OUT 61H

				MOV A,E
				ANI 0FH
				OUT 62H

				#SEVEN SEGMENT DISPLAY CONNECETED VIA
				#BCD TO 7S-DECODER
				JMP <C1>


	[ISR 5.5]:  MVI A,90H
				OUT 53H #CWR

				MVI A,40H
				OUT 51H #PORT B
				#conveyor starts, nozzle stops

				[B3]: IN 50H  #PORT A
				    	RAL
					JNC <B3>
					JMP <B2>
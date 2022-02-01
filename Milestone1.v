`include "define_state.h"

/*

Christopher Poyser - 400081657
Ryan Shortt - 400068823

Monday, November 26, 2018

*/
module Milestone1 (
		
		//clock and reset
		input logic Clock,
		input logic Resetn,

		//start and stop
		input logic Start,
		output logic Stop,
		
		//SRAM
		output logic   [17:0]   SRAM_address,
		output logic   [15:0]   SRAM_write_data,
		output logic            SRAM_we_n,
		input  logic   [15:0]   SRAM_read_data

);
M1_state_type M1_state;


/////////////////////////////////////////////////////////////////////////////////
////////////////////////////// new variables ////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

//u upsample
logic [31:0] U_even_up;
logic [31:0] U_odd_up;

//v upsample
logic [31:0] V_even_up;
logic [31:0] V_odd_up;

//y upsample
logic [7:0] Y_even;
logic [7:0] Y_odd;

//used for rgb calculations before clipping
logic [31:0] RED;
logic [31:0] GREEN;
logic [31:0] BLUE;

logic [8:0]tempblue;

//clipping to 8 bits

//even
logic [7:0] red_even;
logic [7:0] green_even;
logic [7:0] blue_even;

//odd
logic [7:0] red_odd;
logic [7:0] green_odd;
logic [7:0] blue_odd;

//shift registers used for holding u and v values for upsampling
logic [47:0] U_shift_register;
logic [47:0] V_shift_register;

//used as a buffer for the next u and v index since each address contains 2 values and we only want to shift in one at a time
logic [7:0] U_nextplacement;
logic [7:0] V_nextplacement;

//flags

logic flag1, flag2; //flags for reading or not reading next values of u[?] & v[?]. reading = 1, not reading =0

//counters

logic [9:0] colcounter, rowcounter;

//multipliers

logic[31:0] Mult1_op1, Mult1_op2, Mult2_op1, Mult2_op2, Mult3_op1, Mult3_op2;
logic [63:0] Mult1_result_long, Mult2_result_long, Mult3_result_long;
logic [31:0] Mult1_result, Mult2_result, Mult3_result;

assign Mult1_result_long=Mult1_op1*Mult1_op2;
assign Mult1_result=Mult1_result_long[31:0];

assign Mult2_result_long=Mult2_op1*Mult2_op2;
assign Mult2_result=Mult2_result_long[31:0];

assign Mult3_result_long=Mult3_op1*Mult3_op2;
assign Mult3_result=Mult3_result_long[31:0];


logic[17:0] Y_base_address;
logic[17:0] U_base_address;
logic[17:0] V_base_address;
logic[17:0] RGB_base_address;

//stop bit

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////



always @(posedge Clock or negedge Resetn) begin
	if (~Resetn) begin
		M1_state <= S_M1IDLE;
		
		SRAM_address<=18'd38400; //u base address
		SRAM_write_data<=1'd0;
		SRAM_we_n<=1'd1;
		
		U_shift_register<=48'd0;
		V_shift_register<=48'd0;
		
		U_nextplacement<=8'd0;
		V_nextplacement<=8'd0;
		
		//reset address
		Y_base_address<=18'd0;
		U_base_address<=18'd38400;
		V_base_address<=18'd57600;
		RGB_base_address<=18'd146944;

		
		tempblue<=1'd0;
		
		
		flag1<=1'd0;
		flag2<=1'd0;
		
		colcounter<=10'd0;
		rowcounter<=10'd0;

		//u upsample
		U_even_up<=32'd0;
		U_odd_up<=32'd0;

		//v upsample
		V_even_up<=32'd0;
		V_odd_up<=32'd0;

		//y upsample
		Y_even<=8'd0;
		Y_odd<=8'd0;

		//used for rgb calculations before clipping
		RED<=32'd0;
		GREEN<=32'd0;
		BLUE<=32'd0;
		
		Stop<=1'd0;
	
	end else begin
		case (M1_state)
		S_M1IDLE: begin
		
				if(Start==1'd1)begin //begin
					SRAM_address<=U_base_address;
					U_base_address<=U_base_address+18'd1;
					M1_state <= S_LEADIN_0;
				end else begin
					M1_state <= S_M1IDLE;
				end
				
			end
			
			S_LEADIN_0: begin //18'd38400

				SRAM_address<=U_base_address;
				U_base_address<=U_base_address+18'd1;
				M1_state<=S_LEADIN_1;

			end
			S_LEADIN_1: begin //18'd38401
				SRAM_address <= V_base_address;
				V_base_address<=V_base_address+18'd1;
				M1_state <= S_LEADIN_2;
			end
			
			S_LEADIN_2: begin //U[0] and U[1] pushed into shift register. //18'd57600
				U_shift_register[47:40]<=SRAM_read_data[15:8];
				U_shift_register[39:32]<=SRAM_read_data[15:8];
				U_shift_register[31:24]<=SRAM_read_data[15:8];
				U_shift_register[23:16]<=SRAM_read_data[15:8];
				U_shift_register[15:8]<=SRAM_read_data[15:8];
				U_shift_register[7:0]<=SRAM_read_data[7:0];
				
				SRAM_address <= V_base_address;
				V_base_address<=V_base_address+18'd1;
				M1_state <= S_LEADIN_3;
			end
			
			S_LEADIN_3:begin
				U_shift_register<= {U_shift_register[31:0],SRAM_read_data}; //U[2] & U[3] pushed in //18'd57601
				SRAM_address <= Y_base_address;
				Y_base_address<=Y_base_address+18'd1;
				M1_state <= S_LEADIN_4;
			end
			
			S_LEADIN_4:begin //V[0] and V[1] pushed into shift register. //18'd0
				V_shift_register[47:40]<=SRAM_read_data[15:8];
				V_shift_register[39:32]<=SRAM_read_data[15:8];
				V_shift_register[31:24]<=SRAM_read_data[15:8];
				V_shift_register[23:16]<=SRAM_read_data[15:8];
				V_shift_register[15:8]<=SRAM_read_data[15:8];
				V_shift_register[7:0]<=SRAM_read_data[7:0];
				
				
				M1_state <= S_LEADIN_5;
			end
			
			S_LEADIN_5:begin
				V_shift_register<= {V_shift_register[31:0],SRAM_read_data}; //V[2] & V[3] pushed in
				M1_state <= S_LEADIN_6;
			end
			
			S_LEADIN_6:begin
				Y_even<=SRAM_read_data[15:8];
				Y_odd<=SRAM_read_data[7:0];
				M1_state <= S_LEADIN_7;
			end
			
	
			S_LEADIN_7:begin //upsampling for u   //COULD POSSIBLY BE CC0
				U_odd_up<=Mult1_result-Mult2_result+Mult3_result+32'd128;
				U_even_up<={24'd0,U_shift_register[31:24]};
				M1_state <= S_LEADIN_8;
				
				M1_state<=S_LEADIN_8;
				
			end
			
			S_LEADIN_8:begin //upsampling for v //18'd38402
				U_odd_up<={8'd0,U_odd_up[31:8]}; //divide by 256
				V_odd_up<=Mult1_result-Mult2_result+Mult3_result+32'd128;
				V_even_up<={24'd0,V_shift_register[31:24]};
	
				SRAM_address<=U_base_address;
				U_base_address<=U_base_address+18'd1;
				

				M1_state<=S_LEADIN_9;
			end
			
			S_LEADIN_9:begin //rgb calculation for even //18'd57602
				V_odd_up<={8'd0,V_odd_up[31:8]};
				
				RED <= Mult1_result+Mult2_result;
				GREEN <= Mult1_result-Mult3_result;
				BLUE <= Mult1_result;
				
				SRAM_address<=V_base_address;
				V_base_address<=V_base_address+18'd1;
				
				
				M1_state<=S_LEADIN_10;
			end
			
			S_LEADIN_10:begin
				GREEN <= GREEN - Mult2_result;
				BLUE<=BLUE +Mult3_result;
				
					
				
				SRAM_address<=Y_base_address;
				Y_base_address<=Y_base_address+18'd1;
				M1_state <=S_LEADIN_11;
			end
			
			S_LEADIN_11:begin //rgb calculation for odd CC4
			
				tempblue<=blue_even;
				SRAM_write_data<={red_even,green_even};

				SRAM_address<=RGB_base_address;
				RGB_base_address<=RGB_base_address+18'd1;
				
								
				//for shifting in next U[j+7/2]
				U_shift_register<={U_shift_register[39:0], SRAM_read_data[15:8]};
				U_nextplacement<=SRAM_read_data[7:0];
				
				RED <= Mult1_result+Mult2_result;
				GREEN <= Mult1_result - Mult3_result;
				BLUE <= Mult1_result;
				
				SRAM_we_n<=1'd0;	
				M1_state<=S_LEADIN_12;
			end
			
			S_LEADIN_12:begin //COULD POSSIBLY BE CC5
				SRAM_write_data<={tempblue,red_odd};
				
				SRAM_address<=RGB_base_address;
				RGB_base_address<=RGB_base_address+18'd1;

				GREEN <= GREEN - Mult2_result;
				BLUE <= BLUE + Mult3_result;
				
				//for shifting in next V[j+7/2]
				V_shift_register<={V_shift_register[39:0], SRAM_read_data[15:8]};//
				V_nextplacement<=SRAM_read_data[7:0];
				

				
				colcounter<=colcounter+10'd1;
				M1_state <= S_CC_0;
			end
			
			S_CC_0: begin //common case 0
				//write last rgb values
				SRAM_write_data<={green_odd,blue_odd};
				SRAM_address<=RGB_base_address;
				RGB_base_address<=RGB_base_address+18'd1;
				
				//upsample u
				
				U_odd_up<=Mult1_result-Mult2_result+Mult3_result+32'd128;
				U_even_up<={24'd0,U_shift_register[31:24]};
				

				
				//necessary for next Y in next clock cycle
				Y_even<=SRAM_read_data[15:8];
				Y_odd<=SRAM_read_data[7:0];
				
				//write enable and next state
	
				M1_state<=S_CC_1; //cc1
			end
			S_CC_1: begin //CREATE flag1 FOR DECIDING IF THIS COMMON CASE CYCLE WE ARE READING IN VALUES OR NOT
			
			
				U_odd_up<={8'd0,U_odd_up[31:8]}; //divide by 256
				V_odd_up<=Mult1_result-Mult2_result+Mult3_result+32'd128;
				V_even_up<={24'd0,V_shift_register[31:24]};
			
				//if reading next address
				if (flag1==1'd1) begin
				if(colcounter<10'd156) begin
				SRAM_address<=U_base_address;
				U_base_address<=U_base_address+18'd1;
				end
				end
				
				SRAM_we_n<=1'b1;
				M1_state<=S_CC_2;//cc2
			end
			S_CC_2: begin
			

				V_odd_up<={8'd0,V_odd_up[31:8]};
				
				RED <= Mult1_result+Mult2_result;
				GREEN <= Mult1_result-Mult3_result;
				BLUE <= Mult1_result;
				
				if (flag1==1'd1) begin
				if (colcounter<10'd156) begin
				SRAM_address<=V_base_address;
				V_base_address<=V_base_address+18'd1;
				end
				end

				M1_state<=S_CC_3;//cc3
			end
			
			S_CC_3: begin

				GREEN <= GREEN - Mult2_result;
				BLUE<=BLUE +Mult3_result;
				
				
				
				SRAM_address<=Y_base_address;
				Y_base_address<=Y_base_address+18'd1;
				


				M1_state<=S_CC_4;//cc4
			
			end
			S_CC_4: begin
				tempblue<=blue_even;
				SRAM_write_data<={red_even,green_even};
				
				SRAM_we_n<=1'd0;
				SRAM_address<=RGB_base_address;
				RGB_base_address<=RGB_base_address+18'd1;
				

				
				RED <= Mult1_result+Mult2_result;
				GREEN <= Mult1_result - Mult3_result;
				BLUE <= Mult1_result;
				

				if (flag1==1'd1)begin
				//for shifting in next U[j+7/2]
				if(colcounter<10'd156) begin
				U_shift_register<={U_shift_register[39:0], SRAM_read_data[15:8]};
				U_nextplacement<=SRAM_read_data[7:0];
				end
				end else begin
					U_shift_register<={U_shift_register[39:0], U_nextplacement};
				end


				
				M1_state<=S_CC_5;//cc5

			end
			S_CC_5: begin
			
				SRAM_write_data<={tempblue,red_odd};
				SRAM_address<=RGB_base_address;
				RGB_base_address<=RGB_base_address+18'd1;


				GREEN <= GREEN - Mult2_result;
				BLUE <= BLUE + Mult3_result;
				
				
				if (flag1==1'd1)begin
				//for shifting in next V[j+7/2]
					if (colcounter<10'd156) begin
					V_shift_register<={V_shift_register[39:0], SRAM_read_data[15:8]};//
					V_nextplacement<=SRAM_read_data[7:0];
					flag1<=1'd0;		
					end
				end else begin
					V_shift_register<={V_shift_register[39:0], V_nextplacement};//
					flag1<=1'd1;
				end

				
				
				colcounter<=colcounter+10'd1;
				if (colcounter<10'd155) begin 
					M1_state<= S_CC_0;
				end else begin
					M1_state <= S_LEADOUT_0;//cc0
				end

			end
			S_LEADOUT_0: begin
				//write last rgb values
				SRAM_address<=RGB_base_address; //rgb address block
				RGB_base_address<=RGB_base_address+18'd1;

				SRAM_write_data<={green_odd,blue_odd};
				
								
				//necessary for next Y in next clock cycle
				Y_even<=SRAM_read_data[15:8];
				Y_odd<=SRAM_read_data[7:0];
				
				//upsample u
				
				U_odd_up<=Mult1_result-Mult2_result+Mult3_result+32'd128;
				U_even_up<={24'd0,U_shift_register[31:24]};
				
				
				//write enable and next state
				
				M1_state<=S_LEADOUT_1;
			
			end
			S_LEADOUT_1: begin

				U_odd_up<={8'd0,U_odd_up[31:8]}; //divide by 256
				
				V_odd_up<=Mult1_result-Mult2_result+Mult3_result+32'd128;
				V_even_up<={24'd0,V_shift_register[31:24]};
			
				SRAM_we_n<=1'b1;
				M1_state<=S_LEADOUT_2;//

			end
			S_LEADOUT_2: begin

				V_odd_up<={8'd0,V_odd_up[31:8]};
				
				RED <= Mult1_result+Mult2_result;
				GREEN <= Mult1_result-Mult3_result;
				BLUE <= Mult1_result;


				M1_state<=S_LEADOUT_3;
			end
			S_LEADOUT_3: begin
				GREEN <= GREEN - Mult2_result;
				BLUE<=BLUE +Mult3_result;

				if(colcounter<10'd159) begin
				SRAM_address<=Y_base_address;
				Y_base_address<=Y_base_address+18'd1;
				end
	

				M1_state<=S_LEADOUT_4;//
			end
			S_LEADOUT_4: begin
				tempblue<=blue_even;
				SRAM_write_data<={red_even,green_even};
				SRAM_address<=RGB_base_address;
				RGB_base_address<=RGB_base_address+18'd1;
				

				RED <= Mult1_result+Mult2_result;
				GREEN <= Mult1_result - Mult3_result;
				BLUE <= Mult1_result;
				
				SRAM_we_n<=1'd0;	
				
				U_shift_register<={U_shift_register[39:0],U_shift_register[7:0]};
				
				M1_state<=S_LEADOUT_5;//
				
			end
			S_LEADOUT_5: begin
				SRAM_write_data<={tempblue,red_odd};
				SRAM_address<=RGB_base_address;
				RGB_base_address<=RGB_base_address+18'd1;

				GREEN <= GREEN - Mult2_result;
				BLUE <= BLUE + Mult3_result;

				V_shift_register<={V_shift_register[39:0], V_shift_register[7:0]};//
				
				colcounter<=colcounter+10'd1;
				
				
				if(colcounter==10'd159) begin
					M1_state<=S_LEADOUT_6;
				
				end else begin
					M1_state<=S_LEADOUT_0;
			
				end
			end
			S_LEADOUT_6: begin
				SRAM_write_data<={green_odd,blue_odd};
				SRAM_address<=RGB_base_address;
				RGB_base_address<=RGB_base_address+18'd1;
				
				M1_state<=S_LEADOUT_7;
			end
			S_LEADOUT_7: begin
			SRAM_we_n<=1'd1;
			flag1<=1'd0;
			if(rowcounter==18'd239) begin
				Stop<=1'd1;
				M1_state<=S_FINISH;
			end else begin
				U_shift_register<=48'd0;
				V_shift_register<=48'd0;
				RED<=32'd0;
				BLUE<=32'd0;
				GREEN<=32'd0;
				Y_even<=8'd0;
				Y_odd<=8'd0;
				U_even_up<=32'd0;
				U_odd_up<=32'd0;
				V_even_up<=32'd0;
				V_odd_up<=32'd0;
				rowcounter<=rowcounter+10'd1;
				colcounter<=10'd0;
				SRAM_address<=U_base_address;
				U_base_address<=U_base_address+18'd1;
				M1_state<=S_LEADIN_0;
			end
			
			end
			S_FINISH: begin
				
		SRAM_address<=18'd38400; //u base address
		SRAM_write_data<=1'd0;
		SRAM_we_n<=1'd1;
		
		U_shift_register<=48'd0;
		V_shift_register<=48'd0;
		
		U_nextplacement<=8'd0;
		V_nextplacement<=8'd0;
		
		//reset address
		Y_base_address<=18'd0;
		U_base_address<=18'd38400;
		V_base_address<=18'd57600;
		RGB_base_address<=18'd146944;

		
		tempblue<=1'd0;
		
		
		flag1<=1'd0;
		flag2<=1'd0;
		
		colcounter<=10'd0;
		rowcounter<=10'd0;

		//u upsample
		U_even_up<=32'd0;
		U_odd_up<=32'd0;

		//v upsample
		V_even_up<=32'd0;
		V_odd_up<=32'd0;

		//y upsample
		Y_even<=8'd0;
		Y_odd<=8'd0;

		//used for rgb calculations before clipping
		RED<=32'd0;
		GREEN<=32'd0;
		BLUE<=32'd0;
		
		Stop<=1'd0;
				M1_state<=S_M1IDLE;
			end
		default: M1_state<=S_M1IDLE;
		endcase
	end
end

	//comb block

always_comb begin

	Mult1_op1=32'd0;
	Mult1_op2=32'd0;
	
	Mult2_op1=32'd0;
	Mult2_op2=32'd0;
	
	Mult3_op1=32'd0;
	Mult3_op2=32'd0;
	
	red_even=8'd0;
	red_odd=8'd0;
	
	green_even=8'd0;
	green_odd=8'd0;
	
	blue_even=8'd0;
	blue_odd=8'd0;
	
	case(M1_state)
	
	//lead in
	
	S_LEADIN_7: begin //0
	Mult1_op1= U_shift_register[47:40]+U_shift_register[7:0];
	Mult1_op2= 32'd21;
	
	Mult2_op1=U_shift_register[39:32]+U_shift_register[15:8];
	Mult2_op2=32'd52;
	
	Mult3_op1=U_shift_register[31:24]+U_shift_register[23:16];
	Mult3_op2=32'd159;
	end
	S_LEADIN_8: begin //1
	Mult1_op1= V_shift_register[47:40]+V_shift_register[7:0];
	Mult1_op2= 32'd21;
	
	Mult2_op1=V_shift_register[39:32]+V_shift_register[15:8];
	Mult2_op2=32'd52;
	
	Mult3_op1=V_shift_register[31:24]+V_shift_register[23:16];
	Mult3_op2=32'd159;
	end
	S_LEADIN_9: begin //2
	Mult1_op1=32'd76284;
	Mult1_op2=Y_even-8'd16;
	
	Mult2_op1=32'd104595;
	Mult2_op2= V_even_up-32'd128;
	
	Mult3_op1=32'd25624; 
	Mult3_op2= U_even_up-32'd128;
	end
	S_LEADIN_10: begin //3 green-mult2result, blue+mult3result
	

	Mult2_op1=32'd53281;
	Mult2_op2= V_even_up-32'd128;
	
	Mult3_op1=32'd132251; 
	Mult3_op2= U_even_up-32'd128;
	end
	S_LEADIN_11: begin //4
	
	if(RED[31])begin
		red_even = 8'd0;
	end else begin
		if(|RED[30:24])begin
			red_even = 8'b11111111;
		end else begin
			red_even = RED[23:16];
		end
	end
	if(GREEN[31])begin
		green_even = 8'd0;
	end else begin
		if(|GREEN[30:24])begin
			green_even = 8'b11111111;
		end else begin
			green_even = GREEN[23:16];
		end
	end
	if(BLUE[31])begin
		blue_even = 8'd0;
	end else begin
		if(|BLUE[30:24])begin
			blue_even = 8'b11111111;
		end else begin
			blue_even = BLUE[23:16];
		end
	end
	
	Mult1_op1=32'd76284;
	Mult1_op2=Y_odd-8'd16;
	
	Mult2_op1=32'd104595;
	Mult2_op2= $signed(V_odd_up)-32'd128;
	
	Mult3_op1=32'd25624; 
	Mult3_op2= $signed(U_odd_up)-32'd128;
	end
	S_LEADIN_12: begin //5
	if(RED[31])begin
		red_odd = 8'd0;
	end else begin
		if(|RED[30:24])begin
			red_odd = 8'b11111111;
		end else begin
			red_odd = RED[23:16];
		end
	end
	Mult2_op1=32'd53281;
	Mult2_op2= $signed(V_odd_up)-32'd128;
	
	Mult3_op1=32'd132251; 
	Mult3_op2= $signed(U_odd_up)-32'd128;
	end
	
	//common case 
	S_CC_0: begin //0
	if(GREEN[31])begin
		green_odd = 8'd0;
	end else begin
		if(|GREEN[30:24])begin
			green_odd = 8'b11111111;
		end else begin
			green_odd = GREEN[23:16];
		end
	end
	if(BLUE[31])begin
		blue_odd = 8'd0;
	end else begin
		if(|BLUE[30:24])begin
			blue_odd = 8'b11111111;
		end else begin
			blue_odd = BLUE[23:16];
		end
	end
	
	
	Mult1_op1= U_shift_register[47:40]+U_shift_register[7:0];
	Mult1_op2= 32'd21;
	
	Mult2_op1=U_shift_register[39:32]+U_shift_register[15:8];
	Mult2_op2=32'd52;
	
	Mult3_op1=U_shift_register[31:24]+U_shift_register[23:16];
	Mult3_op2=32'd159;
	end
	S_CC_1: begin //1
	Mult1_op1= V_shift_register[47:40]+V_shift_register[7:0];
	Mult1_op2= 32'd21;
	
	Mult2_op1=V_shift_register[39:32]+V_shift_register[15:8];
	Mult2_op2=32'd52;
	
	Mult3_op1=V_shift_register[31:24]+V_shift_register[23:16];
	Mult3_op2=32'd159;
	end
	S_CC_2: begin //2 ASK TA
	Mult1_op1=32'd76284;
	Mult1_op2= Y_even-8'd16;
	
	Mult2_op1=32'd104595;
	Mult2_op2= V_even_up-32'd128;
	
	Mult3_op1=32'd25624; 
	Mult3_op2= U_even_up-32'd128;
	end
	S_CC_3: begin //3

	Mult2_op1=32'd53281;
	Mult2_op2= V_even_up-32'd128;
	
	Mult3_op1=32'd132251; 
	Mult3_op2= U_even_up-32'd128;
	end
	S_CC_4: begin //4
	
	
	if(RED[31])begin
		red_even = 8'd0;
	end else begin
		if(|RED[30:24])begin
			red_even = 8'b11111111;
		end else begin
			red_even = RED[23:16];
		end
	end
	if(GREEN[31])begin
		green_even = 8'd0;
	end else begin
		if(|GREEN[30:24])begin
			green_even = 8'b11111111;
		end else begin
			green_even = GREEN[23:16];
		end
	end
	if(BLUE[31])begin
		blue_even = 8'd0;
	end else begin
		if(|BLUE[30:24])begin
			blue_even = 8'b11111111;
		end else begin
			blue_even = BLUE[23:16];
		end
	end
	
	
	Mult1_op1=32'd76284;
	Mult1_op2=Y_odd-8'd16;
	
	Mult2_op1=32'd104595;
	Mult2_op2= $signed(V_odd_up)-32'd128;
	
	Mult3_op1=32'd25624; 
	Mult3_op2= $signed(U_odd_up)-32'd128;
	end
	S_CC_5: begin //5
	if(RED[31])begin
		red_odd = 8'd0;
	end else begin
		if(|RED[30:24])begin
			red_odd = 8'b11111111;
		end else begin
			red_odd = RED[23:16];
		end
	end
	Mult2_op1=32'd53281;
	Mult2_op2= $signed(V_odd_up)-32'd128;
	
	Mult3_op1=32'd132251; 
	Mult3_op2= $signed(U_odd_up)-32'd128;
	end
	
	//lead out
	
	S_LEADOUT_0: begin //0
	if(GREEN[31])begin
		green_odd = 8'd0;
	end else begin
		if(|GREEN[30:24])begin
			green_odd = 8'b11111111;
		end else begin
			green_odd = GREEN[23:16];
		end
	end
	if(BLUE[31])begin
		blue_odd = 8'd0;
	end else begin
		if(|BLUE[30:24])begin
			blue_odd = 8'b11111111;
		end else begin
			blue_odd = BLUE[23:16];
		end
	end
	
	
	Mult1_op1= U_shift_register[47:40]+U_shift_register[7:0];
	Mult1_op2= 32'd21;
	
	Mult2_op1=U_shift_register[39:32]+U_shift_register[15:8];
	Mult2_op2=32'd52;
	
	Mult3_op1=U_shift_register[31:24]+U_shift_register[23:16];
	Mult3_op2=32'd159;
	end
	S_LEADOUT_1: begin //1
	Mult1_op1= V_shift_register[47:40]+V_shift_register[7:0];
	Mult1_op2= 32'd21;
	
	Mult2_op1=V_shift_register[39:32]+V_shift_register[15:8];
	Mult2_op2=32'd52;
	
	Mult3_op1=V_shift_register[31:24]+V_shift_register[23:16];
	Mult3_op2=32'd159;
	end
	S_LEADOUT_2: begin //2 ASK TA
	Mult1_op1=32'd76284;
	Mult1_op2= Y_even-8'd16;
	
	Mult2_op1=32'd104595;
	Mult2_op2= V_even_up-32'd128;
	
	Mult3_op1=32'd25624; 
	Mult3_op2= U_even_up-32'd128;
	end
	
	
	S_LEADOUT_3: begin //3

	Mult2_op1=32'd53281;
	Mult2_op2= V_even_up-32'd128;
	
	Mult3_op1=32'd132251; 
	Mult3_op2= U_even_up-32'd128;
	end
	
	
	S_LEADOUT_4: begin //4
	
	
	if(RED[31])begin
		red_even = 8'd0;
	end else begin
		if(|RED[30:24])begin
			red_even = 8'b11111111;
		end else begin
			red_even = RED[23:16];
		end
	end
	
	
	if(GREEN[31])begin
		green_even = 8'd0;
	end else begin
		if(|GREEN[30:24])begin
			green_even = 8'b11111111;
		end else begin
			green_even = GREEN[23:16];
		end
	end
	
	
	if(BLUE[31])begin
		blue_even = 8'd0;
	end else begin
		if(|BLUE[30:24])begin
			blue_even = 8'b11111111;
		end else begin
			blue_even = BLUE[23:16];
		end
	end
	
	
	Mult1_op1=32'd76284;
	Mult1_op2=Y_odd-8'd16;
	
	Mult2_op1=32'd104595;
	Mult2_op2= $signed(V_odd_up)-32'd128;
	
	Mult3_op1=32'd25624; 
	Mult3_op2= $signed(U_odd_up)-32'd128;
	end
	
	
	S_LEADOUT_5: begin //5
	if(RED[31])begin
		red_odd = 8'd0;
	end else begin
		if(|RED[30:24])begin
			red_odd = 8'b11111111;
		end else begin
			red_odd = RED[23:16];
		end
	end
	Mult2_op1=32'd53281;
	Mult2_op2= $signed(V_odd_up)-32'd128;
	
	Mult3_op1=32'd132251; 
	Mult3_op2= $signed(U_odd_up)-32'd128;
	end
	S_LEADOUT_6: begin
		if(GREEN[31])begin
		green_odd = 8'd0;
	end else begin
		if(|GREEN[30:24])begin
			green_odd = 8'b11111111;
		end else begin
			green_odd = GREEN[23:16];
		end
	end
	if(BLUE[31])begin
		blue_odd = 8'd0;
	end else begin
		if(|BLUE[30:24])begin
			blue_odd = 8'b11111111;
		end else begin
			blue_odd = BLUE[23:16];
		end
	end
	end

	endcase
end

endmodule
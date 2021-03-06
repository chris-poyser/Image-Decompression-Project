`include "define_state.h"

/*

Christopher Poyser - 400081657
Ryan Shortt - 400068823

Monday, November 26, 2018

*/

module Milestone2 (
				//clock and reset
		input logic Clock,
		input logic Resetn,

		//start and stop
		input logic Go,
		output logic Done,
		
		//SRAM
		output logic   [17:0]   SRAM_address,
		output logic   [15:0]   SRAM_write_data,
		output logic            SRAM_we_n,
		input  logic   [15:0]   SRAM_read_data
		
);
M2_state_type M2_state;

/////////////////////////////////////////////////////////////////////////////////
////////////////////////////// new variables ////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

logic[17:0] offset0, offset1;

logic[7:0] value1WRITES,value2WRITES;

//address lines
logic [6:0] addressARAM0,addressBRAM0;
logic [6:0] addressARAM1,addressBRAM1;
logic [6:0] addressARAM2,addressBRAM2;

//write enables
logic wrenARAM0, wrenBRAM0;
logic wrenARAM1, wrenBRAM1;
logic wrenARAM2, wrenBRAM2;

//data lines
logic [31:0] dataARAM0, dataBRAM0;
logic [31:0] dataARAM1, dataBRAM1;
logic [31:0] dataARAM2, dataBRAM2;

//outputs
logic [31:0] outputARAM0, outputBRAM0;
logic [31:0] outputARAM1, outputBRAM1;
logic [31:0] outputARAM2, outputBRAM2;

logic [6:0] CreadAddressA,CreadAddressB, sPRIMEwriteaddress,sPRIMErow, memARAM2,memBRAM2;

//sample counters and generating address efficiently
// ending with 1 is used for writing to SRAM, ending with 0 is for readin
logic [17:0] rowblock0,colblock0,rowblock1,colblock1;
logic [2:0] rowindex, colindex;
logic [17:0] rowaddress, coladdress;

//for comb block

logic [17:0] rowblock, colblock, offset;
logic SRAMFLAG;

logic[1:0] counter0; //counter for if we are doing y, u or v

//t calulations variables

//accumulators
//for t calculation
logic [31:0] Taccum1, Taccum2, Taccum3, Taccum4;
//for s calculation
logic [31:0] Saccum1, Saccum2, Saccum3, Saccum4;

//divide by 256
logic [31:0] Tone, Ttwo, Tthree, Tfour;
logic [31:0] Sone, Stwo, Sthree, Sfour;

//write addresses
//for writing to T in t calculation and reading from T in S calculation
logic [6:0] TwriteA, TwriteB, TreadA;

logic [6:0] SwriteB;

//write counter in blocks of 4
logic[3:0] writecountT, writecountS;


//buffers for holding Tthree and Tfour
logic[31:0] Tbuffer3, Tbuffer4;

logic[31:0] Sbuffer2,Sbuffer3, Sbuffer4;

logic[17:0] numcolblock0,numcolblock1;

logic[31:0] Mult1_op1, Mult1_op2, Mult2_op1, Mult2_op2, Mult3_op1, Mult3_op2,Mult4_op1,Mult4_op2;
logic [63:0] Mult1_result_long, Mult2_result_long, Mult3_result_long,Mult4_result_long;
logic [31:0] Mult1_result, Mult2_result, Mult3_result,Mult4_result;

assign Mult1_result_long=Mult1_op1*Mult1_op2;
assign Mult1_result=Mult1_result_long[31:0];

assign Mult2_result_long=Mult2_op1*Mult2_op2;
assign Mult2_result=Mult2_result_long[31:0];

assign Mult3_result_long=Mult3_op1*Mult3_op2;
assign Mult3_result=Mult3_result_long[31:0];

assign Mult4_result_long=Mult4_op1*Mult4_op2;
assign Mult4_result=Mult4_result_long[31:0];

//flags
logic flagT, flagS;

//testing


// Instantiate RAM0 (FOR C AND C TRANSPOSE)
dual_port_RAM0 dual_port_RAM_inst0 (
	.address_a ( addressARAM0 ),
	.address_b ( addressBRAM0),
	.clock ( Clock ),
	.data_a (dataARAM0),
	.data_b (dataBRAM0),
	.wren_a ( wrenARAM0 ),
	.wren_b ( wrenBRAM0 ),
	.q_a ( outputARAM0 ),
	.q_b ( outputBRAM0 )
);

// Instantiate RAM1 (FOR S' and S)
dual_port_RAM1 dual_port_RAM_inst1 (
	.address_a ( addressARAM1 ),
	.address_b ( addressBRAM1),
	.clock ( Clock ),
	.data_a ( dataARAM1),
	.data_b ( dataBRAM1),
	.wren_a ( wrenARAM1 ),
	.wren_b ( wrenBRAM1 ),
	.q_a ( outputARAM1 ),
	.q_b ( outputBRAM1 )
);

// Instantiate RAM2 (FOR T=S'C)
dual_port_RAM2 dual_port_RAM_inst2 (
	.address_a ( addressARAM2 ),
	.address_b ( addressBRAM2),
	.clock ( Clock ),
	.data_a ( dataARAM2),
	.data_b ( dataBRAM2),
	.wren_a ( wrenARAM2 ),
	.wren_b ( wrenBRAM2 ),
	.q_a ( outputARAM2 ),
	.q_b ( outputBRAM2 )
);

	

	

// FSM to control the read and write sequence

always @(posedge Clock or negedge Resetn) begin
	if (~Resetn) begin
	
	offset0<=18'd76800;
	offset1<=18'd0;
	
	//RAM0 line 1
	wrenARAM0<=1'b0; //0 is read, 1 is write
	dataARAM0<=32'd0;

	addressARAM0<=7'd0;
	
	//RAM0 line 2
	wrenBRAM0<=1'b0; //0 is read, 1 is write
	dataBRAM0<=32'd0;

	addressBRAM0<=7'd0;
	
	//RAM1 line 1
	wrenARAM1<=1'b0; //0 is read, 1 is write
	dataARAM1<=32'd0;

	addressARAM1<=7'd0;
	
	//RAM1 line 2
	wrenBRAM1<=1'b0; //0 is read, 1 is write
	dataBRAM1<=32'd0;
	addressBRAM1<=7'd0;
	
	//RAM2 line 1
	wrenARAM2<=1'b0; //0 is read, 1 is write
	dataARAM2<=32'd0;

	addressARAM2<=7'd0;
	
	//RAM2 line 2
	wrenBRAM2<=1'b0; //0 is read, 1 is write
	dataBRAM2<=32'd0;

	addressBRAM2<=7'd0;
	
	Done<=1'd0; //When done all of Milestone 2 set to 1
		
	counter0<=2'd0; //Counter for whether doing either Y, U or V
	
	CreadAddressA<=7'd0;
	CreadAddressB<=7'd1; //starting at a different address for reading C from DRAM0
	
	
	sPRIMEwriteaddress<=7'd0; //writing S' in the DRAM1 address from the SRAM
	 
	sPRIMErow<=7'd0; //for reading S' from DRAM1 not from SRAM
	

	rowblock0<=18'd0;
	colblock0<=18'd0;
	rowblock1<=18'd0;
	colblock1<=18'd0;
	
	rowindex<=3'd0;
	colindex<=3'd0; 
	
	Taccum1<=32'd0;
	Taccum2<=32'd0;
	Taccum3<=32'd0;
	Taccum4<=32'd0;
	
	Tbuffer3<=32'd0;
	Tbuffer4<=32'd0;
	
	TwriteA<=7'd0;
	TwriteB<=7'd1; //Start writing at a different address
	
	SwriteB<=7'd64;
	
	writecountT<=4'd0;
	writecountS<=4'd0;
	
	Saccum1<=32'd0;
	Saccum2<=32'd0;
	Saccum3<=32'd0;
	Saccum4<=32'd0;
	
	Sbuffer2<=32'd0;
	Sbuffer3<=32'd0;
	Sbuffer4<=32'd0;


	SRAM_write_data<=16'd0;
	SRAM_we_n<=1'd1; //reading
	
	flagT<=1'd0;
	flagS<=1'd0;
	
	TreadA<=7'd0;
	
	SRAMFLAG<=1'd0;
	
	value1WRITES<=7'd0;
	value2WRITES<=7'd0;
	
	numcolblock0<=18'd39;
	numcolblock1<=18'd39;
	end else begin
		case(M2_state)
		
		S_M2IDLE: begin
		
			if (Go==1'b1) begin
				
				colindex<=3'd0;
				M2_state<=S_LI_FETCH_0;
			end else begin
				M2_state<=S_M2IDLE;
			end
			
		end
		
		S_LI_FETCH_0: begin //18'd76800 , colindex=0
		
			colindex<=colindex+3'd1;
			M2_state<=S_LI_FETCH_1;
		end
		S_LI_FETCH_1: begin //18'd76801, colindex=1
		
			colindex<=colindex+3'd1;
		

			
			M2_state<=S_LI_FETCH_2;
		end
		S_LI_FETCH_2: begin //17'd76802 colindex=2. start writing 0
			
			wrenARAM1<=1'b1; //write
			dataARAM1<=SRAM_read_data; //write the data in memory of RAM1
			addressARAM1<=sPRIMEwriteaddress;
			sPRIMEwriteaddress<=sPRIMEwriteaddress+7'd1; //increment the base address of RAM1 memory
			
			if(colindex<3'd7) begin
				M2_state<=S_LI_FETCH_2;
				colindex<=colindex+3'd1;
			end else begin
				colindex<=3'd0; //reset ci
				if(rowindex<3'd7) begin //once ri reaches 7
					rowindex<=rowindex+3'd1; //increment ri
					M2_state<=S_LI_FETCH_2;
				end else begin
					rowindex<=3'd0; //reset our ri
					colblock0<=colblock0+18'd1; //increment col block to Y(0,1)
					
					M2_state<=S_LI_FETCH_3;
					
				end
			end
			 
		end
		
		//ONLY TOUCH COLBLOCK AND ROWBLOCK AFTER EACH TOTAL Y U AND V CALCULATION
		
		S_LI_FETCH_3: begin
			dataARAM1<=SRAM_read_data; //write the data in memory of RAM1
			addressARAM1<=sPRIMEwriteaddress;
			sPRIMEwriteaddress<=sPRIMEwriteaddress+7'd1; //increment the base address of RAM1 memory
			
			
			
			//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
			addressBRAM1<=sPRIMErow;
			
			//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
			addressARAM0<=CreadAddressA;
					
			addressBRAM0<=CreadAddressB; //C2 and C3
			
			
			M2_state<=S_LI_FETCH_4;
			
		end
		S_LI_FETCH_4: begin //location 0 for S'
			dataARAM1<=SRAM_read_data; //write the data in memory of RAM1
			addressARAM1<=sPRIMEwriteaddress;
			
			//reset sPRIMEwriteaddress for MA
			sPRIMEwriteaddress<=7'd0;
			
			//reading next S' values - 1 AT A TIME
			addressBRAM1<=addressBRAM1+7'd1;
					
			//reading next C values - 4 AT A TIME
			addressARAM0<=addressARAM0+7'd4;
					
			addressBRAM0<=addressBRAM0+7'd4;
			
			M2_state<=S_LI_TCALC_0;
			
		
		end
		
		//ADD IN ANOTHER STATE FOR EXTRA CALCULATIOn(MAYBE)
		S_LI_TCALC_0: begin //START T Calculation. location 1 for S' but calculation for location 0 of S' . (TCC0)
		
		Taccum1<=Mult1_result;
		Taccum2<=Mult2_result;
		Taccum3<=Mult3_result;
		Taccum4<=Mult4_result;
		
		
		
		
		if(writecountT>4'd0) begin
		wrenARAM2<=1'b1; //write
		wrenBRAM2<=1'b1; //write
		
		addressARAM2<=TwriteA;
		addressBRAM2<=TwriteB;
		
		TwriteA<=TwriteA+7'd2;
		TwriteB<=TwriteB+7'd2;
		
		dataARAM2<={Tone};
		dataBRAM2<={Ttwo};
		
		Tbuffer3<=Tthree;
		Tbuffer4<=Tfour;
		end else begin
			wrenARAM1<=1'b0; //disable writing for S'
		end
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressBRAM1<=addressBRAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		M2_state<=S_LI_TCALC_1;
		end
		
		S_LI_TCALC_1: begin //1
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		if(writecountT>4'd0) begin
		
		addressARAM2<=TwriteA;
		addressBRAM2<=TwriteB;
		
		TwriteA<=TwriteA+7'd2;
		TwriteB<=TwriteB+7'd2;
		
		dataARAM2<={Tbuffer3};
		dataBRAM2<={Tbuffer4};
		
		end
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressBRAM1<=addressBRAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		M2_state<=S_LI_TCALC_2;
		end
		S_LI_TCALC_2: begin //2
		
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		if(writecountT>4'd0) begin
		wrenARAM2<=1'b0; //read
		wrenBRAM2<=1'b0; //read
		
		end
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressBRAM1<=addressBRAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		M2_state<=S_LI_TCALC_3;
		
		end
		S_LI_TCALC_3: begin //3
		
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressBRAM1<=addressBRAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		M2_state<=S_LI_TCALC_4;
		
		end 
		S_LI_TCALC_4: begin //4
		
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressBRAM1<=addressBRAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		M2_state<=S_LI_TCALC_5;
		end
		S_LI_TCALC_5: begin //5
		
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressBRAM1<=addressBRAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		if (flagT==1'd1) begin // only incrment when doing calc for next row of T
			CreadAddressA<=CreadAddressA-7'd2;
			CreadAddressB=CreadAddressB-7'd2;
			
			sPRIMErow<=sPRIMErow+7'd8;
			
			flagT<=1'd0;
		end else begin
			CreadAddressA<=CreadAddressA+7'd2; //increments depedning on calculation
			CreadAddressB<=CreadAddressB+7'd2;
			flagT<=1'd1;
		end
		
		M2_state<=S_LI_TCALC_6;
		end
		
		S_LI_TCALC_6: begin //6 NEEDS TO BE ASSERTED HERE . IF FLAG=0, going from C0, C1, C2, C3 to C4, C5, C6, C7
		
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		

		if (writecountT<4'd15) begin
		addressARAM0<=CreadAddressA;
		addressBRAM0<=CreadAddressB;
		
		addressBRAM1<=sPRIMErow;
		end
	
		M2_state<=S_LI_TCALC_7;
		end
		
		S_LI_TCALC_7: begin //7
		
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		
		
		if(writecountT<4'd15) begin
		
	
		writecountT<=writecountT+4'd1;
		
		addressBRAM1<=addressBRAM1+7'd1;
		
		addressARAM0<=addressARAM0+7'd4;			
		addressBRAM0<=addressBRAM0+7'd4;
		
		M2_state<=S_LI_TCALC_0;
		end else begin
			
		//writing counter for the amount of T values (per 4) calculated reset back to 0
		writecountT<=4'd0;	
		
			M2_state<=S_LI_TCALC_8;
		end
		
		end
		
		S_LI_TCALC_8: begin
		
		wrenARAM2<=1'b1; //write
		wrenBRAM2<=1'b1; //write
		
		addressARAM2<=TwriteA;
		addressBRAM2<=TwriteB;
		
		TwriteA<=TwriteA+7'd2;
		TwriteB<=TwriteB+7'd2;
		
		dataARAM2<={Tone};
		dataBRAM2<={Ttwo};
		
		Tbuffer3<=Tthree;
		Tbuffer4<=Tfour;
		

		M2_state<=S_LI_TCALC_9; 
		
		end
		S_LI_TCALC_9: begin //colindex set to 0
		
		addressARAM2<=TwriteA;
		addressBRAM2<=TwriteB;
		
		
		dataARAM2<={Tbuffer3};
		dataBRAM2<={Tbuffer4};
			


		TwriteA<=7'd0;
		TwriteB<=7'd1;
		
		CreadAddressA<=7'd0;
		CreadAddressB<=7'd1;
		//fetch s' -BEGINS
		
		colindex<=3'd0;
		rowindex<=3'd0;
		
		//fetch s' - ENDS
		M2_state<=S_LI_TCALC_10; 
		end
		S_LI_TCALC_10: begin //colindex set to 1
		
		//finish writng T ro ram2
		wrenARAM2<=1'b0; //read
		wrenBRAM2<=1'b0; //read
			
		addressARAM0<=CreadAddressA;
		addressBRAM0<=CreadAddressB;
		
		addressARAM2<=TreadA;
		
		colindex<=colindex+3'd1;
	
		flagT<=1'd0;
		M2_state<=S_LI_TCALC_11;
		end
		S_LI_TCALC_11: begin 
		
		colindex<=colindex+3'd1;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		M2_state<=S_MA_0;
		end
		
		//fetch s' and compute s
		
		S_MA_0: begin  //begining of repitive 8 clock cycle compute S. //colindex set to 2
		
		Saccum1<=Mult1_result;
		Saccum2<=Mult2_result;
		Saccum3<=Mult3_result;
		Saccum4<=Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		if(writecountS>4'd0) begin
			wrenBRAM1<=1'b1; //write
		
			if (flagS==1'd1) begin
				addressBRAM1<=SwriteB;
			end else begin
				addressBRAM1<=addressBRAM1+7'd8;
			end
		
			dataBRAM1<={Sone};
		
			Sbuffer2<=Stwo;
			Sbuffer3<=Sthree;
			Sbuffer4<=Sfour;
		end 
		//code for fetching s' - STARTS
		
			wrenARAM1<=1'b1; //write
			dataARAM1<=SRAM_read_data; //write the data in memory of RAM1
			addressARAM1<=sPRIMEwriteaddress;
			sPRIMEwriteaddress<=sPRIMEwriteaddress+7'd1; //increment the base address of RAM1 memory
			
			if(colindex<3'd7) begin
				colindex<=colindex+3'd1;
			end else begin
				colindex<=3'd0; //reset ci
				if(rowindex<3'd7) begin //once ri reaches 7
					rowindex<=rowindex+3'd1; //increment ri
				end else begin
					rowindex<=3'd0; //reset our ri
				end
			end
		
		
		//code for fetching s' - ENDS
		
		
		M2_state<=S_MA_1;
		end
		
		S_MA_1: begin //2
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		if(writecountS>4'd0) begin
		
		addressBRAM1<=addressBRAM1+7'd8;
		
		
		
		dataBRAM1<={Sbuffer2};	
		end 
		
		//code for fetching s' - STARTS
		
			dataARAM1<=SRAM_read_data; //write the data in memory of RAM1
			addressARAM1<=sPRIMEwriteaddress;
			sPRIMEwriteaddress<=sPRIMEwriteaddress+7'd1; //increment the base address of RAM1 memory
			
			if(colindex<3'd7) begin
				colindex<=colindex+3'd1;
			end else begin
				colindex<=3'd0; //reset ci
				if(rowindex<3'd7) begin //once ri reaches 7
					rowindex<=rowindex+3'd1; //increment ri
				end else begin
					rowindex<=3'd0; //reset our ri
					if (colblock0<numcolblock0) begin // IF LESS THAN 18'd39
						colblock0<=colblock0+18'd1; //increment col block to Y(0,1)
					end else begin
						colblock0<=18'd0;
						if(rowblock0<18'd29) begin
							rowblock0<=rowblock0+18'd1;
						end else begin
							rowblock0<=18'd0;
						end
					end
					
				end
			end
		
		
		//code for fetching s' - ENDS
		
		
		M2_state<=S_MA_2;
		end
		
		S_MA_2: begin //3
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		
		if(writecountS>4'd0) begin

		
		addressBRAM1<=addressBRAM1+7'd8;
		

		dataBRAM1<={Sbuffer3};	
		end 
		
		//code for fetching s' - STARTS
		
			dataARAM1<=SRAM_read_data; //write the data in memory of RAM1
			addressARAM1<=sPRIMEwriteaddress;
			sPRIMEwriteaddress<=sPRIMEwriteaddress+7'd1; //increment the base address of RAM1 memory
			
	
		
		//code for fetching s' - ENDS
		
		M2_state<=S_MA_3;
		end
		
		S_MA_3: begin //4
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;

		
		if(writecountS>4'd0) begin
		
		addressBRAM1<=addressBRAM1+7'd8;
		
		dataBRAM1<={Sbuffer4};	
		end 
		
		if (writecountS==4'd15) begin
		
		end
	
	//code for fetching s' - STARTS
		
			dataARAM1<=SRAM_read_data; //write the data in memory of RAM1
			addressARAM1<=sPRIMEwriteaddress;
			sPRIMEwriteaddress<=sPRIMEwriteaddress+7'd1;
		
		//code for fetching s' - ENDS
		
		M2_state<=S_MA_4;
		end
		
		S_MA_4: begin //5
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		if(writecountS>4'd0) begin
		wrenBRAM1<=1'b0; //read
		end 
		
		//code for fetching s' - STARTS
		
		wrenARAM1<=1'b0; //read
		
		//code for fetching s' - ENDS
	
		
		M2_state<=S_MA_5;
		end
		
		S_MA_5: begin //
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		if (flagS==1'd1) begin
			CreadAddressA<=CreadAddressA-7'd2; //increments depedning on calculation
			CreadAddressB<=CreadAddressB-7'd2;
		
			TreadA<=TreadA+7'd1;
		
			SwriteB<=SwriteB+7'd1;
			flagS<=1'd0;
		
		end else begin
			CreadAddressA<=CreadAddressA+7'd2; //increments depedning on calculation
			CreadAddressB<=CreadAddressB+7'd2;
		
			flagS<=1'd1;
		end
		

		M2_state<=S_MA_6;
		end
		
		S_MA_6: begin //7
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		
		if(writecountS<4'd15) begin
			addressARAM0<=CreadAddressA;
			addressBRAM0<=CreadAddressB;
		
			addressARAM2<=TreadA;
		end
		
		//code for fetching s'
				
				if(colindex<3'd7) begin
					colindex<=colindex+3'd1;
				end else begin
					colindex<=3'd0; //reset ci
					if(rowindex<3'd7) begin //once ri reaches 7
						rowindex<=rowindex+3'd1; //increment ri
					end else begin
						rowindex<=3'd0; //reset our ri		
					end
				end

		//end of code
		
		M2_state<=S_MA_7;
		end
		
		S_MA_7: begin 

		//code for fetching s'
		
				if(colindex<3'd7) begin
					colindex<=colindex+3'd1;
				end else begin
					colindex<=3'd0; //reset ci
					if(rowindex<3'd7) begin //once ri reaches 7
						rowindex<=rowindex+3'd1; //increment ri
					end else begin
						rowindex<=3'd0; //reset our ri		
					end
				end
			
	//end of it
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		
		if (writecountS<4'd15) begin
		
			addressARAM0<=addressARAM0+7'd4;
			addressBRAM0<=addressBRAM0+7'd4;
		
			addressARAM2<=addressARAM2+7'd8;
		
			writecountS<=writecountS+4'd1;
			M2_state<=S_MA_0; 
		end else begin
			writecountS<=4'd0;
			sPRIMEwriteaddress<=7'd0; //RESET WRITING S' STARTING ADDRESS
			M2_state<=S_MA_8;
			
		end
		
		end

		S_MA_8: begin
		wrenBRAM1<=1'b1; //write
		addressBRAM1<=addressBRAM1+7'd8;
		
				
		dataBRAM1<={Sone};
		
		Sbuffer2<=Stwo;
		Sbuffer3<=Sthree;
		Sbuffer4<=Sfour;
		
		M2_state<=S_MA_9;
		end
		S_MA_9: begin
		addressBRAM1<=addressBRAM1+7'd8;
		dataBRAM1<={Sbuffer2};
		
		//setting up MB
		CreadAddressA<=7'd0;
		CreadAddressB<=7'd1;
		
		sPRIMErow=7'd0;
		//end of setting up MB
		
		M2_state<=S_MA_10;
		end
		S_MA_10: begin
		addressBRAM1<=addressBRAM1+7'd8;
		dataBRAM1<={Sbuffer3};
		
				//setting up MB
		addressARAM0<=CreadAddressA;
		addressBRAM0<=CreadAddressB;
		
		addressARAM1<=sPRIMErow;
		// end of setting up
		
		M2_state<=S_MA_11;

		end
		S_MA_11: begin
		addressBRAM1<=addressBRAM1+7'd8;
		dataBRAM1<={Sbuffer4};
	
		
		flagS<=1'd0;
		//CHANGING TO WRITE TO SRAM FOR MB
		SRAMFLAG<=1'b1;
		SwriteB<=7'd64;
		// END OF IT
		
		//reading next S' values - 1 AT A TIME
		addressARAM1<=addressARAM1+7'd1;
					
		//reading next C values - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
			
		M2_state<=S_MB_0;
		
		colindex<=3'd0;
		rowindex<=3'd0;
		
		M2_state<=S_MB_0;
		end
		
		S_MB_0: begin
		
		Taccum1<=Mult1_result;
		Taccum2<=Mult2_result;
		Taccum3<=Mult3_result;
		Taccum4<=Mult4_result;
		
		
		
		
		if(writecountT>4'd0) begin
			wrenARAM2<=1'b1; //write
			wrenBRAM2<=1'b1; //write
		
			addressARAM2<=TwriteA;
			addressBRAM2<=TwriteB;
		
			TwriteA<=TwriteA+7'd2;
			TwriteB<=TwriteB+7'd2;
		
			dataARAM2<={Tone};
			dataBRAM2<={Ttwo};
		
			Tbuffer3<=Tthree;
			Tbuffer4<=Tfour;
		
			addressBRAM1<=addressBRAM1+7'd1;
		end else begin
			//finish wrting (FINISH MA)
			wrenBRAM1<=1'b0; //read FOR READING S' FOR T CALCULATION
			addressBRAM1=7'd64; //starting address
			//END
		end
		
			//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
			addressARAM1<=addressARAM1+7'd1;
					
			//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
			addressARAM0<=addressARAM0+7'd4;
					
			addressBRAM0<=addressBRAM0+7'd4;
		
			M2_state<=S_MB_1;
		
		end
		S_MB_1: begin
		
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		
		
		
		if(writecountT>4'd0) begin
		wrenARAM2<=1'b1; //write
		wrenBRAM2<=1'b1; //write
		
		addressARAM2<=TwriteA;
		addressBRAM2<=TwriteB;
		
		TwriteA<=TwriteA+7'd2;
		TwriteB<=TwriteB+7'd2;
		
		dataARAM2<={Tbuffer3};
		dataBRAM2<={Tbuffer4};
		
		end
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressARAM1<=addressARAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		//CODE FOR WRITING S TO SRAM
		
		addressBRAM1<=addressBRAM1+7'd1;
		
		M2_state<=S_MB_2;
		
		end
		S_MB_2: begin
		
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		
		
		
		if(writecountT>4'd0) begin
		wrenARAM2<=1'b0; //read
		wrenBRAM2<=1'b0; //read
		
		end
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressARAM1<=addressARAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		//CODE FOR WRITING S TO SRAM
		
		value1WRITES<=outputBRAM1[7:0];
		
		addressBRAM1<=addressBRAM1+7'd1;
		
		
		
		M2_state<=S_MB_3;
		
		end
		S_MB_3: begin
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressARAM1<=addressARAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		//CODE FOR WRITING S TO SRAM
		
		value2WRITES<=outputBRAM1[7:0];
		

		
		
		addressBRAM1<=addressBRAM1+7'd1;
		
		M2_state<=S_MB_4;
		end
		
		S_MB_4: begin
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressARAM1<=addressARAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		//Code for wrting S to Sram
		
		SRAM_we_n<=1'b0; //write
		SRAM_write_data<={value1WRITES,value2WRITES};
		
		value1WRITES<=outputBRAM1[7:0];
	
		
		M2_state<=S_MB_5;
		end
		S_MB_5: begin
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		if (flagT==1'd1) begin // only incrment when doing calc for next row of T
			CreadAddressA<=CreadAddressA-7'd2;
			CreadAddressB=CreadAddressB-7'd2;
			
			sPRIMErow<=sPRIMErow+7'd8;
			flagT<=1'd0;
		end else begin
			CreadAddressA<=CreadAddressA+7'd2; //increments depedning on calculation
			CreadAddressB<=CreadAddressB+7'd2;
			flagT<=1'd1;
		end
		
		//start addressing in order to read S' starting from S'(0,0) - 1 AT A TIME
		addressARAM1<=addressARAM1+7'd1;
					
		//start addressing in order to read C starting from C (0,0) - 4 AT A TIME
		addressARAM0<=addressARAM0+7'd4;
					
		addressBRAM0<=addressBRAM0+7'd4;
		
		//CODE FOR WRITING S TO SRAM
		SRAM_write_data<={value1WRITES,outputBRAM1[7:0]};
		
		//CODE FOR WRITING S TO SRAM
		
		
		if(colindex<3'd3) begin
			colindex<=colindex+3'd1;
		end else begin
			colindex<=3'd0;
			if (rowindex<3'd7) begin
				rowindex<=rowindex+3'd1;
			end else begin
				rowindex<=3'd0;
			end
		end
		
		M2_state<=S_MB_6;
		end
		S_MB_6: begin
		
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		

		if (writecountT<4'd15) begin
		addressARAM0<=CreadAddressA;
		addressBRAM0<=CreadAddressB;
		
		addressARAM1<=sPRIMErow;
		end
		
		//CODE FOR WRITING S TO SRAM
		
		SRAM_we_n<=1'b1; //read
		if(colindex<3'd3) begin
			colindex<=colindex+3'd1;
		end else begin
			colindex<=3'd0;
			if (rowindex<3'd7) begin
				rowindex<=rowindex+3'd1;
			end else begin
				rowindex<=3'd0;
			end
		end
	
		
		M2_state<=S_MB_7;
		end
		
		S_MB_7: begin
		Taccum1<=Taccum1+Mult1_result;
		Taccum2<=Taccum2+Mult2_result;
		Taccum3<=Taccum3+Mult3_result;
		Taccum4<=Taccum4+Mult4_result;
		
		
			if(writecountT<4'd15) begin
		
	
			writecountT<=writecountT+4'd1;
		
			addressARAM1<=addressARAM1+7'd1;
		
			addressARAM0<=addressARAM0+7'd4;			
			addressBRAM0<=addressBRAM0+7'd4;
		
			M2_state<=S_MB_0;
			end else begin
			
			//writing counter for the amount of T values (per 4) calculated reset back to 0
			writecountT<=4'd0;	
		
			M2_state<=S_MB_8;
			end
		end
		
		S_MB_8: begin
		
		wrenARAM2<=1'b1; //write
		wrenBRAM2<=1'b1; //write
		
		addressARAM2<=TwriteA;
		addressBRAM2<=TwriteB;
		
		TwriteA<=TwriteA+7'd2;
		TwriteB<=TwriteB+7'd2;
		
		dataARAM2<={Tone};
		dataBRAM2<={Ttwo};
		
		Tbuffer3<=Tthree;
		Tbuffer4<=Tfour;
		
		
		
		//fetch s' - ENDS
		
		M2_state<=S_MB_9;
		end
		S_MB_9: begin
		
		addressARAM2<=TwriteA;
		addressBRAM2<=TwriteB;
		

		dataARAM2<={Tbuffer3};
		dataBRAM2<={Tbuffer4};
		
			
		//reading addresses for C reset back to 0 & 1 (NEED THE OFFSET)
		CreadAddressA<=7'd0;
		CreadAddressB<=7'd1;
		
		TreadA<=7'd0;
		
		
		//fetch s' -BEGINS
		
		colindex<=3'd0;
		rowindex<=3'd0;
		SRAMFLAG<=1'b0;


		//fetch s' -ENDS
		
		M2_state<=S_MB_10;
		end
		S_MB_10: begin
		
		//finish writng T to ram2
		wrenARAM2<=1'b0; //read
		wrenBRAM2<=1'b0; //read
		
		//set up C and T addressing for S calculation;
					
		addressARAM0<=CreadAddressA;
		addressBRAM0<=CreadAddressB;
		
		
		addressARAM2<=TreadA;
		
		colindex<=colindex+3'd1;
		M2_state<=S_MB_11;
		end
		
		S_MB_11: begin
		
	
		//writing addresses for t calculation reset back to 0
		TwriteA<=7'd0;
		TwriteB<=7'd1;
		//reset in order to compute T
		sPRIMErow<=7'd0;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;

		//fetch s' -BEGINS
		colindex<=colindex+3'd1;
		//fetch s' -ENDS
		
		//reset flagT
		flagT<=1'd0;
		
		
		//PUT CODE HERE FOR REPEATING COMMON CASE OR LEAD OUT
		
		if(colblock1<numcolblock1) begin
			colblock1<=colblock1+18'd1;
			M2_state<=S_MA_0;
		end else begin
			colblock1<=18'd0;
			if(rowblock1<18'd29) begin
				rowblock1<=rowblock1+18'd1;
				M2_state<=S_MA_0;
			end
		end
		
		if(rowblock1==18'd29 && colblock1==(numcolblock1-18'd1)) begin
			M2_state<=S_LO_CS_0;
		end
		
		//FINISH CODING LEAD OUT// CHANGE COLBLOCK CONDITIONS TO VARIABLES FOR 39 (Y) and 19 (U/V)
		end
		S_LO_CS_0: begin
		
		Saccum1<=Mult1_result;
		Saccum2<=Mult2_result;
		Saccum3<=Mult3_result;
		Saccum4<=Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		if(writecountS>4'd0) begin
			wrenBRAM1<=1'b1; //write
		
			if (flagS==1'd1) begin
				addressBRAM1<=SwriteB;
			end else begin
				addressBRAM1<=addressBRAM1+7'd8;
			end
		
			dataBRAM1<={Sone};
		
			Sbuffer2<=Stwo;
			Sbuffer3<=Sthree;
			Sbuffer4<=Sfour;
		
			
		end
		M2_state<=S_LO_CS_1;
		end
		S_LO_CS_1: begin
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		if(writecountS>4'd0) begin
		
		addressBRAM1<=addressBRAM1+7'd8;
		
		dataBRAM1<={Sbuffer2};
		
		end
		M2_state<=S_LO_CS_2;
		end
		S_LO_CS_2: begin
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		
		if(writecountS>4'd0) begin

		
		addressBRAM1<=addressBRAM1+7'd8;
		

		dataBRAM1<={Sbuffer3};	
		end 
		
		M2_state<=S_LO_CS_3;
		end
		S_LO_CS_3: begin
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;

		
		if(writecountS>4'd0) begin
		
		addressBRAM1<=addressBRAM1+7'd8;
		
		dataBRAM1<={Sbuffer4};	
		end 
		
		if (writecountS==4'd15) begin
		
		end
		
		M2_state<=S_LO_CS_4;
		end
		S_LO_CS_4: begin
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		if(writecountS>4'd0) begin
		wrenBRAM1<=1'b0; //read
		end 
		
		M2_state<=S_LO_CS_5;
		end
		S_LO_CS_5: begin
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		addressARAM0<=addressARAM0+7'd4;
		addressBRAM0<=addressBRAM0+7'd4;
		
		addressARAM2<=addressARAM2+7'd8;
		
		if (flagS==1'd1) begin
			CreadAddressA<=CreadAddressA-7'd2; //increments depedning on calculation
			CreadAddressB<=CreadAddressB-7'd2;
		
			TreadA<=TreadA+7'd1;
		
			SwriteB<=SwriteB+7'd1;
			flagS<=1'd0;
		
		end else begin
			CreadAddressA<=CreadAddressA+7'd2; //increments depedning on calculation
			CreadAddressB<=CreadAddressB+7'd2;
		
			flagS<=1'd1;
		end
		
		M2_state<=S_LO_CS_6;
		end
		S_LO_CS_6: begin
		
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		
		if(writecountS<4'd15) begin
			addressARAM0<=CreadAddressA;
			addressBRAM0<=CreadAddressB;
		
			addressARAM2<=TreadA;
		end
		
		M2_state<=S_LO_CS_7;
		end
		S_LO_CS_7: begin
	
		Saccum1<=Saccum1+Mult1_result;
		Saccum2<=Saccum2+Mult2_result;
		Saccum3<=Saccum3+Mult3_result;
		Saccum4<=Saccum4+Mult4_result;
		
		
		if (writecountS<4'd15) begin
		
			addressARAM0<=addressARAM0+7'd4;
			addressBRAM0<=addressBRAM0+7'd4;
		
			addressARAM2<=addressARAM2+7'd8;
		
			writecountS<=writecountS+4'd1;
			M2_state<=S_LO_CS_0; 
		end else begin
			writecountS<=4'd0;
			sPRIMEwriteaddress<=7'd0; //RESET WRITING S' STARTING ADDRESS
			M2_state<=S_LO_CS_8;
			
		end
		
		end
		S_LO_CS_8: begin
		
		wrenBRAM1<=1'b1; //write
		addressBRAM1<=addressBRAM1+7'd8;
		
				
		dataBRAM1<={Sone};
		
		Sbuffer2<=Stwo;
		Sbuffer3<=Sthree;
		Sbuffer4<=Sfour;
		
		M2_state<=S_LO_CS_9;
		end
		S_LO_CS_9: begin
		
		addressBRAM1<=addressBRAM1+7'd8;
		dataBRAM1<={Sbuffer2};
		
		M2_state<=S_LO_CS_10;
		end
		S_LO_CS_10: begin
		
		addressBRAM1<=addressBRAM1+7'd8;
		dataBRAM1<={Sbuffer3};
		
		M2_state<=S_LO_CS_11;
		end
		S_LO_CS_11: begin
		
		addressBRAM1<=addressBRAM1+7'd8;
		dataBRAM1<={Sbuffer4};
		
		SRAMFLAG<=1'b1;
		colindex<=3'd0;
		rowindex<=3'd0;
		
		M2_state<=S_LO_WS_0;
		
		end
		S_LO_WS_0: begin
		
		//finish wrting (FINISH MA)
			wrenBRAM1<=1'b0; //read FOR READING S' FOR T CALCULATION
			addressBRAM1=7'd65; //starting address
			wrenARAM1<=1'b0; 
			addressARAM1=7'd64;
		//END
		M2_state<=S_LO_WS_1;
		
		end
		S_LO_WS_1: begin //SET TO 64 & 65
		
		addressARAM1<=addressARAM1+7'd2;
		addressBRAM1<=addressBRAM1+7'd2;
		M2_state<=S_LO_WS_2;
		
		end
		S_LO_WS_2: begin // SET TO 66 & 66. Read in 64 & 65
		
		SRAM_we_n=1'b0; //WRITE
		SRAM_write_data<={outputARAM1[7:0], outputBRAM1[7:0]};
		
		addressARAM1<=addressARAM1+7'd2;
		addressBRAM1<=addressBRAM1+7'd2;
		
		M2_state<=S_LO_WS_3;
		
		end
		
		S_LO_WS_3: begin
		
		SRAM_write_data<={outputARAM1[7:0], outputBRAM1[7:0]};
		
		if (addressARAM1<7'd126 && addressBRAM1< 7'd127) begin
		addressARAM1<=addressARAM1+7'd2;
		addressBRAM1<=addressBRAM1+7'd2;
		M2_state<=S_LO_WS_3;
		end else begin
		M2_state<=S_LO_WS_4;
		end
		if(colindex<3'd3) begin
			colindex<=colindex+3'd1;
		end else begin
			colindex<=3'd0;
			if (rowindex<3'd7) begin
				rowindex<=rowindex+3'd1;
			end else begin
				rowindex<=3'd0;
			end
		end
		
		end
		S_LO_WS_4: begin
		
		SRAM_write_data<={outputARAM1[7:0], outputBRAM1[7:0]};
		
		if(colindex<3'd3) begin
			colindex<=colindex+3'd1;
		end else begin
			colindex<=3'd0;
			if (rowindex<3'd7) begin
				rowindex<=rowindex+3'd1;
			end else begin
				rowindex<=3'd0;
			end
		end
		
		
		M2_state<=S_LO_WS_5;
		end

		S_LO_WS_5: begin
		
		if (counter0<2'd2) begin
			counter0<=counter0+2'd1;
			numcolblock0<=18'd19;
			numcolblock1<=18'd19;
			M2_state<=S_LI_FETCH_0;
			if(counter0==2'd0) begin
				offset0<=18'd153600;
				offset1<=18'd38400;
			end else begin
				offset0<=18'd192000;
				offset1<=18'd57600;
			end
		end else begin
			numcolblock0<=18'd39;
			numcolblock1<=18'd39;
			counter0<=2'd0;
			offset0<=18'd76800;
			offset1<=18'd0;
			Done<=1'b1;
			M2_state<=S_DONE;
		end
		
		//RESET VARIABLES TO BEGIN LEAD IN AGAIN
		

		//RAM0 line 1
		wrenARAM0<=1'b0; //0 is read, 1 is write
		dataARAM0<=32'd0;
		addressARAM0<=7'd0;
	
		//RAM0 line 2
		wrenBRAM0<=1'b0; //0 is read, 1 is write
		dataBRAM0<=32'd0;
		addressBRAM0<=7'd0;
	
		//RAM1 line 1
		wrenARAM1<=1'b0; //0 is read, 1 is write
		dataARAM1<=32'd0;
		addressARAM1<=7'd0;
	
		//RAM1 line 2
		wrenBRAM1<=1'b0; //0 is read, 1 is write
		dataBRAM1<=32'd0;
		addressBRAM1<=7'd0;
	
		//RAM2 line 1
		wrenARAM2<=1'b0; //0 is read, 1 is write
		dataARAM2<=32'd0;
		addressARAM2<=7'd0;
	
		//RAM2 line 2
		wrenBRAM2<=1'b0; //0 is read, 1 is write
		dataBRAM2<=32'd0;
		addressBRAM2<=7'd0;

		CreadAddressA<=7'd0;
		CreadAddressB<=7'd1; //starting at a different address for reading C from DRAM0
	
	
		sPRIMEwriteaddress<=7'd0; //writing S' in the DRAM1 address from the SRAM
	 
		sPRIMErow<=7'd0; //for reading S' from DRAM1 not from SRAM
	

		rowblock0<=18'd0;
		colblock0<=18'd0;
		rowblock1<=18'd0;
		colblock1<=18'd0;
	
		rowindex<=3'd0;
		colindex<=3'd0; 
	
		Taccum1<=32'd0;
		Taccum2<=32'd0;
		Taccum3<=32'd0;
		Taccum4<=32'd0;
	
		Tbuffer3<=32'd0;
		Tbuffer4<=32'd0;
	
		TwriteA<=7'd0;
		TwriteB<=7'd1; //Start writing at a different address
	
		SwriteB<=7'd64;
	
		writecountT<=4'd0;
		writecountS<=4'd0;
	
		Saccum1<=32'd0;
		Saccum2<=32'd0;
		Saccum3<=32'd0;
		Saccum4<=32'd0;
	
		Sbuffer2<=32'd0;
		Sbuffer3<=32'd0;
		Sbuffer4<=32'd0;


		SRAM_write_data<=16'd0;
		SRAM_we_n<=1'd1; //reading
	
		flagT<=1'd0;
		flagS<=1'd0;
		
		TreadA<=7'd0;
	
		SRAMFLAG<=1'd0;
	
		value1WRITES<=7'd0;
		value2WRITES<=7'd0;
		
		//END OF RESETTING VARIABLES
		
		end
		S_DONE: begin	
			
			Done<=1'b0;
			M2_state<=S_M2IDLE;
			
		end

		default: M2_state<=S_M2IDLE;
		endcase
		
	end 
end
	


always_comb begin
			rowblock=18'd0;
			colblock=18'd0;
			offset=18'd0;
			rowaddress=18'd0;
			coladdress=18'd0;
			SRAM_address=18'd0;
		if(SRAMFLAG==1'b1) begin
			rowblock=rowblock1;
			colblock=colblock1;
			offset=offset1;
		end else begin
			rowblock=rowblock0;
			colblock=colblock0;
			offset=offset0;
		end
		
		if(counter0<2'd1) begin //use counter0 to check if should do addressing for y or u/v
			if(SRAMFLAG==1'b0) begin
			rowaddress={rowblock,rowindex};
			coladdress={colblock,colindex};
			SRAM_address={rowaddress,8'd0}+{rowaddress,6'd0}+coladdress +offset;
			end else begin
			rowaddress={rowblock,rowindex};
			coladdress={colblock[15:0],colindex[1:0]};
			SRAM_address={rowaddress,7'd0}+{rowaddress,5'd0}+coladdress +offset;
			end
		end else begin
			if(SRAMFLAG==1'b0) begin
			rowaddress={rowblock,rowindex};
			coladdress={colblock,colindex};
			SRAM_address={rowaddress,7'd0}+{rowaddress,5'd0}+coladdress +offset;
			end else begin
			rowaddress={rowblock,rowindex};
			coladdress={colblock[15:0],colindex[1:0]};
			SRAM_address={rowaddress,6'd0}+{rowaddress,4'd0}+coladdress +offset;
			end
		end	
	
	
	Mult1_op1=32'd0;
	Mult1_op2=32'd0;
	
	Mult2_op1=32'd0;
	Mult2_op2=32'd0;
	
	Mult3_op1=32'd0;
	Mult3_op2=32'd0;
	
	Mult4_op1=32'd0;
	Mult4_op2=32'd0;
	
	Tone =32'd0;
	Ttwo=32'd0;
	Tthree=32'd0;
	Tfour=32'd0;
	Sone =32'd0;
	Stwo=32'd0;
	Sthree=32'd0;
	Sfour=32'd0;
	case(M2_state)
	
		
		
	
		S_LI_TCALC_0: begin
	
		Mult1_op1=$signed(outputBRAM1[15:0]); //S0'
		Mult1_op2=$signed(outputARAM0[31:16]); //C0
		
		Mult2_op1=$signed(outputBRAM1[15:0]); //S0'
		Mult2_op2=$signed(outputARAM0[15:0]); //C1
		
		Mult3_op1=$signed(outputBRAM1[15:0]); //S'
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2
		
		Mult4_op1=$signed(outputBRAM1[15:0]); //S'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3
		
		// divide by 256
		
		Tone={8'd0,Taccum1[31:8]};
		Ttwo={8'd0,Taccum2[31:8]};
		Tthree={8'd0,Taccum3[31:8]};
		Tfour={8'd0,Taccum4[31:8]};
	
		end
		
		S_LI_TCALC_1: begin
		
		Mult1_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult1_op2=$signed(outputARAM0[31:16]); //C8
		
		Mult2_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult2_op2=$signed(outputARAM0[15:0]); //C9
		
		Mult3_op1=$signed(outputBRAM1[15:0]); //S1
		Mult3_op2=$signed(outputBRAM0[31:16]); //C10
		
		Mult4_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C11
		
		end
		
		S_LI_TCALC_2: begin
		
		Mult1_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult1_op2=$signed(outputARAM0[31:16]); //C8
		
		Mult2_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult2_op2=$signed(outputARAM0[15:0]); //C9
		
		Mult3_op1=$signed(outputBRAM1[15:0]); //S1
		Mult3_op2=$signed(outputBRAM0[31:16]); //C10
		
		Mult4_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C11
		
		end
		S_LI_TCALC_3: begin
		
		Mult1_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult1_op2=$signed(outputARAM0[31:16]); //C8
		
		Mult2_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult2_op2=$signed(outputARAM0[15:0]); //C9
		
		Mult3_op1=$signed(outputBRAM1[15:0]); //S1
		Mult3_op2=$signed(outputBRAM0[31:16]); //C10
		
		Mult4_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C11
		
		end
		S_LI_TCALC_4: begin
		
		Mult1_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult1_op2=$signed(outputARAM0[31:16]); //C8
		
		Mult2_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult2_op2=$signed(outputARAM0[15:0]); //C9
		
		Mult3_op1=$signed(outputBRAM1[15:0]); //S1
		Mult3_op2=$signed(outputBRAM0[31:16]); //C10
		
		Mult4_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C11
	
		end
		S_LI_TCALC_5: begin
		
		Mult1_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult1_op2=$signed(outputARAM0[31:16]); //C8
		
		Mult2_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult2_op2=$signed(outputARAM0[15:0]); //C9
		
		Mult3_op1=$signed(outputBRAM1[15:0]); //S1
		Mult3_op2=$signed(outputBRAM0[31:16]); //C10
		
		Mult4_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C11
		
		end
		S_LI_TCALC_6: begin
		
		Mult1_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult1_op2=$signed(outputARAM0[31:16]); //C8
		
		Mult2_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult2_op2=$signed(outputARAM0[15:0]); //C9
		
		Mult3_op1=$signed(outputBRAM1[15:0]); //S1
		Mult3_op2=$signed(outputBRAM0[31:16]); //C10
		
		Mult4_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C11
		
		end
		S_LI_TCALC_7: begin
		
		Mult1_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult1_op2=$signed(outputARAM0[31:16]); //C8
		
		Mult2_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult2_op2=$signed(outputARAM0[15:0]); //C9
		
		Mult3_op1=$signed(outputBRAM1[15:0]); //S1
		Mult3_op2=$signed(outputBRAM0[31:16]); //C10
		
		Mult4_op1=$signed(outputBRAM1[15:0]); //S1'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C11
		
		end
		
		S_LI_TCALC_8: begin
		// divide by 256
		
		Tone={8'd0,Taccum1[31:8]};
		Ttwo={8'd0,Taccum2[31:8]};
		Tthree={8'd0,Taccum3[31:8]};
		Tfour={8'd0,Taccum4[31:8]};
		
		
		
		end
		
		S_MA_0: begin
		
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		
		
		//Clipping to 8 bits
		
		
		if (Saccum1[31]) begin
			Sone=8'd0;
		end else begin
			if (|Saccum1[30:24]) begin
				Sone=8'b11111111;
			end else begin
				Sone=Saccum1[23:16];
			end
		end
		
		
		if (Saccum2[31]) begin
			Stwo=8'd0;
		end else begin
			if (|Saccum2[30:24]) begin
				Stwo=8'b11111111;
			end else begin
				Stwo=Saccum2[23:16];
			end
		end
		
		if (Saccum3[31]) begin
			Sthree=8'd0;
		end else begin
			if (|Saccum3[30:24]) begin
				Sthree=8'b11111111;
			end else begin
				Sthree=Saccum3[23:16];
			end
		end
		
		if (Saccum4[31]) begin
			Sfour=8'd0;
		end else begin
			if (|Saccum4[30:24]) begin
				Sfour=8'b11111111;
			end else begin
				Sfour=Saccum4[23:16];
			end
		end

		
		
		end
		S_MA_1: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		
		end
		S_MA_2: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_MA_3: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_MA_4: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_MA_5: begin
		
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_MA_6: begin
		
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_MA_7: begin
		
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_MA_8: begin
		
		//Clipping to 8 bits
		
		
		if (Saccum1[31]) begin
			Sone=8'd0;
		end else begin
			if (|Saccum1[30:24]) begin
				Sone=8'b11111111;
			end else begin
				Sone=Saccum1[23:16];
			end
		end
		
		
		if (Saccum2[31]) begin
			Stwo=8'd0;
		end else begin
			if (|Saccum2[30:24]) begin
				Stwo=8'b11111111;
			end else begin
				Stwo=Saccum2[23:16];
			end
		end
		
		if (Saccum3[31]) begin
			Sthree=8'd0;
		end else begin
			if (|Saccum3[30:24]) begin
				Sthree=8'b11111111;
			end else begin
				Sthree=Saccum3[23:16];
			end
		end
		
		if (Saccum4[31]) begin
			Sfour=8'd0;
		end else begin
			if (|Saccum4[30:24]) begin
				Sfour=8'b11111111;
			end else begin
				Sfour=Saccum4[23:16];
			end
		end
		
		end
		
		S_MB_0: begin
		
		Mult1_op1=$signed(outputARAM1[15:0]); //S0'
		Mult1_op2=$signed(outputARAM0[31:16]); //C0
		
		Mult2_op1=$signed(outputARAM1[15:0]); //S0'
		Mult2_op2=$signed(outputARAM0[15:0]); //C1
		
		Mult3_op1=$signed(outputARAM1[15:0]); //S'
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2
		
		Mult4_op1=$signed(outputARAM1[15:0]); //S'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3
		
		// divide by 256
		
		Tone={8'd0,Taccum1[31:8]};
		Ttwo={8'd0,Taccum2[31:8]};
		Tthree={8'd0,Taccum3[31:8]};
		Tfour={8'd0,Taccum4[31:8]};
		
		
		end
		
		S_MB_1: begin
		
		Mult1_op1=$signed(outputARAM1[15:0]); //S0'
		Mult1_op2=$signed(outputARAM0[31:16]); //C0
		
		Mult2_op1=$signed(outputARAM1[15:0]); //S0'
		Mult2_op2=$signed(outputARAM0[15:0]); //C1
		
		Mult3_op1=$signed(outputARAM1[15:0]); //S'
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2
		
		Mult4_op1=$signed(outputARAM1[15:0]); //S'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3
		
		end
		
		S_MB_2: begin
		
		Mult1_op1=$signed(outputARAM1[15:0]); //S0'
		Mult1_op2=$signed(outputARAM0[31:16]); //C0
		
		Mult2_op1=$signed(outputARAM1[15:0]); //S0'
		Mult2_op2=$signed(outputARAM0[15:0]); //C1
		
		Mult3_op1=$signed(outputARAM1[15:0]); //S'
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2
		
		Mult4_op1=$signed(outputARAM1[15:0]); //S'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3
		
		end
		
		S_MB_3: begin
		
		Mult1_op1=$signed(outputARAM1[15:0]); //S0'
		Mult1_op2=$signed(outputARAM0[31:16]); //C0
		
		Mult2_op1=$signed(outputARAM1[15:0]); //S0'
		Mult2_op2=$signed(outputARAM0[15:0]); //C1
		
		Mult3_op1=$signed(outputARAM1[15:0]); //S'
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2
		
		Mult4_op1=$signed(outputARAM1[15:0]); //S'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3
		end
		
		S_MB_4: begin
		
		Mult1_op1=$signed(outputARAM1[15:0]); //S0'
		Mult1_op2=$signed(outputARAM0[31:16]); //C0
		
		Mult2_op1=$signed(outputARAM1[15:0]); //S0'
		Mult2_op2=$signed(outputARAM0[15:0]); //C1
		
		Mult3_op1=$signed(outputARAM1[15:0]); //S'
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2
		
		Mult4_op1=$signed(outputARAM1[15:0]); //S'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3
		
		end
		
		S_MB_5: begin
		
		Mult1_op1=$signed(outputARAM1[15:0]); //S0'
		Mult1_op2=$signed(outputARAM0[31:16]); //C0
		
		Mult2_op1=$signed(outputARAM1[15:0]); //S0'
		Mult2_op2=$signed(outputARAM0[15:0]); //C1
		
		Mult3_op1=$signed(outputARAM1[15:0]); //S'
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2
		
		Mult4_op1=$signed(outputARAM1[15:0]); //S'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3
		
		end
		S_MB_6: begin
		
		Mult1_op1=$signed(outputARAM1[15:0]); //S0'
		Mult1_op2=$signed(outputARAM0[31:16]); //C0
		
		Mult2_op1=$signed(outputARAM1[15:0]); //S0'
		Mult2_op2=$signed(outputARAM0[15:0]); //C1
		
		Mult3_op1=$signed(outputARAM1[15:0]); //S'
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2
		
		Mult4_op1=$signed(outputARAM1[15:0]); //S'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3
		
		end
		
		S_MB_7: begin
		
		Mult1_op1=$signed(outputARAM1[15:0]); //S0'
		Mult1_op2=$signed(outputARAM0[31:16]); //C0
		
		Mult2_op1=$signed(outputARAM1[15:0]); //S0'
		Mult2_op2=$signed(outputARAM0[15:0]); //C1
		
		Mult3_op1=$signed(outputARAM1[15:0]); //S'
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2
		
		Mult4_op1=$signed(outputARAM1[15:0]); //S'
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3
		
		end
		
		S_MB_8: begin
		
		// divide by 256
		
		Tone={8'd0,Taccum1[31:8]};
		Ttwo={8'd0,Taccum2[31:8]};
		Tthree={8'd0,Taccum3[31:8]};
		Tfour={8'd0,Taccum4[31:8]};
		
		end
		
		S_LO_CS_0: begin
		
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		
		
		//Clipping to 8 bits
		
		
		if (Saccum1[31]) begin
			Sone=8'd0;
		end else begin
			if (|Saccum1[30:24]) begin
				Sone=8'b11111111;
			end else begin
				Sone=Saccum1[23:16];
			end
		end
		
		
		if (Saccum2[31]) begin
			Stwo=8'd0;
		end else begin
			if (|Saccum2[30:24]) begin
				Stwo=8'b11111111;
			end else begin
				Stwo=Saccum2[23:16];
			end
		end
		
		if (Saccum3[31]) begin
			Sthree=8'd0;
		end else begin
			if (|Saccum3[30:24]) begin
				Sthree=8'b11111111;
			end else begin
				Sthree=Saccum3[23:16];
			end
		end
		
		if (Saccum4[31]) begin
			Sfour=8'd0;
		end else begin
			if (|Saccum4[30:24]) begin
				Sfour=8'b11111111;
			end else begin
				Sfour=Saccum4[23:16];
			end
		end
		end
		S_LO_CS_1: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_LO_CS_2: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_LO_CS_3: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_LO_CS_4: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_LO_CS_5: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_LO_CS_6: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_LO_CS_7: begin
		Mult1_op1=$signed(outputARAM2[23:0]); //T0
		Mult1_op2=$signed(outputARAM0[31:16]); //C0 = CT0
		
		Mult2_op1=$signed(outputARAM2[23:0]); //T0
		Mult2_op2=$signed(outputARAM0[15:0]); //C1 = CT8
		
		Mult3_op1=$signed(outputARAM2[23:0]); //T0
		Mult3_op2=$signed(outputBRAM0[31:16]); //C2=CT16
		
		Mult4_op1=$signed(outputARAM2[23:0]); //T0
		Mult4_op2=$signed(outputBRAM0[15:0]); //C3=CT24
		end
		S_LO_CS_8: begin
			//Clipping to 8 bits
		
		
		if (Saccum1[31]) begin
			Sone=8'd0;
		end else begin
			if (|Saccum1[30:24]) begin
				Sone=8'b11111111;
			end else begin
				Sone=Saccum1[23:16];
			end
		end
		
		
		if (Saccum2[31]) begin
			Stwo=8'd0;
		end else begin
			if (|Saccum2[30:24]) begin
				Stwo=8'b11111111;
			end else begin
				Stwo=Saccum2[23:16];
			end
		end
		
		if (Saccum3[31]) begin
			Sthree=8'd0;
		end else begin
			if (|Saccum3[30:24]) begin
				Sthree=8'b11111111;
			end else begin
				Sthree=Saccum3[23:16];
			end
		end
		
		if (Saccum4[31]) begin
			Sfour=8'd0;
		end else begin
			if (|Saccum4[30:24]) begin
				Sfour=8'b11111111;
			end else begin
				Sfour=Saccum4[23:16];
			end
		end
		
		end
		
	endcase
	
end
	


endmodule
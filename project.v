/*
Christopher Poyser - 400081657
Ryan Shortt - 400068823

Monday, November 26, 2018
*/

`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

module project (
// This is the top module
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_I,           // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[9:0] VGA_RED_O,              // VGA red
		output logic[9:0] VGA_GREEN_O,            // VGA green
		output logic[9:0] VGA_BLUE_O,             // VGA blue
		
		/////// SRAM Interface                    ////////////
		inout wire[15:0] SRAM_DATA_IO,            // SRAM data bus 16 bits
		output logic[17:0] SRAM_ADDRESS_O,        // SRAM address bus 18 bits
		output logic SRAM_UB_N_O,                 // SRAM high-byte data mask 
		output logic SRAM_LB_N_O,                 // SRAM low-byte data mask 
		output logic SRAM_WE_N_O,                 // SRAM write enable
		output logic SRAM_CE_N_O,                 // SRAM chip enable
		output logic SRAM_OE_N_O,                 // SRAM output logic enable
		
		/////// UART                              ////////////
		input logic UART_RX_I,                    // UART receive signal
		output logic UART_TX_O                    // UART transmit signal
);
	
logic resetn;

top_state_type top_state;

// For Push button
logic [3:0] PB_pushed;

// For VGA SRAM interface
logic VGA_enable;
logic [17:0] VGA_base_address;
logic [17:0] VGA_SRAM_address;

// For SRAM
logic [17:0] SRAM_address;
logic [15:0] SRAM_write_data;
logic SRAM_we_n;
logic [15:0] SRAM_read_data;
logic SRAM_ready;

// For UART SRAM interface
logic UART_rx_enable;
logic UART_rx_initialize;
logic [17:0] UART_SRAM_address;
logic [15:0] UART_SRAM_write_data;
logic UART_SRAM_we_n;
logic [25:0] UART_timer;

logic [6:0] value_7_segment [7:0];

// For error detection in UART
logic [3:0] Frame_error;

// For disabling UART transmit
assign UART_TX_O = 1'b1;

assign resetn = ~SWITCH_I[17] && SRAM_ready;

//start for Milestone 1
logic [17:0] M1_SRAM_address;
logic [15:0] M1_SRAM_write_data;
logic [15:0] M1_SRAM_read_data;
logic M1_SRAM_we_n;

logic start;
logic stop;

//milestone 2 

logic [17:0] M2_SRAM_address;
logic [15:0] M2_SRAM_write_data;
logic [15:0] M2_SRAM_read_data;
logic M2_SRAM_we_n;

logic go;
logic done;

// Push Button unit
PB_Controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PB_signal(PUSH_BUTTON_I),	
	.PB_pushed(PB_pushed)
);

// VGA SRAM interface
VGA_SRAM_interface VGA_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.VGA_enable(VGA_enable),
   
	// For accessing SRAM
	.SRAM_base_address(VGA_base_address),
	.SRAM_address(VGA_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
   
	// To VGA pins
	.VGA_CLOCK_O(VGA_CLOCK_O),
	.VGA_HSYNC_O(VGA_HSYNC_O),
	.VGA_VSYNC_O(VGA_VSYNC_O),
	.VGA_BLANK_O(VGA_BLANK_O),
	.VGA_SYNC_O(VGA_SYNC_O),
	.VGA_RED_O(VGA_RED_O),
	.VGA_GREEN_O(VGA_GREEN_O),
	.VGA_BLUE_O(VGA_BLUE_O)
);

// UART SRAM interface
UART_SRAM_interface UART_unit(
	.Clock(CLOCK_50_I),
	.Resetn(resetn), 
   
	.UART_RX_I(UART_RX_I),
	.Initialize(UART_rx_initialize),
	.Enable(UART_rx_enable),
   
	// For accessing SRAM
	.SRAM_address(UART_SRAM_address),
	.SRAM_write_data(UART_SRAM_write_data),
	.SRAM_we_n(UART_SRAM_we_n),
	.Frame_error(Frame_error)
);

// SRAM unit
SRAM_Controller SRAM_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(~SWITCH_I[17]),
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.SRAM_read_data(SRAM_read_data),		
	.SRAM_ready(SRAM_ready),
		
	// To the SRAM pins
	.SRAM_DATA_IO(SRAM_DATA_IO),
	.SRAM_ADDRESS_O(SRAM_ADDRESS_O),
	.SRAM_UB_N_O(SRAM_UB_N_O),
	.SRAM_LB_N_O(SRAM_LB_N_O),
	.SRAM_WE_N_O(SRAM_WE_N_O),
	.SRAM_CE_N_O(SRAM_CE_N_O),
	.SRAM_OE_N_O(SRAM_OE_N_O)
);

//Milestone1 unit

Milestone1 Milestone1_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.Start(start),
	.Stop(stop),

	.SRAM_address(M1_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
	.SRAM_write_data(M1_SRAM_write_data),
	.SRAM_we_n(M1_SRAM_we_n)
   
);
Milestone2 Milestone2_unit(
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.Go(go),
	.Done(done),

	.SRAM_address(M2_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
	.SRAM_write_data(M2_SRAM_write_data),
	.SRAM_we_n(M2_SRAM_we_n)
);

always @(posedge CLOCK_50_I or negedge resetn) begin //top level fsm
	if (~resetn) begin
		top_state <= S_IDLE;
		
		UART_rx_initialize <= 1'b0;
		UART_rx_enable <= 1'b0;
		UART_timer <= 26'd0;
		
		VGA_enable <= 1'b1;
		start<=1'b0;
		go<=1'b0;
		

	end else begin
		UART_rx_initialize <= 1'b0; 
		UART_rx_enable <= 1'b0; 
		
		// Timer for timeout on UART
		// This counter reset itself every time a new data is received on UART
		if (UART_rx_initialize | ~UART_SRAM_we_n) UART_timer <= 26'd0;
		else UART_timer <= UART_timer + 26'd1;

		case (top_state)
		S_IDLE: begin
			VGA_enable <= 1'b1;   
			if (~UART_RX_I | PB_pushed[0]) begin
				// UART detected a signal, or PB0 is pressed
				UART_rx_initialize <= 1'b1;
				
				VGA_enable <= 1'b0;
								
				top_state <= S_ENABLE_UART_RX;
			end
`ifdef SIMULATION
				top_state <= S_ENABLE_UART_RX;
`endif
		end
		S_ENABLE_UART_RX: begin
			// Enable the UART receiver
			UART_rx_enable <= 1'b1;
			top_state <= S_WAIT_UART_RX;
		end
		S_WAIT_UART_RX: begin
`ifdef SIMULATION
			if ((UART_timer == 26'd10)) begin
`else
			if ((UART_timer == 26'd49999999) && (UART_SRAM_address != 18'h00000)) begin
`endif
				// Timeout for 1 sec on UART for detecting if file transmission is finished
				UART_rx_initialize <= 1'b1;
				 				
				//VGA_enable <= 1'b1;
				top_state <= S_MILESTONE2;
			end
		end
		S_MILESTONE2: begin
			go<=1'b1;
			if(done==1'b1) begin
				go<=1'b0;
				top_state<=S_IDLE;
			end else begin
				top_state<=S_MILESTONE2;
			end
		end
		S_MILESTONE1: begin
			start<=1'b1;
			if(stop==1'b1) begin
				start<=1'b0;
				VGA_enable<=1'b1;
				top_state<=S_IDLE;
			end else begin
				top_state<=S_MILESTONE1;
			end
			
		end
		default: top_state <= S_IDLE;
		endcase
	end
end

//muxes

assign VGA_base_address = 18'd146944;

// Give access to SRAM for UART and VGA at appropriate time

always_comb begin
			SRAM_address=18'd0;
			SRAM_write_data=16'd0;
			SRAM_we_n=1'b1;
	if((top_state == S_ENABLE_UART_RX) || (top_state == S_WAIT_UART_RX)) begin
			SRAM_address=UART_SRAM_address;
			SRAM_write_data=UART_SRAM_write_data;
			SRAM_we_n=UART_SRAM_we_n;
	end else begin
		if(top_state==S_MILESTONE2) begin
			SRAM_address=M2_SRAM_address;
			SRAM_write_data=M2_SRAM_write_data;
			SRAM_we_n=M2_SRAM_we_n;
		end else begin
			if(top_state==S_MILESTONE1) begin
				SRAM_address=M1_SRAM_address;
				SRAM_write_data=M1_SRAM_write_data;
				SRAM_we_n=M1_SRAM_we_n;
			end else begin
				SRAM_address=VGA_SRAM_address;
				SRAM_we_n=1'b1;
			end
		end
	end
end
// 7 segment displays
convert_hex_to_seven_segment unit7 (
	.hex_value(SRAM_read_data[15:12]), 
	.converted_value(value_7_segment[7])
);

convert_hex_to_seven_segment unit6 (
	.hex_value(SRAM_read_data[11:8]), 
	.converted_value(value_7_segment[6])
);

convert_hex_to_seven_segment unit5 (
	.hex_value(SRAM_read_data[7:4]), 
	.converted_value(value_7_segment[5])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(SRAM_read_data[3:0]), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit3 (
	.hex_value({2'b00, SRAM_address[17:16]}), 
	.converted_value(value_7_segment[3])
);

convert_hex_to_seven_segment unit2 (
	.hex_value(SRAM_address[15:12]), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(SRAM_address[11:8]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(SRAM_address[7:4]), 
	.converted_value(value_7_segment[0])
);

assign   
   SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
   SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
   SEVEN_SEGMENT_N_O[2] = value_7_segment[2],
   SEVEN_SEGMENT_N_O[3] = value_7_segment[3],
   SEVEN_SEGMENT_N_O[4] = value_7_segment[4],
   SEVEN_SEGMENT_N_O[5] = value_7_segment[5],
   SEVEN_SEGMENT_N_O[6] = value_7_segment[6],
   SEVEN_SEGMENT_N_O[7] = value_7_segment[7];

assign LED_GREEN_O = {resetn, VGA_enable, ~SRAM_we_n, Frame_error, top_state};

endmodule

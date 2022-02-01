`ifndef DEFINE_STATE

// This defines the states
typedef enum logic [2:0] {
	S_IDLE,
	S_ENABLE_UART_RX,
	S_WAIT_UART_RX,
	S_MILESTONE2,
	S_MILESTONE1
} top_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

typedef enum logic [5:0]{
	S_M1IDLE,
	S_LEADIN_0,
	S_LEADIN_1,
	S_LEADIN_2,
	S_LEADIN_3,
	S_LEADIN_4,
	S_LEADIN_5,
	S_LEADIN_6,
	S_LEADIN_7,
	S_LEADIN_8,
	S_LEADIN_9,
	S_LEADIN_10,
	S_LEADIN_11,
	S_LEADIN_12,
	S_CC_0,
	S_CC_1,
	S_CC_2,
	S_CC_3,
	S_CC_4,
	S_CC_5,
	S_LEADOUT_0,
	S_LEADOUT_1,
	S_LEADOUT_2,
	S_LEADOUT_3,
	S_LEADOUT_4,
	S_LEADOUT_5,
	S_FINISH,
	S_LEADOUT_6,
	S_LEADOUT_7

}M1_state_type;

typedef enum logic[7:0]{
	S_M2IDLE,
	S_LI_FETCH_0,
	S_LI_FETCH_1,
	S_LI_FETCH_2,
	S_LI_FETCH_3,
	S_LI_FETCH_4,
	S_LI_TCALC_0,
	S_LI_TCALC_1,
	S_LI_TCALC_2,
	S_LI_TCALC_3,
	S_LI_TCALC_4,
	S_LI_TCALC_5,
	S_LI_TCALC_6,
	S_LI_TCALC_7,
	S_LI_TCALC_8,
	S_LI_TCALC_9,
	S_LI_TCALC_10,
	S_LI_TCALC_11,
	S_MA_0,
	S_MA_1,
	S_MA_2,
	S_MA_3,
	S_MA_4,
	S_MA_5,
	S_MA_6,
	S_MA_7,
	S_MA_8,
	S_MA_9,
	S_MA_10,
	S_MA_11,
	S_MB_0,
	S_MB_1,
	S_MB_2,
	S_MB_3,
	S_MB_4,
	S_MB_5,
	S_MB_6,
	S_MB_7,
	S_MB_8,
	S_MB_9,
	S_MB_10,
	S_MB_11,
	S_LO_CS_0,
	S_LO_CS_1,
	S_LO_CS_2,
	S_LO_CS_3,
	S_LO_CS_4,
	S_LO_CS_5,
	S_LO_CS_6,
	S_LO_CS_7,
	S_LO_CS_8,
	S_LO_CS_9,
	S_LO_CS_10,
	S_LO_CS_11,
	S_LO_WS_0,
	S_LO_WS_1,
	S_LO_WS_2,
	S_LO_WS_3,
	S_LO_WS_4,
	S_LO_WS_5,
	S_DONE
}M2_state_type;

`define DEFINE_STATE 1
`endif

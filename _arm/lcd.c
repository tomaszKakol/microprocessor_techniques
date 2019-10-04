//#include "Board_LED.h"                  // ::Board Support:LED
//#include "LPC17xx.h"                    // Device header
#include "delay.h"
#include <lpc17xx.h>

//*****************************************************************************************************
// Default DATA PORT in OpenLab is PORTB. P0[16:23]
// Default CONTROL PORT in OpenLab is PORTC  P1[16:23]
//*****************************************************************************************************
#define DATA_BUS   								LPC_GPIO0->FIODIR
#define CONTROL_BUS   						LPC_GPIO1->FIODIR
//*****************************************************************************************************

//*****************************************************************************************************
// Control Port definitions
//*****************************************************************************************************
#define CONTROL_SET   						LPC_GPIO1->FIOSET
#define CONTROL_CLEAR   					LPC_GPIO1->FIOCLR
#define RS     		 18	
#define RW     		 17	
#define EN      	 16	
//*****************************************************************************************************

//*****************************************************************************************************
// Data Port definitions
//*****************************************************************************************************
#define DATA_SET      						LPC_GPIO0->FIOSET
#define DATA_CLEAR      					LPC_GPIO0->FIOCLR
#define DATA0      16	
#define DATA1      17	
#define DATA2      18	
#define DATA3      19	
#define DATA4      20	
#define DATA5      21	
#define DATA6      22	
#define DATA7      23	
//*****************************************************************************************************

//*****************************************************************************************************
//Control and Data Mask
//*****************************************************************************************************
#define CONTROL_MASK 	((1<<RS)|(1<<RW)|(1<<EN))
#define DATA_MASK   	((1<<DATA7)|(1<<DATA6)|(1<<DATA5)|(1<<DATA4)|(1<<DATA3)|(1<<DATA2)|(1<<DATA1)|(1<<DATA0))
//*****************************************************************************************************


//**************************************FUNCTION DEFINITION********************************************
// Function definition to process the data to be sent to the appropriate controller pins.
// Hence making it 32 bit compatible.
//*****************************************************************************************************
void SEND_BITWISE(char bite)
{
    DATA_CLEAR =	DATA_MASK;                   // Clear previous data
    DATA_SET|= (((bite >> 0) & 0x01) << DATA0);
    DATA_SET|= (((bite >> 1) & 0x01) << DATA1);
    DATA_SET|= (((bite >> 2) & 0x01) << DATA2);
    DATA_SET|= (((bite >> 3) & 0x01) << DATA3);
    DATA_SET|= (((bite >> 4) & 0x01) << DATA4);
    DATA_SET|= (((bite >> 5) & 0x01) << DATA5);
    DATA_SET|= (((bite >> 6) & 0x01) << DATA6);
    DATA_SET|= (((bite >> 7) & 0x01) << DATA7);
}
//*****************************************************************************************************
//**********************************************END****************************************************


//**************************************FUNCTION DEFINITION********************************************
// Function definition to send lcd commands to specified controller.
//*****************************************************************************************************
void SEND_CMD(unsigned char cmd)
{
	SEND_BITWISE(cmd);		  																	
	CONTROL_CLEAR = (1<<RS)|(1<<RW);
	CONTROL_SET = (1<<EN);  										
	delay_ms(1);
	CONTROL_CLEAR = (1<<EN);
}
//*****************************************************************************************************
//**********************************************END****************************************************


//**************************************FUNCTION DEFINITION********************************************
// Function definition to Initialize the lcd module.
//*****************************************************************************************************
void INIT_LCD()
{
	SEND_CMD(0x38);              //Initialize LCD in 8-bit mode. 2 Lines. 5*7 mode
	SEND_CMD(0x0C);              //Display ON cursor OFF
	SEND_CMD(0x01);              // Clear display
	SEND_CMD(0x06);              //Shift cursor to the right
	SEND_CMD(0x80);              //Force the cursor to the beginning of the line	
}
//*****************************************************************************************************
//**********************************************END****************************************************


//**************************************FUNCTION DEFINITION********************************************
// Function definition to Initialize the ports.
//*****************************************************************************************************
void INIT_PORTS()
{
	DATA_BUS = DATA_MASK;		
	CONTROL_BUS	=	CONTROL_MASK;		
	INIT_LCD();
}
//*****************************************************************************************************
//**********************************************END****************************************************


//**************************************FUNCTION DEFINITION********************************************
// Function definition to send a single character.
//*****************************************************************************************************
void SEND_CHAR_DATA(unsigned char data)
{
	SEND_BITWISE(data);	
	CONTROL_CLEAR =  (1<<RS)|(1<<RW);
	CONTROL_SET = (1<<RS)|(1<<EN); 
	delay_ms(1);
	CONTROL_CLEAR = (1<<EN);
	CONTROL_CLEAR = (1<<RS);	
}
//*****************************************************************************************************
//**********************************************END****************************************************


//**************************************FUNCTION DEFINITION********************************************
// Function definition to send a string.
//*****************************************************************************************************
void SEND_STRING_DATA(char *str)
{
	while(*str!='\0')
	{
		SEND_CHAR_DATA(*str);
		str++;
	}
}
//*****************************************************************************************************
//**********************************************END****************************************************
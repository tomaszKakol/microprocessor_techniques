#include "lcd_lib/Open1768_LCD.h"
#include "lcd_lib/LCD_ILI9325.h"
#include "lcd_lib/asciiLib.h"
#include "Board_LED.h"
#include "LPC17xx.h"                    // Device header

#define N 16


volatile uint32_t msTicks;

void SysTick_Handler(void)  {                               // SysTick interrupt Handler.
  msTicks++;                                                 //  See startup file startup_LPC17xx.s for SysTick vector
}

void wait(int d){
	msTicks = 0;
	while(msTicks <= d);
}

void sleep(int j)
{
	while(j > 0)
		--j;
}


void send_string_uart(char* o){
	int i;
	int counter = 0;
	if(LPC_UART0->LSR & 1){
		LPC_UART0->THR = LPC_UART0->RBR + 1;
		while(*o){
			LPC_UART0->THR = *o;
			o = o+1;
		}
		
		i = 10000000;
		while(i){
			i = i-1;
		}
	}
}

void print_letter_lcd(char* letter, int y_pos, int x_pos){	
int line = 0;
while(1){
	unsigned char pBuffer[N];
	unsigned char mask = 128;
	
	
	int counter = 0;
	if(LPC_UART0->LSR & 1){		
		GetASCIICode(1, pBuffer, LPC_UART0->RBR);
		//lcdWriteReg(ADRX_RAM, x_pos);
		//lcdWriteReg(ADRY_RAM, y_pos);
		
		int i = 0;		
		int j = 0;
		for( i = 0; i < N; ++i){
			for( j = 0; j < 8; ++j){
				if (pBuffer[i] & mask){	
						lcdWriteReg(ADRX_RAM, x_pos - i);
						lcdWriteReg(ADRY_RAM, y_pos + j);
						lcdWriteReg(DATA_RAM, LCDRed);
				}
				mask = mask >> 1;
			}
			mask = 128;
		}
		
		y_pos += 8;
		line +=1;
		
		
		if(y_pos >= LCD_MAX_Y){
			y_pos = 0;
			x_pos -=12;
		}
		
		if(x_pos <= 0){
			const int lcd_size = LCD_MAX_X * LCD_MAX_Y;
			x_pos=LCD_MAX_X;
			y_pos = 0;
			
			while(j < lcd_size){
				lcdWriteReg(DATA_RAM, 0);//LCDWhite
				++j;
			}	
			
		 }
		
	   }
	
	}

}


int main(void)
{
	const int lcd_size = LCD_MAX_X * LCD_MAX_Y;

	int j = 0;
	unsigned char pBuffer[N];
	unsigned char mask = 128;
	
	int y_pos, x_pos;

	
	lcdConfiguration();
	//temp = lcdReadReg(OSCIL_ON);
	init_ILI9325();
	lcdWriteReg(ADRX_RAM, 0);
	lcdWriteReg(ADRY_RAM, 0);
	
	while(j < lcd_size){
		lcdWriteReg(DATA_RAM, 0);//LCDWhite
		++j;
	}
				
	uint32_t display_number = 0;
	
	PIN_Configure(0, 2, 1, 2, 0);
	PIN_Configure(0, 3, 1, 2, 0);
	
	LPC_UART0->LCR = (1 << 7);
	LPC_UART0->DLM = 0;
	LPC_UART0->DLL = 13;
	LPC_UART0->LCR = (3 << 0);
	//LPC_UART0->LCR = (0 << 7);
	
	char tablica[] = "";
	
	print_letter_lcd(tablica, 0, LCD_MAX_X);//while(1)
		
	
	return 0;
	
}


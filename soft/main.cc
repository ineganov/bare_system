//=================ADDRESS DEFINE'S====================//

#define DEFINE_EXTERNAL_DEVICE(NAME, ADDR) volatile int * const NAME = reinterpret_cast<volatile int * const>(ADDR);

DEFINE_EXTERNAL_DEVICE(DEV_JTAG, 0x00000000);
DEFINE_EXTERNAL_DEVICE(DEV_LEDS, 0x00000004);
DEFINE_EXTERNAL_DEVICE(DEV_ADC,	 0x00000008);


//===============FUNCTION DECLARATIONS=================//

extern "C" void delay(int);
extern "C" int mymain();
static int  user_input();
static void leds(int);
static void usleep(int);
static int adc_read(int);

//===============FUNCTION DEFINITIONS==================//

static void usleep(int useconds)
{	delay(useconds*10); 
	return;	}

static int user_input()
{	return *DEV_LEDS; }

static void leds(int l)
{	*DEV_LEDS = l;	}

static int adc_read(int ch)
{   int r = -1;
    *DEV_ADC = ch;
    while (r < 0) r = *DEV_ADC;
    return r;	}

static void do_adc()
{	static unsigned char z = 0xC0;
	
	z >>= 2;
	if(z == 0) z = 0xC0;
	leds(z);
	usleep(10000 + 100*adc_read(2)); 

	return; }

static void do_leds()
{	static unsigned char a = 0x10, left = 1;
	
	if(left)
		{	if(a == 0x80) left = 0;
			else	a <<= 1;	}
	else
		{	if(a == 0x01) left = 1;
			else	a >>= 1;	}
		leds(a);
	usleep(10000 * (1 + (0xF & user_input())));

	return; }
//===================MAIN==============================//
const unsigned char lv[] = {0x81, 0x42, 0x24, 0x18, 0xFF};

int main()
{	for(int i = 0; i < 5; ++i)
	{	leds(lv[i]);
		usleep(300000); }	

	unsigned char sel = 0;
	while(1)
	{	if(1 & (user_input() >> 4)) sel = 1;
		if(1 & (user_input() >> 5)) sel = 0;
		if(sel) do_adc();
		else	do_leds();	}
		
	return 42; }

//=====================================================//

CCOPTS = -Os -G0 -c -nostartfiles -fpack-struct -fstack-usage -Wstack-usage=2000 -std=c++11 -fno-strict-aliasing -fno-exceptions -fno-rtti


all:
	mips-as -mips1 -o startup.o startup.S
	mips-as -mips1 -o functions.o functions.S
	mipsgcc $(CCOPTS) -o main.o main.cc
	mips-ld -o main -T ld.script startup.o functions.o main.o
	mips-objdump -Dz --section=.text main > disas.txt
	mips-objcopy -O binary -j .text main section_text.bin
	mips-objcopy -O binary -j .data main section_data.bin
	./oc_convert section_text.bin program.txt 1024
	./oc_convert section_data.bin data.txt 64
	rm section_text.bin
	rm section_data.bin

clean:	
	rm '*.o'
	rm main
	rm program_objdump.txt
	rm program.txt

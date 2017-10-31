NAME=out
STM_DIR=/usr/local/stm32f0lib
STM_SRC = $(STM_DIR)/Libraries/STM32F0xx_StdPeriph_Driver/src
LINKER_FILE = $(STM_DIR)/Projects/STM32F0xx_StdPeriph_Templates/TrueSTUDIO/STM32F051/STM32F051R8_FLASH.ld

#TOOLS
CC=arm-none-eabi-gcc
AS=arm-none-eabi-as
LD=arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
GDB     = arm-none-eabi-gdb
SIZE = arm-none-eabi-size

#FLAGS
CCFLAGS = -mcpu=cortex-m0 -mthumb -g3 -O0 -Wall
ASFLAGS = -mcpu=cortex-m0 -mthumb -g3 -Wall
LDFLAGS = -specs=nosys.specs

#SOURCES DEFINITION
SOURCES = main.c
SOURCES += stm32f0xx_rcc.c 
SOURCES += stm32f0xx_gpio.c
SOURCES += $(STM_DIR)/Libraries/CMSIS/Device/ST/STM32F0xx/Source/Templates/system_stm32f0xx.c
SOURCES += $(STM_DIR)/Libraries/CMSIS/Device/ST/STM32F0xx/Source/Templates/TrueSTUDIO/startup_stm32f0xx.s
vpath %.c $(STM_DIR)/Libraries/STM32F0xx_StdPeriph_Driver/src

#INCLUDE PATHS
INC = .
INC += $(STM_DIR)/Libraries/CMSIS/Include
INC += $(STM_DIR)/Libraries/CMSIS/Device/ST/STM32F0xx/Include
INC += $(STM_DIR)/Libraries/STM32F0xx_StdPeriph_Driver/inc
INC += $(STM_DIR)/Projects/STM32F0xx_StdPeriph_Templates
INCLUDES = $(addprefix -I,$(INC))

#DEFINES SYMBOLS
DEF = USE_STDPERIPH_DRIVER
DEF += STM32F051
DEFINES = $(addprefix -D,$(DEF))


#COMMANDS
all: $(NAME).bin $(NAME).hex

$(NAME).bin: $(NAME).elf
	$(OBJCOPY) -O binary $^ $@

$(NAME).hex: $(NAME).elf
	$(OBJCOPY) -O ihex $^ $@

$(NAME).elf: $(SOURCES)
	$(CC) $(INCLUDES) $(DEFINES) $(CCFLAGS) $(LDFLAGS) -T$(LINKER_FILE) $^ -o $(NAME).elf
	@echo ""
	$(SIZE) $(NAME).elf
	@echo ""

#$(NAME).elf: $(addsuffix .o, $(SOURCES))
#	$(LD) $(LDFLAGS) $(notdir $^) -o $@

#%.c.o: %.c
#	$(CC) -c $(INCLUDES) $(DEFINES) $(CCFLAGS) $(LDFLAGS) $^ -o $(notdir $@)

#%.s.o: %.s
#	$(AS) $(ASFLAGS) $^ -o $(notdir $@)

.PHONY: openocd	
openocd: $(NAME).elf
	xfce4-terminal --command="openocd -f interface/stlink-v2.cfg -f target/stm32f0x.cfg -c \"init\" -c \"halt\" -c \"reset halt\""

.PHONY: flash	
flash: $(NAME).elf
	openocd -f interface/stlink-v2.cfg -f target/stm32f0x.cfg \
	        -c init -c targets -c "halt" \
	        -c "flash write_image erase $^" \
	        -c "verify_image $^" \
		-c "reset run" -c shutdown

#.PHONY: flash	
#flash: $(NAME).bin
#	st-flash write $^ 0x8000000

.PHONY: clean	
clean: 
	rm -f *.o
	rm -f *.elf 
	rm -f *.map
	rm -f *.lst
	rm -f *.bin
	rm -f *.hex
	rm -f *.d


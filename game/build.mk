SUBDIR 				:= basegame

SPYRO2_BASENAME 	:= SCUS_944.25

BUILD_DIR       	:= $(SUBDIR)/build
TOOLS_DIR       	:= ../tools

# SPYRO2_DIR      	:= spyro2

SPYRO2_ASM_DIR  	:= $(SUBDIR)/asm
SPYRO2_ASM_DIRS    	:= $(SPYRO2_ASM_DIR) $(SPYRO2_ASM_DIR)/data

SPYRO2_C_DIR       	:= $(SUBDIR)/src
SPYRO2_C_DIRS      	:= $(SPYRO2_C_DIR)

SPYRO2_ASSETS_DIR  	:= $(SUBDIR)/assets
SPYRO2_BIN_DIRS    	:= $(SPYRO2_ASSETS_DIR)

SPYRO2_TARGET      	:= $(BUILD_DIR)/$(SPYRO2_BASENAME)

SPYRO2_S_FILES     	:= 	$(foreach dir,$(SPYRO2_ASM_DIRS),$(wildcard $(dir)/*.s))
SPYRO2_C_FILES     	:= 	$(foreach dir,$(SPYRO2_C_DIRS),$(wildcard $(dir)/*.c))
SPYRO2_BIN_FILES   	:= 	$(foreach dir,$(SPYRO2_BIN_DIRS),$(wildcard $(dir)/*.bin))

SPYRO2_O_FILES := 	$(foreach file,$(SPYRO2_S_FILES),$(BUILD_DIR)/$(patsubst $(SUBDIR)/%,%,$(file)).o) \
                 	$(foreach file,$(SPYRO2_C_FILES),$(BUILD_DIR)/$(patsubst $(SUBDIR)/%,%,$(file)).o) \
                 	$(foreach file,$(SPYRO2_BIN_FILES),$(BUILD_DIR)/$(patsubst $(SUBDIR)/%,%,$(file)).o)


MAKE            	:= make
PYTHON          	:= python3
SED             	:= sed
GREP            	:= grep
MODERN_GCC      	:= gcc

CPP             	:= cpp -E

CROSS           	:= mips-linux-gnu-

# CC            	:= $(TOOLS_DIR)/gcc-2.95.2/cc1 -quiet -meb -mcpu=r3000 -mgpopt -mgpOPT -msoft-float -msplit-addresses -mno-abicalls -fno-builtin -fsigned-char
# CC              	:= wine $(TOOLS_DIR)/psyq/psyq4.6/CC1PSX.EXE -quiet

GCC_INCLUDES    	:= -Iinclude
GCC             	:= $(TOOLS_DIR)/gcc-2.95.2/gcc -c -B$(TOOLS_DIR)/gcc-2.95.2/ -pipe $(GCC_INCLUDES)

AS              	:= $(CROSS)as -EL -32 -march=r3000 -mtune=r3000 -msoft-float -no-pad-sections -Iinclude/
LD              	:= $(CROSS)ld -EL
OBJCOPY         	:= $(CROSS)objcopy

SPLAT           	:= $(PYTHON) $(TOOLS_DIR)/splat/split.py

# flags

SDATA_LIMIT     	:= -G8
OPT_FLAGS       	:= -O2

AS_SDATA_LIMIT  	:= -G0

CPP_INCLUDES    	:= -Iinclude
CPP_FLAGS       	:= -undef -Wall -lang-c
CPP_FLAGS       	+= -Dmips -D__GNUC__=2 -D__OPTIMIZE__ -D__mips__ -D__mips -Dpsx -D__psx__ -D__psx -D_PSYQ -D__EXTENSIONS__ -D_MIPSEL -D__CHAR_UNSIGNED__ -D_LANGUAGE_C -DLANGUAGE_C
CPP_FLAGS       	+= $(CPP_INCLUDES)

CC_FLAGS        	:= -mrnames -mel -mgpopt -mgpOPT -msoft-float -msplit-addresses -mno-abicalls -fno-builtin -fsigned-char -gcoff

CHECK_WARNINGS  	:= -Wall -Wextra -Wno-format-security -Wno-unknown-pragmas -Wno-unused-parameter -Wno-unused-variable -Wno-missing-braces -Wno-int-conversion
CC_CHECK        	:= $(MODERN_GCC) -fsyntax-only -fno-builtin -fsigned-char -std=gnu90 -m32 $(CHECK_WARNINGS) $(CPP_FLAGS)

AS_FLAGS        	:= -Wa,-EL,-march=r3000,-mtune=r3000,-msoft-float,-no-pad-sections,-Iinclude


OBJCOPY_FLAGS   	:= -O binary

SPYRO2_LD_FLAGS    	:= -Map $(SPYRO2_TARGET).map -T $(SUBDIR)/$(SPYRO2_BASENAME).ld \
                   	-T $(SUBDIR)/undefined_syms_auto.$(SPYRO2_BASENAME).txt -T $(SUBDIR)/undefined_funcs_auto.$(SPYRO2_BASENAME).txt -T $(SUBDIR)/undefined_syms.$(SPYRO2_BASENAME).txt \
                   	--no-check-sections $(LD_FLAGS_EXTRA)

# recipes

default: all

all: dirs verify

dirs:
	$(foreach dir,$(SPYRO2_ASM_DIRS) $(SPYRO2_BIN_DIRS) $(SPYRO2_C_DIRS),$(shell mkdir -p $(BUILD_DIR)/$(subst $(SUBDIR)/,,$(dir))))

check: $(SPYRO2_BASENAME).ok
verify: $(SPYRO2_TARGET).ok

split: $(SUBDIR)/$(SPYRO2_BASENAME).yaml
	$(SPLAT) $<
	touch $(SUBDIR)/$@.timestamp

clean:
	rm -rf $(BUILD_DIR) $(SPYRO2_ASM_DIR) $(SPYRO2_ASSETS_DIR)
	rm -rf $(SUBDIR)/*.timestamp $(SUBDIR)/$(SPYRO2_BASENAME).ld $(SUBDIR)/*_auto.$(SPYRO2_BASENAME).txt

$(SPYRO2_TARGET): $(SPYRO2_TARGET).elf
	$(OBJCOPY) $(OBJCOPY_FLAGS) $< $@

$(SPYRO2_TARGET).elf: $(SPYRO2_O_FILES)
	@echo "HELLO"
	@echo $@
	$(LD) $(SPYRO2_LD_FLAGS) -L $(SUBDIR) -o $@

$(BUILD_DIR)/%.s.o: $(SUBDIR)/%.s
	$(AS) -G0 -o $@ $<

$(BUILD_DIR)/%.bin.o: $(SUBDIR)/%.bin
	$(LD) -r -b binary -o $@ $<

$(BUILD_DIR)/%.c.o: $(SUBDIR)/%.c
	$(GCC) $(CC_FLAGS) $(SDATA_LIMIT) $(OPT_FLAGS) $(AS_FLAGS),$(AS_SDATA_LIMIT) $< -o $@

# $(BUILD_DIR)/%.c.o: %.c
# 	@$(CC_CHECK) $<
# 	$(CPP) $(CPP_FLAGS) $(CPP_TARGET) $< | $(CC) $(CC_FLAGS) $(OPT_FLAGS) -o $@.s_
# 	$(PYTHON) tools/maspsx/maspsx.py $@.s_ > $@.s
# 	$(AS) $(AS_FLAGS) $@.s -o $@

%.ok: $(SPYRO2_TARGET)
	@echo SHA1
	@echo $<
	@echo "$$(cat $(SUBDIR)/$(notdir $<).sha1)  $<"
	@echo "$$(cat $(SUBDIR)/$(notdir $<).sha1)  $<" | sha1sum --check
	@touch $@

$(BUILD_DIR)/%.a: %.a
	@mkdir -p $$(dirname $@)
	@cp $< $@

# keep .obj files
.SECONDARY:

.PHONY: all clean default
SHELL = /bin/bash -e -o pipefail
# Target
TARGET	   ?= cue2psfcd

# Source Files
SRC_DIR    = .

CFLAGS	    = -O2 -fPIC -std=c++17 
CFLAGS     += -Wno-format

INCLUDE_PATH += $(SRC_DIR)
CFLAGS       += $(patsubst %,-I%,$(INCLUDE_PATH))

LDFLAGS     = 
LIBS        = 

###############################################################################
# Variables
###############################################################################
OBJ_DIR      ?= obj/

###############################################################################
# Variables: Lists of objects, source and deps
###############################################################################
# SRC / Object list
src2obj       = $(OBJ_DIR)$(patsubst %$(suffix $(1)),%.o,$(notdir $(1)))

SRC          ?= $(foreach src,$(SRC_DIR),$(wildcard $(src)/*.cpp))
OBJ          ?= $(foreach src,$(SRC),$(call src2obj,$(src)))
LIB_OBJ      ?= $(foreach src,$(filter-out main.cpp,$(SRC)),$(call src2obj,$(src)))

###############################################################################
# Rules: Compilation macro
###############################################################################
define template_cpp
$(call src2obj,$(1)): $(1) | $(OBJ_DIR)
	@echo "# Compiling $(notdir $(1))"
	@g++-9 $(CFLAGS) -c $$< -o $$@
endef

###############################################################################
# Rules
###############################################################################
all: $(TARGET) 
	
$(OBJ_DIR):
	@mkdir -p $@

$(foreach src,$(SRC),$(eval $(call template_cpp,$(src))))	

$(TARGET): $(OBJ) makefile
	@echo "# Linking $(notdir $@)"
	@g++-9 $(LDFLAGS) $(OBJ) $(LIBS) -o $@

clean:
	-rm -rf $(OBJ_DIR) $(TARGET)


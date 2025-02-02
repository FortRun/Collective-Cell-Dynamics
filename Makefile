# Disable all of make's built-in rules (similar to Fortran's implicit none)
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

# Fortran Compiler
FC := gfortran

# The following must have non-empty value if OpenMP is required
OMP :=

# The following must have non-empty value if Debugging compiler options are required
DEBUG :=

# Dependency Generator
DEPGEN := fortdepend
DEPGEN_INSTALL_DOCS := [https://github.com/ZedThree/fort_depend.py]

# Compiler Flags
ifeq ($(FC), gfortran)
  ifdef DEBUG
    FF += -march=native -O0 -fautomatic -static-libgfortran
    FF += -Wall -Warray-temporaries -Wextra -pedantic 
    FF += -g -fbacktrace -fcheck=all -ffpe-trap=invalid,zero,overflow -finit-real=snan
  else
    FF += -march=native -O3 -static-libgfortran -funroll-loops -fautomatic -w
  endif
  ifdef OMP
    FF += -fopenmp
  endif
else ifeq ($(FC), ifort)
  ifdef DEBUG
    FF += -march=native -static -O0 -auto -fp-stack-check -fpe0  -g -traceback -warn -check all
  else
    FF += -march=native -O3 -fast -auto -w
  endif
  ifdef OMP
    FF += -qopenmp
  endif
else ifeq ($(FC), ifx)
  ifdef DEBUG
    FF += -march=native -static -O0 -auto -fpe0 -g -traceback -warn
  else
    FF += -march=native -O3 -static -fp-model fast -auto -w
  endif
  ifdef OMP
    FF += -qopenmp
  endif
endif

# Linker and linker Flags
LD := $(FC)
ifeq ($(LD), gfortran)
  LF += -fopenmp
else ifneq (, $(filter $(LD), ifort ifx))
  LF += -qopenmp
endif

# Package name
PACKAGE := ccd

# List of all source files
SRC_DIR := src
CUSTOM_SRC_DIR := custom/src
SRCS := $(wildcard $(SRC_DIR)/*.f90 $(CUSTOM_SRC_DIR)/*.f90)

# List of all object files
BUILD_DIR := build
OBJS := $(addprefix $(BUILD_DIR)/, $(addsuffix .o, $(basename $(notdir $(SRCS)))))

# Include path (to be searched by compiler for *.mod files)
IP := $(BUILD_DIR)
ifeq ($(FC), gfortran)
  FF += -J $(IP)
else ifneq (, $(filter $(FC), ifort ifx))
  FF += -module $(IP)
endif 

# Target executable(s)
EXECS := $(basename $(filter $(BUILD_DIR)/$(PACKAGE)_%, $(OBJS)))

# List of all executable scripts
SCRIPT_DIR := scripts
CUSTOM_SCRIPT_DIR := custom/scripts
SCRIPTS := $(wildcard $(SCRIPT_DIR)/$(PACKAGE)_* $(CUSTOM_SCRIPT_DIR)/$(PACKAGE)_*)

# Path to the DRIVER script that represents the entire package
DRIVER_TEMPLATE := $(SCRIPT_DIR)/driver.template
DRIVER := $(SCRIPT_DIR)/$(PACKAGE)

# Bash Completion script
SUBCMDS := $(filter-out %_ %.sh %.py, $(patsubst $(PACKAGE)_%, %, $(notdir $(EXECS) $(SCRIPTS))))
BASHCOMP := $(PACKAGE)_completion.sh
BASHCOMP_TEMPLATE := $(SCRIPT_DIR)/completion.template

# Helpdoc related (https://github.com/somajitdey/helpdoc)
HELPDOC_CMDS := $(addprefix $(PACKAGE)_, $(SUBCMDS))
HELPDOC_SRCS := $(SRCS) $(filter-out %_ %.sh, $(SCRIPTS))

# Dependency file to be generated using `fortdepend`
DEPFILE := .dependencies

# Intrinsic modules in standard Fortran for `fortdepend` to ignore
IMODS := omp_lib omp_lib_kinds iso_fortran_env ieee_arithmetic ieee_exceptions ieee_features iso_c_binding

# Font colors to be used by `echo`
RED='\e[1;31m'
GREEN='\e[1;32m'
BLUE='\e[1;34m'
NOCOLOR='\e[0m'

# Where to seek prerequisites
VPATH := $(SRC_DIR) $(CUSTOM_SRC_DIR)

# System path where executables would be installed
# The following must be a system path that exists. `Main` basically means the `Driver`.
INSTALL_PATH_MAIN := /usr/local/bin
# The following must be a custom directory that doesn't exist by default such that it's existence implies previous installation
INSTALL_PATH_INTERNALS := $(INSTALL_PATH_MAIN)/$(PACKAGE)_
# BASHCOMP_INSTALL_PATH := /etc/bash_completion.d # Legacy standard
BASHCOMP_INSTALL_PATH := /usr/share/bash-completion/completions

# Shell which runs the recipes
SHELL := bash

.PHONY: all clean rebuild install uninstall $(DEPGEN)

all: $(EXECS) $(BASHCOMP) $(DRIVER)
	@echo -e \\n$(GREEN)"make: Success"$(NOCOLOR)

$(EXECS): % : %.o $(filter-out $(BUILD_DIR)/$(PACKAGE)_%.o, $(OBJS))
	$(LD) $(LF) -o $@ $^
	@echo -e $(BLUE)"make: Built $@"$(NOCOLOR)

$(OBJS): $(BUILD_DIR)/%.o : %.f90
	$(FC) -c $(FF) -o $@ $<

# Rebuild all object files when this Makefile or dependency changes
# Create build directory only if non-existent (implemented as "order-only prerequisite")
$(OBJS): $(MAKEFILE_LIST) $(DEPFILE) | $(BUILD_DIR)

$(BUILD_DIR):
	mkdir $@

# Generate fresh dependency file whenever the codebase (sources) is modified or this Makefile changes
$(DEPFILE): $(SRCS) $(MAKEFILE_LIST) | $(DEPGEN)
	@echo -e $(BLUE)"make: Generating dependencies:"$(NOCOLOR)
	$(DEPGEN) --files $(SRCS) --build $(BUILD_DIR) --ignore-modules $(IMODS) --output $(DEPFILE) --overwrite

# Define dependencies between object files
# Note: In fortran, object files are interdependent through .mod files
# Note: .mod file is generated only when module code is compiled into object file

include $(DEPFILE)

$(DEPGEN):
	@which $@ > /dev/null || { echo -e $(RED)"make: Please install $@ first. $(DEPGEN_INSTALL_DOCS)"$(NOCOLOR) && false;}

$(BASHCOMP): $(EXECS) $(SCRIPTS)
	@echo -e $(BLUE)"make: Creating Bash completion script: $(BASHCOMP)"$(NOCOLOR)
	sed -n -e 's/__package__/$(PACKAGE)/g' $(BASHCOMP_TEMPLATE) -e 's/__subcmds__/$(SUBCMDS)/g;p' > $(BASHCOMP)

$(DRIVER): $(EXECS) $(SCRIPTS)
	@echo -e $(BLUE)"make: Creating driver script with version info: $(DRIVER)"$(NOCOLOR)
	@cat $(DRIVER_TEMPLATE) <(echo "echo '$(PACKAGE) Build Version: $$(sha1sum $(EXECS) $(SCRIPTS) | awk NF=1 | sha1sum | awk NF=1)'") \
		> $(DRIVER)
	chmod +x $(DRIVER)

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(DEPFILE) $(BASHCOMP) $(DRIVER)

rebuild: clean all

install:
	@sudo mkdir $(INSTALL_PATH_INTERNALS) || { echo -e $(RED)"make: Uninstall earlier installation first"$(NOCOLOR) && false;}
	sudo install -t $(INSTALL_PATH_INTERNALS) $(EXECS) $(SCRIPTS)
	sudo install -T $(DRIVER) $(INSTALL_PATH_MAIN)/$(PACKAGE)
	sudo install -T $(BASHCOMP) $(BASHCOMP_INSTALL_PATH)/$(PACKAGE)
	echo $(HELPDOC_SRCS) | xargs -n1 -r sudo helpdoc -e || true
	@echo -e \\n$(GREEN)"make install: Success"$(NOCOLOR)

uninstall:
	sudo rm $(INSTALL_PATH_MAIN)/$(PACKAGE)
	sudo rm -rf $(INSTALL_PATH_INTERNALS)
	sudo rm $(BASHCOMP_INSTALL_PATH)/$(PACKAGE)
	echo $(HELPDOC_CMDS) | xargs -n1 -r sudo helpdoc -d || true
	@echo -e \\n$(GREEN)"make uninstall: Success"$(NOCOLOR)

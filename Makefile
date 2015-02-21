BUILDDIR := build
PRODUCT := deqn

SRCDIR := src

HDRS := $(wildcard $(SRCDIR)/*.h)

CSRCS := $(wildcard $(SRCDIR)/*.C)
FSRCS += $(wildcard $(SRCDIR)/fortran/*.f90)
CUSRCS += $(wildcard $(SRCDIR)/*.cu)

OBJS := $(CSRCS:$(SRCDIR)/%.C=$(BUILDDIR)/%.o)
OBJS += $(FSRCS:$(SRCDIR)/fortran/%.f90=$(BUILDDIR)/%.o)
OBJS += $(CUSRCS:$(SRCDIR)/%.cu=$(BUILDDIR)/%.o)

BINARY := $(BUILDDIR)/$(PRODUCT)

CUDA_DIR := /local/java/cuda

# gcc flags:
CXX := g++
CXXFLAGS_DEBUG := -g -DDEBUG
CXXFLAGS_OPT := -O0
CXXFLAGS_OPENMP := -fopenmp

FC := gfortran
FFLAGS := -ffree-form

NVCC := nvcc
NVFLAGS := -g -G -O0

LD := $(CXX)

# select optimized or debug
#CXXFLAGS := $(CXXFLAGS_OPT) $(CPPFLAGS)
CXXFLAGS := $(CXXFLAGS_OPT) $(CXXFLAGS_DEBUG) $(CPPFLAGS) -I$(CUDA_DIR)/include

# add openmp flags (comment out for serial build)
#CXXFLAGS += $(CXXFLAGS_OPENMP)
#LDFLAGS += $(CXXFLAGS_OPENMP)

LDFLAGS +=-L$(CUDA_DIR)/lib64 -lcudart

all : $(BINARY)

$(BINARY) : $(OBJS)
	@echo linking $@
	$(maketargetdir)
	$(LD) $(LDFLAGS) -o $@ $^

$(BUILDDIR)/%.o : $(SRCDIR)/%.C
	@echo compiling $<
	$(maketargetdir)
	$(CXX) $(CXXFLAGS) $(CXXINCLUDES) -c -o $@ $<

$(BUILDDIR)/%.o : $(SRCDIR)/fortran/%.f90
	@echo compiling $<
	$(maketargetdir)
	$(FC) $(FFLAGS) -c -o $@ $<

$(BUILDDIR)/%.o : $(SRCDIR)/%.cu
	@echo compiling $<
	$(maketargetdir)
	$(NVCC) $(NVFLAGS) -c -o $@ $<

define maketargetdir
	-@mkdir -p $(dir $@) > /dev/null 2>&1
endef

clean :
	rm -f $(BINARY) $(OBJS)
	rm -rf $(BUILDDIR)

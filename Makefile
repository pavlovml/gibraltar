# ==============================================================================
# config

.PHONY: all build download link test deps

all: build link

export CPU_ONLY     ?= 0
export USE_CUDNN    ?= 1
export TEST_GPU     ?= 0

export CUDA_DIR     ?= /usr/local/cuda
export CUDA_ARCH    ?= -gencode arch=compute_30,code=sm_30

BUILD_FLAGS         ?= -j8
COMMIT              ?= master
GITHUB_REPO         ?= BVLC/caffe

GIT_REMOTE          ?= https://github.com/$(GITHUB_REPO).git
VERSION_DIR         ?= versions/$(GITHUB_REPO)/$(COMMIT)

BREW_DEPS           ?= openblas glog gflags hdf5 lmdb leveldb szip snappy python numpy opencv
BREW_INSTALL_ARGS   ?= --fresh -vd

UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
CONFIG ?= config/OS\ X.make
endif
ifeq ($(UNAME), Linux)
CONFIG ?= config/Linux.make
endif

# ==============================================================================
# phony targets

build: $(VERSION_DIR)/distribute

download: $(VERSION_DIR)

link:
	@- rm -f bin lib include python
	@ ln -s $(VERSION_DIR)/distribute/lib lib
	@ ln -s $(VERSION_DIR)/distribute/bin bin
	@ ln -s $(VERSION_DIR)/distribute/include include
	@ ln -s $(VERSION_DIR)/distribute/python python
	@ ln -fs $(CUDA_DIR)/lib/libcudart.dylib lib/libcudart.dylib
	@- echo 'Using caffe at $(VERSION_DIR)'

test: build
	cd $(VERSION_DIR) && $(MAKE) test $(BUILD_FLAGS)
	cd $(VERSION_DIR) && $(MAKE) runtest
	cd $(VERSION_DIR) && $(MAKE) pytest

# OS X only, for now
deps:
ifeq ($(UNAME), Darwin)
	@- echo 'P.S. - Remember to run `brew update`.'
	brew tap homebrew/science
	brew install                                   $(BREW_ARGS) $(BREW_DEPS)
	brew install --build-from-source --with-python $(BREW_ARGS) protobuf
	brew install --build-from-source               $(BREW_ARGS) boost boost-python
	brew cask install cuda
else
	@- echo 'Only for OS X, for now.'
endif

# ==============================================================================
# file targets

$(VERSION_DIR):
	git clone $(GIT_REMOTE) $(VERSION_DIR)
	cd $(VERSION_DIR) && git checkout $(COMMIT)

$(VERSION_DIR)/Makefile.config: | $(VERSION_DIR)
	cp $(CONFIG) $(VERSION_DIR)/Makefile.config

$(VERSION_DIR)/distribute: $(VERSION_DIR)/Makefile.config
	cd $(VERSION_DIR) && $(MAKE) all $(BUILD_FLAGS)
	cd $(VERSION_DIR) && $(MAKE) pycaffe
	cd $(VERSION_DIR) && $(MAKE) distribute
	for f in $(VERSION_DIR)/distribute/bin/*.bin; do mv $$f $${f%.*}; done

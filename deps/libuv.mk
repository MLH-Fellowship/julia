## LIBUV ##
ifneq ($(USE_BINARYBUILDER_LIBUV),1)
LIBUV_GIT_URL:=https://github.com/JuliaLang/libuv.git
LIBUV_TAR_URL=https://api.github.com/repos/JuliaLang/libuv/tarball/$1
$(eval $(call git-external,libuv,LIBUV,configure,,$(SRCCACHE)))

UV_CFLAGS := -O2 -DBUILDING_UV_SHARED=1

UV_FLAGS := LDFLAGS="$(LDFLAGS) $(CLDFLAGS) -v"
UV_FLAGS += CFLAGS="$(CFLAGS) $(UV_CFLAGS) $(SANITIZE_OPTS)"

ifneq ($(VERBOSE), 0)
UV_MFLAGS += V=1
endif

LIBUV_BUILDDIR := $(BUILDDIR)/$(LIBUV_SRC_DIR)

ifneq ($(CLDFLAGS)$(SANITIZE_LDFLAGS),)
$(LIBUV_BUILDDIR)/build-configured: LDFLAGS:=$(LDFLAGS) $(CLDFLAGS) $(SANITIZE_LDFLAGS)
endif

ifeq ($(OS), emscripten)
$(LIBUV_BUILDDIR)/build-configured: $(SRCCACHE)/$(LIBUV_SRC_DIR)/source-extracted
	mkdir -p $(dir $@)
	cd $(dir $@) && cmake -E env \
		CMAKE_C_FLAGS="-pthread" \
		CMAKE_SHARED_LINKER_FLAGS="-sTOTAL_MEMORY=65536000 -pthread" \
		CMAKE_EXE_LINKER_FLAGS="-sTOTAL_MEMORY=65536000 -pthread" \
		emcmake cmake $(dir $<) $(CMAKE_COMMON) -DBUILD_TESTING=OFF
	echo 1 > $@

$(LIBUV_BUILDDIR)/build-compiled: $(LIBUV_BUILDDIR)/build-configured
	emmake $(MAKE) -C $(dir $<) $(UV_MFLAGS)
	echo 1 > $@
else
$(LIBUV_BUILDDIR)/build-configured: $(SRCCACHE)/$(LIBUV_SRC_DIR)/source-extracted
	touch -c $(SRCCACHE)/$(LIBUV_SRC_DIR)/aclocal.m4 # touch a few files to prevent autogen from getting called
	touch -c $(SRCCACHE)/$(LIBUV_SRC_DIR)/Makefile.in
	touch -c $(SRCCACHE)/$(LIBUV_SRC_DIR)/configure
	mkdir -p $(dir $@)
	cd $(dir $@) && \
	$(dir $<)/configure --with-pic $(CONFIGURE_COMMON) $(UV_FLAGS)
	echo 1 > $@

$(LIBUV_BUILDDIR)/build-compiled: $(LIBUV_BUILDDIR)/build-configured
	$(MAKE) -C $(dir $<) $(UV_MFLAGS)
	echo 1 > $@
endif

$(LIBUV_BUILDDIR)/build-checked: $(LIBUV_BUILDDIR)/build-compiled
ifeq ($(OS),$(BUILD_OS))
	$(MAKE) -C $(dir $@) check
endif
	echo 1 > $@

$(eval $(call staged-install, \
	libuv,$$(LIBUV_SRC_DIR), \
	MAKE_INSTALL,,, \
	$$(INSTALL_NAME_CMD)libuv.$$(SHLIB_EXT) $$(build_shlibdir)/libuv.$$(SHLIB_EXT)))

clean-libuv:
	rm -rf $(LIBUV_BUILDDIR)/build-configured $(LIBUV_BUILDDIR)/build-compiled
	-$(MAKE) -C $(LIBUV_BUILDDIR) clean


get-libuv: $(LIBUV_SRC_FILE)
extract-libuv: $(SRCCACHE)/$(LIBUV_SRC_DIR)/source-extracted
configure-libuv: $(LIBUV_BUILDDIR)/build-configured
compile-libuv: $(LIBUV_BUILDDIR)/build-compiled
fastcheck-libuv: #none
check-libuv: $(LIBUV_BUILDDIR)/build-checked

else # USE_BINARYBUILDER_LIBUV

$(eval $(call bb-install,libuv,LIBUV,false))

endif

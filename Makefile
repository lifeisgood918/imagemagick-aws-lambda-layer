LIBPNG_VERSION=1.6.39
LIBJPG_VERSION=9e
OPENJP2_VERSION=2.5.0
LIBTIFF_VERSION= 4.5.0
BZIP2_VERSION=1.0.6
LIBWEBP_VERSION=1.3.0
IMAGEMAGICK_VERSION=7.1.1-18
LIBHEIF_VERSION=1.15.2
LIBDE265_VERSION=1.0.12
LCMS_VERSION=2.15

TARGET_DIR ?= /opt/
PROJECT_ROOT = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CACHE_DIR=$(PROJECT_ROOT)build/cache

.ONESHELL:

CONFIGURE = PKG_CONFIG_PATH=$(CACHE_DIR)/lib/pkgconfig \
	./configure \
		CPPFLAGS=-I$(CACHE_DIR)/include \
		LDFLAGS=-L$(CACHE_DIR)/lib \
		--disable-dependency-tracking \
		--disable-shared \
		--enable-static \
		--prefix=$(CACHE_DIR)

## libde265
LIBDE265_SOURCE=libde265-$(LIBDE265_VERSION).tar.gz

$(LIBDE265_SOURCE):
	curl -LO https://github.com/strukturag/libde265/releases/download/v$(LIBDE265_VERSION)/$(LIBDE265_SOURCE)
	
$(CACHE_DIR)/lib/libde265.a: $(LIBDE265_SOURCE)
	tar xf $<
	cd libde265*
	./autogen.sh
	$(CONFIGURE)
	make
	make install

## libheic
LIBHEIF_SOURCE=libheif-$(LIBHEIF_VERSION).tar.gz

$(LIBHEIF_SOURCE):
	curl -LO https://github.com/strukturag/libheif/releases/download/v$(LIBHEIF_VERSION)/$(LIBHEIF_SOURCE)

$(CACHE_DIR)/lib/libheif.a: $(LIBHEIF_SOURCE)
	tar xf $<
	cd libheif*
	./autogen.sh
	$(CONFIGURE)
	make
	make install

## libjpg

LIBJPG_SOURCE=jpegsrc.v$(LIBJPG_VERSION).tar.gz

$(LIBJPG_SOURCE):
	curl -LO http://ijg.org/files/$(LIBJPG_SOURCE)

$(CACHE_DIR)/lib/libjpeg.a: $(LIBJPG_SOURCE)
	tar xf $<
	cd jpeg*
	$(CONFIGURE)	 
	make
	make install


## libpng

LIBPNG_SOURCE=libpng-$(LIBPNG_VERSION).tar.xz

$(LIBPNG_SOURCE):
	curl -LO http://prdownloads.sourceforge.net/libpng/$(LIBPNG_SOURCE)

$(CACHE_DIR)/lib/libpng.a: $(LIBPNG_SOURCE)
	tar xf $<
	cd libpng*
	$(CONFIGURE)	 
	make
	make install

# libbz2

BZIP2_SOURCE=bzip2-$(BZIP2_VERSION).tar.gz

$(BZIP2_SOURCE):
	curl -LO http://prdownloads.sourceforge.net/bzip2/bzip2-$(BZIP2_VERSION).tar.gz

$(CACHE_DIR)/lib/libbz2.a: $(BZIP2_SOURCE)
	tar xf $<
	cd bzip2-*
	make libbz2.a
	make install PREFIX=$(CACHE_DIR)

# libtiff

LIBTIFF_SOURCE=tiff-$(LIBTIFF_VERSION).tar.gz

$(LIBTIFF_SOURCE):
	curl -LO http://download.osgeo.org/libtiff/$(LIBTIFF_SOURCE)

$(CACHE_DIR)/lib/libtiff.a: $(LIBTIFF_SOURCE) $(CACHE_DIR)/lib/libjpeg.a
	tar xf $<
	cd tiff-*
	$(CONFIGURE)	 
	make
	make install

# libwebp

LIBWEBP_SOURCE=libwebp-$(LIBWEBP_VERSION).tar.gz

$(LIBWEBP_SOURCE):
	curl -L https://github.com/webmproject/libwebp/archive/v$(LIBWEBP_VERSION).tar.gz -o $(LIBWEBP_SOURCE)
	
$(CACHE_DIR)/lib/libwebp.a: $(LIBWEBP_SOURCE)
	tar xf $<
	cd libwebp-*
	sh autogen.sh
	$(CONFIGURE)	 
	make
	make install

LCMS_SOURCE=lcms2-$(LCMS_VERSION).tar.gz

$(LCMS_SOURCE):
	curl -L https://github.com/mm2/Little-CMS/releases/download/lcms$(LCMS_VERSION)/lcms2-$(LCMS_VERSION).tar.gz -o $(LCMS_SOURCE)
	
$(CACHE_DIR)/lib/liblcms2.a: $(LCMS_SOURCE)
	tar xf $<
	cd lcms2-*
	sh autogen.sh
	$(CONFIGURE)	 
	make
	make install


## libopenjp2

OPENJP2_SOURCE=openjp2-$(OPENJP2_VERSION).tar.gz

$(OPENJP2_SOURCE):
	curl -L https://github.com/uclouvain/openjpeg/archive/v$(OPENJP2_VERSION).tar.gz -o $(OPENJP2_SOURCE)


$(CACHE_DIR)/lib/libopenjp2.a: $(OPENJP2_SOURCE) $(CACHE_DIR)/lib/libpng.a $(CACHE_DIR)/lib/libtiff.a
	tar xf $<
	cd openjpeg-*
	mkdir -p build
	cd build 
	PKG_CONFIG_PATH=$(CACHE_DIR)/lib/pkgconfig cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=$(CACHE_DIR) \
		-DBUILD_SHARED_LIBS:bool=off \
		-DBUILD_CODEC:bool=off
	make clean
	make install


## ImageMagick

IMAGE_MAGICK_SOURCE=ImageMagick-$(IMAGEMAGICK_VERSION).tar.gz

$(IMAGE_MAGICK_SOURCE):
	curl -L https://github.com/ImageMagick/ImageMagick/archive/$(IMAGEMAGICK_VERSION).tar.gz -o $(IMAGE_MAGICK_SOURCE)


LIBS:=$(CACHE_DIR)/lib/libjpeg.a \
	$(CACHE_DIR)/lib/libpng.a \
	$(CACHE_DIR)/lib/libopenjp2.a \
	$(CACHE_DIR)/lib/libtiff.a \
	$(CACHE_DIR)/lib/libbz2.a \
	$(CACHE_DIR)/lib/libwebp.a \
	$(CACHE_DIR)/lib/libde265.a \
	$(CACHE_DIR)/lib/libheif.a \
	$(CACHE_DIR)/lib/liblcms2.a

$(TARGET_DIR)/bin/identify: $(IMAGE_MAGICK_SOURCE) $(LIBS)
	tar xf $<
	cd ImageMa*
	PKG_CONFIG_PATH=$(CACHE_DIR)/lib/pkgconfig \
		./configure \
		CPPFLAGS=-I$(CACHE_DIR)/include \
		LDFLAGS="-L$(CACHE_DIR)/lib -lstdc++" \
		--disable-dependency-tracking \
		--disable-shared \
		--enable-static \
		--with-heic=yes \
		--with-lcms=yes \
		--prefix=$(TARGET_DIR) \
		--enable-delegate-build \
		--without-modules \
		--disable-docs \
		--without-magick-plus-plus \
		--without-perl \
		--without-x \
		--disable-openmp
	make clean
	make all
	make install

libs: $(LIBS)

all: $(TARGET_DIR)/bin/identify

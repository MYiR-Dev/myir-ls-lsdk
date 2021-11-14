#
# Copyright 2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# NXP eIQ™ Machine Learning Software Development Environment
#

eIQ_REPO_LIST = opencv armcl boost protobuf flatbuffer caffe onnx onnxruntime armnn \
		tensorflow tflite pytorch

eIQDIR = $(PACKAGES_PATH)/apps/eiq
eIQDESTDIR = $(DESTDIR)_eIQ

eiq: dependency $(eIQ_REPO_LIST) tensorflow-protobuf eiq_pack

CAFFE_DEPENDENT_PKG = libgflags-dev libgoogle-glog-dev liblmdb-dev libopenblas-dev \
		      libatlas-base-dev libleveldb-dev libsnappy-dev libopencv-dev \
		      libhdf5-serial-dev libboost-all-dev

TENSORFLOW_DEP_APT_PKG = python3-wheel python3-h5py
TENSORFLOW_DEP_PIP_PKG = enum34 mock keras_applications==1.0.8 keras_preprocessing==1.1.0
TARGET_DEPENDENT_PKG = libhdf5-serial-dev python3-wheel python3-h5py scons libgtk2.0-dev pkg-config  \
		       libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libavresample-dev \
		       python3-pip


.PHONY: opencv
opencv: dependency
ifeq ($(CONFIG_EIQ_OPENCV), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"OpenCV") && \
	 $(call fetch-git-tree,opencv,apps/eiq) && $(call fetch-git-tree,armcl,apps/eiq) && \
	 mkdir -p $(eIQDIR)/opencv/build && cd $(eIQDIR)/opencv/build && \
	 mkdir -p $(eIQDESTDIR)/usr/local/OpenCV && export DESTDIR=$(eIQDESTDIR) && \
	 CXX=$(CROSS_COMPILE)g++ CC=$(CROSS_COMPILE)gcc \
	 export PKG_CONFIG_FOUND=TRUE && \
	 export PKG_CONFIG_LIBDIR=$(RFSDIR)/usr/lib/aarch64-linux-gnu/pkgconfig && \
	 export PKG_CONFIG_PATH=$(RFSDIR)/usr/share/pkgconfig && \
	 export PKG_CONFIG_EXECUTABLE=$(RFSDIR)/usr/bin/pkg-config && \
	 cmake .. -DCMAKE_TOOLCHAIN_FILE=$(eIQDIR)/opencv/platforms/linux/aarch64-gnu.toolchain.cmake \
		  -DCMAKE_BUILD_TYPE=Release -DBUILD_opencv_python2=OFF \
		  -DBUILD_opencv_python3=ON -DWITH_GTK=ON -DWITH_GTK_2_X=ON -DWITH_FFMPEG=ON \
		  -DCMAKE_SYSROOT=$(RFSDIR) -DZLIB_LIBRARY=$(RFSDIR)/lib/aarch64-linux-gnu/libz.so \
		  -DWITH_OPENCL=OFF -DBUILD_JASPER=ON -DINSTALL_TESTS=ON \
		  -DBUILD_EXAMPLES=ON -DBUILD_opencv_apps=ON \
                  -DPYTHON_DEFAULT_EXECUTABLE=/usr/bin/python3 \
                  -DPYTHON3_EXECUTABLE=/usr/bin/python3 -DCMAKE_INSTALL_PREFIX=/usr/local \
                  -DPYTHON3_INCLUDE_DIR=$(RFSDIR)/usr/include/python3.6m \
                  -DPYTHON3_LIBRARY=$(RFSDIR)/usr/lib/aarch64-linux-gnu/libpython3.6m.so \
                  -DPYTHON3_NUMPY_INCLUDE_DIRS=$(RFSDIR)/usr/lib/python3/dist-packages/numpy/core/include \
                  -DPYTHON3_PACKAGES_PATH=/usr/local/lib -DENABLE_VFPV3=OFF -DENABLE_NEON=ON \
		  -DOPENCV_EXTRA_CXX_FLAGS="-I$(RFSDIR)/usr/include/gtk-2.0 -I$(RFSDIR)/usr/include/cairo \
		   -I$(RFSDIR)/usr/lib/aarch64-linux-gnu/glib-2.0/include -I$(RFSDIR)/usr/include/pango-1.0 \
		   -I$(RFSDIR)/usr/lib/aarch64-linux-gnu/gtk-2.0/include -I$(RFSDIR)/usr/include/gdk-pixbuf-2.0 \
		   -I$(RFSDIR)/usr/include/atk-1.0 -I$(eIQDIR)/armcl/include" && \
	 make -j$(JOBS) && make install && \
	 cp -f bin/* $(eIQDESTDIR)/usr/local/bin && \
	 cp -f ../samples/dnn/models.yml $(eIQDESTDIR)/usr/local/OpenCV/ && \
	 cp -r ../samples/data $(eIQDESTDIR)/usr/local/OpenCV && \
	 cd $(eIQDESTDIR)/usr/local/lib/cv2/python-3.6 && \
	 mv cv2.cpython-36m-x86_64-linux-gnu.so cv2.cpython-36m-aarch64-linux-gnu.so && cd - && \
	 $(call fbprint_d,"OpenCV")
endif
endif



.PHONY: armcl
armcl: dependency
ifeq ($(CONFIG_EIQ_ARMCL), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"Arm Compute Library") && \
	 $(call fetch-git-tree,armcl,apps/eiq) && cd $(eIQDIR)/armcl && \
	 scons arch=arm64-v8a neon=1 opencl=0 extra_cxx_flags="-fPIC" \
	    benchmark_tests=0 validation_tests=0 -j$(JOBS) && \
	 $(call fbprint_n,"Installing ARM Compute Library") && \
	 cp_args="-Prf --preserve=mode,timestamps --no-preserve=ownership" && \
	 cp $$cp_args arm_compute support include/half $(eIQDESTDIR)/usr/local/include && \
	 install -m 0755 build/libarm_compute*.so $(eIQDESTDIR)/usr/local/lib && \
	 find build/examples -type f -executable -exec cp -f {} $(eIQDESTDIR)/usr/local/bin/ \; && \
	 $(call fbprint_d,"armcl")
endif
endif



.PHONY: armnn
armnn: dependency boost swig crosspyconfig
ifeq ($(CONFIG_EIQ_ARMNN), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"ArmNN") && \
	 $(call fetch-git-tree,armnn,apps/eiq) && $(call fetch-git-tree,armcl,apps/eiq) && \
	 $(call fetch-git-tree,onnx,apps/eiq) && \
	 $(call fetch-git-tree,armnntf,apps/eiq) && \
	 [ ! -f $(eIQDESTDIR)/usr/local/lib/libprotobuf.so ] && \
	 flex-builder -c protobuf -f $(CONFIGLIST) || echo libprotobuf.so exists && \
	 [ ! -f caffe/build/src/caffe/proto/caffe.pb.cc ] && \
	 flex-builder -c caffe -f $(CONFIGLIST) || echo caffe.pb.cc exists && \
	 [ ! -d tensorflow-protobuf/tensorflow/core ] && \
	 make tensorflow-protobuf -f $(FBDIR)/packages/apps/eiq/eiq.mk || \
	 echo tensorflow-protobuf exists && \
	 [ ! -f flatbuffer/libflatbuffers.a ] && \
	 flex-builder -c flatbuffer -f $(CONFIGLIST) || echo libflatbuffers.a exists && \
	 [ ! -f $(eIQDESTDIR)/usr/local/lib/libarm_compute.so ] && \
	 flex-builder -c armcl -f $(CONFIGLIST) || echo libarm_compute.so exists && \
	 [ ! -f onnx/onnx/onnx.pb.cc ] && \
	 flex-builder -c onnx -f $(CONFIGLIST) || echo onnx.pb.cc exists && \
	 cd $(eIQDIR)/armnn && \
	 git reset --hard && patch -p1 < ../patch/0001-fix-pyarmnn-cross-compile-issue.patch && \
	 sed -i '49c option(USE_CCACHE "USE_CCACHE" OFF)' cmake/GlobalConfig.cmake && \
	 mkdir -p build && cd build && \
	 install_dir=$(eIQDESTDIR)/usr/local/bin && \
	 export CXX=$(CROSS_COMPILE)g++ && \
	 export CC=$(CROSS_COMPILE)gcc && \
	 cmake .. -DBUILD_TESTS=1 \
		  -DBUILD_UNIT_TESTS=1 \
		  -DBUILD_SHARED_LIBS=ON \
		  -DBUILD_PYTHON_SRC=1 \
		  -DBUILD_PYTHON_WHL=1 \
		  -DSWIG_DIR=$(FBDIR)/packages/apps/eiq/swig/host_build \
		  -DSWIG_EXECUTABLE=$(FBDIR)/packages/apps/eiq/swig/host_build/bin/swig \
		  -DPYTHON_INCLUDE_DIR=$(RFSDIR)/usr/include/python3.6m \
		  -DPYTHON_LIBRARY=$(RFSDIR)/usr/lib/aarch64-linux-gnu/libpython3.6m.so \
		  -DARMCOMPUTE_ROOT=$(FBDIR)/packages/apps/eiq/armcl \
		  -DARMCOMPUTE_BUILD_DIR=$(FBDIR)/packages/apps/eiq/armcl/build \
		  -DBOOST_ROOT=$(eIQDESTDIR)/usr/local \
		  -DTF_GENERATED_SOURCES=../../tensorflow-protobuf \
		  -DBUILD_TF_LITE_PARSER=1 \
		  -DTF_LITE_GENERATED_PATH=../../armnntf/tensorflow/lite/schema \
		  -DTF_LITE_SCHEMA_INCLUDE_PATH=../../armnntf/tensorflow/lite/schema \
		  -DFLATBUFFERS_ROOT=../../flatbuffer \
		  -DFLATBUFFERS_LIBRARY=../../flatbuffer/libflatbuffers.a \
		  -DFLATBUFFERS_INCLUDE_PATH=../../flatbuffer/include \
		  -DFLATC_DIR=../../flatbuffer_host \
		  -DARMCOMPUTENEON=1 \
		  -DBUILD_TF_PARSER=1 \
		  -DCAFFE_GENERATED_SOURCES=../../caffe/build/src \
		  -DBUILD_CAFFE_PARSER=1 \
		  -DPROTOBUF_ROOT=$(eIQDESTDIR)/usr/local \
		  -DPROTOBUF_LIBRARY_DEBUG=../../protobuf/arm64_build/src/.libs/libprotobuf.so \
		  -DPROTOBUF_LIBRARY_RELEASE=../../protobuf/arm64_build/src/.libs/libprotobuf.so \
		  -DBUILD_ONNX_PARSER=1 \
		  -DONNX_GENERATED_SOURCES=../../onnx \
		  -DCMAKE_INSTALL_PREFIX=/usr/local && \
	 make -j$(JOBS) && make install && \
	 cp_args="-Prf --preserve=mode,timestamps --no-preserve=ownership" && \
	 find tests -maxdepth 1 -type f -executable -exec cp $$cp_args {} $$install_dir \; && \
	 find . -name "lib*.so" | xargs -I {} cp {} $(eIQDESTDIR)/usr/local/lib && \
	 mkdir -p $(eIQDESTDIR)/usr/share/armnn && \
	 cp -rf $(eIQDIR)/armnn/python/pyarmnn/examples $(eIQDESTDIR)/usr/share/armnn/ && \
	 cp $(eIQDIR)/armnn/build/python/pyarmnn/dist/pyarmnn-*.whl $(eIQDESTDIR)/usr/share/armnn/ && \
	 mv $(eIQDESTDIR)/usr/share/armnn/pyarmnn-22.0.0-cp36-cp36m-linux_x86_64.whl  \
	 $(eIQDESTDIR)/usr/share/armnn/pyarmnn-22.0.0-cp36-cp36m-linux_aarch64.whl && \
	 cp $$cp_args UnitTests $$install_dir && ls -l $(eIQDESTDIR)/usr/local/{bin,lib}/*rmnn* && \
	 $(call fbprint_d,"ArmNN")
endif
endif



.PHONY: tensorflow-protobuf
tensorflow-protobuf:
	@cd $(eIQDIR)/armnntf && echo building dependent tensorflow-protobuf && \
	 ../armnn/scripts/generate_tensorflow_protobuf.sh \
	 ../tensorflow-protobuf ../protobuf/host_build && \
	 echo built tensorflow-protobuf in $(eIQDIR)/tensorflow-protobuf/tensorflow



.PHONY: tensorflow
tensorflow: dependency bazel crosspyconfig
ifeq ($(CONFIG_EIQ_TENSORFLOW), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"tensorflow") && \
	 $(call fetch-git-tree,tensorflow,apps/eiq) && cd $(eIQDIR)/tensorflow && \
	 export CC_OPT_FLAGS="-march=native" && \
	 export PYTHON_BIN_PATH="/usr/bin/python3" && \
	 export PYTHON_LIB_PATH=/usr/local/lib/python3.6/dist-packages && \
	 export TF_NEED_IGNITE=0 && \
	 export TF_ENABLE_XLA=0 && \
	 export TF_NEED_OPENCL_SYCL=0 && \
	 export TF_NEED_ROCM=0 && \
	 export TF_NEED_CUDA=0 && \
	 export TF_DOWNLOAD_CLANG=0 && \
	 export TF_NEED_MPI=0 && \
	 export TF_SET_ANDROID_WORKSPACE=0 && \
	 export PATH="$(PATH):$(HOME)/bin" && \
	 [ ! -f aarch64_compiler.BUILD ] && \
	 git am ../patch/Add-cross-build-for-arm64-tensorflow.patch || \
	 echo tensorflow version: $(tensorflow_repo_tag) && \
	 ./configure && \
	 bazel build -c opt //tensorflow/tools/pip_package:build_pip_package \
	       --cpu=aarch64 --crosstool_top=//tools/aarch64_compiler:toolchain \
	       --host_crosstool_top=@bazel_tools//tools/cpp:toolchain \
	       --verbose_failures && \
	 ./bazel-bin/tensorflow/tools/pip_package/build_pip_package \
	 $(eIQDESTDIR)/usr/share/tensorflow --plat_name linux_aarch64 && \
	 cp tensorflow/examples/label_image/label_image.py $(eIQDESTDIR)/usr/share/tensorflow && \
	 cp tensorflow/examples/label_image/data/grace_hopper.jpg $(eIQDESTDIR)/usr/share/tensorflow && \
	 ls -l $(eIQDESTDIR)/usr/share/tensorflow && $(call fbprint_d,"tensorflow")
endif
endif



.PHONY: tflite
tflite: dependency swig crosspyconfig
ifeq ($(CONFIG_EIQ_TFLITE), y)
	@[ $(DISTROTYPE) != ubuntu -o $(shell echo $(DESTARCH)|cut -c 1-3) != arm ] && exit || \
	 [ ! -f $(RFSDIR)/etc/buildinfo ] && echo building dependent $(RFSDIR) && \
	 flex-builder -i mkrfs -r $(DISTROTYPE):$(DISTROSCALE) -a $(DESTARCH) -f $(CONFIGLIST) || \
	 echo target $(RFSDIR) exist && \
	 $(call fbprint_b,"tflite $(tflite_repo_tag)") && \
	 $(call fetch-git-tree,tflite,apps/eiq) && cd $(eIQDIR)/tflite && \
	 git reset --hard && patch -p1 < ../patch/0001-Fixed-dependency-download-script.patch && \
	 if [ $(DESTARCH) = arm64 -a ! -f tensorflow/lite/tools/make/gen/linux_aarch64/lib/libtensorflow-lite.a ]; then \
	     ./tensorflow/lite/tools/make/download_dependencies.sh && \
	     LDFLAGS=-L$(RFSDIR)/lib/aarch64-linux-gnu \
	     ./tensorflow/lite/tools/make/build_aarch64_lib.sh; \
	 elif [ $(DESTARCH) = arm32 -a ! -f tensorflow/lite/tools/make/gen/rpi_armv7l/lib/libtensorflow-lite.a ]; then \
	     ./tensorflow/lite/tools/make/download_dependencies.sh && \
	     ./tensorflow/lite/tools/make/build_rpi_lib.sh; \
	 fi && \
	 if [ $(DESTARCH) = arm64 -a ! -f tensorflow/lite/tools/pip_package/gen/tflite_pip/python3/dist/tflite_runtime*.whl ]; then \
	     export TENSORFLOW_TARGET=aarch64 && \
	     export PATH=$(FBDIR)/packages/apps/eiq/swig/host_build/bin/:$(PATH) && \
	     LDFLAGS=-L$(eIQDIR)/tflite/tensorflow/lite/tools/make/gen/linux_aarch64/lib/ \
	     ./tensorflow/lite/tools/pip_package/build_pip_package.sh; \
	 fi && \
	 [ $(DESTARCH) = arm64 ] && tfarch=linux_aarch64 || tfarch=rpi_armv7l && \
	 cp -f tensorflow/lite/tools/make/gen/$$tfarch/bin/* $(eIQDESTDIR)/usr/local/bin && \
	 cp -f tensorflow/lite/tools/make/gen/$$tfarch/lib/*.a $(eIQDESTDIR)/usr/local/lib && \
	 mkdir -p $(eIQDESTDIR)/usr/share/tflite && \
	 mkdir -p $(eIQDESTDIR)/usr/share/tflite/examples && \
	 cp -f tensorflow/lite/examples/label_image/testdata/grace_hopper.bmp $(eIQDESTDIR)/usr/share/tflite/examples/ && \
	 cp -f tensorflow/lite/java/ovic/src/testdata/labels.txt $(eIQDESTDIR)/usr/share/tflite/examples/ && \
	 cp -f tensorflow/lite/examples/python/label_image.py $(eIQDESTDIR)/usr/share/tflite/examples/ && \
	 cp $(eIQDIR)/tflite/tensorflow/lite/tools/pip_package/gen/tflite_pip/python3/dist/tflite_runtime*.whl \
	 $(eIQDESTDIR)/usr/share/tflite/ && \
	 ls -l $(eIQDESTDIR)/usr/local/bin/benchmark_model $(eIQDESTDIR)/usr/local/bin/minimal && \
	 ls -l $(eIQDESTDIR)/usr/local/lib/libtensorflow-lite.a $(eIQDESTDIR)/usr/local/lib/benchmark-lib.a && \
	 $(call fbprint_d,"tflite")
endif



.PHONY: protobuf
protobuf:
ifeq ($(CONFIG_EIQ_PROTOBUF), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"protobuf") && \
	 $(call fetch-git-tree,protobuf,apps/eiq) && cd $(eIQDIR)/protobuf && \
	 ./autogen.sh && mkdir -p host_build && cd host_build && \
	 ../configure --prefix=/../../../packages/apps/eiq/protobuf/host_build && \
	 make install -j$(JOBS) && cd .. && mkdir -p arm64_build && cd arm64_build && \
	 CC=$(CROSS_COMPILE)gcc CXX=$(CROSS_COMPILE)g++ \
	 ../configure --host=aarch64-linux --prefix=/usr/local \
	 --with-protoc=$(FBDIR)/packages/apps/eiq/protobuf/host_build/bin/protoc && \
	 DESTDIR=$(eIQDESTDIR) make install -j$(JOBS) && $(call fbprint_d,"protobuf")
endif
endif



.PHONY: flatbuffer
flatbuffer: dependency
ifeq ($(CONFIG_EIQ_FLATBUFFER), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"flatbuffer") && \
	 $(call fetch-git-tree,flatbuffer,apps/eiq) && cd $(eIQDIR) && \
	 [ ! -d flatbuffer_host ] && mv flatbuffer flatbuffer_host && \
	 cd flatbuffer_host && \
	 cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
	       -DFLATBUFFERS_BUILD_SHAREDLIB=ON \
	       -DFLATBUFFERS_BUILD_TESTS=OFF && \
	 make -j$(JOBS) && cd .. || echo flatbuffer_host exists && \
	 $(call fetch-git-tree,flatbuffer,apps/eiq) && \
	 cd flatbuffer && \
	 CXX=$(CROSS_COMPILE)g++ CC=$(CROSS_COMPILE)gcc  \
	 cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
	     -DCMAKE_INSTALL_SO_NO_EXE=0 \
	     -DFLATBUFFERS_BUILD_SHAREDLIB=ON \
	     -DCMAKE_NO_SYSTEM_FROM_IMPORTED=1 \
	     -DFLATBUFFERS_BUILD_TESTS=OFF \
	     -DCMAKE_CXX_FLAGS=-fPIC \
	     -DFLATBUFFERS_FLATC_EXECUTABLE=../flatbuffer_host/flatc && \
	 make -j$(JOBS) && cp -f flatc $(eIQDESTDIR)/usr/local/bin && \
	 $(call fbprint_d,"flatbuffer")
endif
endif



.PHONY: caffe
caffe: dependency boost
ifeq ($(CONFIG_EIQ_CAFFE), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"caffe") && \
	 $(call fetch-git-tree,caffe,apps/eiq) && cd $(eIQDIR)/caffe && \
	 [ ! -d $(eIQDESTDIR)/usr/local/include/google/protobuf ] && \
	 flex-builder -c protobuf -f $(CONFIGLIST) || echo protobuf exists && \
	 cp Makefile.config.example Makefile.config && \
	 sed -i "/^# CPU_ONLY := 1/s/#//g" Makefile.config && \
	 sed -i "/^# USE_OPENCV := 0/s/#//g" Makefile.config && \
	 sed -i "/^INCLUDE_DIRS/a INCLUDE_DIRS += /usr/include/hdf5/serial \
	     $(eIQDESTDIR)/usr/local/include/" Makefile.config && \
	 sed -i "/^LIBRARY_DIRS/a LIBRARY_DIRS += /usr/lib/`uname -i`-linux-gnu/hdf5/serial \
	     $(FBDIR)/packages/apps/eiq/protobuf/host_build/lib" Makefile.config && \
	 export PATH=$(FBDIR)/packages/apps/eiq/protobuf/host_build/bin/:$(PATH) && \
	 export LD_LIBRARY_PATH=$(FBDIR)/packages/apps/eiq/protobuf/host_build/lib:$(LD_LIBRARY_PATH) && \
	 make all -j$(JOBS) && make test -j$(JOBS) && make runtest -j$(JOBS) && \
	 $(call fbprint_d,"caffe")
endif
endif



.PHONY: onnx
onnx: dependency
ifeq ($(CONFIG_EIQ_ONNX), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"onnx") && \
	 export ONNX_ML=1 && $(call fetch-git-tree,onnx,apps/eiq) && \
	 unset ONNX_ML && cd $(eIQDIR)/onnx && \
	 export LD_LIBRARY_PATH=../protobuf/host_build/lib:$(LD_LIBRARY_PATH) && \
	 ../protobuf/host_build/bin/protoc onnx/onnx.proto --proto_path=. \
	    --proto_path=$(eIQDESTDIR)/usr/local/include --cpp_out . && \
	 $(call fbprint_d,"onnx")
endif
endif



.PHONY: onnxruntime
onnxruntime: dependency crosspyconfig
ifeq ($(CONFIG_EIQ_ONNXRUNTIME), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"onnxruntime") && \
	 $(call fetch-git-tree,onnxruntime,apps/eiq,nosubmodule) && cd $(eIQDIR)/onnxruntime && \
	 git submodule update --init && \
	 if [ ! -f $(HOME)/cmake-3.16.2/bin/cmake ]; then \
	     wget https://github.com/Kitware/CMake/releases/download/v3.16.2/cmake-3.16.2-Linux-x86_64.sh && \
	     chmod +x cmake-3.16.2-Linux-x86_64.sh && mkdir -p $(HOME)/cmake-3.16.2 && \
	     ./cmake-3.16.2-Linux-x86_64.sh --skip-license --prefix=$(HOME)/cmake-3.16.2; \
	 fi && \
	 if [ ! -f $(HOME)/protoc-3.6.1/bin/protoc ]; then \
	     mkdir -p $(HOME)/protoc-3.6.1 && cd $(HOME)/protoc-3.6.1 && \
	     wget https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protoc-3.6.1-linux-x86_64.zip && \
	     unzip protoc-3.6.1-linux-x86_64.zip && sudo cp -rf include/google /usr/local/include/ && cd -; \
	 fi && \
	 echo "SET(CMAKE_SYSTEM_NAME Linux)" > $(HOME)/tool.cmake && \
	 echo "set(CMAKE_SYSTEM_PROCESSOR aarch64)" >> $(HOME)/tool.cmake && \
	 echo "set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)" >> $(HOME)/tool.cmake && \
	 echo "set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)" >> $(HOME)/tool.cmake && \
	 echo "SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> $(HOME)/tool.cmake && \
	 echo "SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> $(HOME)/tool.cmake && \
	 echo "SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> $(HOME)/tool.cmake && \
	 echo "SET(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)" >> $(HOME)/tool.cmake && \
	 ./build.sh --config RelWithDebInfo --arm64 --update --build --build_shared_lib --build_wheel --parallel \
		--cmake_path=$(HOME)/cmake-3.16.2/bin/cmake  \
		--path_to_protoc_exe=$(HOME)/protoc-3.6.1/bin/protoc \
		--cmake_extra_defines ONNXRUNTIME_VERSION=$(cat ./VERSION_NUMBER) \
		onnxruntime_USE_PREBUILT_PB=OFF \
		onnxruntime_BUILD_UNIT_TESTS=ON \
		CMAKE_TOOLCHAIN_FILE=$(HOME)/tool.cmake \
		CMAKE_CXX_FLAGS="-Wno-error=unused-parameter -I$(RFSDIR)/usr/aarch64-linux-gnu/include" \
		CMAKE_NO_SYSTEM_FROM_IMPORTED=True \
		ZLIB_LIBRARY=$(RFSDIR)/lib/aarch64-linux-gnu/libz.so \
		PNG_LIBRARY=$(RFSDIR)/usr/lib/aarch64-linux-gnu/libpng.so \
		PYTHON_LIBRARY=$(RFSDIR)/usr/lib/aarch64-linux-gnu/libpython3.6m.so \
		PYTHON_INCLUDE_DIR=$(RFSDIR)/usr/include/python3.6m && \
	 cp -f build/Linux/*/libonnxruntime*.a build/Linux/*/onnx/libonnx*.a $(eIQDESTDIR)/usr/local/lib && \
	 cp -f build/Linux/*/libonnxruntime.so $(eIQDESTDIR)/usr/local/lib && \
	 mkdir -p $(eIQDESTDIR)/usr/share/onnxruntime && \
	 cp -f build/Linux/*/dist/onnxruntime-*.whl $(eIQDESTDIR)/usr/share/onnxruntime/ && \
	 cp -f build/Linux/*/onnxruntime_perf_test build/Linux/*/onnx_test_runner $(eIQDESTDIR)/usr/local/bin/ && \
	 mv $(eIQDESTDIR)/usr/share/onnxruntime/onnxruntime-1.1.2-cp36-cp36m-linux_x86_64.whl \
	 $(eIQDESTDIR)/usr/share/onnxruntime/onnxruntime-1.1.2-cp36-cp36m-linux_aarch64.whl && \
	 $(call fbprint_d,"onnxruntime")
endif
endif



.PHONY: pytorch
pytorch:
ifeq ($(CONFIG_EIQ_PYTORCH), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu ] && exit || \
	 $(call fbprint_b,"pytorch") && \
	 $(call fetch-git-tree,pytorch,apps/eiq) && cd $(eIQDIR)/pytorch && \
	 mkdir -p $(eIQDESTDIR)/usr/share/pytorch && \
	 cp whl/torch*.whl $(eIQDESTDIR)/usr/share/pytorch/ && \
	 cp -rf examples $(eIQDESTDIR)/usr/share/pytorch/ && \
	 ls -l $(eIQDESTDIR)/usr/share/pytorch && \
	 $(call fbprint_d,"pytorch")
endif
endif



.PHONY: bazel
bazel:
	@if [ ! -f $(HOME)/bin/bazel ]; then \
	     $(call fbprint_b,"bazel") && \
	     mkdir -p $(HOME)/.bazel && cd $(HOME)/.bazel && \
	     [ ! -f $(HOME)/.bazel/bazel-0.15.0-installer-linux-x86_64.sh ] && \
	     wget $(bazel_bin_url) || echo bazel installer exists && \
	     chmod +x bazel-0.15.0-installer-linux-x86_64.sh && \
	     ./bazel-0.15.0-installer-linux-x86_64.sh --user; \
	     source $(HOME)/.bazel/bin/bazel-complete.bash && \
	     $(call fbprint_d,"bazel"); \
	 fi



.PHONY: swig
swig:
	@if [ ! -f $(eIQDIR)/swig/host_build/bin/swig ]; then \
	     $(call fbprint_b,"swig") && \
	     $(call fetch-git-tree,swig,apps/eiq) && \
	     cd $(eIQDIR)/swig && mkdir -p host_build && \
	     SWIG_TMP=$(DESTDIR) && export DESTDIR=/ && \
	     ./autogen.sh && ./configure --prefix=$(eIQDIR)/swig/host_build && \
	     make && make install && \
	     export DESTDIR=$(SWIG_TMP) && \
	     $(call fbprint_d,"swig"); \
	 fi



.PHONY: boost
boost: dependency
	@if [ ! -d $(eIQDESTDIR)/usr/local/include/boost ]; then \
	     $(call fbprint_b,"boost") && \
	     mkdir -p $(HOME)/.boost && cd $(HOME)/.boost && \
	     if [ ! -f boost_1_64_0.tar.bz2 ]; then \
		 wget $(boost_bin_url) && \
		 tar xf boost_1_64_0.tar.bz2 --strip-components 1; \
	     fi && \
	     echo "using gcc : arm : $(CROSS_COMPILE)g++ ;" > user_config.jam && \
	     ./bootstrap.sh --prefix=$(eIQDESTDIR)/usr/local && \
	     ./b2 install -j$(JOBS) toolset=gcc-arm link=static cxxflags=-fPIC \
	     --with-filesystem --with-test --with-log \
	     --with-program_options --user-config=user_config.jam && \
	     $(call fbprint_d,"boost"); \
	 fi




dependency:
	@export PATH="$(PATH):$(HOME)/bin" && \
	 mkdir -p $(eIQDESTDIR)/usr/local/bin && mkdir -p $(eIQDESTDIR)/usr/local/include && \
	 mkdir -p $(eIQDESTDIR)/usr/local/lib && mkdir -p $(eIQDESTDIR)/usr/share/tensorflow && \
	 if [ ! -d /usr/share/doc/libboost-all-dev ]; then \
	     sudo apt update && sudo apt install -y $(CAFFE_DEPENDENT_PKG); \
	 fi; \
	 if [ ! -d /usr/share/doc/python3-wheel ]; then \
	     sudo apt update && sudo apt install -y $(TENSORFLOW_DEP_APT_PKG); \
	 fi; \
	 if [ ! -d /usr/local/lib/python3.6/dist-packages/keras_applications -a \
	      ! -d ~/.local/lib/python3.6/site-packages/keras_applications ]; then \
	    pip3 install $(TENSORFLOW_DEP_PIP_PKG); \
	 fi; \
	 if [ ! -f $(RFSDIR)/etc/buildinfo ]; then $(call build_dependent_rfs); fi; \
	 if [ ! -f $(RFSDIR)/usr/lib/aarch64-linux-gnu/libavresample.so -a $(VIRTABLE) = y ]; then \
	     [ -n "$(http_proxy)" ] && sudo cp -f /etc/apt/apt.conf $(RFSDIR)/etc/apt/; \
	     sudo chroot $(RFSDIR) apt update && sudo chroot $(RFSDIR) apt install -y $(TARGET_DEPENDENT_PKG); \
	 fi



crosspyconfig:
	@if [ ! -f /usr/aarch64-linux-gnu/include/aarch64-linux-gnu/python3.6m/pyconfig.h ]; then \
	     [ ! -f $(RFSDIR)/usr/include/aarch64-linux-gnu/python3.6m/pyconfig.h ] && \
	     $(call build_dependent_rfs) || echo pyconfig.h exists && \
	     sudo mkdir -p /usr/aarch64-linux-gnu/include/aarch64-linux-gnu/python3.6m && \
	     sudo cp -f $(RFSDIR)/usr/include/aarch64-linux-gnu/python3.6m/pyconfig.h \
	     /usr/aarch64-linux-gnu/include/aarch64-linux-gnu/python3.6m; \
	fi



eiq_install:
	@[ ! -f $(RFSDIR)/etc/buildinfo ] && echo building dependent $(RFSDIR) && \
	 flex-builder -i mkrfs -r ubuntu:$(DISTROSCALE) -a $(DESTARCH) -f $(CONFIGLIST) || \
	 echo target $(RFSDIR) exist && \
	 $(call fbprint_n,"Installing eIQ from $(eIQDESTDIR) to target $(RFSDIR) ...") && \
	 cp_args="-Prf --preserve=mode,timestamps --no-preserve=ownership" && \
	 sudo cp $$cp_args $(eIQDESTDIR)/* $(RFSDIR)/ && \
	 [ $(HOSTARCH) != aarch64 ] && chrootopt="sudo chroot $(RFSDIR)" || echo Running on $(HOSTARCH) && \
	 [ $(VIRTABLE) = y -a -f $(eIQDESTDIR)/usr/share/tensorflow/tensorflow-1.12.3-cp36-cp36m-linux_aarch64.whl ] && \
	 $(call fbprint_n,"Installing tensorflow to target $(RFSDIR) which can be directly deployed on $(DESTARCH) board") && \
	 $$chrootopt python3 -m pip install /usr/share/tensorflow/tensorflow-1.12.3-cp36-cp36m-linux_aarch64.whl || \
	 ls -l $(eIQDESTDIR)/usr/share/tensorflow/*.whl && \
	 [ $(VIRTABLE) = y -a -f $(eIQDESTDIR)/usr/share/onnxruntime/onnxruntime-1.1.2-cp36-cp36m-linux_aarch64.whl ] && \
	 $$chrootopt python3 -m pip install /usr/share/onnxruntime/onnxruntime-1.1.2-cp36-cp36m-linux_aarch64.whl || \
	 ls -l $(eIQDESTDIR)/usr/share/onnxruntime/onnxruntime-*.whl && \
	 [ $(VIRTABLE) = y -a -f $(eIQDESTDIR)/usr/share/armnn/pyarmnn-22.0.0-cp36-cp36m-linux_aarch64.whl ] && \
	 $$chrootopt python3 -m pip install /usr/share/armnn/pyarmnn-22.0.0-cp36-cp36m-linux_aarch64.whl || \
	 ls -l $(eIQDESTDIR)/usr/share/armnn/pyarmnn-*.whl && \
	 [ $(VIRTABLE) = y -a -f $(eIQDESTDIR)/usr/share/pytorch/torch-1.6.0-cp36-cp36m-linux_aarch64.whl ] && \
	 $$chrootopt apt install -y python3-pil>=4.1.1 && \
	 $$chrootopt python3 -m pip install /usr/share/pytorch/torch-1.6.0-cp36-cp36m-linux_aarch64.whl || \
	 ls -l $(eIQDESTDIR)/usr/share/pytorch/torch-*.whl && \
	 [ $(VIRTABLE) = y -a -f $(eIQDESTDIR)/usr/share/pytorch/torchvision-0.7.0-cp36-cp36m-linux_aarch64.whl ] && \
	 $$chrootopt python3 -m pip install /usr/share/pytorch/torchvision-0.7.0-cp36-cp36m-linux_aarch64.whl || \
	 ls -l $(eIQDESTDIR)/usr/share/pytorch/torchvision-*.whl && \
	 [ $(VIRTABLE) = y -a -f $(eIQDESTDIR)/usr/share/tflite/tflite_runtime-2.2.0-cp36-cp36m-linux_aarch64.whl ] && \
	 $$chrootopt python3 -m pip install numpy==1.16.0 && \
	 $$chrootopt python3 -m pip install /usr/share/tflite/tflite_runtime-2.2.0-cp36-cp36m-linux_aarch64.whl || \
	 ls -l $(eIQDESTDIR)/usr/share/tflite/tflite_runtime-*.whl && \
	 $(call fbprint_n,"eIQ installation completed successfully")




eiq_pack:
	@$(call fbprint_n,"Packing $(eIQDESTDIR)") && cd $(eIQDESTDIR) && \
	 sudo tar czf $(FBOUTDIR)/images/app_components_$(DESTARCH)_eIQ.tgz * && \
	 touch $(eIQDIR)/.eiqdone && \
	 $(call fbprint_d,"$(FBOUTDIR)/images/app_components_$(DESTARCH)_eIQ.tgz")



eiq_clean:
	@echo Cleaning for eIQ components ... && \
	rm -rf $(eIQDIR)/armcl/build $(eIQDIR)/armnn/build $(eIQDIR)/opencv/build \
	    $(eIQDIR)/caffe/.build_release $(eIQDIR)/onnxruntime/build \
	    $(eIQDIR)/flatbuffer/{CMakeFiles,libflatbuffers.*,*.cmake,Makefile,CMakeCache.txt,flat*} \
	    $(eIQDESTDIR) $(eIQDIR)/protobuf/*build $(eIQDIR)/tflite/tensorflow/lite/tools/make/gen \
	    $(eIQDIR)/tflite/tensorflow/lite/tools/pip_package/gen \
	    $(eIQDIR)/.eiqdone && \
	$(call fbprint_n,"Clean eIQ components")



eiq_repo_fetch:
	@echo -e "\nfetch eIQ repositories: $(eIQ_REPO_LIST)"
	@$(call repo-update,fetch,$(eIQ_REPO_LIST),apps/eiq)

eiq_repo_update_branch:
	@echo -e "\neIQ repositories update for branch"
	@$(call repo-update,branch,$(eIQ_REPO_LIST),apps/eiq)

eiq_repo_update_tag:
	@echo -e "\neIQ repositories update for tag"
	@$(call repo-update,tag,$(eIQ_REPO_LIST),apps/eiq)

eiq_repo_update_latest:
	@echo -e "\neIQ repositories update to latest HEAD commit"
	@$(call repo-update,update,$(eIQ_REPO_LIST),apps/eiq)

eiq_repo_update_commit:
	@echo -e "\neIQ repositories update to specified commit ID"
	@$(call repo-update,commit,$(eIQ_REPO_LIST),apps/eiq)

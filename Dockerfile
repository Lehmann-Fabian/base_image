# This file builds a Docker base image for its use in other projects

# Copyright (C) 2020-2021 Gergely Padányi-Gulyás (github user fegyi001),
#                         David Frantz

FROM ubuntu:18.04 as builder

# Install folder
ENV INSTALL_DIR /opt/install/src
RUN mkdir -p $INSTALL_DIR

# Refresh package list & upgrade existing packages 
RUN apt-get -y update && apt-get -y upgrade  

# Add PPA for Python 3.x
RUN apt -y install software-properties-common
RUN add-apt-repository -y ppa:deadsnakes/ppa

# Install libraries
RUN apt-get -y install \
  wget \
  unzip \
  curl \
  git \
  build-essential \
  libgdal-dev \
  gdal-bin \
  python-gdal \ 
  libarmadillo-dev \
  libfltk1.3-dev \
  libgsl0-dev \
  lockfile-progs \
  rename \
  parallel \
  apt-utils \
  cmake \
  libgtk2.0-dev \
  pkg-config \
  libavcodec-dev \
  libavformat-dev \
  libswscale-dev \
  python3.8 \
  python3-pip

# Set python aliases for Python 3.x
RUN echo 'alias python=python3' >> ~/.bashrc \
  && echo 'alias pip=pip3' >> ~/.bashrc \
  && . ~/.bashrc
# NumPy is needed for OpenCV, gsutil for Google downloads
RUN pip3 install --upgrade pip
RUN pip3 install numpy==1.18.1 gsutil

# Build OpenCV from source
RUN mkdir -p $INSTALL_DIR/opencv
WORKDIR $INSTALL_DIR/opencv
RUN wget https://github.com/opencv/opencv/archive/4.1.0.zip \
  && unzip 4.1.0.zip
WORKDIR $INSTALL_DIR/opencv/opencv-4.1.0
RUN mkdir -p $INSTALL_DIR/opencv/opencv-4.1.0/build
WORKDIR $INSTALL_DIR/opencv/opencv-4.1.0/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
  && make -j7 \
  && make install \
  && make clean

# Build SPLITS from source
RUN mkdir -p $INSTALL_DIR/splits
WORKDIR $INSTALL_DIR/splits
RUN wget http://sebastian-mader.net/wp-content/uploads/2017/11/splits-1.9.tar.gz
RUN tar -xzf splits-1.9.tar.gz
WORKDIR $INSTALL_DIR/splits/splits-1.9
RUN ./configure CPPFLAGS="-I /usr/include/gdal" CXXFLAGS=-fpermissive \
  && make \
  && make install \
  && make clean

# Cleanup after successfull builds
RUN rm -rf $INSTALL_DIR
RUN apt-get purge -y --auto-remove apt-utils cmake git build-essential software-properties-common

# Create a dedicated 'docker' group and user
RUN groupadd docker && \
  useradd -m docker -g docker -p docker && \
  chgrp docker /usr/local/bin
# Use this user by default
USER docker

WORKDIR /home/docker

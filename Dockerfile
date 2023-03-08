# Note change this to your preference
ARG VERSION=stable-backports
FROM debian:${VERSION}

LABEL maintainer="rjbaw"
ENV DEBIAN_FRONTEND=noninteractive 
ENV DUSER=docker-user
ENV DGROUP=docker-user
ENV DGID=1000
ENV DUID=1000

RUN apt-get update && apt-get dist-upgrade -y 
RUN apt-get install -y\
    --no-install-recommends \
    devscripts \
    checkinstall \
    software-properties-common \
    git \
    python3 \
    python3-pip \
    python3-dev \
    python3-tk \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    sudo \
    unzip \
    tmux \
    tar \
    build-essential \
    vim \
    apt-transport-https \
    gnupg \
    apt-utils \
    dialog \
    wget \
    curl \
    cmake \
    dvipng \
    texlive-science \
    texlive-latex-extra \
    texlive-plain-generic \
    texinfo \
    texlive-xetex \
    texlive-luatex \
    imagemagick \
    libjansson-dev \
    libxpm-dev \
    libgif-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libx11-dev \
    libncurses5-dev \
    libgtk2.0-dev \
    gnutls-dev \
    dvisvgm \
    automake \
    autoconf \
    xclip \
    scrot \
    xournalpp \
    libglibmm-2.4-dev \
    libboost-all-dev \
    libcppunit-dev \
    liblcms2-dev \
    libjpeg-dev \
    fontconfig \
    librsvg2-dev \
    libglade2-dev \
    nodejs \
    npm \
    bash-completion \
    jupyter

COPY fonts /tmp/fonts/
RUN cp /tmp/fonts/* /usr/local/share/fonts/
RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

#    git clone git://git.savannah.gnu.org/emacs.git &&
#    cd emacs && \
#    git checkout emacs-28 \

RUN cd /tmp && \
    curl https://gnu.mirror.constant.com/emacs/emacs-28.2.tar.gz -so emacs.tar.gz &&\
    tar xf emacs.tar.gz &&\
    cd emacs* \
    ./configure \
    -C \
    --with-cairo \
    --with-modules \
    --with-x-toolkit=lucid \
    --with-native-compilation \
    --with-image-magick \
    --with-json \
    --with-rsvg \
    --with-xwidgets \
    --with-harfbuzz \
    CFLAGS='-O3 -march=native' \
    make -j $(nproc) &&\
    make install

RUN cd /tmp &&\
    curl https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.1-linux-x86_64.tar.gz -so julia.tar.gz &&\
    tar xf julia.tar.gz &&\
    cd julia* &&\
    cp -r * /usr/ 

#    --with-x-toolkit=gtk3 \

RUN cd /usr/local/bin &&\
    ln -s /usr/bin/python3 python &&\
    ln -s /usr/bin/pip3 pip &&\
    python3 -m venv /opt/emacs &&\                                             
    chmod +x /opt/emacs/bin/activate  &&\                                      
    . /opt/emacs/bin/activate &&\  
    pip install -U pip jupyter numpy matplotlib scipy sympy cvxpy

RUN userdel `id -nu $DUID` || true
RUN groupadd -g $DGID $DGROUP;
RUN useradd -r -m -d /workspace -s /bin/bash -g $DGID -G sudo -u $DUID $DUSER;
RUN passwd -d $DUSER

RUN echo "export JULIA_NUM_THREADS=`nproc`" >> /workspace/.bashrc &&\
    echo "export TERM=xterm-256color" >> /workspace/.bashrc &&\
    echo "alias em='emacsclient -c -n -a \"\"'" >> /workspace/.bashrc &&\
    echo "alias et='emacsclient -t -nw -a \"\"'" >> /workspace/.bashrc &&\
    echo "source \"/opt/emacs/bin/activate\"" >> /workspace/.bashrc &&\
    echo "source \"/workspace/.cargo/env\"" >> /workspace/.bashrc
COPY emacs_config /workspace/.emacs.d
RUN chown -R $DUSER. /workspace

RUN apt-get -y autoremove &&\
    apt-get -y autoclean
RUN rm -rf /var/cache/apt
RUN rm -r /tmp/*

USER $DUSER
RUN echo 'y' | emacs --daemon | cat
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN julia -e 'import Pkg; Pkg.add("IJulia")'
WORKDIR /workspace

RUN ["/bin/bash"]

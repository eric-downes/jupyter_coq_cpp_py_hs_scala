## uses the multi-stage pattern https://docs.docker.com/build/building/multi-stage/

############################################
# python, coq, scala adapted from https://gitlab.com/nicolalandro/jupyter-and-coq
############################################

FROM ubuntu

RUN apt-get update && apt-get install -y coq coqide python3-dev python3 curl
RUN apt-get update && apt-get install -y python3-pip default-jre
RUN rm -rf /var/lib/apt/lists/*

# Install jupyter and python dependency
WORKDIR /server
ADD requirements.txt /server/requirements.txt

# Configure jupyter plugin for install extension
RUN jupyter contrib nbextension install --user
RUN jupyter nbextensions_configurator enable --user

# Configure sos (for multi lenguage into a notebook)
RUN python3 -m sos_notebook.install

# Configure coq (proof assistant)
RUN python3 -m coq_jupyter.install

# Install coursier for scala and almond
ENV export PATH=$PATH:$HOME/.local/share/coursier/bin
RUN curl -Lo /usr/local/bin/coursier https://git.io/coursier-cli && chmod +x /usr/local/bin/coursier

# install & configure scala and almond
RUN coursier install scala
RUN coursier launch --fork almond -- --install

############################################
# haskell -- see https://github.com/IHaskell/IHaskell
############################################

FROM haskell AS ihaskell_base
RUN apt-get update && apt-get install -y libzmq5 
RUN rm -rf /var/lib/apt/lists/*

FROM ihaskell_base AS builder
RUN apt-get update && apt-get install -y libzmq3-dev pkg-config
RUN rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY stack.yaml stack.yaml
COPY ihaskell.cabal ihaskell.cabal
COPY ghc-parser ghc-parser
COPY ihaskell-display ihaskell-display

RUN stack setup
RUN stack build ihaskell --only-snapshot
COPY src src
COPY html html
COPY main main
COPY jupyterlab-ihaskell jupyterlab-ihaskell
RUN stack install ihaskell --local-bin-path ./bin/
RUN sed -n 's/resolver: \(.*\)/\1/p' stack.yaml | tee resolver.txt
RUN mkdir /data && \
    snapshot_install_root=$(stack path --snapshot-install-root) && \
    cp $(find ${snapshot_install_root} -name hlint.yaml) /data


FROM ihaskell_base AS ihaskell

# Create runtime user
ENV NB_USER jovyan
ENV NB_UID 1000
RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

# Create directory for storing ihaskell files
ENV IHASKELL_DATA_DIR /usr/local/lib/ihaskell
RUN mkdir -p ${IHASKELL_DATA_DIR} && chown ${NB_UID} ${IHASKELL_DATA_DIR}

# Set up + set hlint data directory
ENV HLINT_DATA_DIR /usr/local/lib/hlint
COPY --from=builder --chown=${NB_UID} /data/hlint.yaml ${HLINT_DATA_DIR}/
ENV hlint_datadir ${HLINT_DATA_DIR}

# Set current user + directory
WORKDIR /home/${NB_USER}/src
RUN chown -R ${NB_UID} /home/${NB_USER}/src
USER ${NB_UID}

# Set up global project
COPY --from=builder --chown=${NB_UID} /build/resolver.txt /tmp/
RUN stack setup --resolver=$(cat /tmp/resolver.txt) --system-ghc
RUN stack config set system-ghc --global true

# Set up env file
RUN stack exec env --system-ghc > ${IHASKELL_DATA_DIR}/env

# Install + setup IHaskell
COPY --from=builder --chown=${NB_UID} /build/bin/ihaskell /usr/local/bin/
COPY --from=builder --chown=${NB_UID} /build/html ${IHASKELL_DATA_DIR}/html
COPY --from=builder --chown=${NB_UID} /build/jupyterlab-ihaskell ${IHASKELL_DATA_DIR}/jupyterlab-ihaskell
RUN export ihaskell_datadir=${IHASKELL_DATA_DIR} && \
    ihaskell install --env-file ${IHASKELL_DATA_DIR}/env
RUN jupyter notebook --generate-config

CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
# CMD jupyter notebook --ip=0.0.0.0 --port=8888 --allow-root --NotebookApp.token=''

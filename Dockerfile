## adapted from https://gitlab.com/nicolalandro/jupyter-and-coq
## 
FROM ubuntu

# Install coq, python, curl
RUN apt-get update && apt-get install -y coq coqide python3-dev python3 curl
RUN apt-get update && apt-get install -y python3-pip default-jre


# Install jupyter and python dependency
WORKDIR /server
ADD requirements.txt /server/requirements.txt
RUN python3 -m pip install -r requirements.txt

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

CMD jupyter notebook --ip=0.0.0.0 --port=8888 --allow-root --NotebookApp.token=''

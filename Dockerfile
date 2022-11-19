## adapted from https://gitlab.com/nicolalandro/jupyter-and-coq
## 
FROM ubuntu

# Install coq e python
RUN apt-get update && apt-get install -y coq coqide python3-dev python3
RUN apt-get update && apt-get install -y python3-pip

# Install scala
RUN apt-get update && apt-get install -y wget
RUN wget https://downloads.lightbend.com/scala/2.11.0/scala-2.11.0.tgz && tar -xvzf scala-2.11.0.tgz && rm scala-2.11.0.tgz
ENV SCALA_HOME=/scala-2.11.0
ENV export PATH=$PATH:$SCALA_HOME/bin:$PATH

# Install jupyter and python dependency
WORKDIR /server
ADD requirements.txt /server/requirements.txt
RUN pip3 install -r requirements.txt

# Configure jupyter plugin for install extension
RUN jupyter contrib nbextension install --user
RUN jupyter nbextensions_configurator enable --user

# Configure coq (proof assistant)
RUN python3 -m coq_jupyter.install

# Configure sos (for multi lenguage into a notebook)
RUN python3 -m sos_notebook.install

# Configure Scala
ADD almond .
RUN ./almond --install

CMD jupyter notebook --ip=0.0.0.0 --port=8888 --allow-root --NotebookApp.token=''

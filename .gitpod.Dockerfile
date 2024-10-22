FROM gitpod/workspace-full

RUN git clone https://github.com/erlang/otp.git && cd otp && git checkout maint-27 && ./configure && make && sudo make install
RUN git clone https://github.com/erlang/rebar3.git && cd rebar3 && ./bootstrap && sudo mv rebar3 /usr/local/bin/
RUN sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates gnupg curl && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && sudo apt-get update && sudo apt-get install-y google-cloud-cli
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && sudo apt-get update && sudo apt-get install -y packer
RUN curl -L https://github.com/google/go-tpm-tools/releases/download/v0.4.4/go-tpm-tools_Linux_x86_64.tar.gz && tar xvf go-tpm-tools.tar.gz  
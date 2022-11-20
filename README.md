# jupyverse

Dockerized jupyter nb in which one can execute commands from many
languages; you choose the kernel for each cell.  Modified from [Nicola
Landro's repo](https://gitlab.com/nicolalandro/jupyter-and-coq)

## Status

Currently we have these working together
- [coq_jupyter](https://github.com/EugeneLoy/coq_jupyter)
- [almond](https://almond.sh/docs/quick-start-install) (scala jupyter kernel)

These commands seem to work:
```
docker build -t jupverse:py-coq-sc .
docker run -p 8888:8888 jupyverse:py-coq-sc
```
However if you visit `0.0.0.0:8888` in chrome.... nothing.  Same with `127.0.0.1:8888` :(

## Future

1. [ ] [IHaskell](https://github.com/IHaskell/IHaskell)
1. [ ] [C++ jupyter kernel](https://github.com/jupyter-xeus/xeus-cling)
1. [ ] [Rust](https://github.com/google/evcxr/tree/main/evcxr_jupyter)
1. [ ] [TypeScript](https://github.com/winnekes/itypescript)
1. [ ] [Agda](https://github.com/lclem/agda-kernel)
1. Adapt to use `jupyter-lab` instead


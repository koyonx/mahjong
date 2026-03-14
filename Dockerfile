FROM ocaml/opam:ubuntu-24.04-ocaml-5.2

USER opam
WORKDIR /home/opam/app

RUN opam install dune melange melange-testing-library ounit2 -y

COPY --chown=opam:opam src/core/ src/core/
COPY --chown=opam:opam src/bindings/ src/bindings/
COPY --chown=opam:opam test/ test/
COPY --chown=opam:opam dune-project .

CMD ["dune", "build"]

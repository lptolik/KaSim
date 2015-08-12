#!/bin/bash

eval `opam config env`
make bin/KaSim
make bin/KaSa


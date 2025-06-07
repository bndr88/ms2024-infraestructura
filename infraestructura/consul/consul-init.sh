# !/bin/bash

consul services register -name=identity -address=https://localhost -port=7081

consul services register -name=catalog -address=https://localhost -port=7291

consul services register -name=inventory -address=https://localhost -port=7050
# Analysis scripts and tools

This folder contains multiple tools and files for the analysis:

- `analysis.jl`: a short script to join all CSV files in `data`. It generates DataFrame-ready CSVs for the parallel approach and their serial equivalent (with an `_s` at the end of the filename):
    - `ackley.csv` and its serial equivalent: `ackley_s.csv`
    - `eggholder`
    - `michalewicz`
    - `rana`
    - `rosenbrock`
- `plots.ipynb`: a Jupyter notebook for generating the figures used in the paper. It creates:
    - `figure1.pdf`
    - `figure2.pdf`

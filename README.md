Here’s the README updated to mention Julia and Gurobi:

---

# Airborne-TSP-Optimizer

## Project Overview
This project tackles a modified Traveling Salesman Problem (TSP) inspired by an aviation challenge, where small aircraft aim to complete multiple stops across France within a 24-hour period. The goal is to maximize the number of aerodromes visited under time and distance constraints.

## Problem Description
The problem models a TSP variant, focusing on optimizing routes between aerodromes, with specific constraints:
- **MTZ (Miller-Tucker-Zemlin) Formulation**: Polynomial constraints, simpler but slower on large datasets.
- **DFJ (Dantzig-Fulkerson-Johnson) Formulation**: Exponential constraints with tighter solutions, using Branch-and-Cut techniques for constraint generation.

## Key Features
- Compares MTZ and DFJ formulations for efficiency and accuracy.
- Implements constraint programming with Julia and the Gurobi optimizer.
- Provides performance metrics on solution time, branch-and-cut nodes, and relaxation bounds.

## Installation
1. **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/Airborne-TSP-Optimizer.git
    cd Airborne-TSP-Optimizer
    ```
2. **Install dependencies**:
    - Ensure [Julia](https://julialang.org/) is installed.
    - Install required Julia packages by running:
      ```julia
      using Pkg
      Pkg.add(["JuMP", "Gurobi"])
      ```
    - [Gurobi](https://www.gurobi.com/) must be installed and licensed for optimization tasks.

## Usage
1. **Define input data**: Structure aerodrome coordinates, initial and final aerodromes, and constraints in the specified format in the `data/` folder.
2. **Run the solver**:
    ```bash
    julia main.jl --method [MTZ | DFJ] --input data/instance.json
    ```
3. **View results**: Results and visualizations are saved to the `output/` folder.

## Example
To solve the problem using MTZ on a sample instance:
```bash
julia main.jl --method MTZ --input data/sample_instance.json
```

## Results
Results for MTZ and DFJ methods are compared, including solution time, branch-and-cut nodes, and relaxation values.
To add the report to your GitHub project, you can include it in a `docs` folder and link to it from the README. Here’s how:


## Documentation
For a detailed description of the problem, methodology, and results, please refer to the project report:
[Project Report (PDF)](Course_d'avion.pdf)


## Acknowledgments
Guidance provided by Sourour Elloumi. Developed by Eya Jlassi and Mohamed Aziz Mhadbi for SOD321: Discrete Optimization at École Nationale Supérieure de Techniques Avancées.

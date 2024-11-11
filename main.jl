# main.jl
include("MTZ.jl")  # Loads functions from MTZ.jl
include("DFJ.jl")  # Load DFJ.jl if it also exists

# Define method and files (or get these from ARGS if needed)
method = "MTZ"    # or "DFJ"
input_file = "data/sample_instance.txt"  # Ensure this file exists with expected structure
output_file = "output/solution.txt"

# Load data using the function from MTZ.jl
if method == "MTZ"
    optimize_path(input_file, output_file)  # Calls the MTZ solver
elseif method == "DFJ"
    # Assuming DFJ has a similar function
    optimize_path_dfj(input_file, output_file)  # Calls the DFJ solver
else
    println("Invalid method. Use MTZ or DFJ.")
end

using JuMP
using Gurobi


# Function to read instance data
function readInstance(file::String)
    # Open file, extract data, close file
    o = open(file, "r")
    data = readlines(o)
    close(o)

    # Get simple numeric data
    n = parse(Int64, data[1])  # number of airports
    d = parse(Int64, data[2])  # departure airport
    f = parse(Int64, data[3])  # arrival airport
    Amin = parse(Int64, data[4])  # Minimum number of airports to visit
    Nr = parse(Int64, data[5])  # number of regions (must all be visited)
    R = parse(Int64, data[9])  # maximum range of the plane

    # Get region definitions
    regions = Dict()
    for i in 1:Nr
        regions[i] = []
    end

    region_data = split(data[7], " ")
    for i in 1:n
        k = parse(Int64, region_data[i])
        if (k != 0)
            push!(regions[k], i)
        end
    end

    # Get airport coordinates
    coords = Matrix{Int64}(zeros(n, 2))  # coordinates matrix
    for i in 1:n
        line = split(data[10 + i], " ")
        coords[i, 1] = parse(Int64, line[1])
        coords[i, 2] = parse(Int64, line[2])
    end

    # Produce distance matrix
    D = Matrix{Int64}(zeros(n, n))  # distance matrix
    for i in 1:n
        for j in 1:n
            D[i, j] = Int64(floor(sqrt((coords[j, 1] - coords[i, 1])^2 + (coords[j, 2] - coords[i, 2])^2)))
        end
    end
    return n, d, f, Amin, Nr, R, regions, coords, D
end


function save_to_txt(filename::String, n, coords, regions, paths, d, e)
    open(filename, "w") do f
        # Write coordinates
        write(f, "Coords:\n")
        for i in 1:n
            write(f, "$(coords[i, 1]), $(coords[i, 2]) \n")
        end

        # Write regions
        write(f, "Regions:\n")
        for (k, airport_indices) in regions
            write(f, "Region $k: $(join(airport_indices, ", "))\n")  # Correctly format output
        end

        # Write paths
        write(f, "Paths:\n")
        for (i, j) in paths
            write(f, "$i ,$j \n")  # Use interpolation
        end
        write(f, "limits:\n")
        write(f, "$d, $e \n")
    end
end


function optimize_path(file::String, output_file::String)
    # Get data
    n, d, f, Amin, Nr, R, regions, coords, D = readInstance(file)

    # Declaration of the model
    model = Model(Gurobi.Optimizer)

    # Declaration of variables
    @variable(model, x[1:n, 1:n], Bin)  # 1 if there is an arc between i and j, 0 otherwise
    @variable(model, y[1:n], Bin)        # 1 if aerodrome i is visited, 0 otherwise
    @variable(model, t[1:n] >= 0)        # Position of the node along the path

    # Declaration of the objective
    @objective(model, Min, sum(D[i, j] * x[i, j] for i in 1:n for j in 1:n))

    # Constraints: initial departure from d
    @constraint(model, sum(x[d, j] for j in 1:n if j != d) == 1)

    # Constraints: final arrival at f
    @constraint(model, sum(x[i, f] for i in 1:n if i != f) == 1)

    # Constraint: minimum number of aerodromes to visit
    @constraint(model, sum(y[i] for i in 1:n) >= Amin)

    # Flow conservation constraints
    for i in 1:n
        if (i != d) && (i != f)
            @constraint(model, sum(x[i, j] for j in 1:n) == y[i])  # Outgoing flow
            @constraint(model, sum(x[j, i] for j in 1:n) == y[i])  # Incoming flow
        end
    end

    # Constraint: at least one aerodrome in each region is visited
    for k in 1:Nr
        @constraint(model, sum(y[i] for i in regions[k]) >= 1)
    end

    # Constraint: maximum distance between two airports
    for i in 1:n
        for j in 1:n
        @constraint(model, D[i, j] * x[i, j]  <= R)
        end
    end

    # Constraint: elementary path (subtour elimination)
    for i in 1:n
        for j in 1:n
            if (i != d) && (i != f) && (j != d) && (j != f)
                @constraint(model, t[i] - t[j] + (n - 1) * x[i, j] <= n - 2)
            end
        end
    end

    # Solve the model
    JuMP.optimize!(model)

    # Display the results
    obj_value = JuMP.objective_value(model)
    println("Objective value: ", obj_value)
    println("Optimal solution for arcs: ")
    for i in 1:n 
        for t in 1:n
            if JuMP.value(x[i, t]) > 0  # Ensure only visited arcs are printed
                println("x[$i, $t]: ", JuMP.value(x[i, t]))
            end
        end 
    end

    # Print the regions visited
    println("Regions visited: ", Nr)
    for k in 1:Nr
        if any(JuMP.value(y[i]) > 0 for i in regions[k])
            println("Region $k has been visited.")
        end
    end

    # Print the nodes visited
    println("Nodes visited: ", Nr)
    for i in 1:n
        println("y[$i]: ", JuMP.value(y[i]))
    end

    # Prepare paths based on visited airports
    paths = []
    for i in 1:n
        for j in 1:n
            if JuMP.value(x[i,j]) > 0
            push!(paths, (i,j))  # Add coordinates of visited airports
            end
         end
    end

    save_to_txt(output_file, n, coords, regions, paths,d, f )

end

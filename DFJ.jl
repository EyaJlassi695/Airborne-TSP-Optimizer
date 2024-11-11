
# ---------------------------------------------------------------
# Function that reads instances and returns formatted data
# Usage : n,d,f,Amin,Nr,R,regions,coords = readInstance("path/to/instance.txt")
# To use it in other files, use include("lecture_distances.jl")
# Parameter meanings :
# n : number of airports
# d : "depart"/start
# f : "fin"/end
# Amin : minimum number of airports to go through
# Nr : number of regions (all must be visited !)
# R : maximum range of a plane
# regions : array such that regions[region number] =
# list of airports in that region
# coords : coordinates of all airports
# ---------------------------------------------------------------
using JuMP
using Gurobi
using IterTools



function readInstance(file::String)

  #Open file, extract data, close file
  o = open(file,"r")
  data = readlines(o)
  close(o)

  #Get simple numeric data
  n = parse(Int64,data[1]) #nombre d'aerodromes
  d = parse(Int64,data[2]) #aerodrome de depart
  f = parse(Int64,data[3]) #aerodrome d'arrivé
  Amin = parse(Int64,data[4]) # Nombre minimal d'aérodromes à visiter 
  Nr = parse(Int64,data[5]) # nbre d'aerodrome à parcourir
  R = parse(Int64,data[9]) #le rayon ou distance maximale

  #Get region definitions
  regions = Dict() #region de chaque aerodrome
  for i in 1:Nr
    regions[i] = []
  end

  region_data = split(data[7]," ")
  for i in 1:n
    k = parse(Int64,region_data[i])
    if (k != 0)
      append!(regions[k],i)
    end
  end

  #Get airport coordinates
  coords = Matrix{Int64}(zeros(n,2)) #coordonnee matrice
  for i in 1:n
    line = split(data[10+i]," ")
    coords[i,1] = parse(Int64,line[1])
    coords[i,2] = parse(Int64,line[2])
  end

  #Produce distance matrix
D = Matrix{Int64}(zeros(n,n)) #distance matrix
for i in 1:n
  for j in 1:n
    D[i,j] = Int64(floor(sqrt((coords[j,1] - coords[i,1])^2
    + (coords[j,2] - coords[i,2])^2)))
  end
end

  return n,d,f,Amin,Nr,R,regions,coords,D
end

function toutes_sous_listes(liste)
  n = length(liste)
  sous_listes = []
  
  for i in 0:(2^n - 1)
      sous_liste = []
      for j in 1:n
          if (i >> (j-1)) & 1 == 1
              push!(sous_liste, liste[j])
          end
      end
      push!(sous_listes, sous_liste)
  end
  
  return sous_listes
end


function minimum(file::String)
    # Get data
    n, d, f, Amin, Nr, R, regions, coords, D = readInstance(file)


    # Declaration of the model
    model = Model(Gurobi.Optimizer)

    # Declaration of variables
    @variable(model, x[1:n, 1:n], Bin)
    @variable(model, y[1:n], Bin)
    

    # Declaration of the objective
    @objective(model, Min, sum(sum(D[i,j] * x[i,j] for i in 1:n) for j in 1:n))

    # Constraints: initial departure from d
    @constraint(model, sum(x[d, j] for j in 1:n if j != d) == 1)

    # Constraints: final arrival at f
    @constraint(model, sum(x[i, f] for i in 1:n if i != f) == 1)

    # Constraint: minimum number of aerodromes to visit
    @constraint(model, sum(y[i] for i in 1:n ) >= Amin)

    # Constraint: flow conservation 
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

    # Constraint: maximum distance between two aerodromes is less than R
    for i in 1:n
        @constraint(model, sum(D[i, j] * x[i, j] for j in 1:n) <= R)
    end
    # Constraint: elimination of cycles (subsets of size >= 2)
    sous_ensemble = toutes_sous_listes(1:n)
    for S in sous_ensemble
        if length(S) >= 2  # Only consider subsets of size >= 2
            @constraint(model, sum(x[i, j] for i in S for j in S if i != j) <= length(S) - 1)
        end
    end
    @constraint(model, [i in 1:n], x[i, i]== 0)


 

    # Solve the model
    JuMP.optimize!(model)

    # Display the results
  obj_value = JuMP.objective_value(model)
  println("Objective value: ", obj_value)
  println("Optimal solution for quantities produced each period: ")
  for i in 1:n 
      for t in 1:n
          if JuMP.value(x[i, t]) > 0  # Ensure only visited arcs are printed
              println("x[$i, $t]: ", JuMP.value(x[i, t]))
          end
      end 
  end

  # Print the regions visited
  println("Regions visited: ",Nr)
  for k in 1:Nr
      if any(JuMP.value(y[i]) > 0 for i in regions[k])
          println("Region $k has been visited.")
      end
  end
 # Print the regions visited
 println("noeud visited: ",Nr)
 for i in 1:n
  println("y",JuMP.value(y[i]))
     
 end
  return
end


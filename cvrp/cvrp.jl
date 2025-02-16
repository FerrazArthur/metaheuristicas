###################################################
# FUNÇÕES E HEURÍSTICAS VARIADAS PARA O CVRP
#
# Adaptado por: Arthur Ferraz
# Baseado em código de Leonardo D. Secchin
# Data: 07/02/2025
###################################################

using CVRPLIB

include("cvrpplot.jl")

# Custo da solução sol no CVRP
function cvrpdist(cvrp, encoded_solution, min_vehicles)
    solution = decode_solution(encoded_solution, min_vehicles,
                cvrp.demand, cvrp.capacity)
    total_dist = 0
    
    for route in solution
        if length(route) > 1
            for i in 1:(length(route)-1)
                total_dist += cvrp.weights[route[i], route[i+1]]
            end
            # Return to deposit
            total_dist += cvrp.weights[route[end], 1]
        end
    end
    return total_dist
end

function swap!(sol, i, j)
    aux = sol[i]
    sol[i] = sol[j]
    sol[j] = aux
end

function reversao!(sol, i, j)
    if i < j
        sol[i:j] .= sol[j:-1:i]
    else
        sol[j:i] .= sol[i:-1:j]
    end
end

function insercao!(sol, i, j)
    if i < j
        sol = [sol[1:(i-1)]; sol[(i+1):j]; i; sol[(j+1):end]]
    else
        sol = [sol[1:j]; i; sol[(j+1):(i-1)]; sol[(i+1):end]]
    end
end

function roleta(p)
    c = cumsum(p)
    r = rand()
    return findfirst(r .<= c)
end

# Decodificação da solução BRKGA para CVRP
# Each element of endoded_solution is composed of a integer for a vehicle plus a
# random number in [0, 1[
function decode_solution(encoded_solution, min_vehicles, demands, capacity)
    solution = [[] for _ in 1:min_vehicles]
    
    # Separate the vehicle and the random number
    decoded = [(Int(floor(x)), x - floor(x)) for x in encoded_solution]

    # Add the client index to the unsorted decoded list and sort it only by the
    # random number
    sorted_clients = sort(collect(enumerate(decoded)), by=x -> x[2][2])
    
    # Assign clients to vehicles
    vehicle_loads = zeros(min_vehicles)  # Track load per vehicle
    for (client, (vehicle, _)) in sorted_clients
        if vehicle_loads[vehicle] + demands[client] <= capacity
            push!(solution[vehicle], client)
            vehicle_loads[vehicle] += demands[client]
        else
            # Find a vehicle with space
            for v in 1:min_vehicles
                if vehicle_loads[v] + demands[client] <= capacity
                    push!(solution[v], client)
                    vehicle_loads[v] += demands[client]
                    break
                end
            end
        end
    end
    
    ## Add the depot to the beginning and end of each route
    for route in solution
        pushfirst!(route, 1)
        push!(route, 1)
    end
    
    return solution
end

function Opt2!(cvrp, solution, min_vehicles)
    melhor = cvrpdist(cvrp, solution, min_vehicles)
    
    for route in solution
        if length(route) > 3
            for i = 2:length(route)-2
                for j = i+1:length(route)-1
                    new_route = copy(route)
                    reversao!(new_route, i, j)
                    new_sol = copy(solution)
                    new_sol[solution .== route] = [new_route]
                    new_dist = cvrpdist(cvrp, new_sol, min_vehicles)
                    
                    if new_dist < melhor
                        solution .= new_sol
                        melhor = new_dist
                    end
                end
            end
        end
    end
end
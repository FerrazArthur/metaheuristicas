###################################################
# FUNÇÕES E HEURÍSTICAS VARIADAS PARA O CVRP
#
# Adaptado por: Arthur Ferraz
# Baseado em código de Leonardo D. Secchin
# Data: 07/02/2025
###################################################

using CVRPLIB

include("cvrpplot.jl")

# Solution cost
function cvrpdist!(cvrp, encoded_solution, min_vehicles)
    solution = decode_solution!(encoded_solution, cvrp, min_vehicles)
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

# Each element of endoded_solution is composed of a integer for a vehicle plus a
# random number in [0, 1[
# Surpassing the cvrp.capacity of a vehicle, a greedy approach is used to find the
# closest vehicle with space and the encoded_solution is reforged
function decode_solution!(encoded_solution, cvrp, min_vehicles)
    solution = [[] for _ in 1:min_vehicles]
    vehicle_loads = zeros(min_vehicles)
    remaining_clients = []
    
    # Separate the vehicle and the random number
    decoded = [(Int(floor(x)), x - floor(x)) for x in encoded_solution]

    # Add the client index to the unsorted decoded list and sort it only by the
    # random number
    sorted_clients = sort(collect(enumerate(decoded)), by=x -> x[2][2])
    
    # Assign clients to vehicles
    for (client, (vehicle, _)) in sorted_clients
        if vehicle_loads[vehicle] + cvrp.demand[client] <= cvrp.capacity
            push!(solution[vehicle], client)
            vehicle_loads[vehicle] += cvrp.demand[client]
        else
            push!(remaining_clients, client)
        end
    end
    
    ## Add the depot to the beginning and end of each route
    for route in solution
        pushfirst!(route, 1)
        push!(route, 1)
    end

    # Insert remaining clients in the best position of any route
    for client in remaining_clients
        best_vehicle, best_position, best_cost = -1, -1, Inf
        
        for v in 1:min_vehicles
            if vehicle_loads[v] + cvrp.demand[client] > cvrp.capacity
                continue
            end
            for pos in 2:length(solution[v])
                new_cost = cvrp.weights[solution[v][pos-1], client] + cvrp.weights[client, solution[v][pos]] - cvrp.weights[solution[v][pos-1], solution[v][pos]]
                
                if new_cost < best_cost
                    best_vehicle, best_position, best_cost = v, pos, new_cost
                end
            end
        end
        
        if best_vehicle != -1
            insert!(solution[best_vehicle], best_position, client)
            vehicle_loads[best_vehicle] += cvrp.demand[client]
        else
            println("Client $client could not be inserted")
        end
    end
    
    # Update encoded solution with respect to the established order
    for v in 1:min_vehicles
        sorted_positions = sortperm([findfirst(==(client), solution[v])
            for client in solution[v] if client != 1])
        for (order, client) in enumerate(solution[v][sorted_positions])
            if client != 1  # Skip depot
                encoded_solution[client] = v + order / (length(solution[v]) + 1)
            end
        end
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
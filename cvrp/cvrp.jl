###################################################
# FUNÇÕES E HEURÍSTICAS VARIADAS PARA O CVRP
#
# Adaptado por: Arthur Ferraz
# Baseado em código de Leonardo D. Secchin
# Data: 07/02/2025
###################################################

using CVRPLIB
include("cvrpplot.jl")
using Dates

# Solution cost without route codification
function cvrpdist_no_route!(cvrp, encoded_solution)
    solution = decode_solution_no_route!(encoded_solution, cvrp)
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

# Solution cost
function cvrpdist!(cvrp, encoded_solution, num_vehicles)
    solution = decode_solution!(encoded_solution, cvrp, num_vehicles)
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


function routeDist(cvrp, route)
    dist = 0.0
    for i in 1:(length(route) - 1)
        dist += cvrp.weights[route[i], route[i+1]]
    end
    return dist
end

function Opt2!(cvrp, solution)
    for route in solution
        melhor = routeDist(cvrp, route)
        if length(route) > 3
            for i = 2:length(route)-2
                for j = i+1:length(route)-1
                    new_route = similar(route)
                    new_route .= route
                    reversao!(new_route, i, j)
                    new_dist = routeDist(cvrp, new_route)
                    
                    if new_dist < melhor
                        route .= new_route
                        melhor = new_dist
                    end
                end
            end
        end
    end
end

# Each element of endoded_solution is composed of a integer for a vehicle plus a
# random number in [0, 1[
# Surpassing the cvrp.capacity of a vehicle, a greedy approach is used to find the
# closest vehicle with space and the encoded_solution is reforged
function decode_solution!(encoded_solution, cvrp, min_vehicles)
    num_vehicles = min_vehicles[]
    solution = [[] for _ in 1:num_vehicles]
    vehicle_loads = zeros(num_vehicles)
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
        
        for v in 1:num_vehicles
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
            # println("Client $client demanded a new vehicle")
            push!(solution, [1, client, 1])
            push!(vehicle_loads, cvrp.demand[client])
            num_vehicles += 1
            min_vehicles[] += 1
        end
    end
    
    # Apply 2-opt heuristic to improve routes
    Opt2!(cvrp, solution)

    # Update encoded solution with respect to the established order
    for v in 1:num_vehicles
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

# Each element of endoded_solution is composed of a integer for a vehicle plus a
# random number in [0, 1[
# A localsearch approach is used to find the order and route of each client that
# minimize the added cost and doesnt excess the capacity of each vehicle.
function decode_solution_no_route!(encoded_solution, cvrp)
    solution = [[1, 1]]
    vehicle_loads = [0]

    # Add the client index to the unsorted decoded list and sort it only by the
    # random number
    sorted_clients = sort(collect(enumerate(encoded_solution)), by=x -> x[2])

    # Assign clients to vehicles
    for (client, _) in sorted_clients
        min_extra_cost = Inf
        best_route_index = nothing
        best_position_index = nothing
        i = 1
        # Search for the best route and position to insert the client
        while i <= length(solution)
            if vehicle_loads[i] + cvrp.demand[client] <= cvrp.capacity
                # Do not consider the depot
                for j in 2:(length(solution[i])-1)
                    extra_cost = cvrp.weights[solution[i][j], client] + cvrp.weights[client, solution[i][j+1]] - cvrp.weights[solution[i][j], solution[i][j+1]]
                    if extra_cost < min_extra_cost
                        min_extra_cost = extra_cost
                        best_route_index = i
                        best_position_index = j
                    end
                end
            end
            i += 1
        end

        # Create a new route
        if best_route_index === nothing
            push!(solution, [1, client, 1])
            push!(vehicle_loads, cvrp.demand[client])
            # Insert the client in the best position
        else
            insert!(solution[best_route_index], best_position_index, client)
            vehicle_loads[best_route_index] += cvrp.demand[client]
        end
    end

    # Apply 2-opt heuristic to improve routes
    Opt2!(cvrp, solution)

    return solution
end

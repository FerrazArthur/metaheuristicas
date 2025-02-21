include("cvrp.jl")

"""
    Input: genitores 1 e 2
    Realiza uma mistura entre os valores de g1 e g2 para gerar um novo indivíduo
    que será sobrescrito em g1
"""
# parametrized uniform crossover
function crossover!(g1, g2; CH=0.7)
    mask = rand(length(g1)) .< CH  # Generate a boolean mask based on CH
    g1 .= mask .* g1 .+ .!mask .* g2  # Apply crossover
end

"""
    Input: conjunto da população e lista com valores de custo
    de cada individuo.
    Seleciona por roleta dois indivíduos distintos entre a população para serem
    g1 e g2, garantindo que g1 seja uma solução melhor que g2
    Return: g1, g2, dois genitores selecionados
"""
function selecao!(populacao, custos, elite_tax)
    roleta_elite = custos[1:elite_tax]/sum(custos[1:elite_tax])
    roleta_elite = cumsum(roleta_elite[:])

    roleta_full = custos[:]/sum(custos[:])
    roleta_full = cumsum(roleta_full[:])

    g1 = similar(populacao[1, :])
    g2 = similar(populacao[1, :])
    #seleciona g1
    randnum = rand()
    first_found = findfirst(randnum .<= roleta_elite)
    second_found = 0;
    while true
        randnum = rand()
        second_found = findfirst(randnum .<= roleta_full)
        if first_found != second_found
            break
        end
    end

    if custos[first_found] < custos[second_found]
        g1 .= populacao[first_found, :]
        g2 .= populacao[second_found, :]
    else
        g1 .= populacao[second_found, :]
        g2 .= populacao[first_found, :]
    end
    return g1, g2
end

"""
    Input:
        cvrp -> Instância cvrp(do inglês 'Capacitated Vehicle Routing Problem')
        do pacote cvrplib;
        N -> Número de indivíduos na população;
        K -> Quantidade de iterações máxima;
        time_s -> Tempo máximo de execução em segundos;
        limite -> Quantidade máxima de interações subsequentes sem atualização
            do melhor global;
"""
function brkga_route(cvrp::CVRP; N=1000, K=1000, time_s=300, limite=200,
                    elitism_ratio=0.2, mutation_ratio=0.1449275, crossover_bias=0.7)
    contad = limite
    elite_tax = Int(floor(elitism_ratio * N))
    mutation_tax = Int(floor(mutation_ratio * (N - elite_tax)))
    crossover_tax = N - elite_tax - mutation_tax  # Garante que a soma seja N
    num_vehicles = Ref(1)
    if (cvrp.depot != 1)
        print("Depósito não é a primeira cidade")
        return
    end
    if (cvrp.weight_type != "EUC_2D")
        print("Tipo de peso não é EUC_2D")
        return
    end
    if (cvrp.distance != Inf)
        print("Distância não é infinita")
        return
    end
    if (cvrp.service_time != 0)
        print("Tempo de serviço não é 0")
        return
    end

    geni1 = zeros(Float64, cvrp.dimension)
    geni2 = zeros(Float64, cvrp.dimension)

    # Generate initial population
    populacao = Matrix{Float64}(undef, N, cvrp.dimension)
    for i in 1:N
        populacao[i, :] = rand(cvrp.dimension) .+ rand(1:num_vehicles[], cvrp.dimension)
    end

    # Evaluate first population
    custos = [cvrpdist!(cvrp, populacao[i, :], num_vehicles) for i in 1:N]
    ordemCustos = sortperm(custos)
    populacao = populacao[ordemCustos, :]
    custos = custos[ordemCustos]

    melhor = deepcopy(populacao[1, :])
    melhorDist = custos[1]

    startTime = Dates.datetime2epochms(now())

    for k = 1:K
        populacao_anterior = deepcopy(populacao)
        
        # Threads.@threads for n in 1:crossover_tax
        for n in 1:crossover_tax
            local geni1 = similar(populacao[1, :])
            local geni2 = similar(populacao[1, :])
            geni1, geni2 = selecao!(populacao_anterior, custos, elite_tax)
            
            crossover!(geni1, geni2, CH = crossover_bias)
            populacao[N - crossover_tax - mutation_tax + n, :] .= geni1[:]
        end
        
        # introduce mutation using imigration concept
        random_mutations = [rand(cvrp.dimension) .+ rand(1:num_vehicles[]) for _ in 1:mutation_tax]

        # Threads.@threads for n in 1:mutation_tax
        for n in 1:mutation_tax
            populacao[N - mutation_tax + n, :] .= random_mutations[n]
        end
        
        # Evaluate population
        custos = [cvrpdist!(cvrp, populacao[i, :], num_vehicles) for i in 1:N]
        ordemCustos = sortperm(custos)
        populacao = populacao[ordemCustos, :]
        custos = custos[ordemCustos]

        if custos[1] < melhorDist
            melhorDist = custos[1]
            melhor = deepcopy(populacao[1, :])
            contad = limite
        end

        # decoded_melhor = decode_solution!(deepcopy(melhor), cvrp, num_vehicles)
        # cvrpplot(cvrp, decoded_melhor, "Indivíduo com menor trajetoria:")
        # sleep(0.08)
        # println("Menor trajeto até então: ", melhorDist, " metros")

        if contad == 0
            println("Alcançado limite de ", limite, " iterações sem melhora")
            break
        end
        contad -= 1
        if Dates.datetime2epochms(now()) - startTime > time_s * 1000
            println("Alcançado tempo limite de ", time_s, " segundos")
            break
        end
    end
    
    # println("Menor custo encontrado é ", melhorDist - cvrp.optimal, " metros menor que o custo ótimo do problema. (", round((melhorDist - cvrp.optimal) * 100.0 / cvrp.optimal; digits=3), "% de erro)")
    # return melhor
    return melhorDist
end


"""
    Input:
        cvrp -> Instância cvrp(do inglês 'Capacitated Vehicle Routing Problem')
        do pacote cvrplib;
        N -> Número de indivíduos na população;
        K -> Quantidade de iterações máxima;
        time_s -> Tempo máximo de execução em segundos;
        limite -> Quantidade máxima de interações subsequentes sem atualização
            do melhor global;
"""
function brkga_no_route(cvrp::CVRP; N=1000, K=1000, time_s=300, limite=200,
                    elitism_ratio=0.2, mutation_ratio=0.1449275, crossover_bias=0.7)
    contad = limite
    elite_tax = Int(floor(elitism_ratio * N))
    mutation_tax = Int(floor(mutation_ratio * (N - elite_tax)))
    crossover_tax = N - elite_tax - mutation_tax
    if (cvrp.depot != 1)
        print("Depósito não é a primeira cidade")
        return
    end
    if (cvrp.weight_type != "EUC_2D")
        print("Tipo de peso não é EUC_2D")
        return
    end
    if (cvrp.distance != Inf)
        print("Distância não é infinita")
        return
    end
    if (cvrp.service_time != 0)
        print("Tempo de serviço não é 0")
        return
    end

    geni1 = zeros(Float64, cvrp.dimension)
    geni2 = zeros(Float64, cvrp.dimension)

    # Generate initial population
    populacao = Matrix{Float64}(undef, N, cvrp.dimension)
    for i in 1:N
        populacao[i, :] = rand(cvrp.dimension)
    end

    # Evaluate first population
    custos = [cvrpdist_no_route!(cvrp, populacao[i, :]) for i in 1:N]
    ordemCustos = sortperm(custos)
    populacao = populacao[ordemCustos, :]
    custos = custos[ordemCustos]

    melhor = deepcopy(populacao[1, :])
    melhorDist = custos[1]

    startTime = Dates.datetime2epochms(now())
    for k = 1:K
        populacao_anterior = deepcopy(populacao)

        # Threads.@threads for n in 1:crossover_tax
        for n in 1:crossover_tax
            local geni1 = similar(populacao[1, :])
            local geni2 = similar(populacao[1, :])
            geni1, geni2 = selecao!(populacao_anterior, custos, elite_tax)
            
            crossover!(geni1, geni2, CH = crossover_bias)
            populacao[N - crossover_tax - mutation_tax + n, :] .= geni1[:]
        end
        
        # introduce mutation using imigration concept
        random_mutations = [rand(cvrp.dimension) for _ in 1:mutation_tax]

        # Threads.@threads for n in 1:mutation_tax
        for n in 1:mutation_tax
            populacao[N - mutation_tax + n, :] .= random_mutations[n]
        end

        # Evaluate population
        custos = [cvrpdist_no_route!(cvrp, populacao[i, :]) for i in 1:N]
        ordemCustos = sortperm(custos)
        populacao = populacao[ordemCustos, :]
        custos = custos[ordemCustos]

        if custos[1] < melhorDist
            melhorDist = custos[1]
            melhor = deepcopy(populacao[1, :])
            contad = limite
        end

        # decoded_melhor = decode_solution_no_route!(melhor, cvrp)
        # cvrpplot(cvrp, decoded_melhor, "Indivíduo com menor trajetoria:")
        # sleep(0.08)
        # println("Menor trajeto até então: ", melhorDist, " metros")
        if contad == 0
            println("Alcançado limite de ", limite, " iterações sem melhora")
            break
        end
        contad -= 1
        if Dates.datetime2epochms(now()) - startTime > time_s * 1000
            println("Alcançado tempo limite de ", time_s, " segundos")
            break
        end
    end
    
    # println("Menor custo encontrado é ", melhorDist - cvrp.optimal, " metros menor que o custo ótimo do problema. (", round((melhorDist - cvrp.optimal) * 100.0 / cvrp.optimal; digits=3), "% de erro)")
    # return melhor
    return melhorDist
end
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
function selecao!(populacao, custos)
    roleta = custos[:]/sum(custos[:])
    roleta = cumsum(roleta[:])

    g1 = similar(populacao[1, :])
    g2 = similar(populacao[1, :])
    #seleciona g1
    randnum = rand()
    first_found = findfirst(randnum .<= roleta)
    second_found = 0;
    while true
        randnum = rand()
        second_found = findfirst(randnum .<= roleta)
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
        limite -> Quantidade máxima de interações subsequentes sem atualização
            do melhor global;
"""
function genetic(cvrp, min_vehicles; N=10000, K=1000, limite=500,
                    crossover_p=0.70, mutation_p=0.1)
    contad = limite

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
        populacao[i, :] = rand(cvrp.dimension) .+ rand(1:min_vehicles, cvrp.dimension)
    end
    melhor = similar(populacao[1, :])
    melhorDist = Inf

    crossover_tax = Int(round(crossover_p * N))
    mutation_tax = Int(round(mutation_p * N))

    for k = 1:K
        # Evaluate population
        custos = [cvrpdist(cvrp, populacao[i, :], min_vehicles) for i in 1:N]
        ordemCustos = sortperm(custos)
        populacao = populacao[ordemCustos, :]
        custos = custos[ordemCustos]

        melhor = copy(populacao[1, :])
        melhorDist = custos[1]
        
        for n in 1:crossover_tax
            geni1 = similar(populacao[1, :])
            geni2 = similar(populacao[1, :])
            geni1, geni2 = selecao!(populacao, custos)
            
            crossover!(geni1, geni2)
            populacao[N - crossover_tax - mutation_tax + n, :] .= geni1[:]
            custos[N - crossover_tax - mutation_tax + n] =
                                            cvrpdist(cvrp, geni1[:], min_vehicles)

            if (custos[N - crossover_tax - mutation_tax + n] < melhorDist)
                melhor .= geni1[:]
                melhorDist = custos[N - crossover_tax - mutation_tax + n]
                contad = limite
            end
        end
        
        # introduce mutation using imigration concept
        for n in 1:mutation_tax
            populacao[N - mutation_tax + n, :] .=
                rand(cvrp.dimension) .+ rand(1:min_vehicles, cvrp.dimension)
            custos[N - mutation_tax + n] =
                cvrpdist(cvrp, populacao[N - mutation_tax + n, :], min_vehicles)

            if (custos[N - mutation_tax + n] < melhorDist)
                melhor = copy(populacao[N - mutation_tax + n, :])
                melhorDist = custos[N - mutation_tax + n]
                contad = limite
            end
        end

        cvrpplot(cvrp, min_vehicles, melhor, "Indivíduo com menor trajetoria:")
        sleep(0.08)
        println("Menor trajeto até então: ", melhorDist, " metros")
        if contad == 0
            break
        end
        contad -= 1
    end
    
    # println("Menor custo encontrado é ", melhorDist - cvrp.optimal, " metros menor que o custo ótimo do problema. (", round((melhorDist - cvrp.optimal) * 100.0 / cvrp.optimal; digits=3), "% de erro)")
    return melhor
end
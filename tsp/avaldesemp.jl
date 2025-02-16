# Importe a biblioteca necessária para medir o tempo de execução
using Dates
using Random
using Statistics

Random.seed!(1234)
include("AVGen.jl")

function runtest()
    #inicia a instância tsp
    #tsp = readTSPLIB(:kroA100);
    tsp = readTSPLIB(:berlin52);

    # Defina os níveis para cada fator
    tamanhos_populacao = [10, 50, 100]  # níveis para o tamanho da população
    taxas_crossover = [0.2, 0.5, 0.8]  # níveis para a taxa de crossover
    taxas_mutacao = [0.05, 0.1, 0.2]  # níveis para a taxa de mutação
    
    # Crie uma matriz vazia para armazenar os resultados
    resultados = zeros(length(tamanhos_populacao), length(taxas_crossover), length(taxas_mutacao), 6)

    # Execute o algoritmo para cada combinação de fatores
    for (i, tamanho) in enumerate(tamanhos_populacao)
        println("tamanho = ", tamanho)
        #criando população inicial pra todas instâncias de teste
        populacao = zeros(Int, tamanho, tsp.dimension)
        distancias = zeros(Int, tamanho)

        #gerando população inicial aleatóriamente
        for x = 1:tamanho
            populacao[x,:] .= randperm(tsp.dimension)
            distancias[x] = tspdist(tsp, populacao[x, :])
        end

        for (j, crossover) in enumerate(taxas_crossover)
            println("CR = ", crossover)
            for (k, mutacao) in enumerate(taxas_mutacao)
                println("CM = ", mutacao)
                # Inicie a contagem do tempo de execução
                
                # Execute seu algoritmo genético com os parâmetros atuais (tamanho, crossover, mutacao)
                # Obtenha os resultados e armazene na matriz resultados
                media10perf = zeros(Float64, 10)
                media10time= zeros(Float64, 10)
                #tirando 10 resultados para média
                Threads.@threads for x = 1:10
                    println("x = ", x)
                    start_time = now()
                    media10perf[x] = genetic(tsp, copy(populacao), copy(distancias), N=tamanho, CR=crossover, CM=mutacao)
                    media10time[x] = Dates.value(now() - start_time)/1000#resultado em segundos
                end
                resultados[i, j, k, 1] = mean(media10perf)
                resultados[i, j, k, 2] = std(media10perf)
                resultados[i, j, k, 3] = 1.812 * std(media10perf)/ sqrt(10)
                resultados[i, j, k, 4] = mean(media10time)#resultado em segundos
                resultados[i, j, k, 5] = std(media10time)#resultado em segundos
                resultados[i, j, k, 6] = 1.812 * std(media10time)/ sqrt(10)
                
                # Calcule o tempo de execução
            end
        end
    end
    return resultados
end

import Pkg
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Dates")
Pkg.add("Random")
Pkg.add("Statistics")
Pkg.add("Plots")
Pkg.add("Dates")
Pkg.add("CVRPLIB")

Pkg.build()

using CSV, DataFrames, Dates, Random, Statistics, Plots, CVRPLIB
include("BRKGA.jl")
# Definição das instâncias do conjunto T
instancias = ["A-n32-k5", "A-n46-k7", "A-n80-k10", "B-n50-k8", "B-n78-k10"]

# Definição dos parâmetros
elitism_ratio_vals = [0.1, 0.2, 0.3, 0.5]
Crossover_Bias_vals = [0.5, 0.6, 0.7, 0.75, 0.8, 0.85]
mutation_ratio_vals = [0.75, 0.1, 0.125, 0.15, 0.2, 0.3, 0.4]

# Criar DataFrame para armazenar os resultados
resultados = DataFrame(
    Instancia=String[],
    Elitism_ratio=Float64[],
    Mutation_ratio=Float64[],
    Crossover_bias=Float64[],
    Melhor_objetivo=Float64[],
    Media_objetivo=Float64[],
    Desvio_padrao=Float64[]
)

# Executar experimentos para todas as combinações
for instancia in instancias
    println("Executando testes para instância: ", instancia)

    # Carregar instância
    cvrp, _, _ = readCVRPLIB(instancia);

    for elitism_p in elitism_ratio_vals
        for Crossover_bias in Crossover_Bias_vals
            for Mutation_ratio in mutation_ratio_vals
                println("Elitism: $elitism_p | Mutation_ratio: $Mutation_ratio | Crossover_bias: $Crossover_bias")
                melhores_resultados = []
                for _ in 1:10  # Executar 10 vezes para cada configuração
                    melhor_custo = brkga_route(cvrp, elitism_ratio=elitism_p, mutation_ratio=Mutation_ratio, crossover_bias=Crossover_bias)
                    push!(melhores_resultados, melhor_custo)
                end

                # Salvar melhor resultado da configuração
                push!(resultados, (instancia, elitism_p, Mutation_ratio, Crossover_bias, minimum(melhores_resultados), mean(melhores_resultados), std(melhores_resultados)))
                println("Instância: $instancia | elitism: $elitism_p | mutation_ratio: $Mutation_ratio | crossover_bias: $Crossover_bias -> Melhor Custo: $(minimum(melhores_resultados)) | Média: $(mean(melhores_resultados)) | Desvio Padrão: $(std(melhores_resultados))")
            end
        end
    end
end

# Salvar os resultados em um arquivo CSV
CSV.write("resultados_calibracao_route.csv", resultados)

println("🔹 Experimentos concluídos! Resultados salvos em 'resultados_calibracao_route.csv'.")

# Criar DataFrame para armazenar os resultados
resultados = DataFrame(
    Instancia=String[],
    Elitism_ratio=Float64[],
    Mutation_ratio=Float64[],
    Crossover_bias=Float64[],
    Melhor_objetivo=Float64[],
    Media_objetivo=Float64[],
    Desvio_padrao=Float64[]
)

# Executar experimentos para todas as combinações
for instancia in instancias
    println("Executando testes para instância: ", instancia)

    # Carregar instância
    cvrp, _, _ = readCVRPLIB(instancia);

    for elitism_p in elitism_ratio_vals
        for Crossover_bias in Crossover_Bias_vals
            for Mutation_ratio in mutation_ratio_vals

                melhores_resultados = []
                for _ in 1:10  # Executar 10 vezes para cada configuração
                    melhor_custo = brkga_no_route(cvrp, elitism_ratio=elitism_p, mutation_ratio=Mutation_ratio, crossover_bias=Crossover_bias)
                    push!(melhores_resultados, melhor_custo)
                end

                # Salvar melhor resultado da configuração
                push!(resultados, (instancia, elitism_p, Mutation_ratio, Crossover_bias, minimum(melhores_resultados), mean(melhores_resultados), std(melhores_resultados)))
                println("Instância: $instancia | elitism: $elitism_p | mutation_ratio: $Mutation_ratio | crossover_bias: $Crossover_bias -> Melhor Custo: $(minimum(melhores_resultados)) | Média: $(mean(melhores_resultados)) | Desvio Padrão: $(std(melhores_resultados))")
            end
        end
    end
end

# Salvar os resultados em um arquivo CSV
CSV.write("resultados_calibracao_no_route.csv", resultados)

println("🔹 Experimentos concluídos! Resultados salvos em 'resultados_calibracao_no_route.csv'.")
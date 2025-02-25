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

using CSV, DataFrames, Dates, Random, Statistics, Plots, CVRPLIB, Base.Threads
include("BRKGA.jl")

partial_results_file = "partial_result.txt"

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

existing_results = Set()
if isfile(partial_results_file)
    println("Carregando resultados anteriores...")
    open(partial_results_file, "r") do file
        for line in eachline(file)
            m = match(r"Instância: (\S+) \| elitism: ([0-9.]+) \| mutation_ratio: ([0-9.]+) \| crossover_bias: ([0-9.]+) -> Melhor Custo: ([0-9.]+) \| Média: ([0-9.]+) \| Desvio Padrão: ([0-9.]+)", line)
            if m !== nothing
                instancia = m[1]
                elitism_p = parse(Float64, m[2])
                mutation_p = parse(Float64, m[3])
                crossover_b = parse(Float64, m[4])
                melhor = parse(Float64, m[5])
                media = parse(Float64, m[6])
                desvio = parse(Float64, m[7])
                
                push!(existing_results, (instancia, elitism_p, mutation_p, crossover_b))
                push!(resultados, (instancia, elitism_p, mutation_p, crossover_b, melhor, media, desvio))
            end
        end
    end
    println("Resultados carregados.")
end

file_lock = ReentrantLock()

tasks = []

function run_parallel_experiments(instancia, elitism_p, Mutation_ratio, Crossover_bias)
    println("Executando: elitism: $elitism_p | mutation_ratio: $Mutation_ratio | crossover_bias: $Crossover_bias")

    results = Vector{Float64}(undef, 10)

    Threads.@threads for i in 1:10
        try
            cvrp, _, _ = readCVRPLIB(instancia)
            results[i] = brkga_route(cvrp, elitism_ratio=elitism_p, mutation_ratio=Mutation_ratio, crossover_bias=Crossover_bias)
        catch e
            results[i] = Inf
        end
    end


    # Compute statistics
    melhor = minimum(results)
    media = mean(results)
    desvio = std(results)

    return melhor, media, desvio
end



# Executar experimentos para todas as combinações
open(partial_results_file, "a") do file
    for instancia in instancias
        println("Executando testes para instância: ", instancia)

        for elitism_p in elitism_ratio_vals
            for Crossover_bias in Crossover_Bias_vals
                for Mutation_ratio in mutation_ratio_vals
                    if (instancia, elitism_p, Mutation_ratio, Crossover_bias) in existing_results
                        println("Configuração já processada: ($instancia, $elitism_p, $Mutation_ratio, $Crossover_bias) - Pulando...")
                        continue
                    end

                    # Run parallel experiments
                    melhor, media, desvio = run_parallel_experiments(instancia, elitism_p, Mutation_ratio, Crossover_bias)

                    lock(file_lock) do
                        push!(resultados, (instancia, elitism_p, Mutation_ratio, Crossover_bias, melhor, media, desvio))
                        
                        # Escrever no arquivo de texto
                        println(file, "Instância: $instancia | elitism: $elitism_p | mutation_ratio: $Mutation_ratio | crossover_bias: $Crossover_bias -> Melhor Custo: $melhor | Média: $media | Desvio Padrão: $desvio")
                    end

                    println("Instância: $instancia | elitism: $elitism_p | mutation_ratio: $Mutation_ratio | crossover_bias: $Crossover_bias -> Melhor Custo: $melhor | Média: $media | Desvio Padrão: $desvio")
                end
            end
        end
    end
end
CSV.write("resultados.csv", resultados)
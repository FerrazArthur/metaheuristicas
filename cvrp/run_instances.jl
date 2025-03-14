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

partial_results_file = "partial_result_run.txt"

# Definição das instâncias do conjunto T
instancias = [
"A-n32-k5",
"A-n33-k5",
"A-n33-k6",
"A-n34-k5",
"A-n36-k5",
"A-n37-k5",
"A-n37-k6",
"A-n38-k5",
"A-n39-k5",
"A-n39-k6",
"A-n44-k6",
"A-n45-k6",
"A-n45-k7",
"A-n46-k7",
"A-n48-k7",
"A-n53-k7",
"A-n54-k7",
"A-n55-k9",
"A-n60-k9",
"A-n61-k9",
"A-n62-k8",
"A-n63-k9",
"A-n63-k10",
"A-n64-k9",
"A-n65-k9",
"A-n69-k9",
"A-n80-k10",
"B-n31-k5",
"B-n34-k5",
"B-n35-k5",
"B-n38-k6",
"B-n39-k5",
"B-n41-k6",
"B-n43-k6",
"B-n44-k7",
"B-n45-k5",
"B-n45-k6",
"B-n50-k7",
"B-n50-k8",
"B-n51-k7",
"B-n52-k7",
"B-n56-k7",
"B-n57-k7",
"B-n57-k9",
"B-n63-k10",
"B-n64-k9",
"B-n66-k9",
"B-n67-k10",
"B-n68-k9",
"B-n78-k10",
"F-n45-k4",
"F-n72-k4",
"F-n135-k7"
]

otimos = [
"784", 
"661", 
"742", 
"778", 
"799", 
"669", 
"949", 
"730", 
"822", 
"831", 
"937", 
"944", 
"1146", 
"914", 
"1073", 
"1010", 
"1167", 
"1073", 
"1354", 
"1034", 
"1288", 
"1616", 
"1314", 
"1401", 
"1174", 
"1159", 
"1763", 
"672", 
"788", 
"955", 
"805", 
"549", 
"829", 
"742", 
"909", 
"751", 
"678", 
"741", 
"1312", 
"1032", 
"747", 
"707", 
"1153", 
"1598", 
"1496", 
"861", 
"1316", 
"1032", 
"1272", 
"1221", 
"724", 
"237", 
"1162",
]

# Definição dos parâmetros
elitism_ratio = 0.28
Crossover_Bias = 0.1983
mutation_ratio = 0.56

# Criar DataFrame para armazenar os resultados
resultados = DataFrame(
    Instancia=String[],
    Otimo=Float64[],
    Melhor_objetivo=Float64[],
    Media_objetivo=Float64[],
    Desvio_padrao_objetivo=Float64[],
    Melhor_tempo=Float64[],
    Media_tempo=Float64[],
    Desvio_padrao_tempo=Float64[],
    Gap_min=Float64[],
    Gap_medio=Float64[]
)

existing_results = Set()
if isfile(partial_results_file)
    println("Carregando resultados anteriores...")
    open(partial_results_file, "r") do file
        for line in eachline(file)
            m = match(r"Instância: (\S+) \| Otimo: ([0-9.]+) \| Melhor_objetivo: ([0-9.]+) \| Media_objetivo: ([0-9.]+) \| Desvio_padrao_objetivo: ([0-9.]+) \| Melhor_tempo: ([0-9.]+) \| Media_tempo: ([0-9.]+) \| Desvio_padrao_tempo: ([0-9.]+) \| Gap_min: ([0-9.]+) \| Gap_medio: ([0-9.]+)", line)
            if m !== nothing
                instancia = m[1]
                otimo = parse(Float64, m[2])
                melhor = parse(Float64, m[3])
                media = parse(Float64, m[4])
                desvio = parse(Float64, m[5])
                melhor_tempo = parse(Float64, m[6])
                media_tempo = parse(Float64, m[7])
                desvio_tempo = parse(Float64, m[8])
                gap_min = parse(Float64, m[9])
                gap_medio = parse(Float64, m[10])
                
                push!(existing_results, instancia)
                push!(resultados, (instancia, otimo, melhor, media, desvio, melhor_tempo, media_tempo, desvio_tempo, gap_min, gap_medio))
            end
        end
    end
    println("Resultados carregados.")
end

file_lock = ReentrantLock()

function run_experiment(instancia, valor_otimo, elitism_p, mutation_ratio, crossover_bias)
    println("Executando testes para instância: ", instancia)

    results = Float64[]
    results_time = Float64[]

    # retrieve instance from path
    instance_folder = "instances/"
    instance_file = joinpath(instance_folder, instancia * ".vrp")
    cvrp = nothing
    if !isfile(instance_file)
        println("Erro: Arquivo de instância não encontrado: $instance_file")
        return Inf, Inf, Inf, Inf, Inf, Inf
    end
    tasks = [Threads.@spawn begin
        try
            try
                # cvrp = first(readCVRPLIB(instancia))
                cvrp = readCVRP(instance_file);
            catch e
                println("Erro ao carregar instância: $instancia - ", e)
                return Inf, Inf, Inf, Inf, Inf, Inf
            end
            obj, tempo = brkga_route(cvrp, optimum=valor_otimo, limite=5000, 
                                     elitism_ratio=elitism_p, mutation_ratio=mutation_ratio, 
                                     crossover_bias=crossover_bias)
            lock(file_lock) do
                push!(results, obj)
                push!(results_time, tempo)
            end
        catch e
            lock(file_lock) do
                push!(results, Inf)
                push!(results_time, Inf)
            end
        end
    end for _ in 1:5]

    wait.(tasks)

    if isempty(results) || isempty(results_time)
        return Inf, Inf, Inf, Inf, Inf, Inf
    end

    # Estatísticas
    melhor = minimum(results)
    media = mean(results)
    desvio = std(results)
    melhor_tempo = minimum(results_time)
    media_tempo = mean(results_time)
    desvio_tempo = std(results_time)

    return melhor, media, desvio, melhor_tempo, media_tempo, desvio_tempo
end

tasks = []

open(partial_results_file, "a") do file
    for (instancia, otimo) in zip(instancias, otimos)
        if instancia in existing_results
            println("Instância já processada: ($instancia) - Pulando...")
            continue
        end

        otimo = parse(Float64, otimo)
        push!(tasks, Threads.@spawn begin
            println("Executando testes para instância: ", instancia)
            melhor, media, desvio, melhor_tempo, media_tempo, desvio_tempo = run_experiment(instancia, otimo, elitism_ratio, mutation_ratio, Crossover_Bias)

            gap_min = (melhor - otimo) / otimo
            gap_medio = (media - otimo) / otimo

            lock(file_lock) do
                push!(resultados, (instancia, otimo, melhor, media, desvio, melhor_tempo, media_tempo, desvio_tempo, gap_min, gap_medio))
                println(file, "Instância: $instancia | Otimo: $otimo | Melhor_objetivo: $melhor | Media_objetivo: $media | Desvio_padrao_objetivo: $desvio | Melhor_tempo: $melhor_tempo | Media_tempo: $media_tempo | Desvio_padrao_tempo: $desvio_tempo | Gap_min: $gap_min | Gap_medio: $gap_medio")
            end

            println("Instância: $instancia | Otimo: $otimo | Melhor_objetivo: $melhor | Media_objetivo: $media | Desvio_padrao_objetivo: $desvio | Melhor_tempo: $melhor_tempo | Media_tempo: $media_tempo | Desvio_padrao_tempo: $desvio_tempo | Gap_min: $gap_min | Gap_medio: $gap_medio")
        end)
    end
end

# Aguarda todas as execuções terminarem
wait.(tasks)

CSV.write("resultados_run.csv", resultados)
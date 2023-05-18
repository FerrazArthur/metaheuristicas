include("tsp.jl")
include("funcoes-teste.jl")

function partSwarm(f, l, u; dimension=100, nPopulation=50, kIter=20000, Cp=0.2, Cg=0.6, W=0.1)
    #verificando requisitos
    Kmax = floor(0.1*kIter)
    #gerando população aleatoriamente
    currentPop = []
    pos = zeros(Float64, nPopulation, dimension)
    vel = zeros(Float64, nPopulation, dimension)
    best = zeros(Float64, nPopulation, dimension)
    bestG = 0
    for i = 1:nPopulation
        pos[i] .= [rand(l:0.001:u, dimension)]
    end
    #criando vetor utilizado para armazenar crossovers
    crossOver = zeros(Float64,dimension)
    minimo = f(currentPop[1])
    #mutacao = Array{Float64, dimension}
    mutacao = zeros(Float64, dimension)
    Kparada = Kmax
    for k = 1:kIter
        for i = 1:nPopulation
            #criando indivíduo mutado
            #escolhendo três indivíduos distintos entre si e entre o indivíduo i
            escolhas = [i]#os escolhidos serão os índices 2, 3 e 4
            for j = 1:4
                append!(escolhas, rand((1:nPopulation)[1:nPopulation .∉ [escolhas]]))  
            end
            #garantindo que a mutação não saia do domínio do problema
            for j = 1:dimension
                mutacao[j] = max(l, min(u, currentPop[escolhas[2]][j] + ((Fmax-Fmin)*rand() + Fmin)*currentPop[escolhas[3]][j]-currentPop[escolhas[4]][j]))
            end

            #realizando cross-over entre i e o mutado
            #escolha de índice aleatório para garantir crossOver != currentPop
            randInd = rand(1:dimension)
            randVal = 0
            for j = 1:dimension
                randVal = rand()
                crossOver[j] = (randVal <= CR || randInd == j) ? mutacao[j] : currentPop[i][j]
            end

            #se o crossOver tiver melhor performance, substituirá o individuo atual.
            if f(crossOver[:]) <= f(currentPop[i][:])
                currentPop[i][:] .= crossOver[:]
                Kparada = Kmax
            end
        end
        for i = 1:nPopulation
            loc = f(currentPop[i][:])
            minimo = loc <= minimo ? loc : minimo
        end
        println("Iteração: ", k, " Mínimo: ", minimo)
        Kparada -= 1
        if Kparada == 0
            break
        end
    end

    return currentPop
end


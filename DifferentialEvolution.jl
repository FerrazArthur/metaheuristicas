include("tsp.jl")
include("funcoes-teste.jl")

function diffEvo(f, l, u; dimension=100, nPopulation=1000, kIter=20000, Fmin=0.2, Fmax=0.6, CR=0.1)
    Kmax = max(10, 0.1*kIter)
    #verificando requisitos
    if nPopulation <= 4
        println("População muito pequena. Utilizaremos 5.")
        nPopulation = 5
    end
    if Fmin > Fmax
        println("Fmin nao pode ser maior que Fmax. Utilizaremos valores padrão(0.2 e 0.6).")
        Fmin = 0.2
        Fmax = 0.6
    end
    
    #gerando população aleatoriamente
    currentPop = []
    for i = 1:nPopulation
        append!(currentPop, [rand(l:0.001:u, dimension)])
    end
    #criando vetor utilizado para armazenar crossovers
    crossOver = zeros(Float64,dimension)
    minimo = f(currentPop)
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
                mutacao[j] = max(l, min(u, getindex(currentPop, escolhas[2])[j] + ((Fmax-Fmin)*rand() + Fmin)*(getindex(currentPop, escolhas[3])[j]-getindex(currentPop, escolhas[3])[j])))
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
                kParada = Kmax
            end
        end
        for i = 1:dimension
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


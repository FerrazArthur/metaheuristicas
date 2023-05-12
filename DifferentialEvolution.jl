include("tsp.jl")
include("funcoes-teste.jl")

function diffEvo(f, l<:Float64, u<:Float64; dim = 3, nPopulation = 4, Fmin=0.2, Fmax=0.6)
    #verificando requisitos
    if nPopulation < 4
        println("População muito pequena. Utilizaremos 4.")
        nPopulation = 4
    end
    if Fmin > Fmax
        println("Fmin nao pode ser maior que Fmax. Utilizaremos valores padrão(0.2 e 0.6).")
        Fmin = 0.2
        Fmax = 0.6
    end
    
    #gerando população aleatoriamente
    currentPop = []
    for i = 1:nPopulation
        append!(currentPop, [rand(l:0.001:u, dim)])
    end
    mutacao = Array{Float64, dim}
    for i = 1:nPopulation

    #calculando mutações
        #escolhendo três indivíduos distintos entre si e entre o indivíduo i
        escolhas = [i]#os escolhidos serão os índices 2, 3 e 4
        for j = 1:4
            append!(escolhas, rand((1:nPopulation)[1:nPopulation .∉ [escolhas]]))  
        end
        for j = 1:dim
            mutação[j] = max(l, min(u, currentPop[escolhas[2]] + ((Fmax-Fmin)*rand() + Fmin)*(currentPop[escolhas[3]]-currentPop[escolhas[4]])))
        end

    end
    println(currentPop)

    return currentPop
end


include("tsp.jl")
include("funcoes-teste.jl")

function partSwarm(f, l, u; dimension=100, nPopulation=50, kIter=20000, Cp=2.05, Cg=2.05, W=0.7, Vmax = 1, VmaxCalibr=true)
    if VmaxCalibr == true
        Vmax = min(Vmax, (u-l)/sqrt(nPopulation))
    end
    Kmax = floor(0.1*kIter)

    #gerando população inicial
    pos = zeros(Float64, nPopulation, dimension)
    vel = zeros(Float64, nPopulation, dimension)
    best = zeros(Float64, nPopulation, dimension)
    bestG = 1
    #inicializando os vetores
    for i = 1:nPopulation
        for j = 1:dimension
            pos[i, j] = (u-l)*rand()+l
            best[i, j] = pos[i, j]
            vel[i, j] = 2*Vmax*rand()-Vmax
        end
    end

    Kparada = Kmax
    for k = 1:kIter
        for i = 1:nPopulation
            #atualiza melhores individuos de cada posição
            if f(pos[i, :]) <= f(best[i, :]) 
                best[i, :] .= pos[i, :]
            end
            #atualiza melhor global
            if f(pos[i, :]) <= f(best[bestG, :])
                Kparada = Kmax
                bestG = i
            end
            #gera valores aleatórios para peso do melhor global e melhor local no calculo de v
            Rg = rand(dimension)
            Rp = rand(dimension)
            for j = 1:dimension
                vel[i, j] = W*vel[i, j] + Cp*Rp[j]*(best[i, j] - pos[i, j]) + Cg*Rg[j]*(best[bestG, j] - pos[i, j])
                #garante que velocidade não fuja dos limites estabelecidos
                vel[i, j] = max(-Vmax, min(Vmax, vel[i, j]))
            end
            #andando com a população
            pos[i, :] .= pos[i, :] + vel[i, :]
            #garantindo que as posições dos pontos nao fujam dos limites
            for j = 1:dimension
                pos[i, j] = max(l, min(u, pos[i, j]))
            end
        end
        println("Iteração: ", k, " Mínimo: ", f(best[bestG, :]))
        Kparada -= 1
        if Kparada == 0
            break
        end
    end

    return pos[bestG, :]
end


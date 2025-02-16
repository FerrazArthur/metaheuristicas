include("tsp.jl")

function antColony(tsp; N=100, K=5, limite=10)
    ro=0.1
    alfa = 1
    beta = 5
    contad = limite
    feromonios = zeros(Float64, tsp.dimension, tsp.dimension)

    #definindo valor inicial para feromonios
    soma = 0.0
    for i = 1:tsp.dimension-1
        for j = i+1:tsp.dimension
            soma+=tsp.weights[i, j]
        end
    end
    feromonios .= tsp.dimension/soma
    caminhos = zeros(Int64, N, tsp.dimension)
    naoVisitadas = ones(Bool, tsp.dimension)
    probLocal = zeros(Float64, tsp.dimension)
    melhor = []

    for k = 1:K #para cada iteração
        for n = 1:N # para cada formiga
            i = rand(1:tsp.dimension)#escolha uma cidade de onde partir
            caminhos[n, 1] = i
            naoVisitadas[i] = false

            for cidade = 2:tsp.dimension
                #calculando probabilidades de visitar cidades vizinhas
                probLocal .= feromonios[i, :].^alfa.*tsp.weights[i, :].^-beta#atendar p divisao por zero
                #removendo probabilidade para cidades ja visitadas
                probLocal[naoVisitadas .== false] .= 0

                #criando soma acumulada
                probLocal /= sum(probLocal)
                probLocal = cumsum(probLocal[:])

                #escolhendo caminho
                j = rand()
                i = findfirst(j .<= probLocal)
                #registrando rota
                naoVisitadas[i] = false
                caminhos[n, cidade] = i
            end
            #busca local aqui
            Opt2!(tsp, caminhos[n, :])
            naoVisitadas .= true
        end

        #atualizando feromonios
        feromonios[:] .= (1-ro).*feromonios[:]#evaporando feromonios
        melhorLocal = 1
        custoLocal = 0
        #para cada formiga
        for n = 1:N
            custoLocal = tspdist(tsp, caminhos[n, :])
            if n % 5 == 0
                println("custoLocal=", custoLocal, " metros")
            end
            melhorLocal = (custoLocal < tspdist(tsp, caminhos[melhorLocal, :])) ? n : melhorLocal
            #atualiza os feromonios da rota
            for j = 1:tsp.dimension-1
                feromonios[caminhos[n, j], caminhos[n, j+1]] += 1.0 / custoLocal
                feromonios[caminhos[n, j+1], caminhos[n, j]] += 1.0 / custoLocal
            end
            feromonios[caminhos[n, tsp.dimension], caminhos[n, 1]] += 1.0 / custoLocal
            feromonios[caminhos[n, 1], caminhos[n, tsp.dimension]] += 1.0 / custoLocal
        end
        #reforçando melhorLocal formiga
        custoLocal = tspdist(tsp, caminhos[melhorLocal, :])#custo da melhor formiga

        #atualiza os feromonios da rota
        for j = 1:tsp.dimension-1
            feromonios[caminhos[melhorLocal, j], caminhos[melhorLocal, j+1]] += 1.0 / custoLocal
            feromonios[caminhos[melhorLocal, j+1], caminhos[melhorLocal, j]] += 1.0 / custoLocal
        end
        feromonios[caminhos[melhorLocal, tsp.dimension], caminhos[melhorLocal, 1]] += 1.0 / custoLocal
        feromonios[caminhos[melhorLocal, 1], caminhos[melhorLocal, tsp.dimension]] += 1.0 / custoLocal

        if isempty(melhor)
            melhor = copy(caminhos[melhorLocal, :])
        elseif custoLocal < tspdist(tsp, melhor)
            melhor .= caminhos[melhorLocal, :]
            contad = limite
        end
        #tspplot(tsp, caminhos[melhorLocal, :])
        tspplot(tsp, melhor, "Formiga com menor trajetoria:")
        #sleep(0.08)
        println("Menor trajeto até então: ", tspdist(tsp, melhor), " metros")
        if contad == 0
            break
        end
        contad -= 1
    end
    println("Menor trajeto encontrado é: ", tspdist(tsp, melhor), " metros")
    println("Menor trajeto encontrado é ", tspdist(tsp, melhor) - tsp.optimal, " metros menor que o trajeto ótimo do problema.(", round((tspdist(tsp, melhor) - tsp.optimal)*100/tsp.optimal; digits = 3),"% de erro)")
    return melhor
end


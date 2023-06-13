include("tsp.jl")
"""
    Input: genitores 1 e 2
    Realiza uma mistura entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function crossover!(g1, g2)
end
"""
    Input: genitores 1 e 2, conjunto da população e lista com valores de aptidão de cada individuo
    Seleciona por roleta dois indivíduos distintos entre a população para serem g1 e g2
"""
function selecao!(g1, g2, populacao, aptidao)
    roleta = aptidao/sum(aptidao)
    roleta = cumsum(roleta)
    #seleciona g1
    randnum = rand()
    g1 .= populacao[findfirst(randnum .<= aptidao), :]
    #seleciona g2, garantindo que seja diferente de g1
    while true
        randnum = rand()
        g2 .= populacao[findfirst(randnum .<= aptidao), :]
        if g2 != g1
            break
        end
    end
end

function mutacao!(individuo)
end

"""
    Input:
        tsp -> Instância tsp(do inglês 'traveling sallesman problem') do pacote tsplib;
        N -> Número de indivíduos na população;
        K -> Quantidade de iterações máxima;
        limite -> Quantidade máxima de interações subsequentes sem atualização
            do melhor global;
        CR -> taxa de crossover;
        CN -> taxa de mutação;

"""
function genetic(tsp, N=500, K=100, limite=10, CR=0.5, CM=0.5)
    contad = limite

    populacao = zeros(Int64, N, tsp.dimension)
    aptidao = zeros(Float64, N)
    geni1 = zeros(Int64, tsp.dimension)
    geni2 = zeros(Int64, tsp.dimension)

    ordemAptidao = collect(1:N)
    melhor = []
    pior = []

    #gerando população inicial aleatóriamente
    for i = 1:N
        populacao[i,:] .=randperm(tsp.dimension)
        aptidao[i] = tspdist(tsp, populacao[i, :])
        return
    end

    for k = 1:K #para cada iteração
        for n = 1:N # para cada indivíduo
     
            #gerando lista ordenada crescente de aptidão entre os indivíduos
            ordemAptidao = sortperm(aptidao)
            
            #selecionando melhor e pior indivíduo
            if isempty(melhor)
                melhor = copy(populacao[ordemAptidao[1], :])
            else
                melhor .= populacao[ordemAptidao[1], :]
            end

            if isempty(pior)
                pior = copy(populacao[ordemAptidao[end], :])
            else
                pior .= populacao[ordemAptidao[end], :]
            end
            
            #seleção de progenitores
            selecao!(geni1, geni2, populacao, aptidao)
            
            #crossover
            if rand() <= CR
                crossover!(geni1, geni2)#ao fim de crossover, geni1 e geni2 serão seus filhos
            end
            #Atualiza o indivíduo atual para o melhor entre geni1 e geni2
            if tspdist(tsp, geni1) < tspdist(tsp, geni2)
                populacao[i, :] .= geni1
                aptidao[i] = tspdist(tsp, geni1)
            else
                populacao[i, :] .= geni2
                aptidao[i] = tspdist(tsp, geni2)
            end

            #mutação
            if rand() <= CM
                mutacao!(populacao[i, :])
            end
            

        end

        melhorLocal = 1
        custoLocal = 0
        #para cada indivíduo
        for n = 1:N
            custoLocal = tspdist(tsp, populacao[n, :])
            if n % 5 == 0 #imprime apenas alguns indivíduos
                println("custoLocal=", custoLocal, " metros")
            end
            melhorLocal = (custoLocal < tspdist(tsp, populacao[melhorLocal, :])) ? n : melhorLocal
        end
        
        #atualiza melhor indivíduo
        custoLocal = tspdist(tsp, populacao[melhorLocal, :])#custo da melhor solução

        if isempty(melhor)
            melhor = copy(populacao[melhorLocal, :])
        elseif custoLocal < tspdist(tsp, melhor)
            melhor .= populacao[melhorLocal, :]
            contad = limite
        end

        #tspplot(tsp, populacao[melhorLocal, :])
        tspplot(tsp, melhor, "Indivíduo com menor trajetoria:")
        #sleep(0.08)
        println("Menor trajeto até então: ", tspdist(tsp, melhor), " metros")
        if contad == 0
            break
        end
        contad -= 1
    end
    println("Menor trajeto encontrado é ", tspdist(tsp, melhor) - tsp.optimal, " metros menor que o trajeto ótimo do problema.(", round((tspdist(tsp, melhor) - tsp.optimal)/tsp.optimal; digits = 3),"% de erro)")
    return melhor
end


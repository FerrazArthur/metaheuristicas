include("tsp.jl")

"""
    Input: genitores 1 e 2
    Realiza uma mistura Partially mapped entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function PMX(g1, g2)
    n = length(g1)
    f1 = zeros(n)
    f2 = zeros(n)

    i = rand(1:n-1)
    j = rand(i+1:n)
    
    f2[i:j] .= g1[i:j]
    f1[i:j] .= g2[i:j]
    #cria uma lista de indices que faltam preencher
    list = []
    if i > 1
        list = collect(1:i-1)
    end
    if j < n
        list = vcat(list, collect(j+1:n))
    end
    #preencheremos os restantes com oque sobrou, garantindo não repetição
    for pos in list
        #preenche f1
        valor = g1[pos]
        while valor ∈ f1
            valor = g2[findfirst(valor .== f1)]
        end
        f1[pos] = valor
        #preenche f2
        valor = g2[pos]
        while valor ∈ f2
            valor = g1[findfirst(valor .== f2)]
        end
        f2[pos] = valor
    end
    #substitui os genitores pelos filhos
    g1.=f1
    g2.=f2
end
"""
    Input: genitores 1 e 2
    Realiza uma mistura Order Crossover entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function OX(g1, g2)
    n = length(g1)
    f1 = zeros(n)
    f2 = zeros(n)

    i = rand(1:n-1)
    j = rand(i+1:n)
    
    f1[i:j] .= g1[i:j]
    f2[i:j] .= g2[i:j]
    #cria uma lista dos indices em ordem, a partir de j+1 até j(formando um ciclo)
    list = []
    if j < n
        list = collect(j+1:n)
    end
    list = vcat(list, collect(1:j))

    #preencheremos os restantes com oque sobrou, garantindo não repetição
    for pos = 1:length(list)
        if pos ∉ i:j
            #preenche f1
            posf1 = pos
            #encontre a primeira ocorrência em g2 que não esteja em f1
            while g2[list[posf1]] ∈ f1[pos]
                posf1 += 1
            end
            f1[pos] = g2[list[posf1]]
            
            #preenche f2
            posf2 = pos
            #encontre a primeira ocorrência em g1 que não esteja em f2
            while g1[list[posf2]] ∈ f2[pos]
                posf2 += 1
            end
            f2[pos] = g1[list[posf2]]
        end
    end
    #substitui os genitores pelos filhos
    g1.=f1
    g2.=f2
end
"""
    Input: lista genitor 1, 2 e filho
    Função auxiliar de CX, realiza a etapa de cycle crossover
"""
function CXaux(g1, g2, f)
    f[1] = g1[1]
    indice = 1
    while true
        #atualiza indice
        indice = g2[f[indice]]
        if g1[indice] ∉ f1
            f[indice] = g1[indice]
        else
            #encontra toda posição que não esta preenchida e a preenche com o equivalente em g2
            list = findall( 0 .== f)
            f[list] .= g2[list]
            break
        end
    end
end
"""
    Input: genitores 1 e 2
    Realiza uma mistura Cycle crossover entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function CX(g1, g2)
    n = length(g1)
    f1 = zeros(n)
    f2 = zeros(n)
    CXaux(g1, g2, f1)
    CXaux(g2, g1, f2)

    #substitui os genitores pelos filhos
    g1.=f1
    g2.=f2
end
"""
    Input: genitores 1 e 2
    Realiza uma mistura entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function crossover!(g1, g2, roletaCross)


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
        #roleta
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
function genetic(tsp, N=500, K=100, limite=10, CR=0.8, CM=0.05)
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


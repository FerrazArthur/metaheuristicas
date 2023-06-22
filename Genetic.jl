include("tsp.jl")

"""
    Input: genitores 1 e 2
    Realiza uma mistura Partially mapped entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function PMX(g1, g2)
    n = length(g1)
    f1 = zeros(Int64, n)
    f2 = zeros(Int64, n)

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
        while valor ∈ f1#usa o mapeamento pra substituir
            valor = f2[findfirst( valor .== f1)]
        end
        f1[pos] = valor

        #preenche f2
        valor = g2[pos]
        while valor ∈ f2
            valor = f1[findfirst(valor .== f2)]
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
    f1 = zeros(Int64, n)
    f2 = zeros(Int64, n)

    i = rand(1:n-1)
    j = rand(i+1:n)
    
    f1[i:j] .= g1[i:j]
    f2[i:j] .= g2[i:j]
    #cria uma lista dos indices em ordem, a partir de j+1 até j(formando um ciclo)
    listg1 = []
    listg2 = []
    if j < n
        listg1 = copy(g1[j+1:n])
        listg2 = copy(g2[j+1:n])
    end
    listg1 = vcat(listg1, g1[1:j])
    listg2 = vcat(listg2, g2[1:j])

    #preencheremos os restantes com oque sobrou, garantindo não repetição
    for pos = 1:n
        if pos ∉ i:j
            #preenche f1
            f1[pos] = listg2[findfirst(listg2 .∉ Ref(f1))]
            #preenche f2
            f2[pos] = listg1[findfirst(listg1 .∉ Ref(f2))]
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
        indice = g2[indice]

        if g1[indice] ∉ f
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
    f1 = zeros(Int64, n)
    f2 = zeros(Int64, n)
    CXaux(g1, g2, f1)
    CXaux(g2, g1, f2)

    #substitui os genitores pelos filhos
    g1.=f1
    g2.=f2
end
"""
    Input: genitores 1 e 2, pesos das funçoes PMX, OX e CX, respectivamente
    Realiza uma mistura entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function crossover!(g1, g2; pesos=[1, 1, 1])
    roleta = pesos/sum(pesos[:])
    roleta = cumsum(roleta[:])
    sorteio = rand()
    sorteio = findfirst(sorteio .<= roleta)
    if sorteio == 1
        PMX(g1, g2)
    elseif sorteio == 2
        OX(g1, g2)
    else
        #CX(g1, g2) ta dando problema, duplicando cidades
    end
end
"""
    Input: genitores 1 e 2, conjunto da população e lista com valores de aptidão de cada individuo
    Seleciona por roleta dois indivíduos distintos entre a população para serem g1 e g2
"""
function selecao!(g1, g2, populacao, aptidao)
    roleta = aptidao[:]/sum(aptidao[:])
    roleta = cumsum(roleta[:])
    #seleciona g1
    randnum = rand()
    randnum = findfirst(randnum .<= roleta)
    g1 .= populacao[randnum, :]
    #seleciona g2, garantindo que seja diferente de g1
    while true
        randnum = rand()
        randnum = findfirst(randnum .<= roleta)
        #roleta
        g2 .= populacao[randnum, :]
        if g2[:] != g1[:]
            break
        end
    end
end

function pbm!(individuo)
    n = length(individuo)
    i = rand(1:n-1)
    j = rand(i+1:n)
    tmp = individuo[i]
    deleteat!(individuo, i)
    insert!(individuo, j, tmp)
end

function obm!(individuo)
    n = length(individuo)
    i = rand(1:n-1)
    j = rand(i+1:n)
    aux = individuo[i]
    individuo[i] = individuo[j]
    individuo[j] = aux
end

function ibm!(individuo)
    n = length(individuo)
    i = rand(1:n-1)
    j = rand(i+1:n)
    reverse!(individuo, i, j)
end

function sbm!(individuo)
    n = length(individuo)
    i = rand(1:n-1)
    j = rand(i+1:n)
    shuffle!(individuo[i:j])
end

function mutacao!(individuo)
    decide = rand(1:4)
    if decide == 1
        pbm!(individuo)
    elseif decide == 2
        obm!(individuo)
    elseif decide == 3
        ibm!(individuo)
    else
        sbm!(individuo)
    end
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

function genetic(tsp; N=1000, K=1000, limite=500, CR=0.6, CM=0.1, sol=[])
    contad = limite

    populacao = zeros(Int64, N, tsp.dimension)
    aptidao = zeros(Float64, N)
    geni1 = zeros(Int64, tsp.dimension)
    geni2 = zeros(Int64, tsp.dimension)

    ordemAptidao = collect(1:N)
    melhor = []

    #gerando população inicial aleatóriamente
    for i = 1:N
        populacao[i,:] .=randperm(tsp.dimension)
        aptidao[i] = tspdist(tsp, populacao[i, :])
    end
    if !isempty(sol)
        populacao[tsp.dimension, :] .= sol[:]
        aptidao[tsp.dimension] = tspdist(tsp, sol[:])
    end
    #atualizando lista ordenada crescente de aptidão entre os indivíduos
    ordemAptidao .= sortperm(aptidao)

    for k = 1:K #para cada iteração
        for n = 1:N # para cada indivíduo
            
            #seleção de progenitores
            selecao!(geni1, geni2, populacao, aptidao)
            #crossover
            if length(unique(geni2)) != length(geni2) || length(unique(geni1)) != length(geni1)
                return
            end
            if rand() <= CR
                crossover!(geni1, geni2)#ao fim de crossover, geni1 e geni2 serão seus filhos
            end
            #Atualiza o indivíduo atual para o melhor entre geni1 e geni2
            if tspdist(tsp, geni1[:]) < tspdist(tsp, geni2[:])
                populacao[n, :] .= geni1[:]
                aptidao[n] = tspdist(tsp, geni1[:])
            else
                populacao[n, :] .= geni2[:]
                aptidao[n] = tspdist(tsp, geni2[:])
            end

            #mutação
            if rand() <= CM
                mutacao!(populacao[n, :])
                aptidao[n] = tspdist(tsp, populacao[n, :])
            end
            
            #atualizando ordem de aptidão entre os indivíduos
            ordemAptidao .= sortperm(aptidao)
        end

        if isempty(melhor)
            melhor = copy(populacao[ordemAptidao[1], :])
        elseif tspdist(tsp, populacao[ordemAptidao[1], :]) < tspdist(tsp, melhor[:])
            melhor .= populacao[ordemAptidao[1], :]
            contad = limite
        end
        #elitismo - mantendo o melhor global na lista
        populacao[ordemAptidao[end], :] .= melhor[:]

        tspplot(tsp, melhor, "Indivíduo com menor trajetoria:")
        #sleep(0.08)
        println("Menor trajeto até então: ", tspdist(tsp, melhor), " metros")
        if contad == 0
            break
        end
        contad -= 1
    end
    println("Menor trajeto encontrado é ", tspdist(tsp, melhor) - tsp.optimal, " metros menor que o trajeto ótimo do problema.(", round((tspdist(tsp, melhor) - tsp.optimal)*100.0/tsp.optimal; digits = 3),"% de erro)")
    return melhor
end


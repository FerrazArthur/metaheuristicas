include("tsp.jl")

"""
    Input: genitores 1 e 2
    Realiza uma mistura Partially mapped entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function PMX(g1, g2)
    n = length(g1)
    f1 = zeros(Int, n)
    f2 = zeros(Int, n)

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
    f1 = zeros(Int, n)
    f2 = zeros(Int, n)

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
    Input: genitores 1 e 2
    Realiza uma mistura Cycle crossover entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function CX(g1, g2)
    n = length(g1)
    f1 = zeros(Int, n)
    f2 = zeros(Int, n)

    #filho 1 identifica ciclo
    p = 1
    while (f1[p] == 0)
        f1[p] = g1[p]
        p = g2[p]
    end
    
    #ciclo gravado nas posições > 0 em filho 1
    ciclo = f1[:] .> 0
    f2[ciclo] .= g2[ciclo]
    
    #posições faltantes
    f1[.!ciclo] .= setdiff(g2[:], f1[ciclo])
    f2[.!ciclo] .= setdiff(g1[:], f2[ciclo])

    g1 .= f1
    g2 .= f2

end
"""
    Input: genitores 1 e 2, pesos das funçoes PMX, OX e CX, respectivamente
    Realiza uma mistura entre os valores de g1 e g2 para gerar duas novas amostras, que serão sobrescritas em g1 e g2
"""
function crossover!(g1, g2; pesos=[0.75, 0.15, 0.1])
#    roleta = pesos/sum(pesos[:])
    roleta = cumsum(pesos[:])
    sorteio = rand()
    sorteio = findfirst(sorteio .<= roleta)
    if sorteio == 1
        PMX(g1, g2)
    elseif sorteio == 2
        OX(g1, g2)
    else
        CX(g1, g2) 
    end
end
"""
    Input: genitores 1 e 2, conjunto da população e lista com valores de aptidão de cada individuo
    Seleciona por roleta dois indivíduos distintos entre a população para serem g1 e g2
"""
function selecao!(g1, g2, populacao, distancias)
    roleta = distancias[:]/sum(distancias[:])
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

function mutacao!(individuo, pesos = [0.05, 0.05, 0.5, 0.4])
    roleta = cumsum(pesos[:])
    decide = rand()
    decide = findfirst(decide .<= roleta)
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

function genetic(tsp, populacao, distancias; N=1000, K=10000, limite=2, CR=0.6, CM=0.1, sol=[])
    contad = limite
    populacaoNova = zeros(Int, N, tsp.dimension)
    distanciasNovas = zeros(Float64, N)
    geni1 = zeros(Int, tsp.dimension)
    geni2 = zeros(Int, tsp.dimension)

    ordemDistancias = collect(1:N)

    melhor = []

    if !isempty(sol)
        populacao[tsp.dimension, :] .= sol[:]
        distancias[tsp.dimension] = tspdist(tsp, sol[:])
    end
    #atualizando lista ordenada crescente de aptidão entre os indivíduos
    ordemDistancias .= sortperm(distancias)
    
    populacaoNova[:, :] .= populacao[:, :]
    distanciasNovas[:] .= distancias[:]

    #definindo a melhor solução inicial
    melhor = copy(populacao[ordemDistancias[1], :])
    melhorDist = tspdist(tsp, melhor[:])


    for k = 1:K #para cada iteração
        for n = 1:N # para cada indivíduo
            #seleção de progenitores
            selecao!(geni1, geni2, populacao, distancias)
            #crossover
            if length(unique(geni2)) != length(geni2) || length(unique(geni1)) != length(geni1)
                return
            end
            if rand() <= CR
                crossover!(geni1, geni2)#ao fim de crossover, geni1 e geni2 serão seus filhos
            end
            #Atualiza o indivíduo atual para o melhor entre geni1 e geni2
            if tspdist(tsp, geni1[:]) < tspdist(tsp, geni2[:])
                populacaoNova[n, :] .= geni1[:]
                distanciasNovas[n] = tspdist(tsp, geni1[:])
            else
                populacaoNova[n, :] .= geni2[:]
                distanciasNovas[n] = tspdist(tsp, geni2[:])
            end

            #mutação
            if rand() <= CM
                mutacao!(populacaoNova[n, :])
                distanciasNovas[n] = tspdist(tsp, populacaoNova[n, :])
            end
            
        end

        #atualizando ordem de menores distancias entre os indivíduos
        ordemDistancias .= sortperm(distanciasNovas)

        #elitismo - mantendo o melhor global na lista
        populacaoNova[ordemDistancias[end], :] .= melhor[:]
        distanciasNovas[ordemDistancias[end]] = melhorDist

        if tspdist(tsp, populacaoNova[ordemDistancias[1], :]) < melhorDist
            melhor .= populacaoNova[ordemDistancias[1], :]
            melhorDist = tspdist(tsp, melhor[:])
            contad = limite
        end
        
        #atualizando população anterior
        #tspplot(tsp, melhor, "Indivíduo com menor trajetoria:")
        populacao[:, :] .= populacaoNova[:, :]
        distancias[:] .= distanciasNovas[:]

        if contad <= 0
            break
        end
        contad -= 1
    end
    return (melhorDist - tsp.optimal)
end

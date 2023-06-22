include("tsp.jl")

function objective(a, b)
	#Testa os valores a e b e retorna true se b for melhor que a, falso do contrário
    dista = 0
    distb = 0
    n = length(a)
    for i = 1:(n-1)
        dista += tsp.weights[a[i], a[i+1]]
        distb += tsp.weights[b[i], b[i+1]]
    end
    dista += tsp.weights[a[1], a[n]]
    distb += tsp.weights[b[1], b[n]]
    
    if distb < dista
		return true
	else 
		return false
	end
end

function imprimirTipo(i, j, tipo)
    #imprime o nome do movimento e as posições envolvidas
    if tipo == 0
        print("SWAP[", i, ", ", j, "]")
    elseif tipo == 1
        print("REVERSÃO[", i, ", ", j, "]")
    elseif tipo == 2
        print("INSERÇÃO[", i, ", ", j, "]")
    end
end

function imprimirBloqueio(i, j, tipo, bloq)
    #caso o movimento esteja bloqueado, imprime seu tipo e quantas iterações faltam pra desbloquear
    if bloq != 0
        #imprime qual operação esta bloqueada
        print("BLOQUEADO: ")
        imprimirTipo(i, j, tipo)
        println(", por mais ",bloq," iterações")
    end
end

function createMoves1d(n)
    #cria lista de movimentos legais
    moves = []
    for i = 1:n-1
        for j = i+1:n
            #swap
            push!(moves, i, j, 0, 0)
            #reversão
            if j - i >= 2
                push!(moves, i, j, 1, 0)
            end
            #inserção
            if j - i >= 1
                push!(moves, i, j, 2, 0)
            end
        end
    end

    #ordena a lista de movimentos para agrupar as diferentes funções
    movFunc = []
    funcoes = []
    #pula de 4 em 4, agrupa os movimentos em listas distintas para depois concatenar elas
    for i = 1:4:length(moves)
        #se o tipo de movimento atual não foi listado ainda, insere ele na lista
        if moves[i+2] ∉ funcoes
            push!(funcoes, moves[i+2])
            push!(movFunc, [])#cria nova lista
            push!(movFunc[length(movFunc)], moves[i], moves[i+1], moves[i+2], moves[i+3])
        else
            #pega o indice da lista desse movimento
            a = findfirst(x -> x == moves[i+2], funcoes)
            push!(movFunc[a], moves[i], moves[i+1], moves[i+2], moves[i+3])
        end
    end
    moves = []
    for i = 1:length(movFunc)
        moves = cat(moves, movFunc[i], dims=1)
    end

    return moves
end

function buscaLocal1d!(tsp, sol, moves, r)
	#essa função explora os movimentos permitidos a partir da solução local, armazena a melhor solução e bloqueia esse movimento
	#percorre as transformações livres
	solLocal = copy(sol)
    iLoc = 0
	x = zeros(typeof(sol[1]),length(solLocal))
	for i = 1:4:length(moves)
		x .= solLocal
		if moves[i+3] == 0
			#analisa qual função deve ser aplicada
			j = moves[i+2]
			if j == 0
				swap!(x, moves[i], moves[i+1])
			elseif j == 1
				reversao!(x, moves[i], moves[i+1])
			elseif j == 2
				insercao!(x, moves[i], moves[i+1])
			else
				println("oops, função nao existe")
			end
			#encontrou uma solução melhor
            if objective(solLocal, x)
				solLocal .= x
				iLoc = i
			end
		end
	end
	if solLocal != sol
        #imprime qual operação foi a melhor
        imprimirTipo(moves[iLoc], moves[iLoc+1], moves[iLoc+2])
        println()

        #bloqueia a transoformação aplicada na melhor solução local
		moves[iLoc+3] = r
		sol .= solLocal
	end
	return sol
end

function createMoves(n)
    #cria lista de movimentos legais
    moves = []
    for i = 1:n-1
        for j = i+1:n
            #swap
            push!(moves, [i, j, 0, 0])
            #reversão
            if j - i >= 2
                push!(moves, [i, j, 1, 0])
            end
            #inserção
            if j - i >= 1
                push!(moves, [i, j, 2, 0])
            end
        end
    end
    #ordena a lista de movimentos para agrupar as diferentes funções
    sort!(moves, by = x -> x[3])
    return moves
end

function tabuSearch1d(tsp, sol, K=200)
    # número de cidades
    n = tsp.dimension
    dist = 0
    
    # solução inicial(randomica)
    #sol=randperm(n)

    #cria tabela de movimentos validos
    moves = createMoves1d(n)

    #define tempo de bloqueio de movimento
    r = minimum([floor(0.1*length(moves)), floor(0.15*K)])

    #realiza a busca tabu
    lim=0
    tspplot(tsp, sol)
    for k = 1:K
        buscaLocal1d!(tsp, sol, moves, r)

        #aspiração
        for i in 1:4:length(moves) 
            moves[i+3]=maximum([0, moves[i+3]-1])
            imprimirBloqueio(moves[i], moves[i+1], moves[i+2], moves[i+3])
        end

        tspplot(tsp, sol)
        #sleep(0.08)
        lim = (dist != tspdist(tsp, sol)) ? 0 : lim + 1
        dist = tspdist(tsp, sol)
        println(dist)
        if lim == floor(0.15*K) || k == K
            lim = k
            break
        end
    end
    #imprime resultado
    println("Custo da solução encontrada (em ",lim ," iterações): ", dist, " metros")
    println("Solução ótima: ", tsp.optimal, " metros")
    println("A diferença é ", dist - tsp.optimal, " metros, oque representa um erro de ",(dist - tsp.optimal)*100/tsp.optimal,"%.")
    println("o valor de r foi: ", r)

end

function config()
    #tsp = readTSPLIB(:berlin52)
    tsp = readTSPLIB(:kroA200)
    sol = randperm(tsp.dimension)
    return tsp, sol
end
#tabuSearch(tsp, sol)
##plotar resposta
#tspplot(tsp, sol)

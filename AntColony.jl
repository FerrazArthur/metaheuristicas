include("tsp.jl")

function antColony!(tsp, sol, N=500, K=100)
    ro=0.1
    alfa = 1
    beta = 5
	feromonios = zeros(Int64, tsp.dimension, tsp.dimension)
    #definindo valor inicial para feromonios
    custo = 0
    for i = 1:tsp.dimension-1
        for j = i+1:tsp.dimension
            soma+=tsp.weights[i, j]
        end
    end
    foromonios[:] .= tsp.dimension/soma

	caminhos = zeros(Int64, N, tsp.dimension)
    naoVisitadas = ones(Bool, tsp.dimension)
    probLocal = zeros(tsp.dimension)
	for k = 1:K #para cada iteração
		for n = 1:N # para cada formiga
           cidade = 1
           i = rand(1:tsp.dimension)#escolha uma cidade de onde partir
           while !isempty(filter(n --> n == true, naoVisitadas))#para cada cidade nao visitada
               naoVisitadas[i] = false
               #calculando probabilidades de visitar cidades vizinhas
               probLocal .= feromonios[i, :].^alf.*tsp.weights[i, :].^beta
               #removendo probabilidade para cidades ja visitadas
               probLocal[naoVisitadas .== false] .= 0
               #criando soma acumulada
               probLocal /= sum(probLocal)
               probLocal = cumsum(probLocal)
               #escolhendo caminho
               j = rand()
               j = findfirst(j .<= probLocal)
               i = j
               #registrando rota
               caminhos[n, cidade] = i
               cidade += 1
           end
#busca local aqui
           naoVisitadas .= 1 
		end

        #atualizando feromonios
        #evaporando feromonios
        feromonios .= (1-ro).*feromonios
        for 
	end
end

function simAnel!(tsp, sol, t0, alfa, maxit, maxitSub)
	moves=[0.05, 0.8, 0.15]
	n = tsp.dimension
	T = t0
	diff = 0
	roleta = cumsum(moves)
	dist = tspdist(tsp, sol)
	solGlob=copy(sol)

	#inicia loop temperatura reduzindo
	for i = 1:maxit
		#inicia loop temperatura constante
		solLoc = zeros(Int64, length(sol))
		for j = 1:maxit
			solLoc .= sol#copia solucao atual
			x = rand()
			x = findfirst(x .<= roleta)
			a = rand(1:length(sol)-1)
			b = rand(a+1:length(sol))
			if x == 1
				swap!(solLoc, a, b)
			elseif x == 2
				reversao!(solLoc, a, b)
			else
				insercao!(solLoc, a, b)
			end
			diff = tspdist(tsp, solLoc) - tspdist(tsp, sol)
			#if diff <= 0 || rand() <= exp(-1*(diff/T))
			if rand() <= exp(-1*(diff/T))
				sol .= solLoc
			end
		end
		solGlob .= (tspdist(tsp, sol) <= tspdist(tsp, solGlob)) ? sol : solGlob
		T *= alfa
		i += 1

		tspplot(tsp, sol)
		sleep(0.08)
		println(tspdist(tsp, sol))
	end
	sol .=solGlob
	tspplot(tsp, sol)
	sleep(0.08)
	println(tspdist(tsp, sol))
end

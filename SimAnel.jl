include("tsp.jl")


function simAnel!(tsp, t0, alfa, maxit, maxitSub; sol=[])
	moves=[0.05, 0.8, 0.15]
	n = tsp.dimension
	T = t0
	diff = 0
	roleta = cumsum(moves)
	dist = tspdist(tsp, sol)
    if isempty(sol)
        sol = copy(randperm(n))
    end
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
    return sol
end

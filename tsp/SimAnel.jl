include("tsp.jl")


function simAnel!(tsp, t0, alfa, maxit, maxitSub; sol=[], limite=50)
	moves=[0.05, 0.8, 0.15]
	n = tsp.dimension
	T = t0
	diff = 0
    contad = limite
	roleta = cumsum(moves)
    if isempty(sol)
        sol = copy(randperm(n))
    end
	dist = tspdist(tsp, sol)
	solGlob=copy(sol)

	#inicia loop temperatura reduzindo
	for i = 1:maxit
		#inicia loop temperatura constante
		solLoc = zeros(Int64, length(sol))
		for j = 1:maxitSub
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
		#solGlob .= (tspdist(tsp, sol) <= tspdist(tsp, solGlob)) ? sol : solGlob
        if tspdist(tsp, sol) <= tspdist(tsp, solGlob)
            solGlob .= sol
            contad = limite
        end
		T *= alfa
		i += 1

        contad-=1
        if(contad <= 0)
            break
        end
		tspplot(tsp, sol)
		sleep(0.08)
		println(tspdist(tsp, sol))
	end
	sol .=solGlob
	tspplot(tsp, sol)
	sleep(0.08)
	println("Solução encontrada: ", tspdist(tsp, sol), "metros")
    println("Solução ótima: ", tsp.optimal, " metros")
    println("A diferença é ", tspdist(tsp, sol) - tsp.optimal, " metros, oque representa um erro de ",         (tspdist(tsp, sol)- tsp.optimal)*100/tsp.optimal,"%.")
 
    return sol
end

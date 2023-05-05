# metaheuristicas
Repositório com metaheuristicas escritas em Julia para disciplina optativa

### TUTORIAL

- Instale o cliente Julia

- Instale o pacote TSPLIB para Julia

- Execute o Julia 

> include("[nome do arquivo"*.jl"]")

> tsp = readTSPLIB([nome do modelo tsp])#exemplo-> :berlin52

- se preciso, use uma solução randomica com:

> sol = randperm(tsp.dimension)

- Execute as metaheuristicas de acordo com a implementação.(passe copy(sol) como parâmetro para as funções que terminem em !, pois elas alteram o valor local.

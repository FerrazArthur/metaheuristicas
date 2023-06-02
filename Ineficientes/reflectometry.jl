include("tsp.jl")
##########################################
#MetaHeuristica baseada em reflectometria no dom. tempo
#Escolher uma cidade inicial randomicamente
#Enviar mensagem a todas as vizinhas, contendo a distancia entre elas, uma referencia a si proprio seguida de outra pra vizinha
#Distribuir essas mensagens em uma fila ordenada por distancia
#Decrementar essa distancia x unidades a cada iteração
#Verificar a fila em busca de uma distancia zero
#Encontrou, indentifique qual a ultima cidade da mensagem e faça:
#   Se todas as cidades estão na mensagem, pare a execução e retone essa rota.
#   Se não, para cada cidade vizinha a essa que já não esteja na mensagem: crie uma nova mensagem com ela no fim e a distancia entre as duas no início.
#   descarte a mensagem.
##########################################


function reflectoMessage(tsp)
    n = tsp.dimension
    maxIt = factorial(big(n))
    it = 1
    #sorteia uma cidade como origem
    cidadeOrigem = rand(1:tsp.dimension)
    #inicia fila de mensagem
    mensagemList = [[0, cidadeOrigem]]
    proxRefList = 1
    while it < maxIt
        #pega o sinal a ser refletido
        mensagem = copy(mensagemList[proxRefList])#pega mensagem para propagar
        lista = mensagem[2:end]#lista com cidade, sem a distancia no inicio
        #remove ele da lista
        deleteat!(mensagemList, proxRefList)#remove origem de propagação da lista de mensagens

        #se mensagem tiver completa com todas cidades, encerra algoritmo
        if length(lista) == n
            println("distancia encontrada - distancia ótima: ", tspdist(tsp, lista[:])-tsp.optimal)
            tspplot(tsp, lista[:])
            return lista[:]
        end

        #guarda a cidade final da mensagem "recebida"
        origemAtual = lista[end]#indice da ultima cidade na mensagem

        #para cada cidade que ainda não esteja na lista de reflexões da mensagem recebida:
        for i in collect(1:n)[1:n .∉ [lista]]
            #adiciona na lista de propagações um vetor com a distancia até a prox cidade e a nova lista de cidades
            append!(mensagemList, [vcat(tsp.weights[origemAtual, i], lista[:], i)])
        end

        #encontra a próxima mensagem que será refletida
        tempArray, proxRefList = findmin(mensagemList)
        tempArray = tempArray[1]#se livra do restante do array, pois só a distância é relevante.

        #atualiza a distância de cada mensagem até seu destino, reduzindo-as à distância da proxima mensagem.
        for i = 1:length(mensagemList)
            mensagemList[i][1] -= tempArray
        end
        it += 1
    end
end

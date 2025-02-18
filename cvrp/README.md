# metaheuristicas
Repositório com metaheuristicas escritas em Julia para disciplina optativa

### TUTORIAL

- Instale o cliente Julia

- Execute o Julia  
- Instale o pacote CVRPLIB para Julia  
    - in julia terminal, type:
    ```bash
    ]add CVRPLIB
    ```

- Instale o pacote Plots  
    - in julia terminal, type:
    ```bash
    ]add Plots
    ```

- Inclua o código 
    ```bash
    include("nome do arquivo".jl")
    ```
    > Devido à abordagem lazy para resolução de dependências, as duas ou três primeiras
    > Tentativas darão erro: apenas insista e será resolvido.

- Adicione uma instancia 
    ```bash
    cvrp, _, _ = readCVRPLIB([nome do modelo cvrp]) # exemplo "A-n46-k7" 
    ```

- Execute
    ```julia
    brkga_route(cvrp);
    brkga_no_route(cvrp); # another implementation that doest encode route
    ```

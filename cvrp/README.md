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

- Adicione o seu codigo  
    ```bash
    include("nome do arquivo".jl")
    ```
- Adicione uma instancia 
    ```bash
    cvrp = readCVRPLIB([nome do modelo cvrp]) exemplo 
    ```
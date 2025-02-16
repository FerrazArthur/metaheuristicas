###################################################
# FUNÇÃO PARA PLOTAR SOLUÇÕES DO CVRP
#
# Adaptado por: Arthur Ferraz
# Baseado em código de Leonardo D. Secchin
# Data: 09/02/2025
###################################################

using Plots
using Random

function cvrpplot(cvrp, min_vehicles, solution, title="")
    # Número de cidades (excluindo o depósito)
    n = cvrp.dimension - 1
    solution = decode_solution(solution, min_vehicles, cvrp.demand, cvrp.capacity)
    # Coordenadas mínimas e máximas
    xmin = minimum(cvrp.coordinates[:,1])
    xmax = maximum(cvrp.coordinates[:,1])
    ymin = minimum(cvrp.coordinates[:,2])
    ymax = maximum(cvrp.coordinates[:,2])
    
    # Adiciona 5% de margem
    folga = 0.05 * max(xmax - xmin, ymax - ymin)
    
    # Configuração da figura
    fig = plot(title = cvrp.name * "\n" * title, 
               xlims = (xmin - folga, xmax + folga), 
               ylims = (ymin - folga, ymax + folga), 
               aspect_ratio = :equal, 
               leg = false)
    
    # Plota as cidades (clientes)
    for i = 2:(n + 1)
        fig = scatter!([cvrp.coordinates[i,1]], [cvrp.coordinates[i,2]], color = "red", mark = :o, markersize = 3)
    end
    
    # Plota o depósito
    fig = scatter!([cvrp.coordinates[1,1]], [cvrp.coordinates[1,2]], color = "blue", mark = :square, markersize = 5, label = "Depósito")
    
    # Plota as rotas dos veículos
    colors = distinguishable_colors(length(solution))
    for (idx, route) in enumerate(solution)
        for i in 1:(length(route) - 1)
            fig = plot!([cvrp.coordinates[route[i],1], cvrp.coordinates[route[i+1],1]], 
                        [cvrp.coordinates[route[i],2], cvrp.coordinates[route[i+1],2]], 
                        color = colors[idx], lw = 1.5)
        end
        # Conectar o último ponto ao depósito
        fig = plot!([cvrp.coordinates[route[end],1], cvrp.coordinates[1,1]], 
                    [cvrp.coordinates[route[end],2], cvrp.coordinates[1,2]], 
                    color = colors[idx], lw = 1.5)
    end
    
    display(fig)
end

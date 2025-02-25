import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Carregar os dados
file_path = "resultados_ordenados.ods"  # Substitua pelo caminho correto
df = pd.read_excel(file_path, engine="odf")

# Converter tipos numéricos para evitar erros
df["Elitism_ratio"] = df["Elitism_ratio"].astype(float)
df["Mutation_ratio"] = df["Mutation_ratio"].astype(float)
df["Crossover_bias"] = df["Crossover_bias"].astype(float)
df["Media_objetivo"] = df["Media_objetivo"].astype(float)
df["Desvio_padrao"] = df["Desvio_padrao"].astype(float)

# Obter todas as instâncias únicas
instancias = df["Instancia"].unique()

# Criar gráficos separados para cada instância
for instancia in instancias:
    df_instancia = df[df["Instancia"] == instancia]
    
    fig, axes = plt.subplots(1, 3, figsize=(18, 6))
    fig.suptitle(f"Análise de Parâmetros para Instância {instancia}", fontsize=14)
    
    # Boxplot do Elitism Ratio
    sns.boxplot(ax=axes[0], x="Elitism_ratio", y="Media_objetivo", data=df_instancia, palette="coolwarm")
    axes[0].set_title("Influência do Elitism Ratio na Média do Objetivo")
    axes[0].set_xlabel("Elitism Ratio")
    axes[0].set_ylabel("Média do Objetivo")
    axes[0].tick_params(axis='x', rotation=45)
    
    # Gráfico de tendência da Taxa de Mutação
    sns.lineplot(ax=axes[1], x="Mutation_ratio", y="Media_objetivo", data=df_instancia, marker="o", palette="viridis")
    axes[1].set_title("Influência da Taxa de Mutação na Média do Objetivo")
    axes[1].set_xlabel("Mutation Ratio")
    axes[1].set_ylabel("Média do Objetivo")
    axes[1].tick_params(axis='x', rotation=45)
    
    # Heatmap de correlação
    corr_matrix = df_instancia[["Elitism_ratio", "Mutation_ratio", "Crossover_bias", "Media_objetivo"]].corr()
    sns.heatmap(ax=axes[2], data=corr_matrix, annot=True, cmap="coolwarm", linewidths=0.5)
    axes[2].set_title("Correlação entre Parâmetros e Média do Objetivo")
    
    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.show()


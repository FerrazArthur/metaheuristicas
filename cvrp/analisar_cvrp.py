import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# Carregar os dados
file_path = "resultados_ordenados.ods"  # Substitua pelo caminho correto
df = pd.read_excel(file_path, engine="odf")

# Converter tipos numéricos para evitar erros
df["Elitism_ratio"] = df["Elitism_ratio"].astype(float)
df["Mutation_ratio"] = df["Mutation_ratio"].astype(float)
df["Crossover_bias"] = df["Crossover_bias"].astype(float)
df["Media_objetivo"] = df["Media_objetivo"].astype(float)
df["Desvio_padrao"] = df["Desvio_padrao"].astype(float)

# Criar um boxplot para visualizar a influência dos parâmetros por instância
plt.figure(figsize=(12, 6))
sns.boxplot(x="Elitism_ratio", y="Media_objetivo", hue="Instancia", data=df, palette="coolwarm")
plt.title("Influência do Elitism Ratio na Média do Objetivo")
plt.xlabel("Elitism Ratio")
plt.ylabel("Média do Objetivo")
plt.legend(title="Instância")
plt.xticks(rotation=45)
plt.show()

# Criar um gráfico de tendência para ver a evolução da Média do Objetivo por parâmetro
plt.figure(figsize=(12, 6))
sns.lineplot(x="Mutation_ratio", y="Media_objetivo", hue="Instancia", data=df, marker="o", palette="viridis")
plt.title("Influência da Taxa de Mutação na Média do Objetivo")
plt.xlabel("Mutation Ratio")
plt.ylabel("Média do Objetivo")
plt.legend(title="Instância")
plt.xticks(rotation=45)
plt.show()

# Criar um heatmap de correlação para ver quais parâmetros influenciam mais
plt.figure(figsize=(10, 6))
corr_matrix = df[["Elitism_ratio", "Mutation_ratio", "Crossover_bias", "Media_objetivo"]].corr()
sns.heatmap(corr_matrix, annot=True, cmap="coolwarm", linewidths=0.5)
plt.title("Correlação entre Parâmetros e Média do Objetivo")
plt.show()


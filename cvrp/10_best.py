import pandas as pd

# Carregar os dados
file_path = "resultados_ordenados.ods"  # Substitua pelo caminho correto
df = pd.read_excel(file_path, engine="odf")

# Converter tipos numéricos para evitar erros
df["Elitism_ratio"] = df["Elitism_ratio"].astype(float)
df["Mutation_ratio"] = df["Mutation_ratio"].astype(float)
df["Crossover_bias"] = df["Crossover_bias"].astype(float)
df["Media_objetivo"] = df["Media_objetivo"].astype(float)
df["Desvio_padrao"] = df["Desvio_padrao"].astype(float)

# Obter as 10 melhores combinações para cada instância
df_top10 = df.groupby("Instancia").head(10)

# Criar uma tabela pivotada para exibição lado a lado
df_top10["Index"] = df_top10.groupby("Instancia").cumcount()  # Criar um índice para alinhar os dados
df_pivot = df_top10.pivot(index="Index", columns="Instancia", values=["Elitism_ratio", "Mutation_ratio", "Crossover_bias", "Media_objetivo", "Desvio_padrao"])

# Ajustar nomes das colunas para um formato mais legível
df_pivot.columns = [f"{col[0]}_{col[1]}" for col in df_pivot.columns]
df_pivot.reset_index(drop=True, inplace=True)

# Salvar os resultados em um arquivo CSV para visualização
output_file = "top10_combinacoes.csv"
df_pivot.to_csv(output_file, index=False)
print(f"Arquivo salvo: {output_file}")

# Opcional: Exibir as primeiras linhas do DataFrame
print(df_pivot.head())


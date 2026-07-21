# bronze_to_silver.py

print(spark.conf.get("spark.databricks.unityCatalog.enabled"))

# --- Parámetro único ---
dbutils.widgets.text("collection_name", "pedidos")
collection_name = dbutils.widgets.get("collection_name")

# --- Lectura desde Bronze vía External Location (sin secretos, autenticación automática) ---
bronze_path = f"abfss://gold@stmongo01.dfs.core.windows.net/mongodb/{collection_name}*.json"
df_bronze = spark.read.json(bronze_path)

print(f"Registros leídos de Bronze para '{collection_name}': {df_bronze.count()}")
df_bronze.printSchema()
# bronze_to_silver.py

from pyspark.sql.types import StructType, StructField, StringType, DoubleType, LongType
from pyspark.sql import functions as F
from datetime import datetime
from delta.tables import *

# --- Estatus inicial ---
status = "SUCCESS"
error_message = None

# --- Inicio de try - except - finally para Data Quality Assurance ---
try:

# --- Parámetro único: qué colección procesar ---
    dbutils.widgets.text("collection_name", "orders")
    collection_name = dbutils.widgets.get("collection_name")

# Esquema estricto por colección
SCHEMAS = {
    "orders": StructType([
        StructField("_id", StructType([StructField("$oid", StringType(), True)]), True),
        StructField("order_id", StringType(), True),
        StructField("customer_id", StringType(), True),
        StructField("order_status", StringType(), True),
        StructField("order_purchase_timestamp", StructType([StructField("$date", StringType(), True)]), True),
        StructField("order_approved_at", StructType([StructField("$date", StringType(), True)]), True),
        StructField("order_delivered_carrier_date", StructType([StructField("$date", StringType(), True)]), True),
        StructField("order_delivered_customer_date", StructType([StructField("$date", StringType(), True)]), True),
        StructField("order_estimated_delivery_date", StructType([StructField("$date", StringType(), True)]), True),
        StructField("created_at", StructType([StructField("$date", StringType(), True)]), True),
    ]),
    
    "order_items": StructType([
        StructField("_id", StructType([StructField("$oid", StringType(), True)]), True),
        StructField("order_id", StringType(), True),
        StructField("order_item_id", LongType(), True),
        StructField("product_id", StringType(), True),
        StructField("seller_id", StringType(), True),
        StructField("shipping_limit_date", StructType([StructField("$date", StringType(), True)]), True),
        StructField("price", DoubleType(), True),
        StructField("freight_value", DoubleType(), True),
        StructField("created_at", StructType([StructField("$date", StringType(), True)]), True),
    ]),
    
    "payments": StructType([
        StructField("_id", StructType([StructField("$oid", StringType(), True)]), True),
        StructField("order_id", StringType(), True),
        StructField("payment_sequential", LongType(), True),
        StructField("payment_type", StringType(), True),
        StructField("payment_installments", LongType(), True),
        StructField("payment_value", DoubleType(), True),
        StructField("created_at", StructType([StructField("$date", StringType(), True)]), True),
    ]),
    
    "customers": StructType([
        StructField("_id", StructType([StructField("$oid", StringType(), True)]), True),
        StructField("customer_id", StringType(), True),
        StructField("customer_unique_id", StringType(), True),
        StructField("customer_zip_code_prefix", StringType(), True),
        StructField("customer_city", StringType(), True),
        StructField("customer_state", StringType(), True),
        StructField("created_at", StructType([StructField("$date", StringType(), True)]), True),
    ]),
    
    "reviews": StructType([
        StructField("_id", StructType([StructField("$oid", StringType(), True)]), True),
        StructField("review_id", StringType(), True),
        StructField("order_id", StringType(), True),
        StructField("review_score", LongType(), True),
        StructField("review_comment_title", StringType(), True),
        StructField("review_comment_message", StringType(), True),
        StructField("review_creation_date", StructType([StructField("$date", StringType(), True)]), True),
        StructField("review_answer_timestamp", StructType([StructField("$date", StringType(), True)]), True),
        StructField("created_at", StructType([StructField("$date", StringType(), True)]), True),
    ]),
    
    "products": StructType([
        StructField("_id", StructType([StructField("$oid", StringType(), True)]), True),
        StructField("product_id", StringType(), True),
        StructField("product_category_name", StringType(), True),
        StructField("product_name_lenght", LongType(), True),
        StructField("product_description_lenght", LongType(), True),
        StructField("product_photos_qty", LongType(), True),
        StructField("product_weight_g", DoubleType(), True),
        StructField("product_length_cm", DoubleType(), True),
        StructField("product_height_cm", DoubleType(), True),
        StructField("product_width_cm", DoubleType(), True),
        StructField("created_at", StructType([StructField("$date", StringType(), True)]), True),
    ]),
    
    "sellers": StructType([
        StructField("_id", StructType([StructField("$oid", StringType(), True)]), True),
        StructField("seller_id", StringType(), True),
        StructField("seller_zip_code_prefix", StringType(), True),
        StructField("seller_city", StringType(), True),
        StructField("seller_state", StringType(), True),
        StructField("created_at", StructType([StructField("$date", StringType(), True)]), True),
    ])
}

    if collection_name not in SCHEMAS:
        raise ValueError(f"No hay schema definido para: {collection_name}")

    bronze_schema = SCHEMAS[collection_name]

# --- Lectura con schema enforcement ---
    bronze_path = f"abfss://bronze@stmongo01.dfs.core.windows.net/mongodb/{collection_name}/"

    df_bronze = spark.read \
        .schema(bronze_schema) \
        .json(bronze_path)

# --- Reconciliación: métricas de Bronze ANTES de transformar ---
    df_bronze_metrics = df_bronze.agg(
        F.count("*").alias("total_rows"),
        F.sum("monto").alias("total_monto")
    )
    df_bronze_metrics.createOrReplaceTempView("bronze_metrics")

    bronze_count = df_bronze.count()
    print(f"Bronze: {bronze_count} registros leídos para '{collection_name}'")

# --- Transformación: aplanar structs anidados + limpieza ---
    def transform_pedidos(df):
        return (
            df.select(
                F.col("_id.`$oid`").alias("id"),
                F.col("pedido_id"),
                F.col("user_id"),
                F.col("sku"),
                F.col("monto"),
                F.col("fecha.`$date`").alias("fecha"),
                F.col("created_at.`$date`").alias("created_at"),
            )
            .dropDuplicates(["pedido_id"])
            .filter("monto > 0")
        )

    TRANSFORMATIONS = {
        "pedidos": transform_pedidos,
    }

    df_silver = TRANSFORMATIONS[collection_name](df_bronze)

# --- Validación vía temp view, antes de escribir ---
    df_silver.createOrReplaceTempView("silver_validation")

    row_count = spark.sql("SELECT COUNT(*) as cnt FROM silver_validation").collect()[0]["cnt"]
    null_check = spark.sql("SELECT COUNT(*) as nulls FROM silver_validation WHERE created_at IS NULL").collect()[0]["nulls"]

    if row_count == 0:
        raise ValueError(f"Validación fallida: '{collection_name}' no tiene registros después de la transformación")
    if null_check > 0:
        raise ValueError(f"Validación fallida: '{collection_name}' tiene {null_check} registros con created_at nulo")

    print(f"✅ Validación exitosa: {row_count} registros, 0 nulls en created_at")

# --- Reconciliación: métricas de Silver DESPUÉS de transformar ---
    df_silver_metrics = df_silver.agg(
        F.count("*").alias("total_rows"),
        F.sum("monto").alias("total_monto")
    )
    df_silver_metrics.createOrReplaceTempView("silver_metrics")

    reconciliation = spark.sql("""
        SELECT 
            b.total_rows as bronze_rows, 
            s.total_rows as silver_rows,
            b.total_rows - s.total_rows as rows_diff
        FROM bronze_metrics b, silver_metrics s
    """).collect()[0]

    print(f"Reconciliación — Bronze: {reconciliation['bronze_rows']}, Silver: {reconciliation['silver_rows']}, Diff: {reconciliation['rows_diff']}")

    if reconciliation['rows_diff'] < 0:
        raise ValueError("⚠️ Silver tiene MÁS registros que Bronze — posible duplicación en la escritura")

    target_table_name = f"mongo_migration.silver.{collection_name}"

# --- Crear tabla con liquid cluster ---
    if not spark.catalog.tableExists(target_table_name):
        print(f"🔄 Creando tabla {target_table_name} por primera vez...")
        df_silver.write \
            .format("delta") \
            .clusterBy("created_at", "user_id") \
            .saveAsTable(target_table_name)

# --- Realizar el MERGE (Upsert) ---
    target_table = DeltaTable.forName(spark, target_table_name)

    target_table.alias("target").merge(
        df_silver.alias("source"),
        "target.id = source.id"
    ) \
    .whenMatchedUpdateAll() \
    .whenNotMatchedInsertAll() \
    .execute()

    print(f"✅ Upsert completado exitosamente en '{target_table_name}'")

except Exception as e:
    status = "FAILED"
    error_message = str(e)
    print(f"❌ Error crítico en el pipeline: {error_message}")
    # Relanzamos para que Azure Data Factory marque el Job como fallido
    raise e

# --- Escritura como tabla Delta en Unity Catalog, con Liquid Clustering ---
finally:
    log_schema = StructType([
        StructField("job", StringType(), True),
        StructField("ts", TimestampType(), True),
        StructField("status", StringType(), True),
        StructField("error", StringType(), True)
    ])
    
    log_data = [(collection_name, datetime.now(), status, error_message)]
    log_df = spark.createDataFrame(log_data, schema=log_schema)

    control_path = "abfss://control@stmongo01.dfs.core.windows.net/job_metadata/"

    log_df.write \
        .format("delta") \
        .mode("append") \
        .save(control_path)
    print(f"✅ Metadata guardada en control.job_metadata con estatus: {status}")
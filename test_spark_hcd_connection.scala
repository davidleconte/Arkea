// Script de test connexion Spark → HCD
// Test avec le keyspace test_spark

println("=" * 60)
println("Test de Connexion Spark → HCD")
println("Keyspace: test_spark")
println("=" * 60)

// Configuration de la connexion HCD
spark.conf.set("spark.cassandra.connection.host", "localhost")
spark.conf.set("spark.cassandra.connection.port", "9042")

println("\n✅ Configuration HCD définie")
println("   Host: localhost")
println("   Port: 9042")

// Test 1: Lecture avec l'API DataFrame (SQL)
println("\n📖 Test 1: Lecture avec DataFrame API")
try {
  val df = spark.read
    .format("org.apache.spark.sql.cassandra")
    .options(Map("keyspace" -> "test_spark", "table" -> "users"))
    .load()
  
  println("✅ Connexion réussie avec DataFrame API !")
  println(s"Nombre de lignes: ${df.count()}")
  println("\nDonnées lues depuis HCD:")
  df.show(truncate = false)
  
  // Test d'opérations
  println("\n🔢 Opérations sur les données:")
  val avgAge = df.agg(org.apache.spark.sql.functions.avg("age")).first().getDouble(0)
  println(s"Âge moyen: $avgAge")
  
  val filtered = df.filter("age > 28")
  println(s"Personnes de plus de 28 ans: ${filtered.count()}")
  filtered.show()
  
} catch {
  case e: Exception => 
    println(s"❌ Erreur avec DataFrame API: ${e.getMessage}")
    e.printStackTrace()
}

// Test 2: Lecture avec l'API RDD
println("\n📖 Test 2: Lecture avec RDD API")
try {
  import com.datastax.spark.connector._
  val rdd = sc.cassandraTable("test_spark", "users")
  
  println("✅ Connexion réussie avec RDD API !")
  println(s"Nombre de partitions: ${rdd.getNumPartitions}")
  println(s"Nombre de lignes: ${rdd.count()}")
  
  println("\nPremières lignes:")
  rdd.take(3).foreach(row => {
    println(s"  ID: ${row.getInt("id")}, Name: ${row.getString("name")}, Age: ${row.getInt("age")}, City: ${row.getString("city")}")
  })
  
} catch {
  case e: Exception => 
    println(s"❌ Erreur avec RDD API: ${e.getMessage}")
    e.printStackTrace()
}

// Test 3: Écriture vers HCD
println("\n✍️  Test 3: Écriture vers HCD")
try {
  // Créer un DataFrame avec de nouvelles données
  val newData = Seq(
    (4, "David", 28, "Toulouse"),
    (5, "Eve", 32, "Nice")
  )
  val newDf = spark.createDataFrame(newData).toDF("id", "name", "age", "city")
  
  println("Données à écrire:")
  newDf.show()
  
  // Écrire vers HCD
  newDf.write
    .format("org.apache.spark.sql.cassandra")
    .options(Map("keyspace" -> "test_spark", "table" -> "users"))
    .mode("append")
    .save()
  
  println("✅ Écriture réussie !")
  
  // Vérifier en relisant
  println("\nVérification - Toutes les données:")
  val allDf = spark.read
    .format("org.apache.spark.sql.cassandra")
    .options(Map("keyspace" -> "test_spark", "table" -> "users"))
    .load()
  
  allDf.show(truncate = false)
  
} catch {
  case e: Exception => 
    println(s"❌ Erreur lors de l'écriture: ${e.getMessage}")
    e.printStackTrace()
}

println("\n" + "=" * 60)
println("✅ Tests de connexion terminés !")
println("=" * 60)
println("\n💡 Spark Shell reste ouvert pour exploration")
println("   Tapez ':quit' pour quitter")





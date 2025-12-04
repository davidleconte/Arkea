// Script de test Spark simple
// Utilise la session Spark déjà disponible dans spark-shell

println("=" * 50)
println("Test Spark de Base")
println("=" * 50)

println("\n✅ Spark Session disponible")
println(s"Version Spark: ${spark.version}")

// Test 1: Créer un DataFrame simple
println("\n📊 Test 1: Création d'un DataFrame simple")
val data = Seq(
  ("Alice", 25, "Paris"),
  ("Bob", 30, "Lyon"),
  ("Charlie", 35, "Marseille")
)
val df = spark.createDataFrame(data).toDF("name", "age", "city")
println("✅ DataFrame créé")
df.show()

// Test 2: Opérations sur le DataFrame
println("\n🔢 Test 2: Opérations sur le DataFrame")
val count = df.count()
val avgAge = df.agg(org.apache.spark.sql.functions.avg("age")).first().getDouble(0)
println(s"Nombre de lignes: $count")
println(s"Âge moyen: $avgAge")

// Test 3: Filtrer les données
println("\n🔍 Test 3: Filtrage")
val filtered = df.filter("age > 28")
println("Personnes de plus de 28 ans:")
filtered.show()

println("\n" + "=" * 50)
println("✅ Tests de base terminés avec succès !")
println("=" * 50)

// Test 4: Connexion à HCD
println("\n🔗 Test 4: Test de connexion à HCD")
try {
  spark.conf.set("spark.cassandra.connection.host", "localhost")
  spark.conf.set("spark.cassandra.connection.port", "9042")

  println("Tentative de connexion à HCD...")

  // Utiliser l'API RDD du connector
  import com.datastax.spark.connector._
  val rdd = sc.cassandraTable("system", "local")
  println(s"✅ Connexion réussie ! Nombre de partitions: ${rdd.getNumPartitions}")
  println("Première ligne:")
  rdd.take(1).foreach(row => println(s"  $row"))

} catch {
  case e: Exception =>
    println(s"⚠️  Erreur de connexion: ${e.getMessage}")
    println(s"   Vérifiez que HCD est démarré sur ${sys.env.getOrElse(\"HCD_HOST\", \"localhost\")}:${sys.env.getOrElse(\"HCD_PORT\", \"9042\")}")
}

println("\n💡 Spark Shell reste ouvert pour exploration")
println("   Tapez 'spark' pour accéder à la session")
println("   Tapez ':quit' pour quitter")

// Script de test Spark → HCD
// Test de connexion et lecture depuis HCD

import org.apache.spark.sql.SparkSession
import com.datastax.spark.connector._

println("=" * 50)
println("Test de connexion Spark → HCD")
println("=" * 50)

// Créer la session Spark avec le connector Cassandra
val spark = SparkSession.builder()
  .appName("Test HCD Connection")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .getOrCreate()

println("\n✅ Spark Session créée")
println(s"Version Spark: ${spark.version}")

// Test 1: Lire depuis le keyspace system (table system.local)
println("\n📖 Test 1: Lecture depuis system.local")
try {
  val df = spark.read
    .format("org.apache.spark.sql.cassandra")
    .options(Map("keyspace" -> "system", "table" -> "local"))
    .load()

  println("✅ Connexion réussie !")
  println(s"Nombre de lignes: ${df.count()}")
  println("\nAperçu des données:")
  df.show(truncate = false)
} catch {
  case e: Exception =>
    println(s"❌ Erreur: ${e.getMessage}")
    e.printStackTrace()
}

// Test 2: Lister les keyspaces disponibles
println("\n📋 Test 2: Liste des keyspaces")
try {
  val keyspaces = spark.read
    .format("org.apache.spark.sql.cassandra")
    .options(Map("keyspace" -> "system_schema", "table" -> "keyspaces"))
    .load()

  println("Keyspaces disponibles:")
  keyspaces.select("keyspace_name").show(truncate = false)
} catch {
  case e: Exception =>
    println(s"⚠️  Erreur (peut être normal): ${e.getMessage}")
}

println("\n" + "=" * 50)
println("✅ Tests terminés")
println("=" * 50)

// Garder la session ouverte pour exploration interactive
println("\n💡 Spark Shell reste ouvert pour exploration interactive")
println("   Tapez 'spark' pour accéder à la session")
println("   Tapez ':quit' pour quitter")

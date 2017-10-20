import scalariform.formatter.preferences._
import com.typesafe.sbt.SbtScalariform
import com.typesafe.sbt.SbtScalariform.ScalariformKeys

name := "universal-recommender"

version := "0.6.1"

organization := "com.actionml"

val mahoutVersion = sys.env.getOrElse("PIO_MAHOUT_VERSION","0.13.1")

val pioVersion = sys.env.getOrElse("PIO_VERSION","0.12.0-incubating")

val elasticsearch1Version = sys.env.getOrElse("PIO_ELASTIC_VERSION","1.7.5")

val sparkVersion = sys.env.getOrElse("PIO_SPARK_VERSION","1.4.0")

scalaVersion := sys.env.getOrElse("PIO_SCALA_VERSION","2.11.8")


//val elasticsearch5Version = "5.1.2"
libraryDependencies ++= Seq(
  "org.apache.predictionio" %% "apache-predictionio-core" % pioVersion % "provided",
  "org.apache.predictionio" % "apache-predictionio-data-elasticsearch1_2.11" % "0.11.0-incubating" % "provided",
  "org.apache.spark" %% "spark-core" % sparkVersion % "provided",
  "org.apache.spark" %% "spark-mllib" % sparkVersion % "provided",
  "org.xerial.snappy" % "snappy-java" % "1.1.1.7",
  // Mahout's Spark libs
  "it.unimi.dsi" % "fastutil" % "7.0.12",
  "org.apache.commons" % "commons-math3" % "3.2",
  "com.tdunning" % "t-digest" % "3.1",
  "org.apache.mahout" %% "mahout-math-scala" % mahoutVersion,
  "org.apache.mahout" %% "mahout-spark" % mahoutVersion
    exclude("org.apache.spark", "spark-core_2.11"),
  "org.apache.mahout"  % "mahout-math" % mahoutVersion,
  "org.apache.mahout"  % "mahout-hdfs" % mahoutVersion
    exclude("com.thoughtworks.xstream", "xstream")
    exclude("org.apache.hadoop", "hadoop-client"),
  //"org.apache.hbase"        % "hbase-client"   % "0.98.5-hadoop2" % "provided",
  //  exclude("org.apache.zookeeper", "zookeeper"),
  // other external libs
  "com.thoughtworks.xstream" % "xstream" % "1.4.4"
    exclude("xmlpull", "xmlpull"),
  // possible build for es5 
  //"org.elasticsearch"       %% "elasticsearch-spark-13" % elasticsearch5Version % "provided",
  "org.elasticsearch" % "elasticsearch" % elasticsearch1Version % "provided",
  "org.elasticsearch" % "elasticsearch-spark-20_2.11" % "5.4.1"
    exclude("org.apache.spark", "spark-catalyst_2.11")
    exclude("org.apache.spark", "spark-sql_2.11"),
  "org.json4s" %% "json4s-native" % "3.2.10")
  

resolvers += Resolver.mavenLocal

SbtScalariform.scalariformSettings

ScalariformKeys.preferences := ScalariformKeys.preferences.value
  .setPreference(AlignSingleLineCaseStatements, true)
  .setPreference(DoubleIndentClassDeclaration, true)
  .setPreference(DanglingCloseParenthesis, Prevent)
  .setPreference(MultilineScaladocCommentsStartOnFirstLine, true)

assemblyMergeStrategy in assembly := {
 case PathList("apache", "lucene-core", "util") => MergeStrategy.concat
 case PathList("META-INF", xs @ _*) => MergeStrategy.discard
 case x => MergeStrategy.first
}


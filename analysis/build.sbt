import scala.io.Source

name := "gitrate-analysis"

scalaVersion := "2.11.11"
scalacOptions ++= Seq(
  "-deprecation",
  "-encoding", "UTF-8",
  "-feature",
  "-language:postfixOps",
  "-target:jvm-1.8",
  "-unchecked",
  "-Xexperimental",
  "-Xfuture",
  "-Xlint",
  "-Yno-adapted-args",
  "-Ywarn-adapted-args",
  "-Ywarn-dead-code",
  "-Ywarn-numeric-widen",
  "-Ywarn-unused",
  "-Ywarn-unused-import",
  "-Ywarn-value-discard",
)

val sparkVersion = "2.1.1" // TODO: migrate to 2.2.0

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % sparkVersion,
  "org.apache.spark" %% "spark-sql" % sparkVersion,
  "org.apache.spark" %% "spark-streaming" % sparkVersion,
  "org.postgresql" % "postgresql" % "42.1.4",

  "com.typesafe.play" %% "play-ws-standalone-json" % "1.0.4",

  "org.scalaj" %% "scalaj-http" % "2.3.0",

  "org.scalatest" %% "scalatest" % "3.1.x-6e03d4d77" % Test,
)

dependencyOverrides ++= Seq(
  // https://stackoverflow.com/questions/43841091/spark2-1-0-incompatible-jackson-versions-2-7-6/43845063#43845063
  "com.fasterxml.jackson.core" % "jackson-core" % "2.8.7",
  "com.fasterxml.jackson.core" % "jackson-databind" % "2.8.7",
  "com.fasterxml.jackson.module" %% "jackson-module-scala" % "2.8.7",

  // https://github.com/scalatest/scalatest/issues/1013
  "org.scalatest" %% "scalatest" % "3.1.x-6e03d4d77" % Test,
)

// https://stackoverflow.com/questions/25144484/sbt-assembly-deduplication-found-error/39058507#39058507
assemblyMergeStrategy in assembly := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case x => MergeStrategy.first
}

coverageEnabled in(Test, compile) := true
coverageEnabled in(Compile, compile) := false

scalastyleConfig := baseDirectory.value / "project" / "scalastyle-config.xml"
scalastyleConfig in Test := baseDirectory.value / "project" / "scalastyle-config-test.xml"

//testOptions in Test += Tests.Argument("-oF")
parallelExecution in Test := false

fork in run := true
cancelable in Global := true
javaOptions in run ++= Source.fromFile("conf/jvm.options").getLines.toSeq ++ Seq(
  //"-Dlog4j.debug=true",
  "-Dlog4j.configuration=log4j.properties"
)

outputStrategy := Some(StdoutOutput)

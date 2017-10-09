package analysis

import github.GithubUser

import com.typesafe.config.Config

import org.apache.spark.rdd.RDD
import org.apache.spark.SparkContext
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types.DoubleType
import org.apache.spark.sql.{Dataset, Row, SparkSession}

import java.net.URL

class Grader(val appConfig: Config,
             warningsToGradeCategory: Dataset[WarningToGradeCategory],
             weightedTechnologies: Seq[String])(implicit sparkContext: SparkContext, sparkSession: SparkSession) {

  import sparkSession.implicits._

  def gradeUsers(users: Iterable[GithubUser]): Iterable[GradedRepository] = {
    val resultsByRepository: Map[String, Iterable[GraderResult]] = processUsers(users).groupBy(_.idBase64)
    for {
      (idBase64, results) <- resultsByRepository
      grades = results.map(_.toGrade).toSeq
      tags = results.flatMap(_.tags).toSet
    } yield GradedRepository(idBase64, tags, grades)
  }

  private def processUsers(users: Iterable[GithubUser]): Iterable[GraderResult] = {
    users.flatMap { user: GithubUser =>
      val scriptInput = user.repositories.map { repo =>
        val languages: Set[String] = repo.languages.toSet + repo.primaryLanguage
        makeScriptInput(repo.idBase64, repo.name, user.login, repo.archiveURL, languages)
      }

      val outputMessages: Dataset[AnalyzerScriptResult] = runAnalyzerScript(scriptInput, withCleanup = true)
      processAnalyzerScriptResults(outputMessages)
    }
  }

  def makeScriptInput(repoIdBase64: String,
                      repoName: String,
                      login: String,
                      archiveURL: URL,
                      languages: Set[String]): String =
    s"$repoIdBase64;$repoName;$login;$archiveURL;${languages.mkString(",")}"

  def runAnalyzerScript(scriptInput: Seq[String], withCleanup: Boolean): Dataset[AnalyzerScriptResult] = {
    val scriptInputRDD: RDD[String] = sparkContext.parallelize(scriptInput)

    val maxTimeToRun = s"${maxExternalScriptDuration.getSeconds}s"
    val timeLimitedRunner = List(s"$scriptsDirectory/runWithTimeout.sh", maxTimeToRun)

    val sandboxRunner = List("firejail", "--quiet", "--blacklist=/home", s"--whitelist=$scriptsDirectory")

    val scriptArguments = List(s"$maxRepoArchiveSizeBytes", s"$withCleanup")
    val script = s"$scriptsDirectory/downloadAndAnalyzeCode.sh" :: scriptArguments

    val command: List[String] = timeLimitedRunner ++ sandboxRunner ++ script

    val scriptOutputFields = 4
    scriptInputRDD
      .pipe(command)
      .map(_.split(";"))
      .filter(_.length == scriptOutputFields)
      .map { case Array(idBase64, language, messageType, message) => (idBase64, language, messageType, message) }
      .toDF("idBase64", "language", "messageType", "message")
      .as[AnalyzerScriptResult]
  }

  def processAnalyzerScriptResults(outputMessages: Dataset[AnalyzerScriptResult]): Iterable[GraderResult] = {
    outputMessages.cache()

    val zero = lit(literal = 0.0)
    val one = lit(literal = 1.0)
    val results: Dataset[PartialGraderResult] = warningCounts(outputMessages)
      .join(linesOfCode(outputMessages), $"idBase64" === $"idBase64_" && $"language" === $"language_")
      .drop("idBase64_", "language_")
      .join(dependencies(outputMessages), $"idBase64" === $"idBase64_" && $"language" === $"language_")
      .distinct
      .select(
        $"idBase64",
        $"language",
        $"dependencies",
        $"gradeCategory",
        $"warningsPerCategory".cast(DoubleType) as "warningsPerCategory",
        $"linesOfCode".cast(DoubleType) as "linesOfCode"
      )
      .select(
        $"idBase64",
        $"language",
        $"dependencies",
        $"gradeCategory",
        greatest(
          zero,
          one - ($"warningsPerCategory" / $"linesOfCode")
        ) as "value"
      )
      .drop("language")
      .groupBy($"idBase64", $"gradeCategory", $"dependencies")
      .agg(avg($"value") as "value")
      .as[PartialGraderResult]

    results.show(truncate = false)
    results
      .collect()
      .map(_.toGraderResult(weightedTechnologies))
  }

  private def linesOfCode(outputMessages: Dataset[AnalyzerScriptResult]): Dataset[Row] =
    outputMessages
      .filter($"messageType" === "lines_of_code")
      .select($"idBase64" as "idBase64_", $"language" as "language_", $"message" as "linesOfCode")

  private def dependencies(outputMessages: Dataset[AnalyzerScriptResult]): Dataset[Row] =
    outputMessages
      .select($"idBase64", $"language", $"message")
      .filter($"messageType" === "dependence")
      .groupBy($"idBase64", $"language")
      .agg(collect_set($"message") as "dependencies")
      .select($"idBase64" as "idBase64_", $"language" as "language_", $"dependencies")

  private def warningCounts(outputMessages: Dataset[AnalyzerScriptResult]): Dataset[Row] = {
    val gradeCategories = "Maintainable,Testable,Robust,Secure,Automated,Performant" // TODO: load from database?
    val zerosPerCategory = outputMessages
      .select(
        $"idBase64",
        $"language",
        explode(split(lit(gradeCategories), ",")) as "gradeCategory",
        lit(literal = 0) as "count"
      )
      .distinct

    warningsToGradeCategory
      .join(outputMessages.filter($"messageType" === "warning"),
            $"tag" === $"language" && $"warning" === $"message",
            joinType = "left")
      .groupBy($"idBase64", $"language", $"gradeCategory")
      .count()
      .union(zerosPerCategory)
      .groupBy($"idBase64", $"language", $"gradeCategory")
      .agg($"idBase64", $"language", $"gradeCategory", max("count") as "warningsPerCategory")
  }

  private val scriptsDirectory = appConfig.getString("app.scriptsDir")
  private val maxExternalScriptDuration = appConfig.getDuration("grader.maxExternalScriptDuration")
  private val maxRepoArchiveSizeBytes = appConfig.getInt("grader.maxRepoArchiveSizeKiB") * 1024

}

case class WarningToGradeCategory(warning: String, tag: String, gradeCategory: String)

case class Grade(gradeCategory: String, value: Double)
case class GradedRepository(idBase64: String, tags: Set[String], grades: Seq[Grade])

case class PartialGraderResult(idBase64: String, dependencies: Seq[String], gradeCategory: String, value: Double) {

  def toGraderResult(weightedTechnologies: Seq[String]): GraderResult = {
    def dependenceToTag(dependence: String): String =
      weightedTechnologies
        .find(technology => dependence.toLowerCase contains technology.toLowerCase)
        .getOrElse(dependence)
    val tags = dependencies.map(dependenceToTag).toSet
    GraderResult(idBase64, tags, gradeCategory, value)
  }

}

case class GraderResult(idBase64: String, tags: Set[String], gradeCategory: String, value: Double) {

  def toGrade: Grade = Grade(gradeCategory, value)

}

case class AnalyzerScriptResult(idBase64: String, language: String, messageType: String, message: String)

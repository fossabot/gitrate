package analysis

import testing.TestUtils
import com.holdenkarau.spark.testing.DataFrameSuiteBase
import controllers.GraderController.{GradeCategory, WarningToGradeCategory}
import org.apache.commons.io.FileUtils
import org.apache.spark.SparkContext
import org.apache.spark.sql.{Dataset, SparkSession}
import org.scalatest.{Outcome, fixture}

class GraderSuite extends fixture.WordSpec with DataFrameSuiteBase with TestUtils {

  import com.typesafe.config.ConfigFactory
  import scala.io.Source
  import java.io.File
  import java.net.URL
  import java.util.UUID

  "Grader" can {

    "runAnalyzerScript" should {

      "ignore repository with invalid files or directories" in { fixture =>
        val login = "himanshuchandra"
        val repoName = "react.js-codes"
        val languages = Set("JavaScript")
        val (results, _, _, repoId) = fixture.runAnalyzerScript(login, repoName, languages)
        val invalidResults = results.collect().filter(_.idBase64 == repoId)
        assert(invalidResults.isEmpty)
      }

      "remove temporary files when done" in { fixture =>
        val login = "alopatindev"
        val repoName = "find-telegram-bot"
        val languages = Set("JavaScript")

        val (results, pathExists, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val idBase64 = results.collect().head.idBase64
        val archiveName = s"$idBase64.tar.gz"

        val directoryExists = pathExists("/")
        val archiveExists = pathExists(s"/../../$archiveName")

        assert(!directoryExists && !archiveExists)
      }

      "run with time limit and remove temporary files when done" in { fixture =>
        val login = "qt"
        val repoName = "qtbase"
        val languages = Set("C++")
        val (results, pathExists, _, repoId) = fixture.runAnalyzerScript(login, repoName, languages, branch = "5.9")
        val limit = fixture.grader.appConfig.getDuration("grader.maxExternalScriptDuration")

        shouldRunAtMost(limit) {
          val _ = results.collect()
        }

        val archiveName = s"$repoId.tar.gz"
        val directoryExists = pathExists("/")
        val archiveExists = pathExists(s"/../../$archiveName")

        val _ = assert(!directoryExists && !archiveExists)
      }

      "ignore too big repository" in { fixture =>
        val login = "qt"
        val repoName = "qtbase"
        val languages = Set("C++")
        val (results, _, _, repoId) = fixture.runAnalyzerScript(login, repoName, languages, branch = "5.3")
        val messages = results.collect().filter(_.idBase64 == repoId)
        assert(messages.isEmpty)
      }

      "detect automation tools" in { fixture =>
        val login = "alopatindev"
        val repoName = "find-telegram-bot"
        val languages = Set("JavaScript")

        val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val messages: Seq[String] = results
          .collect()
          .filter(message => message.language == languages.head && message.messageType == "automation_tool")
          .map(_.message)
        assert(messages contains "travis")
        assert(messages contains "circleci")
        assert(messages contains "docker")
        assert(messages contains "codeclimate")
        assert(messages contains "codeship")
        assert(messages contains "semaphoreci")
        assert(messages contains "david-dm")
        assert(messages contains "dependencyci")
        assert(messages contains "bithound")
        assert(messages contains "snyk")
        assert(messages contains "versioneye")
        assert(messages contains "codecov")
      }

//      "ignore repositories with generated/downloaded files (*.o, *.so, node_modules, etc.)" in { fixture =>
//          ???
//      }
//
//      "process multiple languages" in { fixture =>
//        ???
//      }
//
//      "ignore repository if script fails" in { fixture =>
//        ???
//      }

    }

    "JavaScript analysis" should {

      "compute lines of code" in { fixture =>
        val login = "alopatindev"
        val repoName = "find-telegram-bot"
        val languages = Set("JavaScript")
        val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val linesOfCode: Option[Int] = results
          .collect()
          .find(result => (languages contains result.language) && result.messageType == "lines_of_code")
          .map(_.message.toInt)
        assert(linesOfCode.isDefined && linesOfCode.get > 0)
      }

      "detect dependencies" in { fixture =>
        val login = "alopatindev"
        val repoName = "find-telegram-bot"
        val languages = Set("JavaScript")
        val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val dependencies: Seq[String] = results
          .collect()
          .filter(result => (languages contains result.language) && result.messageType == "dependence")
          .map(_.message)
        assert(dependencies contains "phantom")
        assert(dependencies contains "eslint")
        assert(dependencies contains "eslint-plugin-promise")
        assert(!(dependencies contains "PhantomJS"))
        assert(dependencies.toSet.size === dependencies.length)
      }

//      "ignore scoped dependencies" in { fixture =>
//        ???
//      }

      "detect Node.js dependence" in { fixture =>
        def hasDependence(login: String, repoName: String): Boolean = {
          val languages = Set("JavaScript")
          val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
          val dependencies: Set[String] = results
            .collect()
            .filter(result => (languages contains result.language) && result.messageType == "dependence")
            .map(_.message)
            .toSet
          dependencies contains "Node.js"
        }

        assert(hasDependence(login = "alopatindev", repoName = "find-telegram-bot"))
        assert(hasDependence(login = "gorillamania", repoName = "package.json-validator"))
        assert(!hasDependence(login = "jquery", repoName = "jquery.com"))
      }

      "handle absent dependencies" in { fixture =>
        val login = "Marak"
        val repoName = "hellonode"
        val languages = Set("JavaScript")
        val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val dependencies: Set[String] = results
          .collect()
          .filter(result => (languages contains result.language) && result.messageType == "dependence")
          .map(_.message)
          .toSet
        assert(dependencies.isEmpty)
      }

      "ignore repository without package.json or bower.json" in { fixture =>
        val login = "moisseev"
        val repoName = "BackupPC_Timeline"
        val languages = Set("JavaScript")
        val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val messages = results
          .collect()
          .filter(result => languages contains result.language)
        assert(messages.isEmpty)
      }

      "ignore repository when url from package.json / bower.json doesn't match with git url" in { fixture =>
        val login = "mquandalle"
        val repoName = "react-native-vector-icons"
        val languages = Set("JavaScript")
        val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val messages = results
          .collect()
          .filter(result => languages contains result.language)
        assert(messages.isEmpty)
      }

      "remove package.json, package-lock.json, bower.json, *.eslint*, yarn.lock, .gitignore" in { fixture =>
        val login = "alopatindev"
        val repoName = "find-telegram-bot"
        val languages = Set("JavaScript")
        val (results, pathExists, _, _) = fixture.runAnalyzerScript(login, repoName, languages, withCleanup = false)
        val _ = results.collect()
        assert(!pathExists("/package.json"))
        assert(!pathExists("/package-lock.json"))
        assert(!pathExists("/bower.json"))
        assert(!pathExists("/.eslintrc.yml"))
        assert(!pathExists("/yarn.lock"))
        assert(!pathExists("/.gitignore"))
      }

      "remove minified files" in { fixture =>
        val login = "Masth0"
        val repoName = "TextRandom"
        val languages = Set("JavaScript")
        val (results, pathExists, _, _) = fixture.runAnalyzerScript(login, repoName, languages, withCleanup = false)
        val _ = results.collect()
        assert(!pathExists("/dist/TextRandom.min.js"))
      }

      "remove third-party libraries" in { fixture =>
        val login = "oblador"
        val repoName = "react-native-vector-icons"
        val languages = Set("JavaScript")
        val (results, pathExists, _, _) = fixture.runAnalyzerScript(login, repoName, languages, withCleanup = false)
        val _ = results.collect()
        assert(pathExists("/index.js"))
        assert(pathExists("/Examples"))
        assert(!pathExists("/Examples/IconExplorer/IconList.js"))
        assert(!pathExists("/Examples/IconExplorer"))
      }

      "remove comments" in { fixture =>
        val login = "Masth0"
        val repoName = "TextRandom"
        val languages = Set("JavaScript")
        val (results, _, fileContainsText, _) =
          fixture.runAnalyzerScript(login, repoName, languages, withCleanup = false)
        val _ = results.collect()
        assert(!fileContainsText("/src/TextRandom.js", "Create or remove span"))
        assert(!fileContainsText("/src/TextRandom.js", "Animate random characters"))
      }

    }

    "C and C++ analysis" should {

      "compute lines of code" in { fixture =>
        val login = "alopatindev"
        val languages = Set("C", "C++")
        val repoName = "qdevicemonitor"
        val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val linesOfCode: Seq[Int] = results
          .collect()
          .filter(result => (languages contains result.language) && result.messageType == "lines_of_code")
          .map(_.message.toInt)
          .take(2)
        assert(linesOfCode.length === 2 && linesOfCode.forall(_ > 0))
      }

      "detect warnings" in { fixture =>
        val login = "alopatindev"
        val languages = Set("C", "C++")
        val repoName = "qdevicemonitor"
        val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val warnings: Seq[AnalyzerScriptResult] = results
          .collect()
          .filter(result => (languages contains result.language) && result.messageType == "warning")
        assert(warnings.nonEmpty)
      }

      "detect dependencies" in { fixture =>
        val login = "alopatindev"
        val languages = Set("C", "C++")
        val repoName = "qdevicemonitor"
        val (results, _, _, _) = fixture.runAnalyzerScript(login, repoName, languages)
        val dependencies: Set[String] = results
          .collect()
          .filter(result => (languages contains result.language) && result.messageType == "dependence")
          .map(_.message)
          .toSet
        assert(dependencies contains "libc")
        assert(dependencies contains "STL")
        assert(dependencies contains "Qt")
      }

    }

    "processAnalyzerScriptResults" should {

      "detect parent dependencies" in { fixture =>
        val login = "alopatindev"
        val repoName = "find-telegram-bot"
        val language = "JavaScript"
        val (results: Iterable[GradedRepository], _, _, _) =
          fixture.processAnalyzerScriptResults(login, repoName, Set(language))
        val technologies: Seq[String] = results.head.languageToTechnologies(language)
        assert(technologies contains "eslint")
        assert(technologies contains "eslint-plugin-promise")
      }

      "return all supported grade types" in { fixture =>
        val login = "Masth0"
        val repoName = "TextRandom"
        val languages = Set("JavaScript")
        val (results: Iterable[GradedRepository], _, _, _) =
          fixture.processAnalyzerScriptResults(login, repoName, languages)

        val gradeCategoriesSeq = results.head.grades.map(_.gradeCategory)
        val gradeCategories = gradeCategoriesSeq.toSet
        assert(gradeCategoriesSeq.length === gradeCategories.size)

        val expectedGradeCategories = Set("Maintainable", "Testable", "Robust", "Secure", "Automated", "Performant")
        assert(gradeCategories === expectedGradeCategories)
      }

      "return good grades when code is good" in { fixture =>
        val login = "Masth0"
        val repoName = "TextRandom"
        val languages = Set("JavaScript")
        val (results: Iterable[GradedRepository], _, _, _) =
          fixture.processAnalyzerScriptResults(login, repoName, languages)
        val robustGrade = results.head.grades.find(_.gradeCategory == "Robust").get.value
        assert(robustGrade >= 0.9 && robustGrade < 1.0)
      }

      // "return bad grades when code is bad" in { ??? }

      // "return automated grade based on detected CI/CD services" in { ??? }

      // "return testable grade based on test directories detection" in { ??? }
      // "return testable based on coveralls" in { ??? }
      // "return testable based on scrutinizer-ci" in { ??? }
      // "return testable based on codecov" in { ??? }
      // "return testable based on codeclimate" in { ??? }
      // "return testable based on codacy" in { ??? }

      // "detect services used" in {
      //   assert(
      //     fixture.servicesOf("alopatindev", "qdevicemonitor") === Seq("travis-ci.org", "appveyor.com")
      //     fixture.servicesOf("alopatindev", "find-telegram-bot") === Seq(
      //       "travis-ci.org",
      //       "codecov.io",
      //       "codeclimate.com",
      //       "semaphoreci.com",
      //       "bithound.io",
      //       "versioneye.com",
      //       "david-dm.org",
      //       "dependencyci.com",
      //       "snyk.io",
      //       "npmjs.com"
      //     ))
      // }

    }

  }

  override def withFixture(test: OneArgTest): Outcome = {
    implicit val sparkContext: SparkContext = sc
    implicit val sparkSession: SparkSession = SparkSession.builder
      .config(sparkContext.getConf)
      .getOrCreate()

    import sparkSession.implicits._

    val appConfig = ConfigFactory.load("GraderFixture.conf")
    val warningsToGradeCategory = sparkContext
      .parallelize(
        Seq(
          ("eqeqeq", "JavaScript", "Robust")
        ))
      .toDF("warning", "language", "gradeCategory")
      .as[WarningToGradeCategory]

    val gradeCategories = sparkContext
      .parallelize(
        Seq(
          "Maintainable",
          "Testable",
          "Robust",
          "Secure",
          "Automated",
          "Performant"
        ))
      .toDF("gradeCategory")
      .as[GradeCategory]

    val grader = new Grader(appConfig, warningsToGradeCategory, gradeCategories)
    val dataDir: String = s"${appConfig.getString("app.scriptsDir")}/data"
    val theFixture = FixtureParam(grader, dataDir)
    try {
      withFixture(test.toNoArgTest(theFixture))
    } finally {
      val dir = new File(dataDir)
      FileUtils.deleteDirectory(dir)
      val _ = dir.mkdir()
    }
  }

  case class FixtureParam(grader: Grader, dataDir: String) {

    def runAnalyzerScript(login: String, // scalastyle:ignore
                          repoName: String,
                          languages: Set[String],
                          branch: String = "master",
                          withCleanup: Boolean = true)
      : (Dataset[AnalyzerScriptResult], (String) => Boolean, (String, String) => Boolean, String) = {
      val repoId = UUID.randomUUID().toString
      val archiveURL = new URL(s"https://github.com/$login/$repoName/archive/$branch.tar.gz")
      val input: Seq[String] = Seq(grader.ScriptInput(repoId, repoName, login, archiveURL, languages).toString)

      val results = grader.runAnalyzerScript(input, withCleanup)

      def file(path: String): File = new File(s"$dataDir/$repoId/$repoName-$branch$path").getCanonicalFile

      def pathExists(path: String): Boolean = file(path).exists()

      def fileContainsText(path: String, pattern: String): Boolean =
        Source.fromFile(file(path)).mkString contains pattern

      (results, pathExists, fileContainsText, repoId)
    }

    def processAnalyzerScriptResults(login: String, repoName: String, languages: Set[String])
      : (Iterable[GradedRepository], (String) => Boolean, (String, String) => Boolean, String) = {
      val (outputMessages, pathExists, fileContainsText, repoId) = runAnalyzerScript(login, repoName, languages)
      val results = grader.processAnalyzerScriptResults(outputMessages)
      (results, pathExists, fileContainsText, repoId)
    }

  }

}

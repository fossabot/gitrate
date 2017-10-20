package utils

import com.typesafe.config.Config
import org.apache.spark.rdd.RDD
import org.apache.spark.sql.{Dataset, Row, SparkSession}
import org.apache.spark.streaming.{Seconds, StreamingContext}
import org.apache.spark.{SparkConf, SparkContext}

trait SparkUtils {

  def appConfig: Config
  def postgresqlConfig: Config

  private val sparkConf = new SparkConf()
    .setAppName(appConfig.getString("app.name"))
    .setMaster("local[*]")

  def getOrCreateSparkContext(): SparkContext =
    SparkContext.getOrCreate(sparkConf)

  def createStreamingContext(): StreamingContext = {
    val sc = SparkContext.getOrCreate()
    new StreamingContext(sc, batchDuration)
  }

  def getOrCreateSparkSession(): SparkSession =
    SparkSession.builder
      .config(sparkConf)
      .getOrCreate()

  def initializeSpark(): Unit = {
    val _ = (getOrCreateSparkContext(), getOrCreateSparkSession())
  }

  object Postgres {

    private val dbOptions = Seq("url", "user", "driver")
      .map(key => key -> postgresqlConfig.getString(key))
      .toMap

    def getTable(table: String): Dataset[Row] =
      getOrCreateSparkSession().read
        .format("jdbc")
        .options(dbOptions + ("dbtable" -> table))
        .load

    def executeSQL(query: String): Dataset[Row] = getTable(s"""($query) AS tmp""")

  }

  private val batchDuration = Seconds(appConfig.getDuration("stream.batchDuration").getSeconds)

}

object SparkUtils {

  implicit class RDDUtils(rdd: RDD[_]) {

    def toSparkSession: SparkSession = {
      val conf = rdd.sparkContext.getConf
      SparkSession.builder
        .config(conf)
        .getOrCreate()
    }

  }

}

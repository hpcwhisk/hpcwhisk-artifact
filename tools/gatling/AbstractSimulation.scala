package opal

import com.fasterxml.jackson.databind.ObjectMapper
import scala.util.Random

import scala.concurrent.duration._
import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.commons.validation._
import io.gatling.core.feeder.Record
import java.io.File
import net.sf.saxon.serialize.JSONSerializer
import scala.io.Source

abstract class AbstractSimulation extends Simulation {
  val whiskConfig = {
    val defaultWskProps = sys.env.get("HOME").get + File.separator + ".wskprops"
    val configFile = sys.env.get("WSK_CONFIG_FILE").getOrElse(defaultWskProps)
    Source.fromFile(configFile).getLines()
    .map(line => line.trim.split("=", 2))
    .map(it => it(0) -> it(1))
    .toMap
  }

  val baseUrl = whiskConfig("APIHOST")
  val user = whiskConfig("AUTH").split(":")(0)
  val pass = whiskConfig("AUTH").split(":")(1)
  val random = new Random()
  

  case class ActionConfig(name: String, args: Map[String, Any])

  def toJson(query: Any): String = query match {
    case m: Map[String, Any] => s"{${m.map(toJson(_)).mkString(",")}}"
    case t: (String, Any) => s""""${t._1}":${toJson(t._2)}"""
    case ss: Seq[Any] => s"""[${ss.map(toJson(_)).mkString(",")}]"""
    case s: String => s""""$s""""
    case null => "null"
    case _ => query.toString
  }

  val httpProtocol = http
    // Here is the root for all relative URLs
    .baseUrl(baseUrl)
    // Here are the common headers
    .acceptHeader("application/json")
    .doNotTrackHeader("1")
    .contentTypeHeader("application/json")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")

  val owApiBlockingInvoke =
    http("exec ${action.name}")
      .post("/api/v1/namespaces/guest/actions/${action.name}")
      .queryParamMap(Map("blocking" -> "true", "result" -> "true"))
      .basicAuth(user, pass)
      .requestTimeout(10.minutes)
      .body(StringBody(session => {
        toJson(session("action").as[ActionConfig].args)
      }))

  val owWebInvoke =
    http("exec ${action.name}")
      .post("/api/v1/web/guest/default/${action.name}.json")
      .requestTimeout(10.minutes)
      .body(StringBody(session => {
        toJson(session("action").as[ActionConfig].args)
      }))

}


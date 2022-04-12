package opal

import com.fasterxml.jackson.databind.ObjectMapper

import scala.concurrent.duration._
import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.commons.validation._
import io.gatling.core.feeder.Record
import net.sf.saxon.serialize.JSONSerializer

import scala.util.Random
import scala.io.Source

class StaticLoadSimulation extends AbstractSimulation {
  val feeder = (1 to 100).map { i => 
    Map("action" -> ActionConfig(s"sleep_10ms_$i", Map()))
  }.toArray.random
  var usersPerSec = 10

  val call = scenario("call").feed(feeder).exec(owWebInvoke)

  setUp(call.inject(constantUsersPerSec(usersPerSec) during(1440 minutes))).protocols(httpProtocol)
}


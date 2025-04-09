/*
 * Copyright (c) 2015-2023, the Beysant App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

//https://repo.eclipse.org/index.html#nexus-search;gav~org.eclipse.paho~org.eclipse.paho.client.mqttv3~~~~kw,versionexpand
//https://repo.eclipse.org/service/local/repositories/maven_central/content/org/eclipse/paho/org.eclipse.paho.client.mqttv3/1.2.5/org.eclipse.paho.client.mqttv3-1.2.5.jar

ifEmit(jv) {
emit(jv) {
"""
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
"""
}
}

class App:Mqtt {

  ifEmit(jv) {
   emit(jv) {
   """
   MqttClient client;
   """
   }
  }
  
  new() self {
    fields {
      String broker; //String broker = "tcp://broker.emqx.io:1883"; tcp://127.0.0.1:1883 wss://broker.emqx.io:8084 ssl://broker.emqx.io:8883
      String user;
      String pass;
      String clientId;
      Int connectTimeout = 3; //was 15, very long
      Int keepAlive = 60;
      Int qos = 1;
      IO:Log log = IO:Logs.get(self);
      any messageHandler;
      String lastError;
      List waitingSubs;
    }
    ifEmit(apwk) {
      waitingSubs = List.new();
    }
  }

  handleMessage(String topic, String payload) {
      //log.log("got message " + topic + " " + payload);
    if (def(messageHandler)) {
      try {
        messageHandler.handleMessage(topic, payload);
      } catch (any e) {
        log.elog("exception in messageHandler.handleMessage", e);
      }
    }
  }

  open() self {
    try {
      openInner();
    } catch (any e) {
      log.elog("mqtt error", e);
      if (def(e)) { lastError = e.description; }
    }
  }
  
  openInner() {
    if (TS.isEmpty(clientId)) {
      clientId = System:Random.getString(12); //reusing same id on reconnect is fine, oldest is kicked out
    }
    ifEmit(jv) {
    emit(jv) {
    """
      client = new MqttClient(bevp_broker.bems_toJvString(), bevp_clientId.bems_toJvString(), new MemoryPersistence());
      MqttConnectOptions options = new MqttConnectOptions();
      options.setUserName(bevp_user.bems_toJvString());
      options.setPassword(bevp_pass.bems_toJvString().toCharArray());
      options.setConnectionTimeout(bevp_connectTimeout.bevi_int); //default 30sec
      options.setKeepAliveInterval(bevp_keepAlive.bevi_int); //default 60sec
      options.setAutomaticReconnect(false);

      client.setCallback(new MqttCallback() {

               public void connectionLost(Throwable cause) {
                   //System.out.println("connectionLost: " + cause.getMessage());
              }

               public void messageArrived(String topic, MqttMessage message) {
                   //System.out.println("topic: " + topic);
                   //System.out.println("Qos: " + message.getQos());
                   //System.out.println("message content: " + new String(message.getPayload()));
                   try {
                   BEC_2_4_6_TextString bevls_topic = new BEC_2_4_6_TextString(topic);
                   BEC_2_4_6_TextString bevls_payload = new BEC_2_4_6_TextString(message.toString());
                   bem_handleMessage_2(bevls_topic, bevls_payload);
                   } catch (Throwable t) {
                    System.out.println("Exception in handleMessage");
                   }
              }

               public void deliveryComplete(IMqttDeliveryToken token) {
                   //System.out.println("deliveryComplete---------" + token.isComplete());
              }

          });

      client.connect(options);
    """
    }
    }
    ifEmit(apwk) {
      var sparts = broker.split("/");
      //for (var spart in sparts) {
      //  log.log("spart " + spart);
      //}
      var brkp = sparts[2];
      //log.log("brkp " + brkp);
      var cparts = brkp.split(":");
      //for (var cpart in cparts) {
      //  log.log("cpart " + cpart);
      //}
      var brk = cparts[0];
      var pt = cparts[1];
      var cid = clientId;
      var u = user;
      var p = pass;
      var ka = keepAlive;
      log.log("brk " + brk);
      log.log("pt " + pt);
      Int pti = Int.new(pt);
      String jsmqres;
      emit(js) {
      """
      //prompt(bevl_jspw.bems_toJsString());

      try {
        //client = new Paho.MQTT.Client("iot.eclipse.org", Number(80), "/ws", "clientId");
        //client = new Paho.MQTT.Client("test.mosquitto.org", Number(8081), "clientId");
        //client = new Paho.MQTT.Client("broker.emqxsl.com", Number(8084), "clientId");
        client = new Paho.MQTT.Client(bevl_brk.bems_toJsString(), Number(bevl_pti.bevi_int), bevl_cid.bems_toJsString());
        this.bevi_connected = false;
        this.bevi_client = client;
        var bevs_mqtt = this;


       // set callback handlers
        client.onConnectionLost = function (responseObject) {
            console.log("Connection Lost: "+responseObject.errorMessage);
            bevs_mqtt.bevi_connected = false;
        }

        client.onMessageArrived = function (message) {
          console.log("Message Arrived: "+message.payloadString);
          console.log("from topic: " + message.destinationName);
          var bestop = new be_$class/Text:String$().bems_new(message.destinationName);
          var bespay = new be_$class/Text:String$().bems_new(message.payloadString);
          bevs_mqtt.bem_handleMessage_2(bestop, bespay);
        }

        // Called when the connection is made
        function onConnect(){
            console.log("Connected");
            //client.subscribe("yo");
            //var message = new Paho.MQTT.Message("adrian");
            //message.destinationName = "yo";
            //message.qos = 0;
            //client.send(message);
            let lmsgv = new be_$class/Text:String$().bems_new("a log message from the connect callback");
            bevs_mqtt.bevp_log.bem_log_1(lmsgv);
            bevs_mqtt.bevi_connected = true;
            bevs_mqtt.bem_doWaitingSubs_0();
        }

        // Called when the connection is made
        function onFailConnect(){
            console.log("Fail Connected");
            bevs_mqtt.bevi_connected = false;
        }

        bevl_jsmqres = new be_$class/Text:String$().bems_new("going to connect");
        this.bevp_log.bem_log_1(bevl_jsmqres);
        // Connect the client, providing an onConnect callback
        client.connect({
            onSuccess: onConnect,
            onFailure: onFailConnect,
            userName : bevl_u.bems_toJsString(),
	        password : bevl_p.bems_toJsString(),
            keepAliveInterval : Number(bevl_ka.bevi_int),
            useSSL: true
        });
        let lmsgv = new be_$class/Text:String$().bems_new("past connect");
        this.bevp_log.bem_log_1(lmsgv);

      } catch (e) {
        bevl_jsmqres = new be_$class/Text:String$().bems_new("got exception in mqtt");
        this.bevp_log.bem_log_1(bevl_jsmqres);
        bevl_jsmqres = new be_$class/Text:String$().bems_new(e.toString());
        this.bevp_log.bem_log_1(bevl_jsmqres);
      }
      """
      }
      if (TS.notEmpty(jsmqres)) {
        log.log("mqtt js final " + jsmqres);
      }
    }
  }

  publish(String topic, String message) {
    try {
      publishInner(topic, message);
    } catch (any e) {
      log.elog("mqtt error", e);
      if (def(e)) { lastError = e.description; }
    }
  }

  publishInner(String topic, String message) {
    ifEmit(jv) {
      emit(jv) {
        """
        MqttMessage message = new MqttMessage(beva_message.bems_toJvString().getBytes());
        message.setQos(bevp_qos.bevi_int);
        client.publish(beva_topic.bems_toJvString(), message);
        """
      }
    }
    ifEmit(apwk) {
       emit(js) {
       """
       console.log("mqtt sending");
       try {
         var message = new Paho.MQTT.Message(beva_message.bems_toJsString());
         message.destinationName = beva_topic.bems_toJsString();
         message.qos = 0;
         this.bevi_client.send(message);
         //this.bevi_client.subscribe(beva_topic.bems_toJsString());
       } catch (e) {
         console.log("send failed");
         console.log(e.toString());
         throw e;
       }
       console.log("mqtt sent");
       """
      }
    }
  }

  doWaitingSubs() {
    for (String top in waitingSubs) {
       emit(js) {
       """
       console.log("mqtt late subscribing");
       try {
         this.bevi_client.subscribe(bevl_top.bems_toJsString());
       } catch (e) {
         console.log("subscribe failed");
         console.log(e.toString());
         throw e;
       }
       console.log("mqtt late subscribed");
       """
      }
    }
    waitingSubs = List.new();
  }

  subscribe(String topic) {
    try {
      subscribeInner(topic);
    } catch (any e) {
      log.elog("mqtt error", e);
      if (def(e)) { lastError = e.description; }
    }
  }

  subscribeInner(String topic) {
    ifEmit(jv) {
      emit(jv) {
        """
        client.subscribe(beva_topic.bems_toJvString(), bevp_qos.bevi_int);
        """
      }
    }
    ifEmit(apwk) {
      if (self.isOpen) {
      emit(js) {
       """
       console.log("mqtt subscribing");
       try {
         this.bevi_client.subscribe(beva_topic.bems_toJsString());
       } catch (e) {
         console.log("subscribe failed");
         console.log(e.toString());
         throw e;
       }
       console.log("mqtt subscribed");
       """
      }
      } else {
       waitingSubs += topic;
      }
    }
  }

  unsubscribe(String topic) {
    try {
      unsubscribeInner(topic);
    } catch (any e) {
      log.elog("mqtt error", e);
      if (def(e)) { lastError = e.description; }
    }
  }

  unsubscribeInner(String topic) {
    ifEmit(jv) {
      emit(jv) {
        """
        client.unsubscribe(beva_topic.bems_toJvString());
        """
      }
    }
    ifEmit(apwk) {
      emit(js) {
       """
       console.log("mqtt unsubscribing");
       try {
         this.bevi_client.unsubscribe(beva_topic.bems_toJsString());
       } catch (e) {
         console.log("unsubscribe failed");
         console.log(e.toString());
         throw e;
       }
       console.log("mqtt unsubscribed");
       """
      }
    }
  }

  isOpenGet() Bool {
    try {
      return(isOpenGetInner());
    } catch (any e) {
      log.elog("mqtt error", e);
      if (def(e)) { lastError = e.description; }
    }
    return(false);
  }

  isOpenGetInner() Bool {
    ifEmit(jv) {
      emit(jv) {
        """
        if (client != null && client.isConnected()) {
        """
      }
      return(true);
      emit(jv) {
        """
      }
        """
      }
    }
    ifEmit(apwk) {
      emit(js) {
        """
        if (this.bevi_connected !== null && this.bevi_connected) {
        """
      }
      return(true);
      emit(js) {
        """
        }
        """
      }
    }
    return(false);
  }

  canSubscribeGet() Bool {
    ifEmit(apwk) {
      return(true);
    }
    return(self.isOpen);
  }

  close() {
    try {
      messageHandler = null;
      closeInner();
    } catch (any e) {
      log.elog("mqtt error", e);
      if (def(e)) { lastError = e.description; }
    }
  }

  closeInner() {
    ifEmit(jv) {
      emit(jv) {
        """
        client.disconnectForcibly(10);
        client = null;
        """
      }
    }
    ifEmit(apwk) {
      emit(js) {
       """
       this.bevi_connected = false;
       try {
         this.bevi_client.disconnect();
       } catch (e) {
         console.log("disconnect failed");
         console.log(e.toString());
         throw e;
       }
       """
      }
    }
  }

}


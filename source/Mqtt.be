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
      String broker; //String broker = "tcp://broker.emqx.io:1883"; tcp://127.0.0.1:1883
      String user;
      String pass;
      String clientId;
      Int connectTimeout = 15;
      Int keepAlive = 10;
      Int qos = 1;
      IO:Log log = IO:Logs.get(self);
      any messageHandler;
      String lastError;
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
      options.setConnectionTimeout(bevp_connectTimeout.bevi_int);
      options.setKeepAliveInterval(bevp_keepAlive.bevi_int);

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
      String jsmqres;
      emit(js) {
      """
      //prompt(bevl_jspw.bems_toJsString());

      try {
        //client = new Paho.MQTT.Client("iot.eclipse.org", Number(80), "/ws", "clientId");
        client = new Paho.MQTT.Client("test.mosquitto.org", Number(8081), "clientId");
        //client = new Paho.MQTT.Client("", Number(8084), "clientId");


       // set callback handlers
        client.onConnectionLost = function (responseObject) {
            console.log("Connection Lost: "+responseObject.errorMessage);
        }

        client.onMessageArrived = function (message) {
          console.log("Message Arrived: "+message.payloadString);
        }

        // Called when the connection is made
        function onConnect(){
            console.log("Connected");
            client.subscribe("yo");
            var message = new Paho.MQTT.Message("adrian");
            message.destinationName = "yo";
            message.qos = 0;
            client.send(message);
        }

        // Called when the connection is made
        function onFailConnect(){
            console.log("Fail Connected");
        }

        bevl_jsmqres = new be_$class/Text:String$().bems_new("going to connect");
        this.bevp_log.bem_log_1(bevl_jsmqres);
        // Connect the client, providing an onConnect callback
        client.connect({
            onSuccess: onConnect,
            onFailure: onFailConnect,
            //userName : "user",
	        //password : "pass",
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
    return(false);
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
  }

}


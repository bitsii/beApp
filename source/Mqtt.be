// Copyright 2015 The BraceApp Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

ifEmit(wajv) {
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

  ifEmit(wajv) {
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
    }
  }

  handleMessage(String topic, String payload) {
      //log.log("got message " + topic + " " + payload);
    if (def(messageHandler)) {
      messageHandler.handleMessage(topic, payload);
    }
  }
  
  start() {
    if (TS.isEmpty(clientId)) {
      clientId = System:Random.getString(12);
    }
    ifEmit(wajv) {
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
  }

  publish(String topic, String message) {
    ifEmit(wajv) {
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
    ifEmit(wajv) {
      emit(jv) {
        """
        client.subscribe(beva_topic.bems_toJvString(), bevp_qos.bevi_int);
        """
      }
    }
  }

}


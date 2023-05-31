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

}


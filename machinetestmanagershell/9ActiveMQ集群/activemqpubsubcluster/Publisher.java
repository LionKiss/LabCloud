package activemqpubsubcluster;

import javax.jms.Connection;  
import javax.jms.ConnectionFactory;  
import javax.jms.DeliveryMode;  
import javax.jms.Destination;  
import javax.jms.JMSException;  
import javax.jms.MapMessage;  
import javax.jms.MessageProducer;  
import javax.jms.Session;  
import javax.jms.TextMessage;  
  
import org.apache.activemq.ActiveMQConnectionFactory;  
  
public class Publisher {  
  
    // 单例模式  
  
    // 1、连接工厂  
    private ConnectionFactory connectionFactory;  
    // 2、连接对象  
    private Connection connection;  
    // 3、Session对象  
    private Session session;  
    // 4、生产者  
    private MessageProducer messageProducer;  
  
    public Publisher() {  
  
        try {  
        	this.connectionFactory = new ActiveMQConnectionFactory("admin",  
                    "admin", "tcp://****:61646/");  
            this.connection = connectionFactory.createConnection();  
            this.connection.start();  
            // 不使用事务  
            // 设置客户端签收模式  
            this.session = this.connection.createSession(false,  
                    Session.AUTO_ACKNOWLEDGE);  
            this.messageProducer = this.session.createProducer(null);  
        } catch (JMSException e) {  
            throw new RuntimeException(e);  
        }  
  
    }  
  
    public Session getSession() {  
        return this.session;  
    }  
  
    public void send1(/* String QueueName, Message message */) {  
        try {  
  
            Destination destination = this.session.createTopic("topic1");  
            MapMessage msg1 = this.session.createMapMessage();  
            msg1.setString("name", "张三");  
            msg1.setInt("age", 22);  
  
            MapMessage msg2 = this.session.createMapMessage();  
            msg2.setString("name", "李四");  
            msg2.setInt("age", 25);  
  
            MapMessage msg3 = this.session.createMapMessage();  
            msg3.setString("name", "张三");  
            msg3.setInt("age", 30);  
  
            // 发送消息到topic1  
            this.messageProducer.send(destination, msg1,  
                    DeliveryMode.NON_PERSISTENT, 4, 1000 * 60 * 10);  
            this.messageProducer.send(destination, msg2,  
                    DeliveryMode.NON_PERSISTENT, 4, 1000 * 60 * 10);  
            this.messageProducer.send(destination, msg3,  
                    DeliveryMode.NON_PERSISTENT, 4, 1000 * 60 * 10);  
            
            Destination destination1 = this.session.createTopic("topic2");  
            MapMessage msg11 = this.session.createMapMessage();  
            msg11.setString("name", "张123三");  
            msg11.setInt("age", 122);  
  
            MapMessage msg12 = this.session.createMapMessage();  
            msg12.setString("name", "李123四");  
            msg12.setInt("age", 125);  
  
            MapMessage msg13 = this.session.createMapMessage();  
            msg13.setString("name", "张123三");  
            msg13.setInt("age", 130);  
  
            // 发送消息到topic1  
            this.messageProducer.send(destination1, msg11,  
                    DeliveryMode.NON_PERSISTENT, 4, 1000 * 60 * 10);  
            this.messageProducer.send(destination1, msg12,  
                    DeliveryMode.NON_PERSISTENT, 4, 1000 * 60 * 10);  
            this.messageProducer.send(destination1, msg13,  
                    DeliveryMode.NON_PERSISTENT, 4, 1000 * 60 * 10);  
  
        } catch (JMSException e) {  
            throw new RuntimeException(e);  
        }  
    }  
  
    public void send2() {  
        try {  
            Destination destination = this.session.createTopic("topic1");  
            TextMessage message = this.session.createTextMessage("我是一个字符串");  
            // 发送消息  
            this.messageProducer.send(destination, message,  
                    DeliveryMode.NON_PERSISTENT, 4, 1000 * 60 * 10);  
        } catch (JMSException e) {  
            throw new RuntimeException(e);  
        }  
  
    }  
  
    public static void main(String[] args) {  
        Publisher producer = new Publisher();  
        producer.send1();  
  
    }  
  
}  
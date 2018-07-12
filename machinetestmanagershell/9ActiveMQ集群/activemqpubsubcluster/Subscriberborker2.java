package activemqpubsubcluster;

import javax.jms.Connection;  
import javax.jms.ConnectionFactory;  
import javax.jms.Destination;  
import javax.jms.JMSException;  
import javax.jms.MapMessage;  
import javax.jms.Message;  
import javax.jms.MessageConsumer;  
import javax.jms.MessageListener;  
import javax.jms.Session;  
import javax.jms.TextMessage;  
  
import org.apache.activemq.ActiveMQConnectionFactory;  
  
public class Subscriberborker2 {  
  
    // 单例模式  
  
    // 1、连接工厂  
    private ConnectionFactory connectionFactory;  
    // 2、连接对象  
    private Connection connection;  
    // 3、Session对象  
    private Session session;  
    // 4、生产者  
    private MessageConsumer messageConsumer;  
    // 5、目的地址  
    private Destination destination;  
  
    public Subscriberborker2() {  
  
        try {  
            this.connectionFactory = new ActiveMQConnectionFactory("admin",  
                    "admin", "tcp://*****:61626/");  
            this.connection = connectionFactory.createConnection();  
            this.connection.start();  
            // 不使用事务  
            // 设置客户端签收模式  
            this.session = this.connection.createSession(false,  
                    Session.AUTO_ACKNOWLEDGE);  
            this.destination = this.session.createTopic("topic2");  
            this.messageConsumer = this.session.createConsumer(destination);  
        } catch (JMSException e) {  
            throw new RuntimeException(e);  
        }  
  
    }  
  
    public Session getSession() {  
        return this.session;  
    }  
  
    // 用于监听消息队列的消息  
    class MyLister implements MessageListener {  
  
        @Override  
        public void onMessage(Message message) {  
            try {  
                if (message instanceof TextMessage) {  
  
                }  
                if (message instanceof MapMessage) {  
                    MapMessage ret = (MapMessage) message;  
                    System.out.println(ret.toString());  
                    System.out.println(ret.getString("name"));  
                    System.out.println(ret.getInt("age"));  
                    // 因为设置的是客户端的签收模式，所以要手动的去确认消息的消费  
                    message.acknowledge();  
                }  
            } catch (JMSException e) {  
                throw new RuntimeException(e);  
            }  
        }  
  
    }  
  
    // 用于异步监听消息  
    public void receiver() {  
        try {  
            this.messageConsumer.setMessageListener(new MyLister());  
        } catch (JMSException e) {  
            throw new RuntimeException(e);  
        }  
    }  
  
    public static void main(String[] args) {  
        Subscriberborker2 conmuser = new Subscriberborker2();  
        conmuser.receiver();  
  
    }  
  
}  
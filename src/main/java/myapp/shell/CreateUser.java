package myapp.shell;

import java.util.List;

import myapp.entity.User;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.FileSystemXmlApplicationContext;
import org.springframework.orm.hibernate4.HibernateTransactionManager;

public class CreateUser {

	/**
	 * Run from command line
	 * 
	 * @param args
	 */
	public static void main(String[] args) {

		ApplicationContext ctx = new FileSystemXmlApplicationContext(
				"/src/main/webapp/WEB-INF/applicationContext.xml");
		
		HibernateTransactionManager tm = (HibernateTransactionManager) ctx.getBean("transactionManager");
		tm.getTransaction(null);

		User user = new User();
	    user.setActive(true);
	    user.setEmail("mail@example.com");
	    user.setUserName("userName");
		long id = user.save();
		System.out.println("Saved a new User with id: " + id);
		
        // Every persistent object comes with a built-in way to issue simple queries via a [PersistentClass].objects.[queryMethod] syntax
        User user2 = User.objects.load(id);
        System.out.println("Loaded User by id, name is: " + user2.getUserName());
        
        // objects.all() returns all rows in a table
        List<User> allUsers = User.objects.all();
        User user3 = allUsers.iterator().next();
        System.out.println("First row in User table has name: " + user3.getUserName());
        
        // And objects.filter allows you to query by column value
        List<User> users = User.objects.filter("email", "mail@example.com");
        System.out.println("Found " + users.size() + " user(s) with email: mail@example.com");

	}

}

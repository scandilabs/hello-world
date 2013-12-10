package myapp.entity;

import javax.persistence.Entity;

import com.scandilabs.catamaran.entity.support.EntityFinder;
import com.scandilabs.catamaran.entity.support.PersistableBase;

@Entity
public class User extends PersistableBase {
	
	public static EntityFinder objects;

    private String userName;
    private String email;
    private boolean active;

    public String getUserName() {
        return userName;
    }
    public void setUserName(String userName) {
        this.userName = userName;
    }
    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
    }
    public boolean isActive() {
        return active;
    }
    public void setActive(boolean active) {
        this.active = active;
    }
}
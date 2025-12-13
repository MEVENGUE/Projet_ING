package metier;


public class Client {
	 private String nom;
	    private String prenom;
	    private int age;
	    private String ville;
	    
	    
	    public Client(String nom, String prenom, int age, String ville) {
	        this.nom = nom;
	        this.prenom = prenom;
	        this.age = age;
	        this.ville = ville;
	    }
	    public Client() {
	    }
	    public String getNom() {
	        return nom;
	    }
	    public String getPrenom() {
	        return prenom;
	    }
	    public int getAge() {
	        return age;
	    }
	    public String getVille() {
	        return ville;
	    }
	    public void setNom(String nom) {
	        this.nom = nom;
	    }
	    public void setPrenom(String prenom) {
	        this.prenom = prenom;
	    }
	    public void setAge(int age) {
	        this.age = age;
	    }
	    public void setVille(String ville) {
	        this.ville = ville;
	    }
	}




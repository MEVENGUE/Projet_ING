package test;

import java.util.ArrayList;
import java.util.Scanner;

import dao.ClientDao;

public class GestionTest {
	public static void main(String[] argv) {

        ClientDao clientDao = new ClientDao();

        ArrayList<metier.Client> listeClient = clientDao.createClient();

        try (Scanner scan = new Scanner(System.in)) {
            System.out.println("Saisir Mot clé : ");
            String mc = scan.next();

            System.out.println(clientDao.deleteClientParMC(mc, listeClient));
        } 


    }
}



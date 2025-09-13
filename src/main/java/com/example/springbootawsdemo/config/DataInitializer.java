package com.example.springbootawsdemo.config;

import com.example.springbootawsdemo.entity.User;
import com.example.springbootawsdemo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Override
    public void run(String... args) throws Exception {
        // Create some sample users
        if (userRepository.count() == 0) {
            userRepository.save(new User("John Doe", "john.doe@example.com"));
            userRepository.save(new User("Jane Smith", "jane.smith@example.com"));
            userRepository.save(new User("Bob Johnson", "bob.johnson@example.com"));
            
            System.out.println("Sample data initialized successfully!");
        }
    }
}

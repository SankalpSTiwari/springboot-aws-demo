package com.example.springbootawsdemo.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(HelloController.class)
class HelloControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testHelloEndpoint() throws Exception {
        mockMvc.perform(get("/api/hello"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Hello from Spring Boot on AWS!"))
                .andExpect(jsonPath("$.status").value("success"));
    }

    @Test
    void testHelloWithNameEndpoint() throws Exception {
        mockMvc.perform(get("/api/hello/John"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Hello John from Spring Boot on AWS!"))
                .andExpect(jsonPath("$.status").value("success"));
    }

    @Test
    void testHealthEndpoint() throws Exception {
        mockMvc.perform(get("/api/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.service").value("springboot-aws-demo"));
    }
}

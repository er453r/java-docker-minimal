package com.er453r;


import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class MiniMain {
    public static void main(String[] args) {
        System.out.println("Hello derp!");

        SpringApplication.run(MiniMain.class, args);
    }

    @GetMapping("/hello")
    public String sayHello(@RequestParam(name="name", required=false, defaultValue="General Kenobi") String name) {
        return String.format("Hello there %s", name);
    }
}

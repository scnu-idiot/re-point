package com.idiot.re_point.web;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
public class RootController {

    private final Environment env;

    @Value("${spring.application.name:repoint-backend}")
    private String appName;

    public RootController(Environment env) {
        this.env = env;
    }

    @GetMapping("/")
    public Map<String, Object> root() {
        Map<String, Object> body = new HashMap<>();
        body.put("service", appName);
        body.put("status", "OK");
        body.put("time", OffsetDateTime.now().toString());
        body.put("profiles", env.getActiveProfiles()); // []면 default
        body.put("docs", "/actuator/health");
        return body; // 200 OK + application/json
    }

    // (선택) 프론트/문서용으로 /api 루트도 안내
    @GetMapping("/api")
    public Map<String, Object> apiRoot() {
        Map<String, Object> body = new HashMap<>();
        body.put("service", appName);
        body.put("status", "OK");
        body.put("basePath", "/api");
        return body;
    }
}
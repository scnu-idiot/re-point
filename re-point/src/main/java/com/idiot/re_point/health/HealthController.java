package com.idiot.re_point.health;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthController {
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of("status","OK"));
    }

    @GetMapping("/api/version")
    public Map<String, String> version() {
        return Map.of(
                "name", "re-point-backend",
                "version", "0.0.1",
                "env", System.getProperty("spring.profiles.active", "default")
        );
    }
}